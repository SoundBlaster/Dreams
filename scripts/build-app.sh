#!/bin/zsh
set -euo pipefail
dreams_root="${0:A:h:h}"
cd "$dreams_root"
dreams_configuration="${1:-release}"
.venv/bin/python scripts/glyphs/pipeline.py build
cp research/glyphs/build/DreamsMatrix.ttf Sources/Dreams/DreamsMatrix.ttf
swift build -c "$dreams_configuration"
dreams_bin="$(swift build -c "$dreams_configuration" --show-bin-path)"
dreams_app="$dreams_root/dist/Dreams.app"
mkdir -p "$dreams_app/Contents/MacOS" "$dreams_app/Contents/Resources"
cp "$dreams_bin/Dreams" "$dreams_app/Contents/MacOS/Dreams"
cp -R "$dreams_bin/Dreams_Dreams.bundle" "$dreams_app/Contents/Resources/"
cp "$dreams_root/THIRD_PARTY_NOTICES.md" "$dreams_app/Contents/Resources/"
cat > "$dreams_app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Dreams</string>
<key>CFBundleIdentifier</key><string>local.dreams.app</string>
<key>CFBundleName</key><string>Dreams</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
<key>LSMinimumSystemVersion</key><string>15.0</string>
</dict></plist>
PLIST
codesign --force --deep --sign - "$dreams_app"
print "$dreams_app"
