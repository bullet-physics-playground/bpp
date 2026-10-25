#!/bin/bash
# Check runs on the new track (6 m wide, new advances): Chebyshev-Spears and Hoecken-Spears 4-bar, guides (trot) against
# outside braces with held pendants; waves 4, BUMP 15, 60 s, Earth standard (standard ankle springs), forward;
# seeds 1-4, each on normal and mirrored ground. Resumable: skips runs whose file has a TRACK line.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { out=/home/claude/work/chk36/$4.txt; grep -q '^TRACK' $out 2>/dev/null && return
  f=$(mktemp ./_ck_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; TERRAIN="waves"; AMP=4; BUMP=15; SEED=%s; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; %s\ndofile("/home/claude/work/stallprobe.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 1500 /home/claude/build/release/bpp -f $(basename $f) -n 3700 2>&1 | grep -E "^(TRACK|STALL)|rror" | grep -v ALSA > $out.tmp && mv $out.tmp $out; rm -f $f; }
J=()
for s in 1 2 3 4; do for m in normal mirrored; do
  M=""; [ $m = mirrored ] && M="TERRAIN_MIRROR=true; "
  J+=("Chebyshev-Spears|$s|${M}UNBRACED=true; GAIT={0,180,180,0}|CS_guides_s${s}_$m")
  J+=("Chebyshev-Spears diag|$s|${M}DIAG_OUTSIDE=true; PENDANT_HOLD=true|CS_outside_s${s}_$m")
  J+=("Hoecken-Spears 4-bar|$s|${M}UNBRACED=true; GAIT={0,180,180,0}|HS4_guides_s${s}_$m")
  J+=("Hoecken-Spears 4-bar diag|$s|${M}DIAG_OUTSIDE=true; PENDANT_HOLD=true|HS4_outside_s${s}_$m")
done; done
i=0; for j in "${J[@]}"; do IFS='|' read n s x t <<< "$j"; one "$n" "$s" "$x" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo CHK36_DONE
