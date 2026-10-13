#!/usr/bin/python3
"""実ホストを操作せず、公開固定値と一時ディレクトリで安全性を検証する。"""

import contextlib
import importlib.util
import io
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "codeg_password_helper", Path(__file__).with_name("set-codeg-password.py")
)
helper = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = helper
spec.loader.exec_module(helper)
PUBLIC_OLD = b'CODEG_TOKEN="public-test-fixture-old-0123456789"\n'
PUBLIC_NEW = 'public-test-fixture-new-0123456789\\"$`!'


class PasswordHelperTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.directory_path = Path(self.temporary.name)
        self.path = self.directory_path / "token.env"
        self.path.write_bytes(PUBLIC_OLD)
        self.path.chmod(0o600)
        self.directory = helper.open_settings_directory(self.directory_path)
        self.original = helper.file_metadata(self.directory)

    def tearDown(self):
        os.close(self.directory)
        self.temporary.cleanup()

    def run_update(self, start_effect=None, health_effect=None, replace_effect=None):
        output = io.StringIO()
        identity = object()
        start_effect = start_effect or [identity, identity]
        with contextlib.redirect_stdout(output), contextlib.redirect_stderr(output), \
             patch.object(helper, "stop_service") as stop, \
             patch.object(helper, "start_service", side_effect=start_effect), \
             patch.object(helper, "health", side_effect=health_effect), \
             patch.object(helper.os, "replace", side_effect=replace_effect, wraps=os.replace):
            result = helper.update_password(self.directory, self.original, Path("/public/test/codeg-server"), PUBLIC_NEW)
        self.assertNotIn(PUBLIC_NEW, output.getvalue())
        self.assertNotIn(PUBLIC_OLD.decode(), output.getvalue())
        return result, output.getvalue(), stop.call_count

    def assert_old_restored(self):
        self.assertEqual(self.path.read_bytes(), PUBLIC_OLD)
        self.assertEqual(self.path.stat().st_ino, self.original.st_ino)
        self.assertEqual(self.path.stat().st_mode & 0o777, 0o600)
        self.assertEqual(sorted(p.name for p in self.directory_path.iterdir()), ["token.env"])

    def test_quotes_and_backslashes_are_encoded_for_environment_file(self):
        self.assertEqual(helper.environment_line(PUBLIC_NEW), b'CODEG_TOKEN="public-test-fixture-new-0123456789\\\\\\"$`!"\n')
        for invalid in ("short", "a" * 513, "a" * 31 + " ", "a" * 31 + "\n", "a" * 31 + "あ"):
            with self.assertRaises(helper.SafeError):
                helper.environment_line(invalid)

    def test_symlink_and_insecure_permissions_are_rejected(self):
        self.path.unlink()
        self.path.symlink_to("/public/nonexistent-fixture")
        with self.assertRaises(helper.SafeError):
            helper.file_metadata(self.directory)
        self.path.unlink()
        self.path.write_bytes(PUBLIC_OLD)
        self.path.chmod(0o644)
        with self.assertRaises(helper.SafeError):
            helper.file_metadata(self.directory)
        link = self.directory_path / "directory-link"
        link.symlink_to(self.directory_path, target_is_directory=True)
        with self.assertRaises(helper.SafeError):
            helper.open_settings_directory(link)

    def test_success_replaces_inode_and_keeps_owner_only_backup(self):
        result, _, _ = self.run_update()
        self.assertEqual(result, 0)
        self.assertEqual(self.path.read_bytes(), helper.environment_line(PUBLIC_NEW))
        self.assertNotEqual(self.path.stat().st_ino, self.original.st_ino)
        self.assertEqual(self.path.stat().st_mode & 0o777, 0o600)
        backups = list(self.directory_path.glob(".token.env.backup-*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_bytes(), PUBLIC_OLD)
        self.assertEqual(backups[0].stat().st_ino, self.original.st_ino)
        self.assertEqual(backups[0].stat().st_mode & 0o777, 0o600)
        self.assertEqual(len(list(self.directory_path.iterdir())), 2)

    def test_second_change_lock_is_rejected(self):
        first = helper.acquire_change_lock(self.directory)
        try:
            with self.assertRaises(helper.SafeError):
                helper.acquire_change_lock(self.directory)
        finally:
            os.close(first)

    def test_journal_output_is_rejected_before_service_start(self):
        home = Path(helper.pwd.getpwuid(os.getuid()).pw_dir)
        expected = str(home / ".config/codeg-server/token.env") + " (ignore_errors=no)"
        with patch.object(helper, "systemctl", side_effect=[expected, "journal"]) as commands:
            with self.assertRaises(helper.SafeError):
                helper.start_service(Path("/public/test/codeg-server"))
        self.assertTrue(all("start" not in call.args for call in commands.call_args_list))

    def test_restart_failure_restores_original_inode_and_file(self):
        result, _, stops = self.run_update(start_effect=[helper.SafeError("公開fixture起動失敗"), object()])
        self.assertEqual(result, 1)
        self.assertEqual(stops, 2)
        self.assert_old_restored()

    def test_authentication_failure_restores_original_inode_and_file(self):
        result, _, _ = self.run_update(health_effect=[helper.SafeError("公開fixture認証失敗"), None])
        self.assertEqual(result, 1)
        self.assert_old_restored()

    def test_replace_failure_preserves_original_and_cleans_backup(self):
        actual_replace = os.replace
        calls = 0

        def replace_once_failed(*args, **kwargs):
            nonlocal calls
            calls += 1
            if calls == 1:
                raise OSError("公開fixture置換失敗")
            return actual_replace(*args, **kwargs)

        result, _, _ = self.run_update(replace_effect=replace_once_failed)
        self.assertEqual(result, 1)
        self.assert_old_restored()

    def test_failed_recovery_is_explicitly_unknown(self):
        result, output, _ = self.run_update(start_effect=[helper.SafeError("公開fixture失敗"), helper.SafeError("公開fixture復帰失敗")])
        self.assertEqual(result, 2)
        self.assertIn("結果: 不明", output)
        self.assert_old_restored()

    def test_interrupt_after_completed_rename_restores_old_file(self):
        actual_replace = os.replace
        calls = 0

        def replace_then_interrupt(*args, **kwargs):
            nonlocal calls
            calls += 1
            actual_replace(*args, **kwargs)
            if calls == 1:
                raise KeyboardInterrupt()

        result, _, _ = self.run_update(replace_effect=replace_then_interrupt)
        self.assertEqual(result, 1)
        self.assert_old_restored()

    def test_unknown_external_replacement_preserves_backup(self):
        def external_change(*args):
            unrelated = self.directory_path / "public-unrelated-fixture"
            unrelated.write_bytes(b"public-unrelated-file\n")
            unrelated.chmod(0o600)
            os.replace(unrelated, self.path)
            raise helper.SafeError("公開fixture外部変更")

        result, output, _ = self.run_update(start_effect=external_change)
        self.assertEqual(result, 2)
        self.assertIn("結果: 不明", output)
        backups = list(self.directory_path.glob(".token.env.backup-*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_bytes(), PUBLIC_OLD)
        self.assertEqual(self.path.read_bytes(), b"public-unrelated-file\n")


if __name__ == "__main__":
    unittest.main()
