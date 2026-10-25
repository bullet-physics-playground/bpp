#!/bin/bash
# checks/vehicles.sh -- the vehicle interface (lib/swarm.lua, BOOK.md G18)
#
#   1. every vehicle module provides what lib/swarm.lua's header lists;
#   2. each physical vehicle meets its specification
#      (checks/vehicle_physics.lua: speed and turn caps, small moves at
#      the minimum speed, floating, righting);
#   3. the harness on the ideal vehicle (lib/ideal.lua, perfect tracking)
#      forms the Lennard-Jones 2D triangle as the original particles do:
#      formed (probes/settle_drones.lua's `formed` >= 0), bond length
#      0.99-1.02 of desiredSeparation, nothing lost; seeds 1-2.
#
# Needs BPP (the modules build Bullet objects). Run from the
# ArtificialPhysics folder (about 20 s):  bash checks/vehicles.sh
# Prints ok/FAIL lines and PASS or FAIL; exits 0 or 1.
set -u
cd "$(dirname "$0")/.." || exit 1
BPP=${BPP:-}
if [ -z "$BPP" ]; then for b in ../../../release/bpp ../../../debug/bpp; do [ -x "$b" ] && BPP=$b; done; fi
[ -n "$BPP" ] || { echo "FAIL vehicles: no BPP (set BPP=)"; exit 1; }
export BPP SDL_AUDIODRIVER=${SDL_AUDIODRIVER:-dummy} QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-offscreen}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/rt-checks}; mkdir -p "$XDG_RUNTIME_DIR"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail=0

# 1. the interface
VEHICLES="quadcopter.vehicle lib.ideal ground.vehicle boat.vehicle"
"$BPP" -n 1 -l "
local need = { 'name', 'noun', 'moving', 'floorY', 'planeY', 'new', 'remove', 'setColor', 'sync',
               'guide', 'join', 'command', 'hold', 'step' }
for m in ('$VEHICLES'):gmatch('%S+') do
  local ok, V = pcall(require, m)
  if not ok then print('FAIL vehicles: ' .. m .. ' does not load: ' .. tostring(V))
  else
    local miss = {}
    for _, k in ipairs(need) do if V[k] == nil then miss[#miss + 1] = k end end
    if type(V.can3D) ~= 'boolean' or type(V.fragile) ~= 'boolean' then miss[#miss + 1] = 'can3D/fragile' end
    print((#miss == 0 and 'ok   ' or 'FAIL ') .. m .. (#miss == 0 and ': the whole interface' or ': missing ' .. table.concat(miss, ', ')))
  end
end" > "$T/iface.txt" 2>&1
grep -E "^(ok|FAIL)" "$T/iface.txt"
grep -q "^FAIL" "$T/iface.txt" && fail=1
[ "$(grep -c '^ok' "$T/iface.txt")" = "$(echo $VEHICLES | wc -w)" ] || { [ $fail = 1 ] || { echo "FAIL vehicles: interface check did not run"; tail -3 "$T/iface.txt"; }; fail=1; }

# 2. each vehicle against its specification
for vv in ground:1300 boat:1600; do
  VEH=${vv%:*} "$BPP" -f checks/vehicle_physics.lua -n ${vv#*:} > "$T/phys.txt" 2>&1
  grep -E "^(ok|FAIL)" "$T/phys.txt"
  grep -q "^PASS" "$T/phys.txt" || { fail=1; grep -q "^FAIL" "$T/phys.txt" || { echo "FAIL vehicles: vehicle_physics ${vv%:*} did not finish"; tail -3 "$T/phys.txt"; }; }
done

# 3. the ideal vehicle forms the LJ lattice
python3 lib/batch.py Formations-Lennard-Jones-Quadcopter.lua --probe probes/settle_drones.lua \
  --env VEHICLE=lib.ideal --env DIM=2 --seeds 1-2 --set obstacleField=false --set goalDelay=0 \
  --frames 3000 --out "$T/ideal.csv" > "$T/ideal.txt" 2>&1 || { echo "FAIL vehicles: the ideal run failed"; tail -3 "$T/ideal.txt"; fail=1; }
python3 - "$T/ideal.csv" <<'EOF' || fail=1
import csv, sys
rows = [r for r in csv.DictReader(open(sys.argv[1])) if r.get("final") == "1"]
bad = len(rows) != 2
for r in rows:
    f, b, c = float(r["formed"]), float(r["bond"]), int(r["crashed"])
    ok = f >= 0 and 0.99 <= b <= 1.02 and c == 0
    bad = bad or not ok
    print(("ok  " if ok else "FAIL") + f" ideal LJ 2D seed {r['seed']}: formed at {f:.1f} s, bond {b:.3f} D, {c} lost")
sys.exit(1 if bad else 0)
EOF

if [ $fail = 0 ]; then echo "PASS vehicles"; else echo "FAIL vehicles"; fi
exit $fail
