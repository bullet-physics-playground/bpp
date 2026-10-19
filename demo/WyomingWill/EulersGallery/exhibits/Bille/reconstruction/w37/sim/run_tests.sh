#!/bin/sh
# Dynamics tests of the weighted 37-corner FDM build in bpp (w37-drop.lua = the
# gallery's Bille Drop harness with only the body list changed; via pla-drop.lua).
#   run_tests.sh [W|St]   (default W = the recommended tungsten build)
# Copies ../final/w37-N-data.lua and ../final/w37-N.obj to meshes/ppla-data.lua and
# meshes/ppla.obj (the names the harness expects), runs, and writes the logs to
# ../sim-N/logs/ (where prep_guide.py and simtally.py read them).
#   drops:   6 bodies, random orientations, re-dropped 1 s after rest, real size
#   setdown: 6 bodies at a time, each set down on a given wrong face
# BPP defaults to release/bpp at the top of the repository.
N=${1:-W}
cd "$(dirname "$0")"
BPP=${BPP:-$(cd ../../../../../../../.. && pwd)/release/bpp}
mkdir -p meshes ../sim-$N/logs
cp ../final/w37-$N-data.lua meshes/ppla-data.lua
cp ../final/w37-$N.obj meshes/ppla.obj
L=../sim-$N/logs
for seed in 1 2 3; do
  BD_SEED=$seed BD_COUNT=6 BD_SPREAD=0 BD_SPEED=0.1 BD_REDROP=1 HOLD_S=0 \
    timeout 6000 xvfb-run -a $BPP -f w37-drop.lua -n 30000 > $L/drop-real-s$seed.txt 2>&1
done
NF=$(grep -c 'name = "S' meshes/ppla-data.lua)
f=1
while [ $f -le $NF ]; do
  BD_SEED=$f PP_FACE=$f BD_START=setdown BD_COUNT=6 BD_SPREAD=0 BD_SPEED=0.1 BD_REDROP=0 HOLD_S=0 \
    timeout 3000 xvfb-run -a $BPP -f w37-drop.lua -n 15000 > $L/setdown-real-f$f.txt 2>&1
  f=$((f + 6))
done
