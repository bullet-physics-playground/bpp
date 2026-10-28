#!/bin/bash
# With the exact solver (v:setSolver("mlcp-dantzig"), CFM 1e-8): the 5 cm single step for Chebyshev-Spears and
# Hoecken-Spears slider (6 gaps), then steps 7 seeds 1-4 (60 s), as the fresh table otherwise. Resumable.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { out=/home/claude/work/dz/$3.txt; grep -q -E '^(STEP|TRACK)' $out 2>/dev/null && return; f=$(mktemp ./_dz_XXXX.lua)
  printf 'v:setSolver("mlcp-dantzig"); v:setCfm(1e-8); dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; UNBRACED=true; %s\n' "$1" "$2" > $f
  QT_QPA_PLATFORM=offscreen timeout 6000 /home/claude/build/release/bpp -f $(basename $f) -n $4 2>&1 | grep -E "^(STEP|STALL|TRACK)|rror" | grep -v ALSA > $out.tmp && mv $out.tmp $out; rm -f $f; }
mkdir -p /home/claude/work/dz
J=()
for g in 4 7 10 13 16 19; do for n in "Chebyshev-Spears" "Hoecken-Spears slider"; do J+=("$n|TERRAIN=\"waves\"; AMP=0; SEED=1; STEP_H=5; STEP_GAP=$g; STEP_END=20; dofile(\"/home/claude/work/steptest.lua\")|${n// /_}_h5_g$g|1201"); done; done
for s in 1 2 3 4; do for n in "Chebyshev-Spears" "Hoecken-Spears slider"; do J+=("$n|TERRAIN=\"steps\"; AMP=7; SEED=$s; dofile(\"/home/claude/work/stallprobe.lua\")|${n// /_}_steps7_s$s|3700"); done; done
i=0; for j in "${J[@]}"; do IFS='|' read n x t nf <<< "$j"; one "$n" "$x" "$t" "$nf" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo DZ_DONE
