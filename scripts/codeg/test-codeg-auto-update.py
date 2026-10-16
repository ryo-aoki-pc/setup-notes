#!/usr/bin/python3
"""実サービス・ネットワーク・Codeg を使わず、一時 HOME で更新と復旧を確かめる。"""

import contextlib
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile
import types
import unittest
from unittest.mock import patch

# Windows でも OS に依存しない fixture を実行する。flock 自体の試験は Linux だけ。
if os.name == "nt":
    sys.modules.setdefault("fcntl", types.SimpleNamespace(LOCK_EX=2, LOCK_NB=4))
    sys.modules.setdefault("pwd", types.SimpleNamespace(getpwuid=lambda uid: types.SimpleNamespace(pw_name="fixture")))

spec = importlib.util.spec_from_file_location("codeg_auto_update", Path(__file__).with_name("codeg-auto-update.py"))
helper = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = helper
spec.loader.exec_module(helper)
ASSET = "codeg-server-linux-x64"
OLD = "0.35.1"
NEW = "0.35.2"


def release(version, **changes):
    result = {"tag_name": "v" + version, "draft": False, "prerelease": False,
              "assets": [{"name": ASSET + suffix, "browser_download_url": "https://fixture.invalid/" + ASSET + suffix}
                         for suffix in (".tar.gz", ".tar.gz.sha256")]}
    result.update(changes)
    return result


def archive_bytes(version=NEW, extra=None):
    output = io.BytesIO()
    with tarfile.open(fileobj=output, mode="w:gz") as bundle:
        for name, content in (("codeg-server", version.encode("ascii")), ("codeg-mcp", b"fixture"),
                              ("web/index.html", b"fixture")):
            member = tarfile.TarInfo(ASSET + "/" + name)
            member.size = len(content)
            member.mode = 0o700 if name != "web/index.html" else 0o600
            bundle.addfile(member, io.BytesIO(content))
        if extra:
            bundle.addfile(extra)
    return output.getvalue()


class Clock:
    def __init__(self):
        self.now = 0

    def monotonic(self):
        return self.now

    def sleep(self, seconds):
        self.now += seconds


class UpdateTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="codeg-auto-test-", dir=Path(__file__).parent)
        self.home = Path(self.temporary.name)
        self.paths = helper.Paths.for_home(self.home)
        for directory in (self.paths.install, self.paths.data, self.paths.settings,
                          self.paths.state, self.paths.unit.parent):
            directory.mkdir(mode=0o700, parents=True, exist_ok=True)
            directory.chmod(0o700)
        self.make_install(self.paths.install, OLD)
        self.paths.unit.write_text("[Service]\nEnvironment=CODEG_HOST=127.0.0.1\nEnvironment=CODEG_PORT=3080\n",
                                   encoding="utf-8")
        (self.paths.settings / "token.env").write_bytes(b"public-fixture-not-a-real-token\n")
        (self.paths.data / "codeg.db").write_bytes(b"old-db")
        self.state = "active"
        self.restarts = 0
        self.calls = []
        self.starts = 0
        self.fail_new = False
        self.fail_old = False
        self.migrated = False
        self.clock = Clock()
        self.output = io.StringIO()
        self.bundle = archive_bytes()
        self.api_release = release(NEW)
        self.api_release["assets"][0]["digest"] = "sha256:" + hashlib.sha256(self.bundle).hexdigest()
        self.checksum = hashlib.sha256(self.bundle).hexdigest()
        self.stack = contextlib.ExitStack()
        self.addCleanup(self.temporary.cleanup)
        # 秘密ファイルの監視を閉じてから、一時 HOME を片付ける。
        self.addCleanup(self.stack.close)
        self.stack.enter_context(contextlib.redirect_stdout(self.output))
        self.stack.enter_context(patch.object(helper, "get_paths", return_value=self.paths))
        self.stack.enter_context(patch.object(helper.os, "geteuid", return_value=1000, create=True))
        self.stack.enter_context(patch.object(helper, "asset_name", return_value=ASSET))
        self.stack.enter_context(patch.object(helper, "fetch_releases", side_effect=lambda: [self.api_release]))
        self.stack.enter_context(patch.object(helper, "download", side_effect=self.download))
        self.stack.enter_context(patch.object(helper, "read_version", side_effect=self.version))
        self.stack.enter_context(patch.object(helper, "systemctl", side_effect=self.systemctl))
        self.stack.enter_context(patch.object(helper, "listener_identity", side_effect=self.listener))
        self.stack.enter_context(patch.object(helper, "http_status", side_effect=self.http))
        self.stack.enter_context(patch.object(helper, "port_free", side_effect=lambda host, port: self.state != "active"))
        self.stack.enter_context(patch.object(helper.time, "monotonic", side_effect=self.clock.monotonic))
        self.stack.enter_context(patch.object(helper.time, "sleep", side_effect=self.clock.sleep))
        self.stack.enter_context(patch.object(helper.shutil, "disk_usage",
                                             return_value=types.SimpleNamespace(free=10 * 2**30)))
        self.stack.enter_context(patch.object(helper, "timestamp", return_value="20261016T043000Z"))
        if os.name == "nt":
            self.stack.enter_context(patch.object(helper, "fsync_directory"))
            self.stack.enter_context(patch.object(helper, "secure_directory",
                                                 side_effect=lambda path: path.mkdir(parents=True, exist_ok=True)))
            self.stack.enter_context(patch.object(helper, "acquire_lock", side_effect=self.fake_lock))
            self.stack.enter_context(patch.object(helper, "acquire_password_lock",
                                                 side_effect=lambda paths: self.fake_lock(paths.settings / ".password-change.lock")))
        original_open = io.open

        def guarded_open(file, *args, **kwargs):
            if not isinstance(file, int) and Path(file).name in ("token.env", "token.txt"):
                raise AssertionError("トークンのファイルを開いた")
            return original_open(file, *args, **kwargs)

        self.stack.enter_context(patch.object(io, "open", side_effect=guarded_open))

    def fake_lock(self, path):
        self.calls.append(("lock", path.name))
        return os.open(path, os.O_RDWR | os.O_CREAT, 0o600)

    def make_install(self, directory, version):
        directory.mkdir(parents=True, exist_ok=True)
        (directory / "web").mkdir(exist_ok=True)
        for name in ("codeg-server", "codeg-mcp"):
            path = directory / name
            path.write_text(version, encoding="ascii")
            path.chmod(0o700)

    def version(self, binary):
        self.calls.append(("version", str(binary)))
        return binary.read_text(encoding="ascii")

    def download(self, url, target):
        self.calls.append(("download", target.name))
        if target.name.endswith(".sha256"):
            target.write_text(self.checksum + "  " + ASSET + ".tar.gz\n", encoding="ascii")
        else:
            target.write_bytes(self.bundle)

    def systemctl(self, *args, **kwargs):
        self.calls.append(tuple(args))
        if args[0] == "show":
            return ("ActiveState=" + self.state + "\nNRestarts=" + str(self.restarts)
                    + "\nMainPID=123\nControlGroup=/fixture/codeg")
        if args[0] == "stop":
            self.state = "inactive"
        elif args[0] == "reset-failed":
            self.restarts = 0
        elif args[0] == "start":
            self.starts += 1
            version = (self.paths.install / "codeg-server").read_text(encoding="ascii")
            self.state = "active"
            if version == NEW and not self.migrated:
                self.migrated = True
                (self.paths.data / "codeg.db").write_bytes(b"new-db")
                (self.paths.data / "codeg.db-wal").write_bytes(b"new-wal")
                (self.paths.data / "codeg.db-shm").write_bytes(b"new-shm")
        return ""

    def listener(self, *args):
        if self.state != "active":
            raise helper.Failure("fixture 停止中")
        version = (self.paths.install / "codeg-server").read_text(encoding="ascii")
        if (version == NEW and self.fail_new) or (version == OLD and self.migrated and self.fail_old):
            raise helper.Failure("fixture 待受失敗")
        return self.starts, version, "fixture-inode"

    def http(self, host, port, path):
        self.calls.append(("http", path))
        return 200 if path == "/" else 401

    def test_highest_stable_complete_assets_numeric_order(self):
        releases = [release("0.34.99"), release("0.35.2"), release("0.35.10"), release("0.35.11-rc.2"),
                    release("9.0.0", draft=True), release("8.0.0", prerelease=True), release("7.0.0", assets=[])]
        for missing in (("draft",), ("prerelease",), ("draft", "prerelease")):
            incomplete = release("6.0.0")
            for key in missing:
                del incomplete[key]
            releases.append(incomplete)
        releases.extend((release("９.０.０"), release("٩.٠.٠")))
        self.assertEqual(helper.select_release(releases, ASSET)[0], "0.35.10")
        self.assertEqual(helper.select_release(releases[::-1], ASSET)[0], "0.35.10")
        with self.assertRaises(helper.Failure):
            helper.select_release([release("0.35.2", assets=[releases[0]["assets"][0]])], ASSET)

    def test_current_version_does_not_stop_or_download(self):
        self.api_release = release(OLD)
        self.assertEqual(helper.main(), 0)
        self.assertIn("最新版 " + OLD + " を使用中", self.output.getvalue())
        self.assertFalse(any(call[0] in ("stop", "download") for call in self.calls))

    def test_held_release_and_manual_release(self):
        held = self.paths.state / "skip-version"
        held.write_text(NEW, encoding="ascii")
        self.assertEqual(helper.main(), 1)
        self.assertFalse(any(call[0] == "download" for call in self.calls))
        held.unlink()
        self.assertEqual(helper.main(), 0)
        self.assertEqual((self.paths.install / "codeg-server").read_text(), NEW)
        self.assertFalse(held.exists())

    def test_obsolete_hold_is_removed(self):
        held = self.paths.state / "skip-version"
        held.write_text(OLD, encoding="ascii")
        self.api_release = release(OLD)
        self.assertEqual(helper.main(), 0)
        self.assertFalse(held.exists())

    def test_newer_release_can_bypass_previous_hold(self):
        (self.paths.state / "skip-version").write_text("0.35.0", encoding="ascii")
        self.assertEqual(helper.main(), 0)

    def test_inactive_is_left_stopped(self):
        self.state = "inactive"
        self.assertEqual(helper.main(), 0)
        self.assertFalse(any(call[0] in ("start", "stop", "download") for call in self.calls))
        self.assertIn("止まっているので更新しない", self.output.getvalue())

    def test_transitional_state_is_rejected(self):
        self.state = "activating"
        self.assertEqual(helper.main(), 1)
        self.assertFalse(any(call[0] == "stop" for call in self.calls))

    def test_checksum_and_api_digest_must_both_match_before_stop(self):
        for kind in ("checksum", "digest"):
            with self.subTest(kind=kind):
                self.calls.clear()
                if kind == "checksum":
                    self.checksum = "0" * 64
                else:
                    self.checksum = hashlib.sha256(self.bundle).hexdigest()
                    self.api_release["assets"][0]["digest"] = "sha256:" + "0" * 64
                self.assertEqual(helper.main(), 1)
                self.assertFalse(any(call[0] == "stop" for call in self.calls))
                self.assertFalse(self.paths.candidate.exists())
                self.assertEqual((self.paths.data / "codeg.db").read_bytes(), b"old-db")

    def test_missing_digest_reports_checksum_only(self):
        del self.api_release["assets"][0]["digest"]
        self.assertEqual(helper.main(), 0)
        self.assertIn("digest が無い", self.output.getvalue())

    def test_unsafe_tar_paths_links_and_devices_are_rejected_before_stop(self):
        for name, kind in ((ASSET + "/../escape", tarfile.REGTYPE), ("/absolute", tarfile.REGTYPE),
                           (ASSET + "/link", tarfile.SYMTYPE), (ASSET + "/hard", tarfile.LNKTYPE),
                           (ASSET + "/device", tarfile.CHRTYPE), ("other/file", tarfile.REGTYPE)):
            with self.subTest(name=name):
                member = tarfile.TarInfo(name)
                member.type = kind
                member.linkname = "../../outside"
                self.bundle = archive_bytes(extra=member)
                self.checksum = hashlib.sha256(self.bundle).hexdigest()
                self.api_release["assets"][0]["digest"] = "sha256:" + self.checksum
                self.calls.clear()
                self.assertEqual(helper.main(), 1)
                self.assertFalse(any(call[0] == "stop" for call in self.calls))
                self.assertFalse(self.paths.candidate.exists())

    def test_new_version_timeout_is_held_without_stopping(self):
        def timeout(binary):
            if binary.parent == self.paths.candidate:
                raise helper.VersionTimeout("fixture 時間切れ")
            return self.version(binary)

        with patch.object(helper, "read_version", side_effect=timeout):
            self.assertEqual(helper.main(), 1)
        self.assertEqual((self.paths.state / "skip-version").read_text().strip(), NEW)
        self.assertFalse(any(call[0] == "stop" for call in self.calls))
        self.assertFalse(self.paths.candidate.exists())

    def test_failed_new_start_restores_binary_and_whole_database(self):
        self.fail_new = True
        self.assertEqual(helper.main(), 2)
        self.assertEqual((self.paths.install / "codeg-server").read_text(), OLD)
        self.assertEqual((self.paths.data / "codeg.db").read_bytes(), b"old-db")
        self.assertFalse((self.paths.data / "codeg.db-wal").exists())
        self.assertFalse((self.paths.data / "codeg.db-shm").exists())
        failed = list(self.paths.backups.glob("failed-*"))
        self.assertEqual(len(failed), 1)
        self.assertEqual((failed[0] / "db/codeg.db-wal").read_bytes(), b"new-wal")
        self.assertEqual((failed[0] / "bin/codeg-server").read_text(), NEW)
        self.assertFalse((self.paths.state / "in-progress").exists())
        self.assertEqual((self.paths.state / "skip-version").read_text().strip(), NEW)

    def test_failed_old_start_returns_three_and_preserves_marker(self):
        self.fail_new = self.fail_old = True
        self.assertEqual(helper.main(), 3)
        marker = json.loads((self.paths.state / "in-progress").read_text())
        self.assertEqual(marker["stage"], "rolling-back")
        self.assertEqual(marker["old"], OLD)
        self.assertTrue(list(self.paths.backups.glob("failed-*")))
        backup = Path(marker["backup"])
        self.assertEqual((backup / "bin/codeg-server").read_text(), OLD)
        self.assertEqual((backup / "db/codeg.db").read_bytes(), b"old-db")

    def test_in_progress_does_not_read_version_or_contact_api(self):
        marker = self.paths.state / "in-progress"
        marker.write_text('{"stage":"checking"}', encoding="ascii")
        before = marker.read_bytes()
        self.assertEqual(helper.main(), 3)
        self.assertEqual(marker.read_bytes(), before)
        self.assertFalse(any(call[0] in ("version", "download", "show", "stop") for call in self.calls))
        self.assertIn("前の更新が途中", self.output.getvalue())
        self.assertIn("docs/extra/codeg.md の「AlmaLinux 10 で自動更新の控えから前の版と DB に戻す」",
                      self.output.getvalue())

    def test_keeps_only_two_automatic_generations_and_never_failed(self):
        self.paths.backups.mkdir()
        for name in ("20261010T043000Z-0.34.0", "20261011T043000Z-0.35.0", "20261012T043000Z-0.35.1",
                     "failed-20261001T000000Z", "manual-keep"):
            destination = self.paths.backups / name
            destination.mkdir()
            if name[0].isdigit():
                self.make_install(destination / "bin", OLD)
                (destination / "db").mkdir()
                (destination / "db/codeg.db").write_bytes(b"fixture-backup")
        self.assertEqual(helper.main(), 0)
        names = sorted(path.name for path in self.paths.backups.iterdir())
        self.assertEqual(names, ["20261012T043000Z-0.35.1", "20261016T043000Z-0.35.1",
                                 "failed-20261001T000000Z", "manual-keep"])

    def test_either_lock_failure_aborts(self):
        for password in (False, True):
            with self.subTest(password=password), patch.object(
                    helper, "acquire_password_lock" if password else "acquire_lock",
                    side_effect=helper.Failure("fixture ロック中")):
                self.assertEqual(helper.main(), 1)
                self.assertFalse(any(call[0] == "version" for call in self.calls))

    @unittest.skipIf(os.name == "nt", "実際の flock と POSIX 所有者・モードは Linux で確認する")
    def test_real_flock_is_nonblocking_for_both_lock_files(self):
        for path in (self.paths.state / "lock", self.paths.settings / ".password-change.lock"):
            descriptor = helper.acquire_lock(path)
            try:
                self.assertEqual(helper.main(), 1)
            finally:
                os.close(descriptor)

    def test_self_update_markers_abort_without_stopping(self):
        for directory, name in ((self.paths.install, ".codeg-upgrade-staged"),
                                (self.paths.install, "codeg-server.bak"),
                                (self.paths.install, "codeg-mcp.bak"),
                                (self.paths.install, "web.bak")):
            marker = directory / name
            marker.touch()
            self.assertEqual(helper.main(), 1)
            marker.unlink()
        self.assertFalse(any(call[0] in ("stop", "download") for call in self.calls))

    def test_self_update_markers_in_parent_do_not_block_codeg(self):
        for name in (".codeg-upgrade-staged", "other-tool.bak", "codeg-server.bak"):
            (self.paths.install.parent / name).touch()
        self.assertEqual(helper.main(), 0)
        self.assertEqual((self.paths.install / "codeg-server").read_text(), NEW)
        self.assertTrue((self.paths.install.parent / "other-tool.bak").exists())

    def test_update_never_opens_token_and_lock_uses_same_path(self):
        self.assertEqual(helper.main(), 0)
        self.assertTrue((self.paths.settings / ".password-change.lock").exists())
        self.assertNotIn("public-fixture-not-a-real-token", self.output.getvalue())

    def test_backup_copy_failure_restarts_unchanged_old_database(self):
        with patch.object(helper, "copy_database", side_effect=OSError("fixture 書込失敗")):
            self.assertEqual(helper.main(), 1)
        self.assertEqual((self.paths.install / "codeg-server").read_text(), OLD)
        self.assertEqual((self.paths.data / "codeg.db").read_bytes(), b"old-db")
        self.assertFalse((self.paths.state / "in-progress").exists())
        self.assertEqual(self.state, "active")

    def test_restart_during_health_check_triggers_rollback(self):
        original = self.http

        def restart(host, port, path):
            if self.migrated:
                self.restarts += 1
            return original(host, port, path)

        with patch.object(helper, "http_status", side_effect=restart):
            self.assertEqual(helper.main(), 3)
        self.assertIn("戻せなかった", self.output.getvalue())

    def test_wrong_api_status_cannot_pass_health_check(self):
        with patch.object(helper, "http_status", return_value=200):
            self.assertEqual(helper.main(), 3)

    def test_low_space_does_not_stop_and_cleans_candidate(self):
        with patch.object(helper.shutil, "disk_usage", return_value=types.SimpleNamespace(free=1)):
            self.assertEqual(helper.main(), 1)
        self.assertFalse(any(call[0] == "stop" for call in self.calls))
        self.assertFalse(self.paths.candidate.exists())

    def test_distribution_helper_is_not_installed(self):
        output = io.BytesIO()
        with tarfile.open(fileobj=output, mode="w:gz") as bundle:
            with tarfile.open(fileobj=io.BytesIO(self.bundle), mode="r:gz") as original:
                for member in original.getmembers():
                    bundle.addfile(member, original.extractfile(member) if member.isfile() else None)
            member = tarfile.TarInfo(ASSET + "/codeg-computer-helper")
            member.size = 6
            bundle.addfile(member, io.BytesIO(b"unused"))
        self.bundle = output.getvalue()
        self.checksum = hashlib.sha256(self.bundle).hexdigest()
        self.api_release["assets"][0]["digest"] = "sha256:" + self.checksum
        self.assertEqual(helper.main(), 0)
        self.assertEqual({path.name for path in self.paths.install.iterdir()}, {"codeg-server", "codeg-mcp", "web"})

    def test_prune_failure_reports_successfully_installed_version(self):
        with patch.object(helper, "prune", side_effect=PermissionError("fixture 整理失敗")):
            self.assertEqual(helper.main(), 0)
        self.assertEqual((self.paths.install / "codeg-server").read_text(), NEW)
        self.assertIn("更新: " + OLD + " → " + NEW, self.output.getvalue())
        self.assertNotIn("入れ替えていない", self.output.getvalue())

    def test_cleanup_failure_after_backup_failure_keeps_unchanged_result(self):
        original = shutil.rmtree

        def fail_recovered_backup(path, *args, **kwargs):
            if Path(path).parent == self.paths.backups and not Path(path).name.startswith("failed-"):
                raise PermissionError("fixture 整理失敗")
            return original(path, *args, **kwargs)

        with patch.object(helper, "copy_database", side_effect=OSError("fixture 退避失敗")), \
             patch.object(helper.shutil, "rmtree", side_effect=fail_recovered_backup):
            self.assertEqual(helper.main(), 1)
        self.assertEqual((self.paths.data / "codeg.db").read_bytes(), b"old-db")
        self.assertFalse((self.paths.state / "in-progress").exists())

    def test_abandoned_preparation_is_removed_before_retry(self):
        self.paths.candidate.mkdir()
        (self.paths.candidate / "incomplete-tar-content").write_bytes(b"fixture")
        self.assertEqual(helper.main(), 0)
        self.assertFalse(self.paths.candidate.exists())
        self.assertIn("前の準備", self.output.getvalue())

    def test_prepared_files_are_preserved_while_marker_exists(self):
        (self.paths.state / "in-progress").write_text('{"stage":"backing-up"}', encoding="ascii")
        self.paths.candidate.mkdir()
        prepared = self.paths.candidate / "fixture"
        prepared.write_bytes(b"fixture")
        self.assertEqual(helper.main(), 3)
        self.assertEqual(prepared.read_bytes(), b"fixture")

    def test_endpoint_values_must_be_unique(self):
        self.paths.unit.write_text("Environment=CODEG_HOST=127.0.0.1\nEnvironment=CODEG_PORT=3080\n"
                                   "Environment=CODEG_PORT=3080\n", encoding="utf-8")
        self.assertEqual(helper.main(), 1)
        self.assertFalse(any(call[0] == "version" for call in self.calls))


    def make_restore_backup(self, version=OLD):
        self.paths.backups.mkdir(exist_ok=True)
        backup = self.paths.backups / ("20261015T043000Z-" + OLD)
        self.make_install(backup / "bin", version)
        (backup / "db").mkdir()
        (backup / "db/codeg.db").write_bytes(b"snapshot-db")
        (backup / "db/codeg.db-wal").write_bytes(b"snapshot-wal")
        self.make_install(self.paths.install, NEW)
        (self.paths.data / "codeg.db").write_bytes(b"post-update-db")
        (self.paths.data / "codeg.db-wal").write_bytes(b"post-update-wal")
        (self.paths.data / "codeg.db-shm").write_bytes(b"post-update-shm")
        (self.paths.data / "codeg.db.tasks.lock").write_bytes(b"post-update-lock")
        self.migrated = True
        return backup

    def run_restore(self, backup, hold=NEW):
        with patch.object(helper, "fetch_releases", side_effect=AssertionError("復元で API を呼んだ")), \
             patch.object(helper, "download", side_effect=AssertionError("復元でダウンロードした")):
            return helper.main(["--restore", backup.name, "--hold", hold])

    def assert_restored_snapshot(self):
        self.assertEqual((self.paths.install / "codeg-server").read_text(), OLD)
        self.assertEqual({path.name: path.read_bytes() for path in helper.database_files(self.paths.data)},
                         {"codeg.db": b"snapshot-db", "codeg.db-wal": b"snapshot-wal"})

    def test_restore_completed_backup_stops_itself_and_preserves_displaced_files(self):
        backup = self.make_restore_backup()
        self.assertEqual(self.run_restore(backup), 0)
        self.assert_restored_snapshot()
        self.assertEqual((backup / "bin/codeg-server").read_text(), OLD)
        self.assertEqual((backup / "db/codeg.db").read_bytes(), b"snapshot-db")
        displaced = next(self.paths.backups.glob("failed-manual-*"))
        self.assertEqual((displaced / "bin/codeg-server").read_text(), NEW)
        self.assertEqual((displaced / "db/codeg.db-wal").read_bytes(), b"post-update-wal")
        self.assertEqual((displaced / "db/codeg.db.tasks.lock").read_bytes(), b"post-update-lock")
        self.assertFalse((self.paths.state / "in-progress").exists())
        self.assertEqual((self.paths.state / "skip-version").read_text().strip(), NEW)
        self.assertTrue(any(call[0] == "stop" for call in self.calls))
        self.assertEqual(self.state, "active")
        self.assertIn("復元:", self.output.getvalue())

    def test_restore_stop_failure_restarts_current_version_without_moving_files(self):
        backup = self.make_restore_backup()
        held = self.paths.state / "skip-version"
        held.write_text("0.35.3\n", encoding="ascii")
        before_data = {path.name: path.read_bytes() for path in helper.database_files(self.paths.data)}
        observed_versions = []
        original_check = helper.check

        def stop_then_fail(host, port):
            self.state = "inactive"
            raise helper.Failure("fixture 停止後の待ち受け検査に失敗")

        def check_current(binary, host, port, version, restarts):
            observed_versions.append(version)
            return original_check(binary, host, port, version, restarts)

        with patch.object(helper, "stop", side_effect=stop_then_fail), \
             patch.object(helper, "check", side_effect=check_current):
            self.assertEqual(self.run_restore(backup), 1)
        self.assertEqual(observed_versions, [NEW])
        self.assertEqual(self.state, "active")
        self.assertEqual((self.paths.install / "codeg-server").read_text(), NEW)
        self.assertEqual({path.name: path.read_bytes() for path in helper.database_files(self.paths.data)}, before_data)
        self.assertEqual((backup / "bin/codeg-server").read_text(), OLD)
        self.assertEqual((backup / "db/codeg.db").read_bytes(), b"snapshot-db")
        self.assertEqual(held.read_text(), "0.35.3\n")
        self.assertFalse(list(self.paths.backups.glob("failed-manual-*")))
        self.assertFalse((self.paths.state / "in-progress").exists())

    def test_restore_stop_failure_keeps_marker_when_original_cannot_restart(self):
        backup = self.make_restore_backup()
        self.fail_new = True

        def stop_then_fail(host, port):
            self.state = "inactive"
            raise helper.Failure("fixture 停止後の検査に失敗")

        with patch.object(helper, "stop", side_effect=stop_then_fail):
            self.assertEqual(self.run_restore(backup), 3)
        self.assertEqual((self.paths.install / "codeg-server").read_text(), NEW)
        self.assertEqual((self.paths.data / "codeg.db-wal").read_bytes(), b"post-update-wal")
        self.assertEqual((backup / "db/codeg.db").read_bytes(), b"snapshot-db")
        self.assertFalse(list(self.paths.backups.glob("failed-manual-*")))
        self.assertTrue((self.paths.state / "in-progress").exists())
        self.assertFalse((self.paths.state / "skip-version").exists())

    def test_backing_up_restore_stop_failure_restarts_original_and_keeps_database(self):
        self.paths.backups.mkdir()
        backup = self.paths.backups / ("20261015T043000Z-" + OLD)
        (backup / "db").mkdir(parents=True)
        (backup / "db/codeg.db").write_bytes(b"incomplete-do-not-use")
        (self.paths.data / "codeg.db-wal").write_bytes(b"original-wal")
        helper.progress(self.paths, "backing-up", backup, OLD, NEW)

        def stop_then_fail(host, port):
            self.state = "inactive"
            raise helper.Failure("fixture 停止後の検査に失敗")

        with patch.object(helper, "stop", side_effect=stop_then_fail):
            self.assertEqual(self.run_restore(backup), 1)
        self.assertEqual(self.state, "active")
        self.assertEqual((self.paths.install / "codeg-server").read_text(), OLD)
        self.assertEqual((self.paths.data / "codeg.db").read_bytes(), b"old-db")
        self.assertEqual((self.paths.data / "codeg.db-wal").read_bytes(), b"original-wal")
        self.assertEqual((backup / "db/codeg.db").read_bytes(), b"incomplete-do-not-use")
        self.assertFalse(list(self.paths.backups.glob("failed-manual-*")))
        self.assertFalse((self.paths.state / "in-progress").exists())

    def test_restore_also_starts_an_already_stopped_service(self):
        backup = self.make_restore_backup()
        self.state = "inactive"
        self.assertEqual(self.run_restore(backup), 0)
        self.assert_restored_snapshot()
        self.assertEqual(self.state, "active")

    def check_backing_up_restore(self, source_in_backup):
        self.paths.backups.mkdir()
        backup = self.paths.backups / ("20261015T043000Z-" + OLD)
        (backup / "db").mkdir(parents=True)
        (backup / "db/codeg.db").write_bytes(b"incomplete-do-not-use")
        (self.paths.data / "codeg.db-wal").write_bytes(b"original-wal")
        if source_in_backup:
            os.rename(self.paths.install, backup / "bin")
        helper.progress(self.paths, "backing-up", backup, OLD, NEW)
        self.paths.candidate.mkdir()
        (self.paths.candidate / "incomplete-payload").write_bytes(b"fixture")
        self.state = "inactive"
        original_inode = None if source_in_backup else (self.paths.install / "codeg-server").stat().st_ino
        self.assertEqual(self.run_restore(backup), 0)
        if original_inode is not None:
            self.assertEqual((self.paths.install / "codeg-server").stat().st_ino, original_inode)
        self.assertEqual((self.paths.install / "codeg-server").read_text(), OLD)
        self.assertEqual((self.paths.data / "codeg.db").read_bytes(), b"old-db")
        self.assertEqual((self.paths.data / "codeg.db-wal").read_bytes(), b"original-wal")
        displaced = next(self.paths.backups.glob("failed-manual-*"))
        self.assertEqual((displaced / "partial-backup/db/codeg.db").read_bytes(), b"incomplete-do-not-use")
        self.assertEqual((displaced / "prepared/incomplete-payload").read_bytes(), b"fixture")
        self.assertFalse(self.paths.candidate.exists())
        self.assertFalse((self.paths.state / "in-progress").exists())

    def test_restore_backing_up_with_old_binary_in_backup_keeps_original_database(self):
        self.check_backing_up_restore(source_in_backup=True)

    def test_restore_backing_up_with_old_binary_still_installed_keeps_original_database(self):
        self.check_backing_up_restore(source_in_backup=False)

    def test_restore_rejects_mismatched_binary_version_before_stopping(self):
        backup = self.make_restore_backup(version="0.34.0")
        self.assertEqual(self.run_restore(backup), 1)
        self.assertEqual((self.paths.install / "codeg-server").read_text(), NEW)
        self.assertEqual((self.paths.data / "codeg.db").read_bytes(), b"post-update-db")
        self.assertFalse(any(call[0] in ("stop", "start") for call in self.calls))
        self.assertFalse((self.paths.state / "in-progress").exists())
        self.assertFalse(list(self.paths.backups.glob("failed-manual-*")))

    def test_restore_rejects_invalid_name_hold_and_argument_pairs(self):
        for arguments in (["--restore", "../escape", "--hold", NEW],
                          ["--restore", "failed-20261015T043000Z", "--hold", NEW],
                          ["--restore", "20261015T043000Z-" + OLD, "--hold", "v" + NEW],
                          ["--hold", NEW], ["--unknown", "value", "--hold", NEW]):
            with self.subTest(arguments=arguments):
                self.assertEqual(helper.main(arguments), 1)
        self.assertFalse(any(call[0] in ("stop", "start", "version", "download") for call in self.calls))

    def test_restore_rejects_self_update_markers_before_stopping(self):
        backup = self.make_restore_backup()
        for name in (".codeg-upgrade-staged", "codeg-server.bak"):
            marker = self.paths.install / name
            marker.touch()
            self.assertEqual(self.run_restore(backup), 1)
            marker.unlink()
        self.assertFalse(any(call[0] in ("stop", "start") for call in self.calls))
        self.assertEqual((self.paths.data / "codeg.db-wal").read_bytes(), b"post-update-wal")

    def test_restore_rejects_unknown_or_mismatched_in_progress_without_changing_it(self):
        backup = self.make_restore_backup()
        for changes in ({"stage": "unknown"}, {"old": "0.34.0"}, {"new": "0.35.3"},
                        {"backup": str(self.paths.backups / "different")}, {"backup": backup.name}):
            with self.subTest(changes=changes):
                information = {"stage": "checking", "backup": str(backup), "old": OLD, "new": NEW}
                information.update(changes)
                marker = self.paths.state / "in-progress"
                marker.write_text(json.dumps(information), encoding="utf-8")
                before = marker.read_bytes()
                self.assertEqual(self.run_restore(backup), 1)
                self.assertEqual(marker.read_bytes(), before)
        self.assertFalse(any(call[0] in ("stop", "start") for call in self.calls))
        self.assertEqual((self.paths.install / "codeg-server").read_text(), NEW)

    def test_restore_health_failure_keeps_displaced_files_and_marker(self):
        backup = self.make_restore_backup()
        self.fail_old = True
        self.assertEqual(self.run_restore(backup), 3)
        self.assert_restored_snapshot()
        marker = json.loads((self.paths.state / "in-progress").read_text())
        self.assertEqual(marker["stage"], "rolling-back")
        self.assertEqual(marker["backup"], str(backup))
        displaced = next(self.paths.backups.glob("failed-manual-*"))
        self.assertEqual((displaced / "db/codeg.db-wal").read_bytes(), b"post-update-wal")
        self.assertEqual((backup / "bin/codeg-server").read_text(), OLD)
        self.assertFalse((self.paths.state / "skip-version").exists())

    def test_restore_requires_the_same_change_locks(self):
        backup = self.make_restore_backup()
        for function in ("acquire_lock", "acquire_password_lock"):
            with patch.object(helper, function, side_effect=helper.Failure("fixture ロック中")):
                self.assertEqual(self.run_restore(backup), 1)
        self.assertFalse(any(call[0] == "stop" for call in self.calls))

    def test_backing_up_restore_can_be_retried_after_old_health_failure(self):
        self.paths.backups.mkdir()
        backup = self.paths.backups / ("20261015T043000Z-" + OLD)
        (backup / "db").mkdir(parents=True)
        (backup / "db/codeg.db").write_bytes(b"incomplete-do-not-use")
        helper.progress(self.paths, "backing-up", backup, OLD, NEW)
        with patch.object(helper, "check", side_effect=helper.Failure("fixture 起動確認失敗")):
            self.assertEqual(self.run_restore(backup), 3)
        self.assertEqual(json.loads((self.paths.state / "in-progress").read_text())["stage"], "backing-up")
        self.assertEqual((self.paths.data / "codeg.db").read_bytes(), b"old-db")
        self.assertEqual((self.paths.install / "codeg-server").read_text(), OLD)
        with patch.object(helper, "timestamp", return_value="20261016T043001Z"):
            self.assertEqual(self.run_restore(backup), 0)
        self.assertEqual((self.paths.data / "codeg.db").read_bytes(), b"old-db")
        self.assertFalse((self.paths.state / "in-progress").exists())

    def test_auto_backup_failure_with_failed_restart_can_be_restored_without_partial_db(self):
        def partial_copy(source, destination):
            destination.mkdir()
            (destination / "codeg.db").write_bytes(b"partial-do-not-use")
            raise OSError("fixture 退避失敗")

        with patch.object(helper, "copy_database", side_effect=partial_copy), \
             patch.object(helper, "check", side_effect=helper.Failure("fixture 起動確認失敗")):
            self.assertEqual(helper.main(), 3)
        information = json.loads((self.paths.state / "in-progress").read_text())
        self.assertEqual(information["stage"], "backing-up")
        backup = Path(information["backup"])
        self.assertEqual(self.run_restore(backup), 0)
        self.assertEqual((self.paths.data / "codeg.db").read_bytes(), b"old-db")
        self.assertFalse((self.paths.state / "in-progress").exists())

    def test_late_log_failure_does_not_change_update_or_restore_results(self):
        original = helper.append_log
        calls = 0

        def fail_late(path, message):
            nonlocal calls
            calls += 1
            if calls > 1:
                raise OSError("fixture ログの書き込み失敗")
            return original(path, message)

        with patch.object(helper, "append_log", side_effect=fail_late):
            self.assertEqual(helper.main(), 0)
        self.assertEqual((self.paths.install / "codeg-server").read_text(), NEW)
        self.assertFalse((self.paths.state / "in-progress").exists())
        backup = next(path for path in self.paths.backups.iterdir() if not path.name.startswith("failed-"))
        calls = 0
        with patch.object(helper, "append_log", side_effect=fail_late):
            self.assertEqual(self.run_restore(backup), 0)
        self.assertEqual((self.paths.state / "skip-version").read_text().strip(), NEW)
        self.assertFalse((self.paths.state / "in-progress").exists())
        self.assertIn("専用ログへ書き込めない", self.output.getvalue())

    def test_backing_up_old_bin_move_does_not_create_two_complete_sources(self):
        self.paths.backups.mkdir()
        backup = self.paths.backups / ("20261015T043000Z-" + OLD)
        (backup / "db").mkdir(parents=True)
        (backup / "db/codeg.db").write_bytes(b"incomplete-do-not-use")
        os.rename(self.paths.install, backup / "bin")
        inode = (backup / "bin/codeg-server").stat().st_ino
        helper.progress(self.paths, "backing-up", backup, OLD, NEW)
        actual_rename = os.rename

        def fail_partial_backup_move(source, destination):
            if Path(source) == backup:
                raise OSError("fixture 部分控えの退避失敗")
            return actual_rename(source, destination)

        with patch.object(helper.os, "rename", side_effect=fail_partial_backup_move):
            self.assertEqual(self.run_restore(backup), 3)
        self.assertEqual((self.paths.install / "codeg-server").stat().st_ino, inode)
        self.assertFalse((backup / "bin").exists())
        self.assertEqual((self.paths.data / "codeg.db").read_bytes(), b"old-db")
        with patch.object(helper, "timestamp", return_value="20261016T043001Z"):
            self.assertEqual(self.run_restore(backup), 0)
        self.assertEqual((self.paths.data / "codeg.db").read_bytes(), b"old-db")

    def test_restore_restart_failed_before_backup_keeps_original_binary_and_database(self):
        with patch.object(helper, "stop", side_effect=helper.Failure("fixture 停止失敗")), \
             patch.object(helper, "check", side_effect=helper.Failure("fixture 起動確認失敗")):
            self.assertEqual(helper.main(), 3)
        information = json.loads((self.paths.state / "in-progress").read_text())
        self.assertEqual(information["stage"], "restart-failed")
        backup = Path(information["backup"])
        self.assertFalse(backup.exists())
        inode = (self.paths.install / "codeg-server").stat().st_ino
        self.assertEqual(self.run_restore(backup), 0)
        self.assertEqual((self.paths.install / "codeg-server").stat().st_ino, inode)
        self.assertEqual((self.paths.data / "codeg.db").read_bytes(), b"old-db")
        self.assertFalse((self.paths.state / "in-progress").exists())

    def test_main_writes_utf8_utc_log_and_still_prints(self):
        self.api_release = release(OLD)
        self.assertEqual(helper.main(), 0)
        contents = (self.paths.state / "codeg-auto-update.log").read_text(encoding="utf-8")
        self.assertIn("最新版 " + OLD + " を使用中", contents)
        self.assertIn("最新版 " + OLD + " を使用中", self.output.getvalue())
        for line in contents.splitlines():
            self.assertRegex(line, r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z .+$")
        self.assertFalse(contents.startswith("\ufeff"))

    def test_log_rotates_to_one_previous_generation_and_sanitizes_lines(self):
        logfile = self.paths.state / "codeg-auto-update.log"
        previous = logfile.with_name(logfile.name + ".1")
        previous.write_bytes(b"older-generation")
        oversized = b"x" * (2**20 + 1)
        logfile.write_bytes(oversized)
        with patch.object(helper, "LOG_PATH", logfile):
            helper.log("日本語の記録\n続き\r末尾")
        self.assertEqual(previous.read_bytes(), oversized)
        contents = logfile.read_text(encoding="utf-8")
        self.assertEqual(len(contents.splitlines()), 1)
        self.assertIn("日本語の記録 続き 末尾", contents)
        self.assertIn("日本語の記録 続き 末尾", self.output.getvalue())
        self.assertFalse(logfile.with_name(logfile.name + ".2").exists())
        logfile.write_bytes(b"y" * (2**20 + 1))
        with patch.object(helper, "LOG_PATH", logfile):
            helper.log("次の世代")
        self.assertEqual(previous.read_bytes(), b"y" * (2**20 + 1))
        self.assertIn("次の世代", logfile.read_text(encoding="utf-8"))


class NetworkTests(unittest.TestCase):
    class Response(io.BytesIO):
        def __init__(self, contents, url):
            super().__init__(contents)
            self.url = url

        def geturl(self):
            return self.url

    def test_redirects_reject_every_non_https_scheme_before_following(self):
        redirect = helper.HttpsRedirectHandler()
        request = helper.urllib.request.Request("https://fixture.invalid/start")
        for url in ("http://fixture.invalid/end", "ftp://fixture.invalid/end", "file:///fixture"):
            with self.subTest(url=url), self.assertRaises(helper.Failure):
                redirect.redirect_request(request, None, 302, "fixture", {}, url)
        redirected = redirect.redirect_request(request, None, 302, "fixture", {},
                                               "https://different-host.invalid/end")
        self.assertEqual(redirected.full_url, "https://different-host.invalid/end")

    def test_api_and_archive_reject_non_https_final_responses_without_reading(self):
        with tempfile.TemporaryDirectory(prefix="codeg-network-test-", dir=Path(__file__).parent) as temporary:
            destination = Path(temporary) / "archive.tar.gz"
            for operation in (helper.fetch_releases,
                              lambda: helper.download("https://fixture.invalid/start", destination)):
                response = self.Response(b"must-not-read", "http://fixture.invalid/end")
                with patch.object(response, "read", side_effect=AssertionError("HTTP の本文を読んだ")), \
                     patch.object(helper.urllib.request, "build_opener") as build:
                    build.return_value.open.return_value = response
                    with self.assertRaises(helper.Failure):
                        operation()
                    self.assertIsInstance(build.call_args.args[0], helper.HttpsRedirectHandler)
                self.assertTrue(response.closed)
                self.assertFalse(destination.exists())

    def test_api_accepts_https_on_a_different_distribution_host(self):
        releases = [release(NEW)]
        response = self.Response(json.dumps(releases).encode("utf-8"), "https://other-host.invalid/releases")
        with patch.object(helper.urllib.request, "build_opener") as build:
            build.return_value.open.return_value = response
            self.assertEqual(helper.fetch_releases(), releases)
            self.assertEqual(build.return_value.open.call_args.kwargs["timeout"], 30)
        self.assertTrue(response.closed)

    def test_archive_accepts_https_on_a_different_distribution_host(self):
        response = self.Response(b"public-fixture-archive", "https://other-host.invalid/archive")
        with tempfile.TemporaryDirectory(prefix="codeg-network-test-", dir=Path(__file__).parent) as temporary:
            destination = Path(temporary) / "archive.tar.gz"
            with patch.object(helper.urllib.request, "build_opener") as build:
                build.return_value.open.return_value = response
                helper.download("https://fixture.invalid/start", destination)
                self.assertEqual(build.return_value.open.call_args.kwargs["timeout"], 60)
            self.assertEqual(destination.read_bytes(), b"public-fixture-archive")
        self.assertTrue(response.closed)

    def test_download_rejects_initial_non_https_url_without_opening_anything(self):
        with patch.object(helper.urllib.request, "build_opener") as build:
            with self.assertRaises(helper.Failure):
                helper.download("http://fixture.invalid/start", Path("must-not-exist"))
        build.assert_not_called()


class SystemctlTests(unittest.TestCase):
    def test_bus_failure_retries_the_same_user_machine(self):
        failure = types.SimpleNamespace(returncode=1, stdout="", stderr="Failed to connect to user scope bus")
        success = types.SimpleNamespace(returncode=0, stdout="active\n", stderr="")
        with patch.object(helper.subprocess, "run", side_effect=[failure, success]) as run, \
             patch.object(helper.os, "getuid", return_value=1000, create=True), \
             patch.object(helper.pwd, "getpwuid", return_value=types.SimpleNamespace(pw_name="fixture")):
            self.assertEqual(helper.systemctl("show", "codeg-server.service"), "active")
        self.assertEqual(run.call_args_list[0].args[0], ["systemctl", "--user", "show", "codeg-server.service"])
        self.assertEqual(run.call_args_list[1].args[0], ["systemctl", "--user", "--machine=fixture@.host", "show", "codeg-server.service"])

    def test_non_bus_failures_are_not_retried_or_printed(self):
        failure = types.SimpleNamespace(returncode=1, stdout="private-fixture", stderr="private-fixture")
        with patch.object(helper.subprocess, "run", return_value=failure) as run:
            with self.assertRaises(helper.Failure) as raised:
                helper.systemctl("start", "codeg-server.service")
        self.assertEqual(run.call_count, 1)
        self.assertNotIn("private-fixture", str(raised.exception))


class VersionTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="codeg-version-test-", dir=Path(__file__).parent)
        self.addCleanup(self.temporary.cleanup)
        temporary_patch = patch.object(helper.tempfile, "tempdir", self.temporary.name)
        temporary_patch.start()
        self.addCleanup(temporary_patch.stop)

    def test_only_version_argument_and_disposable_environment_are_passed(self):
        received = []
        record = {}

        class FakeProcess:
            returncode = 0

            def __init__(self, args, **kwargs):
                received.extend(args)
                record.update(kwargs)
                kwargs["stdout"].write(b"0.35.2\n")
                self.pid = 12345

            def wait(self, timeout=None):
                return 0

        with patch.object(helper.subprocess, "Popen", FakeProcess), \
             patch.dict(os.environ, {"CODEG_TOKEN": "public-parent-fixture", "XDG_OTHER": "/not-fixture"}), \
             patch.object(helper, "unused_port", return_value=45454):
            self.assertEqual(helper.read_version(Path("/fake/codeg-server")), NEW)
        self.assertEqual(received, [str(Path("/fake/codeg-server")), "--version"])
        environment = record["env"]
        self.assertNotEqual(environment["CODEG_TOKEN"], "public-parent-fixture")
        self.assertNotIn("XDG_OTHER", environment)
        self.assertEqual(environment["CODEG_HOST"], "127.0.0.1")
        self.assertEqual(environment["CODEG_PORT"], "45454")
        for key in ("HOME", "TMPDIR", "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_STATE_HOME",
                    "XDG_CACHE_HOME", "XDG_RUNTIME_DIR", "CODEG_DATA_DIR", "CODEG_HOME"):
            self.assertEqual(environment[key], record["cwd"])
        self.assertEqual(environment["CODEG_BRIDGE_PORTS"], "off")
        self.assertEqual(environment["CODEG_BROWSER_TUNNEL"], "off")
        self.assertEqual(record["stderr"], subprocess.DEVNULL)
        self.assertTrue(record["start_new_session"])

    def test_version_timeout_kills_the_whole_process_group(self):
        class FakeProcess:
            pid = 99999
            returncode = -9

            def __init__(self, *args, **kwargs):
                self.waits = 0

            def wait(self, timeout=None):
                self.waits += 1
                if self.waits == 1:
                    raise subprocess.TimeoutExpired("public-fixture", timeout)
                return -9

        with patch.object(helper.subprocess, "Popen", FakeProcess), \
             patch.object(helper, "unused_port", return_value=45454), \
             patch.object(helper.os, "killpg", create=True) as kill, \
             patch.object(helper.signal, "SIGKILL", 9, create=True):
            with self.assertRaises(helper.VersionTimeout):
                helper.read_version(Path("/fake/codeg-server"))
        kill.assert_called_once_with(99999, 9)

    @unittest.skipIf(os.name == "nt", "偽の実行ファイルとプロセスグループの実行は Linux で確認する")
    def test_fake_binary_records_its_actual_arguments(self):
        with tempfile.TemporaryDirectory(prefix="codeg-version-test-", dir=Path(__file__).parent) as temporary:
            directory = Path(temporary)
            record = directory / "arguments.json"
            binary = directory / "fake-codeg"
            binary.write_text("#!" + sys.executable + "\nimport json,sys\n"
                              + "with open(" + repr(str(record)) + ", 'w') as f: json.dump(sys.argv[1:], f)\n"
                              + "print('0.35.2')\n", encoding="utf-8")
            binary.chmod(0o700)
            self.assertEqual(helper.read_version(binary), NEW)
            self.assertEqual(json.loads(record.read_text()), ["--version"])


if __name__ == "__main__":
    unittest.main()
