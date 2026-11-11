#!/bin/bash
# How the room's walkers steer by their wheels (handover/STEERING.md, stage C): a room run headless for MINUTES
# simulated minutes on each ground in TERRAINS, then runs/roomlog.lua's lines as tables: the room's turns, rescues
# (turns finished rigidly) and walkers stood up again, and each walker's share of the time turning and backing.
#
#   cd demo/WyomingWill/WalkerRoom
#   BPP=../../../release/bpp runs/room-steer.sh                      # the 11 (walker-room.lua on its own), 4 minutes
#   BPP=... ROOM=room-four.lua ROOM_STEER=arcs runs/room-steer.sh
#   BPP=... ROOM_STEER=curve ROOM_YIELD=true runs/room-steer.sh
#
# Environment: BPP, ROOM (walker-room.lua: the 11 on their own; or room-four.lua), ROOM_STEER (curve; backup, arcs,
# rigid), ROOM_YIELD (false; true: right of way to a walker on the right),
# MINUTES (4), TERRAINS (waves:0 waves:2), THREADS (4), ARENA (the room's own: 15 m). The 11 at 4 threads on an 8-core
# machine: about 0.5 x real time, so about 8 minutes a ground.
set -u
cd "$(dirname "$0")/.."
BPP=${BPP:-bpp}; ROOM=${ROOM:-walker-room.lua}; ROOM_STEER=${ROOM_STEER:-curve}; ROOM_YIELD=${ROOM_YIELD:-false}; MINUTES=${MINUTES:-4}
TERRAINS=${TERRAINS:-"waves:0 waves:2"}; THREADS=${THREADS:-4}; ARENA=${ARENA:-}
command -v "$BPP" > /dev/null || { echo "bpp not found: set BPP to the bpp program"; exit 1; }
secs=$((MINUTES * 60))
for t in $TERRAINS; do
  ter=${t%%:*}; amp=${t##*:}
  f=$(mktemp ./_st_XXXXXX.lua)
  printf 'ROOM_STEER = "%s"; ROOM_YIELD = %s; THREADS = %s; TERRAIN = "%s"; AMP = %s; %sLOAD = "%s"; END_S = %s\ndofile("runs/roomlog.lua")\n' \
    "$ROOM_STEER" "$ROOM_YIELD" "$THREADS" "$ter" "$amp" "${ARENA:+ARENA = $ARENA; }" "$ROOM" "$secs" > "$f"
  out=$(QT_QPA_PLATFORM=offscreen timeout $((secs * 30)) "$BPP" -f "$(basename "$f")" -n $((secs * 60 + 10)) 2>&1 | grep -aE '^(ROOM|WALKER) ')
  rm -f "$f"
  echo "### $ROOM, $ROOM_STEER$([ "$ROOM_YIELD" = true ] && echo ", yield"), $ter $amp, $MINUTES minutes"
  echo
  echo "$out" | grep '^ROOM' | sed 's/^ROOM //; s/|/\n/g' | sed 's/^/- /'
  echo
  echo "| Walker | Turning | Backing | Distance | Turns |"
  echo "| --- | --- | --- | --- | --- |"
  echo "$out" | grep '^WALKER' | sed 's/^WALKER //' | awk -F'|' '{ sub(/turning /, "", $2); sub(/backing /, "", $3); sub(/gone /, "", $4); sub(/turns /, "", $5); printf "| %s | %s | %s | %s | %s |\n", $1, $2, $3, $4, $5 }'
  echo
done
