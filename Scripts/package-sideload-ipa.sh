#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_DIR="$ROOT_DIR/build/SideloadDerivedData"
PACKAGE_DIR="$ROOT_DIR/build/sideload"
PAYLOAD_DIR="$PACKAGE_DIR/Payload"
APP_PATH="$DERIVED_DATA_DIR/Build/Products/Release-iphoneos/MotionReveal.app"
BUILD_LOG="$PACKAGE_DIR/xcodebuild.log"
MANIFEST_PATH="$PACKAGE_DIR/manifest.txt"

cd "$ROOT_DIR"
mkdir -p "$PACKAGE_DIR"

if ! xcodebuild \
  -project MotionReveal.xcodeproj \
  -scheme MotionReveal \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  build \
  CODE_SIGNING_ALLOWED=NO > "$BUILD_LOG" 2>&1; then
  cat "$BUILD_LOG" >&2
  exit 1
fi

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist")"
MARKETING_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Info.plist")"
BUILD_NUMBER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Info.plist")"
IPA_PATH="$PACKAGE_DIR/MotionReveal-${MARKETING_VERSION}+${BUILD_NUMBER}-unsigned.ipa"

rm -rf "$PAYLOAD_DIR" "$PACKAGE_DIR"/MotionReveal-*-unsigned.ipa
mkdir -p "$PAYLOAD_DIR"
ditto "$APP_PATH" "$PAYLOAD_DIR/MotionReveal.app"

(
  cd "$PACKAGE_DIR"
  /usr/bin/zip -qry "$IPA_PATH" Payload
)

IPA_SHA256="$(shasum -a 256 "$IPA_PATH" | awk '{print $1}')"
BUILD_TIMESTAMP="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

{
  echo "build_timestamp=$BUILD_TIMESTAMP"
  echo "ipa_path=$IPA_PATH"
  echo "ipa_sha256=$IPA_SHA256"
  echo "bundle_id=$BUNDLE_ID"
  echo "marketing_version=$MARKETING_VERSION"
  echo "build_number=$BUILD_NUMBER"
  echo "app_path=$APP_PATH"
  echo "xcodebuild_log=$BUILD_LOG"
} > "$MANIFEST_PATH"

echo "$IPA_PATH"
