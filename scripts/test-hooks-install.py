#!/usr/bin/env python3
"""Run `Dreams --install-hooks` against a throwaway HOME and check the merge is safe."""
import json
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BINARY = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "dist/Dreams.app/Contents/MacOS/Dreams"
USER_HOOK = {"hooks": [{"type": "command", "command": "echo привет \"quoted\" \\ tab\t", "timeout": 5}]}


def run(home, *flags):
    env = dict(os.environ, HOME=str(home))
    return subprocess.run([str(app_binary), *flags], env=env, capture_output=True, text=True, timeout=20)


def check(condition, message):
    if not condition:
        raise SystemExit("FAIL: " + message)


def dreams_commands(config):
    return [h["command"] for groups in config.get("hooks", {}).values() for g in groups for h in g["hooks"]
            if "Dreams.app/Contents/MacOS/Dreams" in h["command"]]


with tempfile.TemporaryDirectory() as tmp:
    home = Path(tmp)
    # Hooks are recognised by the installed app path, so run a copy from an app-shaped directory.
    app_binary = home / "Apps with 'quote'/Dreams.app/Contents/MacOS/Dreams"
    app_binary.parent.mkdir(parents=True)
    shutil.copy2(BINARY, app_binary)
    (home / ".claude").mkdir()
    (home / ".codex").mkdir()
    claude = home / ".claude/settings.json"
    codex = home / ".codex/hooks.json"
    original = ('{\n  "zeta": 1,\n  "model": "opus",\n  "alpha": {"nested": [1, 2.5e3, true, null]},\n'
                '  "hooks": {"Stop": [' + json.dumps(USER_HOOK, ensure_ascii=False) + ']}\n}\n')
    claude.write_text(original)

    dry = run(home, "--install-hooks", "--dry-run")
    check(dry.returncode == 0 and claude.read_text() == original and not codex.exists(), "dry run must not write")

    done = run(home, "--install-hooks")
    check(done.returncode == 0, "install failed: " + done.stderr)
    for path, source in [(claude, "claude"), (codex, "codex")]:
        config = json.loads(path.read_text())
        commands = dreams_commands(config)
        check(len(commands) == 6 and all(c.endswith(" --hook " + source) for c in commands), source + ": six hooks")
        check(all(shlex.split(c)[0] == str(app_binary) for c in commands), source + ": quoted path round-trips")
        check(set(config["hooks"]) >= {"SessionStart", "UserPromptSubmit", "PreToolUse", "PostToolUse", "Stop", "SessionEnd"}, source + ": events")
    config = json.loads(claude.read_text())
    check(list(config)[:3] == ["zeta", "model", "alpha"], "user key order must be preserved")
    check(config["alpha"] == {"nested": [1, 2500.0, True, None]}, "user values must survive")
    check(USER_HOOK in config["hooks"]["Stop"], "user's own hook must survive")
    check(len(list(claude.parent.glob("settings.json.dreams-backup-*"))) == 1, "one backup of the existing config")
    check(not list(codex.parent.glob("hooks.json.dreams-backup-*")), "no backup for a new config")

    again = run(home, "--install-hooks")
    check("unchanged" in again.stdout and len(dreams_commands(json.loads(claude.read_text()))) == 6, "install is idempotent")

    gone = run(home, "--uninstall-hooks")
    check(gone.returncode == 0, "uninstall failed: " + gone.stderr)
    check(json.loads(claude.read_text()) == json.loads(original), "uninstall restores the user's config")
    check(json.loads(codex.read_text()) == {}, "uninstall leaves an empty Codex config")

    claude.write_text("[1, 2]")
    bad = run(home, "--install-hooks")
    check(bad.returncode != 0 and claude.read_text() == "[1, 2]", "a non-object config is left untouched")
    claude.write_text("{not json")
    bad = run(home, "--install-hooks")
    check(bad.returncode != 0 and claude.read_text() == "{not json", "broken JSON is left untouched")
print("PASS: install, key order, user hooks, idempotence, uninstall, dry run, refuses broken configs")
