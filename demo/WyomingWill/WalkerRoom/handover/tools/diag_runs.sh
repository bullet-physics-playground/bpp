#!/bin/bash
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
EARTH='GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}'
one() { f=$(mktemp ./_dg_XXXX.lua); printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; TERRAIN="waves"; AMP=4; BUMP=15; SEED=%s; %s; %s\ndofile("/home/claude/work/diagprobe.lua")\n' "$2" "$3" "$EARTH" "$4" > $f
  r=$(QT_QPA_PLATFORM=offscreen timeout 1200 /home/claude/build/release/bpp -f $(basename $f) -n 3700 2>&1 | grep -E "^(TRACK|TILT|CRANK|WELD|SELF|GROUND)|rror" | grep -v ALSA); rm -f $f
  { echo "== $1 seed $3"; echo "$r"; } >> /home/claude/work/dg/dg.txt; }
one "CS guides" "Chebyshev-Spears" 1 'UNBRACED={["Chebyshev-Spears"]=true}; GAIT={0,180,180,0}' &
one "CS diag" "Chebyshev-Spears diag" 1 'X=1' & wait
one "CS diag light" "Chebyshev-Spears diag" 1 'DIAG_LIGHT=0.05' &
one "CS diag low brace" "Chebyshev-Spears diag" 1 'DIAG_ARCH=false' & wait
one "CS guides" "Chebyshev-Spears" 2 'UNBRACED={["Chebyshev-Spears"]=true}; GAIT={0,180,180,0}' &
one "CS diag" "Chebyshev-Spears diag" 2 'X=1' & wait
one "HS4 guides" "Hoecken-Spears 4-bar" 1 'UNBRACED={["Hoecken-Spears 4-bar"]=true}; GAIT={0,180,180,0}' &
one "HS4 diag" "Hoecken-Spears 4-bar diag" 1 'X=1' & wait
echo DG DONE >> /home/claude/work/dg/dg.txt
