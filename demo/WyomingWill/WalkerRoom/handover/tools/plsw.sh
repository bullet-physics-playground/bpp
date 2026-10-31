#!/bin/bash
# plated builds as built (sides, sidePhase 180), Earth standard, waves 4, 20 s: pendant swing against the body (vibprobe pend), with and without PENDANT_HOLD
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { f=$(mktemp ./_ps_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; TERRAIN="waves"; AMP=4; BUMP=15; SEED=1; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; TRACK_SECS=20; CONTACT_AT=1320; VIB_BASE="/home/claude/work/stallprobe.lua"; %s\ndofile("/home/claude/work/vibprobe_at.lua")\n' "$1" "$2" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1325 2>&1 | grep -E "^(TRACK|VIB |CONTACTS)|rror" | grep -v ALSA > /home/claude/work/plsw/$3.txt; rm -f $f; }
for n in "Chebyshev:C" "Chebyshev-Spears:CS" "Hoecken 4-bar:H4" "Hoecken slider:HSL" "Hoecken-Spears slider:HSSL" "Hoecken-Spears 4-bar:HS4" "Hoecken-Spears 4-bar duty 85:HSLS" "Chebyshev-Spears lift 51:L44" "Chebyshev-Spears lift 62:L53"; do
  one "${n%%:*}" "" "${n##*:}_plain" & one "${n%%:*}" "PENDANT_HOLD=true" "${n##*:}_hold"; wait
done
echo PLSW_DONE
