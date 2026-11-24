#!/bin/bash
# Tests for skills/setup/references/verify-ios.sh with xcrun and xcodebuild
# stubbed, so they run anywhere (CI on Linux, or a Mac without a simulator).
#
#   bash tests/verify-ios.test.sh
# Checks are single-quoted strings that check() evals later, on purpose.
# shellcheck disable=SC2016,SC2034
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SCRIPT="$HERE/../plugins/shipcrew/skills/setup/references/verify-ios.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

STUB="$WORK/stub"
mkdir -p "$STUB/bin" "$STUB/container"

# xcrun: records every call, fakes one simulator and one running app.
cat >"$STUB/bin/xcrun" <<'EOF'
#!/bin/bash
echo "xcrun $*" >>"$STUB/calls"
[[ "$1" == simctl ]] || exit 0
shift
case "$1" in
  list) [[ -f "$STUB/sim" ]] && printf '    %s (0000AAAA-0000-0000-0000-000000000001) (Booted)\n' "$(cat "$STUB/sim")" ;;
  create) echo "$2" >"$STUB/sim"; echo 0000AAAA-0000-0000-0000-000000000001 ;;
  delete) rm -f "$STUB/sim" ;;
  launch) echo "$3" >"$STUB/launched"; shift 3; printf '%s\n' "$@" >"$STUB/launch_args" ;;
  get_app_container) echo "$STUB/container" ;;
  spawn)
    if [[ "$3" == launchctl && ! -f "$STUB/crash" ]]; then
      printf '123\t0\tUIKitApplication:%s[0x1a2b][rb-legacy]\n' "${STUB_RUNNING:-$(cat "$STUB/launched")}"
    fi ;;
  io) sleep "${STUB_SHOT_DELAY:-0}"; : >"${!#}"; echo "shot ${!#}" >>"$STUB/calls" ;;
esac
exit 0
EOF

