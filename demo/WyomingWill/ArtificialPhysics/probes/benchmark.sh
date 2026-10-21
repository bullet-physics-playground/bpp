#!/bin/bash
# probes/benchmark.sh -- the cross-vehicle benchmark (BOOK.md §6, BENCHMARK.md)
#
# The same two tasks, with the same law settings (lib/laws.lua), on every
# vehicle behind lib/swarm.lua, measured by probes/settle_drones.lua:
#   task 1, formation: 2D triangle from the compact launch, no obstacles
#     or goal, 5600 frames (~180 s after AP engages);
#   task 2, goal through obstacles: the default scene (the obstacle field,
#     the goal switching on after 20 s and crossing it at 0.2 m/s), 30000
#     frames (~960 s).
# Vehicles: ideal (VEHICLE=lib.ideal on the quadcopter scene: perfect
# tracking, the original particles), Quadcopter, Ground, Boat; laws
# Lennard-Jones and Newtonian; seeds 1-3 (SEEDS= to change).
#
# Run from the ArtificialPhysics folder; writes OUT/task1-LAW-VEH.csv and
# OUT/task2-LAW-VEH.csv (default OUT=benchmark-out). About 90 min on two
# cores, most of it the drones' crossings:
#   bash probes/benchmark.sh [OUT] [VEHICLES] [LAWS] [TASKS]
#   bash probes/benchmark.sh out "Ground Boat" Newtonian 1
set -u
cd "$(dirname "$0")/.." || exit 1
OUT=${1:-benchmark-out}; VEHS=${2:-"ideal Quadcopter Ground Boat"}
LAWS=${3:-"Lennard-Jones Newtonian"}; TASKS=${4:-"1 2"}; SEEDS=${SEEDS:-1-3}
mkdir -p "$OUT"
for task in $TASKS; do
  for veh in $VEHS; do
    for law in $LAWS; do
      env=(); scene=$veh
      [ "$veh" = ideal ] && { env=(--env VEHICLE=lib.ideal); scene=Quadcopter; }
      if [ "$task" = 1 ]; then
        args=(--set obstacleField=false --set goalDelay=0 --frames 5600)
      else
        args=(--frames 30000 --env EVERY=3000)
      fi
      echo "task $task: $law on $veh"
      python3 lib/batch.py "Formations-$law-$scene.lua" --probe probes/settle_drones.lua \
        --env DIM=2 "${env[@]}" --seeds "$SEEDS" "${args[@]}" \
        --out "$OUT/task$task-$law-$veh.csv" > "$OUT/task$task-$law-$veh.log" 2>&1 \
        || echo "  failed: see $OUT/task$task-$law-$veh.log"
    done
  done
done
