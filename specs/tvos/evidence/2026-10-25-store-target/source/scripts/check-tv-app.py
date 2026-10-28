#!/usr/bin/env python3
"""Verify an exported App Store Apple TV app, independently of project settings."""

import argparse
import json
import plistlib
import subprocess
from pathlib import Path

BUNDLE_ID = "ru.egormerkushev.dreams.tv"
TEAM_ID = "P8T2366K8X"
RESOURCES = (
    "Assets.car", "PrivacyInfo.xcprivacy", "DreamsMatrix.ttf", "Matrix-Code.ttf",
    "Rain.metal", "THIRD_PARTY_NOTICES.md", "LICENSE",
)


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path, help="Exported Payload/DreamsTV.app")
    parser.add_argument("--version", required=True)
    parser.add_argument("--build", required=True)
    args = parser.parse_args()
    app = args.app.resolve()
    info = plistlib.loads((app / "Info.plist").read_bytes())
    require(info.get("CFBundleIdentifier") == BUNDLE_ID, "Unexpected app identifier")
    require(info.get("CFBundleShortVersionString") == args.version, "Unexpected version")
    require(info.get("CFBundleVersion") == args.build, "Unexpected build number")
    require(info.get("CFBundleSupportedPlatforms") == ["AppleTVOS"], "Not a device tvOS app")
    require(info.get("UIDeviceFamily") == [3], "Not an Apple TV-only app")
    for resource in RESOURCES:
        require((app / resource).is_file(), f"Missing bundled resource: {resource}")
    icon = info.get("CFBundleIcons", {}).get("CFBundlePrimaryIcon")
    require(bool(icon), "Missing primary TV icon")
    shelf = info.get("TVTopShelfImage", {})
    require(bool(shelf.get("TVTopShelfPrimaryImage")), "Missing standard Top Shelf image")
    require(bool(shelf.get("TVTopShelfPrimaryImageWide")), "Missing wide Top Shelf image")
    privacy = plistlib.loads((app / "PrivacyInfo.xcprivacy").read_bytes())
    require(privacy.get("NSPrivacyTracking") is False, "Unexpected tracking declaration")
    require(privacy.get("NSPrivacyTrackingDomains") == [], "Unexpected tracking domains")
    require(privacy.get("NSPrivacyCollectedDataTypes") == [], "Unexpected collected data")
    require(privacy.get("NSPrivacyAccessedAPITypes") == [{
        "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
        "NSPrivacyAccessedAPITypeReasons": ["CA92.1"],
    }], "Unexpected required-reason API declaration; re-audit before changing this check")
    profile = plistlib.loads(subprocess.check_output([
        "security", "cms", "-D", "-i", str(app / "embedded.mobileprovision"),
    ], stderr=subprocess.DEVNULL))
    entitlements = profile["Entitlements"]
    require(profile.get("TeamIdentifier") == [TEAM_ID], "Unexpected provisioning team")
    require(entitlements.get("application-identifier") == f"{TEAM_ID}.{BUNDLE_ID}",
            "Unexpected provisioning app identifier")
    require(entitlements.get("get-task-allow") is False, "Development profile permits debugging")
    require("ProvisionedDevices" not in profile, "Device-limited profile is not App Store distribution")
    require(not profile.get("ProvisionsAllDevices"), "All-device profile is not App Store distribution")
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
    signature = subprocess.run(["codesign", "-dv", "--verbose=4", str(app)],
                               text=True, capture_output=True, check=True).stderr
    require(f"TeamIdentifier={TEAM_ID}" in signature, "Unexpected code-signature team")
    signed_entitlements = plistlib.loads(subprocess.check_output([
        "codesign", "-d", "--entitlements", ":-", str(app),
    ], stderr=subprocess.DEVNULL))
    require(signed_entitlements.get("application-identifier") == f"{TEAM_ID}.{BUNDLE_ID}",
            "Unexpected signed app identifier")
    require(signed_entitlements.get("get-task-allow") is False, "Signed app permits debugging")
    libraries = subprocess.check_output([
        "otool", "-L", str(app / info["CFBundleExecutable"]),
    ], text=True)
    print(json.dumps({
        "bundleId": BUNDLE_ID, "version": args.version, "build": args.build,
        "platforms": info["CFBundleSupportedPlatforms"], "deviceFamily": info["UIDeviceFamily"],
        "minimumOS": info.get("MinimumOSVersion"), "sdk": info.get("DTSDKName"),
        "xcodeBuild": info.get("DTXcodeBuild"), "team": TEAM_ID,
        "applicationIdentifier": entitlements["application-identifier"],
        "getTaskAllow": False, "signatureVerified": True, "resources": RESOURCES,
        "privacy": privacy, "icon": icon, "topShelf": shelf,
        "signature": signature, "linkedLibraries": libraries,
    }, indent=2))


if __name__ == "__main__":
    main()
