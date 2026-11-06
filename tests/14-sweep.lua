-- Sweep:addProfilePoint() rebuilds the collision hull. The rigid body must
-- collide with the new hull: before the fix it kept a pointer to the hull
-- that addProfilePoint() had just deleted, so v:add() and every collision
-- read freed memory (an AddressSanitizer build aborts; a normal build
-- usually gets away with it because the new hull lands in the same memory).

local pass = 0
local fail = 0

local function check(name, ok, detail)
  if ok then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": " .. tostring(detail))
    fail = fail + 1
  end
end

-- A ray straight down at (x, z); returns the hit fraction (1 = no hit).
local function down(x, z)
  return v:rayTest(btVector3(x, 10, z), btVector3(x, -10, z))
end

-- The default profile spans radius 1 and height 1. A point at radius 3 on
-- the ground widens the base: a ray at radius 2.5 now meets the sloping
-- side, a quarter of the way up.
local s = Sweep(0, btVector3(0, 1, 0), 0.0, 1)
s:addProfilePoint(3.0, 0.0)
v:add(s)
local f = down(2.5, 0)
check("ray meets the widened hull", f < 0.5 and f > 0.47, f)
check("ray beyond the hull misses", down(3.3, 0) == 1, down(3.3, 0))

-- A second point rebuilds again; the body must follow that too.
local s2 = Sweep(0, btVector3(0, 1, 0), 0.0, 1)
s2:addProfilePoint(2.0, 0.0)
s2:addProfilePoint(3.5, 0.0)
s2.pos = btVector3(20, 0, 0)
v:add(s2)
check("ray meets the hull after two rebuilds", down(23.2, 0) < 1, down(23.2, 0))

-- Rebuilding after the sweep is in the world. The world refreshes each
-- body's bounding box when it steps, so the new hull counts from then on.
local s3 = Sweep(0, btVector3(0, 1, 0), 0.0, 1)
s3.pos = btVector3(-20, 0, 0)
v:add(s3)
check("ray misses before the rebuild", down(-22.5, 0) == 1, down(-22.5, 0))
s3:addProfilePoint(3.0, 0.0)
v:stepSimulation(1 / 60, 1, 1 / 60)
check("ray meets the hull rebuilt in the world", down(-22.5, 0) < 1, down(-22.5, 0))

-- Dropped onto a plane, the widened sweep comes to rest on its base.
v:remove(s)
v:remove(s2)
v:remove(s3)
v:add(Plane(0, 1, 0, 0, 100))
local d = Sweep(0, btVector3(0, 1, 0), 0.0, 1)
d:addProfilePoint(3.0, 0.0)
d.pos = btVector3(0, 3, 0)
v:add(d)
for i = 1, 300 do
  v:stepSimulation(1 / 60, 1, 1 / 60)
end
local p = d.pos
check("dropped sweep rests on the plane", math.abs(p.y) < 0.1, p.y)
check("dropped sweep stays upright", math.abs(p.x) < 0.1 and math.abs(p.z) < 0.1,
      string.format("x=%g z=%g", p.x, p.z))

print(string.format("\n%d passed, %d failed", pass, fail))
