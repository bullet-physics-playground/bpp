#!/bin/bash
# The 5 cm single step (steptest.lua) for Chebyshev-Spears and Hoecken-Spears slider at 200 solver iterations (12 gaps),
# then 1000 (6 gaps). Resumable.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { out=/home/claude/work/st/$4.txt; grep -q '^STEP' $out 2>/dev/null && return; f=$(mktemp ./_si_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; TERRAIN="waves"; AMP=0; SEED=1; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; UNBRACED=true; SOLVER_ITERATIONS=%s; STEP_H=5; STEP_GAP=%s; STEP_END=20\ndofile("/home/claude/work/steptest.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 5000 /home/claude/build/release/bpp -f $(basename $f) -n 1201 2>&1 | grep -E "^(STEP|STALL)|rror" | grep -v ALSA > $out.tmp && mv $out.tmp $out; rm -f $f; }
J=()
for g in 4 5.5 7 8.5 10 11.5 13 14.5 16 17.5 19 20.5; do for n in "Chebyshev-Spears" "Hoecken-Spears slider"; do J+=("$n|200|$g|${n// /_}_it200_h5_g$g"); done; done
for g in 4 7 10 13 16 19; do for n in "Chebyshev-Spears" "Hoecken-Spears slider"; do J+=("$n|1000|$g|${n// /_}_it1000_h5_g$g"); done; done
i=0; for j in "${J[@]}"; do IFS='|' read n it g t <<< "$j"; one "$n" "$it" "$g" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo STIT_DONE
