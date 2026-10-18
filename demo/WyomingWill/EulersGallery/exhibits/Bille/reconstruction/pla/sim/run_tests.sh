#!/bin/sh
# Dynamics tests of the PLA-only polyhedron in bpp (pla-drop.lua = Bille Drop
# with only the body list changed). Needs meshes/ppla-data.lua and meshes/ppla.obj.
#   drops:    6 bodies, random orientations, re-dropped 1 s after rest
#   setdown:  6 bodies at a time, each on a given wrong face (PP_FACE..PP_FACE+5)
# Real print size (PP_SCALE=1, BD_SPREAD=0) at speed 0.1 (step 1/1200 s),
# and the gallery's look: 40 cm tall (PP_SCALE=40/size) at the default speed 0.02.
BPP=${BPP:-/tmp/claude-0/-home-claude/27345db2-594b-591b-b841-2c308bf66463/scratchpad/upstream/release/bpp}
cd "$(dirname "$0")"
mkdir -p logs
for seed in 1 2 3 4; do
  BD_SEED=$seed BD_COUNT=6 BD_SPREAD=0 BD_SPEED=0.1 BD_REDROP=1 HOLD_S=0 \
    timeout 3000 xvfb-run -a $BPP -f pla-drop.lua -n 9000 > logs/drop-real-s$seed.txt 2>&1
done
NF=$(grep -c 'name = "S' meshes/ppla-data.lua)
f=1
while [ $f -le $NF ]; do
  BD_SEED=$f PP_FACE=$f BD_START=setdown BD_COUNT=6 BD_SPREAD=0 BD_SPEED=0.1 BD_REDROP=0 HOLD_S=0 \
    timeout 1500 xvfb-run -a $BPP -f pla-drop.lua -n 1500 > logs/setdown-real-f$f.txt 2>&1
  f=$((f + 6))
done
S=$(awk '/size =/{print $3; exit}' meshes/ppla-data.lua | tr -d ,)
SC=$(python3 -c "print(40/$S)")
for seed in 1 2; do
  PP_SCALE=$SC BD_SEED=$seed BD_COUNT=6 BD_SPREAD=1 BD_SPEED=0.1 BD_REDROP=1 HOLD_S=0 \
    timeout 3000 xvfb-run -a $BPP -f pla-drop.lua -n 9000 > logs/drop-gallery-s$seed.txt 2>&1
done
# the gallery's default speed 0.02 (step 1/3000 s)
PP_SCALE=$SC BD_SEED=3 BD_COUNT=6 BD_SPREAD=1 BD_REDROP=1 HOLD_S=0 \
  timeout 3000 xvfb-run -a $BPP -f pla-drop.lua -n 9000 > logs/drop-gallery-slow-s3.txt 2>&1
f=1
while [ $f -le $NF ]; do
  PP_SCALE=$SC BD_SEED=$f PP_FACE=$f BD_START=setdown BD_COUNT=6 BD_SPREAD=1 BD_SPEED=0.1 BD_REDROP=0 HOLD_S=0 \
    timeout 3000 xvfb-run -a $BPP -f pla-drop.lua -n 2400 > logs/setdown-gallery-f$f.txt 2>&1
  f=$((f + 6))
done
