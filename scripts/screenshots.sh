#!/bin/bash
# Builds the Debug app for the Simulator and captures every state in scripts/screenshot_states.tsv.
# Debug only: the -RBScreenshot launch argument exists only in Debug builds. Uploads nothing.
set -uo pipefail

OUT="docs/screenshots"
mkdir -p "$OUT"
LOG="$OUT/.capture-log.txt"
: > "$LOG"

# Mid-afternoon local time, so the seeded runs stay on one date.
UTC_HOUR=$(date -u +%H | sed 's/^0//')
OFFSET=$(( (15 - UTC_HOUR + 24) % 24 )); [ "$OFFSET" -gt 12 ] && OFFSET=$((OFFSET - 24))
if [ "$OFFSET" -ge 0 ]; then TZNAME="Etc/GMT-$OFFSET"; else TZNAME="Etc/GMT+$(( -OFFSET ))"; fi
echo "Time zone for the app: $TZNAME" | tee -a "$LOG"

xcodebuild -project RepBell.xcodeproj -scheme RepBell -configuration Debug \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=NO build -quiet || { echo "build failed" | tee -a "$LOG"; exit 1; }
APP=$(find build/Build/Products/Debug-iphonesimulator -maxdepth 1 -name 'RepBell.app' | head -1)
WATCHAPP=$(find "$APP" -name 'RepBellWatch.app' | head -1)
echo "App: $APP  Watch: $WATCHAPP" | tee -a "$LOG"

runtime() { xcrun simctl list runtimes -j | python3 -c "import json,sys; r=[x for x in json.load(sys.stdin)['runtimes'] if x['isAvailable'] and x['name'].startswith('$1')]; print(r[-1]['identifier'] if r else '')"; }
devtype() { xcrun simctl list devicetypes -j | python3 -c "
import json,sys
want=sys.argv[1:]
types=json.load(sys.stdin)['devicetypes']
for w in want:
    for t in types:
        if t['name']==w: print(t['identifier']); sys.exit()
" "$@"; }

IOS_RT=$(runtime iOS); WATCH_RT=$(runtime watchOS)

size_name() {
  case "$1" in
    default) echo large ;;
    ax3) echo accessibility-extra-large ;;
    ax5) echo accessibility-extra-extra-extra-large ;;
  esac
}

shoot() { # udid bundle prefix size state
  local udid=$1 bundle=$2 prefix=$3 size=$4 state=$5
  local file="$OUT/${prefix}_${size}_${state}.png"
  SIMCTL_CHILD_TZ="$TZNAME" xcrun simctl launch --terminate-running-process "$udid" "$bundle" -RBScreenshot "$state" >/dev/null 2>>"$LOG" \
    || { echo "launch failed: $file" >> "$LOG"; return; }
  sleep 4
  xcrun simctl io "$udid" screenshot "$file" >/dev/null 2>>"$LOG" && echo "ok $file" >> "$LOG" || echo "screenshot failed: $file" >> "$LOG"
}

phone() { # prefix "Device name" sizes...
  local prefix=$1 name=$2; shift 2
  local type; type=$(devtype "$name")
  [ -z "$type" ] && { echo "no device type: $name" | tee -a "$LOG"; return; }
  local udid; udid=$(xcrun simctl create "shot-$prefix" "$type" "$IOS_RT")
  xcrun simctl boot "$udid"; xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl status_bar "$udid" override --time "3:00" --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4 2>>"$LOG"
  xcrun simctl ui "$udid" appearance dark 2>>"$LOG"
  xcrun simctl install "$udid" "$APP"
  for size in "$@"; do
    xcrun simctl ui "$udid" content_size "$(size_name "$size")" 2>>"$LOG"
    sleep 1
    while IFS=$'\t' read -r state _ _ _; do
      [ -n "$state" ] && shoot "$udid" com.grahamdeno.repbell "$prefix" "$size" "$state"
    done < scripts/screenshot_states.tsv
  done
  xcrun simctl shutdown "$udid"; xcrun simctl delete "$udid"
}

watch() { # prefix sizes... ; device names tried in order
  local prefix=$1; shift
  local names=$1; shift
  local type=""; IFS='|' read -ra candidates <<< "$names"
  type=$(devtype "${candidates[@]}")
  [ -z "$type" ] && { echo "no watch type for $prefix ($names)" | tee -a "$LOG"; return; }
  echo "$prefix uses $(xcrun simctl list devicetypes -j | python3 -c "import json,sys; print([t['name'] for t in json.load(sys.stdin)['devicetypes'] if t['identifier']=='$type'][0])")" | tee -a "$LOG"
  local udid; udid=$(xcrun simctl create "shot-$prefix" "$type" "$WATCH_RT")
  xcrun simctl boot "$udid"; xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl install "$udid" "$WATCHAPP"
  for size in "$@"; do
    xcrun simctl ui "$udid" content_size "$(size_name "$size")" 2>>"$LOG"
    sleep 1
    for state in watch-empty watch-set-due watch-between-sets watch-busy watch-finished; do
      shoot "$udid" com.grahamdeno.repbell.watchkitapp "$prefix" "$size" "$state"
    done
  done
  xcrun simctl shutdown "$udid"; xcrun simctl delete "$udid"
}

phone iphone16promax "iPhone 16 Pro Max" default ax5
phone iphonese3 "iPhone SE (3rd generation)" default ax5 ax3
watch watch41mm "Apple Watch Series 9 (41mm)|Apple Watch Series 8 (41mm)|Apple Watch Series 7 (41mm)|Apple Watch Series 10 (42mm)|Apple Watch Series 11 (42mm)" default ax5
watch watch45mm "Apple Watch Series 9 (45mm)|Apple Watch Series 8 (45mm)|Apple Watch Series 7 (45mm)|Apple Watch Series 10 (46mm)|Apple Watch Series 11 (46mm)" default ax5

echo "Captured: $(ls "$OUT"/*.png 2>/dev/null | wc -l)" | tee -a "$LOG"
