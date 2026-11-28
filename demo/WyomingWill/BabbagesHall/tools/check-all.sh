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
check "Suanpan, on its own"       4000 $H/exhibits/Suanpan/suanpan.lua
check "Suanpan subtracting, alone" 3600 $H/exhibits/Suanpan/suanpan.lua SU_WAY=subtract
check "Suanpan multiplying, alone" 12000 $H/exhibits/Suanpan/suanpan.lua SU_WAY=multiply
check "Slide rule, on its own"    9500 $H/exhibits/SlideRule/slide-rule.lua
check "Slide rule powers, alone"   3600 $H/exhibits/SlideRule/slide-rule.lua SR_WAY=powers
check "Napier's bones, on its own" 12500 $H/exhibits/NapiersBones/napiers-bones.lua
check "Genaille's rods, alone"      9000 $H/exhibits/NapiersBones/napiers-bones.lua NB_WAY=genaille
check "Combination lock, on its own" 6000 $H/exhibits/CombinationLock/combination-lock.lua
check "Combination lock, the safecracker's" 32000 $H/exhibits/CombinationLock/combination-lock.lua LK_WAY=safe
check "Bead sort, on its own"    4000 $H/exhibits/BeadSort/bead-sort.lua
check "Spaghetti sort, on its own" 5000 $H/exhibits/BeadSort/bead-sort.lua BS_WAY=spaghetti
check "Differential, on its own"  2400 $H/exhibits/Differential/differential.lua
check "Pascaline, on its own"     4200 $H/exhibits/Pascaline/pascaline.lua
check "Domino Half Adder, on its own" 1750 $H/exhibits/DominoAdder/domino-adder.lua
check "Slide adder, on its own"   6500 $H/exhibits/SlideAdder/slide-adder.lua
check "Slide adder, subtracting"  6500 $H/exhibits/SlideAdder/slide-adder.lua SA_WAY=subtract
check "Linkages, the inverter, alone" 1400 $H/exhibits/Linkages/linkages.lua
check "Linkages, the straight line"  1200 $H/exhibits/Linkages/linkages.lua LN_WAY=line
check "Linkages, multiplying, alone" 1800 $H/exhibits/Linkages/linkages.lua LN_WAY=multiply
check "Linkages, Kempe's, alone"     1300 $H/exhibits/Linkages/linkages.lua LN_WAY=kempe
check "Linkages that write, alone"  2200 $H/exhibits/LinkagesWrite/linkages-write.lua
check "Lehmer's sieve, on its own"  2600 $H/exhibits/LehmerSieve/lehmer-sieve.lua
check "Galton board, on its own"   6000 $H/exhibits/GaltonBoard/galton.lua
check "Splitter board, on its own" 7000 $H/exhibits/GaltonBoard/splitter-board.lua
check "Splitter board, gambler's ruin" 10000 $H/exhibits/GaltonBoard/splitter-board.lua SB_WALLS=ruin SB_START=1 GB_RUNS=1
check "Digi-Comp II, on its own"  135000 $H/exhibits/DigiComp2/digicomp2.lua
check "Suanpan, in the hall"      4600 $H/hall.lua HALL_START=suanpan
check "Suanpan subtracting, in the hall" 4200 $H/hall.lua HALL_START=subtraction
check "Suanpan multiplying, in the hall" 12600 $H/hall.lua HALL_START=multiplication
check "Slide rule, in the hall"   10100 $H/hall.lua HALL_START=slide
check "Slide rule powers, in the hall" 4200 $H/hall.lua HALL_START=squares
check "Napier's bones, in the hall" 13100 $H/hall.lua HALL_START=napier
check "Genaille's rods, in the hall" 9600 $H/hall.lua HALL_START=genaille
check "Combination lock, in the hall" 6600 $H/hall.lua HALL_START=lock
check "Combination lock, safecracker, hall" 32600 $H/hall.lua HALL_START=safecracker
check "Bead sort, in the hall"   4600 $H/hall.lua HALL_START=bead
check "Spaghetti sort, in the hall" 5600 $H/hall.lua HALL_START=spaghetti
check "Differential, in the hall" 3000 $H/hall.lua HALL_START=differential
check "Pascaline, in the hall"    4000 $H/hall.lua HALL_START=pascaline
check "Domino Half Adder, in the hall" 2400 $H/hall.lua HALL_START=domino
check "Slide adder, in the hall"  7200 $H/hall.lua "HALL_START=slide adder"
check "Slide adder subtracting, hall" 7200 $H/hall.lua "HALL_START=adder: sub"
check "Linkages, in the hall"       2000 $H/hall.lua HALL_START=linkages
check "Linkages straight line, hall" 1800 $H/hall.lua "HALL_START=straight line"
check "Linkages multiplying, hall"  2400 $H/hall.lua "HALL_START=linkages: mult"
check "Linkages Kempe's, hall"       1900 $H/hall.lua "HALL_START=kempe's reversor"
check "Linkages that write, hall"   2800 $H/hall.lua "HALL_START=that write"
check "Lehmer's sieve, in the hall" 3000 $H/hall.lua HALL_START=lehmer
check "Galton board, in the hall"  6600 $H/hall.lua HALL_START=galton
check "Splitter board, in the hall" 7600 $H/hall.lua HALL_START=splitter
check "Digi-Comp II, in the hall" 135600 $H/hall.lua HALL_START=digi
if [ $fails -eq 0 ]; then echo "all passed"; else echo "$fails FAILED"; exit 1; fi
