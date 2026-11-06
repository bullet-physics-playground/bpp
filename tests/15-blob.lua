-- Blob: adding a component keeps the blob's mass (it used to set 1); the
-- blob has POV-Ray's surface, the one drawn and collided with; and the
-- POV-Ray export closes each component, as POV-Ray requires:
--   sphere { <center>, radius, strength s }
--   cylinder { <end1>, <end2>, radius, strength s }

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

local function count(s, pattern)
  return select(2, string.gsub(s, pattern, ""))
end

-- Mass
local b = Blob(1.0, 5)
b:addSphereComponent(btVector3(0, 0, 0), 1.0, 1.0)
check("a blob keeps its mass after a sphere component", b.mass == 5, b.mass)
b:addCylinderComponent(btVector3(0, 0, 0), btVector3(0, 1, 0), 0.5, 1.0, 1.0)
check("a blob keeps its mass after a cylinder component", b.mass == 5, b.mass)

local fixed = Blob(1.0, 0)
fixed:addSphereComponent(btVector3(0, 0, 0), 1.0, 1.0)
fixed.pos = btVector3(0, 3, 0)
v:add(fixed)
for i = 1, 60 do
  v:stepSimulation(1 / 60, 1, 1 / 60)
end
check("a fixed blob keeps mass 0", fixed.mass == 0, fixed.mass)
check("a fixed blob does not fall", math.abs(fixed.pos.y - 3) < 1e-6, fixed.pos.y)

-- Surface. POV-Ray's field of a component with radius r and strength s is
-- s * (1 - (d/r)^2)^2 at distance d < r (from the centre, or from the
-- segment of a cylinder component, which has hemispherical caps); the
-- surface is where the summed field equals the threshold. Alone, a sphere
-- component shows a radius of r * sqrt(1 - sqrt(threshold / s)).
-- The collision shape is the convex hull of that surface; a ray straight
-- down finds its top (Bullet adds a 0.04 margin).
local function top(x)
  local f = v:rayTest(btVector3(x, 10, 0), btVector3(x, -10, 0))
  if f == 1 then return nil end
  return 10 - 20 * f
end

local function between(y, lo, hi)
  return y ~= nil and y > lo and y < hi
end

local s1 = Blob(0.5, 0)
s1:addSphereComponent(btVector3(0, 0, 0), 1.0, 1.0)
s1.pos = btVector3(20, 0, 0)
v:add(s1)
check("a sphere component's top is at 0.541", between(top(20), 0.52, 0.61), top(20))
check("a sphere component is narrower than its radius", top(20.8) == nil, top(20.8))

local s2 = Blob(1.0, 0)
s2:addSphereComponent(btVector3(0, 0, 0), 1.0, 1.0)
s2.pos = btVector3(30, 0, 0)
v:add(s2)
check("strength not above threshold: nothing to hit", top(30) == nil, top(30))

local s3 = Blob(0.5, 0)
s3:addSphereComponent(btVector3(0, 0, 0), 1.0, 1.0)
s3.pos = btVector3(40, 0, 0)
v:add(s3)
s3.threshold = 0.9
v:stepSimulation(1 / 60, 1, 1 / 60)
check("raising the threshold shrinks the surface to 0.229", between(top(40), 0.2, 0.3), top(40))

-- A cylinder component from (50, 0, 0) to (52, 0, 0), radius 1: a capsule
-- 0.541 thick around that segment.
local c = Blob(0.5, 0)
c:addCylinderComponent(btVector3(0, 0, 0), btVector3(1, 0, 0), 1.0, 2.0, 1.0)
c.pos = btVector3(50, 0, 0)
v:add(c)
check("a cylinder component reaches past its far end", between(top(52.4), 0, 0.61), top(52.4))
check("a cylinder component ends with its cap", top(52.8) == nil, top(52.8))
check("a cylinder component reaches back past its start", between(top(49.6), 0, 0.61), top(49.6))
check("a cylinder component starts with its cap", top(49.2) == nil, top(49.2))

-- POV-Ray export
local e = Blob(1.0, 1)
e:addSphereComponent(btVector3(0, 0, 0), 1.2, 1.0)
e:addSphereComponent(btVector3(1, 0.5, 0), 0.8, 0.8)
e:addCylinderComponent(btVector3(-0.8, -0.5, 0), btVector3(0, 1, 0), 0.5, 1.5, 0.6)
local pov = e:toPOV()
check("export braces balance", count(pov, "{") == count(pov, "}"),
      count(pov, "{") .. " { against " .. count(pov, "}") .. " }\n" .. pov)
check("sphere components are closed",
      count(pov, "sphere { <[^>]*>, [%d.]+, strength [%d.]+ }") == 2, pov)
check("cylinder component is closed",
      count(pov, "cylinder { <[^>]*>, <[^>]*>, [%d.]+, strength [%d.]+ }") == 1, pov)

print(string.format("\n%d passed, %d failed", pass, fail))
