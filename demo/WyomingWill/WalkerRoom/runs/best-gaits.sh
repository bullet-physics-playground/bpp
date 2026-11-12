#!/bin/bash
# Each walker's best gait for each ground (12 November; handover/HANDOVER.md section 7), and the boards with them.
#   1. Choose, on seeds 1-5, on the boards' 33 grounds: the 8 diag builds at pair offsets 150, 120 and 90 (PAIR_OFFSET)
#      and Spears 4-bar's 4-beat walk 0-90-180-270 (the one option that beat its trot somewhere in runs/gaits.sh; the
#      others lost by 1-7 cm/s), against each one's trot -- from runs/boards-wheels.sh's runs without wheels if they
#      are there (PLAIN), else run here. A walker gets another gait on a ground only if it beats its trot there by more
#      than two standard errors (paired by seed); else a trot. Written to $OUT/gaits.lua.
#   2. Rank, on fresh seeds 6-10 (choosing and ranking on the same runs would flatter the chosen): every walker at a
#      trot on every ground, and at its chosen gait where that isn't a trot; then two boards files, trot.lua and
#      best.lua (each walker at its chosen gait), and how they compare (runs/compare-boards.py).
# All in test-ranking.lua's directions (Klann and Spears 4-bar reversed), without wheels (the gait is the linkage's).
#
#   cd demo/WyomingWill/WalkerRoom
#   BPP=../../../release/bpp runs/best-gaits.sh
#   cp runs/out-best-gaits/gaits.lua lib/gaits.lua          # the viewers and rooms then use them (BEST_GAITS)
#   cp runs/out-best-gaits/best.lua lib/boards.lua          # and the boards with them, if wanted
#
# Environment: BPP, JOBS, OUT (runs/out-best-gaits), PLAIN (runs/out-boards/plain/warm40fast), GROUNDS and the seeds
# (CHOOSE_SEEDS "1 2 3 4 5", RANK_SEEDS "6 7 8 9 10"; to try it small: GROUNDS="waves:4 logs:7" CHOOSE_SEEDS="1 2"
# RANK_SEEDS=3). About 4,100 runs to choose and 1,815 and a few hundred to rank. Runs already done are kept, and a
# trot run already made for any seed -- in PLAIN, or in an earlier ranking here -- is used for choosing, so more seeds
# cost only the new runs. 12 November: five seeds let lucky choices through on the roughest grounds (Hoecken slider
# diag on steps 7: +1.99 on seeds 1-5, slower than its trot on 6-10), so choose on 16 (William: the old minimum) and
# rank on 16 fresh ones (about 17,000 runs, the ones already made reused; 7 hours on 8 cores):
#   CHOOSE_SEEDS="$(seq -s ' ' 1 16)" RANK_SEEDS="$(seq -s ' ' 17 32)" BPP=... runs/best-gaits.sh
set -u
cd "$(dirname "$0")/.."
OUT=${OUT:-runs/out-best-gaits}
PLAIN=${PLAIN:-runs/out-boards/plain/warm40fast}
CHOOSE_SEEDS=${CHOOSE_SEEDS:-"1 2 3 4 5"}; RANK_SEEDS=${RANK_SEEDS:-"6 7 8 9 10"}
if [ -z "${GROUNDS:-}" ]; then
  GROUNDS="flat:0"
  for t in waves random logs steps; do for a in 1 2 3 4 5 6 7 8; do GROUNDS="$GROUNDS $t:$a"; done; done
fi
REV='REVERSE = { ["Klann"] = true, ["Spears 4-bar"] = true }'
DIAG=("Chebyshev-Spears lift 51 diag" "Chebyshev-Spears lift 62 diag" "Chebyshev-Spears diag" "Hoecken-Spears 4-bar diag"
      "Hoecken-Spears slider diag" "Hoecken slider diag" "Hoecken 4-bar diag" "Chebyshev diag")
ALL=("${DIAG[@]}" "Jansen" "Klann" "Spears 4-bar")
B=$(mktemp)
trap 'rm -f "$B"' EXIT
run() {   # folder, walker, settings, seeds, grounds
  echo "$2" > "$B"
  OUT="$1" BUILDS="$B" SEEDS="$4" TERRAINS="$5" EXTRA="$REV${3:+; $3}" runs/run-table.sh > /dev/null
}
settings() {   # option name -> walker-room settings
  case "$1" in trot) echo "";; offset_*) echo "PAIR_OFFSET = ${1#offset_}";; walk_0-90-180-270) echo "GAIT = { 0, 90, 180, 270 }";; esac
}
# 1. choose
echo "1. choosing, seeds $CHOOSE_SEEDS"
for w in "${ALL[@]}"; do   # (its trot: the runs already made, wherever they are, and the rest run here)
  f="${w// /_}"; d="$OUT/choose/${f}__trot/warm40fast"
  mkdir -p "$d"
  for src in "$PLAIN" "$OUT/rank/${f}__trot/warm40fast"; do
    for s in $CHOOSE_SEEDS; do cp -n "$src/${f}_"*"_s$s.txt" "$d/" 2> /dev/null; done
  done
  run "$OUT/choose/${f}__trot" "$w" "" "$CHOOSE_SEEDS" "$GROUNDS"
done
for w in "${DIAG[@]}"; do for o in 150 120 90; do run "$OUT/choose/${w// /_}__offset_$o" "$w" "PAIR_OFFSET = $o" "$CHOOSE_SEEDS" "$GROUNDS"; done; done
run "$OUT/choose/Spears_4-bar__walk_0-90-180-270" "Spears 4-bar" "GAIT = { 0, 90, 180, 270 }" "$CHOOSE_SEEDS" "$GROUNDS"
python3 - "$OUT" "$PLAIN" "$CHOOSE_SEEDS" "$GROUNDS" <<'PY' || exit 1
import sys, os, re, glob, math, statistics as st, collections
out, plain, seeds, grounds = sys.argv[1], sys.argv[2], sys.argv[3].split(), [g.replace(":", "") for g in sys.argv[4].split()]
def speed(f):
    m = re.search(r"^RUN .*?\|speed ([-\d.]+)", open(f).read(), re.M) if os.path.exists(f) else None
    return float(m.group(1)) if m else None
