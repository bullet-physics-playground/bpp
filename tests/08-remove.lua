-- test removing objects, and replacing an object's body or shape
--
-- v:add(obj) hands the object to bpp. v:remove(obj) takes it out of the
-- scene and gives it back to the script: once the script lets go of it
-- (and of its body or shape), it is freed, and memory doesn't grow however
-- many objects a script removes. An object the script still holds, or
-- still reaches through its body or shape, or that a constraint in the
-- world still uses, stays.
--
-- Replacing an object's body while it is in the scene puts the new body in
-- the world in place of the old one. Replacing an object's shape never
-- frees a shape that a body still uses, nor the shape a Mesh shares with
-- other Meshes loaded from the same file.

local pass = 0
local fail = 0

local function check(name, ok, detail)
  if ok then
    io.stderr:write("PASS " .. name .. "\n")
    pass = pass + 1
  else
    io.stderr:write("FAIL " .. name .. (detail and (": " .. detail) or "") .. "\n")
    fail = fail + 1
  end
end

local function step(n)
  for i = 1, n do v:stepSimulation(1 / 60, 1, 1 / 60) end
end

local function full_collect()
  collectgarbage("collect")
  collectgarbage("collect")
end

-- bpp's own memory, from /proc (Linux); nil elsewhere
local function rss()
  local f = io.open("/proc/self/status")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return tonumber(s:match("VmRSS:%s+(%d+)"))
end

local function at(x, y, z)
  return btTransform(btQuaternion(0, 0, 0, 1), btVector3(x, y, z))
end

-- ---------------------------------------------------------------------------
-- 1: removed objects are freed (memory stays flat)
-- ---------------------------------------------------------------------------

local makers = {
  cube = function(i)
    local o = Cube(1, 1, 1, 1)
    o.pos = btVector3(i % 20, 5, 0)
    return o
  end,
  terrain = function()
    local o = Terrain()
    for x = 0, 19 do for z = 0, 19 do
      o:addTriangle(btVector3(x, 0, z), btVector3(x, 0, z + 1), btVector3(x + 1, 0, z))
      o:addTriangle(btVector3(x + 1, 0, z), btVector3(x, 0, z + 1), btVector3(x + 1, 0, z + 1))
    end end
    o:build()
    return o
  end,
}

for _, kind in ipairs({ "cube", "terrain" }) do
  local make = makers[kind]
  local function round(n)
    local live = {}
    for i = 1, n do
      local o = make(i)
      v:add(o)
      live[i] = o
    end
    step(1)
    for i = 1, n do v:remove(live[i]) end
    live = nil
    full_collect()
    step(1)
  end
  for r = 1, 5 do round(200) end            -- (settle)
  full_collect(); step(1)
  local before = rss()
  for r = 1, 30 do round(200) end
  full_collect(); step(1)
  local after = rss()
  if before and after then
    local per = (after - before) * 1024 / (30 * 200)
    check(string.format("removed %s objects are freed (%.0f bytes each kept)", kind, per), per < 200,
          string.format("%d KB -> %d KB", before, after))
  end
end

-- ---------------------------------------------------------------------------
-- 2: what the script still holds stays usable
-- ---------------------------------------------------------------------------

-- the object itself, removed and added again many times
local o = Cube(1, 1, 1, 1)
o.pos = btVector3(3, 4, 5)
for i = 1, 200 do
  v:add(o)
  step(1)
  o = v:remove(o)
  full_collect()
end
check("an object held by the script survives remove/add cycles", o.pos.y < 4.0001)
v:add(o)
step(5)
check("... and is simulated again when added back", o.pos.y < 4)
v:remove(o)
o = nil

-- only its body (the object itself let go of)
local bodies = {}
for i = 1, 50 do
  local c = Cube(1, 1, 1, 1)
  c.pos = btVector3(i, 7, 0)
  v:add(c)
  bodies[i] = c.body
  v:remove(c)
end
full_collect()
step(2)
full_collect()
local okb = true
for i = 1, 50 do
  local p = bodies[i]:getCenterOfMassPosition()
  if math.abs(p.x - i) > 1e-3 or math.abs(p.y - 7) > 1e-3 then okb = false end
end
check("a removed object's body stays usable while the script holds it", okb)
bodies = nil
full_collect()
step(2)

-- only its shape
local shapes = {}
for i = 1, 50 do
  local c = Sphere(0.5, 1)
  v:add(c)
  shapes[i] = c.shape
  v:remove(c)
