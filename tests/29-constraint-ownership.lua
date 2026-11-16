-- A script's constraint and v:addConstraint / v:removeConstraint: bpp takes
-- it once and keeps it until the script ends, so the script's handle stays
-- good whatever order it calls them in. Before, adding one twice broke the
-- handle (and the next v:removeConstraint crashed), removing gave back a
-- second handle that freed the constraint when collected (so adding it back
-- used freed memory), and removing one never added freed it twice. Each case
-- must end the script without a crash, a use after free or a double free
-- (the sanitizer job checks those); here, that the constraints still work.

local pass = 0
local fail = 0

local function check(name, ok, detail)
  if ok then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. (detail and (": " .. detail) or ""))
    fail = fail + 1
  end
end

local function step(n)
  for _ = 1, n do v:stepSimulation(1 / 60, 1, 1 / 60) end
end

-- two cubes hanging from the first, which is fixed, by a joint 2 apart
local function pair(x)
  local a = Cube(1, 1, 1, 0); a.pos = btVector3(x, 10, 0); v:add(a)
  local b = Cube(1, 1, 1, 1); b.pos = btVector3(x, 8, 0); v:add(b)
  local c = btPoint2PointConstraint(a.body, b.body, btVector3(0, -1, 0), btVector3(0, 1, 0))
  return a, b, c
end

local function held(b) return math.abs(b.pos.y - 8) < 0.1 end

-- Removed, collected, added back.
do
  local _, b, c = pair(0)
  v:addConstraint(c)
  check("remove gives back the same handle", rawequal(v:removeConstraint(c), c))
  collectgarbage(); collectgarbage()
  step(30)
  check("removed: the cube falls", not held(b), "y=" .. b.pos.y)
  b.pos = btVector3(0, 8, 0); b.vel = btVector3(0, 0, 0)
  v:addConstraint(c)
  step(30)
  check("added back: it holds again", held(b), "y=" .. b.pos.y)
end

-- Added twice, removed once.
do
  local _, b, c = pair(4)
  v:addConstraint(c)
  v:addConstraint(c)
  v:removeConstraint(c)
  collectgarbage(); collectgarbage()
  step(30)
  check("added twice, removed once: it's out", not held(b), "y=" .. b.pos.y)
end

-- Removed though never added: still the script's.
do
  local _, _, c = pair(8)
  check("never added: remove gives it back", rawequal(v:removeConstraint(c), c))
  c = nil
  collectgarbage(); collectgarbage()
end

-- Removed twice, and left out at the end (bpp frees it).
do
  local _, _, c = pair(12)
  v:addConstraint(c)
  v:removeConstraint(c)
  v:removeConstraint(c)
  collectgarbage(); collectgarbage()
  check("removed twice", true)
end

-- Not a constraint.
check("addConstraint(nil) is an error", not pcall(function() v:addConstraint(nil) end))
check("removeConstraint of a cube is an error",
      not pcall(function() v:removeConstraint(Cube(1, 1, 1, 1)) end))

print(string.format("\n%d passed, %d failed", pass, fail))
