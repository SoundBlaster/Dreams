#!/bin/zsh
# Universal, Developer ID signed, notarized and stapled Dreams-<version>.dmg.
#   scripts/release.sh                  full release (needs a notarytool keychain profile)
#   scripts/release.sh --skip-notarize  sign and verify only, for local checks
# One-time setup:  xcrun notarytool store-credentials dreams-notary
set -euo pipefail
dreams_root="${0:A:h:h}"
cd "$dreams_root"

version="$(<VERSION)"
identity="${DREAMS_SIGN_IDENTITY:-Developer ID Application: Egor Merkushev (P8T2366K8X)}"
profile="${DREAMS_NOTARY_PROFILE:-dreams-notary}"
notarize=1
[[ "${1:-}" == "--skip-notarize" ]] && notarize=0

dist="$dreams_root/dist/release"
app="$dist/Dreams.app"
dmg="$dist/Dreams-$version.dmg"
rm -rf "$dist"
mkdir -p "$dist"

security find-identity -v -p codesigning | grep -qF "$identity" \
  || { print -u2 "Signing identity not found: $identity"; exit 1; }
if (( notarize )); then
  xcrun notarytool history --keychain-profile "$profile" > /dev/null 2>&1 \
    || { print -u2 "No notarytool profile '$profile'. Run: xcrun notarytool store-credentials $profile"; exit 1; }
fi
# The glyph font is built by the pipeline and committed; releases must not depend on Python.
[[ -f Sources/Dreams/DreamsMatrix.ttf ]] || { print -u2 "Sources/Dreams/DreamsMatrix.ttf is missing"; exit 1; }

print "== Build (arm64 + x86_64)"
swift build -c release --arch arm64 --arch x86_64
bin="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"

print "== Assemble"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin/Dreams" "$app/Contents/MacOS/Dreams"
cp -R "$bin/Dreams_Dreams.bundle" "$app/Contents/Resources/"
cp THIRD_PARTY_NOTICES.md LICENSE "$app/Contents/Resources/"
sed "s/__VERSION__/$version/" scripts/Info.plist.in > "$app/Contents/Info.plist"
lipo -archs "$app/Contents/MacOS/Dreams" | grep -q "x86_64" && lipo -archs "$app/Contents/MacOS/Dreams" | grep -q "arm64" \
  || { print -u2 "Binary is not universal"; exit 1; }

print "== Sign (hardened runtime)"
codesign --force --timestamp --options runtime --sign "$identity" "$app"
codesign --verify --deep --strict --verbose=2 "$app"

notarize_and_staple() {  # $1 = file to submit, $2 = file to staple
  xcrun notarytool submit "$1" --keychain-profile "$profile" --wait
  xcrun stapler staple "$2"
  xcrun stapler validate "$2"
}

if (( notarize )); then
  print "== Notarize app"
  ditto -c -k --keepParent "$app" "$dist/Dreams.zip"
  notarize_and_staple "$dist/Dreams.zip" "$app"
  rm "$dist/Dreams.zip"
  spctl -a -vv -t exec "$app"
fi

print "== DMG"
stage="$dist/dmg"
mkdir -p "$stage"
cp -R "$app" "$stage/"
ln -s /Applications "$stage/Applications"
hdiutil create -volname "Dreams $version" -srcfolder "$stage" -fs HFS+ -format UDZO -ov "$dmg" > /dev/null
rm -rf "$stage"
codesign --force --timestamp --sign "$identity" "$dmg"
if (( notarize )); then
  print "== Notarize DMG"
  notarize_and_staple "$dmg" "$dmg"
  spctl -a -vv -t open --context context:primary-signature "$dmg"
fi

print "== Result"
print "$dmg"
print "sha256 $(shasum -a 256 "$dmg" | cut -d' ' -f1)"
(( notarize )) || print "NOT notarized: for local checks only."
