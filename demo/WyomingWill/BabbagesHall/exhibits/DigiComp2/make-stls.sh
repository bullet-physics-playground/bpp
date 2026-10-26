#!/bin/sh
# make-stls.sh -- every printable part of the Digi-Comp II counter, into
# stl/, each turned to lie on the printer's bed (millimetres).
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
part rocker.stl  -D 'PART="print-rocker"'
part wheel.stl   -D 'PART="print-wheel"'
part knob.stl    -D 'PART="print-knob"'
part tile-0.stl  -D 'PART="print-tile0"'
part tile-1.stl  -D 'PART="print-tile1"'
part tile-2.stl  -D 'PART="print-tile2"'
part foot-back.stl  -D 'PART="print-foot-back"'
part foot-front.stl -D 'PART="print-foot-front"'
echo "Print: rocker x3, foot-back x2, foot-front x2; wheel, knob and tile-0, tile-1, tile-2 once each."
echo "Cut the backing sheet from 6 mm plywood to the board's size (README.md)."
