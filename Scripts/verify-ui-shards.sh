#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIM_ID="${1:-}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${2:-$ROOT_DIR/build/verification/ui-shards-$STAMP}"
DERIVED_DATA_DIR="$ROOT_DIR/DerivedData"
MANIFEST_PATH="$OUT_DIR/manifest.txt"
BUILD_LOG="$OUT_DIR/build-for-testing.log"
SHARD_STATUS_PATH="$OUT_DIR/shard-status.txt"
MAX_ATTEMPTS="${MOTIONREVEAL_UI_SHARD_ATTEMPTS:-3}"
SHARD_SETTLE_SECONDS="${MOTIONREVEAL_UI_SHARD_SETTLE_SECONDS:-4}"

usage() {
  cat <<'USAGE' >&2
Usage:
  Scripts/verify-ui-shards.sh [SIMULATOR_UDID] [OUT_DIR]

Runs MotionRevealUITests in smaller shards. This avoids long single-process
XCUITest sessions while preserving coverage and writing logs/result bundles.
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

require_tool xcodebuild
require_tool xcrun

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
: > "$SHARD_STATUS_PATH"

if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate >/dev/null
fi

COMMON_ARGS=(
  -project MotionReveal.xcodeproj
  -scheme MotionReveal
  -configuration Debug
  -destination "platform=iOS Simulator,id=$SIM_ID"
  -collect-test-diagnostics never
  COMPILER_INDEX_STORE_ENABLE=NO
  ONLY_ACTIVE_ARCH=YES
  -packageCachePath "$HOME/Library/Caches/org.swift.swiftpm"
  -derivedDataPath "$DERIVED_DATA_DIR"
)

xcodebuild "${COMMON_ARGS[@]}" build-for-testing > "$BUILD_LOG" 2>&1

run_shard() {
  local name="$1"
  shift

  local args=()

  for test_name in "$@"; do
    args+=("-only-testing:MotionRevealUITests/MotionRevealFirstRunUITests/${test_name}")
  done

  for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
    local log_path="$OUT_DIR/${name}-attempt${attempt}.log"
    local result_path="$OUT_DIR/${name}-attempt${attempt}.xcresult"

    rm -rf "$result_path"

    echo "running $name attempt $attempt"
    xcrun simctl terminate "$SIM_ID" com.jjuzzi.motionreveal >/dev/null 2>&1 || true
    sleep "$SHARD_SETTLE_SECONDS"
    if xcodebuild "${COMMON_ARGS[@]}" "${args[@]}" -resultBundlePath "$result_path" test-without-building > "$log_path" 2>&1; then
      xcrun simctl terminate "$SIM_ID" com.jjuzzi.motionreveal >/dev/null 2>&1 || true
      sleep "$SHARD_SETTLE_SECONDS"
      echo "$name=passed attempt=$attempt log=$log_path result=$result_path" >> "$SHARD_STATUS_PATH"
      return 0
    fi

    xcrun simctl terminate "$SIM_ID" com.jjuzzi.motionreveal >/dev/null 2>&1 || true
    sleep "$SHARD_SETTLE_SECONDS"

    if grep -q "XCTAssert" "$log_path" &&
       ! grep -Eq "kAXError|Early unexpected exit|operation never finished bootstrapping|Test crashed with signal kill" "$log_path"; then
      echo "$name=failed assertion attempt=$attempt log=$log_path result=$result_path" >> "$SHARD_STATUS_PATH"
      return 1
    fi

    if [[ "$attempt" == "$MAX_ATTEMPTS" ]]; then
      echo "$name=failed attempts=$attempt log=$log_path result=$result_path" >> "$SHARD_STATUS_PATH"
      return 1
    fi
  done
}

SHARDS=(
  onboarding-create:testFreshInstallOnboardingCreatesFirstSleeveAndShowsImportAudio
  auto-create-ritual:testDebugAutoCreateDiscRitualReachesProjectScreen
  created-disc-only:testCreatedAlbumDiscPromptIsTheOnlySurfaceUntilTapped
  created-disc-immediate:testCreatedAlbumDiscPromptSupportsImmediateTapIntoNotch
  seeded-container:testSeededSongContainerRouteOpensStudioDrawer
  app-intent-container:testPendingAppIntentRouteOpensSongContainerAndStudioDrawer
  mini-player-controls:testMiniPlayerKeepsTransportControlsAccessible
  seeded-library-persistence:testSeededLibraryPersistsAfterRelaunch
  files-import-persistence:testSimulatedFilesImportAddsAudioAttachmentAndPersistsAfterRelaunch
  files-import-metadata:testSimulatedFilesImportShowsAudioFormatMetadataInProjectRow
  failed-audio-import:testFailedAudioImportShowsVisibleRecoveryOverlay
  picker-provider-failure:testFilesPickerProviderFailureShowsVisibleRecoveryOverlay
  attachment-picker-provider-failure:testFilesAttachmentPickerProviderFailureRetryRequestsAttachmentImporter
  marker-persistence:testMarkerCanBeAddedEditedAndPersistsAfterRelaunch
  slot-pull:testTopSlotPullOpensSongContainerAndStudioDrawer
)

for shard in "${SHARDS[@]}"; do
  run_shard "${shard%%:*}" "${shard#*:}"
done

{
  echo "timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "simulator=$SIM_ID"
  echo "out_dir=$OUT_DIR"
  echo "build_log=$BUILD_LOG"
  echo "shard_status=$SHARD_STATUS_PATH"
  echo "status=passed"
  echo "shards=${SHARDS[*]}"
} > "$MANIFEST_PATH"

echo "$MANIFEST_PATH"
