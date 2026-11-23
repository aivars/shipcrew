#!/bin/bash
# verify.sh for an iOS app. Builds this checkout, drives it on its own
# simulator with launch arguments, and keeps screenshots as evidence.
#
#   verify.sh doctor                      is the build worth driving?
#   verify.sh build                       build this checkout
#   verify.sh shoot <name> [opts] -- <launch args>
#       --wait <s>          seconds before the screenshot (default 8)
#       --appearance <m>    light | dark (default light)
#       --at <lat,lon>      simulated location (default: none)
#       --text-size <s>     simctl content size (default large)
#       --keep              reuse the installed app and its data
#   verify.sh cleanup                     stop the app, shut the simulator
#
# Fill in the block below when you copy this into a repo. Every value can
# also be set from the environment, which is how the template is tested.
set -euo pipefail

# ---- This app -------------------------------------------------------------
APP_NAME=${VERIFY_APP_NAME:-MyApp}                # used in names only
BUNDLE=${VERIFY_BUNDLE:-com.example.MyApp}
PROJECT=${VERIFY_PROJECT:-MyApp.xcodeproj}        # or MyApp.xcworkspace
SCHEME=${VERIFY_SCHEME:-MyApp}
PRODUCT=${VERIFY_PRODUCT:-$SCHEME}                # <PRODUCT>.app
SIM_DEVICE=${VERIFY_SIM_DEVICE:-iPhone 17 Pro}    # a name from: xcrun simctl list devicetypes
# Paths whose changes make a build stale. Name the source folders: "." also
# counts docs and scripts, and every edit there would force a rebuild.
SOURCE_PATHS=${VERIFY_SOURCE_PATHS:-.}
# Launch arguments every shot needs (skip onboarding, silence prompts).
read -r -a BASE_ARGS <<<"${VERIFY_BASE_ARGS:-}"
# Permissions granted before launch, e.g. "photos camera location-always".
GRANTS=${VERIFY_GRANTS:-}
# Simulator locale, e.g. en_GB. Empty leaves the simulator's own.
LOCALE=${VERIFY_LOCALE:-}

# Runs after each clean install, before launch. $1 is the app's data
# container. Copy seed files here if a launch argument reads them.
seed_app() {
  :
}
# ---------------------------------------------------------------------------

# This file lives at .claude/skills/verify-<app>/scripts/verify.sh
REPO=${VERIFY_REPO:-$(cd "$(dirname "$0")/../../../.." && pwd)}
SLUG=$(echo "$APP_NAME" | tr '[:upper:] ' '[:lower:]-')
SIM_NAME=${VERIFY_SIM_NAME:-Verify-$APP_NAME}
DERIVED=${VERIFY_DERIVED:-/tmp/verify-$SLUG-dd}
RUN=${VERIFY_RUN:-$REPO/tmp/verify/$(date +%Y-%m-%d)}   # keep tmp/ git-ignored
APP="$DERIVED/Build/Products/Debug-iphonesimulator/$PRODUCT.app"
STAMP="$DERIVED/verify-stamp.txt"

# What the build was made from: the commit plus hashes of uncommitted work,
# so a screenshot can never pass for a different state of the code.
source_state() {
  local head files diff
  head=$(git -C "$REPO" rev-parse --short HEAD)
  # shellcheck disable=SC2086
  files=$(git -C "$REPO" status --porcelain -- $SOURCE_PATHS | shasum | cut -c1-8)
  # shellcheck disable=SC2086
  diff=$(git -C "$REPO" diff HEAD -- $SOURCE_PATHS | shasum | cut -c1-8)
  echo "$head files:$files diff:$diff"
}

sim_udid() {
  xcrun simctl list devices | { grep -F "$SIM_NAME (" || true; } | head -1 |
    sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/'
}

ensure_sim() {
  UDID=$(sim_udid)
  if [[ -z "$UDID" ]]; then
    # No runtime given: simctl picks the newest one the device supports.
    UDID=$(xcrun simctl create "$SIM_NAME" "$SIM_DEVICE")
    echo "created simulator $SIM_NAME $UDID"
  fi
  xcrun simctl boot "$UDID" 2>/dev/null || true
  xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
  if [[ -n "$LOCALE" && "$(xcrun simctl spawn "$UDID" defaults read -g AppleLocale 2>/dev/null)" != "$LOCALE" ]]; then
    xcrun simctl spawn "$UDID" defaults write -g AppleLocale -string "$LOCALE"
    xcrun simctl spawn "$UDID" defaults write -g AppleLanguages -array "${LOCALE%%_*}"
    xcrun simctl shutdown "$UDID" 2>/dev/null || true
    xcrun simctl boot "$UDID"
    xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
  fi
}

