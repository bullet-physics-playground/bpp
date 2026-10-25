#!/bin/bash
# one-turn sweeps of the diag builds, pendants at guides' length (DIAG_EXT_UP=0); CS and HS4 diag as built outside. (No ankles here, so PENDANT_HOLD finds no pendants and is not on.)
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() {
  n="$1"; extra="$2"
  f=$(mktemp ./_sw_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; CRANK=0.6; LINK_WIDTH=1.0; %s\ndofile("/home/claude/work/sweepprobe.lua")\n' "$n" "$extra" > $f
  SWEEP_OUT="/home/claude/work/sweep6W/${n// /_}.txt" QT_QPA_PLATFORM=offscreen /home/claude/build/release/bpp -f $(basename $f) -n 950 2>&1 | grep -i "error" | grep -v ALSA
  rm -f $f
  echo "$n $(grep -c '^S ' "/home/claude/work/sweep6W/${n// /_}.txt") $(tail -1 "/home/claude/work/sweep6/${n// /_}.txt" | cut -c1-5)"
}
one "Chebyshev diag" "DIAG_OUTSIDE=true" & one "Hoecken 4-bar diag" "DIAG_OUTSIDE=true"; wait
one "Hoecken-Spears long-stance diag" "DIAG_OUTSIDE=true" & one "Spears lift 44 diag" "DIAG_OUTSIDE=true"; wait
one "Spears lift 53 diag" "DIAG_OUTSIDE=true" & one "Chebyshev-Spears diag" "DIAG_OUTSIDE=true"; wait
one "Hoecken-Spears 4-bar diag" "DIAG_OUTSIDE=true"
echo SWEEPS_DONE
