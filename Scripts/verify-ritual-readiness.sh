#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_ONLY=0
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="$ROOT_DIR/build/verification/ritual-readiness-$STAMP"
MANIFEST_PATH="$OUT_DIR/manifest.txt"
REMOTION_REFERENCE_PATH="$ROOT_DIR/build/remotion-ritual/contact-sheet-pass12.png"
RITUAL_SOURCE_PATH="$ROOT_DIR/MotionReveal/Features/MusicWorkspace/Motion/RitualOverlayViews.swift"
RIVE_ASSET_PATH="$ROOT_DIR/MotionReveal/Resources/Rive/playdate_disc_intake.riv"

usage() {
  cat <<'USAGE' >&2
Usage:
  Scripts/verify-ritual-readiness.sh [--report-only]

Checks whether the signature island-disc ritual has the SwiftUI fallback source,
the restored experimental Rive asset, locked Remotion reference when available,
and latest in-app capture evidence.

Without --report-only the script exits non-zero when the SwiftUI ritual source
or restored Rive asset is missing.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --report-only)
      REPORT_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

mkdir -p "$OUT_DIR"

latest_in_app_manifest() {
  find "$ROOT_DIR/build/verification" \
    -path '*/in-app-ritual-*/manifest.txt' \
    -type f \
    -print 2>/dev/null |
    sort |
    tail -n 1
}

write_file_state() {
  local key="$1"
  local path="$2"

  if [[ -f "$path" ]]; then
    echo "${key}_path=$path"
    echo "${key}_sha256=$(shasum -a 256 "$path" | awk '{print $1}')"
  else
    echo "${key}_missing=$path"
  fi
}

RITUAL_SOURCE_STATUS="missing"
if [[ -f "$RITUAL_SOURCE_PATH" ]]; then
  RITUAL_SOURCE_STATUS="present"
fi

RIVE_ASSET_STATUS="missing"
if [[ -f "$RIVE_ASSET_PATH" ]]; then
  RIVE_ASSET_STATUS="present"
fi

LATEST_IN_APP_MANIFEST="$(latest_in_app_manifest || true)"

{
  echo "timestamp=$STAMP"
  echo "report_only=$REPORT_ONLY"
  echo "ritual_runtime=rive-experimental-with-swiftui-fallback"
  echo "rive_status=restored_experimental"
  echo "ritual_source=$RITUAL_SOURCE_PATH"
  echo "ritual_source_status=$RITUAL_SOURCE_STATUS"
  echo "rive_asset=$RIVE_ASSET_PATH"
  echo "rive_asset_status=$RIVE_ASSET_STATUS"
  write_file_state "ritual_source" "$RITUAL_SOURCE_PATH"
  write_file_state "rive_asset" "$RIVE_ASSET_PATH"
  write_file_state "remotion_reference" "$REMOTION_REFERENCE_PATH"
  if [[ -n "$LATEST_IN_APP_MANIFEST" ]]; then
    echo "latest_in_app_manifest=$LATEST_IN_APP_MANIFEST"
    sed 's/^/latest_in_app_/' "$LATEST_IN_APP_MANIFEST"
  else
    echo "latest_in_app_manifest_missing=$ROOT_DIR/build/verification/in-app-ritual-*/manifest.txt"
  fi
} > "$MANIFEST_PATH"

cat "$MANIFEST_PATH"

if [[ "$RITUAL_SOURCE_STATUS" != "present" && "$REPORT_ONLY" -ne 1 ]]; then
  echo "Missing SwiftUI ritual source: $RITUAL_SOURCE_PATH" >&2
  exit 1
fi

if [[ "$RIVE_ASSET_STATUS" != "present" && "$REPORT_ONLY" -ne 1 ]]; then
  echo "Missing Rive intake asset: $RIVE_ASSET_PATH" >&2
  exit 1
fi
