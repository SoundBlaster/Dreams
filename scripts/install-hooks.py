#!/usr/bin/env python3
"""Merge Dreams hooks into user configs, preserving other settings and hooks."""
import argparse
import datetime
import json
import os
from pathlib import Path
import shlex
import shutil
import tempfile

ROOT = Path(__file__).resolve().parents[1]
BINARY = ROOT / "dist/Dreams.app/Contents/MacOS/Dreams"
EVENTS = ["SessionStart", "UserPromptSubmit", "PreToolUse", "PostToolUse", "Stop", "SessionEnd"]


def own_hook(hook):
    command = hook.get("command", "")
    return "Dreams.app/Contents/MacOS/Dreams" in command and " --hook " in command


def merged(config, source, uninstall=False):
    result = json.loads(json.dumps(config))
    hooks = result.setdefault("hooks", {})
    for event, groups in list(hooks.items()):
        kept = []
        for group in groups:
            group["hooks"] = [h for h in group.get("hooks", []) if not own_hook(h)]
            if group["hooks"]:
                kept.append(group)
        if kept:
            hooks[event] = kept
        else:
            del hooks[event]
    if not uninstall:
        for event in EVENTS:
            handler = {"type": "command", "command": shlex.quote(str(BINARY)) + " --hook " + source, "timeout": 3}
            # Preserve ordering for Stop/SessionEnd; visualization work itself is bounded.
            if event in ("PreToolUse", "PostToolUse"):
                handler["async"] = True
            hooks.setdefault(event, []).append({"hooks": [handler]})
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--uninstall", action="store_true")
    parser.add_argument("--examples-only", action="store_true")
    args = parser.parse_args()
    if not args.uninstall and not BINARY.is_file():
        raise SystemExit("Build Dreams first: zsh scripts/build-app.sh release")
    for source, target in [("codex", Path.home()/".codex/hooks.json"), ("claude", Path.home()/".claude/settings.json")]:
        if args.examples_only:
            target = ROOT / "integrations" / (source + "-hooks.json")
        existing = json.loads(target.read_text()) if target.exists() else {}
        updated = merged(existing, source, args.uninstall)
        if updated == existing:
            print(str(target) + ": unchanged")
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists() and not args.examples_only:
            stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
            backup = target.with_name(target.name + ".dreams-backup-" + stamp)
            shutil.copy2(target, backup)
            backup.chmod(0o600)
            print("Backup: " + str(backup))
        fd, temp = tempfile.mkstemp(dir=target.parent, prefix=".dreams-hooks-")
        try:
            with os.fdopen(fd, "w") as out:
                json.dump(updated, out, ensure_ascii=False, indent=2)
                out.write("\n")
            os.replace(temp, target)
        finally:
            if os.path.exists(temp):
                os.unlink(temp)
        print("Updated: " + str(target))


if __name__ == "__main__":
    main()
