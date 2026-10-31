#!/bin/bash
# ch07/kerr2005_fixes.sh -- the Lua port's switches (ch07/kerr2005.lua's
# o.fix: seeds, messages, wallfit, and the three together) on KT, 25
# robots at 20% obstacles, the first run of each of his 10 courses, into
# ch07/kerr2005_fix_runs.txt (his code's runs are the same seeds' lines in
# ch07/kerr2005_runs.txt). About 80 minutes of CPU (Lua 5.1); run from the
# ArtificialPhysics folder:
#   bash ch07/kerr2005_fixes.sh [JOBS] [LUA]
set -eu
cd "$(dirname "$0")/.."
JOBS=${1:-2}; LUA=${2:-lua5.1}
OUT=ch07/kerr2005_fix_runs.txt
# CONTROLLER N PCT COURSE RUN FIXES (kerr2005_run.lua's arguments)
for f in seeds messages wallfit seeds,messages,wallfit; do
  for k in 0 1 2 3 4 5 6 7 8 9; do echo "KTRobot 25 20 $k 0 $f"; done
done | xargs -P "$JOBS" -L 1 "$LUA" ch07/kerr2005_run.lua | sort -k22,22 -k9,9n > "$OUT"
echo "wrote $OUT ($(wc -l < "$OUT") runs)"
