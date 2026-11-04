#!/bin/bash
# checks/vehicles.sh -- the vehicle interface (lib/swarm.lua, BOOK.md G18)
#
#   1. every vehicle module provides what lib/swarm.lua's header lists;
#   2. each physical vehicle meets its specification
#      (checks/vehicle_physics.lua: speed and turn caps, small moves at
#      the minimum speed, floating, righting; the point mass's speed,
#      acceleration and lag);
#   2b. the vehicles with velocity() (G4) fly a commanded velocity and
#      stop on velocity 0 (checks/velocity.lua);
#   3. the harness on the ideal vehicle (lib/ideal.lua, perfect tracking)
#      forms the Lennard-Jones 2D triangle as the original particles do:
#      formed (probes/settle_drones.lua's `formed` >= 0), bond length
#      0.99-1.02 of desiredSeparation, nothing lost; seeds 1-2;
#   4. Ch. 7's corridor on ground robots runs (ch07/Corridor-Ground.lua);
#   5. Ch. 13's dumbbell drives the robot through drive() in Bullet
#      (ch13/Ring-Ground.lua, case 1): the three-point turn.
#
# Needs BPP (the modules build Bullet objects). Run from the
# ArtificialPhysics folder (about 45 s):  bash checks/vehicles.sh
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
VEHICLES="quadcopter.vehicle lib.ideal lib.pointmass ground.vehicle boat.vehicle"
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
for vv in ground:1300 boat:1600 pointmass:500; do
  VEH=${vv%:*} "$BPP" -f checks/vehicle_physics.lua -n ${vv#*:} > "$T/phys.txt" 2>&1
  grep -E "^(ok|FAIL)" "$T/phys.txt"
  grep -q "^PASS" "$T/phys.txt" || { fail=1; grep -q "^FAIL" "$T/phys.txt" || { echo "FAIL vehicles: vehicle_physics ${vv%:*} did not finish"; tail -3 "$T/phys.txt"; }; }
done

# 2b. velocity commands (G4): each vehicle with velocity() flies it
for vv in lib.ideal:700 lib.pointmass:700 boat.vehicle:700 ground.vehicle:700 quadcopter.vehicle:1100; do
  VMOD=${vv%:*} "$BPP" -f checks/velocity.lua -n ${vv#*:} > "$T/vel.txt" 2>&1
  grep -E "^(ok|FAIL)" "$T/vel.txt"
  grep -q "^PASS" "$T/vel.txt" || { fail=1; grep -q "^FAIL" "$T/vel.txt" || { echo "FAIL vehicles: velocity ${vv%:*} did not finish"; tail -3 "$T/vel.txt"; }; }
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

# 4. Ch. 7's corridor on ground robots (ch07/Corridor-Ground.lua: the
#    sonar through Bullet, velocity(), the coverage): KT, 25 robots, 20%,
#    course 0, back-off on (as swept), 200 steps covers about what the
#    port does (8.8%) and the robots drive over 90% of the path they are
#    told
KERR_LIMIT=200 KERR_BACKOFF=1 KERR_EXIT=1 "$BPP" -f ch07/Corridor-Ground.lua -n 10000 > "$T/kt.txt" 2>&1
python3 - "$T/kt.txt" <<'EOF' || fail=1
import sys
m = [l for l in open(sys.argv[1]) if l.startswith("KTRobot ")]
t = m[-1].split() if m else []
f = dict(zip(t[1::2], t[2::2]))
ok = bool(f) and int(f["Time"]) == 200 and 7 < float(f["Total"]) < 12 and float(f["Moved"]) > 0.9
print(("ok  " if ok else "FAIL") + " corridor on ground robots, KT 20%, 200 steps: "
      + (f"total {f['Total']}% (port 8.8%), moved {f['Moved']}, bumps {f['Bumps']}" if f else "no result line"))
sys.exit(0 if ok else 1)
EOF

# 5. Ch. 13's dumbbell on the Pioneer in Bullet (ch13/Ring-Ground.lua,
#    case 1): the attractor dead astern; the robot backs, then drives
#    forwards, and is on the ring pointing in within 15 s (11.0 s measured)
RING_CASE=1 RING_LIMIT=20 RING_EXIT=1 "$BPP" -f ch13/Ring-Ground.lua -n 10000 > "$T/ring.txt" 2>&1
python3 - "$T/ring.txt" <<'EOF' || fail=1
import sys
m = [l for l in open(sys.argv[1]) if l.startswith("Ring ")]
t = m[-1].split() if m else []
f = dict(zip(t[1::2], t[2::2]))
segs = f.get("Segments", "").split(",")
ok = bool(f) and 0 <= float(f["Formed"]) < 15 and [s[0] for s in segs[:2]] == ["B", "F"]
print(("ok  " if ok else "FAIL") + " dumbbell on a ground robot, attractor dead astern: "
      + (f"segments {','.join(segs[:3])}, formed at {f['Formed']} s, point {f['Point']} deg" if f else "no result line"))
sys.exit(0 if ok else 1)
EOF

if [ $fail = 0 ]; then echo "PASS vehicles"; else echo "FAIL vehicles"; fi
exit $fail
