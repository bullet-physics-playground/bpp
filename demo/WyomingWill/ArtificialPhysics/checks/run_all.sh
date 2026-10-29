#!/bin/bash
# checks/run_all.sh -- run every check; the regression suite (WORKFLOW.md §3)
#
# Run from anywhere:   bash checks/run_all.sh          (about 2 minutes)
#                      bash checks/run_all.sh --quick  (about 45 s: smaller samples)
# Prints one line per check and a summary; exits 0 only if all pass.
#
# The Lua checks run INSIDE BPP when a BPP is built, so they test the Lua
# the demos actually run on (BPP links Lua 5.1 or 5.2 depending on the
# build). Without BPP they run in a standalone Lua: $LUA if set, else the
# first of lua5.1, lua5.2, lua5.3, lua5.4, lua. Every check runs on 5.1-5.4.
# BPP is found as lib/batch.py finds it: $BPP, else the newer of debug/bpp
# and release/bpp in the repository; BPP=none forces the standalone Lua.
# Checks that need BPP are skipped, not failed, when none is built.
set -u
cd "$(dirname "$0")/.." || exit 1
QUICK=0; [ "${1:-}" = "--quick" ] && QUICK=1
LOG=$(mktemp -d); trap 'rm -rf "$LOG"' EXIT
export SDL_AUDIODRIVER=${SDL_AUDIODRIVER:-dummy} QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-offscreen}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/rt-checks}; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null

find_bpp() {
  [ "${BPP:-}" = "none" ] && return          # BPP=none: use a standalone Lua
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
find_lua() {
  if [ -n "${LUA:-}" ]; then command -v "$LUA" >/dev/null 2>&1 && echo "$LUA"; return; fi
  for l in lua5.1 lua5.2 lua5.3 lua5.4 lua; do command -v "$l" >/dev/null 2>&1 && { echo "$l"; return; }; done
}
BPP_BIN=$(find_bpp)
LUA_BIN=$(find_lua)

if [ -n "$BPP_BIN" ]; then
  RUNNER="bpp"
  VER=$("$BPP_BIN" -l 'print("LUAVERSION " .. _VERSION)' -n 1 2>/dev/null | grep -o 'LUAVERSION.*' | cut -d' ' -f2-)
  WHERE="inside BPP ($BPP_BIN, ${VER:-Lua ?})"
elif [ -n "$LUA_BIN" ]; then
  RUNNER="lua"
  WHERE="in $($LUA_BIN -v 2>&1 | head -1 | awk '{print $1, $2}') ($LUA_BIN); no BPP built"
else
  echo "checks: no BPP and no Lua interpreter found (install lua5.1, or build BPP, or set BPP= / LUA=)"
  exit 1
fi

# One Lua check: runs it, and passes only if it exits 0 AND its last
# PASS/FAIL line says PASS (BPP does not pass a script's exit status on).
lua_check() { # name, file
  if [ $RUNNER = bpp ]; then "$BPP_BIN" -f "$2" -n 1; else "$LUA_BIN" "$2"; fi
}

pass=0; fail=0; skip=0; failed=()
run() { # name, command...
  local name=$1; shift
  local t0=$(date +%s)
  "$@" > "$LOG/$name.txt" 2>&1
  local rc=$?
  local verdict
  verdict=$(grep -E '^(PASS|FAIL)' "$LOG/$name.txt" | tail -1)
  if [ $rc -eq 0 ] && [ "${verdict%% *}" = "PASS" ]; then
    pass=$((pass + 1)); printf "PASS  %-14s %4ds  %s\n" "$name" $(( $(date +%s) - t0 )) "$verdict"
  else
    fail=$((fail + 1)); failed+=("$name")
    printf "FAIL  %-14s %4ds\n" "$name" $(( $(date +%s) - t0 ))
    { grep -E "^(FAIL|error)|FAIL |rror" "$LOG/$name.txt" || tail -3 "$LOG/$name.txt"; } | head -5 | sed 's/^/        /'
  fi
}
skipped() { skip=$((skip + 1)); printf "SKIP  %-14s       %s\n" "$1" "$2"; }

echo "checks: $(date '+%Y-%m-%d %H:%M'), Lua checks run $WHERE"
if [ $QUICK = 1 ]; then export N_DEFAULT=200000; S="0,25,27,31"; else export N_DEFAULT=1000000; S=""; fi

run monitors      lua_check monitors checks/monitors.lua
run ch02          lua_check ch02 checks/ch02.lua
run ch03          lua_check ch03 checks/ch03.lua
run ch04          lua_check ch04 checks/ch04.lua
run ch04_perfect  lua_check ch04_perfect checks/ch04_perfect.lua
run ch04_couette  lua_check ch04_couette checks/ch04_couette.lua
run ch07          lua_check ch07 checks/ch07.lua
run ch11          lua_check ch11 checks/ch11.lua
run world         lua_check world checks/world.lua
run terrain       lua_check terrain checks/terrain.lua
run town          lua_check town checks/town.lua
run buildings     lua_check buildings checks/buildings.lua
run features      lua_check features checks/features.lua
run lattice       lua_check lattice checks/lattice.lua
run ch13          lua_check ch13 checks/ch13.lua
run fixedwing     lua_check fixedwing checks/fixedwing.lua
export N=$N_DEFAULT                        # sample sizes for the two statistical checks
[ -n "$S" ] && export S_LIST=$S
run mfp_theory    lua_check mfp_theory checks/mfp_theory.lua
run rng_appendix  lua_check rng_appendix checks/rng_appendix.lua
unset N S_LIST
if [ -n "$BPP_BIN" ]; then
  export BPP="$BPP_BIN"
  run batch_repeat bash checks/batch_repeat.sh
  run vehicles     bash checks/vehicles.sh
  run geo          lua_check geo checks/geo.lua
else
  skipped batch_repeat "no BPP binary (build BPP or set BPP=)"
  skipped vehicles     "no BPP binary (build BPP or set BPP=)"
  skipped geo          "no BPP binary (build BPP or set BPP=)"
fi

echo "---"
echo "$pass passed, $fail failed, $skip skipped"
[ $fail -eq 0 ] || { echo "failed: ${failed[*]}"; exit 1; }
