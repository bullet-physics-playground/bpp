#!/bin/bash
# clear.sh "<name>" ... : CLEAR line for each (flat, room defaults, as raisefix2 measured)
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
for n in "$@"; do
  f=$(mktemp ./_cl_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; AMP=0; SEED=1\ndofile("/home/claude/work/clearprobe.lua")\n' "$n" > $f
  QT_QPA_PLATFORM=offscreen /home/claude/build/release/bpp -f $(basename $f) -n 610 2>&1 | grep "^CLEAR"
  rm -f $f
done
