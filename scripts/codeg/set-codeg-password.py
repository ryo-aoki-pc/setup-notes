#!/usr/bin/python3
"""Codeg の共有パスワードを本人の端末で設定する。既存秘密の本文は読まない。"""

import argparse
import fcntl
import getpass
import http.client
import json
import math
import os
import pwd
import secrets
import signal
import stat
import subprocess
import sys
import time
import warnings
from dataclasses import dataclass
from pathlib import Path

SERVICE = "codeg-server.service"
MACHINE = pwd.getpwuid(os.getuid()).pw_name + "@.host"
TOKEN_NAME = "token.env"
PORT = 3080
TIMEOUT = 3


class SafeError(Exception):
    """秘密や外部コマンドの出力を含まない利用者向けエラー。"""


class OperationCancelled(Exception):
    """終了要求を、復帰可能な中止として扱う。"""


def terminate_safely(signum, frame):
    raise OperationCancelled()


def validate_password(value):
    if not 32 <= len(value) <= 512 or any(not 0x21 <= ord(c) <= 0x7E for c in value):
        raise SafeError("パスワードは空白を除く ASCII 文字を 32〜512 文字で入力してください。")


def environment_line(value):
    validate_password(value)
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return ('CODEG_TOKEN="' + escaped + '"\n').encode("ascii")


def check_owner_mode(info, mode, kind):
    predicate = stat.S_ISDIR if kind == "directory" else stat.S_ISREG
    if not predicate(info.st_mode) or info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) != mode:
        raise SafeError("設定の所有者・種類・アクセス権が安全条件を満たしていません。")


