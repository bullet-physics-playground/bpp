#!/bin/bash
# ch11/maxim1_sweep.sh -- maxim1 (Maxim's simulator, one robot, no window) on all
# 12 environments over the mean free path, with longer runs where they are needed
#
#   bash ch11/maxim1_sweep.sh [BASE] [JOBS] [CAP]       (from ArtificialPhysics/)
#   e.g. bash ch11/maxim1_sweep.sh 1e9 8 2e10
#        LIST=1 bash ch11/maxim1_sweep.sh 1e9           (print the runs and their lengths only)
#        STOP=1 bash ch11/maxim1_sweep.sh 1e9           (a run may stop early once KL has not
#                                                       improved at two checkpoints in a row)
#
# Builds maxim1 if needed, then runs every environment at cell size 20 for the
# turn lengths K below (f = K / 20, from 0.05 to 4), seed 1, JOBS at once
# (default 4), the longest runs first. Each run's length is
#     BASE x (cells / 9) x max(1, 13 / K), at most CAP (default 2 x 10^10),
# so the large environments and the short mean free paths (K below 13, the
# bound f = 0.65) run longer: 84cell at K = 1 gets 121 times BASE, before the
# cap. Checkpoints at 10^7 steps and doubling; by default every run goes to
# the last checkpoint within its length (so lengths fall to 10^7 x 2^n).
#
# Output: ch11/runs/ENV_K.txt (one line a checkpoint: steps KL dev; then the
# counts) and ch11/runs/summary.txt (env K f steps KL dev, the last
# checkpoint of each run). python3 ch11/maxim1_plot.py draws them.
#
# DEFINITIONS: K, f, KL, dev as in maxim1.c.
set -u
cd "$(dirname "$0")" || exit 1
BASE=${1:-1e9}
JOBS=${2:-4}
CAP=${3:-2e10}
KS="1 2 3 4 6 8 10 12 13 14 16 18 19 20 22 24 26 30 36 40 48 60 80"
ENVS="3x1 4cell.L 4cell.roll 7cell.dumbbell 3x3 15cell 22cell 35cell 6x6 10x10 spiral82 84cell"
[ -x maxim1 ] && [ maxim1 -nt maxim1.c ] || cc -O2 -o maxim1 maxim1.c -lm || exit 1
mkdir -p runs
# the run list: steps env K, longest first
for e in $ENVS; do
  cells=$(awk '/cell_number/ {print $2}' maxim/$e.environment/environment_20.ini)
  for k in $KS; do
    awk -v b="$BASE" -v c="$cells" -v k="$k" -v cap="$CAP" -v e="$e" \
      'BEGIN { s = b * c / 9 * (k < 13 ? 13 / k : 1); if (s > cap) s = cap; printf "%.0f %s %d\n", s, e, k }'
  done
done | sort -rn > runs/list.txt
if [ "${LIST:-0}" = 1 ]; then
  cat runs/list.txt
  awk '{ t += $1 } END { printf "%d runs, %.3g steps in all\n", NR, t }' runs/list.txt
  exit 0
fi
while read -r steps e k; do
  min=$steps; [ "${STOP:-0}" = 1 ] && min=1.6e8
  echo "./maxim1 maxim/$e.environment/environment_20.ini $k 1 $steps 1e7 $min > runs/${e}_$k.txt"
done < runs/list.txt | xargs -P "$JOBS" -I{} sh -c '{}'
{
  echo "# env K f steps KL dev"
  for e in $ENVS; do
    for k in $KS; do
      grep -v '^#' runs/${e}_$k.txt | tail -1 | awk -v e=$e -v k=$k '{ printf "%s %d %.2f %s %s %s\n", e, k, k / 20, $1, $2, $3 }'
    done
  done
} > runs/summary.txt
echo "wrote ch11/runs/summary.txt"
