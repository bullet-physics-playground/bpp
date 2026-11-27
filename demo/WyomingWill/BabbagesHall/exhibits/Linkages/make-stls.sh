#!/bin/bash
# make-stls.sh -- every printable part of the linkages, into stl/, each
# turned the way it should lie on the printer's bed. Needs openscad.
cd "$(dirname "$0")/parts" || exit 1
OPENSCAD=${OPENSCAD:-openscad}
mkdir -p ../stl
part() { out=$1; shift; echo "  stl/$out"; "$OPENSCAD" -o "../stl/$out" "$@" linkages.scad >/dev/null 2>&1; }
for i in 0 1 2 3; do part board-inverter-$i.stl -D 'PART="board"' -D 'WAY="inverter"' -D "N=$i"; done
for i in 0 1 2 3; do part board-multiply-$i.stl -D 'PART="board"' -D 'WAY="multiply"' -D "N=$i"; done
part arm.stl         -D 'PART="bar"' -D 'LEN=150.52'
part side.stl        -D 'PART="bar"' -D 'LEN=112.5'
part crank.stl       -D 'PART="bar"' -D 'LEN=35'
part lever-0.stl     -D 'PART="lever-half"' -D 'N=0'
part lever-1.stl     -D 'PART="lever-half"' -D 'N=1'
part carriage.stl    -D 'PART="carriage"'
part block.stl       -D 'PART="block"'
part bridge-0.stl    -D 'PART="bridge-half"' -D 'N=0'
part bridge-1.stl    -D 'PART="bridge-half"' -D 'N=1'
part knob.stl        -D 'PART="knob"'
echo "Print: for the inverter and the straight line, board-inverter-0 to 3, arm x2, side x4,"
echo "crank, carriage, knob x2; for the multiplier, board-multiply-0 to 3, lever-0 and lever-1,"
echo "carriage x2, block x2, bridge-0 and bridge-1, knob x2. Glue the board's quarters and the"
echo "halves; print the scales (slate/scale-*.png, rule.png) at 10 px a mm and glue them on."
echo "Buy: 3 mm steel pins, 30 mm long, about 12."
