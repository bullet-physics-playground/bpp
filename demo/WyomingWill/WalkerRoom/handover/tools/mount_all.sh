#!/bin/bash
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
out=${1:-/home/claude/work/mounts.txt}; : > $out
for n in "Jansen" "Klann" "Spears 4-bar" "Chebyshev" "Chebyshev diag" "Chebyshev-Spears" "Chebyshev-Spears diag" "Hoecken 4-bar" "Hoecken 4-bar diag" "Hoecken slider" "Hoecken-Spears slider" "Hoecken-Spears 4-bar" "Hoecken-Spears 4-bar diag" "Hoecken-Spears long-stance" "Hoecken-Spears long-stance diag" "Spears lift 44" "Spears lift 44 diag" "Spears lift 53" "Spears lift 53 diag"; do
  f=$(mktemp ./_mp_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"\ndofile("/home/claude/work/mountprobe.lua")\n' "$n" > $f
  MOUNT_OUT=$out QT_QPA_PLATFORM=offscreen timeout 120 /home/claude/build/release/bpp -f $(basename $f) -n 2 2>&1 | grep -i "error" | grep -v ALSA
  rm -f $f
done
cat $out
