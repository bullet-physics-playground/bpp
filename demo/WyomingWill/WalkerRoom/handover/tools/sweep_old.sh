#!/bin/bash
# one-turn sweeps of the diag builds, pendants at guides' length (DIAG_EXT_UP=0) and held; CS and HS4 diag as built outside
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() {
  n="$1"; extra="$2"
  f=$(mktemp ./_sw_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; CRANK=0.6; PENDANT_HOLD=true; %s\ndofile("/home/claude/work/sweepprobe.lua")\n' "$n" "$extra" > $f
  SWEEP_OUT="/home/claude/work/sweep_old/${n// /_}.txt" QT_QPA_PLATFORM=offscreen /home/claude/build/release/bpp -f $(basename $f) -n 950 2>&1 | grep -i "error" | grep -v ALSA
  rm -f $f
  echo "$n $(grep -c '^S ' "/home/claude/work/sweep_old/${n// /_}.txt") $(tail -1 "/home/claude/work/sweep_old/${n// /_}.txt" | cut -c1-5)"
}
one "Chebyshev diag" "" & one "Hoecken 4-bar diag" ""; wait
one "Hoecken-Spears 4-bar duty 85 diag" "" & one "Chebyshev-Spears lift 51 diag" ""; wait
one "Chebyshev-Spears lift 62 diag" "" & one "Chebyshev-Spears diag" ""; wait
one "Hoecken-Spears 4-bar diag" ""
echo SWEEPS_DONE
