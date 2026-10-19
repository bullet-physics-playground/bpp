#!/bin/sh
# size scan for the tungsten cylinders, seeded from the 220 mm optimum
cd "$(dirname "$0")"
X=runs/opt_W-cyl-3_8x.44_H220_t0.8.npy
run() { python3 opt.py W-cyl-3/8x.44 $1 0.8 1 210 0.8 none $X > runs/scan_W-cyl_$1.log 2>&1; }
qa() { run 200; run 160; }
qb() { run 180; run 190; }
qa & qb; wait
