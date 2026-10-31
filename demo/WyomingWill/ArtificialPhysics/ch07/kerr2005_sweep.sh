#!/bin/bash
# ch07/kerr2005_sweep.sh -- the book's corridor sweep (entries 7.5-7.6,
# Figs. 7.11-7.13) in full on the Lua port of Kerr's 2005 simulator
# (ch07/kerr2005.lua), with his protocol: Exp. 1, 25 robots at 0-40%
# obstacles; Exp. 2, 5-30 robots at 20% (his Thesis_2.java; the book says
# 30%, FINDINGS F97); 10 courses x 10 runs per setting, his seeds. Twice:
# "his" code (switches off) and the "book" version (KT: seeds, messages,
# wallfit; Ant: seeds; Default has no switch, so it runs once). 5,000 runs,
# about 16 CPU-hours with LuaJIT (7 times faster than Lua 5.1, the same
# results to the bit; checks/ch07.lua passes on it).
#
# Resumable: runs already in the output are skipped, so stop it (Ctrl-C)
# and start it again at will. Each run appends his log line (with
# " Fix ..." for the book version) to ch07/kerr2005_sweep_runs.txt;
# ch07/kerr2005_figs.lua summarises it against his logs. Run from the
# ArtificialPhysics folder:
#   bash ch07/kerr2005_sweep.sh [JOBS] [LUA]      (defaults: nproc, luajit)
set -eu
cd "$(dirname "$0")/.."
JOBS=${1:-$(nproc)}; LUA=${2:-luajit}
command -v "$LUA" >/dev/null || { echo "no $LUA: install LuaJIT (apt install luajit) or name another Lua"; exit 1; }
OUT=ch07/kerr2005_sweep_runs.txt
touch "$OUT"
# CONTROLLER N PCT COURSE RUN [FIXES] (kerr2005_run.lua's arguments); the
# slow settings first (Default at 40% runs 150,000 steps on most courses)
list() {
  for mode in his book; do
    for c in Simple2 AntRobot KTRobot; do
      fix=""
      if [ "$mode" = book ]; then
        case $c in KTRobot) fix=seeds,messages,wallfit ;; AntRobot) fix=seeds ;; *) continue ;; esac
      fi
      for p in 40 30 20 10 0; do
        for k in 0 1 2 3 4 5 6 7 8 9; do for r in 0 1 2 3 4 5 6 7 8 9; do echo "$c 25 $p $k $r${fix:+ $fix}"; done; done
      done
      for n in 5 10 15 20 30; do
        for k in 0 1 2 3 4 5 6 7 8 9; do for r in 0 1 2 3 4 5 6 7 8 9; do echo "$c $n 20 $k $r${fix:+ $fix}"; done; done
      done
    done
  done
}
# drop the runs already done (key: controller N pct course run fixes)
todo=$(list | awk -v out="$OUT" 'BEGIN {
           while ((getline l < out) > 0) { n = split(l, f, " ")
             if (n >= 17) done[f[1]" "f[5]" "f[7]" "f[9]" "f[11]" "(f[18] == "Fix" ? f[19] : "")] = 1 } }
         !(($1" "$2" "$3" "$4" "$5" "$6) in done)')
total=$(list | wc -l); left=$(printf '%s' "$todo" | grep -c . || true)
echo "kerr2005 sweep: $((total - left)) of $total runs done, $left to go, $JOBS at a time ($LUA)"
[ "$left" -eq 0 ] || printf '%s\n' "$todo" | xargs -P "$JOBS" -L 1 sh -c '"$0" ch07/kerr2005_run.lua "$@" >> ch07/kerr2005_sweep_runs.txt' "$LUA"
echo "kerr2005 sweep: $(awk 'NF >= 17 { print $1, $5, $7, $9, $11, $19 }' "$OUT" | sort -u | wc -l) of $total runs in $OUT"
