#!/bin/bash
# ch07/kerr2005.sh -- builds Kerr's 2005 robot simulator (ch07/kerr2005/)
# with its robots' seeds made settable (ch07/kerr2005_seed.diff, in a
# temporary copy; his files are not touched) and our ch07/KerrSweep.java,
# and runs his corridor sweep (book entries 7.5-7.6, Figs. 7.11-7.13) on a
# sample of his own settings: 25 robots over his obstacle courses (0-40%),
# and 5-30 robots at 20% (his Thesis_2.java), one run per course from his
# seeds. Writes ch07/kerr2005_runs.txt, his log lines; checks/ch07.lua
# compares them with his thesis logs (ch07/kerr2005/log/thesis/).
# Needs a JDK (javac, java); about an hour on two cores. Run from the
# ArtificialPhysics folder:
#   bash ch07/kerr2005.sh [JOBS]
set -eu
cd "$(dirname "$0")/.."
JOBS=${1:-2}
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
cp -r ch07/kerr2005 "$TMP/"
(cd "$TMP" && patch -p1 -s < "$OLDPWD/ch07/kerr2005_seed.diff")
K="$TMP/kerr2005"
cp ch07/KerrSweep.java "$K/"
# only what the three controllers use: util/ImageSaver.java needs the JPEG
# codec of old JDKs and robot/Simple.java repeats a class of Simple2.java
(cd "$K" && javac -nowarn -d out -sourcepath . KerrSweep.java robot/KTRobot.java robot/AntRobot.java robot/Simple2.java 2>/dev/null)
cp -r "$K/data" "$K/out/"; mkdir -p "$K/out/log"
OUT=ch07/kerr2005_runs.txt
# CONTROLLER N PCT START END RUNS (KerrSweep's arguments)
{
  for c in KTRobot Simple2; do
    for p in 0 10 20 30 40; do for k in 0 1 2 3 4 5 6 7 8 9; do echo "$c 25 $p $k $((k+1)) 1"; done; done
    for n in 5 10 15 20 30; do for k in 0 1 2 3 4 5 6 7 8 9; do echo "$c $n 20 $k $((k+1)) 1"; done; done
  done
  for p in 0 10 20 30 40; do for k in 0 1 2 3 4; do echo "AntRobot 25 $p $k $((k+1)) 1"; done; done
} | (cd "$K/out" && xargs -P "$JOBS" -L 1 sh -c 'java -Dkerr.seed=1 -cp . KerrSweep "$@" 2>/dev/null' _) | grep ' Speed ' | sort -k1,1 -k5,5n -k7,7n -k9,9n > "$OUT"
echo "wrote $OUT ($(wc -l < "$OUT") runs)"
