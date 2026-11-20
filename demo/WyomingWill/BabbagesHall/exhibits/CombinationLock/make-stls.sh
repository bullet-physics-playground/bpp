#!/bin/sh
# make-stls.sh -- every printable part of the combination lock, into stl/,
# turned the way it should lie on the printer's bed. Needs openscad and lua.
# The wheels' gates are cut for the combination: COMBO=12-34-56 ./make-stls.sh
# (31-72-46 if not given). Steel pins, the fence, the spindle, the spring and
# the wave washer are bought: README.md.
set -e
cd "$(dirname "$0")"
OPENSCAD=${OPENSCAD:-openscad}
LUA=${LUA:-$(command -v lua5.2 || command -v lua5.1 || command -v lua)}
COMBO=${COMBO:-31-72-46}
set -- $(echo "$COMBO" | tr -c '0-9\n' ' ')
GATES=$("$LUA" lock.lua gates "$1" "$2" "$3")
set -- $GATES
mkdir -p stl
cd parts
part() { out=$1; shift; echo "  stl/$out"; "$OPENSCAD" -o "../stl/$out" "$@" combination-lock.scad >/dev/null 2>&1; }
part wheel-1.stl            -D 'PART="wheel"' -D "GATE=$1" -D 'WHEEL_N=1'
part wheel-2.stl            -D 'PART="wheel"' -D "GATE=$2" -D 'WHEEL_N=2'
part wheel-3.stl            -D 'PART="wheel"' -D "GATE=$3" -D 'WHEEL_N=3'
part cam.stl                -D 'PART="cam"'
part dial.stl               -D 'PART="dial"'
part dial-marks.stl         -D 'PART="dial-marks"'
part washer.stl             -D 'PART="washer"'
part back-plate.stl         -D 'PART="back-plate"'
part base.stl               -D 'PART="base"'
part standard.stl           -D 'PART="standard"'
part guide.stl              -D 'PART="guide"'
part keeper.stl             -D 'PART="keeper"'
part bolt.stl               -D 'PART="bolt"'
part lever.stl              -D 'PART="lever"'
part slate-left.stl         -D 'PART="slate-left"'
part slate-right.stl        -D 'PART="slate-right"'
part slate-frame-left.stl   -D 'PART="slate-frame-left"'
part slate-frame-right.stl  -D 'PART="slate-frame-right"'
part slate-stand.stl        -D 'PART="slate-stand"'
echo "The wheels' gates are cut for $COMBO."
echo "Print: the three wheels, cam, dial (and dial-marks in a second colour), back-plate, base,"
echo "  standard, keeper, bolt, lever x1 each; washer x3; guide x2; the slate's four halves; slate-stand x2."
echo "Buy: 3 x 14 mm steel dowels x3, 3 x 10 mm x1; 4 mm steel rod 48 mm (the fence); 4 x 18 mm pin;"
echo "  8 mm steel rod 40 mm (the spindle, a flat filed on one end); a small torsion spring; a thin wave"
echo "  washer for a 12 mm post; an e-clip or collar."
