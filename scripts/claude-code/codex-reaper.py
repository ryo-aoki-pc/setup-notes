"""SessionStart hook: kill Codex plugin brokers left behind by ended sessions.

The Codex plugin for Claude Code starts a detached app-server-broker.mjs for
each workspace it is used in, and every broker keeps a codex app-server with
a dozen sandbox processes under it. The plugin's SessionEnd hook stops it,
but a session that crashes or is archived never runs that hook, and the
trees pile up (hundreds of processes after a day).

A broker is killed when it is older than --min-age-hours and no
codex-companion.mjs process (a foreground task or a background task-worker)
is running for an overlapping --cwd. Its parent is not looked at: brokers
are detached, so the parent is gone even while the broker is in use. A
broker killed while idle is started again by the plugin on the next call.

Nothing is written to stdout in hook mode, since SessionStart output goes
into Claude's context; kills are appended to hooks/codex-reaper.log.
"""

import argparse
from datetime import datetime
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time

BROKER = "app-server-broker.mjs"
COMPANION = "codex-companion.mjs"
LOG_NAME = "codex-reaper.log"
LOG_LIMIT = 1024 * 1024
TOKEN = re.compile(r'"([^"]*)"|(\S+)')
# Only the node processes matter; filtering in PowerShell keeps the JSON small.
WINDOWS_QUERY = (
    "[Console]::OutputEncoding = [Text.Encoding]::UTF8; "
    "@(Get-CimInstance Win32_Process -Filter \"Name = 'node.exe'\" | "
    "Where-Object { $_.CreationDate -and $_.CommandLine -match 'app-server-broker\\.mjs|codex-companion\\.mjs' } | "
    "ForEach-Object { [pscustomobject]@{ pid = $_.ProcessId; "
    "started = ([DateTimeOffset]$_.CreationDate).ToUnixTimeSeconds(); cmdline = $_.CommandLine } }) | "
    "ConvertTo-Json -Compress"
)


def config_directory():
    override = os.environ.get("CLAUDE_CONFIG_DIR")
    return (Path(override).expanduser() if override else Path.home() / ".claude").resolve()


def no_window():
    return {"creationflags": subprocess.CREATE_NO_WINDOW} if os.name == "nt" else {}


def windows_processes():
    shell = Path(os.environ.get("SystemRoot", r"C:\Windows"), "System32", "WindowsPowerShell", "v1.0", "powershell.exe")
    result = subprocess.run(
        [str(shell), "-NoProfile", "-NonInteractive", "-Command", WINDOWS_QUERY],
        capture_output=True, timeout=20, check=True, **no_window(),
    )
    text = result.stdout.decode("utf-8-sig").strip()
    return json.loads(text) if text else []


def linux_processes():
    ticks = os.sysconf("SC_CLK_TCK")
    boot = next(int(line.split()[1]) for line in Path("/proc/stat").read_text().splitlines()
                if line.startswith("btime "))
    processes = []
    for entry in Path("/proc").iterdir():
        if not entry.name.isdigit():
            continue
        try:
            argv = (entry / "cmdline").read_bytes().decode("utf-8", "replace").split("\0")
            # Field 22 (starttime) counts from after the parenthesised command name.
            fields = (entry / "stat").read_text().rsplit(")", 1)[1].split()
        except OSError:
            continue
        argv = [value for value in argv if value]
        if argv:
            processes.append({"pid": int(entry.name), "started": boot + int(fields[19]) / ticks, "argv": argv})
    return processes


def arguments(process):
    if isinstance(process.get("argv"), list):
        return [str(value) for value in process["argv"]]
    return [plain or quoted for quoted, plain in TOKEN.findall(process.get("cmdline") or "")]


def option(argv, name):
    for index, value in enumerate(argv[:-1]):
        if value == name:
            return argv[index + 1]
    return None


def script_index(argv, name):
    for index, value in enumerate(argv):
        if value.replace("\\", "/").rsplit("/", 1)[-1].lower() == name:
            return index
    return None


def normalized(path):
    path = path.replace("\\", "/").rstrip("/")
    return path.lower() if os.name == "nt" or re.match(r"^[A-Za-z]:/", path) else path


def overlaps(first, second):
    return first == second or first.startswith(second + "/") or second.startswith(first + "/")


def classify(processes, now, min_age_hours):
    """Return (stale, kept) brokers; kept entries carry the reason in Japanese."""
    brokers, companions = [], []
    for process in processes:
        argv = arguments(process)
        broker = script_index(argv, BROKER)
        if broker is not None and "serve" in argv[broker + 1:]:
            brokers.append((process, argv))
        elif script_index(argv, COMPANION) is not None:
            companions.append(option(argv, "--cwd"))
    stale, kept = [], []
    for process, argv in brokers:
        cwd = option(argv, "--cwd")
        item = {"pid": int(process["pid"]), "started": float(process["started"]), "cwd": cwd,
                "pid_file": option(argv, "--pid-file")}
        if now - item["started"] < min_age_hours * 3600:
            kept.append((item, "起動から {} 時間たっていない".format(min_age_hours)))
        elif cwd is None:
            kept.append((item, "--cwd が無く、どのワークスペースのものか分からない"))
        elif any(other is None or overlaps(normalized(cwd), normalized(other)) for other in companions):
            kept.append((item, "同じワークスペースの codex-companion が動いている"))
        else:
            stale.append(item)
    return stale, kept