def key(g):   # waves4 -> "waves 4", the boards' name; flat0 -> "flat 0"
    t = re.match(r"([a-z]+)(\d+)", g); return f"{t.group(1)} {t.group(2)}"
def runs_of(d, w):
    return {(g, s): speed(os.path.join(d, f"{w.replace(' ', '_')}_{g}_s{s}.txt")) for g in grounds for s in seeds}
choice, lines = collections.defaultdict(dict), []
walkers = sorted({os.path.basename(d).split("__")[0].replace("_", " ") for d in glob.glob(os.path.join(out, "choose", "*__*")) if not d.endswith("__trot")})
for w in walkers:
    tdir = os.path.join(out, "choose", w.replace(" ", "_") + "__trot", "warm40fast")
    trot = runs_of(tdir if os.path.isdir(tdir) else plain, w)
    opts = {os.path.basename(d).split("__")[1]: runs_of(os.path.join(d, "warm40fast"), w)
            for d in glob.glob(os.path.join(out, "choose", w.replace(" ", "_") + "__*")) if not d.endswith("__trot")}
    for g in grounds:
        best = None
        for o, r in opts.items():
            d = [r[(g, s)] - trot[(g, s)] for s in seeds if r[(g, s)] is not None and trot[(g, s)] is not None]
            if len(d) < 2: continue
            m, se = st.mean(d), st.stdev(d) / math.sqrt(len(d))
            if m - 2 * se > 0 and (best is None or m > best[1]): best = (o, m, se)
        if best:
            choice[w][key(g)] = best[0]
            lines.append(f"| {w} | {key(g)} | {best[0].replace('_', ' ')} | {best[1]:+.2f} ± {best[2]:.2f} |")
with open(os.path.join(out, "gaits.lua"), "w") as f:
    f.write("-- Each walker's best gait for each ground (made by runs/best-gaits.sh, chosen on seeds " + " ".join(seeds) + "):\n")
    f.write("-- another gait only where it beat the walker's trot by more than two standard errors; else a trot. BEST_GAITS\n")
    f.write("GROUND_GAITS = {\n")
    for w in sorted(choice):
        f.write(f'  ["{w}"] = {{\n')
        for k, o in sorted(choice[w].items()):
            v = f"offset = {o[7:]}" if o.startswith("offset_") else "gait = { " + ", ".join(o[5:].split("-")) + " }"
            f.write(f'    ["{k}"] = {{ {v} }},\n')
        f.write("  },\n")
    f.write("}\n")
with open(os.path.join(out, "choices.txt"), "w") as f:
    f.write("\n".join(f"{w}|{k}|{o}" for w in choice for k, o in choice[w].items()) + "\n")
print(f"{sum(len(c) for c in choice.values())} choices other than a trot, of {len(walkers) * len(grounds)} walker-grounds (in {out}/gaits.lua):\n")
print("| Walker | Ground | Gait | Against its trot |\n| --- | --- | --- | --- |")
print("\n".join(lines) if lines else "| (none) | | | |")
PY
# 2. rank, on fresh seeds
echo
echo "2. ranking, seeds $RANK_SEEDS"
for w in "${ALL[@]}"; do run "$OUT/rank/${w// /_}__trot" "$w" "" "$RANK_SEEDS" "$GROUNDS"; done
while IFS='|' read -r w k o; do
  [ -z "$w" ] && continue
  run "$OUT/rank/${w// /_}__$o" "$w" "$(settings "$o")" "$RANK_SEEDS" "${k/ /:}"
done < "$OUT/choices.txt"
python3 - "$OUT" "$RANK_SEEDS" <<'PY' || exit 1
import sys, os, glob, shutil
out, seeds = sys.argv[1], set(sys.argv[2].split())
choice = {}
for line in open(os.path.join(out, "choices.txt")):
    if line.strip(): w, k, o = line.strip().split("|"); choice[(w, k.replace(" ", ""))] = o
for name in ("trot", "best"):
    d = os.path.join(out, "boards-" + name, "warm40fast"); shutil.rmtree(d, ignore_errors=True); os.makedirs(d)
for f in glob.glob(os.path.join(out, "rank", "*__trot", "warm40fast", "*.txt")):
    base = os.path.basename(f); w = os.path.basename(os.path.dirname(os.path.dirname(f))).split("__")[0].replace("_", " ")
    g, seed = base[:-4].rsplit("_", 2)[1:]
    if seed[1:] not in seeds: continue   # (only this ranking's seeds: an earlier ranking's are in the same folders)
    shutil.copy(f, os.path.join(out, "boards-trot", "warm40fast", base))
    o = choice.get((w, g))
    src = os.path.join(out, "rank", w.replace(" ", "_") + "__" + o, "warm40fast", base) if o else f
    shutil.copy(src, os.path.join(out, "boards-best", "warm40fast", base))
PY
python3 runs/boards.py "$OUT/boards-trot/warm40fast" > "$OUT/trot.lua" || exit 1
python3 runs/boards.py "$OUT/boards-best/warm40fast" > "$OUT/best.lua" || exit 1
echo "boards: $OUT/trot.lua (all at a trot) and $OUT/best.lua (each at its chosen gait), seeds $RANK_SEEDS"
echo
python3 runs/compare-boards.py "$OUT/trot.lua" "$OUT/best.lua"
