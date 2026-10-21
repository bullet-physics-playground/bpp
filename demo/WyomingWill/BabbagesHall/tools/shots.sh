#!/bin/bash
# shots.sh -- run a script in bpp's window on a virtual screen and take
# screenshots at the given seconds after it starts (to look at what changed).
#
#   tools/shots.sh <script.lua> <out-prefix> <t1> [t2 ...]
#   SHOT_ENV="HALL_START=pascaline PA_TOUR=0" tools/shots.sh demo/WyomingWill/BabbagesHall/hall.lua /tmp/x 20
#
# The script path is from the repository's top folder. Writes
# <out-prefix>-<t>.png, the whole 1920x1080 screen (the 3D view is about
# x 0-1658, y 62-962). Needs Xvfb, xdotool and ImageMagick. Drawing is in
# software here, so a few frames a second; the simulation runs slower than
# real time accordingly (it steps one frame per drawn frame).
#
# To look from a camera of your own, make a small script that runs the
# exhibit and then sets the camera, and pass that:
#   dofile("demo/WyomingWill/BabbagesHall/hall.lua")
#   v.cam:setUpVector(btVector3(0, 1, 0), true)
#   v.cam.pos = btVector3(-170, 160, 1100); v.cam.look = btVector3(-390, 95, 1100)
F=$1; OUT=$2; shift 2
cd "$(dirname "$0")/../../../.." || exit 1
BPP=${BPP:-build/release/bpp}
Xvfb :99 -screen 0 1920x1080x24 >/dev/null 2>&1 & XP=$!
sleep 1
export DISPLAY=:99
env $SHOT_ENV LIBGL_ALWAYS_SOFTWARE=1 "$BPP" "$F" > "${OUT}-bpp.log" 2>&1 & BP=$!
sleep ${LOAD_S:-8}
WID=$(xdotool search --onlyvisible --name "^bpp" 2>/dev/null | head -1)
[ -n "$WID" ] && { xdotool windowmove --sync "$WID" 0 0; xdotool windowsize --sync "$WID" 1920 1080; sleep 2; }
prev=0
for t in "$@"; do
  sleep "$(echo "$t - $prev" | bc)"; prev=$t
  import -window root "${OUT}-${t}.png"
done
kill $BP; sleep 0.5; kill -9 $BP 2>/dev/null; kill $XP
