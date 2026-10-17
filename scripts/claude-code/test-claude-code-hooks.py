#!/usr/bin/env python3
"""Test the guard and installer using subprocesses and temporary settings only."""

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
GUARD = SCRIPT_DIR / "no-color-guard.py"
INSTALLER = SCRIPT_DIR / "setup-claude-code-hooks.py"
BLOCK = [
    r"$p = Start-Process 'C:\Program Files\WezTerm\wezterm-gui.exe' -ArgumentList 'start','--','pwsh' -PassThru",
    r"$wez = Join-Path $env:ProgramFiles 'WezTerm\wezterm-gui.exe'; Start-Process $wez -PassThru",
    "wezterm start --always-new-process -- lazygit",
    "wezterm cli spawn --new-window -- pwsh",
    "wt.exe new-tab pwsh",
    "Start-Process wt",
    "Start-Process pwsh -ArgumentList '-NoExit'",
    "Start-Process -FilePath powershell.exe",
    "tmux new-session -d -s x lazygit",
    "cd repo && lazygit",
    "lazygit --use-config-dir C:\\tmp\\x",
    "Set-Location C:\\x; lazygit",
    "echo 確かめ  # tmux new-session (日本語を含む)",
    "Set-Location C:\\作業\\見積; lazygit",
    "tmux -2 new-session -d",
    "tmux -L dev new-session -d -s x",
    "tmux -u -f ~/.tmux.conf new",
    "/usr/local/bin/lazygit",
    "~/.local/bin/lazygit -p ~/repo",
    r"& 'C:\Users\x\scoop\shims\lazygit.exe'",
]
ALLOW = [
    r"$env:NO_COLOR = $null; Start-Process 'C:\Program Files\WezTerm\wezterm-gui.exe' -PassThru",
    "env -u NO_COLOR tmux new-session -d -s x lazygit",
    "wezterm cli send-text --pane-id 0 --no-paste j",
    "wezterm cli get-text --pane-id 0",
    "wezterm --version",
    "lazygit --version",
    'git -C "$env:LOCALAPPDATA\\lazygit" status --short --branch',
    "git -C C:\\tmp\\xd-lazygit log --oneline -3",
    'git commit -m "lazygit の設定と Excel の差分の道具を分ける"',
    "gh pr view 34 --repo ryo-aoki-pc/lazygit --json state",
    "/c/Windows/System32/OpenSSH/ssh.exe -o BatchMode=yes abiko-pi 'bash -l -s' <<'EOS'\ntmux new-session -d -s xd lazygit\nEOS",
    "wsl -d AlmaLinux-10 -e bash -lc 'tmux new-session -d -s x'",
    r"Start-Process $wm -ArgumentList '/s-','/e' -PassThru",
    "python scripts/setup-excel-diff.py --check",
    "scoop install lazygit",
    "winget list --id JesseDuffield.lazygit",
    "git log --oneline -- lazygit",
    "git diff HEAD~1 -- lazygit",
    "tmux -L dev send-keys -t x q",
    "ls ~/.config/lazygit",
    "/usr/local/bin/lazygit --version",
]


class GuardTests(unittest.TestCase):
    def run_guard(self, payload):
        environment = os.environ.copy()
        # Reproduce Windows' ANSI pipe decoding even on a Linux test host.
        environment["PYTHONIOENCODING"] = "cp932"
        result = subprocess.run(
            [sys.executable, "-B", str(GUARD)],
            input=payload,
            capture_output=True,
            env=environment,
            timeout=15,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, b"")
        return result.stdout

    def assert_decision(self, command, expected, tool_name="PowerShell"):
        payload = json.dumps(
            {"tool_name": tool_name, "tool_input": {"command": command}},
            ensure_ascii=False,
        ).encode("utf-8")
        output = self.run_guard(payload)
        if expected == "allow":
            self.assertEqual(output, b"", command)
            return
        decision = json.loads(output.decode("utf-8"))["hookSpecificOutput"]
        self.assertEqual(decision["hookEventName"], "PreToolUse")
        self.assertEqual(decision["permissionDecision"], "deny", command)
        self.assertIn("NO_COLOR=1", decision["permissionDecisionReason"])
        self.assertIn("このツールの環境には", decision["permissionDecisionReason"])

    def test_bash_payload_with_japanese_is_denied(self):
        self.assert_decision("echo 確かめ  # tmux new-session", "deny", "Bash")

    def test_empty_and_invalid_input_allow(self):
        for payload in (b"", b"not json", b"{", b"\xff"):
            with self.subTest(payload=payload):
                self.assertEqual(self.run_guard(payload), b"")


def decision_test(command, expected):
    def test(self):
        self.assert_decision(command, expected)
    return test


