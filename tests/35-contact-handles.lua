-- The handles v:eachContact gives are the ones the objects were added
-- with, also for objects added inside a coroutine (Babbage's Hall loads its
-- exhibits in coroutines). v:add used to keep whatever was at index 2 of
-- the main Lua state's stack: from a coroutine that is the first argument
-- given to coroutine.resume, here a string, and eachContact then handed the
-- script that string for the object.

local pass = 0
local fail = 0

local function check(name, ok, got)
  if ok then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": got " .. tostring(got))
    fail = fail + 1
  end
end

v.gravity = btVector3(0, -9.81, 0)

-- a ball resting on a floor, both added from a coroutine
local made = {}
local co = coroutine.create(function()
  local floor = Cube(10, 1, 10, 0)
  floor.pos = btVector3(0, -0.5, 0)
  v:add(floor)
  local ball = Sphere(1, 1)
  ball.pos = btVector3(0, 0.49, 0)
  v:add(ball)
  made.floor, made.ball = floor, ball
  coroutine.yield()
end)
local ok, err = coroutine.resume(co, "not an object")
check("the coroutine ran", ok, err)

-- one added from the main thread, for comparison
local box = Cube(1, 1, 1, 1)
box.pos = btVector3(4, 0.49, 0)
v:add(box)

for i = 1, 5 do v:stepSimulation(1 / 60, 1, 1 / 60) end

local names = { [made.floor] = "floor", [made.ball] = "ball", [box] = "box" }
local seen, strays = {}, {}
v:eachContact(function(a, b)
  for _, o in ipairs({ a, b }) do
    local n = names[o]
    if n then seen[n] = true else strays[#strays + 1] = tostring(o) end
  end
end)
check("the ball's contact names the ball", seen.ball, nil)
check("the floor's contacts name the floor", seen.floor, nil)
check("the box's contact names the box", seen.box, nil)
check("no contact names anything else", #strays == 0, strays[1])

print(string.format("\n%d passed, %d failed", pass, fail))