end
full_collect()
step(2)
local oks = true
for i = 1, 50 do
  local ok = pcall(function() return shapes[i]:getName() end)
  if not ok then oks = false end
end
check("a removed object's shape stays usable while the script holds it", oks)
shapes = nil

-- a hinge still in the world, after both its objects are removed and let go of
do
  local a, b = Cube(1, 1, 1, 1), Cube(1, 1, 1, 1)
  a.pos = btVector3(0, 20, 0)
  b.pos = btVector3(0, 18, 0)
  v:add(a)
  v:add(b)
  local h = btHingeConstraint(a.body, b.body, btVector3(0, -1, 0), btVector3(0, 1, 0),
                              btVector3(0, 0, 1), btVector3(0, 0, 1))
  v:addConstraint(h)
  v:remove(a)
  v:remove(b)
  a, b = nil, nil
  for i = 1, 3 do full_collect(); step(5) end
  check("objects removed while a constraint in the world uses them: no crash", true)
  v:removeConstraint(h)
  h = nil
  for i = 1, 3 do full_collect(); step(5) end
  check("... nor once the constraint is removed too", true)
end

-- removed and kept only in a table, then added back
do
  local spare = {}
  for i = 1, 30 do
    local c = Cube(1, 1, 1, 1)
    c.pos = btVector3(i, 30, 0)
    v:add(c)
    spare[i] = v:remove(c)
  end
  full_collect()
  step(2)
  for i = 1, 30 do v:add(spare[i]) end
  step(10)
  local fell = true
  for i = 1, 30 do if not (spare[i].pos.y < 30) then fell = false end end
  check("objects kept in a table after removal can be added back", fell)
  for i = 1, 30 do v:remove(spare[i]) end
  spare = nil
  full_collect()
  step(1)
end

-- an object removed twice, and one never added
do
  local c = Cube(1, 1, 1, 1)
  v:add(c)
  v:remove(c)
  v:remove(c)
  local d = Cube(1, 1, 1, 1)
  v:remove(d)
  c, d = nil, nil
  full_collect()
  step(1)
  check("removing twice, or removing what was never added: no crash", true)
end

-- removed through the handle v:eachContact gave, while the script keeps the
-- one it made (every handle bpp gives a script for an object is that one)
do
  local floor = Cube(400, 1, 400, 0)
  floor.pos = btVector3(0, -0.5, -300)
  v:add(floor)
  local keep = {}
  for i = 1, 5 do
    local c = Cube(1, 1, 1, 1)
    c.pos = btVector3(i * 3, 0.5, -300)
    v:add(c)
    keep[i] = c
  end
  step(30)
  local seen = {}
  v:eachContact(function(a, b)
    if a and a ~= floor then seen[a] = true end
    if b and b ~= floor then seen[b] = true end
  end)
  local same = true
  for h in pairs(seen) do
    local found = false
    for i = 1, 5 do if rawequal(h, keep[i]) then found = true end end
    if not found then same = false end
    v:remove(h)
  end
  check("v:eachContact hands the script the objects' own handles", same and next(seen) ~= nil)
  seen = nil
  full_collect()
  step(2)
  local ok = true
  for i = 1, 5 do
    keep[i].pos = btVector3(0, 99, -300)
    if math.abs(keep[i].pos.y - 99) > 1e-3 then ok = false end
  end
  check("... so an object removed through one stays usable through the other", ok)
  for i = 1, 5 do v:remove(keep[i]) end
  v:remove(floor)
  keep, floor = nil, nil
  full_collect()
  step(1)
end

-- ---------------------------------------------------------------------------
-- 3: replacing a body while the object is in the scene
-- ---------------------------------------------------------------------------

do
  local c = Cube(1, 1, 1, 1)
  c.pos = btVector3(50, 10, 0)
  v:add(c)
  step(1)
  local old = c.body
  local s = btSphereShape(0.5)
  local inertia = btVector3(0, 0, 0)
  s:calculateLocalInertia(1, inertia)
  c.body = btRigidBody(1, btDefaultMotionState(at(60, 10, 0)), s, inertia)
  step(30)
  check("a replaced body leaves the world", not old:isInWorld())
  check("the new body is in the world in its place", c.body:isInWorld())
  check("... and is simulated (it falls)", c.pos.y < 9.9)
  v:remove(c)
  check("removing the object takes the new body out of the world", not c.body:isInWorld())
  c, old = nil, nil
  full_collect()
  step(1)
end

