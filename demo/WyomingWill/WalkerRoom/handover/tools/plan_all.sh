#!/bin/bash
# plan_all.sh OUT : the plan geometry of every walker build, as the room builds it
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
rm -f "$1"
for n in "Jansen" "Klann" "Spears 4-bar" "Chebyshev" "Chebyshev diag" "Chebyshev-Spears" "Chebyshev-Spears diag" "Hoecken 4-bar" "Hoecken 4-bar diag" "Hoecken slider" "Hoecken-Spears slider" "Hoecken-Spears 4-bar" "Hoecken-Spears 4-bar diag" "Hoecken-Spears 4-bar duty 85" "Hoecken-Spears 4-bar duty 85 diag" "Chebyshev-Spears lift 51" "Chebyshev-Spears lift 51 diag" "Chebyshev-Spears lift 62" "Chebyshev-Spears lift 62 diag"; do
  f=$(mktemp ./_pl_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; AMP=0; SEED=1; %s\ndofile("/home/claude/work/planprobe.lua")\n' "$n" "$2" > $f
  QT_QPA_PLATFORM=offscreen /home/claude/build/release/bpp -f $(basename $f) -n 2 2>&1 | grep "^PLAN" >> "$1"
  rm -f $f
done
