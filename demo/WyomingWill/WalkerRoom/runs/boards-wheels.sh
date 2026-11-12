#!/bin/bash
# The ranking boards without wheels and with (11 November): the 11 walkers test-ranking.lua shows, in its directions
# (Klann and Spears 4-bar reversed), on the boards' 33 grounds, 5 seeds, the standard runs (run-table.sh,
# warm40fast) -- once as built, once with SHOES = {} (a wheel each side, both free, as the viewers have them) --
# then both boards files, and how they compare (runs/compare-boards.py). Both from the same code on the same
# machine: the old lib/boards.lua was put together from runs on different days and machines, and today's code
# without wheels doesn't reproduce it exactly.
#
#   cd demo/WyomingWill/WalkerRoom
#   BPP=../../../release/bpp runs/boards-wheels.sh
#
# Environment: BPP, JOBS (run-table.sh's: one run per CPU), OUT (default runs/out-boards), GROUNDS and SEEDS (to
# try it small: GROUNDS="logs:7 waves:4" SEEDS=1). 3,630 runs: about
# 7 hours on 2 CPUs; on 8 cores well under an hour. Runs already done are kept, so it can be stopped and started.
# Then, to use the wheel boards in the viewer: cp "$OUT/wheels.lua" lib/boards.lua
set -u
cd "$(dirname "$0")/.."
OUT=${OUT:-runs/out-boards}
if [ -z "${GROUNDS:-}" ]; then
  GROUNDS="flat:0"
  for t in waves random logs steps; do for a in 1 2 3 4 5 6 7 8; do GROUNDS="$GROUNDS $t:$a"; done; done
fi
SEEDS=${SEEDS:-"1 2 3 4 5"}
B=$(mktemp)
trap 'rm -f "$B"' EXIT
printf '%s\n' "Chebyshev-Spears lift 51 diag" "Chebyshev-Spears lift 62 diag" "Klann" "Chebyshev-Spears diag" \
  "Hoecken-Spears 4-bar diag" "Hoecken-Spears slider diag" "Jansen" "Spears 4-bar" "Hoecken slider diag" \
  "Hoecken 4-bar diag" "Chebyshev diag" > "$B"
REV='REVERSE = { ["Klann"] = true, ["Spears 4-bar"] = true }'
for v in plain wheels; do
  extra="$REV"; [ "$v" = wheels ] && extra="SHOES = {}; $REV"
  OUT="$OUT/$v" BUILDS="$B" SEEDS="$SEEDS" TERRAINS="$GROUNDS" EXTRA="$extra" runs/run-table.sh > /dev/null
  python3 runs/boards.py "$OUT/$v/warm40fast" > "$OUT/$v.lua" || exit 1
  echo "$v: $(ls "$OUT/$v/warm40fast"/*.txt | wc -l) runs, boards in $OUT/$v.lua"
done
echo
python3 runs/compare-boards.py "$OUT/plain.lua" "$OUT/wheels.lua"
