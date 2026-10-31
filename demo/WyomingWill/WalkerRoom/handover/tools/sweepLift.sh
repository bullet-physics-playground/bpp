#!/bin/bash
# (31 October 2026: every build, for its lift as a share of stride; then python3 liftpct.py /home/claude/work/sweepLift)
# trot sweeps (body held, one slow crank turn) of every build that goes into the runs, as it will be run:
# own frames and guides at GAIT trot, diag builds with outside braces and held pendants; Earth standard, ankles on
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
STD='CRANK=0.6; GRAVITY=981; FIXED=1/3840; ANKLE_SPRING={stiffness=42000, damping=4200}; GAIT={0,180,180,0}; LINK_WIDTH=1.0'
one() { f=$(mktemp ./_st_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; %s\ndofile("/home/claude/work/sweepprobe.lua")\n' "$1" "$STD" "$2" > $f
  SWEEP_OUT="/home/claude/work/sweepLift/$3.txt" QT_QPA_PLATFORM=offscreen /home/claude/build/release/bpp -f $(basename $f) -n 950 2>&1 | grep -i error | grep -v ALSA; rm -f $f; }
G='UNBRACED=true'; D='DIAG_OUTSIDE=true; OUTSIDE_V=true'
jobs=( "Jansen||Jansen" "Klann||Klann" "Spears 4-bar||Spears_4-bar"
  "Chebyshev|$G|Chebyshev" "Chebyshev-Spears|$G|Chebyshev-Spears" "Hoecken 4-bar|$G|Hoecken_4-bar" "Hoecken slider|$G|Hoecken_slider"
  "Hoecken-Spears slider|$G|Hoecken-Spears_slider" "Hoecken-Spears 4-bar|$G|Hoecken-Spears_4-bar" "Hoecken-Spears 4-bar duty 85|$G|Hoecken-Spears_4-bar_duty_85"
  "Chebyshev-Spears lift 51|$G|Chebyshev-Spears_lift_51" "Chebyshev-Spears lift 62|$G|Chebyshev-Spears_lift_62"
  "Chebyshev diag|$D|Chebyshev_diag" "Chebyshev-Spears diag|$D|Chebyshev-Spears_diag" "Hoecken 4-bar diag|$D|Hoecken_4-bar_diag"
  "Hoecken-Spears 4-bar diag|$D|Hoecken-Spears_4-bar_diag" "Hoecken-Spears 4-bar duty 85 diag|$D|Hoecken-Spears_4-bar_duty_85_diag"
  "Chebyshev-Spears lift 51 diag|$D|Chebyshev-Spears_lift_51_diag" "Chebyshev-Spears lift 62 diag|$D|Chebyshev-Spears_lift_62_diag" "Hoecken slider diag|$D|Hoecken_slider_diag" "Hoecken-Spears slider diag|$D; PENDANT_HOLD=true|Hoecken-Spears_slider_diag" )
i=0; for j in "${jobs[@]}"; do IFS='|' read n x t <<< "$j"; one "$n" "$x" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo SWEEP_DONE
