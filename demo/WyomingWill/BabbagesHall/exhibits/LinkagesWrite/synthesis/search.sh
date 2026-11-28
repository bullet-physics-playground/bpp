#!/bin/bash
# search.sh -- every search the alphabet came from, again (hours on 2
# cores; use THREADS=16 on more). Writes runs4/, cur/, b3/ here; then
#   MAXSPAN=4 python3 final2.py && cd .. && python3 make-alphabet.py
# The runs as made are in runs.tar.xz (tar xJf runs.tar.xz instead).
cd "$(dirname "$0")"
T=${THREADS:-2}
gcc -O3 -march=native -fopenmp -o linkage_native linkage_native.c -lm || exit 1
mkdir -p runs4 cur b3
python3 - <<'PY'
import math, numpy as np, letters as LT, multi as MU
from letters import arc
def save(fn, pts):
    with open(fn, "w") as f:
        f.write("%d\n" % len(pts))
        for i, (x, y) in enumerate(pts): f.write("%r %r %r\n" % (2 * math.pi * i / len(pts), float(x), float(y)))
for c in LT.LETTERS: save("t-%s-slow.txt" % c, LT.timed(LT.walk(LT.LETTERS[c]), 100))
for c, pens in MU.MULTI.items():
    pre = "n" if c in "EFKZ" else "m"
    for i, st in enumerate(pens): save("cur/%s-%s%d.txt" % (pre, c, i), LT.timed(LT.walk([st]), 100))
CAN = {"line": [[(0, 0), (1, 0)]], "semi": [arc(0, 0, 1, 1, 180, 360, 24)],
       "Stop": [arc(.32, .75, .28, .25, 20, 270, 24)], "Sbot": [arc(.32, .25, .28, .25, 90, -160, 24)]}
for k, st in CAN.items(): save("cur/c-%s.txt" % k, LT.timed(LT.walk(st), 100))
PY
run() { local dir=$1 f=$2 out=$3 seed=$4 d=$5; shift 5
  [ -s $out.out ] && grep -q "^RESULT" $out.out && return
  env "$@" ./linkage_native $f --max_extra_dyads $d --tol 0.0001 --mode shape --popsize 40 --maxiter 1500 --seed $seed --threads $T --min_margin_frac 0.6 > $out.out 2> $out.err; }
for c in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z; do for s in 1 2; do run runs4 t-$c-slow.txt runs4/$c-slow-$s $s 5 X=1; done; done
for f in cur/m-*.txt cur/n-*.txt; do b=${f%.txt}; for s in 1 2; do run cur $f $b-$s $s 4 X=1; done; done
for k in line semi Stop Sbot; do for s in 1 2; do run b3 cur/c-$k.txt b3/c-$k-$s $s 4 LK_BOUND=3; done; done
for c in A B C; do for s in 1 2; do run b3 t-$c-slow.txt b3/$c-slow-$s $s 4 LK_BOUND=3; done; done
