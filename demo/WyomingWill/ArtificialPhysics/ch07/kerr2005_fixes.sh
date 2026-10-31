#!/bin/bash
# ch07/kerr2005_fixes.sh -- the Lua port's switches (ch07/kerr2005.lua's
# o.fix: seeds, messages, wallfit) on KT, 25 robots, into
# ch07/kerr2005_fix_runs.txt:
#   at 20% obstacles, each switch and the three together, the first run of
#     each of his 10 courses (his code's runs are the same seeds' lines in
#     ch07/kerr2005_runs.txt);
#   at 0% obstacles, each switch alone, 100 runs (seeds 100-199; his code
#     and the three together are in ch07/kerr2005_sweep_runs.txt), where the
#     full sweep found the book's version slower (FINDINGS F101).
# About 15 minutes with LuaJIT (80 with Lua 5.1); run from the
# ArtificialPhysics folder:
#   bash ch07/kerr2005_fixes.sh [JOBS] [LUA]
set -eu
cd "$(dirname "$0")/.."
JOBS=${1:-2}; LUA=${2:-$(command -v luajit || echo lua5.1)}
OUT=ch07/kerr2005_fix_runs.txt
# CONTROLLER N PCT COURSE RUN FIXES (kerr2005_run.lua's arguments)
{
  for f in seeds messages wallfit seeds,messages,wallfit; do
    for k in 0 1 2 3 4 5 6 7 8 9; do echo "KTRobot 25 20 $k 0 $f"; done
  done
  for f in seeds messages wallfit; do
    for k in 0 1 2 3 4 5 6 7 8 9; do for r in 0 1 2 3 4 5 6 7 8 9; do echo "KTRobot 25 0 $k $r $f"; done; done
  done
} | xargs -P "$JOBS" -L 1 "$LUA" ch07/kerr2005_run.lua | sort -k7,7n -k19,19 -k9,9n -k11,11n > "$OUT"
echo "wrote $OUT ($(wc -l < "$OUT") runs)"
