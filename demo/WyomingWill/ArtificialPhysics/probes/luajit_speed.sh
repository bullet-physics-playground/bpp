#!/bin/bash
# probes/luajit_speed.sh -- BPP's own Lua against LuaJIT on the
# ArtificialPhysics scenes (FINDINGS F100): each scene headless, SEED=1,
# delayMs 0 (lib/batch.lua, as lib/batch.py runs them), a fixed number of
# frames, once with BPP's Lua and once with LuaJIT loaded in its place
# (LD_PRELOAD); then the world generator (probes/worldgen_time.lua). Prints
# one line per run: scene, frames, Lua, exit status, wall seconds, and a
# hash of the scene's printed output, which must be the same for both.
#
# The preload works only for a BPP linked against Lua 5.1 (LuaJIT has the
# 5.1 interface): Ubuntu 24.04's build. A Lua 5.2 build (Ubuntu 22.04)
# would need luabind and BPP built against LuaJIT instead.
#
# Needs LuaJIT's library (apt install libluajit-5.1-2). About 15 minutes.
# Run from the ArtificialPhysics folder:
#   bash probes/luajit_speed.sh [BPP] [LIBLUAJIT]
set -u
cd "$(dirname "$0")/.."
BPP=${1:-../../../release/bpp}
JIT=${2:-$(ls /usr/lib/*/libluajit-5.1.so.2 2>/dev/null | head -1)}
[ -x "$BPP" ] && [ -n "$JIT" ] || { echo "need BPP ($BPP) and libluajit-5.1.so.2"; exit 1; }
export SDL_AUDIODRIVER=dummy QT_QPA_PLATFORM=offscreen SEED=1
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/rt-luajit}; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
LOG=$(mktemp -d); trap 'rm -rf "$LOG"' EXIT
while read -r scene frames env; do
  [ -z "$scene" ] && continue
  for lua in bpp luajit; do
    pre=""; [ $lua = luajit ] && pre=$JIT
    s=$(date +%s.%N)
    env $env LD_PRELOAD=$pre "$BPP" -f "$scene" -l "require('lib.batch').start()" -n "$frames" > "$LOG/out" 2>&1; e=$?
    t=$(echo "$(date +%s.%N) - $s" | bc)
    h=$(grep -av "^rng: \|QStandardPaths" "$LOG/out" | md5sum | cut -c1-8)
    printf '%-40s %5s %-7s exit %d %7.2f s output %s\n' "$scene${env:+ $env}" "$frames" "$lua" "$e" "$t" "$h"
  done
done <<'LIST'
Formations-Newtonian.lua 5400
Formations-Lennard-Jones.lua 5400
Formations-Newtonian-Quadcopter.lua 5400
Formations-Lennard-Jones-Quadcopter.lua 5400
Formations-Newtonian-Ground.lua 5400
Formations-Lennard-Jones-Ground.lua 5400
Formations-Newtonian-Boat.lua 5400
Formations-Lennard-Jones-Boat.lua 5400
Uniform_Coverage.lua 5400
ch02/Spring1D.lua 5400
ch02/Spring2D.lua 5400
ch02/Spring3D.lua 5400
ch02/SolarSystem.lua 5400
ch02/Planets.lua 5400
ch02/Tetrahedron.lua 5400
ch02/SpringLattice.lua 5400
ch04/Couette-Vehicles.lua 3000
ch13/UAV-Attractor.lua 5400
ch13/UAV-Targets.lua 5400
LIST
for lua in bpp luajit; do
  pre=""; [ $lua = luajit ] && pre=$JIT
  echo "$lua: $(LD_PRELOAD=$pre "$BPP" -f probes/worldgen_time.lua -n 1 2>&1 | grep -a 'WORLDGEN total')"
done
