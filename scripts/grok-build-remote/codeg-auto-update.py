#!/usr/bin/python3 -I
"""Codeg を最新の安定版へ更新する。秘密の設定ファイルは開かない。

終了: 0 最新・更新済み・停止中・手動復元済み / 1 中断・保留 / 2 復元して保留 / 3 復元不能・処理途中。
"""

import contextlib
from datetime import datetime, timezone
import fcntl
import hashlib
import http.client
import ipaddress
import json
import os
from pathlib import Path, PurePosixPath
import platform
import pwd
import re
import secrets
import shlex
import shutil
import signal
import socket
import stat
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.parse
import urllib.request
from dataclasses import dataclass

SERVICE = "codeg-server.service"
API = "https://api.github.com/repos/spacering-net/codeg/releases?per_page=50"
RECOVERY = "docs/extra/grok-build-remote.md の「自動更新の控えから前の版と DB に戻す」"
VERSION_TIMEOUT = 10
HEALTH_TIMEOUT = 120
STABLE_SECONDS = 30
LOG_PATH = None


class Failure(Exception):
    """外部コマンドの出力や秘密を含まない失敗。"""


class VersionTimeout(Failure):
    pass


@dataclass(frozen=True)
class Paths:
    home: Path
    install: Path
    candidate: Path
    data: Path
    settings: Path
    state: Path
    unit: Path

    @classmethod
    def for_home(cls, home):
        home = Path(home)
        return cls(home, home / ".local/opt/codeg-server", home / ".local/opt/.codeg-server.new",
                   home / ".local/share/codeg", home / ".config/codeg-server",
                   home / ".local/state/codeg-auto-update",
                   home / ".config/systemd/user/codeg-server.service")

    @property
    def backups(self):
        return self.state / "backups"


def get_paths():
    return Paths.for_home(Path.home())


