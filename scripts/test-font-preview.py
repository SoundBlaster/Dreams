#!/usr/bin/env python3
"""Check the font selected in Dreams through a fresh MCP process and Metal preview.

Toggle the checkbox in Dreams, then run with `classic` or `restored`.
Add --override to select the font in this test process only, preserving preferences.
Uses a temporary keyword feed and never covers the desktop.
"""
import base64
import json
import os
import sys
import tempfile

from smoke import MCPClient, ROOT

expected = sys.argv[1]
assert expected in {"classic", "restored"}
override = "--override" in sys.argv[2:]
arguments = ["-restoredGlyphs", "YES" if expected == "restored" else "NO"] if override else []
with tempfile.TemporaryDirectory(prefix="dreams-font-preview-") as feed:
    client = MCPClient(env=dict(os.environ, DREAMS_FEED_DIRECTORY=feed), publisher=True,
                       extra_args=arguments)
    try:
        client.request("initialize", {
            "protocolVersion": "2025-06-18", "capabilities": {},
            "clientInfo": {"name": "font-preview-check", "version": "1"}})
        client.send({"jsonrpc": "2.0", "method": "notifications/initialized"})
        status = client.call("dreams_status")
        assert status["matrix_font"] == expected, status
        client.call("dreams_publish_keywords", {
            "session_id": "font-preview-check", "keywords": ["Глифы"], "activity": "working"})
        result = client.request("tools/call", {"name": "dreams_preview", "arguments": {}})
        assert not result.get("isError"), result
        png = base64.b64decode(result["content"][0]["data"])
        assert png.startswith(b"\x89PNG\r\n\x1a\n") and len(png) > 10000
        out = ROOT / "artifacts" / f"font-{expected}-preview.png"
        out.parent.mkdir(exist_ok=True)
        out.write_bytes(png)
        out.with_suffix(".json").write_text(json.dumps(status, indent=2, ensure_ascii=False))
        source = "process-only override" if override else "persisted selection"
        print(f"PASS: {expected} {source}; font loaded and Metal preview rendered: {out}")
    finally:
        client.close()
