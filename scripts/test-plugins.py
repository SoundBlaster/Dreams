#!/usr/bin/env python3
"""Check the Claude Code and Codex plugins in plugins/ and their marketplaces."""
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EVENTS = ["SessionStart", "UserPromptSubmit", "PreToolUse", "PostToolUse", "Stop", "SessionEnd"]
CLAUDE, CODEX = ROOT / "plugins/dreams-claude", ROOT / "plugins/dreams-codex"


def check(condition, message):
    if not condition:
        sys.exit("FAIL: " + message)


def load(path):
    return json.loads(Path(path).read_text(encoding="utf8"))


version = (ROOT / "VERSION").read_text().strip()
claude_manifest, codex_manifest = load(CLAUDE / ".claude-plugin/plugin.json"), load(CODEX / "plugin.json")
for manifest in (claude_manifest, codex_manifest):
    check(manifest["name"] == "dreams", "plugin name must be dreams")
    check(manifest["version"] == version, f"plugin version {manifest['version']} must match VERSION {version}")
claude_mp, codex_mp = load(ROOT / ".claude-plugin/marketplace.json"), load(ROOT / ".agents/plugins/marketplace.json")
check(claude_mp["plugins"][0]["name"] == claude_manifest["name"], "Claude entry name = manifest name")
check((ROOT / claude_mp["plugins"][0]["source"]).samefile(CLAUDE), "Claude marketplace source")
check((ROOT / codex_mp["plugins"][0]["source"]["path"]).samefile(CODEX), "Codex marketplace source")

for plugin, variable, agent in ((CLAUDE, "CLAUDE_PLUGIN_ROOT", "claude"), (CODEX, "PLUGIN_ROOT", "codex")):
    hooks = load(plugin / "hooks/hooks.json")["hooks"]
    check(list(hooks) == EVENTS, f"{agent}: the six events of the installer, got {list(hooks)}")
    for event, groups in hooks.items():
        handler = groups[0]["hooks"][0]
        check(handler["command"] == f'sh "${{{variable}}}/scripts/dreams-hook.sh" {agent}', f"{agent} {event}: command")
        check(handler["timeout"] == 3 and handler.get("async", False) == (event in ("PreToolUse", "PostToolUse")), f"{agent} {event}: timeout/async")
    mcp = load(plugin / (".mcp.json" if plugin == CLAUDE else "mcp.json"))["mcpServers"]["dreams"]
    check(mcp["args"] == ["--mcp", "--publisher"], f"{agent}: the plugin MCP server must be publisher-only")
check((CLAUDE / "scripts/dreams-hook.sh").read_bytes() == (CODEX / "scripts/dreams-hook.sh").read_bytes(), "hook scripts must be identical")
check(os.access(CLAUDE / "scripts/dreams-hook.sh", os.X_OK), "hook script must be executable")

# The script: runs the app's hook when installed, silent when not.
script = str(CLAUDE / "scripts/dreams-hook.sh")
quiet = subprocess.run(["sh", script, "claude"], input="{}", text=True, capture_output=True,
                       env=dict(os.environ, DREAMS_APP_DIRS="/nonexistent"))
check(quiet.returncode == 0 and not quiet.stdout and not quiet.stderr, "a missing app must be silent")
with tempfile.TemporaryDirectory() as tmp:
    app = Path(tmp) / "Dreams.app/Contents/MacOS"
    app.mkdir(parents=True)
    (app / "Dreams").write_text('#!/bin/sh\nprintf "%s %s" "$1" "$2" > "$DREAMS_TEST_OUT"\n')
    (app / "Dreams").chmod(0o755)
    out = Path(tmp) / "out"
    subprocess.run(["sh", script, "codex"], env=dict(os.environ, DREAMS_APP_DIRS=tmp, DREAMS_TEST_OUT=str(out)), check=True)
    check(out.read_text() == "--hook codex", "the script must run `Dreams --hook <agent>`")

notes = []
if shutil.which("claude"):
    for target in (CLAUDE, ROOT):
        result = subprocess.run(["claude", "plugin", "validate", str(target)], capture_output=True, text=True)
        check("Validation passed" in result.stdout and result.returncode == 0, f"claude plugin validate {target.name}: {result.stdout[-200:]}")
    with tempfile.TemporaryDirectory() as config:
        env = dict(os.environ, CLAUDE_CONFIG_DIR=config)
        for args in (["marketplace", "add", str(ROOT)], ["install", "dreams@dreams"]):
            result = subprocess.run(["claude", "plugin", *args], env=env, capture_output=True, text=True)
            check(result.returncode == 0, f"claude plugin {' '.join(args)}: {result.stdout[-200:]}{result.stderr[-200:]}")
        details = subprocess.run(["claude", "plugin", "details", "dreams"], env=env, capture_output=True, text=True).stdout
        check("Hooks (6)" in details and "MCP servers (1)" in details, "installed Claude plugin inventory: " + details[-300:])
    notes.append("claude validate+install")
if shutil.which("codex"):
    with tempfile.TemporaryDirectory() as home:
        env = dict(os.environ, CODEX_HOME=home)
        for args in (["marketplace", "add", str(ROOT)], ["add", "dreams@dreams"]):
            result = subprocess.run(["codex", "plugin", *args], env=env, capture_output=True, text=True)
            check(result.returncode == 0, f"codex plugin {' '.join(args)}: {result.stdout[-200:]}{result.stderr[-200:]}")
        cached = list(Path(home).glob("plugins/cache/dreams/dreams/*/hooks/hooks.json"))
        check(cached, "the installed Codex plugin must carry hooks/hooks.json")
        check('enabled = true' in (Path(home) / "config.toml").read_text(), "the plugin must be enabled in config.toml")
    notes.append("codex marketplace add+install")
print("PASS: manifests, versions, six events, publisher-only MCP, script behavior" + (", " + ", ".join(notes) if notes else ""))
