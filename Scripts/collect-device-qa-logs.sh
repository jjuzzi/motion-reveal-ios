#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_UDID="${1:-}"
DURATION_SECONDS="${2:-120}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${3:-$ROOT_DIR/build/device-qa/$STAMP}"
LOG_PATH="$OUT_DIR/motionreveal-device.log"
IMPORT_EVENTS_PATH="$OUT_DIR/import-events.log"
SYSLOG_ERROR_PATH="$OUT_DIR/idevicesyslog.stderr.log"
DEVICE_LIST_PATH="$OUT_DIR/device-list.txt"
XCDEVICE_LIST_PATH="$OUT_DIR/xcdevice-list.json"
IDEVICE_ID_LIST_PATH="$OUT_DIR/idevice-id-list.txt"
IDEVICE_ID_NETWORK_LIST_PATH="$OUT_DIR/idevice-id-network-list.txt"
MANIFEST_PATH="$OUT_DIR/manifest.txt"
SIDELOAD_MANIFEST_PATH="$ROOT_DIR/build/sideload/manifest.txt"
IDEVICE_NETWORK="${MOTIONREVEAL_IDEVICE_NETWORK:-0}"

usage() {
  cat <<'USAGE' >&2
Usage:
  Scripts/collect-device-qa-logs.sh [DEVICE_UDID] [SECONDS] [OUT_DIR]

Examples:
  Scripts/collect-device-qa-logs.sh
  Scripts/collect-device-qa-logs.sh 00008140-001234567890001C 180
  MOTIONREVEAL_IDEVICE_NETWORK=1 Scripts/collect-device-qa-logs.sh 00008140-001234567890001C 180

The script captures device inventory and streams MotionReveal logs with
idevicesyslog. If DEVICE_UDID is omitted, idevicesyslog uses the default
connected device. Set MOTIONREVEAL_IDEVICE_NETWORK=1 to stream over
libimobiledevice network pairing.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required tool: $1" >&2
    exit 1
  fi
}

require_tool xcrun
require_tool idevicesyslog
require_tool idevice_id

mkdir -p "$OUT_DIR"

xcrun devicectl list devices > "$DEVICE_LIST_PATH" 2>&1 || true
xcrun xcdevice list > "$XCDEVICE_LIST_PATH" 2>&1 || true
idevice_id -l > "$IDEVICE_ID_LIST_PATH" 2>&1 || true
idevice_id -n -l > "$IDEVICE_ID_NETWORK_LIST_PATH" 2>&1 || true

IDEVICE_ARGS=(--no-colors --process "MotionReveal" --output "$LOG_PATH")
if [[ "$IDEVICE_NETWORK" == "1" || "$IDEVICE_NETWORK" == "true" || "$IDEVICE_NETWORK" == "yes" ]]; then
  IDEVICE_ARGS=(--network "${IDEVICE_ARGS[@]}")
fi
if [[ -n "$DEVICE_UDID" ]]; then
  IDEVICE_ARGS=(--udid "$DEVICE_UDID" "${IDEVICE_ARGS[@]}")
fi

idevicesyslog "${IDEVICE_ARGS[@]}" 2> "$SYSLOG_ERROR_PATH" &
LOG_PID="$!"

sleep "$DURATION_SECONDS"

kill -INT "$LOG_PID" >/dev/null 2>&1 || true
wait "$LOG_PID" >/dev/null 2>&1 || true

if [[ -f "$LOG_PATH" ]]; then
  grep -E "Files picker|Import (copy|status)|securityScopeGranted" "$LOG_PATH" > "$IMPORT_EVENTS_PATH" || true
else
  : > "$IMPORT_EVENTS_PATH"
fi

{
  echo "timestamp=$STAMP"
  echo "device_udid=${DEVICE_UDID:-default-connected-device}"
  echo "duration_seconds=$DURATION_SECONDS"
  echo "device_list=$DEVICE_LIST_PATH"
  echo "xcdevice_list=$XCDEVICE_LIST_PATH"
  echo "idevice_id_list=$IDEVICE_ID_LIST_PATH"
  echo "idevice_id_network_list=$IDEVICE_ID_NETWORK_LIST_PATH"
  echo "idevice_network=$IDEVICE_NETWORK"
  echo "log=$LOG_PATH"
  echo "import_events=$IMPORT_EVENTS_PATH"
  echo "syslog_stderr=$SYSLOG_ERROR_PATH"
  echo "sideload_manifest=$SIDELOAD_MANIFEST_PATH"
  if [[ -f "$SIDELOAD_MANIFEST_PATH" ]]; then
    while IFS= read -r line; do
      case "$line" in
        ipa_path=*|ipa_sha256=*|bundle_id=*|marketing_version=*|build_number=*|build_timestamp=*|xcodebuild_log=*)
          echo "$line"
          ;;
      esac
    done < "$SIDELOAD_MANIFEST_PATH"
  else
    echo "sideload_manifest_missing=$SIDELOAD_MANIFEST_PATH"
  fi
  echo
  if [[ -f "$LOG_PATH" ]]; then
    shasum -a 256 "$LOG_PATH"
  else
    echo "log_missing=$LOG_PATH"
  fi
  if [[ -f "$IMPORT_EVENTS_PATH" ]]; then
    shasum -a 256 "$IMPORT_EVENTS_PATH"
  else
    echo "import_events_missing=$IMPORT_EVENTS_PATH"
  fi
} > "$MANIFEST_PATH"

echo "$OUT_DIR"
