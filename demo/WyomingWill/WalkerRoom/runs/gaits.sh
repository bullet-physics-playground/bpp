#!/bin/bash
# Is a trot the best gait (11 November, open)? The 11 walkers test-ranking.lua shows, in its directions (Klann and
# Spears 4-bar reversed), each against its own trot:
#   - the 8 with diag braces (each brace ties a diagonal pair's cranks): the offset between the pairs, PAIR_OFFSET
#     in walker-room.lua, at 180 (the trot), 150, 120 and 90 degrees (180 + x is the same walk as 180 - x, sides swapped)
#   - Jansen, Klann and Spears 4-bar (their own frames: each crank free): GAIT, trot, bound and the four 4-beat
#     walks (of the six orders of 90/180/270, two pairs are one walk with the sides swapped), and Spears 4-bar's own
# on seven grounds across the range, 5 seeds, the standard runs (run-table.sh, warm40fast), then a table: each
# option's mean speed on each ground and over all of them, against that walker's trot (the difference and its
# standard error, paired by ground and seed).
#
#   cd demo/WyomingWill/WalkerRoom
#   BPP=../../../release/bpp runs/gaits.sh
#
# Environment: BPP, JOBS, OUT (runs/out-gaits), GROUNDS (flat:0 waves:4 random:4 logs:5 logs:7 steps:4 steps:7),
# SEEDS (1 2 3 4 5), WALKERS (all 11; or names joined by commas). 51 options x 7 grounds x 5 seeds = 1,785 runs. Runs
# already done are kept; the table covers what is in OUT, so give a smaller set its own OUT. The high-lift walkers on
# waves (12 November: offsets below 180 looked better there on waves 4):
#   OUT=runs/out-gaits-waves WALKERS="Chebyshev-Spears lift 51 diag,Chebyshev-Spears lift 62 diag" \
#     GROUNDS="waves:2 waves:3 waves:4 waves:5 waves:6 waves:7 waves:8" BPP=... runs/gaits.sh
set -u
cd "$(dirname "$0")/.."
OUT=${OUT:-runs/out-gaits}
GROUNDS=${GROUNDS:-"flat:0 waves:4 random:4 logs:5 logs:7 steps:4 steps:7"}
SEEDS=${SEEDS:-"1 2 3 4 5"}
REV='REVERSE = { ["Klann"] = true, ["Spears 4-bar"] = true }'
B=$(mktemp)
trap 'rm -f "$B"' EXIT
WALKERS=${WALKERS:-}
one() {   # folder name, walker, settings
  [ -n "$WALKERS" ] && [[ ",$WALKERS," != *",$2,"* ]] && return
  echo "$2" > "$B"
  OUT="$OUT/$1" BUILDS="$B" SEEDS="$SEEDS" TERRAINS="$GROUNDS" EXTRA="$REV; $3" runs/run-table.sh > /dev/null
  echo "done $1"
}
for w in "Chebyshev-Spears lift 51 diag" "Chebyshev-Spears lift 62 diag" "Chebyshev-Spears diag" "Hoecken-Spears 4-bar diag" \
         "Hoecken-Spears slider diag" "Hoecken slider diag" "Hoecken 4-bar diag" "Chebyshev diag"; do
  for o in 180 150 120 90; do one "${w// /_}__offset_$o" "$w" "PAIR_OFFSET = $o"; done
done
GAITS="trot:0,180,180,0 bound:0,180,0,180 walk_0-90-180-270:0,90,180,270 walk_0-270-180-90:0,270,180,90 walk_0-90-270-180:0,90,270,180 walk_0-180-90-270:0,180,90,270"
for w in "Jansen" "Klann" "Spears 4-bar"; do
  gaits="$GAITS"; [ "$w" = "Spears 4-bar" ] && gaits="$gaits own_0-225-180-225:0,225,180,225"
  for g in $gaits; do one "${w// /_}__gait_${g%%:*}" "$w" "GAIT = { ${g#*:} }"; done
done
echo
python3 - "$OUT" <<'PY'
import sys, os, re, glob, math, statistics as st, collections
out = sys.argv[1]
runs = collections.defaultdict(dict)   # (walker, option) -> (ground, seed) -> speed
for d in sorted(glob.glob(os.path.join(out, "*__*"))):
    w, opt = os.path.basename(d).split("__", 1)
    for f in glob.glob(os.path.join(d, "warm40fast", "*.txt")):
        m = re.search(r"^RUN .*?\|speed ([-\d.]+)", open(f).read(), re.M)
        if not m: continue
        ter, seed = os.path.basename(f)[:-4].rsplit("_", 2)[1:]
        runs[(w.replace("_", " "), opt)][(ter, seed)] = float(m.group(1))
grounds = sorted({g for r in runs.values() for g, _ in r}, key=lambda g: (["flat", "waves", "random", "logs", "steps"].index(re.match(r"[a-z]+", g).group(0)), g))
print("| Walker | Option | " + " | ".join(grounds) + " | All | Against its trot |")
print("| --- | --- | " + " | ".join("---" for _ in grounds) + " | --- | --- |")
for w in sorted({w for w, _ in runs}):
    base = runs.get((w, "offset_180")) or runs.get((w, "gait_trot")) or {}
    for (ww, opt), r in sorted(runs.items(), key=lambda kv: kv[0][1]):
        if ww != w: continue
        cells = [f"{st.mean([v for (g, _), v in r.items() if g == gr]):.2f}" if any(g == gr for g, _ in r) else "-" for gr in grounds]
        keys = [k for k in r if k in base]
        d = [r[k] - base[k] for k in keys]
        vs = "—" if r is base else (f"{st.mean(d):+.2f} ± {st.stdev(d) / math.sqrt(len(d)):.2f}" if len(d) > 1 else "-")
        print(f"| {w} | {opt.replace('_', ' ')} | " + " | ".join(cells) + f" | {st.mean(r.values()):.2f} | {vs} |")
PY
