#!/bin/bash
# keys.sh -- run a script in bpp's window on a virtual screen, press keys,
# and take a screenshot every GAP seconds after (camera flights, an
# exhibit's keys, the mouse).
#
#   SHOT_ENV="HALL_START=domino DA_TOUR=0" KEYS="Tab Tab" KEYDELAY=7 \
#     tools/keys.sh demo/WyomingWill/BabbagesHall/hall.lua /tmp/fly
#
# KEYS     xdotool key names, pressed in turn (Tab, shift+Tab, space, t, 4 ...)
# KEYDELAY seconds between them (0)       GAP     between screenshots (0.45)
# LOAD_S   seconds to wait for loading (25; Euler's Gallery needs ~70)
# PREKEY   a key first, e.g. Escape to close a dialog (Euler's solar system
#          asks once about downloading its music)
# HOVER    "x y": rest the mouse there instead of pressing keys first (the
#          Pascaline's holes: then KEYS="space")
# Writes <out-prefix>-0.png ... -6.png.
F=$1; OUT=$2
cd "$(dirname "$0")/../../../.." || exit 1
BPP=${BPP:-build/release/bpp}
Xvfb :99 -screen 0 1920x1080x24 >/dev/null 2>&1 & XP=$!
sleep 1; export DISPLAY=:99
env $SHOT_ENV LIBGL_ALWAYS_SOFTWARE=1 "$BPP" "$F" > "${OUT}-bpp.log" 2>&1 & BP=$!
sleep ${LOAD_S:-25}
WID=$(xdotool search --onlyvisible --name "^bpp" | head -1)
[ -n "$WID" ] && { xdotool windowmove --sync "$WID" 0 0; xdotool windowsize --sync "$WID" 1920 1080; sleep 2; }
[ -n "$PREKEY" ] && { xdotool key $PREKEY; sleep 3; }
xdotool mousemove 1600 300 click 1; sleep 0.5          # (the 3D view gets the keyboard; off any exhibit)
if [ -n "$HOVER" ]; then
  set -- $HOVER; xdotool mousemove $1 $2; sleep 0.3; xdotool mousemove $(( $1 + 1 )) $2; sleep 2
fi
for k in ${KEYS:-Tab}; do xdotool key $k; sleep ${KEYDELAY:-0}; done
for t in 0 1 2 3 4 5 6; do import -window root "${OUT}-$t.png"; sleep ${GAP:-0.45}; done
kill $BP; sleep 0.5; kill -9 $BP 2>/dev/null; kill $XP