def open_settings_directory(path):
    before = os.stat(path, follow_symlinks=False)
    check_owner_mode(before, 0o700, "directory")
    fd = os.open(path, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        after = os.fstat(fd)
        check_owner_mode(after, 0o700, "directory")
        if (before.st_dev, before.st_ino) != (after.st_dev, after.st_ino):
            raise SafeError("設定ディレクトリが確認中に変わりました。")
    except BaseException:
        os.close(fd)
        raise
    return fd


def file_metadata(directory, name=TOKEN_NAME):
    info = os.stat(name, dir_fd=directory, follow_symlinks=False)
    check_owner_mode(info, 0o600, "file")
    return info


def acquire_change_lock(directory):
    name = ".password-change.lock"
    try:
        fd = os.open(name, os.O_RDWR | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600, dir_fd=directory)
    except FileExistsError:
        before = file_metadata(directory, name)
        fd = os.open(name, os.O_RDWR | os.O_NOFOLLOW, dir_fd=directory)
        after = os.fstat(fd)
        if (before.st_dev, before.st_ino) != (after.st_dev, after.st_ino):
            os.close(fd)
            raise SafeError("変更ロックが確認中に変わりました。")
    try:
        check_owner_mode(os.fstat(fd), 0o600, "file")
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BaseException:
        os.close(fd)
        raise SafeError("別のパスワード変更が進行中か、安全な変更ロックを取得できません。") from None
    return fd


def same_file(before, after):
    return (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns) == (
        after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns
    )


def write_pending(directory, value):
    name = ".token.env.pending-" + secrets.token_hex(16)
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW
    fd = os.open(name, flags, 0o600, dir_fd=directory)
    try:
        check_owner_mode(os.fstat(fd), 0o600, "file")
        data = environment_line(value)
        view = memoryview(data)
        while view:
            written = os.write(fd, view)
            if written <= 0:
                raise SafeError("新しい設定を書き込めませんでした。")
            view = view[written:]
        os.fsync(fd)
    except BaseException:
        os.unlink(name, dir_fd=directory)
        raise
    finally:
        os.close(fd)
    os.fsync(directory)
    return name


def make_backup(directory, original):
    if not same_file(original, file_metadata(directory)):
        raise SafeError("既存設定が確認中に変わりました。")
    name = ".token.env.backup-" + secrets.token_hex(16)
    os.link(TOKEN_NAME, name, src_dir_fd=directory, dst_dir_fd=directory, follow_symlinks=False)
    try:
        if not same_file(original, file_metadata(directory, name)):
            raise SafeError("退避した設定の同一性を確認できませんでした。")
        os.fsync(directory)
    except BaseException:
        os.unlink(name, dir_fd=directory)
        raise
    return name


def systemctl(*arguments):
    try:
        result = subprocess.run(
            ["systemctl", "--user", "--machine=" + MACHINE, *arguments],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            text=True, timeout=30, check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        raise SafeError("Codeg のユーザーサービスに接続できませんでした。") from None
    if result.returncode:
        raise SafeError("Codeg のユーザーサービス操作に失敗しました。")
    return result.stdout.strip()


def validate_service_configuration():
    home = Path(pwd.getpwuid(os.getuid()).pw_dir)
    expected_file = str(home / ".config/codeg-server" / TOKEN_NAME) + " (ignore_errors=no)"
    if systemctl("show", SERVICE, "--property=EnvironmentFiles", "--value") != expected_file:
        raise SafeError("Codeg のサービスが予定した設定ファイルを参照していません。")
    if systemctl("show", SERVICE, "--property=StandardError", "--value") != "null":
        raise SafeError("Codeg 起動時の秘密出力が破棄される構成を確認できません。")


def service_information():
    properties = "ActiveState,SubState,MainPID,ControlGroup"
    result = systemctl("show", SERVICE, "--property=" + properties)
    values = dict(line.split("=", 1) for line in result.splitlines() if "=" in line)
    if values.get("ActiveState") != "active" or values.get("SubState") != "running":
        raise SafeError("Codeg の専用サービスが running ではありません。")
    try:
        pid = int(values.get("MainPID", "0"))
    except ValueError:
        raise SafeError("Codeg のプロセスを確認できませんでした。") from None
    group = values.get("ControlGroup", "")
    if pid <= 0 or not group.startswith("/"):
        raise SafeError("Codeg の専用サービス所属を確認できませんでした。")
    return pid, group


@dataclass(frozen=True)
class Listener:
    pid: int
    started: int
    executable: str
    executable_device: int
    executable_inode: int
    socket_inode: str


def process_metadata(pid, service_group, expected_executable):
    proc = Path("/proc") / str(pid)
    if proc.stat().st_uid != os.getuid():
        raise SafeError("Codeg のプロセス所有者を確認できませんでした。")
    with open(proc / "cgroup", encoding="ascii") as stream:
        groups = [line.rstrip("\n").split(":", 2)[2] for line in stream]
    if not any(group == service_group or group.startswith(service_group + "/") for group in groups):
        raise SafeError("Codeg プロセスのサービス所属を確認できませんでした。")
    with open(proc / "stat", encoding="ascii") as stream:
        fields = stream.read().rsplit(")", 1)[1].split()
    executable = os.readlink(proc / "exe")
    executable_stat = os.stat(proc / "exe")
    if executable != str(expected_executable):
        raise SafeError("Codeg の実行ファイルが想定したパスと一致しません。")
    return int(fields[19]), executable, executable_stat.st_dev, executable_stat.st_ino


def listener_identity(expected_executable):
    supervisor, service_group = service_information()
    process_metadata(supervisor, service_group, expected_executable)
    sockets = []
    for path in ("/proc/net/tcp", "/proc/net/tcp6"):
        with open(path, encoding="ascii") as stream:
            for line in stream:
                columns = line.split()
                if len(columns) < 10 or columns[3] != "0A":
                    continue
                address, hexadecimal_port = columns[1].split(":")
                if int(hexadecimal_port, 16) == PORT:
                    sockets.append((path, address, columns[9]))
    if len(sockets) != 1 or sockets[0][:2] != ("/proc/net/tcp", "0100007F"):
        raise SafeError("3080 番の待受が単一の 127.0.0.1 に限定されていません。")
    socket_inode = sockets[0][2]
    group_directory = Path("/sys/fs/cgroup") / service_group.lstrip("/")
    candidates = set()
    for process_file in group_directory.rglob("cgroup.procs"):
        with open(process_file, encoding="ascii") as stream:
            candidates.update(int(line) for line in stream if line.strip())
    owners = []
    for pid in candidates:
        try:
            for fd in (Path("/proc") / str(pid) / "fd").iterdir():
                try:
                    if os.readlink(fd) == "socket:[" + socket_inode + "]":
                        owners.append(pid)
                        break
                except FileNotFoundError:
                    continue
        except FileNotFoundError:
            continue
    if len(owners) != 1:
        raise SafeError("待受を所有する Codeg 専用サービスの worker を一意に確認できません。")
    pid = owners[0]
    started, executable, device, inode = process_metadata(pid, service_group, expected_executable)
    return Listener(pid, started, executable, device, inode, socket_inode)


def health(expected_executable, fixed_identity, token=None, expected_status=401):
    before = listener_identity(expected_executable)
    if before != fixed_identity:
        raise SafeError("検証前に Codeg の待受プロセスが変わりました。")
    headers = {"Content-Type": "application/json"}
    if token is not None:
        headers["Authorization"] = "Bearer " + token
    connection = http.client.HTTPConnection("127.0.0.1", PORT, timeout=TIMEOUT)
    try:
        connection.request("POST", "/api/health", body="{}", headers=headers)
        response = connection.getresponse()
        status_code = response.status
        valid_json = True
        if expected_status == 200:
            body = response.read(8193)
            try:
                valid_json = len(body) <= 8192 and json.loads(body).get("status") == "ok"
            except (ValueError, AttributeError, UnicodeDecodeError):
                valid_json = False
        response.close()
    except (OSError, http.client.HTTPException):
        raise SafeError("Codeg の health 応答を確認できませんでした。") from None
    finally:
        connection.close()
    if listener_identity(expected_executable) != fixed_identity:
        raise SafeError("検証中に Codeg の待受プロセスが変わりました。")
    if status_code != expected_status or not valid_json:
        raise SafeError("Codeg の認証応答が期待した結果と一致しません。")


def start_service(expected_executable):
    validate_service_configuration()
    ticks_per_second = os.sysconf("SC_CLK_TCK")
    request_tick = math.floor(time.clock_gettime(time.CLOCK_BOOTTIME) * ticks_per_second)
    # プロセス開始時刻のカーネル精度を越えてから起動し、旧プロセスを除外する。
    while math.floor(time.clock_gettime(time.CLOCK_BOOTTIME) * ticks_per_second) <= request_tick:
        time.sleep(1 / ticks_per_second)
    systemctl("start", SERVICE)
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        try:
            identity = listener_identity(expected_executable)
            if identity.started > request_tick:
                return identity
        except (SafeError, OSError, ValueError, IndexError):
            pass
        time.sleep(0.1)
    raise SafeError("新しく起動した Codeg の待受を確認できませんでした。")


def stop_service():
    systemctl("stop", SERVICE)
    pid = systemctl("show", SERVICE, "--property=MainPID", "--value")
    if pid != "0":
        raise SafeError("Codeg の停止を確認できませんでした。")


def remove_if_present(directory, name):
    if name is not None:
        try:
            os.unlink(name, dir_fd=directory)
        except FileNotFoundError:
            pass


def update_password(directory, original, expected_executable, value):
    pending = None
    backup = None
    pending_metadata = None
    stop_requested = False
    succeeded = False
    recovery_known = False
    try:
        pending = write_pending(directory, value)
        pending_metadata = file_metadata(directory, pending)
        backup = make_backup(directory, original)
        stop_requested = True
        stop_service()
        if not same_file(original, file_metadata(directory)):
            raise SafeError("既存設定が更新直前に変わりました。")
        os.replace(pending, TOKEN_NAME, src_dir_fd=directory, dst_dir_fd=directory)
        pending = None
        os.fsync(directory)
        file_metadata(directory)
        identity = start_service(expected_executable)
        health(expected_executable, identity, value, 200)
        health(expected_executable, identity)
        incorrect = secrets.token_urlsafe(48)
        while incorrect == value:
            incorrect = secrets.token_urlsafe(48)
        health(expected_executable, identity, incorrect)
        succeeded = True
    except BaseException:
        print("設定変更または検証に失敗しました。旧設定への復帰を確認します。", file=sys.stderr)
        try:
            if stop_requested:
                stop_service()
            current = file_metadata(directory)
            if pending_metadata is not None and same_file(pending_metadata, current):
                if backup is None or not same_file(original, file_metadata(directory, backup)):
                    raise SafeError("旧設定の退避を確認できませんでした。")
                os.replace(backup, TOKEN_NAME, src_dir_fd=directory, dst_dir_fd=directory)
                # 同じ inode 同士の rename は退避名を残すことがある。
                remove_if_present(directory, backup)
                backup = None
                os.fsync(directory)
            elif not same_file(original, current):
                raise SafeError("既存設定が確認中に変わりました。")
            if stop_requested:
                restored = start_service(expected_executable)
                health(expected_executable, restored)
            recovery_known = True
            print("旧設定へ戻しました。パスワード変更は完了していません。", file=sys.stderr)
        except BaseException:
            print("結果: 不明。旧設定への復帰または Codeg の再起動を確認できませんでした。", file=sys.stderr)
            if backup is not None:
                print("旧設定の退避ファイル名: " + backup, file=sys.stderr)
            return 2
        return 1
    finally:
        remove_if_present(directory, pending)
        if recovery_known:
            remove_if_present(directory, backup)
        os.fsync(directory)
    if succeeded:
        print("パスワードを設定しました。認証 200、未認証 401、誤った値 401 を同じ Codeg プロセスで確認しました。")
        print("HTTPS 画面で、本人が入力した新しいパスワードを使って再ログインしてください。")
        print("旧設定の退避ファイル名: " + backup)
    return 0


def main():
    parser = argparse.ArgumentParser(description="Codeg の共有パスワードを本人の端末で設定します。")
    parser.add_argument("--check", action="store_true", help="既存秘密を読まず、安全条件と稼働状態だけを確認します。")
    arguments = parser.parse_args()
    if os.getuid() == 0:
        raise SafeError("Codeg を起動したユーザー本人の端末で実行してください。sudo は使用しません。")
    home = Path(pwd.getpwuid(os.getuid()).pw_dir)
    expected_executable = home / ".local/opt/codeg-server/codeg-server"
    directory = open_settings_directory(home / ".config/codeg-server")
    change_lock = None
    try:
        if not arguments.check:
            change_lock = acquire_change_lock(directory)
        original = file_metadata(directory)
        validate_service_configuration()
        if systemctl("is-enabled", SERVICE) != "enabled":
            raise SafeError("Codeg のユーザーサービスが enabled ではありません。")
        identity = listener_identity(expected_executable)
        health(expected_executable, identity)
        if arguments.check:
            print("確認済み: 設定 metadata 安全、Codeg enabled・active、127.0.0.1:3080 のサービス所属・PID・開始時刻・実行ファイル一致、未認証 health 401。")
            return 0
        if not sys.stdin.isatty():
            raise SafeError("パスワード入力には本人の対話端末が必要です。")
        with warnings.catch_warnings():
            warnings.simplefilter("error", getpass.GetPassWarning)
            value = getpass.getpass("新しい共有パスワード（32〜512 文字、画面には表示しません）: ")
            validate_password(value)
            confirmation = getpass.getpass("もう一度入力してください: ")
        if value != confirmation:
            raise SafeError("2 回の入力が一致しません。設定は変更していません。")
        confirmation = None
        validate_service_configuration()
        return update_password(directory, original, expected_executable, value)
    finally:
        if change_lock is not None:
            os.close(change_lock)
        os.close(directory)


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, terminate_safely)
    try:
        exit_code = main()
    except SafeError as error:
        print(str(error), file=sys.stderr)
        exit_code = 1
    except (KeyboardInterrupt, OperationCancelled, EOFError, getpass.GetPassWarning):
        print("入力を中止しました。パスワードは出力していません。", file=sys.stderr)
        exit_code = 1
    except Exception:
        print("安全条件または稼働状態を確認できませんでした。", file=sys.stderr)
        exit_code = 1
    sys.exit(exit_code)
