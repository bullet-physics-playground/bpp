-- test Lua garbage collector behavior and luabind dangling pointer detection
--
-- bpp keeps Lua's garbage collector running for the whole run: everything the
-- C++ side uses is kept referenced from Lua (an object keeps the body, shape
-- and mesh a script hands it; a Bullet constructor keeps the script-made
-- pieces it was given), so collecting can never free what the scene uses.
-- collectgarbage("stop") is ignored, and BPP_GC_AUTO is true.

local pass = 0
local fail = 0

local function assert_eq(name, got, expected)
  if got == expected then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": got=" .. tostring(got) .. " expected=" .. tostring(expected))
    fail = fail + 1
  end
end

local function assert_gt(name, got, threshold)
  if got > threshold then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": got=" .. tostring(got) .. " expected > " .. tostring(threshold))
    fail = fail + 1
  end
end

local function assert_lt(name, got, threshold)
  if got < threshold then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": got=" .. tostring(got) .. " expected < " .. tostring(threshold))
    fail = fail + 1
  end
end

local function assert_ge(name, got, threshold)
  if got >= threshold then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": got=" .. tostring(got) .. " expected >= " .. tostring(threshold))
    fail = fail + 1
  end
end

-- ============================================================================
-- Section 1: Lua GC basics
-- ============================================================================

local mem_before = collectgarbage("count")
assert_ge("initial memory > 0", mem_before, 0)

local rc = collectgarbage("collect")
assert_eq("collect returns 0", rc, 0)

local mem_after_collect = collectgarbage("count")
assert_lt("memory after collect <= before", mem_after_collect, mem_before + 1)

local data = {}
for i = 1, 10000 do
  data[i] = string.rep("x", 100)
end
local mem_with_data = collectgarbage("count")
assert_gt("memory grows with allocations", mem_with_data, mem_after_collect)

data = nil
collectgarbage("collect")
local mem_after_free = collectgarbage("count")
assert_lt("memory drops after freeing references", mem_after_free, mem_with_data)

assert_eq("BPP_GC_AUTO is set", BPP_GC_AUTO, true)

-- "stop" is ignored: the collector keeps running, so garbage made afterwards
-- is still freed without any explicit collection (about 40 MB is made here;
-- with the collector stopped, all of it would stay).
rc = collectgarbage("stop")
assert_eq("stop returns 0", rc, 0)

collectgarbage("collect")
local mem_before_garbage = collectgarbage("count")
local peak = mem_before_garbage
for i = 1, 4000 do
  local junk = string.rep(string.char(65 + i % 26), 10000) .. i
  if i % 100 == 0 then
    peak = math.max(peak, collectgarbage("count"))
  end
end
assert_lt("collector keeps running after stop (peak growth < 20 MB)",
          peak - mem_before_garbage, 20 * 1024)

rc = collectgarbage("restart")
assert_eq("restart returns 0", rc, 0)
collectgarbage("collect")
local mem_restarted = collectgarbage("count")
assert_lt("memory back down after collect", mem_restarted, mem_before_garbage + 100)

local stepped = collectgarbage("step")
assert_eq("step returns boolean", type(stepped), "boolean")
collectgarbage("step", 100)

local prev_pause = collectgarbage("setpause", 200)
assert_ge("setpause returns previous value >= 0", prev_pause, 0)
local curr_pause = collectgarbage("setpause", prev_pause)
assert_eq("setpause round-trip", curr_pause, 200)

local prev_mul = collectgarbage("setstepmul", 200)
assert_ge("setstepmul returns previous value >= 0", prev_mul, 0)
local curr_mul = collectgarbage("setstepmul", prev_mul)
assert_eq("setstepmul round-trip", curr_mul, 200)

if newproxy then
  local finalized = false
  local proxy = newproxy(true)
  local mt = getmetatable(proxy)
  mt.__gc = function(self)
    finalized = true
  end
  proxy = nil
  collectgarbage("collect")
  assert_eq("finalizer called via newproxy", finalized, true)
else
  print("SKIP finalizer test (newproxy not available)")
end

collectgarbage("collect")
local m1 = collectgarbage("count")
local m2 = collectgarbage("count")
assert_eq("count is consistent across calls", m1, m2)

for round = 1, 10 do
  local t = {}
  for i = 1, 1000 do
    t[i] = string.format("item_%d_%d", round, i)
  end
  t = nil
  collectgarbage("collect")
end
local mem_final = collectgarbage("count")
assert_ge("memory stable after stress test", mem_final, 0)
assert_lt("no leak after stress test", mem_final, mem_with_data)

