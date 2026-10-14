#!/bin/zsh
set -euo pipefail
dreams_root="${0:A:h:h}"
dreams_catalog_package="$dreams_root/Packages/DreamsSettingsUI"
dreams_catalog_configuration="${1:-release}"
swift build --package-path "$dreams_catalog_package" -c "$dreams_catalog_configuration" --product DreamsSettingsCatalog -Xswiftc -warnings-as-errors
dreams_catalog_bin="$(swift build --package-path "$dreams_catalog_package" -c "$dreams_catalog_configuration" --show-bin-path)"
dreams_catalog_app="$dreams_root/dist/DreamsSettingsCatalog.app"
mkdir -p "$dreams_catalog_app/Contents/MacOS" "$dreams_catalog_app/Contents/Resources"
cp "$dreams_catalog_bin/DreamsSettingsCatalog" "$dreams_catalog_app/Contents/MacOS/"
cp -R "$dreams_catalog_bin/DreamsSettingsUI_DreamsSettingsCatalog.bundle" "$dreams_catalog_app/Contents/Resources/"
cp "$dreams_root/assets/AppIcon.icns" "$dreams_catalog_app/Contents/Resources/"
cat > "$dreams_catalog_app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>ru.egormerkushev.dreams.settings-catalog</string>
<key>CFBundleName</key><string>Dreams Settings Catalog</string>
<key>CFBundleDisplayName</key><string>Dreams Settings Catalog</string>
<key>CFBundleExecutable</key><string>DreamsSettingsCatalog</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>15.0</string>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>CFBundleLocalizations</key><array><string>en</string><string>ru</string></array>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --deep --sign - "$dreams_catalog_app"
print "$dreams_catalog_app"