def append_log(path, message):
    if path.is_symlink():
        raise Failure("ログのファイルがリンクになっている")
    if path.exists() and path.stat().st_size > 2**20:
        previous = path.with_name(path.name + ".1")
        previous.unlink(missing_ok=True)
        path.rename(previous)
    stamp = datetime.now(timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")
    with path.open("a", encoding="utf-8", newline="\n") as stream:
        stream.write(stamp + " " + message + "\n")
        stream.flush()
    path.chmod(0o600)


def log(message):
    message = str(message).replace("\r", " ").replace("\n", " ")
    print(message, flush=True)
    if LOG_PATH is not None:
        try:
            append_log(LOG_PATH, message)
        except (OSError, Failure):
            print("記録: 専用ログへ書き込めないため、状態のディレクトリを確かめる", flush=True)


def parse(version):
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
        raise Failure("版の形式が x.y.z ではない")
    return tuple(map(int, version.split(".")))


def asset_name():
    architecture = {"aarch64": "arm64", "arm64": "arm64", "x86_64": "x64"}.get(platform.machine())
    if architecture is None:
        raise Failure("この CPU の配布物は扱っていない")
    return "codeg-server-linux-" + architecture


class HttpsRedirectHandler(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, response, code, message, headers, new_url):
        if urllib.parse.urlsplit(new_url).scheme.lower() != "https":
            raise Failure("HTTPS 以外へのリダイレクトは受け入れない")
        return super().redirect_request(request, response, code, message, headers, new_url)


def open_https(request, timeout):
    if urllib.parse.urlsplit(request.full_url).scheme.lower() != "https":
        raise Failure("取得先の URL が HTTPS ではない")
    response = urllib.request.build_opener(HttpsRedirectHandler()).open(request, timeout=timeout)
    try:
        if urllib.parse.urlsplit(response.geturl()).scheme.lower() != "https":
            raise Failure("取得先の最終 URL が HTTPS ではない")
    except BaseException:
        response.close()
        raise
    return response


def fetch_releases():
    request = urllib.request.Request(API, headers={"User-Agent": "setup-notes-codeg-auto-update",
                                                 "Accept": "application/vnd.github+json"})
    with open_https(request, timeout=30) as response:
        return json.load(response)


def select_release(releases, asset):
    candidates = []
    for release in releases:
        tag = release.get("tag_name", "")
        if not re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", tag):
            continue
        if release.get("draft", True) or release.get("prerelease", True):
            continue
        assets = {entry["name"]: entry for entry in release.get("assets", [])}
        archive = asset + ".tar.gz"
        if archive in assets and archive + ".sha256" in assets:
            candidates.append((parse(tag[1:]), tag[1:], assets[archive], assets[archive + ".sha256"]))
    if not candidates:
        raise Failure("必要な配布物がそろった安定版が見つからない")
    _, version, archive, checksum = max(candidates, key=lambda entry: entry[0])
    return version, archive, checksum


def download(url, destination):
    request = urllib.request.Request(url, headers={"User-Agent": "setup-notes-codeg-auto-update"})
    with open_https(request, timeout=60) as response, destination.open("xb") as stream:
        shutil.copyfileobj(response, stream)
        stream.flush()
        os.fsync(stream.fileno())


def verify_archive(archive, checksum, metadata):
    text = checksum.read_text(encoding="ascii").strip()
    match = re.fullmatch(r"([0-9a-fA-F]{64})[ \t]+\*?([^\r\n]+)", text)
    if not match or match[2] != archive.name:
        raise Failure("SHA-256 ファイルの形式か配布物の名前が一致しない")
    with archive.open("rb") as stream:
        actual = hashlib.file_digest(stream, "sha256").hexdigest()
    if actual != match[1].lower():
        raise Failure("配布物と .sha256 の SHA-256 が一致しない")
    digest = metadata.get("digest")
    if digest is None or digest == "":
        log("API に digest が無いため、.sha256 だけで照合した")
    elif not re.fullmatch(r"sha256:[0-9a-fA-F]{64}", digest) or actual != digest[7:].lower():
        raise Failure("配布物と API の digest が一致しない")


def extract_archive(archive, destination, asset):
    # 全項目を先に調べ、リンクなどの後続項目で検査をすり抜けさせない。
    destination.mkdir(mode=0o700)
    with tarfile.open(archive, "r:gz") as bundle:
        members = bundle.getmembers()
        seen = set()
        for member in members:
            path = PurePosixPath(member.name)
            if (path.is_absolute() or ".." in path.parts or "\\" in member.name
                    or not path.parts or path.parts[0] != asset
                    or not (member.isdir() or member.isreg()) or path in seen):
                raise Failure("配布物に安全でないパス・種類・重複がある")
            seen.add(path)
        bundle.extractall(destination, members=members, filter="data")
    extracted = destination / asset
    validate_install(extracted, exact=False)
    return extracted


def validate_install(directory, exact=True):
    if directory.is_symlink() or not directory.is_dir():
        raise Failure("Codeg の本体のディレクトリが無いかリンクになっている")
    entries = {path.name for path in directory.iterdir()}
    required = {"codeg-server", "codeg-mcp", "web"}
    if not required <= entries or (exact and entries != required):
        raise Failure("Codeg の本体は codeg-server・codeg-mcp・web の 3 つに揃えてから実行する")
    for name in ("codeg-server", "codeg-mcp", "web"):
        path = directory / name
        if path.is_symlink() or (not path.is_dir() if name == "web" else not path.is_file()):
            raise Failure("Codeg の本体の種類が一致しない")
    if not os.access(directory / "codeg-server", os.X_OK) or not os.access(directory / "codeg-mcp", os.X_OK):
        raise Failure("Codeg の本体に実行権限が無い")


def check_self_update(paths):
    if not paths.install.exists():
        return
    if any(path.name == ".codeg-upgrade-staged" or path.name.endswith(".bak")
           for path in paths.install.iterdir()):
        raise Failure("画面の自己更新の目印がある。自己更新を片付けてから実行する")


def unused_port():
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        return listener.getsockname()[1]


def read_version(binary):
    # --help もサーバーを起動する版がある。引数は --version だけに固定する。
    with tempfile.TemporaryDirectory(prefix="codeg-version-") as temporary:
        environment = {key: value for key, value in os.environ.items()
                       if not key.startswith(("CODEG_", "XDG_"))}
        environment.update({key: temporary for key in ("HOME", "TMPDIR", "XDG_CONFIG_HOME", "XDG_DATA_HOME",
                                                      "XDG_STATE_HOME", "XDG_CACHE_HOME", "XDG_RUNTIME_DIR",
                                                      "CODEG_DATA_DIR", "CODEG_HOME", "CODEG_STATIC_DIR")})
        environment.update(CODEG_HOST="127.0.0.1", CODEG_PORT=str(unused_port()),
                           CODEG_TOKEN=secrets.token_urlsafe(48), CODEG_BRIDGE_PORTS="off", CODEG_BROWSER_TUNNEL="off")
        with tempfile.TemporaryFile() as output:
            process = subprocess.Popen([str(binary), "--version"], env=environment, cwd=temporary,
                                       stdout=output, stderr=subprocess.DEVNULL, start_new_session=True)
            try:
                process.wait(timeout=VERSION_TIMEOUT)
            except subprocess.TimeoutExpired:
                with contextlib.suppress(ProcessLookupError):
                    os.killpg(process.pid, signal.SIGKILL)
                process.wait()
                raise VersionTimeout("本体の --version が 10 秒で終わらない") from None
            except BaseException:
                with contextlib.suppress(ProcessLookupError):
                    os.killpg(process.pid, signal.SIGKILL)
                process.wait()
                raise
            if process.returncode:
                raise Failure("本体の --version が失敗した")
            output.seek(0)
            text = output.read(4097).decode("ascii", errors="replace")
            versions = re.findall(r"^([0-9]+\.[0-9]+\.[0-9]+)$", text, re.M)
            if len(text) > 4096 or len(versions) != 1:
                raise Failure("本体の --version から版を一意に確認できない")
            return versions[0]


def systemctl(*arguments, check=True, timeout=120):
    command = ["systemctl", "--user"]
    result = subprocess.run([*command, *arguments], capture_output=True, text=True, timeout=timeout)
    if result.returncode and any(message in result.stderr for message in (
            "Failed to connect to user scope bus", "Failed to connect to bus")):
        username = pwd.getpwuid(os.getuid()).pw_name
        result = subprocess.run([*command, "--machine=" + username + "@.host", *arguments],
                                capture_output=True, text=True, timeout=timeout)
    if check and result.returncode:
        raise Failure("Codeg のユーザーサービスを操作できない")
    return result.stdout.strip()


def service_info():
    output = systemctl("show", SERVICE, "--property=ActiveState,NRestarts,MainPID,ControlGroup")
    values = dict(line.split("=", 1) for line in output.splitlines() if "=" in line)
    if not all(key in values for key in ("ActiveState", "NRestarts", "MainPID", "ControlGroup")):
        raise Failure("Codeg のサービスの状態が揃っていない")
    return values


def endpoints(unit):
    values = {"CODEG_HOST": [], "CODEG_PORT": []}
    for line in unit.read_text(encoding="utf-8").splitlines():
        if not line.startswith("Environment="):
            continue
        for entry in shlex.split(line.split("=", 1)[1]):
            key, separator, value = entry.partition("=")
            if separator and key in values:
                values[key].append(value)
    if any(len(entries) != 1 for entries in values.values()):
        raise Failure("サービスの CODEG_HOST と CODEG_PORT が 1 つずつではない")
    host = str(ipaddress.ip_address(values["CODEG_HOST"][0]))
    port = int(values["CODEG_PORT"][0])
    if not 1 <= port <= 65535:
        raise Failure("待ち受けのポートの範囲が正しくない")
    return host, port


def listening_sockets(host, port):
    sockets = []
    for name in ("tcp", "tcp6"):
        with open("/proc/net/" + name, encoding="ascii") as stream:
            for line in stream:
                columns = line.split()
                if len(columns) < 10 or columns[3] != "0A":
                    continue
                hexadecimal_address, hexadecimal_port = columns[1].split(":")
                if int(hexadecimal_port, 16) != port:
                    continue
                raw = bytes.fromhex(hexadecimal_address)
                if sys.byteorder == "little":
                    raw = b"".join(raw[index:index + 4][::-1] for index in range(0, len(raw), 4))
                sockets.append((ipaddress.ip_address(raw), columns[9]))
    return sockets


def port_free(host, port):
    return not listening_sockets(host, port)


def listener_identity(binary, host, port):
    info = service_info()
    if info["ActiveState"] != "active" or int(info["MainPID"]) <= 0:
        raise Failure("Codeg が active ではない")
    group = info["ControlGroup"]
    if not group.startswith("/") or group == "/":
        raise Failure("Codeg のサービス所属が確認できない")
    sockets = listening_sockets(host, port)
    if len(sockets) != 1 or sockets[0][0] != ipaddress.ip_address(host):
        raise Failure("Codeg の待ち受けが設定と一致しない")
    socket_inode = sockets[0][1]
    owners = []
    group_path = Path("/sys/fs/cgroup") / group.lstrip("/")
    candidates = set()
    for process_file in group_path.rglob("cgroup.procs"):
        candidates.update(map(int, process_file.read_text(encoding="ascii").split()))
    for pid in candidates:
        proc = Path("/proc") / str(pid)
        try:
            if any(os.readlink(fd) == "socket:[" + socket_inode + "]" for fd in (proc / "fd").iterdir()):
                owners.append(pid)
        except FileNotFoundError:
            continue
    if len(owners) != 1:
        raise Failure("Codeg の待ち受けプロセスを一意に確認できない")
    proc = Path("/proc") / str(owners[0])
    expected = binary.stat()
    actual = (proc / "exe").stat()
    if (proc.stat().st_uid != os.getuid() or os.readlink(proc / "exe") != str(binary)
            or (actual.st_dev, actual.st_ino) != (expected.st_dev, expected.st_ino)):
        raise Failure("待ち受けの実行ファイルが入れた本体と一致しない")
    started = int((proc / "stat").read_text(encoding="ascii").rsplit(")", 1)[1].split()[19])
    return owners[0], started, actual.st_dev, actual.st_ino, socket_inode


def http_status(host, port, path):
    # http.client は環境のプロキシや認証情報を使わない。
    connection = http.client.HTTPConnection(host, port, timeout=2)
    try:
        connection.request("GET", path)
        response = connection.getresponse()
        status_code = response.status
        response.close()
        return status_code
    finally:
        connection.close()


def stop(host, port):
    systemctl("stop", SERVICE)
    deadline = time.monotonic() + 60
    while time.monotonic() < deadline:
        if service_info()["ActiveState"] in ("inactive", "failed") and port_free(host, port):
            return
        time.sleep(1)
    raise Failure("Codeg のサービスと待ち受けが止まらない")


def start():
    systemctl("reset-failed", SERVICE, check=False)
    baseline = int(service_info()["NRestarts"])
    systemctl("start", SERVICE)
    return baseline


def check(binary, host, port, version, restarts):
    deadline = time.monotonic() + HEALTH_TIMEOUT
    stable_since = None
    fixed_identity = None
    while time.monotonic() < deadline:
        info = service_info()
        if int(info["NRestarts"]) != restarts or info["ActiveState"] == "failed":
            raise Failure("Codeg の確認中に再起動または起動失敗が起きた")
        try:
            identity = listener_identity(binary, host, port)
            valid = (info["ActiveState"] == "active" and http_status(host, port, "/") == 200
                     and http_status(host, port, "/api/version") == 401
                     and listener_identity(binary, host, port) == identity)
        except (Failure, OSError, ValueError, http.client.HTTPException):
            valid = False
        if valid:
            if stable_since is None or identity != fixed_identity:
                stable_since = time.monotonic()
                fixed_identity = identity
            if time.monotonic() - stable_since >= STABLE_SECONDS:
                if read_version(binary) != version:
                    raise Failure("入れた本体の版が予定した版と一致しない")
                final = service_info()
                if (final["ActiveState"] != "active" or int(final["NRestarts"]) != restarts
                        or listener_identity(binary, host, port) != fixed_identity):
                    raise Failure("版を確かめる間に Codeg が変わった")
                return
        else:
            stable_since = None
            fixed_identity = None
        time.sleep(1)
    raise Failure("120 秒待っても Codeg の正常な状態が 30 秒続かない")


def fsync_directory(path):
    descriptor = os.open(path, os.O_RDONLY | os.O_DIRECTORY)
    try:
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def write_state(path, text):
    descriptor, temporary = tempfile.mkstemp(prefix=".state-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
        fsync_directory(path.parent)
    finally:
        Path(temporary).unlink(missing_ok=True)


def progress(paths, stage, backup, old, new):
    write_state(paths.state / "in-progress", json.dumps({"stage": stage, "backup": str(backup),
                                                        "old": old, "new": new}, indent=2) + "\n")


def clear_progress(paths):
    (paths.state / "in-progress").unlink(missing_ok=True)
    fsync_directory(paths.state)


def database_files(directory):
    if directory.is_symlink() or not directory.is_dir():
        raise Failure("データベースの場所が通常のディレクトリではない")
    result = sorted(directory.glob("codeg.db*"))
    if any(path.is_symlink() or not path.is_file() for path in result):
        raise Failure("データベース一式に通常ファイル以外がある")
    return result


def copy_database(source, destination):
    destination.mkdir(mode=0o700, parents=True, exist_ok=True)
    for path in database_files(source):
        target = destination / path.name
        with path.open("rb") as original, target.open("xb") as copied:
            shutil.copyfileobj(original, copied)
            copied.flush()
            os.fsync(copied.fileno())
    fsync_directory(destination)


def check_capacity(paths):
    device = paths.backups.stat().st_dev
    if any(path.stat().st_dev != device for path in (paths.install, paths.data)):
        raise Failure("本体・DB と控えが同じファイルシステムに無い")
    size = sum(path.stat().st_size for path in database_files(paths.data))
    for directory in (paths.backups, paths.data):
        if shutil.disk_usage(directory).free < size * 2 + 2**30:
            raise Failure("空き容量が足りない。DB の 2 倍と 1 GiB が要る")


def timestamp():
    return time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())


def prune(paths):
    backups = sorted(path for path in paths.backups.iterdir()
                     if re.fullmatch(r"[0-9]{8}T[0-9]{6}Z-[0-9]+\.[0-9]+\.[0-9]+", path.name)
                     and path.is_dir() and not path.is_symlink()
                     and (path / "bin/codeg-server").is_file()
                     and (path / "bin/codeg-mcp").is_file()
                     and (path / "bin/web").is_dir() and (path / "db").is_dir())
    for backup in backups[:-2]:
        shutil.rmtree(backup)
        log("古い自動更新の控えを削除: " + backup.name)
    fsync_directory(paths.backups)


def remove_recovered_backup(backup):
    try:
        shutil.rmtree(backup)
    except OSError:
        log("旧版への復帰は確認済み。復元済みの控えの整理に失敗した: " + str(backup))


def rollback(paths, backup, old, latest, host, port):
    progress(paths, "rolling-back", backup, old, latest)
    stop(host, port)
    failed = paths.backups / ("failed-" + timestamp())
    failed.mkdir(mode=0o700)
    (failed / "db").mkdir(mode=0o700)
    os.rename(paths.install, failed / "bin")
    for path in database_files(paths.data):
        os.rename(path, failed / "db" / path.name)
    fsync_directory(paths.data)
    fsync_directory(failed / "db")
    # 復帰の確認にも失敗した場合に備え、元の bin/db の組は消費しない。
    with tempfile.TemporaryDirectory(prefix="restore-", dir=paths.state) as temporary:
        restored = Path(temporary) / "bin"
        shutil.copytree(backup / "bin", restored)
        os.rename(restored, paths.install)
    copy_database(backup / "db", paths.data)
    fsync_directory(paths.install.parent)
    restarts = start()
    check(paths.install / "codeg-server", host, port, old, restarts)
    clear_progress(paths)
    log("失敗した本体と DB の退避: " + str(failed))


def prepare(paths, version, archive_metadata, checksum_metadata, asset, work):
    archive = work / (asset + ".tar.gz")
    checksum = work / (archive.name + ".sha256")
    download(archive_metadata["browser_download_url"], archive)
    download(checksum_metadata["browser_download_url"], checksum)
    verify_archive(archive, checksum, archive_metadata)
    extracted = extract_archive(archive, paths.candidate, asset)
    for name in ("codeg-server", "codeg-mcp", "web"):
        os.rename(extracted / name, paths.candidate / name)
    shutil.rmtree(extracted)
    validate_install(paths.candidate)
    try:
        if read_version(paths.candidate / "codeg-server") != version:
            raise Failure("取得した本体の版が最新の安定版と一致しない")
    except (Failure, OSError, subprocess.SubprocessError):
        write_state(paths.state / "skip-version", version + "\n")
        raise
    check_capacity(paths)


def update(paths, old, latest, host, port):
    backup = paths.backups / (timestamp() + "-" + old)
    if backup.exists():
        raise Failure("同じ名前の控えが既にある。次の実行まで待つ")
    log("更新を始める: " + old + " → " + latest)
    try:
        stop(host, port)
    except (Exception, KeyboardInterrupt):
        try:
            restarts = start()
            check(paths.install / "codeg-server", host, port, old, restarts)
        except (Exception, KeyboardInterrupt):
            progress(paths, "restart-failed", backup, old, latest)
            log("停止後に元の Codeg を起動できない。" + RECOVERY + "で復旧する")
            return 3
        log("中断: 停止を確認できなかった。元の Codeg は起動済み")
        return 1
    try:
        progress(paths, "backing-up", backup, old, latest)
        backup.mkdir(mode=0o700)
        os.rename(paths.install, backup / "bin")
        fsync_directory(paths.install.parent)
        copy_database(paths.data, backup / "db")
        fsync_directory(backup)
        fsync_directory(paths.backups)
    except (Exception, KeyboardInterrupt):
        try:
            if (backup / "bin").exists() and not paths.install.exists():
                os.rename(backup / "bin", paths.install)
                fsync_directory(paths.install.parent)
            restarts = start()
            check(paths.install / "codeg-server", host, port, old, restarts)
            clear_progress(paths)
            if backup.exists():
                remove_recovered_backup(backup)
        except (Exception, KeyboardInterrupt):
            log("退避に失敗し、元の Codeg へ戻せない。" + RECOVERY + "で復旧する")
            return 3
        log("中断: 退避に失敗した。元の Codeg は起動済み")
        return 1
    try:
        progress(paths, "installing", backup, old, latest)
        os.rename(paths.candidate, paths.install)
        fsync_directory(paths.install.parent)
        progress(paths, "checking", backup, old, latest)
        restarts = start()
        check(paths.install / "codeg-server", host, port, latest, restarts)
    except (Exception, KeyboardInterrupt):
        log("更新の確認に失敗した。直前の本体と DB へ戻す")
        try:
            write_state(paths.state / "skip-version", latest + "\n")
            # 入れ替えの rename 自体が失敗したときも、同じ復旧経路に揃える。
            if not paths.install.exists():
                paths.install.mkdir(mode=0o700)
            rollback(paths, backup, old, latest, host, port)
        except (Exception, KeyboardInterrupt):
            log("戻せなかった。" + RECOVERY + "で復旧する。控え: " + str(backup))
            return 3
        log(old + " に戻し、" + latest + " を保留した")
        return 2
    (paths.state / "skip-version").unlink(missing_ok=True)
    clear_progress(paths)
    try:
        prune(paths)
    except (OSError, Failure, KeyboardInterrupt):
        log("更新は確認済み。古い控えの整理に失敗したため backups を確かめる")
    log("更新: " + old + " → " + latest)
    return 0


def secure_directory(path):
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    info = path.lstat()
    if not stat.S_ISDIR(info.st_mode) or info.st_uid != os.getuid():
        raise Failure("状態のディレクトリの所有者か種類が正しくない")
    path.chmod(0o700)


def acquire_lock(path):
    descriptor = os.open(path, os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW, 0o600)
    try:
        info = os.fstat(descriptor)
        if not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) != 0o600:
            raise Failure("変更ロックの所有者・種類・アクセス権が正しくない")
        fcntl.flock(descriptor, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BaseException:
        os.close(descriptor)
        raise Failure("別の更新またはパスワード変更が動いているか、ロックを取得できない") from None
    return descriptor


def acquire_password_lock(paths):
    info = paths.settings.lstat()
    if not stat.S_ISDIR(info.st_mode) or info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) != 0o700:
        raise Failure("パスワード設定のディレクトリが安全条件を満たさない")
    return acquire_lock(paths.settings / ".password-change.lock")


