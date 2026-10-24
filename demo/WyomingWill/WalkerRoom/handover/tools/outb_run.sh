#!/bin/bash
# $1 label, $2 walker, $3 extra lua; Earth standard, trot; vibprobe over stallprobe
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
f=$(mktemp ./_ob_XXXX.lua)
printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; UNBRACED={["Chebyshev-Spears"]=true, ["Hoecken-Spears 4-bar"]=true}; GAIT={0,180,180,0}; TERRAIN="waves"; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; VIB_BASE="/home/claude/work/stallprobe.lua"; %s\ndofile("/home/claude/work/vibprobe.lua")\n' "$2" "$3" > $f
QT_QPA_PLATFORM=offscreen timeout 1500 /home/claude/build/release/bpp -f $(basename $f) -n 3700 2>&1 | grep -E "^(TRACK|VIB |CONTACTS|STALL|WELD)|rror" | grep -v ALSA > /home/claude/work/outb/$1.txt
rm -f $f
