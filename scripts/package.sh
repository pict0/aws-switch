#!/usr/bin/env bash
# Builds an unsigned installer package: build/AWSSwitch-<version>.pkg
#   /Applications/AWS Switch.app
#   /usr/local/share/aws-switch/aws-switch.zsh
# scripts/pkg/postinstall adds the source line to the logged-in user's ~/.zshrc.
# Unsigned: on other Macs, Gatekeeper requires right-click > Open, or
# System Settings > Privacy & Security > Open Anyway.
set -euo pipefail

cd "$(dirname "$0")/.."
scripts/bundle.sh

version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
identifier=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" Resources/Info.plist)
staging=build/pkgroot
components=build/components.plist
output="build/AWSSwitch-${version}.pkg"

rm -rf "$staging" "$components" "$output"
mkdir -p "$staging/Applications" "$staging/usr/local/share/aws-switch"
cp -R "build/AWS Switch.app" "$staging/Applications/"
cp shell/aws-switch.zsh "$staging/usr/local/share/aws-switch/"

# Strip quarantine and other removable attributes. com.apple.provenance is SIP-protected and
# survives; pkgbuild records it as ._ entries, which Installer folds back into attributes
# rather than writing as files.
xattr -cr "$staging"
codesign --verify --strict "$staging/Applications/AWS Switch.app"

# Without this, Installer "upgrades" any existing copy of the bundle wherever it lives
# (e.g. ~/Applications) instead of installing to /Applications.
pkgbuild --analyze --root "$staging" "$components"
/usr/libexec/PlistBuddy -c "Set :0:BundleIsRelocatable false" "$components" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Add :0:BundleIsRelocatable bool false" "$components"

pkgbuild \
  --root "$staging" \
  --component-plist "$components" \
  --scripts scripts/pkg \
  --identifier "$identifier" \
  --version "$version" \
  --install-location / \
  "$output"

echo "Built $output"
