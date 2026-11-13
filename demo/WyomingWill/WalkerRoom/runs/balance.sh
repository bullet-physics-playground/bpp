#!/bin/bash
# How far each walker's centre of mass sits from the middle of its feet, braces and all (14 November; handover
# section 7, "Balance"): runs/balprobe.lua on each of the 11 walkers test-ranking.lua shows (or BUILDS, a file of
# names), with the runs' settings (run-table.sh's), one BAL line each. EXTRA: more settings (as run-table.sh's).
#
#   cd demo/WyomingWill/WalkerRoom
#   BPP=../../../release/bpp runs/balance.sh
set -u
cd "$(dirname "$0")/.."
BPP=${BPP:-bpp}
command -v "$BPP" > /dev/null || { echo "bpp not found: set BPP to the bpp program"; exit 1; }
if [ -n "${BUILDS:-}" ]; then mapfile -t NAMES < "$BUILDS"; else NAMES=(
  "Chebyshev-Spears lift 51 diag" "Chebyshev-Spears lift 62 diag" "Chebyshev-Spears diag" "Hoecken-Spears 4-bar diag"
  "Hoecken-Spears slider diag" "Hoecken slider diag" "Hoecken 4-bar diag" "Chebyshev diag" "Jansen" "Klann" "Spears 4-bar"); fi
one() {
  case "$1" in Jansen|Klann|"Spears 4-bar") b="OWN_FRAME=true";; *diag) b="DIAG_OUTSIDE=true; PENDANT_HOLD=true";; *) b="UNBRACED=true";; esac
  f=$(mktemp ./_bal_XXXXXX.lua)
  printf 'v:setSolver("si-warm"); SOLVER_ITERATIONS=40; FIXED=1/1920; v:setSolverInfo("residual", 0.01); MOTOR_STRENGTH=2; dofile("lib/trotting-walkers.lua"); dofile("lib/spears-lift-walkers.lua"); ONLY="%s"; TERRAIN="flat"; AMP=0; SEED=1; BUMP=15; GRAVITY=981; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; %s\n%s\ndofile("runs/balprobe.lua")\n' \
    "$1" "$b" "${EXTRA:-}" > "$f"
  QT_QPA_PLATFORM=offscreen timeout 600 "$BPP" -f "$(basename "$f")" -n 2400 2>&1 | grep -aE '^BAL|rror' | grep -v ALSA
  rm -f "$f"
}
export BPP EXTRA; export -f one
printf '%s\n' "${NAMES[@]}" | xargs -d '\n' -P "${JOBS:-4}" -I{} bash -c 'one "$@"' _ {} | sort
