#!/usr/bin/env python3
"""Check catalog packaging, localization and separation from the production app."""
import json
from pathlib import Path
import plistlib
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "Packages/DreamsSettingsUI"
APP = ROOT / "dist/DreamsSettingsCatalog.app"


def manifest(path):
    return json.loads(subprocess.check_output(
        ["swift", "package", "--package-path", str(path), "dump-package"], text=True))


def strings(path):
    pairs = re.findall(r'^("(?:[^"\\]|\\.)*")\s*=\s*("(?:[^"\\]|\\.)*");$', path.read_text(), re.M)
    values = {json.loads(key): json.loads(value) for key, value in pairs}
    assert len(pairs) == len(values), f"Duplicate keys: {path}"
    return values


def main():
    catalog = manifest(PACKAGE)
    assert not catalog["dependencies"], "Catalog must not depend on production or external packages"
    targets = {target["name"]: target for target in catalog["targets"]}
    assert not targets["DreamsSettingsUI"]["dependencies"]
    assert len(targets["DreamsSettingsCatalog"]["dependencies"]) == 1
    assert "DreamsSettingsUI" in json.dumps(targets["DreamsSettingsCatalog"]["dependencies"])
    production = manifest(ROOT)
    assert "DreamsSettingsUI" not in json.dumps(production), "Stage one must remain opt-in and standalone"
    assert catalog["platforms"] == [{"options": [], "platformName": "macos", "version": "15.0"}]
    source = PACKAGE / "Sources/DreamsSettingsCatalog"
    english = strings(source / "shared/assets/Localization/en.lproj/Localizable.strings")
    russian = strings(source / "shared/assets/Localization/ru.lproj/Localizable.strings")
    assert english.keys() == russian.keys()
    used = set()
    for path in source.rglob("*.swift"):
        used.update(re.findall(r'catalogString\("([^"]+)"\)', path.read_text()))
    assert used == english.keys(), (used - english.keys(), english.keys() - used)
    with (APP / "Contents/Info.plist").open("rb") as stream:
        info = plistlib.load(stream)
    assert info["CFBundleIdentifier"] == "ru.egormerkushev.dreams.settings-catalog"
    assert info["CFBundleIdentifier"] != "ru.egormerkushev.dreams"
    assert info["LSMinimumSystemVersion"] == "15.0"
    assert (APP / "Contents/MacOS" / info["CFBundleExecutable"]).is_file()
    bundle = APP / "Contents/Resources/DreamsSettingsUI_DreamsSettingsCatalog.bundle"
    resources = bundle / "Contents/Resources" if (bundle / "Contents/Resources").is_dir() else bundle
    for language, expected in [("en", english), ("ru", russian)]:
        path = resources / (language + ".lproj") / "Localizable.strings"
        raw = subprocess.check_output(["plutil", "-convert", "json", "-o", "-", str(path)])
        assert json.loads(raw) == expected, f"Bundled translations differ: {language}"
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(APP)], check=True)
    print(f"PASS: standalone dependency graph, separate app identity, {len(used)} EN/RU labels, bundled resources and signature")


if __name__ == "__main__":
    main()
