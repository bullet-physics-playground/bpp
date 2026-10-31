#!/bin/bash
# ch07/kerr2005_reference.sh -- builds Kerr's 2005 robot simulator
# (ch07/kerr2005/) with its robots' seeds made settable
# (ch07/kerr2005_seed.diff, in a temporary copy; his files are not touched)
# and our ch07/KerrTrace.java, and writes the runs that checks/ch07.lua
# compares the Lua port (ch07/kerr2005.lua) with, to
# ch07/kerr2005_reference.txt: each run's state at its last step (every
# robot's position and bearing, the cells covered). Needs a JDK (javac,
# java); a minute. Run from the ArtificialPhysics folder:
#   bash ch07/kerr2005_reference.sh
set -eu
cd "$(dirname "$0")/.."
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
cp -r ch07/kerr2005 "$TMP/"
(cd "$TMP" && patch -p1 -s < "$OLDPWD/ch07/kerr2005_seed.diff")
K="$TMP/kerr2005"
cp ch07/KerrTrace.java "$K/"
(cd "$K" && javac -nowarn -d out -sourcepath . KerrTrace.java robot/KTRobot.java robot/AntRobot.java robot/Simple2.java 2>/dev/null)
cp -r "$K/data" "$K/out/"; mkdir -p "$K/out/log"
OUT=ch07/kerr2005_reference.txt
: > "$OUT"
# KerrTrace's arguments: CONTROLLER N COURSE SEED STEPS EVERY
while read -r ctl n course seed steps; do
  [ -z "$ctl" ] && continue
  echo "# $ctl $n $course $seed $steps" >> "$OUT"
  (cd "$K/out" && java -Dkerr.seed=1 -cp . KerrTrace "$ctl" "$n" "$course" "$seed" "$steps" "$steps" 2>/dev/null) >> "$OUT"
done <<'RUNS'
KTRobot 25 none 100 150000
KTRobot 5 course_20_1.txt 110 150000
KTRobot 25 course_20_0.txt 100 1000
AntRobot 25 course_20_0.txt 100 2000
Simple2 25 course_20_0.txt 100 500
RUNS
echo "wrote $OUT"
