#!/bin/bash
# ch04/coverage1_sweep.sh -- coverage1 (one agent, the Android rule) for MFP 120 down to 1
#
#   bash coverage1_sweep.sh [MAXSTEPS] [JOBS] [FIRST]   (run where coverage1.c is)
#   e.g. bash coverage1_sweep.sh                     (cap 10^10 steps, 5 at a time)
#        bash coverage1_sweep.sh 1.6e9 2 1.25e7      (checkpoints through 2e8, Fig. 4.19's budget)
#
# Builds coverage1 if needed, then runs MFP 120, 119, ..., 1, seed 1, JOBS at
# once (default 5), each until its deviation stops improving or MAXSTEPS
# (coverage1.c's stopping rule). One file a run, mfp/mfpNNN.txt, and a
# summary, mfp/summary.txt: MFP, f = MFP / 26.667, the steps run and the
# last and best deviation (Eq. 4.1), one line a run, MFP descending.
set -u
cd "$(dirname "$0")" || exit 1
MAX=${1:-1e10}
JOBS=${2:-5}
FIRST=${3:-1e7}
[ -x coverage1 ] && [ coverage1 -nt coverage1.c ] || cc -O2 -o coverage1 coverage1.c -lm || exit 1
mkdir -p mfp
seq 120 -1 1 | xargs -P "$JOBS" -I{} sh -c './coverage1 {} 1 '"$MAX $FIRST"' > mfp/mfp$(printf %03d {}).txt'
{
  echo "# MFP f steps last_deviation best_deviation"
  for m in $(seq 120 -1 1); do
    awk -v m=$m '!/^#/ { t = $1; d = $2; if (b == "" || d < b) b = d }
      END { printf "%d %.4f %d %.6f %.6f\n", m, m / (80 / 3), t, d, b }' mfp/mfp$(printf %03d $m).txt
  done
} > mfp/summary.txt
cat mfp/summary.txt
