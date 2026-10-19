#!/bin/sh
# fairness re-runs of the balls from the cylinder optimum; more dowel sizes
cd "$(dirname "$0")"
X=runs/opt_W-cyl-3_8x.44_H220_t0.8.npy
run() { python3 opt.py $1 $2 0.8 1 210 0.8 none $X > runs/scan_$(echo $1|tr / _)_$2$3.log 2>&1; }
qa() { run W-ball-12 220 _cylstart; run St-ball-1/2 200 _cylstart; run St-dowel-8x24 200; }
qb() { run Pb-ball-.535 220 _cylstart; run St-dowel-10x24 220; }
qa & qb; wait
