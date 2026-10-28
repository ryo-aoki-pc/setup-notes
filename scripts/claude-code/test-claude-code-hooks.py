#!/usr/bin/env python3
"""Test the hooks and installer using subprocesses and temporary settings only."""

import json
import os
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
GUARD = SCRIPT_DIR / "no-color-guard.py"
REAPER = SCRIPT_DIR / "codex-reaper.py"
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
        self.reaper = self.config / "hooks" / "codex-reaper.py"
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

    def command(self, name, config=None):
        path = ((config or self.config) / "hooks" / name).resolve()
        return '{} "{}"'.format(
            "python" if os.name == "nt" else "python3",
            path.as_posix() if os.name == "nt" else str(path),
        )

    def reaper_entry(self, config=None):
        return {"hooks": [{
            "type": "command",
            "command": self.command("codex-reaper.py", config),
            "async": True,
        }]}

    def expected_settings(self, config=None):
        return {"hooks": {
            "PreToolUse": [self.expected_entry(config)],
            "SessionStart": [self.reaper_entry(config)],
        }}

    def expected_entry(self, config=None):
        command = self.command("no-color-guard.py", config)
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
        session = self.read_settings()["hooks"]["SessionStart"]
        self.assertEqual(session.count(self.reaper_entry()), 1)
        reaper_hooks = [
            hook for entry in session for hook in entry.get("hooks", [])
            if "codex-reaper.py" in hook.get("command", "")
        ]
        self.assertEqual(len(reaper_hooks), 1)
        self.assertEqual(self.reaper.read_bytes(), REAPER.read_bytes())

    def test_install_without_settings_creates_current_hook(self):
        output = self.run_installer()
        self.assert_installation()
        self.assertEqual(self.read_settings(), self.expected_settings())
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
        self.assertEqual(first["hooks"]["SessionStart"], session_hooks + [self.reaper_entry()])
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
                self.write_settings({"hooks": {"PreToolUse": entries, "SessionStart": [self.reaper_entry()]}})
                before = self.snapshot()
                self.run_installer("--check", expected=1)
                self.assertEqual(self.snapshot(), before)

    def test_check_changed_or_old_reaper_fails_and_reinstall_repairs_it(self):
        self.run_installer()
        self.reaper.write_bytes(b"old reaper body\n")
        self.run_installer("--check", expected=1)
        self.run_installer()
        old = self.reaper_entry()
        old["hooks"][0]["timeout"] = 30
        del old["hooks"][0]["async"]
        self.write_settings({"hooks": {"PreToolUse": [self.expected_entry()], "SessionStart": [old]}})
        output = self.run_installer("--check", expected=1)
        self.assertIn("codex-reaper.py", output)
        self.run_installer()
        self.assertEqual(self.read_settings(), self.expected_settings())
        self.run_installer("--check")

    def test_uninstall_preserves_other_settings_and_hooks_and_second_is_noop(self):
        self.run_installer()
        other = {"matcher": "Bash", "hooks": [{
            "type": "command", "command": "echo preserve"
        }]}
        session = [{"hooks": [{"type": "command", "command": "echo session"}]}]
        self.write_settings({
            "theme": "dark",
            "hooks": {"PreToolUse": [self.expected_entry(), other],
                      "SessionStart": session + [self.reaper_entry()]},
            "language": "日本語",
        })
        self.run_installer("--uninstall")
        self.assertFalse(self.hook.exists())
        self.assertFalse(self.reaper.exists())
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
            "PreToolUse": [self.expected_entry()], "SessionStart": [self.reaper_entry()]
        }})
        self.run_installer("--uninstall")
        self.assertEqual(self.read_settings(), {"theme": "dark"})
        self.assertFalse(self.hook.exists())
        self.assertFalse(self.reaper.exists())

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
        for value in ([], {"hooks": []}, {"hooks": {"PreToolUse": {}}}, {"hooks": {"SessionStart": [1]}}):
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
        self.assertEqual((fallback / "hooks" / "codex-reaper.py").read_bytes(), REAPER.read_bytes())
        self.assertEqual(settings, self.expected_settings(fallback))
        self.assertFalse(self.config.exists())