def run_locked(paths):
    if (paths.state / "in-progress").exists() or (paths.state / "in-progress").is_symlink():
        log("前の更新が途中で止まっている。何も変更しない。" + RECOVERY + "で復旧する")
        return 3
    validate_install(paths.install)
    check_self_update(paths)
    if paths.candidate.is_symlink():
        raise Failure("展開先 .codeg-server.new がリンクになっている。復旧の節を確かめる")
    if paths.candidate.exists():
        if not paths.candidate.is_dir():
            raise Failure("展開先 .codeg-server.new がディレクトリではない")
        # in-progress が無ければ、止める前の準備だけが残っている。
        shutil.rmtree(paths.candidate)
        log("前の準備で残った .codeg-server.new を片付けた")
    host, port = endpoints(paths.unit)
    current = read_version(paths.install / "codeg-server")
    parse(current)
    asset = asset_name()
    latest, archive, checksum = select_release(fetch_releases(), asset)
    skip = paths.state / "skip-version"
    if skip.is_symlink():
        raise Failure("保留ファイルがリンクになっている")
    held = skip.read_text(encoding="ascii").strip() if skip.exists() else ""
    if held:
        parse(held)
        if parse(held) <= parse(current):
            skip.unlink()
            fsync_directory(paths.state)
            held = ""
    if parse(latest) <= parse(current):
        log("最新版 " + current + " を使用中")
        return 0
    if latest == held:
        log("保留中: " + latest + "。skip-version を消すと次の実行で試し直す")
        return 1
    state = service_info()["ActiveState"]
    if state == "inactive":
        log("Codeg が止まっているので更新しない")
        return 0
    if state != "active":
        raise Failure("Codeg が active ではない")
    secure_directory(paths.backups)
    work = Path(tempfile.mkdtemp(prefix="download-", dir=paths.state))
    try:
        prepare(paths, latest, archive, checksum, asset, work)
        if service_info()["ActiveState"] != "active":
            raise Failure("準備中に Codeg の状態が変わった")
        return update(paths, current, latest, host, port)
    finally:
        for temporary in (paths.candidate, work):
            try:
                if temporary.exists() and not temporary.is_symlink():
                    shutil.rmtree(temporary)
            except (OSError, Failure, KeyboardInterrupt):
                log("作業用の展開物を片付けられないため、次の実行前に状態を確かめる: " + str(temporary))



