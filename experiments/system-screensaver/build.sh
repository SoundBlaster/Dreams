#!/bin/bash
set -euo pipefail
if [ "$#" -ne 1 ] || [[ "$1" != /* ]]; then
  echo "Usage: bash build.sh /absolute/output/directory" >&2
  exit 2
fi
source_dir="$(cd "$(dirname "$0")" && pwd)"
bundle="$1/Dreams Experiment.saver"
mkdir -p "$bundle/Contents/MacOS"
cp "$source_dir/Info.plist" "$bundle/Contents/Info.plist"
xcrun swiftc -swift-version 5 -parse-as-library -emit-library \
  -framework ScreenSaver -framework AppKit \
  "$source_dir/DreamsSaver.swift" -o "$bundle/Contents/MacOS/DreamsSystemSaver"
codesign --force --sign - "$bundle"
echo "$bundle"
