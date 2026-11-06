-- Blob: adding a component keeps the blob's mass (it used to set 1), and
-- the POV-Ray export closes each component, as POV-Ray requires:
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
