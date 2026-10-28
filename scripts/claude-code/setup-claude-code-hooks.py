"""Install, check, or remove the Claude Code hooks (Python 3.9+).

The hooks are the NO_COLOR guard (PreToolUse) and the Codex broker reaper
(SessionStart).
"""

import argparse
import copy
import json
import os
from pathlib import Path
import re
import sys
import tempfile


HOOKS = [
    {
        "name": "no-color-guard.py",
        "event": "PreToolUse",
        "matcher": "Bash|PowerShell",
        "options": {"timeout": 10, "statusMessage": "NO_COLOR の引き継ぎを確かめています"},
    },
    {
        "name": "codex-reaper.py",
        "event": "SessionStart",
        "matcher": None,
        # Listing the processes takes seconds on Windows; do not hold up the session start.
        "options": {"async": True},
    },
]
RELOAD_MESSAGE = (
    "Claude Code を起動し直すか、動いているセッションでは設定が読み直されるまで待ってください。"
)


class SetupError(Exception):
    pass


def config_directory():
    override = os.environ.get("CLAUDE_CONFIG_DIR")
    return (Path(override).expanduser() if override else Path.home() / ".claude").resolve()


def pattern(spec):
    return re.compile(r"(?<![\w.-]){}(?![\w.-])".format(re.escape(spec["name"])), re.IGNORECASE)


def expected_entry(spec, target):
    interpreter = "python" if os.name == "nt" else "python3"
    path = target.as_posix() if os.name == "nt" else str(target)
    # Claude Code runs the command through a shell, including Git Bash on Windows.
    quoted = path.replace("\\", "\\\\").replace('"', '\\"').replace("$", "\\$").replace(chr(96), "\\" + chr(96))
    entry = {} if spec["matcher"] is None else {"matcher": spec["matcher"]}
    entry["hooks"] = [dict({"type": "command", "command": '{} "{}"'.format(interpreter, quoted)}, **spec["options"])]
    return entry


def is_hook(spec, hook):
    command = hook.get("command", "")
    args = hook.get("args", [])
    values = [command]
    if isinstance(args, str):
        values.append(args)
    elif isinstance(args, list):
        values.extend(args)
    return any(isinstance(value, str) and pattern(spec).search(value) for value in values)


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
    for event in sorted({spec["event"] for spec in HOOKS}):
        entries = hooks.get(event, [])
        if not isinstance(entries, list):
            raise SetupError("settings.json の hooks.{} が配列ではありません。何も変更していません。".format(event))
        for entry in entries:
            if not isinstance(entry, dict) or not isinstance(entry.get("hooks"), list):
                raise SetupError("{} の項目の形が不正です。何も変更していません。".format(event))
            if not all(isinstance(hook, dict) for hook in entry["hooks"]):
                raise SetupError("{} の hooks の項目の形が不正です。何も変更していません。".format(event))
    return data, True


def update_event(hooks, spec, canonical):
    entries = hooks.get(spec["event"], [])
    updated = []
    inserted = False
    found = False
    for entry in entries:
        remaining = [hook for hook in entry["hooks"] if not is_hook(spec, hook)]
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
        return
    if canonical is not None and not inserted:
        updated.append(canonical)
    if updated:
        hooks[spec["event"]] = updated
    else:
        hooks.pop(spec["event"], None)


def updated_settings(settings, canonicals=None):
    """Put each hook's canonical entry in place, or remove the hooks when canonicals is None."""
    result = copy.deepcopy(settings)
    hooks = result.get("hooks", {})
    had_hooks = "hooks" in result
    for spec in HOOKS:
        update_event(hooks, spec, None if canonicals is None else canonicals[spec["name"]])
    if hooks:
        result["hooks"] = hooks
    elif had_hooks and result != settings:
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


def check(settings, settings_exists, targets, sources, canonicals):
    reasons = []
    if not settings_exists:
        reasons.append("settings.json がありません。")
    for spec in HOOKS:
        name = spec["name"]
        target = targets[name]
        if not target.is_file():
            reasons.append("写したフック本体（{}）がありません。".format(name))
        elif target.read_bytes() != sources[name]:
            reasons.append("写したフック本体（{}）の中身がリポジトリと違います。".format(name))
        entries = settings.get("hooks", {}).get(spec["event"], [])
        matches = [entry for entry in entries for hook in entry["hooks"] if is_hook(spec, hook)]
        if len(matches) != 1:
            reasons.append("設定の {} の項目が 1 つではありません（{} 個）。".format(name, len(matches)))
        elif matches[0] != canonicals[name]:
            reasons.append("設定の {} の項目が今の形と違います。".format(name))
    if reasons:
        for reason in reasons:
            print("確認失敗: " + reason, file=sys.stderr)
        return 1
    print("確認しました: フック本体と設定は今の形です。")
    return 0


def run(args):
    directory = config_directory()
    settings_path = directory / "settings.json"
    targets = {spec["name"]: directory / "hooks" / spec["name"] for spec in HOOKS}
    # Validate existing settings before creating directories or changing any file.
    settings, settings_exists = read_settings(settings_path)
    if args.uninstall:
        updated = updated_settings(settings)
        changed = updated != settings
        existing = [target for target in targets.values() if target.exists()]
        if changed:
            write_settings(settings_path, updated)
        for target in existing:
            target.unlink()
        if not changed and not existing:
            print("消すものがありません。")
        else:
            print("フックを外しました。")
            print(RELOAD_MESSAGE)
        return 0
    sources = {name: Path(__file__).with_name(name).read_bytes() for name in targets}
    canonicals = {spec["name"]: expected_entry(spec, targets[spec["name"]]) for spec in HOOKS}
    if args.check:
        return check(settings, settings_exists, targets, sources, canonicals)
    updated = updated_settings(settings, canonicals)
    directory.joinpath("hooks").mkdir(parents=True, exist_ok=True)
    for name, target in targets.items():
        if not target.is_file() or target.read_bytes() != sources[name]:
            atomic_write(target, sources[name])
    if not settings_exists or updated != settings:
        write_settings(settings_path, updated)
    print("フックを導入しました。")
    print(RELOAD_MESSAGE)
    return 0


def main():
    parser = argparse.ArgumentParser(description="Claude Code のフック（NO_COLOR・Codex の片付け）を導入・確認・撤去します。")
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
