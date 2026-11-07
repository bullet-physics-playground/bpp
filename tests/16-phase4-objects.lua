-- The object types added in "Phase 4" that have no demo of their own:
-- TrueType, SuperQuadric, Patch and ReferenceObject (Sweep and Blob have
-- 14-sweep.lua and 15-blob.lua). Each is built, simulated, and exported
-- to POV-Ray.

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

local function balanced(pov)
  return count(pov, "{") == count(pov, "}")
end

local function step(n)
  for i = 1, n do
    v:stepSimulation(1 / 60, 1, 1 / 60)
  end
end

-- Dropped from height 3, each comes to rest on the ground.
v:add(Plane(0, 1, 0, 0, 200))
local text = TrueType("Generic.ttf", "BPP", 1.5, 1)
local sq1 = SuperQuadric(0.5, 0.5, 1.2, 1)
local sq2 = SuperQuadric(0.3, 0.8, 1.0, 1)
text.pos = btVector3(0, 3, 0)
sq1.pos = btVector3(6, 3, 0)
sq2.pos = btVector3(12, 3, 0)
v:add(text)
v:add(sq1)
v:add(sq2)
step(300)
check("TrueType falls and rests on the ground", text.pos.y > 0 and text.pos.y < 1, text.pos.y)
-- A superquadric of size s rests with its centre s/2 up.
check("SuperQuadric of size 1.2 rests at 0.6", math.abs(sq1.pos.y - 0.6) < 0.05, sq1.pos.y)
check("SuperQuadric of size 1.0 rests at 0.5", math.abs(sq2.pos.y - 0.5) < 0.05, sq2.pos.y)

local floor = Cube(20, 1, 20, 0)
floor.pos = btVector3(40, -0.5, 0)
v:add(floor)
local patch = Patch(2.0, 1)
patch.pos = btVector3(40, 3, 0)
v:add(patch)
step(120)
check("Patch falls and rests on a box", math.abs(patch.pos.y) < 0.05, patch.pos.y)

-- POV-Ray export: the right object, braces balanced.
local pov = text:toPOV()
check("TrueType exports as text", pov:find('^text { ttf "Generic.ttf" "BPP" 1.5, 0') ~= nil, pov)
check("TrueType export balances", balanced(pov), pov)

pov = sq1:toPOV()
check("SuperQuadric exports as superellipsoid", pov:find("^superellipsoid { <0.5, 0.5>") ~= nil, pov)
check("SuperQuadric export balances", balanced(pov), pov)

pov = patch:toPOV()
check("Patch exports as bicubic_patch", pov:find("^bicubic_patch {") ~= nil, pov)
check("Patch exports 16 control points", count(pov, "\n  <[^>\n]*>") == 16, pov)
check("Patch export balances", balanced(pov), pov)

local ref = ReferenceObject("MyThing")
pov = ref:toPOV()
check("ReferenceObject exports a reference", pov:find("^object { MyThing") ~= nil, pov)
check("ReferenceObject export balances", balanced(pov), pov)

-- Without a name there is nothing to refer to: only a POV-Ray comment.
pov = ReferenceObject():toPOV()
check("an unnamed ReferenceObject exports only a comment",
      pov:find("^//") ~= nil and pov:find("{") == nil and pov:find("}") == nil, pov)

print(string.format("\n%d passed, %d failed", pass, fail))