class ReaperTests(unittest.TestCase):
    """Only --dry-run with a fake process list: nothing real is ever killed."""

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="codex-reaper-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.environment = os.environ.copy()
        self.environment["CLAUDE_CONFIG_DIR"] = str(self.root / "config")
        self.environment["PYTHONIOENCODING"] = "utf-8"
        self.now = time.time()

    def broker(self, pid, hours, cwd, pid_file=None):
        cmdline = r"C:\scoop\nodejs\node.exe C:\Users\x\.claude\plugins\cache\openai-codex\codex\1.0.6\scripts\app-server-broker.mjs serve --endpoint pipe:\\.\pipe\cxc-a-codex-app-server"
        if cwd is not None:
            cmdline += " --cwd " + (cwd if " " not in cwd else '"{}"'.format(cwd))
        cmdline += " --pid-file " + (pid_file or r"C:\Temp\cxc-{}\broker.pid".format(pid))
        return {"pid": pid, "started": self.now - hours * 3600, "cmdline": cmdline}

    def companion(self, pid, cwd, command="task"):
        return {"pid": pid, "started": self.now - 60, "argv": [
            "/usr/bin/node", "/home/x/.claude/plugins/cache/openai-codex/codex/1.0.6/scripts/codex-companion.mjs",
            command, "--cwd", cwd,
        ]}

    def run_reaper(self, processes, *arguments, expected=0):
        listing = self.root / "processes.json"
        listing.write_text(json.dumps(processes, ensure_ascii=False), encoding="utf-8")
        result = subprocess.run(
            [sys.executable, "-B", str(REAPER), "--dry-run", "--processes-from", str(listing), *arguments],
            capture_output=True, env=self.environment, timeout=15,
        )
        output = (result.stdout + result.stderr).decode("utf-8")
        self.assertEqual(result.returncode, expected, output)
        return output

    def decisions(self, output):
        return {
            int(line.split("PID ")[1].split("（")[0]): line.split(":")[0]
            for line in output.splitlines() if line.startswith(("消す:", "残す:"))
        }

    def test_old_unused_broker_is_killed_and_young_one_kept(self):
        output = self.run_reaper([
            self.broker(101, 5, "C:/Users/x/Temp/claude/a/scratchpad/codex-wt"),
            self.broker(102, 1, "C:/Users/x/Temp/claude/b/scratchpad/codex-wt"),
        ])
        self.assertEqual(self.decisions(output), {101: "消す", 102: "残す"})
        self.assertIn("何も変更していません", output)

    def test_broker_used_by_companion_is_kept_across_separators_and_case(self):
        output = self.run_reaper([
            self.broker(201, 5, "C:/Users/x/Temp/claude/a/scratchpad/codex-wt"),
            self.broker(202, 5, "C:/Users/x/Temp/claude/b/scratchpad/codex-wt"),
            self.broker(203, 5, "C:/Users/x/Temp/claude/a/scratchpad/codex-wt2"),
            self.companion(301, r"c:\users\x\temp\claude\a\scratchpad\codex-wt\sub", "task-worker"),
        ])
        self.assertEqual(self.decisions(output), {201: "残す", 202: "消す", 203: "消す"})

    def test_companion_without_cwd_keeps_every_broker(self):
        companion = self.companion(301, "/tmp")
        companion["argv"] = companion["argv"][:3]
        output = self.run_reaper([self.broker(401, 5, "C:/a"), companion])
        self.assertEqual(self.decisions(output), {401: "残す"})

    def test_broker_without_cwd_and_quoted_cwd(self):
        output = self.run_reaper([
            self.broker(501, 5, None),
            self.broker(502, 5, "C:/Users/x/作業 フォルダ/codex"),
            self.companion(301, "C:/Users/x/作業 フォルダ/codex"),
        ])
        self.assertEqual(self.decisions(output), {501: "残す", 502: "残す"})

    def test_other_codex_processes_are_not_brokers(self):
        output = self.run_reaper([
            {"pid": 601, "started": self.now - 9 * 3600, "cmdline": r'"C:\Users\x\AppData\Local\OpenAI\Codex\bin\codex.exe" app-server'},
            {"pid": 602, "started": self.now - 9 * 3600, "cmdline": r"C:\Program Files\ChatGPT\ChatGPT.exe --type=renderer"},
            {"pid": 603, "started": self.now - 9 * 3600, "cmdline": "node app-server-broker.mjs status"},
        ])
        self.assertEqual(self.decisions(output), {})
        self.assertIn("消すもの 0 個", output)

    def test_single_object_listing_and_min_age_option(self):
        output = self.run_reaper(self.broker(701, 1, "C:/a"), "--min-age-hours", "0.5")
        self.assertEqual(self.decisions(output), {701: "消す"})

    def test_processes_from_requires_dry_run_and_bad_listing_stops(self):
        listing = self.root / "processes.json"
        listing.write_text("[]", encoding="utf-8")
        result = subprocess.run(
            [sys.executable, "-B", str(REAPER), "--processes-from", str(listing)],
            capture_output=True, env=self.environment, timeout=15,
        )
        self.assertNotEqual(result.returncode, 0)
        listing.write_text("{broken", encoding="utf-8")
        result = subprocess.run(
            [sys.executable, "-B", str(REAPER), "--dry-run", "--processes-from", str(listing)],
            capture_output=True, env=self.environment, timeout=15,
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("中断:", result.stderr.decode("utf-8"))
        self.assertFalse((self.root / "config").exists())


if __name__ == "__main__":
    unittest.main()
