#!/usr/bin/env python3
"""Check the UI string tables and the localized hook words, in an isolated mailbox."""
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BINARY = ROOT / "dist/Dreams.app/Contents/MacOS/Dreams"
TABLES = ROOT / "Sources/Dreams/Localization"
SPECIFIER = re.compile(r"%(?:\d+\$)?[@dfsl]+|%%")


def check(condition, message):
    if not condition:
        sys.exit("FAIL: " + message)


def table(language):
    text = (TABLES / f"{language}.lproj/Localizable.strings").read_text(encoding="utf8")
    entries = dict(re.findall(r'^"([^"]+)"\s*=\s*"((?:[^"\\]|\\.)*)";', text, re.M))
    check(text.count(" = ") == len(entries), f"{language}: every line must parse as a key = value pair")
    return entries


english, russian = table("en"), table("ru")
check(english.keys() == russian.keys(),
      f"key sets differ: {sorted(english.keys() ^ russian.keys())}")
for key in english:
    check(SPECIFIER.findall(english[key]) == SPECIFIER.findall(russian[key]),
          f"{key}: format specifiers differ between en and ru")
    check(english[key].strip() and russian[key].strip(), f"{key}: empty text")
check(not re.search("[Ѐ-ӿ]", "".join(english.values())), "en: Cyrillic text in the English table")

# Every L("key") and HookWord used in Swift must exist (keys built at run time, like "hooks." + agent, are listed below).
used = set()
for source in (ROOT / "Sources/Dreams").glob("*.swift"):
    used |= set(re.findall(r'\bL\("([^"]+)"\s*[,)]', source.read_text(encoding="utf8")))
check(used <= english.keys(), f"keys used in Swift but missing: {sorted(used - english.keys())}")
for dynamic in ("hooks.codex", "hooks.claude", *[f"status.stopped.{r}" for r in ("user", "escape", "hotkey", "reopen", "timer", "agent")]):
    check(dynamic in english, f"{dynamic} is missing")
words = re.search(r"case (start.*)", (ROOT / "Sources/Dreams/Localization.swift").read_text(encoding="utf8"))
for word in [w.strip() for w in words.group(1).split(",")]:
    check("hook." + word in english, f"hook.{word} is missing")

# The hook process shows the words of the forced language.
expected = {"en": {"Edit": "code", "Stop": "done"}, "ru": {"Edit": "код", "Stop": "готово"}}
for language, cases in expected.items():
    for event, tool in [("PreToolUse", "Edit"), ("Stop", None)]:
        with tempfile.TemporaryDirectory(prefix="dreams-l10n-") as feed:
            env = dict(os.environ, DREAMS_FEED_DIRECTORY=feed, DREAMS_LANGUAGE=language)
            payload = {"session_id": "l10n", "hook_event_name": event}
            if tool:
                payload["tool_name"] = tool
            done = subprocess.run([str(BINARY), "--hook", "claude"], input=json.dumps(payload),
                                  text=True, capture_output=True, env=env, timeout=5)
            check(done.returncode == 0 and not done.stdout, f"{language} {event}: hook must stay silent")
            messages = [json.loads(p.read_text(encoding="utf8")) for p in Path(feed).glob("*.json")]
            check(len(messages) == 1, f"{language} {event}: expected one message")
            check(messages[0]["words"] == [cases[tool or "Stop"]],
                  f"{language} {event}: words {messages[0]['words']}")
print(f"PASS: {len(english)} keys in en and ru, specifiers match, Swift keys exist, hook words follow DREAMS_LANGUAGE")
