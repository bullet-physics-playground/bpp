#!/bin/bash
# Spec footTips check (HS slider diag, logs 7 seed 1, should match tips10's 4.73), then Hoecken slider diag with its
# spec toes on all 10 terrains, seeds 1-3, 20 s, the ft2 standard (29 October).
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
mkdir -p /home/claude/work/hst
one() { out=/home/claude/work/hst/$3.txt; grep -q '^TQ' $out 2>/dev/null && return; f=$(mktemp ./_hs_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=200; MOTOR_STRENGTH=2; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; DIAG_OUTSIDE=true; PENDANT_HOLD=true; TQ_FROM=2; TQ_TO=20; dofile("/home/claude/work/torqueprobe.lua")\n' "$1" "$2" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -E "^(TQ|STALL|TRACK)|rror" | grep -v ALSA > $out; rm -f $f; }
J=("Hoecken-Spears slider diag|TERRAIN=\"logs\"; AMP=7; SEED=1|check_HSsd_logs7_s1")
for s in 1 2 3; do
  for t in waves:0 waves:2 waves:4 waves:6 logs:3 logs:5 logs:7 steps:3 steps:5 steps:7; do
    T="TERRAIN=\"${t%%:*}\"; AMP=${t##*:}; SEED=$s"; tg="${t%%:*}${t##*:}_s$s"; [ $t = waves:0 ] && tg="flat_s$s"
    J+=("Hoecken slider diag|$T|Hsd_$tg"); done; done
i=0; for j in "${J[@]}"; do IFS='|' read n T t <<< "$j"; one "$n" "$T" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo HST_DONE
