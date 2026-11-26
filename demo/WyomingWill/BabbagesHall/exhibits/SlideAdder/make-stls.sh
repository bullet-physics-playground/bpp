#!/bin/bash
# make-stls.sh -- every printable part of the slide adder, into stl/, each
# turned the way it should lie on the printer's bed. Needs openscad.
cd "$(dirname "$0")/parts" || exit 1
OPENSCAD=${OPENSCAD:-openscad}
mkdir -p ../stl
part() { out=$1; shift; echo "  stl/$out"; "$OPENSCAD" -o "../stl/$out" "$@" slide-adder.scad >/dev/null 2>&1; }
part band.stl        -D 'PART="band"'
part cover-lower.stl -D 'PART="cover-lower"'
part cover-upper.stl -D 'PART="cover-upper"'
part island.stl      -D 'PART="island"'
part back-lower.stl  -D 'PART="back-lower"'
part back-upper.stl  -D 'PART="back-upper"'
part bar.stl         -D 'PART="bar"'
part stylus.stl      -D 'PART="stylus"'
part foot-left.stl   -D 'PART="foot-left"'
part foot-right.stl  -D 'PART="foot-right"'
echo "Print: band x6, cover-lower, cover-upper, island x5, back-lower, back-upper, bar, stylus,"
echo "foot-left, foot-right. Glue the halves; print the labels (slate/labels-*.png,"
echo "cover-top.png, window-*.png, band-digits.png) at 10 px a mm and glue them on."
echo "Buy: nothing."
