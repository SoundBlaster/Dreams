#!/bin/zsh
set -euo pipefail
dreams_root="${0:A:h:h}"
cd "$dreams_root"
dreams_configuration="${1:-release}"
.venv/bin/python scripts/glyphs/pipeline.py build
cp research/glyphs/build/DreamsMatrix.ttf Sources/Dreams/DreamsMatrix.ttf
zsh "$dreams_root/scripts/swift-macos.sh" build -c "$dreams_configuration" --product Dreams
dreams_bin="$(zsh "$dreams_root/scripts/swift-macos.sh" build -c "$dreams_configuration" --show-bin-path)"
dreams_app="$dreams_root/dist/Dreams.app"
mkdir -p "$dreams_app/Contents/MacOS" "$dreams_app/Contents/Resources"
cp "$dreams_bin/Dreams" "$dreams_app/Contents/MacOS/Dreams"
cp -R "$dreams_bin/Dreams_Dreams.bundle" "$dreams_app/Contents/Resources/"
cp "$dreams_root/THIRD_PARTY_NOTICES.md" "$dreams_root/assets/AppIcon.icns" "$dreams_app/Contents/Resources/"
sed "s/__VERSION__/$(<VERSION)/" scripts/Info.plist.in > "$dreams_app/Contents/Info.plist"
codesign --force --deep --sign - "$dreams_app"
print "$dreams_app"
