#!/bin/bash
# One 7 cm (then 5 cm) step on flat ground (steptest.lua): each walker (guides, trot, forward, as the fresh table) from
# 12 distances (its front foot 4 to 20.5 cm short of the face), 20 s. Resumable.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { out=/home/claude/work/st/$4.txt; grep -q '^STEP' $out 2>/dev/null && return; f=$(mktemp ./_st_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; TERRAIN="waves"; AMP=0; SEED=1; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; %s; STEP_H=%s; STEP_GAP=%s; STEP_END=20\ndofile("/home/claude/work/steptest.lua")\n' "$1" "$2" "$3" "$5" > $f
  QT_QPA_PLATFORM=offscreen timeout 1500 /home/claude/build/release/bpp -f $(basename $f) -n 1201 2>&1 | grep -E "^(STEP|STALL)|rror" | grep -v ALSA > $out.tmp && mv $out.tmp $out; rm -f $f; }
J=()
for h in 7 5; do for g in 4 5.5 7 8.5 10 11.5 13 14.5 16 17.5 19 20.5; do
  for n in "Chebyshev-Spears" "Hoecken-Spears slider" "Hoecken slider" "Chebyshev" "Hoecken-Spears 4-bar"; do J+=("$n|UNBRACED=true|$h|${n// /_}_h${h}_g$g|$g"); done; done; done
i=0; for j in "${J[@]}"; do IFS='|' read n x h t g <<< "$j"; one "$n" "$x" "$h" "$t" "$g" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo ST_DONE
