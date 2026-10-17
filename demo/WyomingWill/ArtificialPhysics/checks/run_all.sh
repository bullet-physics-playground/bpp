#!/bin/bash
# checks/run_all.sh -- run every check; the regression suite (WORKFLOW.md §3)
#
# Run from anywhere:   bash checks/run_all.sh          (about 2 minutes)
#                      bash checks/run_all.sh --quick  (about 30 s: smaller samples)
# Prints one line per check and a summary; exits 0 only if all pass.
# Pure-Lua checks run in lua5.1; checks that need BPP find it as
# lib/batch.py does ($BPP, else the newest debug/bpp or release/bpp), and
# are skipped (not failed) when no BPP is built.
set -u
cd "$(dirname "$0")/.." || exit 1
QUICK=0; [ "${1:-}" = "--quick" ] && QUICK=1
LOG=$(mktemp -d); trap 'rm -rf "$LOG"' EXIT

find_bpp() {
  [ -n "${BPP:-}" ] && { echo "$BPP"; return; }
  local d=$PWD
  while [ "$d" != "/" ]; do
    local best=""
    for b in "$d/debug/bpp" "$d/release/bpp"; do
      [ -x "$b" ] && { [ -z "$best" ] || [ "$b" -nt "$best" ]; } && best=$b
    done
    [ -n "$best" ] && { echo "$best"; return; }
    d=$(dirname "$d")
  done
}
BPP_BIN=$(find_bpp)

pass=0; fail=0; skip=0; failed=()
run() { # name, command...
  local name=$1; shift
  local t0=$(date +%s)
  if "$@" > "$LOG/$name.txt" 2>&1; then
    pass=$((pass + 1)); printf "PASS  %-14s %4ds  %s\n" "$name" $(( $(date +%s) - t0 )) "$(grep -E '^(PASS|ok)' "$LOG/$name.txt" | tail -1)"
  else
    fail=$((fail + 1)); failed+=("$name")
    printf "FAIL  %-14s %4ds\n" "$name" $(( $(date +%s) - t0 ))
    grep -E "^(FAIL|error)|FAIL " "$LOG/$name.txt" | head -5 | sed 's/^/        /'
  fi
}
skipped() { skip=$((skip + 1)); printf "SKIP  %-14s       %s\n" "$1" "$2"; }

echo "checks: $(date '+%Y-%m-%d %H:%M'), lua5.1 $(lua5.1 -v 2>&1 | awk '{print $2}'), bpp ${BPP_BIN:-none}"
if [ $QUICK = 1 ]; then N_RNG=200000; N_MFP=200000; else N_RNG=1000000; N_MFP=1000000; fi

run monitors      lua5.1 checks/monitors.lua
run ch02          lua5.1 checks/ch02.lua
run world         lua5.1 checks/world.lua
run mfp_theory    env N=$N_MFP lua5.1 checks/mfp_theory.lua
if [ $QUICK = 1 ]; then
  run rng_appendix env N=$N_RNG lua5.1 checks/rng_appendix.lua 0 25 27 31
else
  run rng_appendix env N=$N_RNG lua5.1 checks/rng_appendix.lua
fi
if [ -n "$BPP_BIN" ]; then
  export BPP="$BPP_BIN"
  run batch_repeat bash checks/batch_repeat.sh
else
  skipped batch_repeat "no BPP binary (build BPP or set BPP=)"
fi

echo "---"
echo "$pass passed, $fail failed, $skip skipped"
[ $fail -eq 0 ] || { echo "failed: ${failed[*]}"; exit 1; }
