#!/bin/bash
# check-all.sh -- every exhibit's tour, on its own and inside the hall.
# Each prints "RESULT <exhibit> tour: PASS" when every reading is right.
# Run before sending any patch that touches an exhibit or the hall.
#
#   demo/WyomingWill/BabbagesHall/tools/check-all.sh       (from anywhere)
#   BPP=/path/to/bpp tools/check-all.sh
#
# The runs go one at a time: two bpp processes building the same new
# OpenSCAD part at once can collide in bpp's mesh cache (one then fails to
# load it). Takes a few minutes.
cd "$(dirname "$0")/../../../.." || exit 1          # the repository's top folder
BPP=${BPP:-}
if [ -z "$BPP" ]; then
  for b in build/release/bpp release/bpp debug/bpp build/debug/bpp "$(command -v bpp)"; do
    [ -x "$b" ] && { BPP=$b; break; }
  done
fi
[ -x "$BPP" ] || { echo "no bpp found: set BPP=/path/to/bpp"; exit 1; }
H=demo/WyomingWill/BabbagesHall
fails=0
check() { # name, frames, script, env...
  local name=$1 frames=$2 script=$3; shift 3
  local out
  out=$(env "$@" timeout 7200 "$BPP" -f "$script" -n "$frames" 2>&1 | grep -E "RESULT|rror" | grep -v ALSA)
  printf '%-34s %s\n' "$name" "$(echo "$out" | tr '\n' ' ')"
  echo "$out" | grep -q "PASS" || fails=$((fails + 1))
}
check "Differential, on its own"  2400 $H/exhibits/Differential/differential.lua
check "Pascaline, on its own"     4200 $H/exhibits/Pascaline/pascaline.lua
check "Domino Half Adder, on its own" 1750 $H/exhibits/DominoAdder/domino-adder.lua
check "Lehmer's sieve, on its own"  2600 $H/exhibits/LehmerSieve/lehmer-sieve.lua
check "Digi-Comp II, on its own"  96000 $H/exhibits/DigiComp2/digicomp2.lua
check "Differential, in the hall" 3000 $H/hall.lua HALL_START=differential
check "Pascaline, in the hall"    4000 $H/hall.lua HALL_START=pascaline
check "Domino Half Adder, in the hall" 2400 $H/hall.lua HALL_START=domino
check "Lehmer's sieve, in the hall" 3000 $H/hall.lua HALL_START=lehmer
check "Digi-Comp II, in the hall" 96600 $H/hall.lua HALL_START=digi
if [ $fails -eq 0 ]; then echo "all passed"; else echo "$fails FAILED"; exit 1; fi