# xcodebuild: makes the .app folder where the script expects it.
cat >"$STUB/bin/xcodebuild" <<'EOF'
#!/bin/bash
while [[ $# -gt 0 ]]; do
  [[ "$1" == -derivedDataPath ]] && mkdir -p "$2/Build/Products/Debug-iphonesimulator/MyApp.app"
  shift
done
EOF
chmod +x "$STUB/bin/"*

REPO="$WORK/repo"
mkdir -p "$REPO/Sources"
git -C "$REPO" init -q
echo 'tmp/' >"$REPO/.gitignore"
echo 'struct A {}' >"$REPO/Sources/A.swift"
git -C "$REPO" add .
git -C "$REPO" -c user.email=t@example.com -c user.name=t commit -qm init

export STUB PATH="$STUB/bin:$PATH"
export VERIFY_REPO="$REPO" VERIFY_DERIVED="$WORK/dd" VERIFY_SOURCE_PATHS=Sources
RUN="$REPO/tmp/verify/$(date +%Y-%m-%d)"
V() { /bin/bash "$SCRIPT" "$@"; }

fails=0
pass() { echo "ok    $1"; }
fail() { echo "FAIL  $1"; fails=$((fails + 1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

# --- source state ----------------------------------------------------------
s0=$(V state)
echo 'struct B {}' >"$REPO/Sources/B.swift"; s1=$(V state)
echo 'struct B { var x = 1 }' >"$REPO/Sources/B.swift"; s2=$(V state)
check "a new file changes the state" '[[ "$s0" != "$s1" ]]'
check "editing a new file changes the state" '[[ "$s1" != "$s2" ]]'
echo 'notes' >"$REPO/README.md"
check "files outside SOURCE_PATHS do not" '[[ "$(V state)" == "$s2" ]]'

# --- build and doctor ------------------------------------------------------
check "doctor fails before a build" '! V doctor >/dev/null'
V build >/dev/null
check "doctor passes after a build" 'V doctor >/dev/null'
echo 'struct B { var x = 2 }' >"$REPO/Sources/B.swift"
check "doctor fails after a new file is edited" '! V doctor >/dev/null'
V build >/dev/null

echo '' >"$REPO/.gitignore"
check "doctor fails when evidence is not git-ignored" 'out=$(V doctor || true); [[ "$out" == *"not git-ignored"* ]]'
echo 'tmp/' >"$REPO/.gitignore"
V build >/dev/null

# --- shoot -----------------------------------------------------------------
out1=$(V shoot home --wait 0 --at 1,2 -- -title "two words")
out2=$(V shoot home --wait 0 -- -title "two words")
check "first shot is home.png" '[[ "$out1" == "$RUN/home.png" && -f "$out1" ]]'
check "a second shot does not overwrite the first" '[[ "$out2" == "$RUN/home-2.png" && -f "$out2" ]]'
check "launch args with spaces stay one argument" '[[ "$(cat "$STUB/launch_args")" == "$(printf -- "-title\ntwo words")" ]]'
check "--at sets the location" 'grep -q "location .* set 1,2" "$STUB/calls"'
check "no --at clears the location" 'grep -q "location .* clear" "$STUB/calls"'
check "two manifest lines" '[[ $(wc -l <"$RUN/manifest.tsv") -eq 2 ]]'
check "shoot records the simulator per checkout" 'grep -q "^Verify-MyApp-[0-9a-f]\{6\}$" "$STUB/sim"'

touch "$STUB/crash"
check "a crash fails the shot" '! V shoot crashy --wait 0 2>/dev/null'
check "a crash is in the manifest" 'grep -q "^crashy	.*	CRASHED	" "$RUN/manifest.tsv"'
rm "$STUB/crash"

check "a running com.example.MyAppWidget is not the app" '! STUB_RUNNING=com.example.MyAppWidget V shoot widget --wait 0 2>/dev/null'
check "an unknown option exits 2" 'rc=0; V shoot x --nope >/dev/null 2>&1 || rc=$?; [[ $rc -eq 2 ]]'
check "no arguments prints usage" 'out=$(V 2>/dev/null || true); [[ "$out" == *"verify.sh replay"* ]]'

# --- replay ----------------------------------------------------------------
: >"$STUB/calls"
V shoot plain --wait 0 >/dev/null
: >"$STUB/calls"
check "replay of named shots succeeds" 'V replay home plain >/dev/null'
check "replay reruns both shots" '[[ $(grep -c "simctl launch" "$STUB/calls") -eq 2 ]]'
check "replay keeps the recorded args" 'V replay home >/dev/null && [[ "$(cat "$STUB/launch_args")" == "$(printf -- "-title\ntwo words")" ]]'
check "replay writes new evidence" '[[ -f "$RUN/home-4.png" && -f "$RUN/plain-2.png" ]]'
check "replay of a missing name skips it" 'out=$(V replay nosuch 2>&1); [[ "$out" == *"skip  nosuch"* ]]'

# --- lock ------------------------------------------------------------------
: >"$STUB/calls"
STUB_SHOT_DELAY=2 V shoot first --wait 0 >/dev/null &
sleep 0.5
V shoot second --wait 0 >/dev/null 2>&1
wait
order=$(grep -E "simctl launch|^shot" "$STUB/calls" | sed -E 's/.*(launch|shot).*/\1/' | tr '\n' ' ')
check "parallel shots run one at a time" '[[ "$order" == "launch shot launch shot " ]]'
check "the lock is released" '[[ ! -e "$WORK/dd.lock" ]]'

# --- cleanup ---------------------------------------------------------------
V cleanup --delete >/dev/null
check "cleanup --delete removes the simulator" '[[ ! -f "$STUB/sim" ]]'
check "cleanup keeps evidence" '[[ -f "$RUN/home.png" ]]'

echo
if [[ $fails -gt 0 ]]; then echo "$fails failed"; exit 1; fi
echo "all passed"
