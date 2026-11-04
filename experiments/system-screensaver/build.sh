#!/bin/bash
set -euo pipefail
if [ "$#" -ne 1 ] || [[ "$1" != /* ]]; then
  echo "Usage: bash build.sh /absolute/output/directory" >&2
  exit 2
fi
source_dir="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$source_dir/../.." && pwd)"
bundle="$1/Dreams Experiment.saver"
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources"
cp "$source_dir/Info.plist" "$bundle/Contents/Info.plist"
cp "$root/Sources/Dreams/Rain.metal" "$root/Sources/Dreams/Matrix-Code.ttf" "$root/Sources/Dreams/DreamsMatrix.ttf" "$bundle/Contents/Resources/"
xcrun swiftc -swift-version 5 -parse-as-library -emit-library \
  -framework ScreenSaver -framework AppKit -framework MetalKit \
  "$source_dir/DreamsSaver.swift" \
  "$root/Sources/Dreams/features/rain/ui/RainRenderer.swift" \
  "$root/Sources/Dreams/features/rain/ui/MatrixRain.swift" \
  "$root/Sources/Dreams/features/rain/ui/FPSOverlay.swift" \
  "$root/Sources/Dreams/features/rain/model/MatrixSimulation.swift" \
  "$root/Sources/Dreams/features/rain/model/GlyphPulse.swift" \
  "$root/Sources/Dreams/features/rain/model/PresentedFPS.swift" \
  "$root/Sources/Dreams/features/rain/model/RainActivity.swift" \
  "$root/Sources/Dreams/features/rain/model/RainFrameBudget.swift" \
  "$root/Sources/Dreams/features/rain/model/RainPerformance.swift" \
  "$root/Sources/Dreams/features/rain/config/DreamsPreset.swift" \
  "$root/Sources/Dreams/entities/agent-activity/model/KeywordFeed.swift" \
  "$root/Sources/Dreams/entities/agent-activity/model/KeywordFeedReader.swift" \
  "$root/Sources/Dreams/entities/agent-activity/model/HookWord.swift" \
  "$root/Sources/Dreams/entities/agent-activity/model/ToolCallLine.swift" \
  "$root/Sources/Dreams/shared/lib/DreamsError.swift" \
  "$root/Sources/Dreams/shared/lib/Localization.swift" \
  -o "$bundle/Contents/MacOS/DreamsSystemSaver"
codesign --force --sign - "$bundle"
echo "$bundle"
