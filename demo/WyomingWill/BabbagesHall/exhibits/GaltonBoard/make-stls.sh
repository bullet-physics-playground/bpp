#!/bin/sh
# make-stls.sh -- every printable part of the Galton board, into stl/, each
# turned to lie on the printer's bed (millimetres); and the front sheet's
# outline, for cutting it from 3 mm clear acrylic.
#
#   ./make-stls.sh                (needs openscad)
#
# The sizes come from parts/geometry.scad, which galton.lua writes from
# galton-geometry.lua whenever a size there changes (run the exhibit once,
# in bpp, after changing one).
set -e
cd "$(dirname "$0")/parts"
OPENSCAD=${OPENSCAD:-openscad}
mkdir -p ../stl
part() { out=$1; shift; echo "  stl/$out"; "$OPENSCAD" -o "../stl/$out" "$@" galton.scad >/dev/null 2>&1; }
part tile-top.stl     -D 'PART="print-tile-top"'
part tile-middle.stl  -D 'PART="print-tile-middle"'
part tile-bottom.stl  -D 'PART="print-tile-bottom"'
part splice.stl       -D 'PART="print-splice"'
part wheel.stl        -D 'PART="print-wheel"'
part crank.stl        -D 'PART="print-crank"'
part slide.stl        -D 'PART="print-slide"'
part drawer.stl       -D 'PART="print-drawer"'
part stand.stl        -D 'PART="print-stand"'
part cut-front.svg    -D 'PART="cut-front"'
echo "Print: the three tiles, splice x2, and one each of the wheel, crank, slide, drawer and stand."
echo "Cut the front sheet from 3 mm clear acrylic: stl/cut-front.svg (drill its screw holes through the rim's)."
