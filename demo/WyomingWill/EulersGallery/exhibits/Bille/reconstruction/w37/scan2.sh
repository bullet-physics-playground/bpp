#!/bin/sh
# second scan: smaller steel / lead at smaller sizes, lead and tungsten at 220/240
cd "$(dirname "$0")"
run() { python3 opt.py $1 $2 0.8 1 210 0.8 none > runs/scan_$(echo $1|tr / _)_$2.log 2>&1; }
qa() { run Pb-ball-.535 220; run St-ball-1/2 170; run Pb-ball-.440 190; run W-cyl-3/8x.44 240; }
qb() { run Pb-ball-.570 220; run St-ball-9/16 190; run W-ball-10 200; run St-ball-7/16 150; }
qa & qb; wait
