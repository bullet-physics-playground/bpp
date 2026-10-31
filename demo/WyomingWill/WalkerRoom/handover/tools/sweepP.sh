#!/bin/bash
# one-turn sweeps of the nine plated builds, as built (body held)
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() {
  n="$1"; f=$(mktemp ./_sw_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; CRANK=0.6; GRAVITY=981; FIXED=1/3840; ANKLE_SPRING={stiffness=42000, damping=4200}; %s\ndofile("/home/claude/work/sweepprobe.lua")\n' "$n" "$2" > $f
  SWEEP_OUT="/home/claude/work/sweepP/${n// /_}$3.txt" QT_QPA_PLATFORM=offscreen /home/claude/build/release/bpp -f $(basename $f) -n 950 2>&1 | grep -i "error" | grep -v ALSA
  rm -f $f
}
L=("Chebyshev" "Chebyshev-Spears" "Hoecken 4-bar" "Hoecken slider" "Hoecken-Spears slider" "Hoecken-Spears 4-bar" "Hoecken-Spears 4-bar duty 85" "Chebyshev-Spears lift 51" "Chebyshev-Spears lift 62")
for n in "${L[@]}"; do one "$n" "" "" & one "$n" "PENDANT_HOLD=true" "_hold"; wait; done
echo SWEEPS_DONE