def alive(pid):
    if os.name != "nt":
        try:
            # A zombie has exited; it only waits for its parent to reap it.
            return Path("/proc", str(pid), "stat").read_text().rsplit(")", 1)[1].split()[0] != "Z"
        except OSError:
            return False
    # os.kill on Windows terminates the process, so ask for its exit code instead.
    import ctypes
    kernel32 = ctypes.windll.kernel32
    handle = kernel32.OpenProcess(0x1000, False, pid)  # PROCESS_QUERY_LIMITED_INFORMATION
    if not handle:
        return False
    try:
        code = ctypes.c_ulong()
        return bool(kernel32.GetExitCodeProcess(handle, ctypes.byref(code))) and code.value == 259  # STILL_ACTIVE
    finally:
        kernel32.CloseHandle(handle)


def kill(pid):
    if os.name == "nt":
        # The same tree kill as the plugin's terminateProcessTree. Its exit code is
        # not 0 when part of the tree is already gone, so the broker itself is checked.
        subprocess.run(["taskkill", "/PID", str(pid), "/T", "/F"], capture_output=True, timeout=20, **no_window())
    else:
        try:
            # Brokers are spawned detached, so each leads its own process group.
            if os.getpgid(pid) == pid:
                os.killpg(pid, signal.SIGTERM)
            else:
                os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            return False
    for unused in range(20):
        if not alive(pid):
            return True
        time.sleep(0.1)
    return False


def remove_session_files(pid_file):
    # Mirror the plugin's teardownBrokerSession: pid, log, then the empty cxc-* directory.
    if not pid_file:
        return
    directory = Path(pid_file).parent
    if not directory.name.startswith("cxc-"):
        return
    for name in ("broker.pid", "broker.log"):
        try:
            (directory / name).unlink()
        except OSError:
            pass
    try:
        directory.rmdir()
    except OSError:
        pass


def stamp(seconds):
    return datetime.fromtimestamp(seconds).strftime("%Y-%m-%d %H:%M")


def append_log(lines):
    path = config_directory() / "hooks" / LOG_NAME
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.stat().st_size > LOG_LIMIT:
        os.replace(str(path), str(path.with_name(LOG_NAME + ".1")))
    with path.open("a", encoding="utf-8") as stream:
        stream.writelines(line + "\n" for line in lines)


def load(path):
    processes = json.loads(Path(path).read_text(encoding="utf-8"))
    return processes if isinstance(processes, list) else [processes]


def run(args):
    if args.processes_from:
        processes = load(args.processes_from)
    elif os.name == "nt":
        processes = windows_processes()
    else:
        processes = linux_processes()
    # ConvertTo-Json writes a single process as an object, not a list.
    if isinstance(processes, dict):
        processes = [processes]
    stale, kept = classify(processes, time.time(), args.min_age_hours)
    if args.dry_run:
        for item in stale:
            print("消す: PID {pid}（起動 {started}、{cwd}）".format(
                pid=item["pid"], started=stamp(item["started"]), cwd=item["cwd"]))
        for item, reason in kept:
            print("残す: PID {pid}（起動 {started}、{reason}）".format(
                pid=item["pid"], started=stamp(item["started"]), reason=reason))
        print("消すもの {} 個、残すもの {} 個。何も変更していません。".format(len(stale), len(kept)))
        return 0
    lines = []
    for item in stale:
        killed = kill(item["pid"])
        if killed:
            remove_session_files(item["pid_file"])
        lines.append("{now}\t{result}\tpid={pid}\tstarted={started}\tcwd={cwd}".format(
            now=datetime.now().isoformat(timespec="seconds"), result="killed" if killed else "failed",
            pid=item["pid"], started=stamp(item["started"]), cwd=item["cwd"]))
    if lines:
        append_log(lines)
    return 0


def main():
    parser = argparse.ArgumentParser(description="Claude Code の Codex プラグインが残した古い broker を片付けます。")
    parser.add_argument("--dry-run", action="store_true", help="何も止めず、消すものと残すものを表示します。")
    parser.add_argument("--min-age-hours", type=float, default=2, help="これより新しい broker は残します（既定 2）。")
    parser.add_argument("--processes-from", metavar="FILE", help="試験用: プロセスの一覧を JSON から読みます（--dry-run と一緒に使う）。")
    args = parser.parse_args()
    if args.processes_from and not args.dry_run:
        parser.error("--processes-from は --dry-run と一緒に使ってください。")
    try:
        return run(args)
    except Exception as error:
        if args.dry_run:
            print("中断: {}".format(error), file=sys.stderr)
            return 1
        # Never hold up or fail the session start.
        try:
            append_log(["{}\terror\t{}".format(datetime.now().isoformat(timespec="seconds"), error)])
        except Exception:
            pass
        return 0


if __name__ == "__main__":
    sys.exit(main())
