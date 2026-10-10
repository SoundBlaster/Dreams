#!/usr/bin/env python3
"""Install into a throwaway HOME and /Applications, then check scripts/uninstall.sh removes exactly Dreams."""
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "dist/Dreams.app"
DOMAIN = "ru.egormerkushev.dreams-uninstall-test"


def check(condition, message):
    if not condition:
        sys.exit("FAIL: " + message)


def run(env, *args):
    return subprocess.run([str(ROOT / "scripts/uninstall.sh"), *args], env=env, text=True, capture_output=True, timeout=60)


with tempfile.TemporaryDirectory() as tmp:
    home, apps = Path(tmp) / "home", Path(tmp) / "Applications"
    home.mkdir()
    apps.mkdir()
    shutil.copytree(APP, apps / "Dreams.app", symlinks=True)
    env = dict(os.environ, HOME=str(home), DREAMS_APPLICATIONS=str(apps), DREAMS_PREFS_DOMAINS=DOMAIN)
    binary = apps / "Dreams.app/Contents/MacOS/Dreams"
    (home / ".claude").mkdir()
    (home / ".codex").mkdir()
    user_hook = {"hooks": [{"type": "command", "command": "echo mine"}]}
    (home / ".claude/settings.json").write_text(json.dumps({"model": "opus", "hooks": {"Stop": [user_hook]}}))
    check(subprocess.run([str(binary), "--install-hooks"], env=env, capture_output=True).returncode == 0, "install hooks")
    support = home / "Library/Application Support/Dreams/Keywords"
    support.mkdir(parents=True)
    (support / "x.json").write_text("{}")
    subprocess.run(["defaults", "write", DOMAIN, "rainSpeed", "-float", "2"], check=True, env=env)
    backups = list((home / ".claude").glob("settings.json.dreams-backup-*"))
    check(backups, "installer should have left a backup")

    try:
        dry = run(env, "--purge", "--dry-run")
        check(dry.returncode == 0 and (apps / "Dreams.app").exists() and support.exists(), "dry run must change nothing")
        check("would" in dry.stdout, "dry run should say what it would do")

        plain = run(env)
        check(plain.returncode == 0, plain.stderr)
        check(not (apps / "Dreams.app").exists(), "the app must be removed")
        config = json.loads((home / ".claude/settings.json").read_text())
        check(config == {"model": "opus", "hooks": {"Stop": [user_hook]}}, "hooks removed, the user's config intact")
        check(json.loads((home / ".codex/hooks.json").read_text()) == {}, "Codex hooks removed")
        check(support.exists(), "without --purge the mailbox stays")
        check(subprocess.run(["defaults", "read", DOMAIN, "rainSpeed"], capture_output=True, env=env).returncode == 0, "without --purge settings stay")

        # A second run, now without the app, must not fail and must say what it cannot do.
        shutil.copytree(APP, apps / "Dreams.app", symlinks=True)
        purge = run(env, "--purge")
        check(purge.returncode == 0, purge.stderr)
        check(not (home / "Library/Application Support/Dreams").exists(), "--purge removes the mailbox")
        check(subprocess.run(["defaults", "read", DOMAIN, "rainSpeed"], capture_output=True, env=env).returncode != 0, "--purge removes settings")
        check(not list((home / ".claude").glob("settings.json.dreams-backup-*")), "--purge removes hook backups")
        check((home / ".claude/settings.json").exists(), "the user's own config must survive --purge")
        again = run(env, "--purge")
        check(again.returncode == 0, "running again must be harmless")
    finally:
        subprocess.run(["defaults", "delete", DOMAIN], capture_output=True, env=env)
print("PASS: dry run, hooks and app removed, user config intact, --purge removes settings/mailbox/backups, idempotent")
