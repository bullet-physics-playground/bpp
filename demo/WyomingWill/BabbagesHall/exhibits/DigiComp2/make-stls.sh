#!/bin/sh
# make-stls.sh -- every printable part of the Digi-Comp II (as built so far,
# step 2b), into stl/, each turned to lie on the printer's bed (millimetres).
#
#   ./make-stls.sh            (needs openscad; bpp to refresh geometry.scad)
#   BPP=/path/to/bpp ./make-stls.sh
#
# parts/geometry.scad is written by the exhibit from digicomp2-geometry.lua
# (DC_EXPORT=1); without bpp, the one that is there is used.
set -e
cd "$(dirname "$0")"
BPP=${BPP:-bpp}
OPENSCAD=${OPENSCAD:-openscad}
mkdir -p stl
if command -v "$BPP" >/dev/null 2>&1; then
  DC_EXPORT=1 DC_TOUR=0 HOLD_S=0 "$BPP" -f digicomp2.lua -n 1 >/dev/null 2>&1 \
    && echo "geometry: parts/geometry.scad, from digicomp2-geometry.lua" \
    || echo "geometry: bpp didn't run; using the parts/geometry.scad that is there"
else
  echo "geometry: no bpp; using the parts/geometry.scad that is there"
fi
cd parts
part() { out=$1; shift; echo "  stl/$out"; "$OPENSCAD" -o "../stl/$out" "$@" digicomp2.scad >/dev/null 2>&1; }
part rocker.stl     -D 'PART="print-rocker"'
part foot.stl       -D 'PART="print-foot"'
part flap.stl       -D 'PART="print-flap"'
part wheel.stl      -D 'PART="print-wheel"'
part knob.stl       -D 'PART="print-knob"'
for i in 0 1; do
  for j in 0 1 2 3 4 5 6; do
    part "upper-$i-$j.stl" -D "PART=\"print-upper-$i-$j\""
    part "lower-$i-$j.stl" -D "PART=\"print-lower-$i-$j\""
  done
done
part foot-back-1.stl -D 'PART="print-foot-back-1"'
part foot-back-2.stl -D 'PART="print-foot-back-2"'
part foot-front.stl -D 'PART="print-foot-front"'
echo "Print: rocker x13, foot x13, flap x7, foot-back-1 x2, foot-back-2 x2, foot-front x2; wheel, knob and every"
echo "upper-i-j and lower-i-j tile once. Cut the lower board from 6 mm plywood (README.md)."