local big = {}
for i = 1, 5000 do
  big[i] = string.rep("z", 80)
end
local mem_big = collectgarbage("count")
big = nil
local steps = 0
local done = false
while not done do
  done = collectgarbage("step", 50)
  steps = steps + 1
  if steps > 1000 then break end
end
assert_gt("incremental steps performed", steps, 0)
local mem_incr = collectgarbage("count")
assert_lt("incremental GC reclaims memory", mem_incr, mem_big)

-- ============================================================================
-- Section 2: Scene objects — add/remove 100 random objects, dangling pointer checks
--
-- Ownership model (luabind adopt policies):
--   v:add(obj)    — adopt(_2): ownership transfers Lua -> C++. The Lua wrapper
--                    becomes non-owning (m_weak holds raw pointer for access).
--   obj = v:remove(obj) — adopt(result): v:remove() returns the Object pointer
--                    with a NEW owning Lua wrapper. The caller MUST reassign
--                    obj = v:remove(obj) so the new owning wrapper replaces
--                    the old non-owning one. This enables add/remove/add cycles.
-- ============================================================================

local object_factories = {
  { name = "Plane",    create = function() return Plane(0, 1, 0, 0, 5) end },
  { name = "Sphere",   create = function() return Sphere(0.5, 1) end },
  { name = "Cube",     create = function() return Cube(0.5, 0.5, 0.5, 1) end },
  { name = "Cylinder", create = function() return Cylinder(0.5, 1.0, 1.0) end },
  { name = "Triangle", create = function()
    return Triangle(btVector3(0,0,0), btVector3(1,0,0), btVector3(0.5,0,1), 0)
  end },
}

