#!/bin/sh
# make-stls.sh -- every printable part of the suanpan, into stl/, turned the
# way it should lie on the printer's bed. Needs openscad.
set -e
cd "$(dirname "$0")/parts"
OPENSCAD=${OPENSCAD:-openscad}
mkdir -p ../stl
part() { out=$1; shift; echo "  stl/$out"; "$OPENSCAD" -o "../stl/$out" "$@" suanpan.scad >/dev/null 2>&1; }
part bead.stl         -D 'PART="bead"'
part bar-near.stl     -D 'PART="near"'
part bar-far.stl      -D 'PART="far"'
part bar-side.stl     -D 'PART="side"'
part beam.stl         -D 'PART="beam"'
part slate-left.stl         -D 'PART="slate-left"'
part slate-right.stl        -D 'PART="slate-right"'
part slate-frame-left.stl   -D 'PART="slate-frame-left"'
part slate-frame-right.stl  -D 'PART="slate-frame-right"'
echo "Print: bead x49, bar-near x1, bar-far x1, bar-side x2, beam x1, and the slate's four halves."
echo "Buy: seven 3 mm steel rods, 136 mm long."
