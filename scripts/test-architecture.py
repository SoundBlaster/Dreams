#!/usr/bin/env python3
"""Prove the configured architecture gate rejects upward and sideways dependencies."""
import json
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def lint(files):
    with tempfile.TemporaryDirectory(prefix="dreams-fsd-") as directory:
        for name, source in files.items():
            path = Path(directory, name)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(source)
        result = subprocess.run(
            ["zsh", str(ROOT / "scripts/lint-architecture.sh"), "--root", directory, "--format", "json"],
            cwd=ROOT, capture_output=True, text=True, timeout=60,
        )
        return result.returncode, json.loads(result.stdout)


valid = {
    "pages/settings/ui/Settings.swift": "struct Settings { let model: RainModel }",
    "features/rain/model/RainModel.swift": "struct RainModel {}",
}
code, report = lint(valid)
assert code == 0, report
code, report = lint(valid | {
    "entities/activity/model/Activity.swift": "struct Activity { let page: Settings }",
})
assert code != 0 and "dependency-direction" in json.dumps(report), report
code, report = lint(valid | {
    "features/other/model/Other.swift": "struct Other { let rain: RainModel }",
})
assert code != 0 and "same-layer" in json.dumps(report), report
print("PASS: configured FSD gate accepts downward dependencies and rejects upward and same-layer slice imports")
