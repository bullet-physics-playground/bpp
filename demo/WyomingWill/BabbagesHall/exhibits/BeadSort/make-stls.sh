#!/bin/sh
# make-stls.sh -- every printable part of the bead sort, into stl/, turned the
# way it should lie on the printer's bed. Needs openscad.
set -e
cd "$(dirname "$0")/parts"
OPENSCAD=${OPENSCAD:-openscad}
mkdir -p ../stl
part() { out=$1; shift; echo "  stl/$out"; "$OPENSCAD" -o "../stl/$out" "$@" bead-sort.scad >/dev/null 2>&1; }
part bead.stl              -D 'PART="bead"'
part bar-bottom-left.stl   -D 'PART="bar-bottom-left"'
part bar-bottom-right.stl  -D 'PART="bar-bottom-right"'
part bar-top-left.stl      -D 'PART="bar-top-left"'
part bar-top-right.stl     -D 'PART="bar-top-right"'
part bar-side.stl          -D 'PART="bar-side"'
part foot-left.stl         -D 'PART="foot-left"'
part foot-right.stl        -D 'PART="foot-right"'
part rest.stl              -D 'PART="rest"'
part knob.stl              -D 'PART="knob"'
echo "Print: bead x72 (eight colours, nine of each), bar-bottom-left, bar-bottom-right,"
echo "bar-top-left, bar-top-right, bar-side x2, foot-left, foot-right, rest, knob."
echo "Buy: nine 3 mm steel rods, 116 mm long; a 3 mm steel pin, 264 mm long (the hinge)."