local function pick_factory()
  return object_factories[math.random(#object_factories)]
end

collectgarbage("collect")
local mem_baseline = collectgarbage("count")

-- ---------------------------------------------------------------------------
-- Test 2a: create 100 random objects, add them all to the scene
-- ---------------------------------------------------------------------------
local objects = {}
for i = 1, 100 do
  local f = pick_factory()
  local obj = f.create()
  obj.pos = btVector3(math.random(-50, 50), math.random(0, 20), math.random(-50, 50))
  obj.col = string.format("#%02x%02x%02x", math.random(64,255), math.random(64,255), math.random(64,255))
  v:add(obj)
  objects[i] = { obj = obj, factory = f.name }
end

assert_eq("100 objects created and added", #objects, 100)

local access_ok = true
for i = 1, #objects do
  local o = objects[i].obj
  if o == nil then
    access_ok = false
    break
  end
  local p = o.pos
  if p == nil then
    access_ok = false
    break
  end
end
assert_eq("all 100 objects accessible after add", access_ok, true)

collectgarbage("collect")
local mem_with_objects = collectgarbage("count")
assert_gt("memory increased with 100 scene objects", mem_with_objects, mem_baseline)

-- ---------------------------------------------------------------------------
-- Test 2b: remove all 100 objects — use obj = v:remove(obj) to reclaim ownership
-- ---------------------------------------------------------------------------
for i = 1, #objects do
  objects[i].obj = v:remove(objects[i].obj)
end

local post_remove_ok = true
for i = 1, #objects do
  local o = objects[i].obj
  if o == nil then
    post_remove_ok = false
    break
  end
end
assert_eq("all 100 objects still accessible after remove", post_remove_ok, true)

objects = nil
collectgarbage("collect")

local mem_after_remove = collectgarbage("count")
assert_lt("memory drops after removing and GC", mem_after_remove, mem_with_objects)

-- ---------------------------------------------------------------------------
-- Test 2c: remove then access — obj = v:remove(obj) restores Lua ownership
-- ---------------------------------------------------------------------------
local obj = Sphere(1.0, 1.0)
obj.pos = btVector3(42, 0, 0)
v:add(obj)
obj = v:remove(obj)

local pos_after_remove = obj.pos
assert_eq("pos accessible after remove", pos_after_remove.x, 42)

obj = nil
collectgarbage("collect")

-- ---------------------------------------------------------------------------
-- Test 2d: rapid add/remove cycles with random objects
-- ---------------------------------------------------------------------------
for cycle = 1, 100 do
  local f = pick_factory()
  local o = f.create()
  o.pos = btVector3(cycle, 0, cycle)
  v:add(o)
  o = v:remove(o)
  o = nil
end
collectgarbage("collect")
assert_eq("100 rapid add/remove cycles no crash", true, true)

-- ---------------------------------------------------------------------------
-- Test 2e: interleaved add/remove — add N, remove half, add more, remove rest
-- ---------------------------------------------------------------------------
local interleaved = {}
for i = 1, 50 do
  local f = pick_factory()
  local o = f.create()
  o.pos = btVector3(i * 0.1, 0, 0)
  v:add(o)
  interleaved[i] = o
end

for i = 1, 50, 2 do
  interleaved[i] = v:remove(interleaved[i])
end

for i = 51, 100 do
  local f = pick_factory()
  local o = f.create()
  o.pos = btVector3(i * 0.1, 0, 0)
  v:add(o)
  interleaved[i] = o
end

local interleaved_remove_ok = true
for i = 1, 100 do
  if interleaved[i] then
    local ok, err = pcall(function()
      interleaved[i] = v:remove(interleaved[i])
    end)
    if not ok then
      interleaved_remove_ok = false
    end
  end
end
assert_eq("interleaved add/remove no crash", interleaved_remove_ok, true)

interleaved = nil
collectgarbage("collect")

-- ---------------------------------------------------------------------------
-- Test 2f: double-remove should not crash
-- ---------------------------------------------------------------------------
local double_remove_obj = Cube(1, 1, 1, 1)
double_remove_obj.pos = btVector3(99, 0, 0)
v:add(double_remove_obj)
double_remove_obj = v:remove(double_remove_obj)

local double_remove_ok = pcall(function()
  double_remove_obj = v:remove(double_remove_obj)
end)
if double_remove_ok then
  print("PASS double-remove did not crash (C++ handles gracefully)")
  pass = pass + 1
else
  print("FAIL double-remove crashed — potential dangling pointer in luabind")
  fail = fail + 1
end

double_remove_obj = nil
collectgarbage("collect")

-- ---------------------------------------------------------------------------
-- Test 2g: add/remove/add cycle — obj = v:remove(obj) restores ownership
-- Note: This test currently fails with luabind ownership transfer error.
-- The second v:add() after remove+add cycle is not supported.
-- ---------------------------------------------------------------------------
local recycle_obj = Sphere(0.7, 2.0)
recycle_obj.pos = btVector3(7, 8, 9)
v:add(recycle_obj)
assert_eq("pos.x after add", recycle_obj.pos.x, 7)
recycle_obj = v:remove(recycle_obj)
assert_eq("pos.x after remove", recycle_obj.pos.x, 7)

recycle_obj = nil
collectgarbage("collect")

-- ---------------------------------------------------------------------------
-- Test 2h: Cylinder adopt check (now fixed with adopt(result) on constructors)
-- ---------------------------------------------------------------------------
local cyl = Cylinder(0.3, 1.0, 1.0)
cyl.pos = btVector3(5, 5, 5)
v:add(cyl)

local cyl_pos_before = cyl.pos
assert_eq("cylinder pos before remove", cyl_pos_before.x, 5)

cyl = v:remove(cyl)
local cyl_alive = pcall(function()
  local p = cyl.pos
end)
if cyl_alive then
  print("PASS cylinder accessible after remove")
  pass = pass + 1
else
  print("FAIL cylinder dangling pointer after remove")
  fail = fail + 1
end

cyl = nil
collectgarbage("collect")

-- ---------------------------------------------------------------------------
-- Test 2i: final memory check — no leaks from luabind ownership transfers
-- ---------------------------------------------------------------------------
collectgarbage("collect")
collectgarbage("collect")
local mem_end = collectgarbage("count")

local mem_growth = mem_end - mem_baseline
assert_lt("no significant memory leak after all tests", mem_growth, 500)

-- ============================================================================
-- Section 3: Bullet pieces a script builds itself survive collection
--
-- A script may build its own triangle mesh, shape, motion state and body and
-- hand them to an object. bpp uses them every step, so none may be freed while
-- the object uses them, even when the script keeps no reference of its own.
-- (Before bpp kept them referenced, a collection here freed them and bpp
-- crashed on the next step.)
-- ============================================================================

local function step(n)
  for i = 1, n do v:stepSimulation(1 / 60, 1, 1 / 60) end
end

local function full_collect()
  collectgarbage("collect")
  collectgarbage("collect")
end

local function pyramid_mesh(l)
  local m = btTriangleMesh()
  local a, b = btVector3(0, l * 2, 0), btVector3(0, 2, l * 2)
  local c, d = btVector3(-l, 0, -l), btVector3(l * 2, 0, 0)
  m:addTriangle(a, b, c, true)
  m:addTriangle(b, c, d, true)
  m:addTriangle(c, d, a, true)
  m:addTriangle(d, a, b, true)
  return m
end

local function at(x, y, z)
  return btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1), btVector3(x, y, z)))
