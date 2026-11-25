#!/bin/sh
# make-stls.sh -- every printable part of the bead sort and the spaghetti sort,
# into stl/, each turned the way it should lie on the printer's bed. Needs
# openscad.
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
# the spaghetti sort (the second way)
sp() { out=$1; shift; echo "  stl/$out"; "$OPENSCAD" -o "../stl/$out" "$@" spaghetti-sort.scad >/dev/null 2>&1; }
for n in 0 1 2 3 4 5 6 7 8 9; do sp rod-$n.stl -D 'PART="rod"' -D "N=$n"; done
sp base-left.stl   -D 'PART="base-left"'
sp base-right.stl  -D 'PART="base-right"'
sp comb-left.stl   -D 'PART="comb-left"'
sp comb-right.stl  -D 'PART="comb-right"'
sp post.stl        -D 'PART="post"'
sp palm-left.stl   -D 'PART="palm-left"'
sp palm-right.stl  -D 'PART="palm-right"'
sp palm-knob.stl   -D 'PART="knob"'
echo "Print: bead x72 (eight colours, nine of each), bar-bottom-left, bar-bottom-right,"
echo "bar-top-left, bar-top-right, bar-side x2, foot-left, foot-right, rest, knob."
echo "The spaghetti sort: rod-0 to rod-9 (two of each is a good set; or cut 8 mm dowel"
echo "to 30 + 12 n mm), base-left, base-right, comb-left, comb-right, post, palm-left,"
echo "palm-right, palm-knob."
echo "Buy: nine 3 mm steel rods, 116 mm long; a 3 mm steel pin, 264 mm long (the hinge)."
