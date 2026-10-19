#!/bin/sh
# key robustness rows for the other working options (200 trials per row)
cd "$(dirname "$0")"
R="nominal,unsorted (3%),planes 0.1,planes 0.2,planes 0.3,rings 0.2,rings 0.5,sliced + layer xy 0.2,combined (planes 0.2)"
one() { python3 robust.py $2 $1 200 0.8 "$R" > final/robust-alt-$(echo $1|tr / _).log 2>&1; }
qa() { one Pb-cyl-3/8x.6 runs/opt_Pb-cyl-3_8x.6_H220_t0.8.npy; one W-ball-12 runs/opt_W-ball-12_H220_t0.8.npy; }
qb() { one Wputty-cyl-10x12 runs/opt_Wputty-cyl-10x12_H220_t0.8.npy; B=$(python3 -c "
import json; M=json.load(open('runs/materials.json')); b=max([d for d in M if d['weight']=='Bi-cyl-10x12'], key=lambda d: d['margin']); print(f\"runs/opt_Bi-cyl-10x12_H{b['H']}_t0.8.npy\")"); one Bi-cyl-10x12 $B; }
qa & qb; wait
