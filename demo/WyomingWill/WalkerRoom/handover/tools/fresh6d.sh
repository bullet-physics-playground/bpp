#!/bin/bash
# The two sliders again with SLIDER_6DOF (the room's default from 27 October), as the fresh table (William, 25 October): all 19 run builds as they stand (own frames and guides at trot; diag with outside
# braces and held pendants, no V), LINK_WIDTH 1.0, forward, Earth standard, 8 m track, 60 s, bump 15, normal ground.
# Flat; waves 2/4/6; logs 3/5/7; steps 3/5/7; seeds 1-2 (seed 1 first). vibprobe over stallprobe: TRACK, STALL, CONTACTS.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { out=/home/claude/work/fresh6d/$4.txt; grep -q '^TRACK' $out 2>/dev/null && return; f=$(mktemp ./_f6_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; VIB_BASE="/home/claude/work/slidertest.lua"; %s\ndofile("/home/claude/work/vibprobe.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 1500 /home/claude/build/release/bpp -f $(basename $f) -n 3700 2>&1 | grep -E "^(TRACK|STALL|CONTACTS|VIB |SLIDER)|rror" | grep -v ALSA > $out.tmp && mv $out.tmp $out; rm -f $f; }
OWN=("Jansen" "Klann" "Spears 4-bar")
GUIDES=("Chebyshev" "Chebyshev-Spears" "Hoecken 4-bar" "Hoecken slider" "Hoecken-Spears slider" "Hoecken-Spears 4-bar" "Hoecken-Spears 4-bar duty 85" "Chebyshev-Spears lift 51" "Chebyshev-Spears lift 62")
DIAG=("Chebyshev diag" "Chebyshev-Spears diag" "Hoecken 4-bar diag" "Hoecken-Spears 4-bar diag" "Hoecken-Spears 4-bar duty 85 diag" "Chebyshev-Spears lift 51 diag" "Chebyshev-Spears lift 62 diag")
J=()
for s in 1 2; do
  for t in waves:0 waves:2 waves:4 waves:6 logs:3 logs:5 logs:7 steps:3 steps:5 steps:7; do
    T="TERRAIN=\"${t%%:*}\"; AMP=${t##*:}; SEED=$s"; tg="${t%%:*}${t##*:}_s$s"; [ $t = waves:0 ] && tg="flat_s$s"
    for n in "Hoecken slider" "Hoecken-Spears slider"; do J+=("$n|$T|UNBRACED=true|${n// /_}_$tg"); done
  done; done
echo "jobs ${#J[@]}"
i=0; for j in "${J[@]}"; do IFS='|' read n T x t <<< "$j"; one "$n" "$T" "$x" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo FRESH6D_DONE
