"""PreToolUse guard: do not start a terminal window or TUI with NO_COLOR set.

Claude Code's Bash/PowerShell tools run with NO_COLOR=1. A terminal window
(WezTerm, Windows Terminal, a new console) or a TUI (lazygit, tmux) started
from them inherits it, and lazygit/delta then draw without any colors. This
has been rediscovered in several sessions, so the launch is stopped here
until the command clears NO_COLOR itself.

Commands that mention NO_COLOR are allowed (they handle it), and so are
commands run through ssh or wsl, which do not pass NO_COLOR on.
"""

import json
import re
import sys

LAUNCHES = [
    r"\bwezterm-gui(?:\.exe)?\b",
    r"\bwezterm(?:\.exe)?['\"]?\s+(?:start|cli\s+spawn|ssh|connect|serial)\b",
    r"(?:^|[;&|({]|\bStart-Process\b)\s*['\"]?wt(?:\.exe)?['\"]?(?=\s|$|[;&|)}])",
    r"\bStart-Process\b[^;\n|]*?\b(?:pwsh|powershell|cmd|conhost|bash|mintty|git-bash|wt)(?:\.exe)?\b",
    r"\btmux\s+(?:new-session|new|new-window|neww|split-window|splitw|respawn-pane)\b",
    r"(?:^|[;&|({]|\bexec\b|--)\s*['\"]?lazygit(?:\.exe)?['\"]?(?!\s+(?:--version|-v|--help|-h|--print-config-dir|--print-default-config)\b)(?=\s|$|[;&|)}])",
]
REMOTE = re.compile(r"(?:^|[\s;&|('\"/\\])(?:ssh|wsl)(?:\.exe)?['\"]?\s", re.IGNORECASE | re.MULTILINE)


def main():
    # The payload is UTF-8; Windows Python would decode a pipe with the ANSI
    # code page and fail on Japanese text, silently letting everything pass.
    try:
        payload = json.loads(sys.stdin.buffer.read().decode("utf-8"))
    except ValueError:
        return 0
    command = (payload.get("tool_input") or {}).get("command") or ""
    if not command or "NO_COLOR" in command or REMOTE.search(command):
        return 0
    if not any(re.search(pattern, command, re.IGNORECASE | re.MULTILINE) for pattern in LAUNCHES):
        return 0
    reason = (
        "このツールの環境には NO_COLOR=1 があり、ここから開いた端末の窓や TUI（WezTerm・Windows Terminal・"
        "新しいコンソール・lazygit・tmux）に引き継がれて、lazygit や delta の色が消える。"
        "起動するコマンドの中で先に外してから実行し直すこと。"
        "PowerShell は `$env:NO_COLOR = $null`、bash は `unset NO_COLOR` か `env -u NO_COLOR <コマンド>`。"
        "色を消したまま開くのが目的なら、コマンドに NO_COLOR と書いてあれば通す。"
    )
    output = {"hookSpecificOutput": {"hookEventName": "PreToolUse",
                                     "permissionDecision": "deny",
                                     "permissionDecisionReason": reason}}
    sys.stdout.buffer.write(json.dumps(output, ensure_ascii=False).encode("utf-8"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
