#!/bin/bash
# Chebyshev-Spears lift 62, guides and outside V diag (held), at today's widths and at 1.0; waves 6, bump 15, 60 s, Earth standard,
# trot, forward, seeds 1-4 on normal and mirrored ground. Resumable.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { out=/home/claude/work/l53/$4.txt; grep -q '^TRACK' $out 2>/dev/null && return; f=$(mktemp ./_l53_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; TERRAIN="waves"; AMP=6; BUMP=15; SEED=%s; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; %s\ndofile("/home/claude/work/stallprobe.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 1200 /home/claude/build/release/bpp -f $(basename $f) -n 3700 2>&1 | grep -E "^(TRACK|STALL)" > $out.tmp && mv $out.tmp $out; rm -f $f; }
J=()
for s in 1 2 3 4; do for m in normal mirrored; do M=""; [ $m = mirrored ] && M="TERRAIN_MIRROR=true; "
  for w in w0 w1; do W=""; [ $w = w1 ] && W="LINK_WIDTH=1.0; "
    J+=("Chebyshev-Spears lift 62|$s|${M}${W}UNBRACED=true; GAIT={0,180,180,0}|g_${w}_s${s}_$m")
    J+=("Chebyshev-Spears lift 62 diag|$s|${M}${W}DIAG_OUTSIDE=true; OUTSIDE_V=true; PENDANT_HOLD=true|d_${w}_s${s}_$m")
  done; done; done
i=0; for j in "${J[@]}"; do IFS='|' read n s x t <<< "$j"; one "$n" "$s" "$x" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo L53_DONE
