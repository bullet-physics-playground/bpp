#!/bin/bash
# The room's speed with threads (November 2026): handover/tools/roomtime.lua (5 simulated s, wall clock) for one
# walker, four (room-four.lua's first four) and the 11 walker-room.lua shows on its own (Klann and Spears 4-bar
# reversed; GROUPS_LIST="21": every build, as on 6 November), the body marks on and off, at each number of threads.
# Threads 0 is the room as before; 1 and more, the threaded world (bpp built with qmake CONFIG+=bundled_bullet, see
# scripts/bullet-threads.sh; with the system Bullet every row runs on one thread). One run at a time, so the machine
# is otherwise idle: about 15 minutes on a Ryzen 7 3700X (not measured).
#
#   cd demo/WyomingWill/WalkerRoom
#   BPP=~/build-mt/release/bpp runs/room-speed.sh                 # threads 0 1 2 4 8
#   BPP=... THREADS_LIST="0 4" GROUPS_LIST="4" runs/room-speed.sh
set -u
cd "$(dirname "$0")/.."
BPP=${BPP:-bpp}; THREADS_LIST=${THREADS_LIST:-"0 1 2 4 8"}; GROUPS_LIST=${GROUPS_LIST:-"1 4 11"}
command -v "$BPP" > /dev/null || { echo "bpp not found: set BPP to the bpp program"; exit 1; }
only() { case "$1" in
  1)  echo 'ONLY = { ["Chebyshev-Spears lift 51 diag"] = true }';;
  4)  echo 'ONLY = { ["Klann"] = true, ["Jansen"] = true, ["Chebyshev-Spears lift 51 diag"] = true, ["Chebyshev-Spears lift 62 diag"] = true }';;
  11) echo 'ONLY = {}; for _, n in ipairs({ "Chebyshev-Spears lift 51 diag", "Chebyshev-Spears lift 62 diag", "Chebyshev-Spears diag", "Hoecken-Spears 4-bar diag", "Hoecken-Spears slider diag", "Klann", "Jansen", "Hoecken slider diag", "Hoecken 4-bar diag", "Chebyshev diag", "Spears 4-bar" }) do ONLY[n] = true end; REVERSE = { ["Klann"] = true, ["Spears 4-bar"] = true }';;
  21) echo 'ONLY = nil';; esac; }
bracing() { case "$1" in 1) echo "diag";; *) echo "mixed";; esac; }
direction() { case "$1" in 11) echo "as the ranking";; *) echo "forward";; esac; }
printf '| Walkers | Bracing | Timing | Direction | Marks | Threads | Speed |\n| --- | --- | --- | --- | --- | --- | --- |\n'
for g in $GROUPS_LIST; do for m in on off; do for n in $THREADS_LIST; do
  f=$(mktemp ./_rs_XXXXXX.lua)
  printf '%s\n' 'v:setSolver("si-warm"); v:setSolverInfo("residual", 0.01)' \
    'SOLVER_ITERATIONS = 40; FIXED = 1 / 1920; MOTOR_STRENGTH = 2; GRAVITY = 981; YAW_DAMP = 1' \
    'ANKLE_SPRING = { stiffness = 42000, damping = 4200 }; LINK_WIDTH = 1.0; GAIT = { 0, 180, 180, 0 }; DIAG_OUTSIDE = true' \
    'dofile("lib/trotting-walkers.lua"); dofile("lib/spears-lift-walkers.lua")' "$(only "$g")" \
    'PENDANT_HOLD = setmetatable({}, { __index = function(_, k) return k:find("diag$") ~= nil end })' \
    "MARKS = $([ $m = on ] && echo true || echo false); THREADS = $n" 'dofile("handover/tools/roomtime.lua")' > "$f"
  r=$(QT_QPA_PLATFORM=offscreen timeout 3600 "$BPP" -f "$(basename "$f")" -n 370 2>&1 | grep -ao '([0-9.]* x real time)' | tr -d '()')
  rm -f "$f"
  printf '| %s | %s | trot | %s | %s | %s | %s |\n' "$g" "$(bracing "$g")" "$(direction "$g")" "$m" "$n" "${r:-failed}"
done; done; done
