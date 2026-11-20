-- The motion state bpp makes for a script's body (obj.body = btRigidBody(...),
-- then obj.pos or obj.trans) when the object goes before the
-- script ends. The body is Lua's and frees no motion state, and the object
-- left it, so it leaked (an intermittent leak in Euler's Gallery, as the
-- collector happened to run). It goes with the script's other motion states
-- now -- and once only, though two objects shared the body and one freed it
-- first. The sanitizer job checks for the leak and a double free; here, that
-- the objects work.

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

local function at(x, y, z) return btTransform(btQuaternion(0, 0, 0, 1), btVector3(x, y, z)) end
local function body() return btRigidBody(1, btDefaultMotionState(at(0, 5, 0)), btSphereShape(1), btVector3(1, 1, 1)) end

-- objects with script-made bodies, moved each way, then collected
for i = 1, 3 do
  local o = Sphere(1, 1)
  o.body = body()
  o.trans = at(i, 2, 0)
  o.pos = btVector3(i, 3, 0)
  check("moved #" .. i, math.abs(o.pos.y - 3) < 1e-4, tostring(o.pos.y))
end
collectgarbage(); collectgarbage()

-- one body, two objects: the first goes, the second moves it on and goes too
do
  local b = body()
  local o1 = Sphere(1, 1); o1.body = b; o1.pos = btVector3(0, 1, 0)
  local o2 = Sphere(1, 1); o2.body = b
  o1 = nil
  collectgarbage(); collectgarbage()
  o2.pos = btVector3(0, 7, 0)   -- (frees the motion state o1 left)
  check("shared body moved on", math.abs(o2.pos.y - 7) < 1e-4, tostring(o2.pos.y))
  o2 = nil
  collectgarbage(); collectgarbage()
end

-- and one added, removed and collected
do
  local o = Sphere(1, 1)
  o.body = body()
  o.pos = btVector3(4, 2, 0)
  v:add(o)
  v:remove(o)
  o = nil
  collectgarbage(); collectgarbage()
end

v:stepSimulation(1 / 60, 1, 1 / 60)
check("stepped", true)

print(string.format("\n%d passed, %d failed", pass, fail))