# Keep every original example visible as an individual unittest result.
for expected, commands in (("deny", BLOCK), ("allow", ALLOW)):
    for index, command in enumerate(commands, 1):
        setattr(GuardTests, "test_{}_{:02d}".format(expected, index),
                decision_test(command, expected))


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="claude-code-hooks-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.config = self.root / "設定 with spaces"
        self.settings = self.config / "settings.json"
        self.hook = self.config / "hooks" / "no-color-guard.py"
        self.environment = os.environ.copy()
        self.environment["CLAUDE_CONFIG_DIR"] = str(self.config)
        self.environment["PYTHONIOENCODING"] = "utf-8"
        # Also isolate the fallback path if a regression ignores the override.
        self.home = self.root / "home"
        self.home.mkdir()
        self.environment["HOME"] = str(self.home)
        self.environment["USERPROFILE"] = str(self.home)

    def run_installer(self, *arguments, expected=0, environment=None):
        result = subprocess.run(
            [sys.executable, "-B", str(INSTALLER), *arguments],
            capture_output=True,
            env=environment if environment is not None else self.environment,
            timeout=15,
        )
        output = (result.stdout + result.stderr).decode("utf-8")
        self.assertEqual(result.returncode, expected, output)
        self.assertRegex(output, "[ぁ-んァ-ヶ一-龯]", output)
        return output

    def write_settings(self, value):
        self.config.mkdir(parents=True, exist_ok=True)
        self.settings.write_text(
            json.dumps(value, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    def read_settings(self):
        return json.loads(self.settings.read_text(encoding="utf-8"))

    def expected_entry(self, config=None):
        path = ((config or self.config) / "hooks" / "no-color-guard.py").resolve()
        command = '{} "{}"'.format(
            "python" if os.name == "nt" else "python3",
            path.as_posix() if os.name == "nt" else str(path),
        )
        return {
            "matcher": "Bash|PowerShell",
            "hooks": [{
                "type": "command",
                "command": command,
                "timeout": 10,
                "statusMessage": "NO_COLOR の引き継ぎを確かめています",
            }],
        }

    def snapshot(self):
        return {
            str(path.relative_to(self.root)): (
                path.read_bytes(), path.stat().st_mtime_ns
            )
            for path in self.root.rglob("*") if path.is_file()
        }, sorted(str(path.relative_to(self.root)) for path in self.root.rglob("*"))

    def assert_installation(self):
        entries = self.read_settings()["hooks"]["PreToolUse"]
        self.assertEqual(entries.count(self.expected_entry()), 1)
        guard_hooks = [
            hook for entry in entries for hook in entry.get("hooks", [])
            if "no-color-guard.py" in hook.get("command", "")
        ]
        self.assertEqual(len(guard_hooks), 1)
        self.assertEqual(self.hook.read_bytes(), GUARD.read_bytes())

    def test_install_without_settings_creates_current_hook(self):
        output = self.run_installer()
        self.assert_installation()
        self.assertEqual(self.read_settings(), {
            "hooks": {"PreToolUse": [self.expected_entry()]}
        })
        self.assertIn("Claude Code", output)
        self.assertIn("設定", output)

    def test_install_twice_preserves_other_settings_hooks_and_key_order(self):
        read_hook = {"matcher": "Read", "hooks": [{
            "type": "command", "command": "echo read-hook"
        }]}
        bash_hook = {"matcher": "Bash", "hooks": [{
            "type": "command", "command": "echo bash-hook"
        }]}
        session_hooks = [{"hooks": [{"type": "command", "command": "echo start"}]}]
        original = {
            "theme": "dark",
            "permissions": {"allow": ["Bash(git status:*)"]},
            "hooks": {"SessionStart": session_hooks, "PreToolUse": [read_hook, bash_hook]},
            "language": "日本語",
        }
        self.write_settings(original)
        self.run_installer()
        self.assert_installation()
        first = self.read_settings()
        self.assertEqual(list(first), list(original))
        self.assertEqual(list(first["hooks"]), list(original["hooks"]))
        self.assertEqual(first["theme"], original["theme"])
        self.assertEqual(first["permissions"], original["permissions"])
        self.assertEqual(first["language"], original["language"])
        self.assertEqual(first["hooks"]["SessionStart"], session_hooks)
        self.assertEqual(
            [entry for entry in first["hooks"]["PreToolUse"]
             if entry != self.expected_entry()], [read_hook, bash_hook]
        )
        self.assertIn('\n  "theme":', self.settings.read_text(encoding="utf-8"))
        self.assertIn('\n    "SessionStart":', self.settings.read_text(encoding="utf-8"))
        self.run_installer()
        self.assert_installation()
        self.assertEqual(self.read_settings(), first)

    def test_install_replaces_old_command_and_args_without_losing_sibling(self):
        sibling = {"type": "command", "command": "echo keep-this-hook", "timeout": 5}
        separate = {"matcher": "Read", "hooks": [{
            "type": "command", "command": "echo keep-separate"
        }]}
        self.write_settings({"hooks": {"PreToolUse": [
            {"matcher": "Bash", "hooks": [
                {"type": "command", "command": "python", "args": ["C:/old/no-color-guard.py"]},
                sibling,
            ]},
            {"matcher": "PowerShell", "hooks": [{
                "type": "command", "command": 'python "C:/old/no-color-guard.py"',
                "timeout": 2,
            }]},
            separate,
        ]}})
        self.run_installer()
        self.assert_installation()
        entries = self.read_settings()["hooks"]["PreToolUse"]
        self.assertIn({"matcher": "Bash", "hooks": [sibling]}, entries)
        self.assertIn(separate, entries)
        self.assertEqual(len(entries), 3)

    def test_check_succeeds_without_changing_files(self):
        self.run_installer()
        before = self.snapshot()
        self.run_installer("--check")
        self.assertEqual(self.snapshot(), before)

    def test_check_missing_settings_does_not_create_anything(self):
        before = self.snapshot()
        self.run_installer("--check", expected=1)
        self.assertEqual(self.snapshot(), before)

    def test_check_changed_hook_fails_and_reinstall_repairs_it(self):
        self.run_installer()
        self.hook.write_bytes(b"old hook body\n")
        before = self.snapshot()
        self.run_installer("--check", expected=1)
        self.assertEqual(self.snapshot(), before)
        self.run_installer()
        self.assert_installation()
        self.run_installer("--check")

    def test_check_missing_hook_fails_without_changes(self):
        self.run_installer()
        self.hook.unlink()
        before = self.snapshot()
        self.run_installer("--check", expected=1)
        self.assertEqual(self.snapshot(), before)

    def test_check_old_settings_and_duplicate_entries_fail_without_changes(self):
        self.run_installer()
        for duplicate in (False, True):
            with self.subTest(duplicate=duplicate):
                entry = self.expected_entry()
                if duplicate:
                    entries = [entry, entry]
                else:
                    entry["hooks"][0]["timeout"] = 2
                    entries = [entry]
                self.write_settings({"hooks": {"PreToolUse": entries}})
                before = self.snapshot()
                self.run_installer("--check", expected=1)
                self.assertEqual(self.snapshot(), before)

    def test_uninstall_preserves_other_settings_and_hooks_and_second_is_noop(self):
        self.run_installer()
        other = {"matcher": "Bash", "hooks": [{
            "type": "command", "command": "echo preserve"
        }]}
        session = [{"hooks": [{"type": "command", "command": "echo session"}]}]
        self.write_settings({
            "theme": "dark",
            "hooks": {"PreToolUse": [self.expected_entry(), other], "SessionStart": session},
            "language": "日本語",
        })
        self.run_installer("--uninstall")
        self.assertFalse(self.hook.exists())
        self.assertEqual(self.read_settings(), {
            "theme": "dark",
            "hooks": {"PreToolUse": [other], "SessionStart": session},
            "language": "日本語",
        })
        before = self.snapshot()
        output = self.run_installer("--uninstall")
        self.assertIn("消すものがありません", output)
        self.assertEqual(self.snapshot(), before)

    def test_uninstall_removes_empty_pretooluse_and_hooks(self):
        self.run_installer()
        self.write_settings({"theme": "dark", "hooks": {
            "PreToolUse": [self.expected_entry()]
        }})
        self.run_installer("--uninstall")
        self.assertEqual(self.read_settings(), {"theme": "dark"})
        self.assertFalse(self.hook.exists())

    def test_uninstall_without_settings_creates_nothing(self):
        before = self.snapshot()
        for unused in range(2):
            output = self.run_installer("--uninstall")
            self.assertIn("消すものがありません", output)
            self.assertEqual(self.snapshot(), before)

    def test_uninstall_without_guard_preserves_existing_empty_hooks(self):
        for hooks in ({}, {"PreToolUse": []}):
            with self.subTest(hooks=hooks):
                self.write_settings({"theme": "dark", "hooks": hooks})
                before = self.snapshot()
                output = self.run_installer("--uninstall")
                self.assertIn("消すものがありません", output)
                self.assertEqual(self.snapshot(), before)

    def test_invalid_json_stops_all_modes_without_changing_files(self):
        self.config.mkdir()
        self.settings.write_bytes('{"theme": "日本語", broken'.encode("utf-8"))
        for existing_hook in (False, True):
            if existing_hook:
                self.hook.parent.mkdir()
                self.hook.write_bytes(b"existing hook must stay\n")
            for arguments in ((), ("--check",), ("--uninstall",)):
                with self.subTest(existing_hook=existing_hook, arguments=arguments):
                    before = self.snapshot()
                    self.run_installer(*arguments, expected=1)
                    self.assertEqual(self.snapshot(), before)

    def test_invalid_settings_shapes_stop_without_changes(self):
        for value in ([], {"hooks": []}, {"hooks": {"PreToolUse": {}}}):
            with self.subTest(value=value):
                self.write_settings(value)
                before = self.snapshot()
                self.run_installer(expected=1)
                self.assertEqual(self.snapshot(), before)

    def test_default_config_directory_uses_temporary_home(self):
        environment = self.environment.copy()
        del environment["CLAUDE_CONFIG_DIR"]
        self.run_installer(environment=environment)
        fallback = self.home / ".claude"
        self.assertEqual((fallback / "hooks" / "no-color-guard.py").read_bytes(), GUARD.read_bytes())
        settings = json.loads((fallback / "settings.json").read_text(encoding="utf-8"))
        self.assertEqual(settings, {"hooks": {"PreToolUse": [self.expected_entry(fallback)]}})
        self.assertFalse(self.config.exists())


if __name__ == "__main__":
    unittest.main()
