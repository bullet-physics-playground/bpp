--
-- EULER'S CABINET OF CURIOSITIES -- an 18th-century walnut gallery for the
-- Bullet Physics Playground, L-shaped, holding WyomingWill's rigid-body
-- curiosities: the gombocs, Bille and the weighted polyhedra, the
-- Dzhanibekov effect, the rattleback, the tippe top, the chain fountain,
-- and bays waiting for the next ones.
--
-- Only the exhibit you are standing at runs. Walk away and it stops where
-- it is, mid-air if need be; come back and it carries on from there.
--
-- KEYS (click the 3D view first so it has the keyboard):
--   Tab         walk to the next exhibit (and the two views down the hall)
--   Shift+Tab   walk back
--   everything else goes to the exhibit you're at, with the same keys as
--   when it runs on its own; the Shortcuts pane shows them.
--   Rest the mouse on an exhibit, a placard or a covered bay to see what it is.
--
-- MORE EXHIBITS: one line each in EXHIBITS, below. A line whose script
-- isn't there yet becomes a covered bay with its placard ("in
-- preparation"); when the script turns up, the bay comes to life. The hall
-- grows to fit: add lines and both wings get longer.
--
-- HOW IT WORKS: each exhibit is the unchanged script, loaded into a sandbox
-- of its own (its own set of globals) that moves everything it builds to
-- its bay and moves everything it reads back again, so its own sums still
-- hold; finds its files in its own folder; gives its bodies its own gravity;
-- keeps its sliders apart (named "Exhibit: slider" in the Params pane); and
-- collects its per-frame callbacks, keys and help, which this file passes on
-- only while you're at it. Its ground plane is left out (the hall's floor
-- stands in for it, at the same height). The exhibits you're not at have
-- their moving bodies taken out of the simulation (they keep their
-- velocities) and their callbacks aren't called, so they cost nothing.
--
-- UNITS: centimetres; the floor is at y = 0.
--

local realV = v
local realCube, realSphere, realCylinder, realMesh = Cube, Sphere, Cylinder, Mesh
local realCone = Cone
local unpack = unpack or table.unpack

local function findDir(cands, file)
  for _, d in ipairs(cands) do
    local f = io.open(d .. file, "r")
    if f then f:close(); return d end
  end
  error("Euler's Cabinet: can't find " .. file)
end
local HERE = findDir({ "./", "demo/WyomingWill/Cabinet/" }, "cabinet.lua")
local MESH = HERE .. "cabinet-meshes/"
local LABELS = dofile(MESH .. "labels.lua")

-- ---------------------------------------------------------------------
-- the exhibits, in the order you walk past them
-- ---------------------------------------------------------------------
--   dir, file  the script (dir from this folder). Not there: a covered bay.
--   name       what the header and Tab call it
--   label      its placard (a key of cabinet-meshes/labels.lua)
--   prefix     its sliders in the Params pane are named prefix .. name
--   floorY     the height of its own ground plane, in its own units: that
--              is where the hall's floor goes
--   stand      { w, d }: a walnut stand under it, up to its own y = -4 (for
--              the trays, which float above their ground plane on their own)
--   about      what the placard says when the mouse rests on it
EXHIBITS = EXHIBITS or {
  { dir = "../Gomboc/", file = "gomboc-drop-c.lua", name = "Gömböc Drop C", label = "gomboc-drop-c",
    prefix = "Drop C: ", floorY = -80, stand = { 172, 145 },
    about = "Gömböc Drop C: the Gömböc, the convex body of uniform density with one stable\n" ..
            "and one unstable balance point, dropped at random until it rights itself." },
  { dir = "../Gomboc/", file = "gomboc-variety.lua", name = "Gömböc Variety", label = "gomboc-variety",
    prefix = "Variety: ", floorY = -80, stand = { 172, 145 },
    about = "Gömböc Variety: Gomboc-C at three sizes and the lumpier Sloan beta shapes,\n" ..
            "all of uniform density. The white dot is each one's balancing point." },
  { dir = "../Bille/", file = "bille-drop.lua", name = "Bille and the polyhedra", label = "bille",
    prefix = "Bille: ", floorY = -80, stand = { 272, 210 },
    about = "Bille Drop: the weighted monostable tetrahedron (Bille) and the 21-, 26- and\n" ..
            "37-corner spiral polyhedra. An edge lights up when it lands on the table." },
  { dir = "../Dzhanibekov/", file = "dzhanibekov.lua", name = "the Dzhanibekov effect", label = "dzhanibekov",
    prefix = "Dzhanibekov: ", floorY = 0,
    about = "The Dzhanibekov effect: three T-handles spinning in zero gravity. Spun about\n" ..
            "the middle axis, the handle flips over and back, again and again." },
  { dir = "../Rattleback/", file = "rattleback.lua", name = "the rattlebacks", label = "rattleback",
    prefix = "Rattleback: ", floorY = -75,
    about = "The rattleback: spun one way it spins; spun the other way it wobbles,\n" ..
            "stops and spins back." },
  { dir = "../TippeTop/", file = "tippe-top.lua", name = "the tippe tops", label = "tippe-top",
    prefix = "Tippe top: ", floorY = -75,
    about = "The tippe top: spin it on its ball and it turns itself over onto its stem,\n" ..
            "raising its centre of mass as it goes." },
  { dir = "../ChainFountain/", file = "chain-fountain.lua", name = "the chain fountain", label = "chain-fountain",
    prefix = "Fountain: ", floorY = 0,
    about = "The chain fountain (the Mould effect): a bead chain pouring out of a jar\n" ..
            "rises in an arch above the rim on its way to the floor." },
  { dir = "../SpinningEgg/", file = "spinning-egg.lua", name = "the spinning egg", label = "spinning-egg",
    about = "Coming: the spinning egg. A hard-boiled egg spun fast on its side\nrises up onto its end." },
  { dir = "../DoubleCone/", file = "double-cone.lua", name = "the double cone", label = "double-cone",
    about = "Coming: the double cone. Two cones joined at their bases roll 'uphill'\n" ..
            "along a V-shaped ramp, though their centre of mass goes down." },
  { dir = "../Oloid/", file = "oloid.lua", name = "the oloid and the sphericon", label = "oloid",
    about = "Coming: the oloid and the sphericon, rollers that touch the floor with\n" ..
            "their whole surface as they wobble along a winding path." },
  { dir = "../Slinky/", file = "falling-slinky.lua", name = "the falling Slinky", label = "slinky",
    about = "Coming: the falling Slinky. Let a hanging Slinky go, and its bottom\n" ..
            "hangs still in mid-air until the top crashes into it." },
  { dir = "../BrazilNut/", file = "brazil-nut.lua", name = "the Brazil-nut effect", label = "brazil-nut",
    about = "Coming: the Brazil-nut effect. Shake a box of mixed grains and the big\n" ..
            "ones come up to the top." },
  { dir = "../NewtonsCradle/", file = "newtons-cradle.lua", name = "Newton's cradle", label = "newtons-cradle",
    about = "Coming: Newton's cradle, a row of steel balls passing momentum along the line." },
}
-- empty bays at the far end, for ideas still to come
SPARE_BAYS = SPARE_BAYS or 3

