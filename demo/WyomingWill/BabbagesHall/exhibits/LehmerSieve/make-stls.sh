#!/bin/sh
# make-stls.sh -- every printable part of Lehmer's number sieve, into stl/,
# each turned to lie on the printer's bed (millimetres); and the base's
# outline, for cutting it from 12 mm plywood.
#
#   ./make-stls.sh                (needs openscad)
#
# The outlines come from parts/geometry.scad, which parts/make-geometry.py
# writes (python3 make-geometry.py, in parts/; it needs shapely): run that
# first only if you have changed a size in it.
set -e
cd "$(dirname "$0")/parts"
OPENSCAD=${OPENSCAD:-openscad}
mkdir -p ../stl
part() { out=$1; shift; echo "  stl/$out"; "$OPENSCAD" -o "../stl/$out" "$@" lehmer-sieve.scad >/dev/null 2>&1; }
for m in 9 8 7 5; do
  part "wheel-$m.stl"       -D "PART=\"print-wheel-$m\""
  part "crank-$m.stl"       -D "PART=\"print-crank-$m\""
  part "lock-$m.stl"        -D "PART=\"print-lock-$m\""
  part "detent-$m.stl"      -D "PART=\"print-detent-$m\""
  part "detent-post-$m.stl" -D "PART=\"print-detent-post-$m\""
done
part peg.stl          -D 'PART="print-peg"'
part cam.stl          -D 'PART="print-cam"'
part handle.stl       -D 'PART="print-handle"'
part probe-arm.stl    -D 'PART="print-probe-arm"'
part probe-pointer.stl -D 'PART="print-probe-pointer"'
part guide.stl        -D 'PART="print-guide"'
part bell.stl         -D 'PART="print-bell"'
part washer.stl       -D 'PART="print-washer"'
part washer-low.stl   -D 'PART="print-washer-low"'
part bearing.stl      -D 'PART="print-bearing"'
part shaft-washer.stl -D 'PART="print-shaft-washer"'
part foot.stl         -D 'PART="print-foot"'
part axle-nut.stl     -D 'PART="print-axle-nut"'
part cut-base.svg     -D 'PART="cut-base"'
echo "Print: one of each wheel, crank, lock, detent and detent post (9, 8, 7, 5); peg x20; washer x3,"
echo "washer-low x1, foot x4; cam, handle, probe-arm, probe-pointer, guide, bell, bearing, shaft-washer and axle-nut once each."
echo "Cut the base from 12 mm plywood: stl/cut-base.svg."
