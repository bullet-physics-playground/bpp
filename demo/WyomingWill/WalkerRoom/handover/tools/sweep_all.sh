#!/bin/bash
cd "$(dirname "$0")/../.."
mkdir -p "${WORK:-/tmp/walker-work}/sweep2"   # (the sweeps go here: WORK, default /tmp/walker-work)
r4='crank=1, coupler=2, rocker=3, pendant=4'
rsl='crank=1, coupler=2, pendant=3'
declare -A R=( ["Jansen"]='crank=1, rodJ=2, triG=3, rodK=4, rodC=5, rodF=6, triJ4=7' ["Klann"]='crank=1, triA=2, rockerLower=3, triB=4, rockerUpper=5' ["Hoecken slider"]="$rsl" ["Hoecken-Spears slider"]="$rsl" )
for n in "Jansen" "Klann" "Spears 4-bar" "Chebyshev" "Chebyshev diag" "Chebyshev-Spears" "Chebyshev-Spears diag" "Hoecken 4-bar" "Hoecken 4-bar diag" "Hoecken slider" "Hoecken-Spears slider" "Hoecken-Spears 4-bar" "Hoecken-Spears 4-bar diag" "Hoecken-Spears 4-bar duty 85" "Hoecken-Spears 4-bar duty 85 diag" "Chebyshev-Spears lift 51" "Chebyshev-Spears lift 51 diag" "Chebyshev-Spears lift 62" "Chebyshev-Spears lift 62 diag"; do
  p=${R[$n]:-$r4}
  f=$(mktemp ./_sw_XXXX.lua)
  printf 'dofile("lib/trotting-walkers.lua"); dofile("lib/spears-lift-walkers.lua"); ONLY="%s"; CRANK=0.6\ndofile("handover/tools/sweepprobe.lua")\n' "$n" > $f
  SWEEP_OUT="${WORK:-/tmp/walker-work}/sweep2/${n// /_}.txt" QT_QPA_PLATFORM=offscreen ${BPP:-../../../release/bpp} -f $(basename $f) -n 950 2>&1 | grep -i "error" | grep -v ALSA
  rm -f $f
  echo "$n $(grep -c '^S ' "${WORK:-/tmp/walker-work}/sweep2/${n// /_}.txt") $(tail -1 "${WORK:-/tmp/walker-work}/sweep2/${n// /_}.txt" | cut -c1-5)"
done
