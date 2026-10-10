#!/usr/bin/env python3
"""Verify the real Metal preview alpha with/without --transparent; no screen capture."""
import base64
import io
import os
import tempfile
import numpy as np
from PIL import Image
from smoke import MCPClient, ROOT

for transparent in (False, True):
    with tempfile.TemporaryDirectory(prefix='dreams-alpha-') as feed:
        client = MCPClient(env=dict(os.environ, DREAMS_FEED_DIRECTORY=feed), publisher=True,
            extra_args=['--transparent'] if transparent else ['-transparentBackground', 'NO'])  # the saved setting must not leak in
        try:
            client.request('initialize', {'protocolVersion': '2025-06-18', 'capabilities': {},
                'clientInfo': {'name': 'alpha-check', 'version': '1'}})
            client.send({'jsonrpc': '2.0', 'method': 'notifications/initialized'})
            assert client.call('dreams_status')['transparent_background'] == transparent
            client.call('dreams_publish_keywords', {'session_id': 'alpha-check',
                'keywords': ['Свет'], 'activity': 'working'})
            result = client.request('tools/call', {'name': 'dreams_preview', 'arguments': {}})
            png = base64.b64decode(result['content'][0]['data'])
            pixels = np.asarray(Image.open(io.BytesIO(png)).convert('RGBA'))
            alpha = pixels[:, :, 3]
            if transparent:
                assert alpha.min() == 0 and (alpha > 0).sum() > 1000
                assert ((alpha > 0) & (alpha < 255)).sum() > 1000, 'Glyph edges must preserve partial alpha'
            else:
                assert alpha.min() == 255
            (ROOT / 'artifacts' / ('matrix-transparent.png' if transparent else 'matrix-opaque.png')).write_bytes(png)
            print('PASS', 'transparent' if transparent else 'opaque', 'Metal alpha:', int(alpha.min()), int(alpha.max()))
        finally:
            client.close()
