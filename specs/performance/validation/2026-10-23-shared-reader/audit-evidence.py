#!/usr/bin/env python3
"""Verify retained source/maps and lossless raw reports; no performance acceptance."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import subprocess


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--external-root", type=Path)
    args = parser.parse_args()
    packet = Path(__file__).resolve().parent
    root = packet.parents[3]
    revision = "680833b15edb0435c31bf3f4f1bc3c17ca934dd5"
    result = {"sourceRevision": revision, "sources": [], "maps": [], "reports": []}
    for name in ["performance", "keyword-feed", "drop-motion", "settings-host"]:
        package = root / "specs" / name
        identity_path = package / "evidence/2026-10-23-shared-reader/source-identity.json"
        identity = json.loads(identity_path.read_text())
        assert identity["sourceRevision"] == revision, identity_path
        for row in identity["files"]:
            data = (package / row["snapshot"]).read_bytes()
            committed = subprocess.check_output(["git", "show", f"{revision}:{row['path']}"], cwd=root)
            assert sha(data) == row["sha256"] and data == committed, row
            assert data == (root / row["path"]).read_bytes(), row
            result["sources"].append({"package": name, "path": row["path"], "sha256": sha(data)})
        for row in identity.get("maps", []):
            data = (package / row["snapshot"]).read_bytes()
            assert sha(data) == row["sha256"] and data == (root / row["path"]).read_bytes(), row
            result["maps"].append({"package": name, "path": row["path"], "sha256": sha(data)})
        # Check reused, older snapshots too; current bindings deliberately keep identical bytes.
        for spec in sorted((package / "specs").glob("*.spec.yaml")):
            bindings = spec.read_text().split("implementationBindings:", 1)[1]
            for line in bindings.splitlines():
                value = line.strip().removeprefix("- ")
                if value.startswith("evidence/") and "/source/" in value:
                    original = value.split("/source/", 1)[1]
                    if original.endswith(".md.txt"):
                        original = original.removesuffix(".txt")
                    snapshot = (package / value).read_bytes()
                    committed = subprocess.check_output(["git", "show", f"{revision}:{original}"], cwd=root)
                    assert snapshot == committed == (root / original).read_bytes(), (spec, value)
    external_groups = {"pairs": "shared-reader-pairs-2026-10-23",
                       "quiet-pairs": "shared-reader-quiet-pairs-2026-10-23",
                       "smoke": "reader-measured-smoke-2026-10-23"}
    for path, identity in json.loads((packet / "raw-identities.json").read_text()).items():
        archive = root / path
        data = gzip.decompress(archive.read_bytes())
        assert sha(data) == identity["uncompressedSHA256"], path
        assert sha(archive.read_bytes()) == identity["archivedSHA256"], path
        if args.external_root:
            relative = archive.relative_to(packet)
            original = args.external_root / external_groups[relative.parts[0]] / Path(*relative.parts[1:])
            assert data == original.with_suffix("").read_bytes(), path
        json.loads(data)
        result["reports"].append({"path": path, **identity})
    result["externalOriginalsChecked"] = args.external_root is not None
    result["status"] = "pass"
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
