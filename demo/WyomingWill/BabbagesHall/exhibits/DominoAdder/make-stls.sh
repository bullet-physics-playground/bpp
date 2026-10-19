#!/bin/sh
# make-stls.sh -- every printable part of the Domino Half Adder, into stl/
#
#   ./make-stls.sh            (needs openscad; bpp to refresh the layout)
#   BPP=/path/to/bpp ./make-stls.sh
#
# 1. parts/layout.scad, every pocket of the template, is written by the
#    exhibit itself (so the print is the simulation's layout). Without bpp,
#    the layout.scad that is there is used.
# 2. Then OpenSCAD makes the parts. Template tiles are made only where there
#    are pockets.
set -e
cd "$(dirname "$0")"
BPP=${BPP:-bpp}
OPENSCAD=${OPENSCAD:-openscad}
mkdir -p stl

if command -v "$BPP" >/dev/null 2>&1; then
  DA_EXPORT=parts/layout.scad DA_TOUR=0 HOLD_S=0 "$BPP" -f domino-adder.lua -n 1 >/dev/null 2>&1 \
    && echo "layout: parts/layout.scad, from the exhibit" \
    || echo "layout: bpp didn't run; using the parts/layout.scad that is there"
else
  echo "layout: no bpp; using the parts/layout.scad that is there"
fi

cd parts
part() { out=$1; shift; echo "  stl/$out"; "$OPENSCAD" -o "../stl/$out" "$@" domino-adder.scad >/dev/null 2>&1; }

part domino.stl -D 'PART="domino"'
part tell.stl   -D 'PART="tell"'
part inlay0.stl -D 'PART="inlay0"'
part inlay1.stl -D 'PART="inlay1"'
part pin.stl    -D 'PART="pin"'
for t in A B GO SUM CARRY; do part "sign-$t.stl" -D 'PART="sign"' -D "TEXT=\"$t\""; done
part template.svg -D 'PART="template2d"'

# the tiles with pockets in them (a pocket reaches 25 mm round its centre)
TILES=$(grep -E '^\s*\[[0-9]' layout.scad | sed 's/[][]//g' | awk -F, '{
  for (dx = -25; dx <= 25; dx += 50) for (dy = -25; dy <= 25; dy += 50) {
    tx = int(($1 + dx) / 200); ty = int(($2 + dy) / 200); if (tx >= 0 && ty >= 0) print tx "-" ty
  } }' | sort -u)
n=0
for t in $TILES; do
  tx=${t%-*}; ty=${t#*-}
  part "tile-$tx-$ty.stl" -D 'PART="tile"' -D "TX=$tx" -D "TY=$ty"
  n=$((n + 1))
done
echo "$n template tiles."