-- ---------------------------------------------------------------------
-- the hall's plan: an L. Wing A runs north from the entrance (+z) to the
-- corner; wing B runs east from the corner. Bays down both sides of each.
-- ---------------------------------------------------------------------
local BAY_W, BAY_D, AISLE = 420, 330, 340      -- a bay's width along the wing, its depth; the aisle
local WW = 2 * BAY_D + AISLE                    -- a wing's width (1000)
local HW = WW / 2
local H = 460                                   -- the ceiling
local NBAYS = #EXHIBITS + SPARE_BAYS
local ROWS_A = math.ceil(math.ceil(NBAYS / 2) / 2)    -- rows of two bays in wing A
local ROWS_B = math.ceil((NBAYS - 2 * ROWS_A) / 2)
local LA, LB = ROWS_A * BAY_W, ROWS_B * BAY_W   -- the wings' lengths, past the corner
local XE = HW + LB                              -- wing B's far wall
local ZS = LA                                   -- the entrance wall
local ZN = -WW                                  -- the corner's north wall

-- the bays, in walking order: each { x, z, a } with a the way it faces
-- (0: toward +z), and the aisle side of it
local function rot(a, dx, dz) return dx * math.cos(a) + dz * math.sin(a), -dx * math.sin(a) + dz * math.cos(a) end
local BAYS = {}
for k = 0, ROWS_A - 1 do
  local z = ZS - BAY_W / 2 - k * BAY_W
  BAYS[#BAYS + 1] = { x = -HW + BAY_D / 2, z = z, a = math.pi / 2, wing = "A" }    -- west side, facing east
  BAYS[#BAYS + 1] = { x = HW - BAY_D / 2, z = z, a = -math.pi / 2, wing = "A" }    -- east side, facing west
end
for k = 0, ROWS_B - 1 do
  local x = HW + BAY_W / 2 + k * BAY_W
  BAYS[#BAYS + 1] = { x = x, z = ZN + BAY_D / 2, a = 0, wing = "B" }               -- north side, facing south
  BAYS[#BAYS + 1] = { x = x, z = -BAY_D / 2, a = math.pi, wing = "B" }             -- south side, facing north
end

-- ---------------------------------------------------------------------
-- physics: whichever exhibit you're at gets its own settings
-- ---------------------------------------------------------------------
local BPP_PHYSICS = { timeStep = 1 / 25, fixedTimeStep = 1 / 100, maxSubSteps = 7,
                      iterations = 10, erp = 0.2, erp2 = 0.2, cfm = 0, animationPeriod = 16 }
local IDLE = { timeStep = 1 / 60, fixedTimeStep = 1 / 60, maxSubSteps = 1,
               iterations = 10, erp = 0.2, erp2 = 0.2, cfm = 0, animationPeriod = 16 }
local function applyPhysics(p)
  realV.timeStep, realV.fixedTimeStep, realV.maxSubSteps = p.timeStep, p.fixedTimeStep, p.maxSubSteps
  if realV.setSolverIterations then realV:setSolverIterations(p.iterations) end
  realV:setErp(p.erp)
  realV:setErp2(p.erp2)
  if realV.setCfm then realV:setCfm(p.cfm) end
  if realV.animationPeriod then realV.animationPeriod = p.animationPeriod or 16 end
end
realV.gravity = btVector3(0, -981, 0)

-- ---------------------------------------------------------------------
-- the sandboxes
-- ---------------------------------------------------------------------
local exhibits = {}        -- the live ones, in walking order
local active = nil         -- the exhibit you're at (nil: one of the views)
local loading = nil        -- the exhibit being loaded

local function loadIn(file, env)
  if setfenv then
    local f, err = loadfile(file)
    if f then setfenv(f, env) end
    return f, err
  end
  return loadfile(file, "t", env)
end
local function exists(path)
  local fh = io.open(path, "rb")
  if fh then fh:close() return true end
  return false
end
-- roots to look in for files named from bpp's own folder
local ROOTS = {}
for entry in package.path:gmatch("[^;]+") do
  local d = entry:match("^(.*[/\\])module[/\\]%?%.lua$")
  if d then ROOTS[#ROOTS + 1] = d; ROOTS[#ROOTS + 1] = d .. "../"; ROOTS[#ROOTS + 1] = d .. "../../" end
end
local ident = btQuaternion(0, 0, 0, 1)
local function shiftT(t, by) local o = btTransform(); o:mult(by, t); return o end
local function real(o) return type(o) == "table" and rawget(o, "__real") or o end
local function unwrapAll(...)
  local n = select("#", ...)
  local a = { ... }
  for i = 1, n do a[i] = real(a[i]) end
  return unpack(a, 1, n)
end

local CALLBACKS = { preSim = true, postSim = true, preDraw = true, postDraw = true, onKey = true,
                    onParamChanged = true, onCommand = true, onJoystick = true, onSpaceNavigator = true,
                    onHover = true, cycleObject = true }
local TIMING = { timeStep = true, fixedTimeStep = true, maxSubSteps = true, animationPeriod = true }

-- a body's methods that take or give directions (turned with the exhibit)
local DIR_IN = { setLinearVelocity = true, setAngularVelocity = true, applyCentralImpulse = true,
                 applyCentralForce = true, applyTorque = true, applyTorqueImpulse = true, setGravity = true,
                 applyForce = true, applyImpulse = true }
local DIR_OUT = { getLinearVelocity = true, getAngularVelocity = true, getGravity = true,
                  getTotalForce = true, getTotalTorque = true }

local function makeExhibit(e, offset, turn)
  local g = { e = e, name = e.name, dir = e.dir, off = offset, callbacks = {}, shortcuts = {},
              help = "", down = {}, dyn = {}, physics = {}, N = 0, prefix = e.prefix or (e.name .. ": "),
              vset = {}, view = {}, turn = turn or 0 }
  for k, val in pairs(BPP_PHYSICS) do g.physics[k] = val end
  -- placed at offset, turned by `turn` about the upright (its +z, the side
  -- it's seen from on its own, faces its bay's aisle)
  local ox, oy, oz = offset.x, offset.y, offset.z
  local t = turn or 0
  local cs, sn = math.cos(t), math.sin(t)
  local turned = (t ~= 0)
  local QROT, QINV = btQuaternion(btVector3(0, 1, 0), t), btQuaternion(btVector3(0, 1, 0), -t)
  local OFF = btTransform(QROT, offset)
  local INV = OFF:inverse()
  local function toWorld(p) return btVector3(p.x * cs + p.z * sn + ox, p.y + oy, -p.x * sn + p.z * cs + oz) end
  local function toLocal(q)
    local x, z = q.x - ox, q.z - oz
    return btVector3(x * cs - z * sn, q.y - oy, x * sn + z * cs)
  end
  -- directions (velocities, spins, forces, gravity): turned, not moved
  local function dirW(p) if not turned then return p end return btVector3(p.x * cs + p.z * sn, p.y, -p.x * sn + p.z * cs) end
  local function dirL(p) if not turned then return p end return btVector3(p.x * cs - p.z * sn, p.y, p.x * sn + p.z * cs) end
  g.dirW, g.dirL = dirW, dirL
  g.toWorld, g.toLocal = toWorld, toLocal
  local dir = e.dir
  local function fix(path)
    if type(path) ~= "string" or path:sub(1, 1) == "/" or path:match("^%a:[/\\]") then return path end
    if exists(dir .. path) then return dir .. path end
    if exists(path) then return path end
    local bare = path:gsub("^[%./\\]*", "")
    for _, r in ipairs(ROOTS) do
      if exists(r .. path) then return r .. path end
      if exists(r .. bare) then return r .. bare end
    end
    return dir .. path
  end

  -- its gravity, on its own bodies
  local function applyGravity(body)
    if g.gravity then pcall(function() body:setGravity(dirW(g.gravity)) end) end
  end

  -- a rigid body it made itself: transforms through the offset
  local bodyMeta = {
    __index = function(p, k)
      local r = rawget(p, "__real")
      local fn
      if k == "setCenterOfMassTransform" or k == "setWorldTransform" then
        local f = r[k]
        fn = function(_, t) return f(r, shiftT(t, OFF)) end
      elseif k == "getCenterOfMassTransform" or k == "getWorldTransform" then
        local f = r[k]
        fn = function(_) return shiftT(f(r), INV) end
      elseif k == "getCenterOfMassPosition" then
        fn = function(_) return toLocal(r:getCenterOfMassPosition()) end
      elseif turned and DIR_IN[k] then
        local f = r[k]
        fn = function(_, a, b) if b ~= nil then return f(r, dirW(a), dirW(b)) end return f(r, dirW(a)) end
      elseif turned and DIR_OUT[k] then
        local f = r[k]
        fn = function(_) return dirL(f(r)) end
      elseif turned and k == "getVelocityInLocalPoint" then
        local f = r[k]
        fn = function(_, a) return dirL(f(r, dirW(a))) end
      elseif turned and k == "getOrientation" then
        local f = r[k]
        fn = function(_) return QINV * f(r) end
      else
        local val = r[k]
        if type(val) ~= "function" then return val end
        fn = function(_, ...) return val(r, unwrapAll(...)) end
      end
      rawset(p, k, fn)
      return fn
    end,
  }
  local function wrapBody(b) return setmetatable({ __real = b }, bodyMeta) end

  -- an object it made: positions through the offset
  local objMeta = {
    __index = function(p, k)
      local r = rawget(p, "__real")
      if k == "pos" then return toLocal(r.pos) end
      if k == "trans" then return shiftT(r.trans, INV) end
      if k == "body" then
        local b = rawget(p, "__body")
        if b then return b end
        local ok, rb = pcall(function() return r.body end)
        if ok and rb then b = wrapBody(rb); rawset(p, "__body", b) end
        return b
      end
      local val = r[k]
      if type(val) == "function" then
        local fn = function(self, ...) return val(r, unwrapAll(...)) end
        rawset(p, k, fn)
        return fn
      end
      return val
    end,
    __newindex = function(p, k, val)
      local r = rawget(p, "__real")
      if k == "pos" then r.pos = toWorld(val)
      elseif k == "trans" then r.trans = shiftT(val, OFF)
      elseif k == "body" then
        if type(val) == "table" then rawset(p, "__body", val) else rawset(p, "__body", val and wrapBody(val) or nil) end
        r.body = real(val)
      else r[k] = val end
    end,
  }
  local function wrap(o)
    pcall(function() o.trans = OFF end)          -- (made at its own origin, square to it)
    return setmetatable({ __real = o }, objMeta)
  end

  -- the camera: moved by the offset; what it sets as it loads is kept as
  -- its view (the hall turns that to face its bay's aisle)
  local camFns = {}
  local cam = setmetatable({}, {
    __index = function(_, k)
      local c = realV.cam
      if k == "pos" or k == "look" then return toLocal(c[k]) end
      local val = c[k]
      if type(val) == "function" then
        local fn = camFns[k]
        if not fn then
          fn = function(self, ...) if active == g or loading == g then return val(realV.cam, ...) end end
          camFns[k] = fn
        end
        return fn
      end
      return val
    end,
    __newindex = function(_, k, val)
      if k == "pos" or k == "look" then
        if loading == g then g.view[k] = val
        elseif active == g then realV.cam[k] = toWorld(val) end
        return
      end
      if active == g or loading == g then realV.cam[k] = val end
    end,
  })

  -- the viewer, as the exhibit sees it
  local vpFns = {}
  local special = {
    add = function(_, o)
      if type(o) == "table" and rawget(o, "__dummy") then return end
      local r = real(o)
      realV:add(r)
      local ok, body = pcall(function() return r.body end)
      if ok and body then
        applyGravity(body)
        if not body:isStaticObject() then g.dyn[r] = body end
      end
    end,
    remove = function(_, o)
      if type(o) == "table" and rawget(o, "__dummy") then return end
      local r = real(o)
      g.dyn[r] = nil
      realV:remove(r)
    end,
    addConstraint = function(_, c, ...) return realV:addConstraint(real(c), ...) end,
    removeConstraint = function(_, c, ...) return realV:removeConstraint(real(c), ...) end,
    setCfm = function(_, x) g.physics.cfm = x end,
    setErp = function(_, x) g.physics.erp = x end,
    setErp2 = function(_, x) g.physics.erp2 = x end,
    setSolverIterations = function(_, n) g.physics.iterations = n end,
    addShortcut = function(_, keys, fn) g.shortcuts[keys] = fn end,
    removeShortcut = function(_, keys) g.shortcuts[keys] = nil end,
    addParam = function(_, n, ...) return realV:addParam(g.prefix .. n, ...) end,
    getParam = function(_, n) return realV:getParam(g.prefix .. n) end,
    setHelpText = function(_, text)
      g.help = text
      if active == g then realV:setHelpText(g.header() .. text) end
    end,
    setStatusText = function(_, text) if active == g and text and text ~= "" then print(text) end end,
    loadSound = function(_, path) return realV:loadSound(fix(path)) end,
  }
  local vp = setmetatable({}, {
    __index = function(_, k)
      if k == "cam" then return cam end
      if k == "gravity" then return g.gravity or realV.gravity end
      if TIMING[k] then return g.physics[k] end
      if CALLBACKS[k] then return function(_, fn) g.callbacks[k] = fn end end
      local s = special[k]
      if s then return s end
      if g.vset[k] ~= nil then return g.vset[k] end
      local val = realV[k]
      if type(val) == "function" then
        local fn = vpFns[k]
        if not fn then fn = function(self, ...) return val(realV, ...) end; vpFns[k] = fn end
        return fn
      end
      return val
    end,
    __newindex = function(_, k, val)
      if k == "gravity" then
        g.gravity = val
        for _, b in pairs(g.dyn) do applyGravity(b) end
        return
      end
      if TIMING[k] then g.physics[k] = val; return end
      g.vset[k] = val        -- (lights, shadows and the like: the hall's own stay)
    end,
  })

  local env = setmetatable({}, { __index = _G })
  env._G = env
  env.v = vp
  env.Cube = function(...) return wrap(realCube(...)) end
  env.Sphere = function(...) return wrap(realSphere(...)) end
  env.Cylinder = function(...) return wrap(realCylinder(...)) end
  if realCone then env.Cone = function(...) return wrap(realCone(...)) end end
  env.Mesh = function(path, ...) return wrap(realMesh(fix(path), ...)) end
  -- its ground plane: the hall's floor stands in for it
  env.Plane = function()
    return setmetatable({ __dummy = true }, { __index = function() return function() end end,
                                              __newindex = function() end })
  end
  env.btRigidBody = function(...) return wrapBody(btRigidBody(unwrapAll(...))) end
  env.btDefaultMotionState = function(t, ...) return btDefaultMotionState(shiftT(t, OFF), ...) end
  for _, cn in ipairs({ "btHingeConstraint", "btPoint2PointConstraint", "btGeneric6DofConstraint",
                        "btGeneric6DofSpringConstraint", "btConeTwistConstraint", "btSliderConstraint",
                        "btFixedConstraint", "btUniversalConstraint", "btHinge2Constraint",
                        "btHingeAccumulatedAngleConstraint", "btGearConstraint" }) do
    local ctor = _G[cn]
    if ctor then env[cn] = function(...) return ctor(unwrapAll(...)) end end
  end
  if getPosXYZ then
    env.getPosXYZ = function(o)
      local x, y, z = getPosXYZ(real(o))
      x, z = x - ox, z - oz
      return x * cs - z * sn, y - oy, x * sn + z * cs
    end
    local function outL(x, y, z) return x * cs - z * sn, y, x * sn + z * cs end
    local function inW(x, y, z) return x * cs + z * sn, y, -x * sn + z * cs end
    env.getVelXYZ = function(o) return outL(getVelXYZ(real(o))) end
    env.getAngVelXYZ = function(o) return outL(getAngVelXYZ(real(o))) end
    env.setVelXYZ = function(o, x, y, z) return setVelXYZ(real(o), inW(x, y, z)) end
    env.setAngVelXYZ = function(o, x, y, z) return setAngVelXYZ(real(o), inW(x, y, z)) end
    env.copyTrans = function(a, b) return copyTrans(real(a), real(b)) end
  end
  if objectKey then env.objectKey = function(o) return objectKey(real(o)) end end
  env.io = setmetatable({
    open = function(path, mode) return io.open(fix(path), mode) end,
    lines = function(path, ...) if path == nil then return io.lines() end return io.lines(fix(path), ...) end,
  }, { __index = io })
  env.loadfile = function(path) return loadIn(fix(path), env) end
  env.dofile = function(path)
    local f = assert(env.loadfile(path))
    return f()
  end
  local loaded = {}
  env.require = function(mod)
    if loaded[mod] then return loaded[mod] end
    for pattern in package.path:gmatch("[^;]+") do
      local file = pattern:gsub("%?", (mod:gsub("%.", "/")))
      if exists(file) then
        local f = assert(loadIn(file, env))
        loaded[mod] = f(mod) or true
        return loaded[mod]
      end
    end
    return require(mod)
  end
  g.env = env
  g.load = function() env.dofile(e.file) end

  -- pausing: its moving bodies leave the simulation (keeping their
  -- velocities) and its callbacks aren't called, until it's resumed
  g.setPaused = function(on)
    if on == (g.paused == true) then return end
    g.paused = on
    if on then
      local list = {}
      for r, b in pairs(g.dyn) do
        list[#list + 1] = b
        list[#list + 1] = b:getActivationState()
        b:forceActivationState(5)                 -- DISABLE_SIMULATION
      end
      g.saved = list
    else
      local list = g.saved or {}
      for i = 1, #list, 2 do list[i]:forceActivationState(list[i + 1]) end
      g.saved = nil
    end
  end
  return g
end

-- ---------------------------------------------------------------------
-- the hall
-- ---------------------------------------------------------------------
local UP = btQuaternion(btVector3(1, 0, 0), math.pi / 2)
local function yq(a) return btQuaternion(btVector3(0, 1, 0), a) end
local HOVER = {}           -- objectKey -> text, for the hall's own things
local function vis(o, col, tr)
  o.col = col
  pcall(function() o.collides = false end)
  if tr then pcall(function() o.transparency = tr end) end
  realV:add(o)
  return o
end
local function box(x, y, z, sx, sy, sz, col, q)
  local c = realCube(sx, sy, sz, 0)
  c.trans = btTransform(q or ident, btVector3(x, y, z))
  return vis(c, col)
end
-- a solid one (the floor; things the mouse can rest on)
local function solid(x, y, z, sx, sy, sz, col, q, hover)
  local c = realCube(sx, sy, sz, 0)
  c.trans = btTransform(q or ident, btVector3(x, y, z))
  c.col = col
  c.friction = 0.6
  c.restitution = 0.2
  realV:add(c)
  if hover and objectKey then HOVER[objectKey(c)] = hover end
  return c
end
local function cyl(x, y, z, r, h, col, q)
  local c = realCylinder(r, h, 0)
  c.trans = btTransform(q or UP, btVector3(x, y, z))
  return vis(c, col)
end
local function mesh(file, x, y, z, col, q)
  local m = realMesh(file, 0, false)
  m.trans = btTransform(q or ident, btVector3(x, y, z))
  return vis(m, col)
end

local WALNUT, DARK, PANEL, GILT, GOLD = "#4a2c14", "#2a1a0c", "#5a3418", "#b8932e", "#d4af37"
local FELT, CREAM = "#1f4d3a", "#b9ae94"
realV.glLight0 = btVector4(HW + LB / 2, 1600, -WW / 2 + 400, 0.4)

-- the floor: parquet planks in two woods, running down each wing (solid:
-- it's what anything falling off an exhibit lands on)
do
  local P = 62
  local n = 0
  for x = -HW, HW - P, P do          -- wing A, along z
    n = n + 1
    solid(x + P / 2, -1, ZS / 2, P, 2, ZS, (n % 2 == 0) and "#7a4a24" or "#8a5a2e")
  end
  n = 0
  for z = ZN, -P, P do               -- the corner and wing B, along x
    n = n + 1
    solid((XE - HW) / 2, -1, z + P / 2, XE + HW, 2, P, (n % 2 == 0) and "#7a4a24" or "#8a5a2e")
  end
end

-- walls: walnut, a dado rail, a cornice, gilded panel frames
local function wall(x0, z0, x1, z1, panels)
  local L = math.sqrt((x1 - x0) ^ 2 + (z1 - z0) ^ 2)
  local a = math.atan2(x1 - x0, z1 - z0) + math.pi / 2     -- (the wall runs along its own x)
  local q = yq(a)
  local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
  box(cx, H / 2, cz, L, H, 4, WALNUT, q)
  for _, y in ipairs({ 95, H - 14 }) do box(cx, y, cz, L, 6, 7, DARK, q) end
  box(cx, 4, cz, L, 8, 6, DARK, q)                                       -- skirting
  if panels then
    local nx, nz = (x1 - x0) / L, (z1 - z0) / L
    for s = 105, L - 105, 210 do
      local px, pz = x0 + nx * s, z0 + nz * s
      box(px, 270, pz, 168, 210, 5, GILT, q)
      box(px, 270, pz, 156, 198, 6, PANEL, q)
    end
  end
end
wall(-HW, ZS, -HW, 0, true)             -- wing A's west wall
wall(-HW, 0, -HW, ZN, false)            -- the corner's west wall
wall(HW, ZS, HW, 0, true)               -- wing A's east wall
wall(-HW, ZN, HW, ZN, false)            -- the corner's north wall, with the title
wall(HW, ZN, XE, ZN, true)              -- wing B's north wall
wall(HW, 0, XE, 0, true)                -- wing B's south wall
wall(XE, 0, XE, ZN, false)              -- wing B's far end, with a tall window
box(XE - 3, 230, ZN / 2, 4, 300, 220, GILT)
box(XE - 4, 230, ZN / 2, 4, 284, 204, "#9fb8c8")
box(XE - 5, 230, ZN / 2, 4, 284, 6, GILT); box(XE - 5, 230, ZN / 2, 4, 6, 204, GILT)
-- and a large empty frame on the corner's west wall, facing wing B
box(-HW + 3, 240, ZN / 2, 4, 190, 150, GILT); box(-HW + 4, 240, ZN / 2, 4, 174, 134, "#1d2a3a")
-- the entrance wall, with a door in it
box(-HW / 2 - 50, H / 2, ZS, HW - 100, H, 4, WALNUT)
box(HW / 2 + 50, H / 2, ZS, HW - 100, H, 4, WALNUT)
box(0, (H + 260) / 2, ZS, 200, H - 260, 4, WALNUT)
box(-104, 130, ZS - 3, 10, 270, 8, GILT); box(104, 130, ZS - 3, 10, 270, 8, GILT); box(0, 265, ZS - 3, 218, 12, 8, GILT)
box(0, 130, ZS + 6, 200, 260, 2, "#1a0f06")

-- the ceiling, coffered
box(0, H, ZS / 2, WW, 4, ZS, "#3a2210")
box((XE - HW) / 2, H, ZN / 2, XE + HW, 4, -ZN, "#3a2210")
for z = 0, ZS, 140 do box(0, H - 7, z, WW, 12, 9, DARK) end
for x = -HW, XE, 140 do box(x, H - 7, ZN / 2, 9, 12, -ZN, DARK) end

-- chandeliers down the middle of each wing and one in the corner
local function chandelier(x, z)
  cyl(x, H - 40, z, 1, 80, GILT)
  cyl(x, H - 82, z, 36, 6, GOLD)
  for k = 0, 7 do
    local dx, dz = rot(k * math.pi / 4, 31, 0)
    cyl(x + dx, H - 74, z + dz, 2.4, 11, "#fff4cc")
  end
end
for z = ZS - BAY_W, 0, -2 * BAY_W do chandelier(0, z) end
chandelier(0, ZN / 2)
for x = HW + BAY_W, XE - 1, 2 * BAY_W do chandelier(x, ZN / 2) end

-- the title on the corner's north wall, facing down wing A
mesh(MESH .. LABELS.title.file, 0, 365, ZN + 4, GOLD)
-- two gilded frames under it, and an armillary sphere in the middle of the corner
for _, x in ipairs({ -250, 250 }) do
  box(x, 235, ZN + 4, 130, 160, 3, GILT); box(x, 235, ZN + 5, 114, 144, 3, "#1d2a3a")
end
do
  local cx, cz = 0, ZN / 2
  cyl(cx, 40, cz, 22, 80, WALNUT); cyl(cx, 81, cz, 28, 3, GILT)
  cyl(cx, 95, cz, 3, 26, GILT)
  local ring = MESH .. "ring.obj"
  local tilt = btQuaternion(btVector3(0, 0, 1), math.rad(23.4))
  mesh(ring, cx, 140, cz, GOLD, tilt)                                           -- the ecliptic
  mesh(ring, cx, 140, cz, GILT)                                                 -- the equator
  mesh(ring, cx, 140, cz, GILT, btQuaternion(btVector3(1, 0, 0), math.pi / 2))  -- a meridian
  mesh(ring, cx, 140, cz, GILT, btQuaternion(btVector3(0, 0, 1), math.pi / 2))  -- the colure
  local s = realSphere(5, 0); s.trans = btTransform(ident, btVector3(cx, 140, cz)); s.col = "#2a4a7a"
  realV:add(s)
  if objectKey then HOVER[objectKey(s)] = "An armillary sphere: the heavens in brass rings,\nwith the Earth in the middle." end
end

-- a bay: its rug, pilasters either side on the wall behind, and the
-- placard at the aisle edge
local function bayFrame(b, labelKey, hoverText)
  local a = b.a
  local q = yq(a)
  -- the rug
  local rx, rz = rot(a, 0, 0)
  box(b.x, 0.3, b.z, (b.wing == "A") and (BAY_D - 30) or (BAY_W - 40), 0.6,
      (b.wing == "A") and (BAY_W - 40) or (BAY_D - 30), "#5a1a1a")
  box(b.x, 0.45, b.z, (b.wing == "A") and (BAY_D - 50) or (BAY_W - 60), 0.6,
      (b.wing == "A") and (BAY_W - 60) or (BAY_D - 50), "#3a1010")
  -- pilasters at the bay's edges, against the wall
  for _, s in ipairs({ -1, 1 }) do
    local dx, dz = rot(a, s * BAY_W / 2, -BAY_D / 2 + 8)
    box(b.x + dx, H / 2, b.z + dz, 26, H, 14, PANEL, q)
    local cx, cz = rot(a, s * BAY_W / 2, -BAY_D / 2 + 10)
    box(b.x + cx, H - 40, b.z + cz, 34, 16, 18, GILT, q)
    box(b.x + cx, 14, b.z + cz, 34, 28, 18, DARK, q)
  end
  -- the placard: a walnut post and an inclined board, the name in gilt
  local L = LABELS[labelKey] or LABELS.reserved
  local px, pz = rot(a, 0, BAY_D / 2 - 6)
  px, pz = b.x + px, b.z + pz
  box(px, 45, pz, 6, 90, 6, DARK, q)
  local tiltQ = q * btQuaternion(btVector3(1, 0, 0), -math.rad(35))
  local bw = L.w + 12
  local board = solid(px, 95, pz, bw, 14, 2.5, DARK, tiltQ, hoverText)
  box(px, 95, pz, bw + 2, 16, 2, GILT, tiltQ)
  -- (the lettering stands on the board's face)
  local ux, uz = rot(a, 0, 1)
  local nY, nH = math.cos(math.rad(35)), math.sin(math.rad(35))     -- the face's normal: up and out
  local lx, ly, lz = px + ux * 1.3 * nY, 95 + 1.3 * nH, pz + uz * 1.3 * nY
  -- (its letters are L.h tall from y = 0: centred on the board)
  local dy = -L.h / 2
  local cx, cy, cz = lx + ux * (-dy * nH), ly + dy * nY, lz + uz * (-dy * nH)
  mesh(MESH .. L.file, cx, cy, cz, GOLD, tiltQ)
  return px, pz
end

-- a covered bay: a plinth with a dust sheet over what's coming
local function coveredBay(b, e)
  bayFrame(b, e.label, e.about)
  local q = yq(b.a)
  box(b.x, 40, b.z, 110, 80, 110, WALNUT, q)
  box(b.x, 81, b.z, 118, 3, 118, GILT, q)
  solid(b.x, 125, b.z, 92, 86, 92, CREAM, q, e.about)       -- the dust sheet, hanging in folds
  box(b.x, 98, b.z, 104, 34, 104, "#a99e84", q)
  box(b.x, 167, b.z, 80, 4, 80, "#c4b99e", q)
  local L = LABELS["in-preparation"]
  local dx, dz = rot(b.a, 0, 46.2)
  mesh(MESH .. L.file, b.x + dx, 150, b.z + dz, "#6a5a3a", q)
end
local function emptyBay(b)
  local text = "An empty bay, waiting for the next curiosity."
  bayFrame(b, "reserved", text)
  local q = yq(b.a)
  solid(b.x, 40, b.z, 110, 80, 110, WALNUT, q, text)
  box(b.x, 81, b.z, 118, 3, 118, GILT, q)
end

-- ---------------------------------------------------------------------
-- the exhibits into their bays
-- ---------------------------------------------------------------------
for i, b in ipairs(BAYS) do
  local e = EXHIBITS[i]
  if not e then
    emptyBay(b)
  elseif not exists(e.dir .. e.file) then
    coveredBay(b, e)
  else
    local off = btVector3(b.x, -(e.floorY or 0), b.z)
    local g = makeExhibit(e, off, b.a)
    g.bay = b
    bayFrame(b, e.label, e.about)
    if e.stand then
      local top, q = off.y - 4, yq(b.a)
      box(b.x, top / 2, b.z, e.stand[1] - 10, top, e.stand[2] - 10, WALNUT, q)
      box(b.x, top - 3, b.z, e.stand[1] - 4, 6, e.stand[2] - 4, DARK, q)
      box(b.x, 5, b.z, e.stand[1], 10, e.stand[2], DARK, q)
      box(b.x, top - 8, b.z, e.stand[1] - 6, 2, e.stand[2] - 6, GILT, q)
    end
    loading = g
    local ok, err = pcall(g.load)
    loading = nil
    if ok then
      g.setPaused(true)
      exhibits[#exhibits + 1] = g
      print(string.format("CABINET: %s is in its bay (%s%s)", g.name, e.dir, e.file))
    else
      print("CABINET: " .. g.name .. " didn't load: " .. tostring(err))
    end
  end
end

-- ---------------------------------------------------------------------
-- walking round: the exhibits, and two views down the hall
-- ---------------------------------------------------------------------
local VIEW_A = { name = "the entrance", isView = true,
                 pos = btVector3(0, 270, ZS - 20), look = btVector3(0, 110, ZN) }
local VIEW_B = { name = "the corner", isView = true,
                 pos = btVector3(-HW + 120, 250, ZN / 2 + 60), look = btVector3(XE, 110, ZN / 2) }
local stops = { VIEW_A }
for _, g in ipairs(exhibits) do if g.bay.wing == "A" then stops[#stops + 1] = g end end
stops[#stops + 1] = VIEW_B
for _, g in ipairs(exhibits) do if g.bay.wing == "B" then stops[#stops + 1] = g end end
local function indexOf(s) for i, x in ipairs(stops) do if x == s then return i end end end
local here = VIEW_A

local function nextStop(s, d)
  local i = indexOf(s) or 1
  return stops[(i - 1 + d) % #stops + 1]
end
local function header(g)
  return function()
    return "EULER'S CABINET OF CURIOSITIES -- at " .. g.name ..
           "\n(Tab: walk on to " .. nextStop(g, 1).name .. "; Shift+Tab: back to " .. nextStop(g, -1).name .. ")\n" ..
           "Its sliders are the \"" .. g.prefix .. "\" ones in the Params pane.\n\n"
  end
end
for _, g in ipairs(exhibits) do g.header = header(g) end

local function hallHelp(s)
  local live, coming = {}, {}
  for _, g in ipairs(exhibits) do live[#live + 1] = "  " .. g.name end
  for i, e in ipairs(EXHIBITS) do
    if not exists(e.dir .. e.file) then coming[#coming + 1] = "  " .. e.name end
  end
  return "EULER'S CABINET OF CURIOSITIES -- " .. s.name ..
         "\n(Tab: walk on to " .. nextStop(s, 1).name .. "; Shift+Tab: back to " .. nextStop(s, -1).name .. ")\n\n" ..
         "Only the exhibit you're standing at runs; the others wait where they\n" ..
         "were and carry on when you come back. Rest the mouse on a placard or a\n" ..
         "covered bay to read it.\n\n" ..
         "On show:\n" .. table.concat(live, "\n") .. "\n\n" ..
         (#coming > 0 and ("In preparation:\n" .. table.concat(coming, "\n") .. "\n\n") or "") ..
         "Tab / Shift+Tab   walk on / back\n" ..
         "the mouse          looks round as usual\n"
end

local function goTo(s)
  -- let go of any keys still held at the exhibit we're leaving, and stop it
  if active then
    local f = active.callbacks.onKey
    for key in pairs(active.down) do if f then pcall(f, active.N, key, false) end end
    active.down = {}
    active.setPaused(true)
  end
  here = s
  local c = realV.cam
  c:setUpVector(btVector3(0, 1, 0), true)
  if s.isView then
    active = nil
    applyPhysics(IDLE)
    c.pos = s.pos
    c.look = s.look        -- (in that order: the look turns the view from where it now is)
    realV:setHelpText(hallHelp(s))
  else
    active = s
    s.setPaused(false)
    applyPhysics(s.physics)
    local view = s.view
    local pos = view.pos or btVector3(0, 150, 200)
    local look = view.look or btVector3(0, 0, 0)
    c.pos = s.toWorld(pos)
    c.look = s.toWorld(look)
    realV:setHelpText(s.header() .. s.help)
  end
end

-- ---------------------------------------------------------------------
-- passing things on to the exhibit you're at
-- ---------------------------------------------------------------------
local function report(g, k, err)
  print("CABINET: " .. g.name .. " " .. k .. ": " .. tostring(err))
  g.callbacks[k] = nil              -- (said once, not every frame)
end
local function callActive(k)
  local g = active
  if not g then return end
  local f = g.callbacks[k]
  if f then
    local ok, err = pcall(f, g.N)
    if not ok then report(g, k, err) end
  end
end

realV:preSim(function(N)
  if active then
    active.N = active.N + 1
    callActive("preSim")
    if active then applyPhysics(active.physics) end
  end
end)
realV:postSim(function(N) callActive("postSim") end)
realV:preDraw(function(N) callActive("preDraw") end)
realV:postDraw(function(N) callActive("postDraw") end)

local HELD_BACK = { S = true, D = true, R = true, P = true }
realV:onKey(function(N, key, down)
  if key == "Tab" or key == "Backtab" then
    if down then goTo(nextStop(here, key == "Tab" and 1 or -1)) end
    return true
  end
  local g = active
  if not g then
    if key == "P" then
      if down then print("CABINET: P (save every frame for POV-Ray) is held back here; use the POV-Ray menu.") end
      return true
    end
    return false
  end
  local sc = g.shortcuts[key]
  if sc then
    if down then
      local ok, err = pcall(sc, g.N)
      if not ok then print("CABINET: " .. g.name .. " key " .. key .. ": " .. tostring(err)) end
    end
    return true
  end
  local f = g.callbacks.onKey
  local used = false
  if f then
    if down then g.down[key] = true else g.down[key] = nil end
    local ok, r = pcall(f, g.N, key, down)
    used = ok and r
  end
  -- bpp's own one-letter keys (S stop, D sleeping, R reload, P POV-Ray)
  -- would change the whole hall: at an exhibit they do only what it uses
  -- them for
  if not used and HELD_BACK[key] then return true end
  return used
end)

realV:onParamChanged(function(N, name, value)
  for _, g in ipairs(exhibits) do
    local p = g.prefix
    if name:sub(1, #p) == p then
      local f = g.callbacks.onParamChanged
      if f then
        local ok, err = pcall(f, g.N, name:sub(#p + 1), value)
        if not ok then print("CABINET: " .. g.name .. ": " .. tostring(err)) end
      end
      return
    end
  end
end)

-- hover: the hall's own placards, else whichever exhibit knows the thing
if realV.onHover then
  realV:onHover(function(N, obj, x, y, z)
    if objectKey then
      local t = HOVER[objectKey(obj)]
      if t then return t end
    end
    for _, g in ipairs(exhibits) do
      local f = g.callbacks.onHover
      if f then
        local p = g.toLocal(btVector3(x, y, z))
        local ok, r = pcall(f, g.N, obj, p.x, p.y, p.z)
        if ok and r then return r end
      end
    end
    return nil
  end)
end

if realV.onePerFrame ~= nil then realV.onePerFrame = true end
-- (START: begin at that exhibit's name, for trying one out)
local START = os.getenv("CABINET_START")
if START then
  for _, g in ipairs(exhibits) do if g.name:lower():find(START:lower(), 1, true) then here = g end end
  if START == "corner" then here = VIEW_B end
end
goTo(here)
print(string.format("CABINET: %d exhibits on show, %d in preparation, %d empty bays; wings %.0f and %.0f m long",
                    #exhibits, #EXHIBITS - #exhibits, #BAYS - #EXHIBITS, (LA + WW) / 100, (LB + WW) / 100))