cmd_build() {
  local kind=-project
  [[ "$PROJECT" == *.xcworkspace ]] && kind=-workspace
  mkdir -p "$DERIVED"
  rm -f "$STAMP"
  xcodebuild build "$kind" "$REPO/$PROJECT" -scheme "$SCHEME" -configuration Debug \
    -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DERIVED" -quiet
  source_state >"$STAMP"
  echo "built $(cat "$STAMP")"
}

cmd_doctor() {
  local ok=0 udid
  udid=$(sim_udid)
  if [[ -n "$udid" ]]; then echo "ok    simulator $SIM_NAME $udid"; else echo "note  simulator $SIM_NAME missing; shoot makes it"; fi
  if [[ ! -d "$APP" ]]; then
    echo "FAIL  no build at $APP; run: verify.sh build"; ok=1
  elif [[ ! -f "$STAMP" ]]; then
    echo "FAIL  the last build did not finish; run: verify.sh build"; ok=1
  elif [[ "$(cat "$STAMP")" != "$(source_state)" ]]; then
    echo "FAIL  build is from [$(cat "$STAMP")], checkout is [$(source_state)]; run: verify.sh build"; ok=1
  else
    echo "ok    build matches checkout [$(cat "$STAMP")]"
  fi
  echo "evidence goes to $RUN"
  return $ok
}

cmd_shoot() {
  local name=${1:?shoot needs a name}; shift
  local wait=8 appearance=light where="" size=large keep=0
  while [[ $# -gt 0 && "$1" != "--" ]]; do
    case "$1" in
      --wait) wait=$2; shift 2 ;;
      --appearance) appearance=$2; shift 2 ;;
      --at) where=$2; shift 2 ;;
      --text-size) size=$2; shift 2 ;;
      --keep) keep=1; shift ;;
      *) echo "unknown option $1" >&2; exit 2 ;;
    esac
  done
  [[ "${1:-}" == "--" ]] && shift
  cmd_doctor >/dev/null || { cmd_doctor; exit 1; }
  ensure_sim
  mkdir -p "$RUN"
  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
  if [[ $keep -eq 0 ]]; then
    # A clean install per shot: data left by one state must not show in the next.
    xcrun simctl uninstall "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
    xcrun simctl install "$UDID" "$APP"
    seed_app "$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data)"
    for service in $GRANTS; do
      xcrun simctl privacy "$UDID" grant "$service" "$BUNDLE" 2>/dev/null || true
    done
  fi
  xcrun simctl ui "$UDID" appearance "$appearance" >/dev/null 2>&1 || true
  xcrun simctl ui "$UDID" content_size "$size" >/dev/null 2>&1 || true
  [[ -n "$where" ]] && xcrun simctl location "$UDID" set "$where"
  xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged \
    --batteryLevel 100 --cellularMode active --cellularBars 4 --wifiBars 3 >/dev/null 2>&1 || true
  rm -f "$RUN/$name.png"
  xcrun simctl launch "$UDID" "$BUNDLE" ${BASE_ARGS[@]+"${BASE_ARGS[@]}"} "$@" >/dev/null
  sleep "$wait"
  # Read the list whole first: grep -q closing the pipe early fails it under pipefail.
  local running
  running=$(xcrun simctl spawn "$UDID" launchctl list 2>/dev/null || true)
  if [[ "$running" != *"UIKitApplication:$BUNDLE"* ]]; then
    echo "FAIL  the app is not running $wait s after launch (crash?)" >&2
    printf '%s\tCRASHED\t%s\t%s\n' "$name" "$(cat "$STAMP")" "$*" >>"$RUN/manifest.tsv"
    exit 1
  fi
  xcrun simctl io "$UDID" screenshot --type png "$RUN/$name.png" >/dev/null 2>&1
  printf '%s\t%s\t%s\t%s %s %s\t%s\n' "$name" "$(date +%H:%M:%S)" "$(cat "$STAMP")" \
    "$appearance" "$size" "${where:-no-location}" "$*" >>"$RUN/manifest.tsv"
  echo "$RUN/$name.png"
}

cmd_cleanup() {
  UDID=$(sim_udid)
  [[ -z "$UDID" ]] && return 0
  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
  xcrun simctl status_bar "$UDID" clear >/dev/null 2>&1 || true
  xcrun simctl shutdown "$UDID" 2>/dev/null || true
  echo "stopped $SIM_NAME; evidence kept in $RUN"
}

case "${1:-}" in
  doctor) cmd_doctor ;;
  build) cmd_build ;;
  shoot) shift; cmd_shoot "$@" ;;
  cleanup) cmd_cleanup ;;
  *) sed -n '2,16p' "$0"; exit 2 ;;
esac
