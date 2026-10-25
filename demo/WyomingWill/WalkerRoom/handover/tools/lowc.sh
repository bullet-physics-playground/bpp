#!/bin/bash
# low plates (PLATE_LOW), 20 s, Earth standard but the body damped every way (BODY_ANG_DAMP=1; plated builds tip over at sides with a free body),
# sides (as built), forward; pendants held except on the sliders (they jam held): every contact by part kind
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { f=$(mktemp ./_lc_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; TERRAIN="waves"; AMP=%s; BUMP=15; SEED=1; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; BODY_ANG_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; PLATE_LOW=true; TRACK_SECS=20; CONTACT_AT=1320; VIB_BASE="/home/claude/work/stallprobe.lua"; %s\ndofile("/home/claude/work/vibprobe_at.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1325 2>&1 | grep -E "^(TRACK|CONTACTS)|rror" | grep -v ALSA > /home/claude/work/lowc/$4_a$2.txt; rm -f $f; }
for n in "Chebyshev:C:H" "Chebyshev-Spears:CS:H" "Hoecken 4-bar:H4:H" "Hoecken-Spears 4-bar:HS4:H" "Hoecken-Spears long-stance:HSLS:H" "Spears lift 44:L44:H" "Spears lift 53:L53:H" "Hoecken slider:HSL:-" "Hoecken-Spears slider:HSSL:-"; do
  IFS=: read name t h <<< "$n"; x=""; [ "$h" = H ] && x="PENDANT_HOLD=true"
  one "$name" 0 "$x" $t & one "$name" 4 "$x" $t; wait
done
echo LOWC_DONE
