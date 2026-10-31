#!/bin/bash
# one-turn sweeps of the seven diag builds with outside braces and V bottom braces (OUTSIDE_V), body held, no ankles
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() {
  n="$1"; extra="$2"
  f=$(mktemp ./_sw_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; CRANK=0.6; LINK_WIDTH=1.0; %s\ndofile("/home/claude/work/sweepprobe.lua")\n' "$n" "$extra" > $f
  SWEEP_OUT="/home/claude/work/sweepVW/${n// /_}.txt" QT_QPA_PLATFORM=offscreen /home/claude/build/release/bpp -f $(basename $f) -n 950 2>&1 | grep -i "error" | grep -v ALSA
  rm -f $f
  echo "$n $(grep -c '^S ' "/home/claude/work/sweepVW/${n// /_}.txt") $(tail -1 "/home/claude/work/sweepV/${n// /_}.txt" | cut -c1-5)"
}
one "Chebyshev diag" "DIAG_OUTSIDE=true; OUTSIDE_V=true" & one "Hoecken 4-bar diag" "DIAG_OUTSIDE=true; OUTSIDE_V=true"; wait
one "Hoecken-Spears 4-bar duty 85 diag" "DIAG_OUTSIDE=true; OUTSIDE_V=true" & one "Chebyshev-Spears lift 51 diag" "DIAG_OUTSIDE=true; OUTSIDE_V=true"; wait
one "Chebyshev-Spears lift 62 diag" "DIAG_OUTSIDE=true; OUTSIDE_V=true" & one "Chebyshev-Spears diag" "DIAG_OUTSIDE=true; OUTSIDE_V=true"; wait
one "Hoecken-Spears 4-bar diag" "DIAG_OUTSIDE=true; OUTSIDE_V=true"
echo SWEEPS_DONE
