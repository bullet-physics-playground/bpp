#!/bin/bash
S=${S:-/path/to/scratch}   # set: G = this repo's EulersGallery, W = a work folder with creep.lua = bille-drop.lua + creep-lua.patch
G=$S/chk2/demo/WyomingWill/EulersGallery/exhibits/Bille; BPP=$S/upstream/release/bpp; W=$S/pla-work; mkdir -p $W/creep
cd $G
r() { tag=$1; n=$2; shift 2; env HOLD_S=0 BD_START=setdown BD_COUNT=1 BD_SPREAD=0 BD_REDROP=0 BD_SEED=1 CR_LOG=$W/creep/$tag.csv "$@" timeout 3000 xvfb-run -a $BPP -f $W/creep.lua -n $n 2>&1 | grep -v 'ALSA\|XDG\|Audio\|^t=' > $W/creep/$tag.txt; }
# resting on the stable face, 12 s simulated, logged every 0.05 s
for kf in bille:D p26:base p37:base ppla:base; do k=${kf%%:*}; f=${kf##*:}
  for L in def noloss; do
    X=""; [ $L = noloss ] && X="BD_ROLL=0 BD_SPIN=0"
    r home-$k-$L-3000 36000 CR_KIND=$k CR_FACE=$f CR_EVERY=150 $X &
    r home-$k-$L-1200 7200 CR_KIND=$k CR_FACE=$f CR_EVERY=30 BD_SPEED=0.1 $X &
    r home-$k-$L-4800 7200 CR_KIND=$k CR_FACE=$f CR_EVERY=30 BD_SPEED=0.1 BD_STEPS=4800 $X &
    wait
  done
done
# set down on a false face: logged every frame for the first simulated second
for kf in bille:A bille:C p37:S1 ppla:S1 p26:S1; do k=${kf%%:*}; f=${kf##*:}
  r false-$k-$f-3000 3000 CR_KIND=$k CR_FACE=$f CR_EVERY=1 &
  r false-$k-$f-1200 600 CR_KIND=$k CR_FACE=$f CR_EVERY=1 BD_SPEED=0.1 &
  r false-$k-$f-4800 600 CR_KIND=$k CR_FACE=$f CR_EVERY=1 BD_SPEED=0.1 BD_STEPS=4800 &
  wait
done
