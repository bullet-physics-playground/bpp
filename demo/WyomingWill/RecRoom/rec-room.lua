--
-- REC ROOM -- a 1970s basement games room for the Bullet Physics
-- Playground, 11 by 11 metres: Pinball Machine A against the back wall
-- with the bar and the jukebox, one of WyomingWill's clocks (N7) on the
-- wall between them, and the Pool Table, the Bumper Pool table and the
-- Snooker Table down the right-hand side, with a sofa across from them.
--
-- Tab walks between them (Shift+Tab walks back): the pinball machine, the
-- pool table, the snooker table, the bumper pool table, the clock, and a
-- look round the room. The keys work the thing you're at, exactly as when
-- it's opened on its own (see each one's README or help); the Shortcuts
-- pane shows them.
--
-- HOW IT WORKS: the games are the unchanged pinball-machine-a.lua,
-- pool-table.lua, snooker-table.lua, bumper-pool.lua and
-- N7_Clock_handcheck.lua, each loaded into a sandbox of its own (its own
-- set of globals) that
--   * places it in the room (everything it builds is moved by an offset,
--     and for the clock shrunk to a quarter size; everything it reads back
--     is moved back, so its own sums still hold),
--   * finds its files (sounds, meshes, rules, the computer player's brain)
--     in its own folder,
--   * gives it its own gravity, applied to its bodies alone (bpp's world
--     has one gravity): the tables' straight down, the pinball machine's
--     tilted 6.5 degrees toward the player, the clock's whatever its
--     clock_gravity slider says,
--   * collects its per-frame callbacks, key handler and shortcuts, which
--     this file calls in turn, sending the keys only to the game you're at,
--   * lets it move the camera and fill the Shortcuts pane only while
--     you're at it.
-- The physics settings (step, solver) are the world's, and the clock's
-- escapement needs its own (100 steps a second) while the tables need 900,
-- so they take turns frame by frame, each frozen while the other steps; the
-- clock gets 25 frames for each real second, as it does on its own. A
-- table that's waiting for a shot has its balls frozen too, and the room
-- collects Lua's garbage a little every frame. Everything keeps running
-- wherever you stand.
--
-- FILES: the pinball and pool folders must sit next to this one (as
-- pinball-machine-a/ and pool-table/, or Pinball/ and Pool/). The snooker
-- and bumper pool tables (snooker-table/ or Snooker/, bumper-pool/ or
-- BumperPool/) and the clock (../Clocks/ or ../../WyomingWill/Clocks/) are
-- used if they're there; without one, the room simply goes without it.
--
-- UNITS: centimetres. The floor is at y = FLOOR.
--

local FLOOR = -95.4                  -- (the pinball machine's legs stand here)
-- The tables all run along x, as they're built (the sandbox moves them but
-- doesn't turn them): one behind another down the right-hand side of the
-- room, each with its scoreboard against the right-hand wall (x = 647) and
-- at least 1.5 m round it for the cue. (Their legs are 82 cm long.)
local POOL_OFFSET = btVector3(460, FLOOR + 82, 100)      -- scoreboard 187 past its middle
local BUMPER_OFFSET = btVector3(533, FLOOR + 82, 385)    -- 114
local SNOOKER_OFFSET = btVector3(399, FLOOR + 82, 696)   -- 248
local realV = v
local realCube, realSphere, realCylinder, realMesh, realOpenSCAD = Cube, Sphere, Cylinder, Mesh, OpenSCAD
local unpack = unpack or table.unpack

-- The physics settings (step, solver) are the world's, not a game's. The
-- pinball machine and the pool table share the pool table's (900 steps a
-- second, which its break needs). The clock's escapement needs its own
-- (100 steps a second), so the two take turns, frame by frame, each frozen
-- while the other goes. The clock gets a frame whenever it has had fewer
-- than 25 for each real second since it started (the pace its own frame
-- timer gives it when it runs alone), so however busy the room is, its
-- world runs at the same speed; the games get all the other frames. At 83
-- frames a second that leaves them their usual 60.
local ROOM_PHYSICS = { timeStep = 1 / 60, fixedTimeStep = 1 / 900, maxSubSteps = 30,
                       iterations = 24, erp = 0.2, erp2 = 0.2 }
-- bpp's and Bullet's own starting values, for a game that doesn't set them
local BPP_PHYSICS = { timeStep = 1 / 25, fixedTimeStep = 1 / 100, maxSubSteps = 7,
                      iterations = 10, erp = 0.2, erp2 = 0.2, animationPeriod = 40 }
local MAX_OWED = 5.0      -- the clock catches up on at most this many seconds' frames
local function applyPhysics(p)
  v.timeStep, v.fixedTimeStep, v.maxSubSteps = p.timeStep, p.fixedTimeStep, p.maxSubSteps
  if v.setSolverIterations then v:setSolverIterations(p.iterations) end
  v:setErp(p.erp)
  v:setErp2(p.erp2)
end
applyPhysics(ROOM_PHYSICS)
if v.animationPeriod then v.animationPeriod = 16 end
v.gravity = btVector3(0, -981, 0)

-- ---------------------------------------------------------------------
-- the sandboxes
-- ---------------------------------------------------------------------

local games = {}          -- in Tab order
local active = nil        -- the game you're at (nil: looking round the room)

local function wrapped(o) return type(o) == "table" and rawget(o, "__real") or o end

-- Where the two games are, relative to this file's folder. The first
-- folder in each list that holds the game's script is used; add yours to
-- the front of the list if it lives somewhere else.
local function findGame(dirs, file)
  for _, d in ipairs(dirs) do
    local fh = io.open(d .. file, "r")
    if fh then fh:close(); return d end
  end
  error("can't find " .. file .. " in any of: " .. table.concat(dirs, ", "))
end
PINBALL_FILE = "pinball-machine-a.lua"
PINBALL_DIR = findGame({ "../pinball-machine-a/", "../Pinball/", "../pinball/" }, PINBALL_FILE)
POOL_FILE = "pool-table.lua"
POOL_DIR = findGame({ "../pool-table/", "../Pool/", "../pool/" }, POOL_FILE)
-- the snooker and bumper pool tables are welcome but not required
local function findOptional(dirs, file)
  for _, d in ipairs(dirs) do
    local fh = io.open(d .. file, "r")
    if fh then fh:close(); return d end
  end
  print("REC ROOM: no " .. file .. " (looked in " .. table.concat(dirs, ", ") .. ")")
end
SNOOKER_FILE = "snooker-table.lua"
SNOOKER_DIR = findOptional({ "../snooker-table/", "../Snooker/", "../snooker/", "../SnookerTable/" }, SNOOKER_FILE)
BUMPER_FILE = "bumper-pool.lua"
BUMPER_DIR = findOptional({ "../bumper-pool/", "../BumperPool/", "../Bumper Pool/", "../Bumper/", "../bumper/" }, BUMPER_FILE)

-- Load a Lua file so that its globals live in env. Lua 5.1 does this with
-- setfenv; Lua 5.2 and later dropped setfenv and take the environment as
-- loadfile's third argument instead. Either way works here.
local function loadIn(file, env)
  if setfenv then
    local f, err = loadfile(file)
    if f then setfenv(f, env) end
    return f, err
  end
  return loadfile(file, "t", env)
end

-- Roots to look for files a game names from bpp's own folder (such as
-- "demo/mesh/x.stl"): bpp puts <root>/demo/module/ (or <root>/module/) on
-- package.path, so the roots can be read back from there.
local ROOTS = {}
for entry in package.path:gmatch("[^;]+") do
  local d = entry:match("^(.*[/\\])module[/\\]%?%.lua$")
  if d then ROOTS[#ROOTS + 1] = d; ROOTS[#ROOTS + 1] = d .. "../"; ROOTS[#ROOTS + 1] = d .. "../../" end
end
local function exists(path)
  local fh = io.open(path, "rb")
  if fh then fh:close() return true end
  return false
end

-- makeGame(name, dir, offset, opts): a sandbox for one game.
--   opts.scale      -- shrink (or grow) everything the game builds by this
--                      much, about its own origin. Gravity and motor
--                      torques are scaled to suit, so it runs exactly as it
--                      does full size (lengths x s, gravity x s, torques
--                      x s^2: the same motion, in the same time).
--   opts.motors     -- scale its hinge motors' impulses from the physics
--                      step it was written for (bpp's usual 1/100 s, or
--                      whatever it sets) to the room's 1/900 s, so they
--                      push just as hard per second.
--   opts.params     -- a prefix for its sliders' names in the Params pane
--   opts.noCamera   -- never let it move the camera (the room has its own
--                      view of it)
--   opts.ownPhysics -- it runs with its own physics settings (step, solver,
--                      ERP), taking turns with the others; otherwise the
--                      room's settings apply
local function makeGame(name, dir, offset, opts)
  opts = opts or {}
  local S = opts.scale or 1
  local g = { name = name, dir = dir, off = offset, callbacks = {}, help = "", down = {},
              shortcuts = {}, bodies = {}, physics = {}, N = 0 }
  for k, val in pairs(BPP_PHYSICS) do g.physics[k] = val end
  local OFF = btTransform(btQuaternion(0, 0, 0, 1), offset)
  local INV = btTransform(btQuaternion(0, 0, 0, 1), btVector3(-offset.x, -offset.y, -offset.z))
  local ox, oy, oz = offset.x, offset.y, offset.z
  local function sv(p) return btVector3(p.x * S, p.y * S, p.z * S) end   -- a length, scaled
  local function toWorld(p) return btVector3(p.x * S + ox, p.y * S + oy, p.z * S + oz) end
  local function toLocal(q) return btVector3((q.x - ox) / S, (q.y - oy) / S, (q.z - oz) / S) end
  -- a file the game names: in its own folder, else as named, else from
  -- bpp's own folder
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
  local function shiftT(t, by) local o = btTransform(); o:mult(by, t); return o end

  -- an object the game made: positions go through the offset (and scale)
  local objMeta = {
    __index = function(p, k)
      local r = rawget(p, "__real")
      if k == "pos" then return toLocal(r.pos) end
      if k == "trans" then
        if S == 1 then return shiftT(r.trans, INV) end
        local q = r.pos
        return btTransform(r.trans:getRotation(), btVector3(q.x - ox, q.y - oy, q.z - oz))
      end
      local val = r[k]
      if type(val) == "function" then
        local fn = function(self, ...) return val(r, ...) end
        rawset(p, k, fn)                  -- made once, not on every call
        return fn
      end
      return val
    end,
    __newindex = function(p, k, val)
      local r = rawget(p, "__real")
      if k == "pos" then r.pos = toWorld(val)
      elseif k == "trans" then r.trans = shiftT(val, OFF)
      else r[k] = val end
    end,
  }
  local function wrap(o) return setmetatable({ __real = o }, objMeta) end

  -- the camera: moved by the offset, and only while you're at this game
  local camFns = {}
  local cam = setmetatable({}, {
    __index = function(_, k)
      local c = realV.cam
      if k == "pos" or k == "look" then return toLocal(c[k]) end
      local val = c[k]
      if type(val) == "function" then
        local fn = camFns[k]
        if not fn then
          fn = function(self, ...) if active == g and not opts.noCamera then return val(realV.cam, ...) end end
          camFns[k] = fn
        end
        return fn
      end
      return val
    end,
    __newindex = function(_, k, val)
      if active ~= g or opts.noCamera then return end
      local c = realV.cam
      if k == "pos" or k == "look" then c[k] = toWorld(val)
      else c[k] = val end
    end,
  })

  -- its gravity, applied to its own bodies
  local function applyGravity(body)
    if g.gravity then pcall(function() body:setGravity(sv(g.gravity)) end) end
  end

  -- constraints: pivots scaled, motor impulses scaled to the room's step
  local conMeta = {
    __index = function(p, k)
      local r = rawget(p, "__real")
      local val = r[k]
      if type(val) ~= "function" then return val end
      if k == "enableAngularMotor" then
        local fn = function(self, on, vel, imp) return val(r, on, vel, imp * g.motorFactor()) end
        rawset(p, k, fn); return fn
      elseif k == "setMaxMotorImpulse" then
        local fn = function(self, imp) return val(r, imp * g.motorFactor()) end
        rawset(p, k, fn); return fn
      elseif k == "setLinearLowerLimit" or k == "setLinearUpperLimit" then
        local fn = function(self, lim) return val(r, sv(lim)) end
        rawset(p, k, fn); return fn
      end
      local fn = function(self, ...) return val(r, ...) end
      rawset(p, k, fn)
      return fn
    end,
  }
  local function wrapCon(c) return setmetatable({ __real = c }, conMeta) end
  g.motorFactor = function()
    local f = S * S
    if opts.motors and not opts.ownPhysics then f = f * ROOM_PHYSICS.fixedTimeStep / g.physics.fixedTimeStep end
    return f
  end

  -- the viewer, as the game sees it
  local IGNORED = { timeStep = true, fixedTimeStep = true, maxSubSteps = true, animationPeriod = true }
  local prefix = opts.params or ""
  local vpFns = {}
  local vp = setmetatable({}, {
    __index = function(_, k)
      if k == "cam" then return cam end
      if k == "gravity" then return g.gravity or realV.gravity end
      if k == "add" then
        return function(_, o)
          local r = wrapped(o)
          realV:add(r)
          local ok, body = pcall(function() return r.body end)
          if ok and body then g.bodies[#g.bodies + 1] = body; applyGravity(body) end
        end
      end
      if k == "remove" then return function(_, o) realV:remove(wrapped(o)) end end
      if k == "addConstraint" or k == "removeConstraint" then
        return function(_, c, ...) return realV[k](realV, wrapped(c), ...) end
      end
      if k == "preSim" or k == "postSim" or k == "preDraw" or k == "onKey" then
        return function(_, fn) g.callbacks[k] = fn end
      end
      if k == "addShortcut" then return function(_, keys, fn) g.shortcuts[keys] = fn end end
      if k == "removeShortcut" then return function(_, keys) g.shortcuts[keys] = nil end end
      if k == "addParam" then return function(_, n, ...) return realV:addParam(prefix .. n, ...) end end
      if k == "getParam" then return function(_, n) return realV:getParam(prefix .. n) end end
      if k == "setErp" or k == "setErp2" then
        local key = (k == "setErp") and "erp" or "erp2"
        return function(_, x) g.physics[key] = x end
      end
      if k == "setHelpText" then
        return function(_, text)
          g.help = text
          if active == g then realV:setHelpText(g.header() .. text) end
        end
      end
      if k == "loadSound" then return function(_, path) return realV:loadSound(fix(path)) end end
      if k == "setSolverIterations" then
        return function(_, n) g.physics.iterations = n end
      end
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
        for _, b in ipairs(g.bodies) do applyGravity(b) end
        return
      end
      if IGNORED[k] then
        g.physics[k] = val
        return
      end
      realV[k] = val
    end,
  })

  local env = setmetatable({}, { __index = _G })
  env._G = env
  env.v = vp
  if S == 1 then
    env.Cube = function(...) return wrap(realCube(...)) end
    env.Sphere = function(...) return wrap(realSphere(...)) end
    env.Cylinder = function(...) return wrap(realCylinder(...)) end
    env.Mesh = function(path, ...) return wrap(realMesh(fix(path), ...)) end
    if realOpenSCAD then env.OpenSCAD = function(...) return wrap(realOpenSCAD(...)) end end
  else
    -- sizes scaled; masses kept
    local function sized(ctor, nSizes)
      return function(a, ...)
        if type(a) ~= "number" then
          if a == nil then return wrap(ctor()) end
          return wrap(ctor(sv(a), ...))          -- the btVector3-of-sizes forms
        end
        local args = { a, ... }
        for i = 1, math.min(nSizes, #args) do args[i] = args[i] * S end
        return wrap(ctor(unpack(args)))
      end
    end
    env.Cube = sized(realCube, 3)
    env.Sphere = sized(realSphere, 1)
    env.Cylinder = sized(realCylinder, 2)
    -- meshes: OpenSCAD scales them (bpp's Mesh has no scale of its own)
    env.OpenSCAD = function(sdl, ...)
      return wrap(realOpenSCAD("module bpp_unscaled() {\n" .. sdl .. "\n}\nscale(" .. S .. ") bpp_unscaled();\n", ...))
    end
    env.Mesh = function(path, ...)
      local file = fix(path):gsub("\\", "/")
      return wrap(realOpenSCAD('scale(' .. S .. ') import("' .. file .. '");', ...))
    end
    -- transforms the game builds hold scaled positions (constraint
    -- frames are relative to a body, so that's all they need)
    env.btTransform = function(q, p)
      if q == nil then return btTransform() end
      return btTransform(q, sv(p))
    end
  end
  -- a motion state places a body in the world: through the offset
  env.btDefaultMotionState = function(t, ...) return btDefaultMotionState(shiftT(t, OFF), ...) end
  if S ~= 1 or opts.motors then
    env.btHingeConstraint = function(a, b, c, d, e, f)
      if f ~= nil then                                   -- (A, B, pivotA, pivotB, axisA, axisB)
        return wrapCon(btHingeConstraint(a, b, sv(c), sv(d), e, f))
      elseif d == nil then                               -- (A, pivotA, axisA)
        return wrapCon(btHingeConstraint(a, sv(b), c))
      end
      return wrapCon(btHingeConstraint(a, b, c, d))      -- (A, B, frameA, frameB): already scaled
    end
    env.btGeneric6DofConstraint = function(...) return wrapCon(btGeneric6DofConstraint(...)) end
    if btPoint2PointConstraint then
      env.btPoint2PointConstraint = function(a, b, c, d)
        return wrapCon(btPoint2PointConstraint(a, b, sv(c), sv(d)))
      end
    end
  end
  env.io = setmetatable({ open = function(path, mode) return io.open(fix(path), mode) end }, { __index = io })
  -- the room collects garbage for everyone, a little every frame (see
  -- below); a game's own "collect everything now" would sweep the whole
  -- room's heap in one go, so it's left to the room
  env.collectgarbage = function(opt, ...)
    if opt == "collect" or opt == "stop" or opt == "restart" or opt == "step" then return 0 end
    return collectgarbage(opt, ...)
  end
  env.loadfile = function(path)
    return loadIn(fix(path), env)
  end
  env.dofile = function(path)
    local f = assert(env.loadfile(path))
    return f()
  end
  local loaded = {}
  env.require = function(mod)
    if loaded[mod] then return loaded[mod] end
    for pattern in package.path:gmatch("[^;]+") do
      local file = pattern:gsub("%?", (mod:gsub("%.", "/")))
      local fh = io.open(file, "r")
      if fh then
        fh:close()
        local f = assert(loadIn(file, env))
        loaded[mod] = f(mod) or true
        return loaded[mod]
      end
    end
    return require(mod)
  end
  g.env = env
  g.load = function(file) env.dofile(file) end
  -- pausing: its moving bodies are taken out of the simulation (they cost
  -- nothing and keep their velocities), and its per-frame callbacks aren't
  -- called, until it's resumed. Its frame count N stops too, so it sees
  -- its own frames one after another, as it does on its own.
  g.setPaused = function(on)
    if on == (g.paused == true) then return end
    g.paused = on
    if on then
      local list = {}
      for _, b in ipairs(g.bodies) do
        if not b:isStaticObject() then
          list[#list + 1] = b
          list[#list + 1] = b:getActivationState()
          b:forceActivationState(5)          -- DISABLE_SIMULATION
        end
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
-- the games
-- ---------------------------------------------------------------------

local pinball = makeGame("the pinball machine", PINBALL_DIR, btVector3(0, 0, 0))
local pool = makeGame("the pool table", POOL_DIR, POOL_OFFSET)
games = { pinball, pool }
local snooker = SNOOKER_DIR and makeGame("the snooker table", SNOOKER_DIR, SNOOKER_OFFSET)
local bumper = BUMPER_DIR and makeGame("the bumper pool table", BUMPER_DIR, BUMPER_OFFSET)
if snooker then games[#games + 1] = snooker end
if bumper then games[#games + 1] = bumper end

-- the clock, if it's to hand: shrunk to hang on the back wall, left of
-- the pinball machine. Its gravity slider is "clock_gravity" in the Params
-- pane (its script calls it "gravity"; the name is kept apart from any
-- other game's). The placing below is worked out for N7; the other clocks
-- are built differently (N2 on a 60 m plate) and would need their own.
CLOCK_FILE = CLOCK_FILE or "N7_Clock_handcheck.lua"
CLOCK_SCALE = CLOCK_SCALE or 0.25
local clock
do
  local dirs = { "../Clocks/", "../clocks/", "../../WyomingWill/Clocks/", "../WyomingWill/Clocks/" }
  local cdir
  for _, d in ipairs(dirs) do if exists(d .. CLOCK_FILE) then cdir = d break end end
  if cdir then
    -- its stand (a block 300 deep behind the works) goes into the wall; the
    -- wall's face is at its z = 240, just behind the pendulum's swing
    local S = CLOCK_SCALE
    clock = makeGame("the clock", cdir,
                     CLOCK_OFFSET or btVector3(-100, FLOOR + 160 - 163 * S, -150 - 240 * S),
                     { scale = S, params = "clock_", noCamera = true, ownPhysics = true })
    games[#games + 1] = clock
  else
    print("REC ROOM: no clock (looked for " .. CLOCK_FILE .. " in " .. table.concat(dirs, ", ") .. ")")
  end
end

local function nextOf(g)
  for i, x in ipairs(games) do if x == g then return games[i + 1] end end
  return games[1]
end
local function header(g)
  return function()
    local n = nextOf(g)
    local h = "REC ROOM -- at " .. g.name .. "   (Tab: walk over to "
              .. (n and n.name or "look round the room") .. "; Shift+Tab: back)\n\n"
    if g == bumper then
      h = h .. "(Tab walks on, so choose your ball with X / Z.)\n\n"
    end
    if g == clock then
      h = h .. "Its gravity is the clock_gravity slider in the Params pane: it moves\n"
              .. "the clock alone. Its keys work while you're standing at it.\n\n"
    end
    return h
  end
end
for _, g in ipairs(games) do g.header = header(g) end

-- (the pinball machine first, so it has the camera as it sets up; then
-- the tables, then the clock)
active = pinball
pinball.load(PINBALL_FILE)
active = pool
pool.load(POOL_FILE)
if snooker then active = snooker; snooker.load(SNOOKER_FILE) end
if bumper then active = bumper; bumper.load(BUMPER_FILE) end
if clock then
  active = clock
  local friction = realV.friction
  local ok, err = pcall(clock.load, CLOCK_FILE)
  pcall(function() realV.friction = friction end)
  if not ok then
    print("REC ROOM: the clock didn't load: " .. tostring(err))
    table.remove(games)
    clock = nil
  end
end
active = pinball

-- ---------------------------------------------------------------------
-- the room
-- ---------------------------------------------------------------------

local ident = btQuaternion(0, 0, 0, 1)
local UP = btQuaternion(btVector3(1, 0, 0), math.pi / 2)
local function yq(a) return btQuaternion(btVector3(0, 1, 0), a) end
local function vis(o, col)
  o.col = col
  pcall(function() o.collides = false end)
  v:add(o)
  return o
end
local function box(x, y, z, sx, sy, sz, col, q)
  local c = Cube(sx, sy, sz, 0)
  c.trans = btTransform(q or ident, btVector3(x, y, z))
  return vis(c, col)
end
local function cyl(x, y, z, r, h, col, q)
  local c = Cylinder(r, h, 0)
  c.trans = btTransform(q or UP, btVector3(x, y, z))
  return vis(c, col)
end

local X0, X1 = -470, 650                               -- side walls
local Z0, Z1 = -150, 960                               -- back wall, front of the room
local H = 340                                         -- wall height (the views look down from up to 3.2 m)
local WOOD, GROOVE, CARPET = "#6b4423", "#3e2612", "#5a3a24"

-- floor (just above the pinball machine's own), walls with panelling
box((X0 + X1) / 2, FLOOR - 0.8, (Z0 + Z1) / 2, X1 - X0, 2, Z1 - Z0, CARPET)
box((X0 + X1) / 2, FLOOR + H / 2, Z0 - 2, X1 - X0, H, 4, WOOD)
box(X0 - 2, FLOOR + H / 2, (Z0 + Z1) / 2, 4, H, Z1 - Z0, "#5e3b1e")
box(X1 + 2, FLOOR + H / 2, (Z0 + Z1) / 2, 4, H, Z1 - Z0, "#5e3b1e")
box((X0 + X1) / 2, FLOOR + H / 2, Z1 + 2, X1 - X0, H, 4, WOOD)          -- front wall
for x = X0 + 20, X1 - 10, 20 do
  box(x, FLOOR + H / 2, Z0 + 0.2, 1.2, H, 1, GROOVE)
  box(x, FLOOR + H / 2, Z1 - 0.2, 1.2, H, 1, GROOVE)
end
-- the door, in the front wall
box(-150, FLOOR + 105, Z1 - 1.2, 92, 210, 2, "#4a2a12")
box(-150, FLOOR + 105, Z1 - 1.0, 100, 218, 1.6, "#2b1608")
cyl(-186, FLOOR + 100, Z1 - 3, 2.5, 4, "#c9a227", ident)
for z = Z0 + 20, Z1 - 10, 20 do
  box(X0 + 0.2, FLOOR + H / 2, z, 1, H, 1.2, GROOVE)
  box(X1 - 0.2, FLOOR + H / 2, z, 1, H, 1.2, GROOVE)
end
-- skirting board and a picture rail
for _, y in ipairs({ FLOOR + 6, FLOOR + 200 }) do
  box((X0 + X1) / 2, y, Z0 + 0.8, X1 - X0, 4, 1.5, "#2b1608")
  box((X0 + X1) / 2, y, Z1 - 0.8, X1 - X0, 4, 1.5, "#2b1608")
  box(X0 + 0.8, y, (Z0 + Z1) / 2, 1.5, 4, Z1 - Z0, "#2b1608")
  box(X1 - 0.8, y, (Z0 + Z1) / 2, 1.5, 4, Z1 - Z0, "#2b1608")
end

-- a rug under each table
local function rug(x, z, w, d, c1, c2)
  box(x, FLOOR + 0.35, z, w, 0.2, d, c1)
  box(x, FLOOR + 0.45, z, w - 12, 0.2, d - 12, c2)
  box(x, FLOOR + 0.55, z, w - 24, 0.2, d - 24, c1)
end
local px, pz = POOL_OFFSET.x, POOL_OFFSET.z
rug(px, pz, 400, 260, "#8b1e1e", "#b8860b")
if snooker then rug(SNOOKER_OFFSET.x, SNOOKER_OFFSET.z, 520, 320, "#1e3a5f", "#b8860b") end
if bumper then rug(BUMPER_OFFSET.x, BUMPER_OFFSET.z, 260, 200, "#2f5d2f", "#b8860b") end

-- the bar along the back wall, left of the pinball machine, with stools
local bx = -270
box(bx, FLOOR + 55, Z0 + 22, 220, 110, 40, "#4a2a12")
box(bx, FLOOR + 112, Z0 + 26, 232, 5, 52, "#2b1608")
for i = 0, 3 do box(bx - 90 + i * 60, FLOOR + 55, Z0 + 42.2, 40, 90, 1, "#5a3418") end
for i = -1, 1 do
  cyl(bx + i * 65, FLOOR + 38, Z0 + 75, 2, 76, "#999999")
  cyl(bx + i * 65, FLOOR + 77, Z0 + 75, 14, 5, "#8b0000")
  cyl(bx + i * 65, FLOOR + 25, Z0 + 75, 10, 1.5, "#999999")
end
-- shelves behind it
for i = 0, 1 do box(bx, FLOOR + 150 + i * 30, Z0 + 6, 180, 2, 12, "#2b1608") end
local bottleCols = { "#1f6f3a", "#6b3a1e", "#c9a227", "#8e1b1b", "#1f4f8f" }
for i = 0, 13 do
  cyl(bx - 80 + i * 12.5, FLOOR + 159 + (i % 2) * 30, Z0 + 6, 2.4, 16, bottleCols[i % 5 + 1], ident * UP)
end

-- the neon sign above the bar
local BITS = { 1, 2, 4, 8, 16, 32, 64 }
local CH = { A = 119, E = 121, G = 61, L = 56, M = 55, O = 63, P = 115, R = 80, [" "] = 0 }
local function neon(text, x0, y0, z, scale, col)
  local W, Hh, T = 1.9 * scale, 3.2 * scale, 0.28 * scale
  local pitch = 3.1 * scale
  local segs = { { 0, Hh / 2, W, T }, { W / 2, Hh / 4, T, Hh / 2 }, { W / 2, -Hh / 4, T, Hh / 2 },
                 { 0, -Hh / 2, W, T }, { -W / 2, -Hh / 4, T, Hh / 2 }, { -W / 2, Hh / 4, T, Hh / 2 },
                 { 0, 0, W, T } }
  local parts = {}
  for k = 1, #text do
    local bits = CH[text:sub(k, k)] or 0
    for s, gg in ipairs(segs) do
      if bits % (2 * BITS[s]) >= BITS[s] then
        parts[#parts + 1] = box(x0 + (k - 1) * pitch + gg[1], y0 + gg[2], z, gg[3], gg[4], 0.8, col)
      end
    end
  end
  return parts
end
local sign = neon("GAME ROOM", bx - 110, FLOOR + 222, Z0 + 1.5, 6, "#ff9f1c")

-- the jukebox, right of the pinball machine
local jx = 88
box(jx, FLOOR + 75, Z0 + 20, 70, 150, 36, "#8b0000")
cyl(jx, FLOOR + 150, Z0 + 20, 34.6, 35.2, "#ffb300", ident)
box(jx, FLOOR + 95, Z0 + 38.6, 50, 50, 1, "#ffd9a0")
local jukeBars = {}
for i = 0, 5 do jukeBars[#jukeBars + 1] = box(jx - 22 + i * 9, FLOOR + 60, Z0 + 38.6, 3, 50, 1, (i % 2 == 0) and "#ff6f00" or "#00e5ff") end
box(jx, FLOOR + 30, Z0 + 38.6, 56, 20, 1, "#3a0000")

-- the dartboard on the left wall, and a rack of cues
for i, r in ipairs({ 24, 21, 16, 11, 5, 2 }) do
  cyl(X0 + 0.5 + i * 0.4, FLOOR + 170, 20, r, 0.5,
      (i % 2 == 0) and "#1a1a1a" or ((i >= 5) and "#c1121f" or "#e8dcc0"), yq(math.pi / 2))
end
box(X0 + 2, FLOOR + 110, 330, 3, 120, 60, "#3b1d0c")
for i = 0, 3 do
  cyl(X0 + 5, FLOOR + 95, 308 + i * 14, 1.2, 145, (i % 2 == 0) and "#e8cf9a" or "#c9a66b", UP)
end

-- a sofa against the left-hand wall, facing the tables, with a coffee table
do
  local sx, sz = X0 + 50, 560
  box(sx, FLOOR + 22, sz, 80, 44, 200, "#6b2d1e")                  -- seat
  box(sx - 32, FLOOR + 60, sz, 16, 60, 200, "#6b2d1e")             -- back
  box(sx, FLOOR + 40, sz - 104, 80, 80, 16, "#5a2418")             -- arms
  box(sx, FLOOR + 40, sz + 104, 80, 80, 16, "#5a2418")
  for i = -1, 1, 2 do box(sx + 2, FLOOR + 46, sz + i * 42, 60, 6, 80, "#7d3a28") end   -- cushions
  local tx = sx + 110
  box(tx, FLOOR + 40, sz, 60, 4, 120, "#3b2412")                   -- coffee table
  for i = -1, 1, 2 do for j = -1, 1, 2 do
    box(tx + i * 24, FLOOR + 19, sz + j * 52, 5, 38, 5, "#2b1608")
  end end
  cyl(tx, FLOOR + 46, sz - 30, 4, 10, "#c9a227", ident * UP)       -- a trophy
  cyl(tx - 5, FLOOR + 43, sz + 25, 9, 2, "#1a1a1a", ident * UP)    -- an ashtray (it's 1975)
end

-- the back wall's right-hand end: a second rack of cues under a POOL sign
local rx = 420
box(rx, FLOOR + 110, Z0 + 2, 90, 120, 3, "#3b1d0c")
for i = 0, 5 do
  cyl(rx - 35 + i * 14, FLOOR + 95, Z0 + 5, 1.2, 145, (i % 2 == 0) and "#e8cf9a" or "#c9a66b", UP)
end
local sign2 = neon("POOL", rx - 28, FLOOR + 205, Z0 + 1.5, 6, "#39d0ff")

-- wall lights: warm sconces
local sconces = {}
for _, s in ipairs({ { 40, Z0 + 3 }, { 250, Z0 + 3 }, { 560, Z0 + 3 } }) do
  sconces[#sconces + 1] = box(s[1], FLOOR + 185, s[2], 18, 12, 6, "#ffe0a0")
end
for _, z in ipairs({ 120, 300, 500, 700, 900 }) do
  sconces[#sconces + 1] = box(X0 + 3, FLOOR + 185, z, 6, 12, 18, "#ffe0a0")
end
for _, z in ipairs({ 245, 540, 870 }) do              -- between the scoreboards
  sconces[#sconces + 1] = box(X1 - 3, FLOOR + 185, z, 6, 12, 18, "#ffe0a0")
end

-- ---------------------------------------------------------------------
-- walking round: Tab goes to the next game, then a look round the room
-- ---------------------------------------------------------------------

local ROOM_VIEW = { pos = btVector3(X0 + 30, FLOOR + 360, Z1 - 30), look = btVector3(150, FLOOR + 10, 280) }
local roomHelp = [[
REC ROOM -- looking round   (Tab: walk over to the pinball machine; Shift+Tab: back)

A 1970s basement games room: Pinball Machine A against the back wall, a
clock on the wall, the bar, the jukebox; the pool, bumper pool and snooker
tables down the right-hand side; a sofa, the dartboard.
Tab walks between them:
  at the pinball machine -- its keys (Shift / Z / flippers, Return plunger,
                            Space shake, 1 new game, P computer, V its views)
  at the pool table      -- its keys (arrows aim, Up/Down force, W/A/S/D spin,
  and the snooker table     Space shoot, P computer, V/B/T its cameras)
  at the bumper pool     -- the same, with X / Z to choose your ball (Tab
  table                     walks on), O the second player, L the level
  at the clock           -- its keys (T tune its gravity, G lock it, S sound);
                            its gravity is the clock_gravity slider
  looking round the room -- the mouse turns and zooms the view as usual
]]

local function goTo(g)
  -- let go of any keys still held at the game we're leaving
  if active then
    for key in pairs(active.down) do
      local f = active.callbacks.onKey
      if f then pcall(f, active.N, key, false) end
    end
    active.down = {}
  end
  active = g
  if g == pinball then
    local b = pinball.env.TF.board
    b.setView(b.view or 1)
    realV:setHelpText(pinball.header() .. pinball.help)
  elseif g and (g == pool or g == snooker or g == bumper) then
    local TF = g.env.TF
    TF.setView(TF.S.view or "table")
    realV:setHelpText(g.header() .. g.help)
  elseif g and g == clock then
    local c = realV.cam
    local o, S = clock.off, CLOCK_SCALE
    c:setUpVector(btVector3(0, 1, 0), true)
    c.pos = btVector3(o.x + 30 * S, o.y + 145 * S + 8, o.z + 560 * S + 175)
    c.look = btVector3(o.x + 30 * S, o.y + 135 * S, o.z + 400 * S)
    realV:setHelpText(clock.header() .. clock.help)
  else
    local c = realV.cam
    c:setUpVector(btVector3(0, 1, 0), true)
    c.pos = ROOM_VIEW.pos
    c.look = ROOM_VIEW.look
    realV:setHelpText(roomHelp)
  end
end

v:onKey(function(N, key, down)
  if key == "Tab" then
    if down then
      if active == nil then goTo(games[1]) else goTo(nextOf(active)) end
    end
    return true
  end
  if key == "Backtab" then                -- Shift+Tab: back the other way
    if down then
      local prev = nil
      for i, x in ipairs(games) do if x == active then prev = games[i - 1] end end
      if active == nil then prev = games[#games] end
      goTo(prev)
    end
    return true
  end
  if not active then return false end
  local sc = active.shortcuts[key]
  if sc then
    if down then sc(active.N) end
    return true
  end
  local f = active.callbacks.onKey
  if not f then return false end
  if down then active.down[key] = true else active.down[key] = nil end
  return f(active.N, key, down)
end)

-- the neon flickers now and then; the jukebox's bars dance
local flick = 0
local function roomTick(N)
  if N % 90 == 0 and math.random() < 0.35 then flick = 6 end
  if flick > 0 then
    flick = flick - 1
    local col = (flick % 2 == 0) and "#ff9f1c" or "#5a3308"
    for _, p in ipairs(sign) do p.col = col end
  end
  if N % 12 == 0 then
    for i, bar in ipairs(jukeBars) do
      bar.col = ((i + math.floor(N / 12)) % 3 == 0) and "#ffffff" or ((i % 2 == 0) and "#ff6f00" or "#00e5ff")
    end
  end
end

-- Taking turns. Between frames the games are running and the clock is
-- waiting (so keys and anything else between frames see the games'
-- settings); a clock frame swaps them over in preSim, just before the
-- step, and back in postSim, just after.
local clockTurn, lastWasClock = false, false
local lost, report = 0, { frames = 0 }     -- time the clock has lost, for the console
local clockStart, clockN0                -- real time and clock frames when it started
local function whose(onClock)
  for _, g in ipairs(games) do g.setPaused((g == clock) ~= onClock) end
  applyPhysics(onClock and clock.physics or ROOM_PHYSICS)
end
-- A table that's waiting for a shot, with every ball still, has its balls
-- taken out of the simulation (the tables keep them awake on purpose, so
-- otherwise they'd be solved 900 times a second sitting still). They're
-- put back the moment a stroke begins (or anything moves them). The
-- table's own scripts, its computer player included, carry on as usual.
local WAITING = { aim = true, inhand = true, cleared = true, over = true }
local function ballBodies(g)
  local list = {}
  for _, b in pairs(g.env.TF.balls) do
    local ok, body = pcall(function() return b.obj.body end)
    if ok and body then list[#list + 1] = body end
  end
  return list
end
local function restTable(g)
  local T = g.env.TF
  if not (T and T.S and T.balls) then return end
  local still = WAITING[T.S.state] == true
  if still and not g.resting then
    for _, body in ipairs(ballBodies(g)) do
      local lv, av = body:getLinearVelocity(), body:getAngularVelocity()
      if lv.x * lv.x + lv.y * lv.y + lv.z * lv.z > 0.25 or av.x * av.x + av.y * av.y + av.z * av.z > 0.25 then
        still = false
        break
      end
    end
  end
  if still and not g.resting then
    g.resting = {}
    for _, body in ipairs(ballBodies(g)) do
      g.resting[#g.resting + 1] = { body, body:getActivationState() }
      body:forceActivationState(5)        -- DISABLE_SIMULATION
    end
  elseif not still and g.resting then
    for _, r in ipairs(g.resting) do r[1]:forceActivationState(r[2]) end
    g.resting = nil
  end
end

local function call(k, all)
  local err
  for _, g in ipairs(games) do
    local f = g.callbacks[k]
    if f and (all or not g.paused) then
      local ok, e = pcall(f, g.N)
      if not ok and not err then err = g.name .. ": " .. tostring(e) end
    end
  end
  return err
end
v:preSim(function(N)
  if clock then
    -- the clock's frames are owed to it by the real seconds gone by (a
    -- stopwatch, never the time of day); it takes a turn when it's owed
    -- one, but never two in a row, so the games always get at least every
    -- other frame (if the room can't manage 50 frames a second, the clock
    -- falls behind rather than the games stopping)
    local fps = 1000 / clock.physics.animationPeriod
    local now = v:getTime()
    if not clockStart then clockStart, clockN0 = now, clock.N end
    local owed = (now - clockStart) * fps - (clock.N - clockN0)
    if owed > MAX_OWED * fps then        -- bpp was paused, or badly held up: don't race
      lost = lost + (owed - MAX_OWED * fps) / fps
      clockStart = now - ((clock.N - clockN0) + MAX_OWED * fps) / fps
      owed = MAX_OWED * fps
    end
    -- say so (once every 10 s at most) when the clock has lost time
    report.frames = report.frames + 1
    if not report.t then report.t, report.clockN = now, clock.N end
    if now - report.t >= 10 then
      if lost > 0.05 then
        local el = now - report.t
        print(string.format("REC ROOM: the clock lost %.1f s in the last %.0f s. The room ran at %.0f frames a second; " ..
                            "the clock needs %.0f of them, at most every other one, so it keeps time only when the room " ..
                            "manages %.0f or more (and isn't held up).",
                            lost, el, report.frames / el, fps, 2 * fps))
      end
      lost, report.t, report.frames, report.clockN = 0, now, 0, clock.N
    end
    clockTurn = owed >= 1 and not lastWasClock
    lastWasClock = clockTurn
    if clockTurn then whose(true) end
  end
  for _, g in ipairs(games) do if not g.paused then g.N = g.N + 1 end end
  if not clockTurn then
    for _, g in ipairs(games) do
      if g == pool or g == snooker or g == bumper then restTable(g) end
    end
  end
  local err = call("preSim")
  if err then error(err, 0) end
end)
v:postSim(function(N)
  local err = call("postSim")
  if clockTurn then whose(false); clockTurn = false end
  roomTick(N)
  if err then error(err, 0) end
end)
-- Garbage: bpp keeps Lua's collector stopped, and each game used to
-- collect everything every couple of seconds -- here that would be the
-- whole room's garbage at once, a pause long enough to be felt. Instead
-- the room collects a little every frame: it steps the collector until the
-- cycle finishes or GC_BUDGET seconds have gone, then stops it again.
GC_BUDGET = GC_BUDGET or 0.002
v:preDraw(function(N)
  local t0 = os.clock()
  repeat
    local done = collectgarbage("step", 0)
  until done or os.clock() - t0 > GC_BUDGET
  collectgarbage("stop")
  local err = call("preDraw", true)
  if err then error(err, 0) end
end)

TF = { pinball = pinball, pool = pool, snooker = snooker, bumper = bumper, clock = clock, goTo = goTo, games = games,
       at = function() return active end }
-- with the clock taking 25 frames a second, the room needs 85 for the
-- games to keep their 60: 12 ms a frame (83 a second)
if clock then
  whose(false)
  if v.animationPeriod then v.animationPeriod = 12 end
end
goTo(pinball)
