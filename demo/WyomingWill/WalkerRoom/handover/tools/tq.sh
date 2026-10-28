#!/bin/bash
# Crank torque demand (torqueprobe.lua) at 1000 iterations (early stop at residual 0.01), flat and steps 5 seed 1,
# 20 s, without and with joint friction (mu 0.1, pin 0.25 cm), 8 walkers as run (own frames, guides). Resumable.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { out=/home/claude/work/tq/$4.txt; grep -q '^TQ' $out 2>/dev/null && return; f=$(mktemp ./_tq_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=1000; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; %s; TQ_FROM=2; TQ_TO=20; dofile("/home/claude/work/torqueprobe.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 6000 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -E "^(TQ|STALL|TRACK)|rror" | grep -v ALSA > $out.tmp && mv $out.tmp $out; rm -f $f; }
J=()
for fr in "off:XX=1" "fric:JOINT_FRICTION={mu=0.1, pin=0.25}"; do for t in "flat:TERRAIN=\"waves\"; AMP=0; SEED=1" "steps5:TERRAIN=\"steps\"; AMP=5; SEED=1"; do
  for c in "Jansen|XX=2" "Klann|XX=2" "Spears 4-bar|XX=2" "Chebyshev|UNBRACED=true" "Chebyshev-Spears|UNBRACED=true" "Hoecken-Spears 4-bar|UNBRACED=true" "Hoecken-Spears slider|UNBRACED=true" "Spears lift 44|UNBRACED=true"; do
    n=${c%%|*}; x=${c#*|}; J+=("$n|${t#*:}|$x; ${fr#*:}|${n// /_}_${t%%:*}_${fr%%:*}"); done; done; done
i=0; for j in "${J[@]}"; do IFS='|' read n T x t <<< "$j"; one "$n" "$T" "$x" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo TQ_DONE
