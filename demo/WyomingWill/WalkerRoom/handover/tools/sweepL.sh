#!/bin/bash
# one-turn sweeps of the nine plated builds with low plates (PLATE_LOW), body held, ankles on
cd "$(dirname "$0")/../.."
mkdir -p "${WORK:-/tmp/walker-work}/sweepL"   # (the sweeps go here: WORK, default /tmp/walker-work)
one() {
  n="$1"; f=$(mktemp ./_sw_XXXX.lua)
  printf 'dofile("lib/trotting-walkers.lua"); dofile("lib/spears-lift-walkers.lua"); ONLY="%s"; CRANK=0.6; GRAVITY=981; FIXED=1/3840; ANKLE_SPRING={stiffness=42000, damping=4200}; PLATE_LOW=true; %s\ndofile("handover/tools/sweepprobe.lua")\n' "$n" "$2" > $f
  SWEEP_OUT="${WORK:-/tmp/walker-work}/sweepL/${n// /_}$3.txt" QT_QPA_PLATFORM=offscreen ${BPP:-../../../release/bpp} -f $(basename $f) -n 950 2>&1 | grep -i "error" | grep -v ALSA
  rm -f $f
}
L=("Chebyshev" "Chebyshev-Spears" "Hoecken 4-bar" "Hoecken slider" "Hoecken-Spears slider" "Hoecken-Spears 4-bar" "Hoecken-Spears 4-bar duty 85" "Chebyshev-Spears lift 51" "Chebyshev-Spears lift 62")
one "${L[0]}" "" "" & one "${L[1]}" "" ""; wait; one "${L[2]}" "" "" & one "${L[3]}" "" ""; wait; one "${L[4]}" "" "" & one "${L[5]}" "" ""; wait; one "${L[6]}" "" "" & one "${L[7]}" "" ""; wait; one "${L[8]}" "" ""
echo SWEEPS_DONE
