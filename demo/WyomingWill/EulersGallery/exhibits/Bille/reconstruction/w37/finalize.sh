#!/bin/sh
# final outputs for one design: NAME WEIGHT design.npy
#   export (STL, props, bpp mesh/data, summary) -> figures -> fit coupon -> PrusaSlicer check
#   -> publish the print files to ../../print/w37/
# as run:  sh finalize.sh w37-W W-cyl-3/8x.44 runs/opt_W-cyl-3_8x.44_H200_t0.8.npy   (refined by refine.sh)
#          sh finalize.sh w37-St St-dowel-10x20 runs/opt_St-dowel-10x20_H220_t0.8.npy
# Needs python3 + numpy, scipy, trimesh, manifold3d, matplotlib, and prusa-slicer on the PATH.
# The G-code (final/NAME.gcode, ~17 MB) is not kept in the repository.
set -e
cd "$(dirname "$0")"
N=$1; WT=$2; X=$3
mkdir -p final ../../print/w37
[ "$X" = "final/$N.npy" ] || cp $X final/$N.npy
python3 export.py final/$N.npy $WT $N final > final/$N-export.log
python3 figs.py final/$N.npy $WT $N final >> final/$N-export.log
python3 coupon.py $WT final/coupon-$(echo $N | sed 's/w37-//').stl >> final/$N-export.log
python3 slicecheck.py final/$N.npy $WT final/$N.stl final/$N.gcode > final/$N-slicecheck.log
for f in $N.stl $N-props.txt $N.gcode.check.json $N-cutaway3d.png $N-section.png $N-bottom.png coupon-$(echo $N | sed 's/w37-//').stl; do
  mv final/$f ../../print/w37/
done
echo done $N