@dataclass(frozen=True)
class RestorePlan:
    backup: Path
    source_bin: Path
    version: str
    hold: str
    keep_database: bool
    displaced: Path
    host: str
    port: int


def validate_tree(directory):
    if directory.is_symlink() or not directory.is_dir():
        raise Failure("復元する本体の場所が通常のディレクトリではない")
    for path in directory.rglob("*"):
        if path.is_symlink() or not (path.is_file() or path.is_dir()):
            raise Failure("復元する本体にリンクか通常ファイル以外がある")


def complete_install(directory):
    try:
        validate_install(directory)
        validate_tree(directory)
        return True
    except (Failure, OSError):
        return False


def plan_restore(paths, name, hold):
    if not re.fullmatch(r"[0-9]{8}T[0-9]{6}Z-[0-9]+\.[0-9]+\.[0-9]+", name):
        raise Failure("控えは backups 直下の UTC日時-x.y.z の名前で指定する")
    parse(hold)
    version = name.rsplit("-", 1)[1]
    backup = paths.backups / name
    if (paths.backups.is_symlink() or not paths.backups.is_dir() or backup.is_symlink()
            or backup.resolve().parent != paths.backups.resolve()):
        raise Failure("控えの場所が専用のディレクトリではない")
    if paths.install.is_symlink() or (paths.install.exists() and not paths.install.is_dir()):
        raise Failure("現在の本体の場所が通常のディレクトリではない")
    check_self_update(paths)
    if paths.install.exists():
        for path in paths.install.iterdir():
            if path.name not in ("codeg-server", "codeg-mcp", "web") or path.is_symlink():
                raise Failure("現在の本体に想定外のファイルかリンクがある")
            if not (path.is_dir() if path.name == "web" else path.is_file()):
                raise Failure("現在の本体の種類が一致しない")
    if paths.candidate.is_symlink() or (paths.candidate.exists() and not paths.candidate.is_dir()):
        raise Failure("残った展開先が通常のディレクトリではない")
    if (paths.state / "skip-version").is_symlink():
        raise Failure("保留ファイルがリンクになっている")
    marker = paths.state / "in-progress"
    if marker.is_symlink():
        raise Failure("途中の目印がリンクになっている")
    information = json.loads(marker.read_text(encoding="utf-8")) if marker.exists() else None
    if information is not None:
        if not isinstance(information, dict) or information.get("stage") not in (
                "backing-up", "installing", "checking", "rolling-back", "restart-failed"):
            raise Failure("途中の段階が不明なため、控えを保持して確認する")
        recorded_backup = Path(information.get("backup", ""))
        if (not recorded_backup.is_absolute() or recorded_backup.resolve() != backup.resolve()
                or information.get("old") != version or information.get("new") != hold):
            raise Failure("途中の控え・旧版・更新先が指定した値と一致しない")
    keep_database = information is not None and information["stage"] in ("backing-up", "restart-failed")
    database_files(paths.data)
    if keep_database:
        candidates = [directory for directory in (paths.install, backup / "bin") if complete_install(directory)]
        if len(candidates) != 1 or not (paths.data / "codeg.db").is_file():
            raise Failure("完全な旧本体が一方だけにあることと、元 DB を確認できない")
        source_bin = candidates[0]
    else:
        source_bin = backup / "bin"
        validate_install(source_bin)
        validate_tree(source_bin)
        database_files(backup / "db")
        if not (backup / "db/codeg.db").is_file():
            raise Failure("控えに codeg.db が無い")
    if read_version(source_bin / "codeg-server") != version:
        raise Failure("控えの本体の版がディレクトリ名と一致しない")
    device = paths.backups.stat().st_dev
    if any(path.stat().st_dev != device for path in (paths.install.parent, paths.data, source_bin)):
        raise Failure("本体・DB と控えが同じファイルシステムに無い")
    host, port = endpoints(paths.unit)
    service_info()
    displaced = paths.backups / ("failed-manual-" + timestamp())
    if displaced.exists() or displaced.is_symlink():
        raise Failure("同じ名前の手動復元の退避先がある。次の実行まで待つ")
    return RestorePlan(backup, source_bin, version, hold, keep_database, displaced, host, port)


