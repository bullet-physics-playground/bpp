#!/bin/sh
# refine a design: 3 more optimiser seeds from its own best (perturbed restarts)
cd "$(dirname "$0")"
python3 opt.py $1 $2 0.8 3 210 0.8 none $3 > runs/refine_$(echo $1|tr / _)_$2.log 2>&1
