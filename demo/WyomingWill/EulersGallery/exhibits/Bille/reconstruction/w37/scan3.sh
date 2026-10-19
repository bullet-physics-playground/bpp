#!/bin/sh
# third scan: cylinders of steel / lead / putty; steel ball re-check from the tungsten optimum
cd "$(dirname "$0")"
run() { python3 opt.py $1 $2 0.8 ${3:-1} 210 0.8 none $4 > runs/scan_$(echo $1|tr / _)_$2${5}.log 2>&1; }
X=runs/opt_W-cyl-3_8x.44_H220_t0.8.npy
qa() { run St-dowel-10x20 220 1 $X; run Pb-cyl-3/8x.6 220 1 $X; run St-ball-5/8 220 3 $X _recheck; }
qb() { run St-dowel-10x16 200 1 $X; run Wputty-cyl-10x12 220 1 $X; }
qa & qb; wait
