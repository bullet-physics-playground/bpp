#!/bin/bash
# ch07/kerr2005_port.sh -- reruns a sample of ch07/kerr2005_runs.txt (his
# Java, rerun from his drivers' seeds) on the Lua port, ch07/kerr2005.lua,
# into ch07/kerr2005_lua_runs.txt; checks/ch07.lua compares the two line
# for line. The sample: courses 0-2 of every KT and Default setting (his
# Default at 40% runs 150,000 steps on most courses, so only course 6 there)
# and two Ant runs. About two hours of CPU (Lua 5.1); run from the
# ArtificialPhysics folder:
#   bash ch07/kerr2005_port.sh [JOBS] [LUA]
set -eu
cd "$(dirname "$0")/.."
JOBS=${1:-2}; LUA=${2:-lua5.1}
OUT=ch07/kerr2005_lua_runs.txt
# CONTROLLER N PCT COURSE (kerr2005_run.lua's arguments; run 0)
{
  for c in KTRobot Simple2; do
    for p in 0 10 20 30; do for k in 0 1 2; do echo "$c 25 $p $k"; done; done
    for n in 5 10 15 20 30; do for k in 0 1 2; do echo "$c $n 20 $k"; done; done
  done
  for k in 0 1 2; do echo "KTRobot 25 40 $k"; done
  echo "Simple2 25 40 6"
  echo "AntRobot 25 0 0"; echo "AntRobot 25 20 0"
} | xargs -P "$JOBS" -L 1 "$LUA" ch07/kerr2005_run.lua | sort -k1,1 -k5,5n -k7,7n -k9,9n > "$OUT"
echo "wrote $OUT ($(wc -l < "$OUT") runs)"
