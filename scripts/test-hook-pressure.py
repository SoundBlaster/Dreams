#!/usr/bin/env python3
"""Exercise real hook accumulation, decay, and Stop in an isolated mailbox."""
import json
import os
import subprocess
import tempfile
from pathlib import Path
from smoke import MCPClient, ROOT

with tempfile.TemporaryDirectory(prefix="dreams-pressure-") as directory:
    env = dict(os.environ, DREAMS_FEED_DIRECTORY=directory)
    client = MCPClient(env=env, publisher=True)
    def hook(event):
        subprocess.run([str(ROOT / 'dist/Dreams.app/Contents/MacOS/Dreams'), '--hook', 'codex'],
            env=env, input=json.dumps({'session_id': 'pressure-check', 'hook_event_name': event,
                'tool_name': 'Read'}), text=True, check=True, capture_output=True)
    try:
        client.request('initialize', {'protocolVersion': '2025-06-18', 'capabilities': {},
            'clientInfo': {'name': 'pressure-check', 'version': '1'}})
        client.send({'jsonrpc': '2.0', 'method': 'notifications/initialized'})
        hook('UserPromptSubmit')
        initial = client.call('dreams_status')
        for _ in range(8):
            hook('PreToolUse')
            hook('PostToolUse')
        busy = client.call('dreams_status')
        payload = next(json.loads(p.read_text()) for p in Path(directory).glob('*.json')
            if json.loads(p.read_text())['sessionID'] == 'codex:pressure-check')
        assert [event['label'] for event in payload['events']] == ['TASK'] + ['read'] * 8, 'PostToolUse must not duplicate a call stream'

        assert busy['activity_level'] > initial['activity_level'] + .2, (initial, busy)
        assert busy['action_pressure'] > .95, busy
        client.call('dreams_publish_keywords', {'session_id': 'pressure-check-keywords',
            'keywords': ['Проверка'], 'activity': 'idle'})
        # Advance only the isolated fixture's event timestamp, leaving expiry in the future.
        path = next(p for p in Path(directory).glob('*.json')
            if json.loads(p.read_text())['sessionID'] == 'codex:pressure-check')
        data = json.loads(path.read_text())
        data['updatedAt'] -= 40
        path.write_text(json.dumps(data))
        quiet = client.call('dreams_status')
        assert .5 <= quiet['activity_level'] < busy['activity_level'] - .2, quiet
        hook('Stop')
        stopped = client.call('dreams_status')
        assert stopped['activity_level'] == stopped['action_pressure'] == 0, stopped
        print('PASS real hooks: burst increases activity, time decays pressure, Stop clears it')
        print('Levels:', initial['activity_level'], busy['activity_level'], quiet['activity_level'], stopped['activity_level'])
    finally:
        client.close()
