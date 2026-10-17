#!/bin/bash
S=${PROBES:?set PROBES to this probes folder}
PROBE=${PROBE:-cube_drone.lua}   # or tri_drone.lua (then grep TRI)
cd ~/bpp/demo/WyomingWill/ArtificialPhysics
export SDL_AUDIODRIVER=dummy XDG_RUNTIME_DIR=/tmp/rt QT_QPA_PLATFORM=offscreen
mkdir -p $S/sweep
job() { law=$1; ord=$2; seed=$3; shift 3
  env LAUNCHORDER=$ord SEED=$seed "$@" timeout 1700 ~/bpp/release/bpp -f Formations-$law-Quadcopter.lua -l "dofile('$S/$PROBE')" -n 5600 2>&1 | grep "CUBE\|SHAPE\|TRI" > $S/sweep/${TAG}_${law}_o${ord}_s${seed}.log; }
for law in Lennard-Jones Newtonian; do for ord in 0 1 2 3 4; do
  job $law $ord 1 "$@" & job $law $ord 2 "$@" & wait; job $law $ord 3 "$@"
done; done
echo DONE > $S/sweep/${TAG}.done
