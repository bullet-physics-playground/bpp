#!/bin/bash
# 20 s at the Earth standard, trot, outside braces, pendants held: every contact by part kind (contact check only)
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { # name tag amp
  f=$(mktemp ./_ct_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; TERRAIN="waves"; AMP=%s; BUMP=15; SEED=1; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; DIAG_OUTSIDE=true; PENDANT_HOLD=true; TRACK_SECS=20; CONTACT_AT=1320; VIB_BASE="/home/claude/work/stallprobe.lua"\ndofile("/home/claude/work/vibprobe_at.lua")\n' "$1" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1325 2>&1 | grep -E "^(CONTACTS|TRACK|WELD)|rror" | grep -v ALSA > /home/claude/work/outb5/$2_a$3.txt
  rm -f $f
}
for n in "Chebyshev diag:C" "Hoecken 4-bar diag:H4" "Hoecken-Spears 4-bar duty 85 diag:HSLS" "Chebyshev-Spears lift 51 diag:L44" "Chebyshev-Spears lift 62 diag:L53"; do
  for a in 0 4; do one "${n%%:*}" "${n##*:}" $a & done; wait
done
echo CT_DONE
