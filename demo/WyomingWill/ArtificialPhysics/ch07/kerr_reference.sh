#!/bin/bash
# ch07/kerr_reference.sh -- builds Kerr's 2004 Java (ch07/kerr/) with the seed
# made settable (ch07/kerr_seed.diff, in a temporary copy; his files are not
# touched) and our ch07/KerrReference.java, and writes the runs that
# checks/ch07.lua compares ch07/kerr.lua with, to ch07/kerr_reference.txt.
# Needs a JDK (javac, java). Run from the ArtificialPhysics folder:
#   bash ch07/kerr_reference.sh
set -eu
cd "$(dirname "$0")/.."
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
cp -r ch07/kerr "$TMP/"
(cd "$TMP" && patch -p1 -s < "$OLDPWD/ch07/kerr_seed.diff")
OUT=ch07/kerr_reference.txt
: > "$OUT"
# variant, Kerr's directory, seed, then KerrReference's arguments:
# NPART NCELL_X NCELL_Y LENGTH T VWALL_L VWALL_R DIR0 DIR1 CLOSED STEPS EVERY
while read -r variant dir seed args; do
  [ -z "$variant" ] && continue
  d="$TMP/kerr/$dir"
  if [ ! -d "$d/out" ]; then
    cp ch07/KerrReference.java "$d/experiments/"
    (cd "$d" && javac -nowarn -d out shared/*.java ktphysics/*.java experiments/KerrReference.java 2>/dev/null)
  fi
  echo "# $variant $seed $args" >> "$OUT"
  (cd "$d" && java -Dkerr.seed="$seed" -cp out experiments.KerrReference $args 2>/dev/null) | grep -v '^System width' >> "$OUT"
done <<'RUNS'
couette StandardCouette 12345 500 7 70 10 273 0 1.2 -1 1 false 200 7
couette StandardCouette 777 500 7 70 10 273 0 0.65 -1 1 false 1000 7
uniform UniformDistribution 777 2000 20 20 1 273 0 0 1 1 false 400 13
speed AverageSpeed 12345 500 10 10 1 25 0 0 1 1 true 400 7
RUNS
echo "wrote $OUT"
