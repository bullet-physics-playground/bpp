#!/bin/bash
# Option A (William, 25 October): patch 37's walkers ("base": flat outside braces, each file's own widths) against each
# change since, one by one: V (OUTSIDE_V, diag builds only), width (LINK_WIDTH 1.0, all), both (diag). Every run build as
# it is run (own frames and guides at trot; diag with outside braces and held pendants), forward, Earth standard, 6 m track,
# 60 s; waves 4 and logs 5 (bump 15); seeds 1-2, each on normal and mirrored ground. vibprobe over stallprobe: TRACK,
# STALL each second, CONTACTS (parts touching by kind: the slider crank against its guide block, Spears 4-bar's legs
# against its body). Resumable; seed by seed, so partial results are usable. Waits for the lift 53 batch first.
until grep -q L53_DONE /home/claude/work/l53.log 2>/dev/null; do sleep 20; done
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { out=/home/claude/work/cmpA/$4.txt; grep -q '^TRACK' $out 2>/dev/null && return; f=$(mktemp ./_ca_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; VIB_BASE="/home/claude/work/stallprobe.lua"; %s\ndofile("/home/claude/work/vibprobe.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 1500 /home/claude/build/release/bpp -f $(basename $f) -n 3700 2>&1 | grep -E "^(TRACK|STALL|CONTACTS|VIB )|rror" | grep -v ALSA > $out.tmp && mv $out.tmp $out; rm -f $f; }
OWN=("Jansen" "Klann" "Spears 4-bar")
GUIDES=("Chebyshev" "Chebyshev-Spears" "Hoecken 4-bar" "Hoecken slider" "Hoecken-Spears slider" "Hoecken-Spears 4-bar" "Hoecken-Spears long-stance" "Spears lift 44" "Spears lift 53")
DIAG=("Chebyshev diag" "Chebyshev-Spears diag" "Hoecken 4-bar diag" "Hoecken-Spears 4-bar diag" "Hoecken-Spears long-stance diag" "Spears lift 44 diag" "Spears lift 53 diag")
J=()
for s in 1 2; do for m in normal mirrored; do M=""; [ $m = mirrored ] && M="TERRAIN_MIRROR=true; "
  for t in "waves:4" "logs:5"; do T="TERRAIN=\"${t%%:*}\"; AMP=${t##*:}; SEED=$s"; tg="${t%%:*}${t##*:}_s${s}_$m"
    for n in "${OWN[@]}"; do for c in base:"" width:"LINK_WIDTH=1.0"; do
      J+=("$n|$T|${M}GAIT={0,180,180,0}; ${c#*:}|${n// /_}_${c%%:*}_$tg"); done; done
    for n in "${GUIDES[@]}"; do for c in base:"" width:"LINK_WIDTH=1.0"; do
      J+=("$n|$T|${M}UNBRACED=true; GAIT={0,180,180,0}; ${c#*:}|${n// /_}_${c%%:*}_$tg"); done; done
    for n in "${DIAG[@]}"; do for c in base:"" V:"OUTSIDE_V=true" width:"LINK_WIDTH=1.0" both:"OUTSIDE_V=true; LINK_WIDTH=1.0"; do
      J+=("$n|$T|${M}DIAG_OUTSIDE=true; PENDANT_HOLD=true; ${c#*:}|${n// /_}_${c%%:*}_$tg"); done; done
  done; done; done
echo "jobs ${#J[@]}"
i=0; for j in "${J[@]}"; do IFS='|' read n T x t <<< "$j"; one "$n" "$T" "$x" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo CMPA_DONE