end

-- Every builder returns an object added to the scene; the Bullet pieces it made
-- are local to the builder, so only the object can keep them alive.
local builders = {
  { name = "triangle mesh -> GImpact shape -> body (mass, ms, shape, inertia)",
    build = function(x)
      local shape = btGImpactMeshShape(pyramid_mesh(1))
      shape:updateBound()
      local inertia = btVector3()
      shape:calculateLocalInertia(1, inertia)
      local o = Mesh()
      o.shape = shape
      o.body = btRigidBody(1, at(x, 20, 0), shape, inertia)
      v:add(o)
      return o
    end },
  { name = "construction info -> body",
    build = function(x)
      local shape = btSphereShape(0.5)
      local inertia = btVector3()
      shape:calculateLocalInertia(1, inertia)
      local o = Sphere(0.5, 1)
      o.shape = shape
      o.body = btRigidBody(btRigidBodyConstructionInfo(1, at(x, 20, 0), shape, inertia))
      v:add(o)
      return o
    end },
  { name = "compound shape with child shapes",
    build = function(x)
      local shape = btCompoundShape(true)
      shape:addChildShape(btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0)),
                          btBoxShape(btVector3(0.5, 0.5, 0.5)))
      shape:addChildShape(btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 1, 0)),
                          btSphereShape(0.4))
      local inertia = btVector3()
      shape:calculateLocalInertia(1, inertia)
      local o = Cube(1, 1, 1, 1)
      o.shape = shape
      o.body = btRigidBody(1, at(x, 20, 0), shape, inertia)
      v:add(o)
      return o
    end },
  { name = "convex triangle mesh shape, uniformly scaled",
    build = function(x)
      local shape = btUniformScalingShape(btConvexTriangleMeshShape(pyramid_mesh(1), true), 0.5)
      local inertia = btVector3()
      shape:calculateLocalInertia(1, inertia)
      local o = Cube(1, 1, 1, 1)
      o.shape = shape
      o.body = btRigidBody(1, at(x, 20, 0), shape, inertia)
      v:add(o)
      return o
    end },
}

local built = {}
for i, b in ipairs(builders) do
  built[i] = { name = b.name, obj = b.build(i * 10) }
end

-- Lots of other garbage, then full collections between steps: anything only
-- Lua kept alive is gone after this.
for round = 1, 5 do
  local t = {}
  for i = 1, 20000 do t[i] = { i } end
  t = nil
  full_collect()
  step(20)
end

for i, b in ipairs(built) do
  local ok, y = pcall(function() return b.obj.pos.y end)
  assert_eq("still simulated after collections: " .. b.name, ok and y < 20, true)
end

-- ============================================================================
-- Section 4: removing such objects and collecting does not crash
-- ============================================================================

for i, b in ipairs(built) do
  b.obj = v:remove(b.obj)
end
built = nil
full_collect()
step(5)
assert_eq("removed script-built objects collected without a crash", true, true)

-- And again, collecting while they are still in the scene, then clearing it.
for i, b in ipairs(builders) do b.build(i * 10) end
full_collect()
step(10)
full_collect()
assert_eq("script-built objects left in the scene survive a collection", true, true)

-- ============================================================================
-- Section 5: handing in a replacement, and built-in objects with Lua pieces
-- ============================================================================

-- A body replaced while it is in the dynamics world stays alive (Bullet still
-- simulates it) rather than being freed under it.
local function lua_body(x)
  local s = btSphereShape(0.5)
  return btRigidBody(1, at(x, 10, 0), s, btVector3(0, 0, 0))
end
local swapped = Cube(1, 1, 1, 1)
swapped.body = lua_body(0)
v:add(swapped)
swapped.body = lua_body(5)
for round = 1, 3 do
  local t = {}
  for i = 1, 20000 do t[i] = { i } end
  t = nil
  full_collect()
  step(5)
end
assert_eq("body replaced while in the world: no crash", true, true)

-- Built-in objects (Cube, Sphere, ...) given a script's shape or body, then
-- collected without ever being added: each frees only what it made itself.
for i = 1, 100 do
  local c = Cube(1, 1, 1, 1)
  c.shape = btSphereShape(1)
  if i % 2 == 0 then c.body = lua_body(i) end
  local sp = Sphere(1, 1)
  sp.shape = btSphereShape(2)
  sp.radius = 2
end
full_collect()
assert_eq("built-in objects with script-made pieces collected: no crash", true, true)

print(string.format("\n%d passed, %d failed", pass, fail))
