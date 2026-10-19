#!/bin/sh
# make-stls.sh -- every printable part of the Differential, into stl/,
# turned the way it should lie on the printer's bed. Needs openscad.
# Then (optional) parts/make-hulls.py remakes the simulation's gear data.
set -e
cd "$(dirname "$0")/parts"
OPENSCAD=${OPENSCAD:-openscad}
mkdir -p ../stl
part() { out=$1; shift; echo "  stl/$out"; "$OPENSCAD" -o "../stl/$out" "$@" differential.scad >/dev/null 2>&1; }
part side.stl          -D 'PART="print-side"'
part spider.stl        -D 'PART="print-spider"'
part carrier-half.stl  -D 'PART="print-carrierhalf"'
part drum.stl          -D 'PART="print-drum"'
part crank.stl         -D 'PART="print-crank"'
part frame.stl         -D 'PART="print-frame"'
echo "Print: side x2, spider x2, carrier-half x2, drum x2, crank x2, frame x1."