def restore(paths, name, hold):
    work = None
    try:
        # 型・段階・版・DB の検査と本体の複製は、サービスを止める前に済ませる。
        plan = plan_restore(paths, name, hold)
        current_version = plan.version if plan.source_bin == paths.install else None
        if current_version is None and complete_install(paths.install):
            with contextlib.suppress(Failure, OSError, subprocess.SubprocessError):
                current_version = read_version(paths.install / "codeg-server")
        work = Path(tempfile.mkdtemp(prefix="manual-restore-", dir=paths.state))
        if not plan.keep_database:
            shutil.copytree(plan.source_bin, work / "bin")
            copy_database(plan.backup / "db", work / "db")
    except (Exception, KeyboardInterrupt) as error:
        reason = str(error) if isinstance(error, Failure) else "控えと復元の前提を確認できない"
        log("中断: " + reason + "。本体と DB は変更していない")
        if work is not None:
            with contextlib.suppress(OSError):
                shutil.rmtree(work)
        return 1
    try:
        stage = "backing-up" if plan.keep_database else "rolling-back"
        progress(paths, stage, plan.backup, plan.version, hold)
        try:
            stop(plan.host, plan.port)
        except (Exception, KeyboardInterrupt):
            try:
                restarts = start()
                original_version = current_version or read_version(paths.install / "codeg-server")
                check(paths.install / "codeg-server", plan.host, plan.port, original_version, restarts)
                clear_progress(paths)
            except (Exception, KeyboardInterrupt):
                log("停止後に元の Codeg を確認できない。in-progress を残して " + RECOVERY + "で復旧する")
                return 3
            log("中断: 停止を確認できなかった。元の Codeg を再開し、本体と DB は復元していない")
            return 1
        plan.displaced.mkdir(mode=0o700)
        (plan.displaced / "db").mkdir(mode=0o700)
        if paths.candidate.exists():
            os.rename(paths.candidate, plan.displaced / "prepared")
        keep_current_binary = plan.keep_database and plan.source_bin == paths.install
        if paths.install.exists() and not keep_current_binary:
            os.rename(paths.install, plan.displaced / "bin")
        if not plan.keep_database:
            for path in database_files(paths.data):
                os.rename(path, plan.displaced / "db" / path.name)
            fsync_directory(paths.data)
            fsync_directory(plan.displaced / "db")
        if not keep_current_binary:
            source = plan.source_bin if plan.keep_database else work / "bin"
            os.rename(source, paths.install)
        if plan.keep_database:
            if plan.backup.exists():
                os.rename(plan.backup, plan.displaced / "partial-backup")
        else:
            for path in database_files(work / "db"):
                os.rename(path, paths.data / path.name)
            fsync_directory(paths.data)
        fsync_directory(paths.install.parent)
        fsync_directory(plan.displaced)
        fsync_directory(paths.backups)
        restarts = start()
        check(paths.install / "codeg-server", plan.host, plan.port, plan.version, restarts)
        write_state(paths.state / "skip-version", hold + "\n")
        clear_progress(paths)
        log("復元: " + plan.version + " に戻し、" + hold + " を保留した")
        if plan.keep_database:
            log("元 DB は保持した。部分的な控えと展開物の退避: " + str(plan.displaced))
        else:
            log("手動復元前の本体と DB の退避: " + str(plan.displaced))
        return 0
    except (Exception, KeyboardInterrupt):
        log("復元または旧版の起動確認に失敗した。退避と in-progress を残したまま、" + RECOVERY + "を確かめる")
        return 3
    finally:
        try:
            shutil.rmtree(work)
        except (OSError, Failure, KeyboardInterrupt):
            log("復元の作業用ディレクトリを片付けられない: " + str(work))


