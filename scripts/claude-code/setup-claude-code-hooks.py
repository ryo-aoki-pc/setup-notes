"""Install, check, or remove the Claude Code NO_COLOR guard (Python 3.9+)."""

import argparse
import copy
import json
import os
from pathlib import Path
import re
import sys
import tempfile


GUARD_NAME = "no-color-guard.py"
GUARD_PATTERN = re.compile(r"(?<![\w.-])no-color-guard\.py(?![\w.-])", re.IGNORECASE)
RELOAD_MESSAGE = (
    "Claude Code を起動し直すか、動いているセッションでは設定が読み直されるまで待ってください。"
)


class SetupError(Exception):
    pass


def config_directory():
    override = os.environ.get("CLAUDE_CONFIG_DIR")
    return (Path(override).expanduser() if override else Path.home() / ".claude").resolve()


def expected_entry(target):
    interpreter = "python" if os.name == "nt" else "python3"
    path = target.as_posix() if os.name == "nt" else str(target)
    # Claude Code runs the command through a shell, including Git Bash on Windows.
    quoted = path.replace("\\", "\\\\").replace('"', '\\"').replace("$", "\\$").replace(chr(96), "\\" + chr(96))
    return {
        "matcher": "Bash|PowerShell",
        "hooks": [
            {
                "type": "command",
                "command": '{} "{}"'.format(interpreter, quoted),
                "timeout": 10,
                "statusMessage": "NO_COLOR の引き継ぎを確かめています",
            }
        ],
    }


def is_guard(hook):
    command = hook.get("command", "")
    args = hook.get("args", [])
    values = [command]
    if isinstance(args, str):
        values.append(args)
    elif isinstance(args, list):
        values.extend(args)
    return any(isinstance(value, str) and GUARD_PATTERN.search(value) for value in values)


def read_settings(path):
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return {}, False
    except (ValueError, UnicodeError):
        raise SetupError("settings.json を UTF-8 の JSON として読めません。何も変更していません。")
    if not isinstance(data, dict):
        raise SetupError("settings.json の最上位がオブジェクトではありません。何も変更していません。")
    hooks = data.get("hooks", {})
    if not isinstance(hooks, dict):
        raise SetupError("settings.json の hooks がオブジェクトではありません。何も変更していません。")
    entries = hooks.get("PreToolUse", [])
    if not isinstance(entries, list):
        raise SetupError("settings.json の hooks.PreToolUse が配列ではありません。何も変更していません。")
    for entry in entries:
        if not isinstance(entry, dict) or not isinstance(entry.get("hooks"), list):
            raise SetupError("PreToolUse の項目の形が不正です。何も変更していません。")
        if not all(isinstance(hook, dict) for hook in entry["hooks"]):
            raise SetupError("PreToolUse の hooks の項目の形が不正です。何も変更していません。")
    return data, True


def updated_settings(settings, canonical=None):
    result = copy.deepcopy(settings)
    hooks = result.get("hooks", {})
    entries = hooks.get("PreToolUse", [])
    updated = []
    inserted = False
    found = False
    for entry in entries:
        remaining = [hook for hook in entry["hooks"] if not is_guard(hook)]
        if len(remaining) == len(entry["hooks"]):
            updated.append(entry)
            continue
        found = True
        if canonical is not None and not inserted:
            updated.append(canonical)
            inserted = True
        if remaining:
            entry["hooks"] = remaining
            updated.append(entry)
    if canonical is None and not found:
        return result
    if canonical is not None and not inserted:
        updated.append(canonical)
    if updated:
        hooks["PreToolUse"] = updated
        result["hooks"] = hooks
    else:
        hooks.pop("PreToolUse", None)
        if hooks:
            result["hooks"] = hooks
        else:
            result.pop("hooks", None)
    return result


def atomic_write(path, content):
    # Replace from the destination directory so os.replace stays on one filesystem.
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=str(path.parent), prefix="." + path.name + ".", delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(content)
        os.replace(str(temporary), str(path))
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()


def write_settings(path, data):
    atomic_write(path, (json.dumps(data, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))


def check(settings, settings_exists, target, source, canonical):
    reasons = []
    if not target.is_file():
        reasons.append("写したフック本体がありません。")
    elif target.read_bytes() != source:
        reasons.append("写したフック本体の中身がリポジトリと違います。")
    entries = settings.get("hooks", {}).get("PreToolUse", [])
    matches = [entry for entry in entries for hook in entry["hooks"] if is_guard(hook)]
    if not settings_exists:
        reasons.append("settings.json がありません。")
    if len(matches) != 1:
        reasons.append("設定の no-color-guard.py の項目が 1 つではありません（{} 個）。".format(len(matches)))
    elif matches[0] != canonical:
        reasons.append("設定の no-color-guard.py の項目が今の形と違います。")
    if reasons:
        for reason in reasons:
            print("確認失敗: " + reason, file=sys.stderr)
        return 1
    print("確認しました: フック本体と設定は今の形です。")
    return 0


def run(args):
    directory = config_directory()
    settings_path = directory / "settings.json"
    target = directory / "hooks" / GUARD_NAME
    # Validate existing settings before creating directories or changing either file.
    settings, settings_exists = read_settings(settings_path)
    if args.uninstall:
        updated = updated_settings(settings)
        changed = updated != settings
        target_exists = target.exists()
        if changed:
            write_settings(settings_path, updated)
        if target_exists:
            target.unlink()
        if not changed and not target_exists:
            print("消すものがありません。")
        else:
            print("フックを外しました。")
            print(RELOAD_MESSAGE)
        return 0
    source = Path(__file__).with_name(GUARD_NAME).read_bytes()
    canonical = expected_entry(target)
    if args.check:
        return check(settings, settings_exists, target, source, canonical)
    updated = updated_settings(settings, canonical)
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.is_file() or target.read_bytes() != source:
        atomic_write(target, source)
    if not settings_exists or updated != settings:
        write_settings(settings_path, updated)
    print("フックを導入しました。")
    print(RELOAD_MESSAGE)
    return 0


def main():
    parser = argparse.ArgumentParser(description="Claude Code の NO_COLOR フックを導入・確認・撤去します。")
    actions = parser.add_mutually_exclusive_group()
    actions.add_argument("--check", action="store_true", help="何も変更せず、フック本体と設定を確認します。")
    actions.add_argument("--uninstall", action="store_true", help="設定の項目と写したフック本体を外します。")
    args = parser.parse_args()
    try:
        return run(args)
    except (OSError, SetupError) as error:
        print("中断: {}".format(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
