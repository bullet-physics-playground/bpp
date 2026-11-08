-- Decorations (o.decoration, v:attach): objects that are only drawn and
-- exported, never in Bullet's world. Following a parent happens when bpp
-- draws or exports, which a unit test does not do: the golden demo
-- (decorations.lua, exported) and the screens scene (decorations.lua, drawn)
-- check that. Here: Bullet never moves a decoration, nothing meets it, the
-- ray never finds it, v:attach takes only a decoration, and taking one out
-- and putting it back is safe.

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

local function step(n)
  for i = 1, n do v:stepSimulation(1 / 60, 1, 1 / 60) end
end

v.gravity = btVector3(0, -9.81, 0)

local box = Cube(1, 1, 1, 1)
check("an object is not a decoration by default", box.decoration == false, box.decoration)

-- with mass, it would fall if Bullet stepped it
local d = Cube(1, 1, 1, 1)
d.decoration = true
d.pos = btVector3(0, 5, 0)
v:add(d)
check("decoration is set", d.decoration == true, d.decoration)
step(60)
check("Bullet never moves a decoration", math.abs(d.pos.y - 5) < 1e-6, d.pos.y)

-- a box falls through a decoration floor
local floor = Cube(10, 1, 10, 0)
floor.decoration = true
floor.pos = btVector3(20, 0, 0)
v:add(floor)
box.pos = btVector3(20, 2, 0)
v:add(box)
step(120)
check("a body falls through a decoration", box.pos.y < -2, box.pos.y)

-- the ray: through the decoration at x = 0 to nothing (1: no hit); the same ray finds a body there
check("the ray never finds a decoration", v:rayTest(btVector3(0, 10, 0), btVector3(0, -10, 0)) == 1)
local solid = Cube(1, 1, 1, 0)
solid.pos = btVector3(40, 5, 0)
v:add(solid)
check("the same ray finds a body", v:rayTest(btVector3(40, 10, 0), btVector3(40, -10, 0)) < 1)

-- v:attach takes only a decoration, and not itself
check("attach refuses an object that is not a decoration", not pcall(function() v:attach(box, d) end))
check("attach refuses an object to itself", not pcall(function() v:attach(d, d) end))
check("attach takes a decoration", pcall(function() v:attach(d, box) end))
check("detach", pcall(function() v:detach(d) end))
check("attach to a decoration's parent that is itself a decoration", pcall(function() v:attach(d, floor) end))

-- out and back in, and out again, with its parent gone first
check("remove a parent", pcall(function() v:remove(floor) end))
check("remove a decoration", pcall(function() v:remove(d) end))
check("add it back", pcall(function() v:add(d) end))
step(10)
check("still never moved by Bullet", math.abs(d.pos.y - 5) < 1e-6, d.pos.y)
check("remove it again", pcall(function() v:remove(d) end))

print(string.format("\n%d passed, %d failed", pass, fail))
