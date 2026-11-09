#!/bin/zsh
set -eu
PROJECT_DIR="${0:A:h}"
APP_DIR="$HOME/Applications/代理启动器.app"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
ICON_WORK_DIR=$(mktemp -d)
trap 'rm -rf "$ICON_WORK_DIR"' EXIT
ICONSET_DIR="$ICON_WORK_DIR/LauncherIcon.iconset"
mkdir -p "$ICONSET_DIR"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$PROJECT_DIR/assets/LauncherIcon.png" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
    retina_size=$((size * 2))
    sips -z "$retina_size" "$retina_size" "$PROJECT_DIR/assets/LauncherIcon.png" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/LauncherIcon.icns"
cp "$PROJECT_DIR/assets/LauncherIcon.png" "$APP_DIR/Contents/Resources/LauncherIcon.png"
clang -O2 -fobjc-arc -mmacosx-version-min=12.0 "$PROJECT_DIR/main.m" -framework AppKit -o "$APP_DIR/Contents/MacOS/ProxyLauncher"
cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>ProxyLauncher</string>
<key>CFBundleIdentifier</key><string>local.easytier.proxy-launcher</string>
<key>CFBundleName</key><string>代理启动器</string>
<key>CFBundleDisplayName</key><string>代理启动器</string>
<key>CFBundleIconFile</key><string>LauncherIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.5</string>
<key>CFBundleVersion</key><string>6</string>
<key>LSMinimumSystemVersion</key><string>12.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP_DIR"
print "Built: $APP_DIR"
