#!/bin/sh
# make-stls.sh -- every printable part of Napier's bones, into stl/, turned
# the way it should lie on the printer's bed. Needs openscad. The faces are
# not printed in plastic: print napier-faces.pdf and genaille-faces.pdf on
# paper (make-faces.py).
set -e
cd "$(dirname "$0")/parts"
OPENSCAD=${OPENSCAD:-openscad}
mkdir -p ../stl
part() { out=$1; shift; echo "  stl/$out"; "$OPENSCAD" -o "../stl/$out" "$@" napiers-bones.scad >/dev/null 2>&1; }
part rod.stl                -D 'PART="rod"'
part board.stl              -D 'PART="board"'
part foot.stl               -D 'PART="foot"'
part tray.stl               -D 'PART="tray"'
part slate-left.stl         -D 'PART="slate-left"'
part slate-right.stl        -D 'PART="slate-right"'
part slate-stand-left.stl   -D 'PART="slate-stand-left"'
part slate-stand-right.stl  -D 'PART="slate-stand-right"'
part slate-frame-left.stl   -D 'PART="slate-frame-left"'
part slate-frame-right.stl  -D 'PART="slate-frame-right"'
echo "Print: rod x11 (ten and the index), board, tray, foot x2, the slate's six halves"
echo "  (its board, stand and frame)."
echo "Print napier-faces.pdf and genaille-faces.pdf at 100%; wrap one strip round each rod."
