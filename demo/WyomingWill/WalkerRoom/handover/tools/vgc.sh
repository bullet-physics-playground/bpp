#!/bin/bash
# bottom brace on the ground: flat outside braces against V (OUTSIDE_V); logs 6 and waves 4, BUMP 15, seed 1, 20 s,
# Earth standard, trot, forward, pendants held; bracehit.lua's BRACESUM (share of frames each brace piece touches each kind)
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { out=/home/claude/work/vgc/$4.txt; grep -q BRACESUM $out 2>/dev/null && return; f=$(mktemp ./_vg_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; TERRAIN="%s"; AMP=%s; BUMP=15; SEED=1; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; DIAG_OUTSIDE=true; PENDANT_HOLD=true; TRACK_SECS=20; CONTACT_AT=1320; BH_SHOW=0; %s\ndofile("/home/claude/work/bracehit.lua")\n' "$1" "$2" "$3" "$5" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1325 2>&1 | grep -E "^(BRACESUM|TRACK)|rror" | grep -v ALSA > $out; rm -f $f; }
J=()
for n in "Chebyshev diag:C" "Hoecken 4-bar diag:H4" "Chebyshev-Spears diag:CS" "Hoecken-Spears 4-bar diag:HS4" "Hoecken-Spears long-stance diag:HSLS" "Spears lift 44 diag:L44" "Spears lift 53 diag:L53"; do
  for g in "logs:6" "waves:4"; do J+=("${n%%:*}|${g%%:*}|${g##*:}|${n##*:}_${g%%:*}_flat|") ; J+=("${n%%:*}|${g%%:*}|${g##*:}|${n##*:}_${g%%:*}_v|OUTSIDE_V=true"); done
done
i=0; for j in "${J[@]}"; do IFS='|' read n t a tag x <<< "$j"; one "$n" "$t" "$a" "$tag" "$x" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo VGC_DONE