def restore_arguments(arguments):
    if not arguments:
        return None
    values = dict(zip(arguments[::2], arguments[1::2]))
    if len(arguments) != 4 or set(values) != {"--restore", "--hold"}:
        raise Failure("引数は --restore <控えの名前> --hold <問題の版> の組で指定する")
    return values["--restore"], values["--hold"]


def main(arguments=None):
    global LOG_PATH
    try:
        requested = restore_arguments(arguments or [])
    except Failure as error:
        log("中断: " + str(error))
        return 1
    if os.geteuid() == 0:
        log("中断: root では動かさない。Codeg を動かす一般ユーザーで実行する")
        return 1
    os.umask(0o077)
    paths = get_paths()
    descriptors = []
    previous_log = LOG_PATH
    try:
        secure_directory(paths.state)
        LOG_PATH = paths.state / "codeg-auto-update.log"
        append_log(LOG_PATH, "復元の確認を始める" if requested else "自動更新の確認を始める")
        descriptors.append(acquire_lock(paths.state / "lock"))
        # set-codeg-password.py の acquire_change_lock() と同じファイル・flock。
        descriptors.append(acquire_password_lock(paths))
        if requested is not None:
            return restore(paths, *requested)
        return run_locked(paths)
    except (Exception, KeyboardInterrupt) as error:
        if requested is None and (paths.state / "in-progress").exists():
            log("処理を完了できない。" + RECOVERY + "で復旧する")
            return 3
        reason = str(error) if isinstance(error, Failure) else "更新の取得または安全条件の検査に失敗した"
        log("中断: " + reason + "。Codeg の本体と DB は入れ替えていない")
        return 1
    finally:
        for descriptor in reversed(descriptors):
            os.close(descriptor)
        LOG_PATH = previous_log


def interrupted(signum, frame):
    raise Failure("終了要求を受けた")


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, interrupted)
    sys.exit(main(sys.argv[1:]))
