#!/bin/bash
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { # name tag extra
  f=$(mktemp ./_ct_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; TERRAIN="waves"; AMP=4; BUMP=15; SEED=1; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; TRACK_SECS=20; CONTACT_AT=1320; VIB_BASE="/home/claude/work/stallprobe.lua"; %s\ndofile("/home/claude/work/vibprobe_at.lua")\n' "$1" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1325 2>&1 | grep -E "^(CONTACTS|TRACK)|rror" | grep -v ALSA > /home/claude/work/outb5/$2.txt
  rm -f $f
}
G='UNBRACED=true; GAIT={0,180,180,0}'
one "Chebyshev" C_guides "$G" & one "Hoecken 4-bar" H4_guides "$G"; wait
one "Hoecken-Spears 4-bar duty 85" HSLS_guides "$G" & one "Chebyshev-Spears lift 51" L44_guides "$G"; wait
one "Chebyshev-Spears lift 62" L53_guides "$G" & one "Chebyshev-Spears lift 51 diag" L44_old "PENDANT_HOLD=true"; wait
one "Chebyshev-Spears lift 62 diag" L53_old "PENDANT_HOLD=true" & one "Chebyshev-Spears diag" CS_out "DIAG_OUTSIDE=true; PENDANT_HOLD=true"; wait
echo CT_DONE
