#!/bin/sh
# one optimiser job: WEIGHT H TAG (seeded from the 220 mm tungsten-cylinder optimum)
cd "$(dirname "$0")"
python3 opt.py $1 $2 0.8 1 210 0.8 none runs/opt_W-cyl-3_8x.44_H220_t0.8.npy > runs/scan_$(echo $1|tr / _)_$2$3.log 2>&1
