#!/bin/sh
# make-stls.sh -- every printable part of the Pascaline, into stl/, each
# turned to lie on the printer's bed; and the two plates' outlines, for
# cutting from 6 mm acrylic or plywood instead.
#
#   ./make-stls.sh            (needs openscad; bpp to refresh geometry.scad)
#   BPP=/path/to/bpp ./make-stls.sh
set -e
cd "$(dirname "$0")"
BPP=${BPP:-bpp}
OPENSCAD=${OPENSCAD:-openscad}
mkdir -p stl
if command -v "$BPP" >/dev/null 2>&1; then
  PA_EXPORT=1 PA_TOUR=0 HOLD_S=0 "$BPP" -f pascaline.lua -n 1 >/dev/null 2>&1 \
    && echo "geometry: parts/geometry.scad, from pascaline-geometry.lua" \
    || echo "geometry: bpp didn't run; using the parts/geometry.scad that is there"
else
  echo "geometry: no bpp; using the parts/geometry.scad that is there"
fi
cd parts
part() { out=$1; shift; echo "  stl/$out"; "$OPENSCAD" -o "../stl/$out" "$@" pascaline.scad >/dev/null 2>&1; }
part digit-cam.stl      -D 'PART="print-digitcam"'
part digit-last.stl     -D 'PART="print-digitlast"'
part dial.stl           -D 'PART="print-dial"'
part sautoir-0.stl      -D 'PART="print-lever0"'
part sautoir-1.stl      -D 'PART="print-lever1"'
part pawl-0.stl         -D 'PART="print-pawl0"'
part pawl-1.stl         -D 'PART="print-pawl1"'
part detent.stl         -D 'PART="print-detent"'
for p in front-left front-right back-left back-right base-left base-right end; do
  part "frame-$p.stl" -D "PART=\"print-$p\""
done
part pointer.stl         -D 'PART="print-pointer"'
part cut-front-plate.svg -D 'PART="cut-front"'
part cut-back-plate.svg  -D 'PART="cut-back"'
echo "Print: digit-cam x2, digit-last x1, dial x3, sautoir-0, sautoir-1, pawl-0, pawl-1, detent x3, frame-end x2, and the other frame pieces once each (pointer x3 only with cut plates)."