-- a body a hinge in the world joins: the world is left as it is (Bullet
-- can't step a constraint whose body has left it), and removing the object
-- and the hinge afterwards is safe
do
  local a, b = Cube(1, 1, 1, 1), Cube(1, 1, 1, 1)
  a.pos = btVector3(0, 20, 300)
  b.pos = btVector3(0, 18, 300)
  v:add(a)
  v:add(b)
  local h = btHingeConstraint(a.body, b.body, btVector3(0, -1, 0), btVector3(0, 1, 0),
                              btVector3(0, 0, 1), btVector3(0, 0, 1))
  v:addConstraint(h)
  local old = a.body
  local s = btSphereShape(0.5)
  local inertia = btVector3(0, 0, 0)
  s:calculateLocalInertia(1, inertia)
  a.body = btRigidBody(1, btDefaultMotionState(at(5, 20, 300)), s, inertia)
  step(30)
  check("a body a hinge in the world joins stays in the world when replaced", old:isInWorld())
  old = nil
  v:remove(a)
  a = nil
  for i = 1, 3 do full_collect(); step(5) end
  v:removeConstraint(h)
  h = nil
  for i = 1, 3 do full_collect(); step(5) end
  v:remove(b)
  b = nil
  full_collect()
  step(1)
  check("... and removing the object, then the hinge: no crash", true)
end

-- the same with bodies the script made itself: one swapped in, a hinge on
-- it, then another (the first stays in the world for the hinge), then the
-- object removed and let go of
do
  local function mk(x)
    local s = btSphereShape(0.5)
    local inertia = btVector3(0, 0, 0)
    s:calculateLocalInertia(1, inertia)
    return btRigidBody(1, btDefaultMotionState(at(x, 20, 400)), s, inertia)
  end
  local a, b = Cube(1, 1, 1, 1), Cube(1, 1, 1, 1)
  b.pos = btVector3(0, 18, 400)
  v:add(a)
  v:add(b)
  a.body = mk(0)
  local h = btHingeConstraint(a.body, b.body, btVector3(0, -1, 0), btVector3(0, 1, 0),
                              btVector3(0, 0, 1), btVector3(0, 0, 1))
  v:addConstraint(h)
  a.body = mk(5)
  v:remove(a)
  a = nil
  for i = 1, 4 do full_collect(); step(1) end
  local junk = {}
  for i = 1, 3000 do junk[i] = btSphereShape(1) end
  junk = nil
  step(30)
  v:removeConstraint(h)
  v:remove(b)
  h, b = nil, nil
  for i = 1, 3 do full_collect(); step(2) end
  check("script-made bodies replaced around a hinge, then the object removed: no crash", true)
end

-- ---------------------------------------------------------------------------
-- 4: replacing a shape
-- ---------------------------------------------------------------------------

-- a built-in object's own shape, replaced while its body uses it
do
  local c = Cube(1, 1, 1, 1)
  c.pos = btVector3(70, 2, 0)
  v:add(c)
  c.shape = btSphereShape(0.5)
  for i = 1, 3 do full_collect(); step(20) end
  check("a built-in object's shape replaced while its body uses it: no crash", true)
  v:remove(c)
  c = nil
  full_collect()
  step(1)
end

-- the shape a Mesh shares with every Mesh from the same file
do
  local m1 = Mesh("demo/mesh/torus.stl", 1)
  local m2 = Mesh("demo/mesh/torus.stl", 1)
  m1.pos = btVector3(100, 5, 0)
  m2.pos = btVector3(150, 10, 0)
  v:add(m1)
  v:add(m2)
  step(5)
  local tm = btTriangleMesh()
  tm:addTriangle(btVector3(0, 0, 0), btVector3(1, 0, 0), btVector3(0, 0, 1), true)
  local gs = btGImpactMeshShape(tm)
  gs:updateBound()
  m1.shape = gs
  for i = 1, 3 do full_collect(); step(20) end
  local m3 = Mesh("demo/mesh/torus.stl", 1)
  m3.pos = btVector3(200, 5, 0)
  v:add(m3)
  step(20)
  check("a Mesh's shared shape replaced on one Mesh: the others and new ones still work", m2.pos.y < 10 and m3.pos.y < 5,
        string.format("y %.2f, %.2f", m2.pos.y, m3.pos.y))
  v:remove(m1); v:remove(m2); v:remove(m3)
  m1, m2, m3 = nil, nil, nil
  full_collect()
  step(1)
end

print(string.format("\n%d passed, %d failed", pass, fail))
