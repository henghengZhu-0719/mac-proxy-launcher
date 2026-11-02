#!/bin/zsh
set -eu
PROJECT_DIR="${0:A:h}"
APP_DIR="$HOME/Applications/代理启动器.app"
mkdir -p "$APP_DIR/Contents/MacOS"
clang -O2 -fobjc-arc -mmacosx-version-min=12.0 "$PROJECT_DIR/main.m" -framework AppKit -o "$APP_DIR/Contents/MacOS/ProxyLauncher"
cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>ProxyLauncher</string>
<key>CFBundleIdentifier</key><string>local.easytier.proxy-launcher</string>
<key>CFBundleName</key><string>代理启动器</string>
<key>CFBundleDisplayName</key><string>代理启动器</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.2</string>
<key>CFBundleVersion</key><string>3</string>
<key>LSMinimumSystemVersion</key><string>12.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP_DIR"
print "Built: $APP_DIR"
