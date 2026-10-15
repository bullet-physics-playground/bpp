#!/bin/bash
# Hall-identity check: run one exhibit in the Cabinet and on its own, and
# compare everything it prints.
#   cmp2.sh START FOLDER FILE FRAMES TAG
# START is part of the exhibit's name (as CABINET_START takes it), FOLDER and
# FILE its script, FRAMES how many frames to run, TAG names the output files
# (/tmp/h-TAG.txt from the hall, /tmp/s-TAG.txt on its own). Environment
# variables (seeds, rates) pass through to both runs. BPP overrides the bpp
# binary (default: release/bpp at the top of the repository). Headless runs
# need a display; on a machine without one, run it under xvfb-run.
# Example:  GV_SEED=3 bash cmp2.sh variety Gomboc gomboc-variety.lua 1200 gv
cd "$(dirname "$0")/../.." || exit 1            # demo/WyomingWill
BPP=${BPP:-$(cd ../.. && pwd)/release/bpp}
tag=$5
(cd Cabinet && CABINET_START="$1" timeout 3000 "$BPP" -f cabinet.lua -n $4 2>&1 | grep -v "ALSA\|XDG\|Audio" | sed -n '/exhibits on show/,$p' | tail -n +2) > /tmp/h-$tag.txt
(cd "$2" && timeout 3000 "$BPP" -f "$3" -n $4 2>&1 | grep -v "ALSA\|XDG\|Audio") > /tmp/s-$tag.txt
n=$(wc -l < /tmp/h-$tag.txt)
if [ "$n" -gt 0 ] && tail -n $n /tmp/s-$tag.txt | cmp -s - /tmp/h-$tag.txt; then echo "$1: IDENTICAL ($n run lines)"; else echo "$1: DIFFERS ($n lines)"; fi
