#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_ID="com.jjuzzi.motionreveal"
SIM_ID="${1:-}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${2:-$ROOT_DIR/build/verification/in-app-ritual-$STAMP}"
DERIVED_DATA_DIR="$ROOT_DIR/build/RitualCaptureDerivedData"
APP_PATH="$DERIVED_DATA_DIR/Build/Products/Debug-iphonesimulator/MotionReveal.app"
REFERENCE_CONTACT="$ROOT_DIR/build/remotion-ritual/contact-sheet-pass12.png"
VIDEO_PATH="$OUT_DIR/ritual-capture.mp4"
CONTACT_SHEET_PATH="$OUT_DIR/ritual-contact-sheet.jpg"
BUILD_LOG="$OUT_DIR/xcodebuild.log"
LAUNCH_LOG="$OUT_DIR/launch.log"
MANIFEST_PATH="$OUT_DIR/manifest.txt"
CAPTURE_SECONDS="${CAPTURE_SECONDS:-5}"
CONTACT_TRIM_START="${CONTACT_TRIM_START:-1.75}"

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required tool: $1" >&2
    exit 1
  fi
}

require_tool xcrun
require_tool xcodebuild
require_tool ffmpeg

if [[ -z "$SIM_ID" ]]; then
  SIM_ID="$(
    xcrun simctl list devices booted |
      awk -F'[()]' '/Booted/ && /iPhone/ { print $2; exit }'
  )"
fi

if [[ -z "$SIM_ID" ]]; then
  echo "No booted iPhone simulator found. Boot an iPhone simulator, then rerun." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

cd "$ROOT_DIR"

if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate >/dev/null
fi

xcodebuild \
  -project MotionReveal.xcodeproj \
  -scheme MotionReveal \
  -configuration Debug \
  -destination "id=$SIM_ID" \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  build \
  CODE_SIGNING_ALLOWED=NO > "$BUILD_LOG" 2>&1

xcrun simctl install "$SIM_ID" "$APP_PATH"
xcrun simctl terminate "$SIM_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true

xcrun simctl io "$SIM_ID" recordVideo --codec=h264 "$VIDEO_PATH" >/dev/null 2>&1 &
RECORD_PID="$!"

sleep 1
xcrun simctl launch "$SIM_ID" "$BUNDLE_ID" --auto-load-ritual > "$LAUNCH_LOG"
sleep "$CAPTURE_SECONDS"

kill -INT "$RECORD_PID" >/dev/null 2>&1 || true
wait "$RECORD_PID" >/dev/null 2>&1 || true

ffmpeg -y \
  -i "$VIDEO_PATH" \
  -vf "trim=start=$CONTACT_TRIM_START,setpts=PTS-STARTPTS,fps=4,scale=390:-1:flags=lanczos,tile=5x4" \
  -frames:v 1 \
  "$CONTACT_SHEET_PATH" >/dev/null 2>&1

{
  echo "simulator=$SIM_ID"
  echo "bundle=$BUNDLE_ID"
  echo "capture_seconds=$CAPTURE_SECONDS"
  echo "contact_trim_start=$CONTACT_TRIM_START"
  echo "video=$VIDEO_PATH"
  echo "contact_sheet=$CONTACT_SHEET_PATH"
  if [[ -f "$REFERENCE_CONTACT" ]]; then
    echo "reference_contact=$REFERENCE_CONTACT"
  else
    echo "reference_contact=missing:$REFERENCE_CONTACT"
  fi
  echo
  shasum -a 256 "$VIDEO_PATH" "$CONTACT_SHEET_PATH"
  if [[ -f "$REFERENCE_CONTACT" ]]; then
    shasum -a 256 "$REFERENCE_CONTACT"
  fi
} > "$MANIFEST_PATH"

echo "$CONTACT_SHEET_PATH"
