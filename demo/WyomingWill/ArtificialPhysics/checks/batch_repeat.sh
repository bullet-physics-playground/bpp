#!/bin/bash
# checks/batch_repeat.sh -- lib/batch.py gives the same CSV run serially
# and two at a time, for the particle demo and the drones.
#
# Run from the ArtificialPhysics folder (about a minute):
#   bash checks/batch_repeat.sh
# Prints PASS or FAIL and exits 0 or 1.
set -u
cd "$(dirname "$0")/.." || exit 1
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

# The same CSV without the wall_s column, which is timing.
strip() { python3 -c 'import csv,sys
r=list(csv.reader(open(sys.argv[1]))); i=r[0].index("wall_s")
for row in r: print(",".join(row[:i]+row[i+1:]))' "$1"; }

fail=0
compare() { # name, then the lib/batch.py arguments
  local name=$1; shift
  python3 lib/batch.py "$@" --jobs 1 --out "$T/$name-1.csv" > "$T/$name-1.txt" 2>&1 || { echo "FAIL batch_repeat: $name serial run failed"; tail -3 "$T/$name-1.txt"; fail=1; return; }
  python3 lib/batch.py "$@" --jobs 2 --out "$T/$name-2.csv" > "$T/$name-2.txt" 2>&1 || { echo "FAIL batch_repeat: $name parallel run failed"; tail -3 "$T/$name-2.txt"; fail=1; return; }
  local rows; rows=$(($(wc -l < "$T/$name-1.csv") - 1))
  if diff <(strip "$T/$name-1.csv") <(strip "$T/$name-2.csv") > /dev/null; then
    echo "ok   $name: $rows rows identical with --jobs 1 and --jobs 2"
  else
    echo "FAIL $name: CSVs differ between --jobs 1 and --jobs 2"; fail=1
  fi
}

compare uniform Uniform_Coverage.lua --seeds 1-4 --set meanFreePath=10,30 --frames 1500 --match ticks=
compare drones Formations-Lennard-Jones-Quadcopter.lua --probe probes/batch_drones.lua --env EVERY=300 --seeds 1-2 --frames 600

if [ $fail = 0 ]; then echo "PASS batch_repeat"; else echo "FAIL batch_repeat"; fi
exit $fail
