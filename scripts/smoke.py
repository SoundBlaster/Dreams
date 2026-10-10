#!/usr/bin/env python3
"""Bounded MCP integration smoke; --interactive keeps the UI lab alive for CUA."""
import argparse
import base64
import json
import os
from pathlib import Path
import queue
import subprocess
import sys
import tempfile
import threading
import time

ROOT = Path(__file__).resolve().parents[1]


class MCPClient:
    def __init__(self, env=None, publisher=False, extra_args=()):
        self.publisher = publisher
        self.stderr = tempfile.TemporaryFile(mode="w+")
        self.process = subprocess.Popen(
            [str(ROOT / "dist/Dreams.app/Contents/MacOS/Dreams"), "--mcp"]
            + (["--publisher"] if publisher else []) + list(extra_args),
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=self.stderr,
            text=True, bufsize=1, env=env)
        self.responses = queue.Queue()
        self.sequence = 0
        self.reader = threading.Thread(target=self.read, daemon=True)
        self.reader.start()

    def read(self):
        for line in self.process.stdout:
            try:
                self.responses.put(json.loads(line))
            except json.JSONDecodeError:
                self.responses.put({"invalid_stdout": line})
        self.responses.put({"eof": True})

    def send(self, value):
        self.process.stdin.write(json.dumps(value) + "\n")
        self.process.stdin.flush()

    def request(self, method, params=None):
        self.sequence += 1
        request_id = self.sequence
        self.send({"jsonrpc": "2.0", "id": request_id, "method": method, "params": params or {}})
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            response = self.responses.get(timeout=max(0.1, deadline - time.monotonic()))
            if "invalid_stdout" in response or "eof" in response:
                raise RuntimeError(response)
            if response.get("id") == request_id:
                if "error" in response:
                    raise RuntimeError(response["error"])
                return response["result"]
        raise TimeoutError(method)

    def call(self, name, arguments=None, expect_error=False):
        result = self.request("tools/call", {"name": name, "arguments": arguments or {}})
        assert bool(result.get("isError")) == expect_error, result
        text = result["content"][0]["text"]
        return text if expect_error else json.loads(text)

    def close(self):
        if self.process.poll() is None:
            try:
                if not self.publisher:
                    self.call("dreams_stop")
                    self.call("dreams_workspace_close")
            finally:
                self.process.stdin.close()
            try:
                self.process.wait(timeout=8)
            except subprocess.TimeoutExpired:
                self.process.terminate()
                self.process.wait(timeout=5)
        self.stderr.seek(0)
        errors = self.stderr.read()
        if errors:
            print(errors, file=sys.stderr)
        self.stderr.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--interactive", action="store_true")
    args = parser.parse_args()
    feed_dir = tempfile.TemporaryDirectory(prefix="dreams-smoke-")
    env = dict(os.environ, DREAMS_FEED_DIRECTORY=feed_dir.name, DREAMS_LANGUAGE="en")
    client = MCPClient(env=env)
    try:
        initialized = client.request("initialize", {
            "protocolVersion": "2025-06-18", "capabilities": {
                "elicitation": {"form": {}, "url": {}},
                "experimental": {"codex/auth-change": {}, "custom": "enabled"}},
            "clientInfo": {"name": "dreams-smoke", "version": "1.0"}})
        client.send({"jsonrpc": "2.0", "method": "notifications/initialized"})
        tools = client.request("tools/list")["tools"]
        assert len(tools) == 10
        print("MCP handshake:", initialized["protocolVersion"], flush=True)
        client.call("dreams_start", {"duration_seconds": -1}, expect_error=True)
        client.call("dreams_start", {"brightness": "bright"}, expect_error=True)
        client.call("dreams_publish_keywords", {"session_id": "invalid", "keywords": []}, expect_error=True)
        client.call("dreams_publish_keywords", {"session_id": "invalid", "keywords": ["a" * 33]}, expect_error=True)
        client.call("dreams_publish_keywords", {"session_id": "invalid", "keywords": ["test"], "activity": "unknown"}, expect_error=True)
        publisher = MCPClient(env=env, publisher=True)
        try:
            publisher.request("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                "clientInfo": {"name": "publisher-smoke", "version": "1"}})
            publisher.send({"jsonrpc": "2.0", "method": "notifications/initialized"})
            assert len(publisher.request("tools/list")["tools"]) == 4
            publisher.call("dreams_start", expect_error=True)
            publisher.call("dreams_publish_keywords", {"session_id": "codex-demo", "keywords": ["Metal", "Metal", "волны"], "color": "cyan"})
            assert client.call("dreams_status")["keyword_sessions"][0]["keywords"] == ["Metal", "волны"]
            hook = subprocess.run([str(ROOT / "dist/Dreams.app/Contents/MacOS/Dreams"), "--hook", "claude"],
                input=json.dumps({"session_id": "hook-demo", "hook_event_name": "PreToolUse", "tool_name": "Edit", "tool_input": {"content": "MUST_NOT_APPEAR"}}),
                text=True, capture_output=True, env=env, timeout=3)
            assert hook.returncode == 0 and not hook.stdout and not hook.stderr, hook
            state = client.call("dreams_status")
            assert len(state["keyword_sessions"]) == 2, state
            assert "MUST_NOT_APPEAR" not in json.dumps(state), state
            assert any(s["keywords"] == ["code"] for s in state["keyword_sessions"]), state
            assert state["working_agents"] == 2, state
            # Lifecycle events change activity, independent of their displayed words.
            for event, expected in [("Stop", 1), ("SessionStart", 1), ("PreToolUse", 2)]:
                hook = subprocess.run([str(ROOT / "dist/Dreams.app/Contents/MacOS/Dreams"), "--hook", "claude"],
                    input=json.dumps({"session_id": "hook-demo", "hook_event_name": event, "tool_name": "Edit"}),
                    text=True, capture_output=True, env=env, timeout=3)
                assert hook.returncode == 0 and not hook.stdout and not hook.stderr
                assert client.call("dreams_status")["working_agents"] == expected
            publisher.call("dreams_publish_keywords", {"session_id": "codex-demo", "keywords": ["готово"], "activity": "idle"})
            assert client.call("dreams_status")["working_agents"] == 1
            publisher.call("dreams_publish_keywords", {"session_id": "codex-demo", "keywords": ["Metal", "волны"]})
            publisher.call("dreams_publish_keywords", {"session_id": "expiry", "keywords": ["temporary"]})
            # Advance only the disposable fixture's expiration; verify the real reader prunes it.
            for path in Path(feed_dir.name).glob("*.json"):
                message = json.loads(path.read_text())
                if message["sessionID"] == "expiry":
                    message["expiresAt"] = 0
                    path.write_text(json.dumps(message))
            assert len(client.call("dreams_status")["keyword_sessions"]) == 2
        finally:
            publisher.close()
        preview = client.request("tools/call", {"name": "dreams_preview", "arguments": {}})
        assert not preview.get("isError"), preview
        image = preview["content"][0]
        assert image["type"] == "image" and image["mimeType"] == "image/png", image
        preview_path = ROOT / "artifacts/matrix-preview.png"
        preview_path.parent.mkdir(exist_ok=True)
        preview_path.write_bytes(base64.b64decode(image["data"]))
        workspace = client.call("dreams_workspace_create")
        assert workspace["virtual_display_id"] is not None, workspace
        assert workspace["workspace_window_display_id"] == workspace["virtual_display_id"], workspace
        state = client.call("dreams_start", {"duration_seconds": 120, "brightness": 0.12})
        assert state["rain_visible"]
        assert "visual_style" not in state
        frames = []
        for index in range(2):
            time.sleep(2)
            frame = client.request("tools/call", {"name": "dreams_preview", "arguments": {}})
            data = base64.b64decode(frame["content"][0]["data"])
            (ROOT / f"artifacts/matrix-live-{index}.png").write_bytes(data)
            frames.append(data)
        assert frames[0] != frames[1], "Animation frames did not change"
        print("LAB_READY", "pid=" + str(client.process.pid), json.dumps(state), flush=True)
        if args.interactive:
            print('Enter {"name":"dreams_status"} or "finish".', flush=True)
            for line in sys.stdin:
                if line.strip() == "finish":
                    break
                command = json.loads(line)
                print(json.dumps(client.call(command["name"], command.get("arguments"))), flush=True)
        assert not client.call("dreams_prepare_ui")["rain_visible"]
        assert client.call("dreams_resume")["rain_visible"]
        state = client.call("dreams_start", {"duration_seconds": 1})
        assert state["rain_visible"]
        time.sleep(1.5)
        state = client.call("dreams_status")
        assert not state["rain_visible"], state
        assert not state["prevents_idle_sleep"], state
        assert client.call("dreams_workspace_close")["virtual_display_id"] is None
        client.call("dreams_clear_keywords", {"session_id": "codex-demo"})
        assert len(client.call("dreams_status")["keyword_sessions"]) == 1
        print("PASS: MCP lifecycle, cross-process keywords, hook mapping, expiry, PNG, workspace, auto-stop.", flush=True)
    finally:
        client.close()
        feed_dir.cleanup()


if __name__ == "__main__":
    main()
