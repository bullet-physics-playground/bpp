#!/bin/sh
# make-figures.sh -- the manual's figures (manual/*.png), drawn from
# digicomp2-geometry.lua. Needs lua (5.1 or 5.2), python3 and matplotlib.
set -e
cd "$(dirname "$0")"
LUA=${LUA:-$(command -v lua5.2 || command -v lua5.1 || command -v lua)}
T=$(mktemp)
"$LUA" dump-geometry.lua ../digicomp2-geometry.lua "$T"
python3 figures.py "$T" .
rm -f "$T"
