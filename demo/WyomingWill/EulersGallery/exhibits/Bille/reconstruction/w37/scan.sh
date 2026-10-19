#!/bin/sh
# scan of stock weights at 220 mm (one optimiser seed each; 2 queues)
cd "$(dirname "$0")"
qa() { for w in W-cyl-3/8x.44 W-ball-12 Pb-ball-.570 St-ball-11/16; do python3 opt.py $w 220 0.8 1 210 0.8 none > runs/scan_$(echo $w|tr / _)_220.log 2>&1; done; }
qb() { for w in St-ball-5/8 St-ball-3/4 Pb-ball-.535 W-ball-10; do python3 opt.py $w 220 0.8 1 210 0.8 none > runs/scan_$(echo $w|tr / _)_220.log 2>&1; done; }
qa & qb; wait
