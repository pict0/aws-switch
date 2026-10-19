#!/usr/bin/env bash
# Builds a release .app bundle and ad-hoc signs it with the hardened runtime.
# Usage: scripts/bundle.sh [--install]   (--install copies it to ~/Applications)
set -euo pipefail

cd "$(dirname "$0")/.."
swift build -c release

app="build/AWS Switch.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp "$(swift build -c release --show-bin-path)/AWSSwitch" "$app/Contents/MacOS/"
cp Resources/Info.plist "$app/Contents/"

codesign --force --options runtime --sign - "$app"
codesign --verify --strict "$app"
echo "Built $app"

if [[ "${1:-}" == "--install" ]]; then
  mkdir -p "$HOME/Applications"
  rm -rf "$HOME/Applications/AWS Switch.app"
  cp -R "$app" "$HOME/Applications/"
  echo "Installed to ~/Applications/AWS Switch.app"
fi
