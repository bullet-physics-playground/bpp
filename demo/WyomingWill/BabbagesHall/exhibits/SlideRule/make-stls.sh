#!/bin/sh
# make-stls.sh -- every printable part of the slide rule, into stl/, turned
# the way it should lie on the printer's bed. Needs openscad. The scales are
# not printed in plastic: print scales.pdf on paper (make-scales.py).
set -e
cd "$(dirname "$0")/parts"
OPENSCAD=${OPENSCAD:-openscad}
mkdir -p ../stl
part() { out=$1; shift; echo "  stl/$out"; "$OPENSCAD" -o "../stl/$out" "$@" slide-rule.scad >/dev/null 2>&1; }
part stock-left.stl         -D 'PART="stock-left"'
part stock-right.stl        -D 'PART="stock-right"'
part slide-left.stl         -D 'PART="slide-left"'
part slide-right.stl        -D 'PART="slide-right"'
part stock-splice.stl       -D 'PART="stock-splice"'
part slide-splice.stl       -D 'PART="slide-splice"'
part cursor.stl             -D 'PART="cursor"'
part foot.stl               -D 'PART="foot"'
part slate-left.stl         -D 'PART="slate-left"'
part slate-right.stl        -D 'PART="slate-right"'
part slate-frame-left.stl   -D 'PART="slate-frame-left"'
part slate-frame-right.stl  -D 'PART="slate-frame-right"'
echo "Print: stock-left, stock-right, slide-left, slide-right, cursor x1 each; stock-splice x2;"
echo "  slide-splice x1; foot x2; the slate's four halves."
echo "Buy: 2 mm clear acrylic, 25.8 x 46.2 mm, for the cursor's window. Print scales.pdf at 100%."
