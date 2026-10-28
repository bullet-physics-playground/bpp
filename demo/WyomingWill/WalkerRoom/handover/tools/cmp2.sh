#!/bin/bash
# Waves 4 seed 1 and flat, Chebyshev-Spears and Hoecken-Spears slider: the exact solver (MLCP) against converged sequential
# impulse (1000 iterations, residual 0.01). Resumable.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { out=/home/claude/work/cmp2/$3.txt; grep -q '^TRACK' $out 2>/dev/null && return; f=$(mktemp ./_c2_XXXX.lua)
  printf '%s; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; UNBRACED=true; %s; dofile("/home/claude/work/stallprobe.lua")\n' "$4" "$1" "$2" > $f
  QT_QPA_PLATFORM=offscreen timeout 6000 /home/claude/build/release/bpp -f $(basename $f) -n 3700 2>&1 | grep -E "^(STALL|TRACK)|rror" | grep -v ALSA > $out.tmp && mv $out.tmp $out; rm -f $f; }
J=()
for t in waves:4 waves:0 logs:5; do for n in "Chebyshev-Spears" "Hoecken-Spears slider"; do for sv in 'mlcp:v:setSolver("mlcp-dantzig"); v:setCfm(1e-8)' 'si1k:v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=1000'; do
  J+=("$n|TERRAIN=\"${t%%:*}\"; AMP=${t##*:}; SEED=1|${n// /_}_${sv%%:*}_${t%%:*}${t##*:}|${sv#*:}"); done; done; done
i=0; for j in "${J[@]}"; do IFS='|' read n x t s <<< "$j"; one "$n" "$x" "$t" "$s" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo CMP2_DONE
