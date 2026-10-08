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
-- so each frame bpp steps the games, and then, whenever the clock is due a
-- step, the room freezes the games and steps the clock once more with its
-- own settings; it gets 25 steps for each real second, as it does on its
-- own. (An older bpp without v:stepSimulation means taking turns, frame by
-- frame.) The
-- room collects Lua's garbage a little every frame. Everything keeps running
-- wherever you stand.
--
-- FILES: the pinball and pool folders must sit next to this one (as
-- pinball-machine-a/ and pool-table/, or Pinball/ and Pool/). The snooker
-- and bumper pool tables (snooker-table/ or Snooker/, bumper-pool/ or
-- BumperPool/) and the clock (../Clocks/ or ../../WyomingWill/Clocks/) are
-- used if they're there; without one, the room simply goes without it.
--
-- MORE GAMES: any other bpp script can join the room with one line in
-- MORE_GAMES, below: on the floor, on a table or on a shelf, where you say,
-- at the size you say. It comes with WyomingWill's Jansen walker and
-- koppi's marble run.
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
                       iterations = 24, erp = 0.2, erp2 = 0.2, cfm = 0 }
-- bpp's and Bullet's own starting values, for a game that doesn't set them
local BPP_PHYSICS = { timeStep = 1 / 25, fixedTimeStep = 1 / 100, maxSubSteps = 7,
                      iterations = 10, erp = 0.2, erp2 = 0.2, cfm = 0, animationPeriod = 40 }
local MAX_OWED = 5.0      -- the clock catches up on at most this many seconds' frames
MAX_CATCHUP = MAX_CATCHUP or 4   -- and takes at most this many steps in one frame
-- How the clock gets its steps. OLD_TURNS = false (the default): with a
-- bpp that has v:stepSimulation, the clock is stepped inside the games'
-- frames, so the games get all 60 (full speed). OLD_TURNS = true: it takes
-- turns with the games, frame by frame -- on a 60 Hz screen the games get
-- about 35 frames a second (they run at about 58% speed) and the room uses
-- the least processor. Both keep the clock's time the same. (The games in
-- MORE_GAMES, below, need the first way: with OLD_TURNS they run with the
-- tables' physics settings instead of their own.)
if OLD_TURNS == nil then OLD_TURNS = false end
local CAN_STEP = (v.stepSimulation ~= nil) and not OLD_TURNS
local function applyPhysics(p)
  v.timeStep, v.fixedTimeStep, v.maxSubSteps = p.timeStep, p.fixedTimeStep, p.maxSubSteps
  if v.setSolverIterations then v:setSolverIterations(p.iterations) end
  v:setErp(p.erp)
  v:setErp2(p.erp2)
  if v.setCfm then v:setCfm(p.cfm) end
end
applyPhysics(ROOM_PHYSICS)
if v.animationPeriod then v.animationPeriod = 16 end

-- The cost meter: what each frame spends its time on, measured every second
-- and printed to the console every METER_PRINT seconds (0: never). METER =
-- false turns it off. (The Shortcuts pane holds only the keys: something
-- written there every second kept it from being scrolled.)
if METER == nil then METER = true end
METER_PRINT = METER_PRINT or 10
local meterText = ""
local function showHelp(text)
  v:setHelpText(text)
end
-- A game's news (whose turn, the score, a game won): to the console, from
-- the game you're at only, so the console isn't filled by every table at once
-- (see setStatusText below); walking over to a game shows where it stands
local function showStatus(g, text)
  if text and text ~= "" then print(text) end
end
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
--   opts.paramStart -- starting values for its sliders, by name, used in
--                      place of the ones its script gives them
--   opts.noCamera   -- never let it move the camera (the room has its own
--                      view of it)
--   opts.ownPhysics -- it runs with its own physics settings (step, solver,
--                      ERP), taking turns with the others; otherwise the
--                      room's settings apply
--   opts.turn       -- turned this many degrees about the upright (seen
--                      from above, anticlockwise: 90 turns its front, +z,
--                      to face +x)
--   opts.extra      -- one of MORE_GAMES: its ground plane (a Plane) is
--                      left out (the room gives it a floor of its own,
--                      opts.patch), its terrain is cut to that patch, and
--                      its gravity starts at bpp's own
--   opts.patch      -- { w, d }: that floor's size in cm, about its origin
local function makeGame(name, dir, offset, opts)
  opts = opts or {}
  local S = opts.scale or 1
  local g = { name = name, dir = dir, off = offset, callbacks = {}, help = "", down = {},
              shortcuts = {}, bodies = {}, objects = {}, bodyObj = {}, physics = {}, N = 0,
              ownPhysics = opts.ownPhysics, scale = S, turn = opts.turn or 0, extra = opts.extra,
              prefix = opts.params or "" }
  for k, val in pairs(BPP_PHYSICS) do g.physics[k] = val end
  if opts.extra then g.gravity = btVector3(0, -9.81, 0) end        -- (bpp's own)
  local turn = math.rad(opts.turn or 0)
  local cs, sn = math.cos(turn), math.sin(turn)
  local ROT = btQuaternion(btVector3(0, 1, 0), turn)
  local OFF = btTransform(ROT, offset)
  local INV = OFF:inverse()
  local ox, oy, oz = offset.x, offset.y, offset.z
  local function sv(p) return btVector3(p.x * S, p.y * S, p.z * S) end   -- a length, scaled
  -- a direction (gravity), turned with the game and scaled
  local function rv(p) return btVector3((p.x * cs + p.z * sn) * S, p.y * S, (-p.x * sn + p.z * cs) * S) end
  local function toWorld(p)
    return btVector3((p.x * cs + p.z * sn) * S + ox, p.y * S + oy, (-p.x * sn + p.z * cs) * S + oz)
  end
  local function toLocal(q)
    local x, y, z = q.x - ox, q.y - oy, q.z - oz
    return btVector3((x * cs - z * sn) / S, y / S, (x * sn + z * cs) / S)
  end
  g.toWorld, g.toLocal = toWorld, toLocal
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
      -- (its position in a transform stays scaled, as the game's own
      -- btTransforms are: see env.btTransform)
      if k == "trans" then return shiftT(r.trans, INV) end
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
      if k == "pos" then
        if turn == 0 then r.pos = toWorld(val)
        else r.trans = shiftT(btTransform(shiftT(r.trans, INV):getRotation(), sv(val)), OFF) end   -- (keeping its turn)
      elseif k == "trans" then r.trans = shiftT(val, OFF)
      else r[k] = val end
    end,
  }
  local function wrap(o) return setmetatable({ __real = o }, objMeta) end
  -- a new object of the game's: when the game is turned, it starts out
  -- turned with it (at the game's origin), as it would start out square to
  -- the world on its own
  local function made(o)
    if turn ~= 0 then o.trans = OFF end
    return wrap(o)
  end

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
    if g.gravity then pcall(function() body:setGravity(rv(g.gravity)) end) end
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
  local addedParams = {}
  local vpFns = {}
  local vp = setmetatable({}, {
    __index = function(_, k)
      if k == "cam" then return cam end
      if k == "gravity" then return g.gravity or realV.gravity end
      if k == "add" then
        return function(_, o)
          if type(o) == "table" and rawget(o, "__dummy") then return end
          local r = wrapped(o)
          realV:add(r)
          g.objects[r] = true
          local ok, body = pcall(function() return r.body end)
          if ok and body then
            g.bodies[#g.bodies + 1] = body
            g.bodyObj[body] = r
            g.moving = nil                  -- (the list of its moving bodies: made again)
            applyGravity(body)
            if opts.awake and not body:isStaticObject() then body:forceActivationState(4) end   -- DISABLE_DEACTIVATION
          end
        end
      end
      if k == "remove" then
        return function(_, o)
          if type(o) == "table" and rawget(o, "__dummy") then return end
          local r = wrapped(o)
          -- (its body leaves the list: once the object is gone, so is the body)
          local ok, body = pcall(function() return r.body end)
          if ok and body then
            for i = #g.bodies, 1, -1 do
              if rawequal(g.bodyObj[g.bodies[i]], r) then g.bodyObj[g.bodies[i]] = nil; table.remove(g.bodies, i) end
            end
            g.moving = nil
          end
          g.objects[r] = nil
          realV:remove(r)
        end
      end
      if k == "addConstraint" or k == "removeConstraint" then
        return function(_, c, ...) return realV[k](realV, wrapped(c), ...) end
      end
      if k == "preSim" or k == "postSim" or k == "preDraw" or k == "postDraw" or k == "onKey"
         or k == "onParamChanged" or k == "onCommand" or k == "onJoystick" or k == "onSpaceNavigator" then
        return function(_, fn) g.callbacks[k] = fn end
      end
      if k == "setCfm" then return function(_, x) g.physics.cfm = x end end
      if k == "addShortcut" then return function(_, keys, fn) g.shortcuts[keys] = fn end end
      if k == "removeShortcut" then return function(_, keys) g.shortcuts[keys] = nil end end
      if k == "addParam" then
        return function(_, n, val, ...)
          -- (opts.paramStart: a slider's starting value, in place of the one
          -- the game's script gives it the first time it adds it)
          local start = opts.paramStart and opts.paramStart[n]
          if start and not addedParams[n] and type(val) == "number" then val = start end
          addedParams[n] = true
          return realV:addParam(prefix .. n, val, ...)
        end
      end
      if k == "getParam" then return function(_, n) return realV:getParam(prefix .. n) end end
      if k == "setErp" or k == "setErp2" then
        local key = (k == "setErp") and "erp" or "erp2"
        return function(_, x) g.physics[key] = x end
      end
      if k == "setHelpText" then
        return function(_, text)
          g.help = text
          if active == g then showHelp(g.header() .. text) end
        end
      end
      if k == "setStatusText" then
        -- (once: a one-off, such as a shot's settings, not the game's standing)
        return function(_, text, once)
          if not once then g.status = text end
          if active == g then showStatus(g, text) end
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
    env.Cube = function(...) return made(realCube(...)) end
    env.Sphere = function(...) return made(realSphere(...)) end
    env.Cylinder = function(...) return made(realCylinder(...)) end
    env.Mesh = function(path, ...) return made(realMesh(fix(path), ...)) end
    if realOpenSCAD then env.OpenSCAD = function(...) return made(realOpenSCAD(...)) end end
  else
    -- sizes scaled; masses kept
    local function sized(ctor, nSizes)
      return function(a, ...)
        if type(a) ~= "number" then
          if a == nil then return made(ctor()) end
          return made(ctor(sv(a), ...))          -- the btVector3-of-sizes forms
        end
        local args = { a, ... }
        for i = 1, math.min(nSizes, #args) do args[i] = args[i] * S end
        return made(ctor(unpack(args)))
      end
    end
    env.Cube = sized(realCube, 3)
    env.Sphere = sized(realSphere, 1)
    env.Cylinder = sized(realCylinder, 2)
    -- meshes: OpenSCAD scales them (bpp's Mesh has no scale of its own)
    env.OpenSCAD = function(sdl, ...)
      return made(realOpenSCAD("module bpp_unscaled() {\n" .. sdl .. "\n}\nscale(" .. S .. ") bpp_unscaled();\n", ...))
    end
    env.Mesh = function(path, ...)
      local file = fix(path):gsub("\\", "/")
      return made(realOpenSCAD('scale(' .. S .. ') import("' .. file .. '");', ...))
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
  -- bpp's plain-number readers and setters (getPosXYZ and the rest, which
  -- make no garbage): handed the real object, and a position through the
  -- offset (and scale and turn), as obj.pos is; velocities and spins as they
  -- are, as obj.vel and obj.body are
  if getPosXYZ then
    local function real(o) return type(o) == "table" and rawget(o, "__real") or o end
    env.getPosXYZ = function(o)
      local x, y, z = getPosXYZ(real(o))
      x, y, z = x - ox, y - oy, z - oz
      return (x * cs - z * sn) / S, y / S, (x * sn + z * cs) / S
    end
    env.getVelXYZ = function(o) return getVelXYZ(real(o)) end
    env.getAngVelXYZ = function(o) return getAngVelXYZ(real(o)) end
    env.setVelXYZ = function(o, x, y, z) return setVelXYZ(real(o), x, y, z) end
    env.setAngVelXYZ = function(o, x, y, z) return setAngVelXYZ(real(o), x, y, z) end
    -- (both of the game's: the same offset either way)
    env.copyTrans = function(a, b) return copyTrans(real(a), real(b)) end
  end
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
  if opts.extra then
    -- its ground plane (an endless one, in the room) is left out: the room
    -- gives it a floor of its own. What the game does with it does nothing.
    env.Plane = function()
      return setmetatable({ __dummy = true }, { __index = function() return function() end end,
                                                __newindex = function() end })
    end
    -- its terrain: moved, turned and scaled with it, and cut to its patch
    -- of floor (what's outside it would cover the room). The game still
    -- numbers the triangles as it made them.
    if Terrain then
      env.Terrain = function(...)
        local t = wrap(Terrain(...))
        local real = rawget(t, "__real")
        local n, kept = 0, {}
        local hw, hd = opts.patch[1] / 2 / S, opts.patch[2] / 2 / S
        local function inside(p) return math.abs(p.x) <= hw and math.abs(p.z) <= hd end
        rawset(t, "addTriangle", function(_, a, b, c)
          if inside(a) and inside(b) and inside(c) then
            kept[n] = real:getNumTriangles()
            real:addTriangle(toWorld(a), toWorld(b), toWorld(c))
          end
          n = n + 1
        end)
        rawset(t, "getNumTriangles", function() return n end)
        rawset(t, "setTriangleColor", function(_, i, ...)
          if kept[i] then real:setTriangleColor(kept[i], ...) end
        end)
        rawset(t, "getTriangleColor", function(_, i, ...)
          if kept[i] then return real:getTriangleColor(kept[i], ...) end
        end)
        return t
      end
    end
  end
  g.env = env
  -- Its fixed parts (mass 0) asleep, as Bullet puts them when they're
  -- added: a script that wakes one (the walkers keep their floor awake)
  -- would have it tested against every other fixed thing it touches, on
  -- every step of every game. A sleeping one still stops what hits it.
  g.settle = function()
    for _, b in ipairs(g.bodies) do
      if b:isStaticObject() then b:forceActivationState(2) end    -- ISLAND_SLEEPING
    end
  end
  -- (and where everything it made was when it had loaded, for putting it
  -- back as it started)
  -- (again after a slider of its own made it build itself again, as the
  -- walker's terrain slider does: when the parts it started with are gone)
  g.started = function(again)
    if again then
      local gone = false
      for o in pairs(g.startTrans) do if not g.objects[o] then gone = true; break end end
      if not gone then return end
    end
    g.settle()
    g.startTrans = {}
    for o in pairs(g.objects) do
      g.startTrans[o] = btTransform(o.trans:getRotation(), o.pos)
    end
    -- (paused, it takes in anything new it has made)
    if g.paused then g.setPaused(false); g.setPaused(true) end
  end
  g.load = function(file)
    env.dofile(file)
    if opts.extra then g.started() end
  end
  -- Putting it back as it started: everything it made as it loaded goes
  -- back where it was then, at rest (its own script carries on as it was).
  -- Nothing is taken away and made again, so it costs no memory however
  -- often it happens.
  g.putBack = function()
    local zero = btVector3(0, 0, 0)
    for o, t in pairs(g.startTrans) do
      o.trans = t
      local ok, body = pcall(function() return o.body end)
      if ok and body and not body:isStaticObject() then
        body:setLinearVelocity(zero)
        body:setAngularVelocity(zero)
        body:clearForces()
        if opts.awake then body:forceActivationState(4) else body:activate(true) end
      end
    end
    g.putBacks = (g.putBacks or 0) + 1
    print(string.format("REC ROOM: %s put back as it started (%d times so far)", g.name, g.putBacks))
  end
  -- taking away something it made after it had loaded (a marble that fell)
  g.takeAway = function(body)
    local o = g.bodyObj[body]
    if o then vp:remove(o) end
  end
  -- pausing: its moving bodies are taken out of the simulation (they cost
  -- nothing and keep their velocities), and its per-frame callbacks aren't
  -- called, until it's resumed. Its frame count N stops too, so it sees
  -- its own frames one after another, as it does on its own.
  -- (only the bodies that can move: most of a game's -- rails, walls, the
  -- scoreboard's segments -- never do, and going through all of them, some
  -- 3,000 in the room, each time the clock or another game with its own
  -- physics took a step cost half a millisecond. The list is made when
  -- first needed, and again after the game adds or removes something.)
  local function movingBodies()
    if not g.moving then
      local list = {}
      for _, b in ipairs(g.bodies) do
        if not b:isStaticObject() then list[#list + 1] = b end
      end
      g.moving = list
    end
    return g.moving
  end
  g.setPaused = function(on)
    if on == (g.paused == true) then return end
    g.paused = on
    if on then
      local list = {}
      for _, b in ipairs(movingBodies()) do
        list[#list + 1] = b
        list[#list + 1] = b:getActivationState()
        b:forceActivationState(5)          -- DISABLE_SIMULATION
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

-- MORE GAMES: any bpp script, brought into the room with one line here.
-- The first thing on a line is its file, from this file's folder (or a
-- full path); everything else is optional:
--   on     = "floor", "table" or "wall": what it stands on. The room gives
--            it a patch of floor, a table, or a shelf on the wall nearest
--            x, z (its back to the wall, facing into the room). Its own
--            ground plane, if it makes one, is left out.
--   x, z   = where its middle goes, in cm. The room runs from x = -470
--            (left wall) to 650 (right wall), and from z = -150 (the back
--            wall, behind the pinball machine) to 960 (the door's wall).
--   size   = { w, d }: that floor patch, table top or shelf, in cm
--            (w across, d front to back, as the game is built); default
--            { 100, 60 }. When anything of the game leaves it (falls off,
--            walks off), the room puts the game back as it started
--            (something it made later, such as a marble, is just taken
--            away).
--   height = the table top or the shelf, in cm above the floor (default
--            75 for a table, 110 for a shelf)
--   turn   = turned this many degrees, anticlockwise seen from above
--            (default 0: its front, +z, toward the door; on a wall, it
--            faces into the room)
--   scale  = its size (0.1 a tenth; default 1). Its gravity and motors are
--            scaled to suit, so it moves as it does full size.
--   ground = the height of its own floor, in its own units (default 0):
--            that's what rests on the floor, table or shelf
--   name   = what Tab calls it (default: from the file's name)
--   awake  = true: its parts never go to sleep (for a demo that asks you
--            to turn deactivation off)
--   keep   = true: never put back
--   follow = true: while you're at it, the view follows it as it moves
--            (for something that walks about)
--   solid  = false: its floor patch, table top or shelf is only to look
--            at; nothing rests on it, and whatever falls off is caught by
--            the putting back instead. For a game that has a floor of its own
--            (the walker's terrain), or none it needs (the marble run): a
--            solid top costs time against a big moving mesh near it (the
--            marble run's wheel: 3 times the time).
-- Each one runs with its own physics settings (its own steps), as the
-- clock does. Tab walks to each, after the clock.
MORE_GAMES = MORE_GAMES or {
  { "../../koppi/marblerun.lua", on = "table", x = 250, z = -95, size = { 70, 50 }, scale = 2, ground = -0.5, awake = true, solid = false, name = "the marble run" },
  { "../Walkers/Jansen_6LegT.lua", on = "floor", x = -40, z = 330, size = { 300, 110 }, scale = 0.12, height = 2, solid = false, follow = true, name = "the walker" },
}

-- the clock, if it's to hand: shrunk to hang on the back wall, left of
-- the pinball machine. Its gravity slider is "clock_gravity" in the Params
-- pane (its script calls it "gravity"; the name is kept apart from any
-- other game's). The placing below is worked out for N7; the other clocks
-- are built differently (N2 on a 60 m plate) and would need their own.
CLOCK_FILE = CLOCK_FILE or "N7_Clock_handcheck.lua"
CLOCK_SCALE = CLOCK_SCALE or 0.25
-- The clock's gravity to start with. N7 in the room keeps 60.0 s a turn at
-- about 1215 (three nights' averages: 1215, 1215, 1214.7); its own script
-- starts at 1166. The slider and training (T, G) work as usual from here.
-- nil: start where the clock's script says.
if CLOCK_G == nil then CLOCK_G = 1215 end
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
                     { scale = S, params = "clock_", noCamera = true, ownPhysics = true,
                       paramStart = { gravity = CLOCK_G } })    games[#games + 1] = clock
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
    if g.extra then
      h = h .. "Its keys work while you're standing at it; its sliders, if it has any,\n"
              .. "are the " .. g.prefix .. " ones in the Params pane." .. (g.keep and "" or
              "\nIt's put back as it started when a part of it leaves its " .. g.on .. (g.on == "wall" and " shelf" or "")
              .. ".") .. "\n\n"
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

-- The light: high up over the left-hand side of the room (bpp's own is off
-- to the right, which had the right-hand wall and the scoreboards shade the
-- tables). It comes down steeply enough that the left-hand wall's shadow
-- stops short of the pinball machine and the clock. (x, y, z over w, as
-- OpenGL takes it: a light at -1000, 2800, 400.)
ROOM_LIGHT = ROOM_LIGHT or btVector4(-400, 1120, 160, 0.4)
v.glLight0 = ROOM_LIGHT

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
-- MORE_GAMES: each on its own floor patch, table or shelf
-- ---------------------------------------------------------------------

local extras = {}
local SUPPORT_HEIGHT = { floor = 0.7, table = 75, wall = 110 }
for _, spec in ipairs(MORE_GAMES) do
  local file = spec[1] or spec.file or ""
  local gdir, base = file:match("^(.*[/\\])([^/\\]+)$")
  if not gdir then gdir, base = "./", file end
  local on = spec.on or "floor"
  if not exists(gdir .. base) then
    print("REC ROOM: MORE_GAMES: can't find " .. file)
  elseif not SUPPORT_HEIGHT[on] then
    print("REC ROOM: MORE_GAMES: " .. file .. ": on = \"" .. tostring(on) .. "\"? (floor, table or wall)")
  else
    local w, d = (spec.size or {})[1] or 100, (spec.size or {})[2] or 60
    local x, z, turn = spec.x or 0, spec.z or 400, spec.turn
    if on == "wall" then
      -- the nearest wall: its back against it, facing into the room
      local walls = { { x - X0, 90 }, { X1 - x, -90 }, { z - Z0, 0 }, { Z1 - z, 180 } }
      table.sort(walls, function(a, b) return a[1] < b[1] end)
      turn = turn or walls[1][2]
      local t = walls[1][2]
      if t == 90 then x = X0 + d / 2 + 1 elseif t == -90 then x = X1 - d / 2 - 1
      elseif t == 0 then z = Z0 + d / 2 + 1 else z = Z1 - d / 2 - 1 end
    end
    turn = turn or 0
    local top = FLOOR + (spec.height or SUPPORT_HEIGHT[on])
    local S = spec.scale or 1
    local name = spec.name or ("the " .. base:gsub("%.lua$", ""):gsub("[_%-]+", " "))
    local prefix = (name:gsub("^the ", ""):gsub("%W+", "_")) .. "_"
    local g = makeGame(name, gdir, btVector3(x, top - (spec.ground or 0) * S, z),
                       { scale = S, turn = turn, extra = true, patch = { w, d }, awake = spec.awake,
                         noCamera = true, params = prefix, ownPhysics = CAN_STEP, motors = not CAN_STEP })
    g.on, g.top, g.x, g.z, g.w, g.d, g.keep, g.follow = on, top, x, z, w, d, spec.keep, spec.follow
    -- its support: a floor patch (a mat), a table or a shelf. Its top is
    -- solid; the rest is only to look at.
    local q = yq(math.rad(turn))
    local function at(lx, ly, lz)          -- a point on it, in the room
      local c, s = math.cos(math.rad(turn)), math.sin(math.rad(turn))
      return x + lx * c + lz * s, ly, z - lx * s + lz * c
    end
    local thick = (on == "floor") and 1 or 3
    local slabTop = (on == "floor") and FLOOR + SUPPORT_HEIGHT.floor or top     -- (a mat stays on the floor)
    local slab = Cube(w, thick, d, 0)
    slab.trans = btTransform(q, btVector3(x, slabTop - thick / 2, z))
    slab.col = (on == "floor") and "#3d5a40" or "#7a5230"
    slab.friction = 0.8
    if spec.solid == false then slab.collides = false end
    v:add(slab)
    if on == "table" then
      for i = -1, 1, 2 do for j = -1, 1, 2 do
        local lx, _, lz = at(i * (w / 2 - 5), 0, j * (d / 2 - 5))
        box(lx, (FLOOR + top - thick) / 2, lz, 5, top - thick - FLOOR, 5, "#4a2a12", q)
      end end
      local cx, _, cz = at(0, 0, 0)
      box(cx, top - thick - 4, cz, w - 6, 8, d - 6, "#5a3418", q)        -- the apron
    elseif on == "wall" then
      for i = -1, 1, 2 do                                                 -- brackets
        local lx, _, lz = at(i * (w / 2 - 8), 0, 0)
        box(lx, top - thick - 10, lz, 3, 20, d - 4, "#2b1608", q)
      end
    else
      local cx, _, cz = at(0, 0, 0)
      box(cx, slabTop - 0.9, cz, w + 6, 0.4, d + 6, "#b8860b", q)        -- the mat's edge
    end
    extras[#extras + 1] = g
    games[#games + 1] = g
    g.header = header(g)
    active = g
    local friction = realV.friction
    local ok, err = pcall(g.load, base)
    pcall(function() realV.friction = friction end)
    g.builtAt = v:getTime()
    if not ok then
      print("REC ROOM: " .. name .. " didn't load: " .. tostring(err))
      table.remove(games)
      table.remove(extras)
    end
  end
end
active = pinball

-- the middle of an extra's moving parts, and how far they spread from it
local function middleOf(g)
  return function()
    local pts = {}
    local sx, sy, sz = 0, 0, 0
    for _, b in ipairs(g.bodies) do
      if not b:isStaticObject() then
        local p = b:getCenterOfMassPosition()
        pts[#pts + 1] = p
        sx, sy, sz = sx + p.x, sy + p.y, sz + p.z
      end
    end
    local n = #pts
    if n == 0 then return nil end
    local m = btVector3(sx / n, sy / n, sz / n)
    local r = 0
    for _, p in ipairs(pts) do
      r = math.max(r, math.sqrt((p.x - m.x) ^ 2 + (p.y - m.y) ^ 2 + (p.z - m.z) ^ 2))
    end
    return m, r
  end
end
for _, g in ipairs(extras) do g.middle = middleOf(g) end

-- Putting back: when a part of it (its middle) is past the edge of its
-- floor patch, table or shelf, or has fallen below it, the game is put back
-- as it started -- or, if that part is something it made after it had
-- loaded (a marble), that part alone is taken away. (Put back again within
-- a few seconds: it doesn't fit its support, and is left as it is, with a
-- word in the console.)
local function checkExtra(g)
  if g.keep or g.stuck then return end
  local c, s = math.cos(math.rad(g.turn)), math.sin(math.rad(g.turn))
  local out, startOut = {}, false
  for _, b in ipairs(g.bodies) do
    if not b:isStaticObject() then
      local p = b:getCenterOfMassPosition()
      local dx, dz = p.x - g.x, p.z - g.z
      local lx, lz = dx * c - dz * s, dx * s + dz * c
      if math.abs(lx) > g.w / 2 or math.abs(lz) > g.d / 2 or p.y < g.top - 20 then
        out[#out + 1] = b
        if g.startTrans[g.bodyObj[b]] then startOut = true end
      end
    end
  end
  if startOut then
    if v:getTime() - g.builtAt < 5 then
      g.stuck = true
      print("REC ROOM: " .. g.name .. " doesn't fit its " .. g.on .. " (size = { " .. g.w .. ", " .. g.d ..
            " }): it's left as it is")
      return
    end
    local ok, err = pcall(g.putBack)
    g.builtAt = v:getTime()
    if not ok then
      g.stuck = true
      print("REC ROOM: " .. g.name .. " couldn't be put back: " .. tostring(err))
    end
  end
  for _, b in ipairs(out) do
    if not g.startTrans[g.bodyObj[b]] then g.takeAway(b) end
  end
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
  and the snooker table     Space shoot, P computer, V/B/T its cameras;
                            M: a match against the computer, or alone)
  at the bumper pool     -- the same, with X / Z to choose your ball (Tab
  table                     walks on), O the second player, L the level
  at the clock           -- its keys (T tune its gravity, G lock it, S sound);
                            its gravity is the clock_gravity slider
  looking round the room -- the mouse turns and zooms the view as usual
]]
if #extras > 0 then
  local names = {}
  for _, g in ipairs(extras) do names[#names + 1] = g.name:gsub("^the ", "") end
  roomHelp = roomHelp .. "  and, from MORE_GAMES     -- " .. table.concat(names, ", ") .. "\n"
end

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
  if g and g.status then showStatus(g, g.status) end
  if g == pinball then
    local b = pinball.env.TF.board
    b.setView(b.view or 1)
    showHelp(pinball.header() .. pinball.help)
  elseif g and (g == pool or g == snooker or g == bumper) then
    local TF = g.env.TF
    TF.setView(TF.S.view or "table")
    showHelp(g.header() .. g.help)
  elseif g and g == clock then
    local c = realV.cam
    local o, S = clock.off, CLOCK_SCALE
    c:setUpVector(btVector3(0, 1, 0), true)
    c.pos = btVector3(o.x + 30 * S, o.y + 145 * S + 8, o.z + 560 * S + 175)
    c.look = btVector3(o.x + 30 * S, o.y + 135 * S, o.z + 400 * S)
    showHelp(clock.header() .. clock.help)
  elseif g and g.extra then
    -- in front of it, looking at the middle of its moving parts (or of its
    -- support, if nothing of it moves), from far enough to see it whole
    local look, r = g.middle()
    look = look or btVector3(g.x, g.top + 15, g.z)
    local dist = math.min(math.max(g.w, g.d) * 0.8 + 60, math.max(60, 3 * (r or 1e9) + 40))
    g.lastMiddle = look
    local t = math.rad(g.turn)
    local c = realV.cam
    c:setUpVector(btVector3(0, 1, 0), true)
    c.pos = btVector3(look.x + math.sin(t) * dist, look.y + dist * 0.5, look.z + math.cos(t) * dist)
    c.look = look
    showHelp(g.header() .. g.help)
  else
    local c = realV.cam
    c:setUpVector(btVector3(0, 1, 0), true)
    c.pos = ROOM_VIEW.pos
    c.look = ROOM_VIEW.look
    showHelp(roomHelp)
  end
end

local HELD_BACK = { S = true, D = true, R = true, P = true }
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
  -- (P, looking round the room, would have bpp save every frame for
  -- POV-Ray: all 3,300 objects written to a file each frame, two frames a
  -- second. Easy to press by mistake -- it's snooker's "computer plays" --
  -- so here it only says how; the POV-Ray menu still does it.)
  if not active and key == "P" then
    if down then
      print("REC ROOM: P (save every frame for POV-Ray) is held back in the room view, " ..
            "so it can't be started by mistake; use the POV-Ray menu for that.")
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
  local used = false
  if f then
    if down then active.down[key] = true else active.down[key] = nil end
    used = f(active.N, key, down)
  end
  -- bpp's own one-letter keys change the whole room (S stops the
  -- simulation, D turns sleeping off, R reloads, P saves every frame for
  -- POV-Ray). At a game, they do only what that game uses them for, or
  -- nothing; looking round the room, they're bpp's as usual (all but P:
  -- see above).
  if not used and HELD_BACK[key] then return true end
  return used
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
-- whose(g): g's turn to be stepped, with its own settings, everything else
-- waiting; whose(nil): the games' turn, the clock and the others with their
-- own physics waiting
local function whose(x)
  for _, g in ipairs(games) do
    if x then g.setPaused(g ~= x) else g.setPaused(g == clock or g.ownPhysics == true) end
  end
  applyPhysics(x and x.physics or ROOM_PHYSICS)
end
-- ---------------------------------------------------------------------
-- the cost meter
-- ---------------------------------------------------------------------
-- Times are added up over each second and shown per frame, in ms.
--
-- Two stopwatches. `wall` is bpp's elapsed-time stopwatch (v:getTime), for
-- the meter's one-second windows and the gaps between frames: real time,
-- waiting included. `now` times short pieces of work (physics, scripts,
-- drawing, and the garbage allowance). It is v:getTime too when that is
-- fine-grained (a bpp whose getTime returns a double from nsecsElapsed).
-- An older bpp's getTime ticks in whole milliseconds, and since it is
-- single precision, ever more coarsely the longer bpp runs (every 2 ms
-- after 4.6 hours, every 8 ms after 18): there the processor clock,
-- os.clock, times the work instead. (It counts every thread, so if anything
-- it runs fast: a garbage allowance comes out shorter, never longer.)
local wall = function() return v:getTime() * 1000 end
local now
do
  local t0 = v:getTime()
  local t1 = t0
  repeat t1 = v:getTime() until t1 ~= t0
  local t2 = t1
  repeat t2 = v:getTime() until t2 ~= t1
  if t2 - t1 < 0.0001 then
    now = wall
  else
    now = function() return os.clock() * 1000 end
    print(string.format("REC ROOM: bpp's stopwatch ticks every %.1f ms; timing short work with the processor clock instead",
                        (t2 - t1) * 1000))
  end
end
local meter = { t0 = nil, longest = 0, lastDraw = nil, frames = 0, gameFrames = 0, clockFrames = 0,
                physGames = 0, physClock = 0, physOwn = {}, physOwnAll = 0, room = 0, gc = 0, draw = 0, draws = 0,
                scripts = {} }
local lastPrint = nil
THINK_FILL = THINK_FILL or 0.9
THINK_MIN, THINK_MAX = THINK_MIN or 0.5, THINK_MAX or 3
local thinkMs = THINK_MAX
local SHORT = {}
local function shortName(g)
  return SHORT[g] or (g.name:gsub("^the ", ""):gsub(" machine$", ""):gsub(" table$", ""))
end
-- (a bpp that skips what can't be seen says how many objects the last frame
-- drew, for the screen and into the shadow map)
local function drawnLineOneByOne()
  local ok, n = pcall(function() return realV.drawnObjects end)
  if not ok or type(n) ~= "number" then return "" end
  if not realV.culling then return "  drawn    everything (culling off)\n" end
  if realV.shadows then
    -- (and a bpp that records the still objects' shadows replays those)
    local okc, c = pcall(function() return realV.shadowCached end)
    if okc and type(c) == "number" and c > 0 then
      -- (and one that saves the still objects' depth copies it back instead)
      local oks, s = pcall(function() return realV.shadowFromSaved end)
      return string.format("  drawn    %d objects, %d into the shadow map and %d more from its %s\n",
                           n, realV.shadowCasters, c, (oks and s == true) and "saved depth" or "record")
    end
    return string.format("  drawn    %d objects, %d into the shadow map\n", n, realV.shadowCasters)
  end
  return string.format("  drawn    %d objects\n", n)
end
-- (a bpp that merges the still boxes and cylinders for the screen draws
-- those besides: "N objects + M merged")
local function drawnLine()
  local line = drawnLineOneByOne()
  local ok, m = pcall(function() return realV.screenMerged end)
  if ok and type(m) == "number" and m > 0 then
    line = line:gsub("(%d+) objects", "%1 objects + " .. m .. " merged", 1)
  end
  return line
end
-- (a bpp with the drawing timer, v.drawTiming, switched on: where the
-- drawing time went, on the processor and on the graphics card)
local function timingLine()
  local ok, on = pcall(function() return realV.drawTiming end)
  if not ok or on ~= true then return "" end
  local r = realV:drawTimingReport()
  if r == "" then return "" end
  return "  timing   " .. r .. "\n"
end
local function meterTick(t)
  if not METER then return end
  if not meter.t0 then meter.t0 = t; return end
  local el = (t - meter.t0) / 1000
  if el < 1 then return end
  local budget = (v.animationPeriod or 16)
  if meter.frames == 0 then
    -- the simulation isn't running (bpp still draws)
    local d = math.max(meter.draws, 1)
    meterText = string.format(
      "COST METER -- the simulation is paused\n" ..
      "  %.0f frames drawn a second: drawing %.2f, garbage %.2f ms each\n\n",
      meter.draws / el, meter.draw / d, meter.gc / d)
  else
    -- (physics and scripts happen once per simulated frame, drawing and
    -- garbage once per drawn frame; while it runs, those are the same)
    local n, d = meter.frames, math.max(meter.draws, 1)
    local per = function(x) return x / n end
    local parts, busy = {}, 0
    for _, g in ipairs(games) do
      local x = per(meter.scripts[g] or 0)
      busy = busy + x
      parts[#parts + 1] = string.format("%s %.2f", shortName(g), x)
    end
    local room = per(meter.room)
    busy = busy + room + per(meter.physGames) + per(meter.physClock) + per(meter.physOwnAll) + meter.gc / d + meter.draw / d
    local own = ""
    for _, g in ipairs(extras) do own = own .. string.format(", %s %.2f", shortName(g), per(meter.physOwn[g] or 0)) end
    local fps = meter.frames / el
    -- how long a frame actually had (the screen may hold frames to its own
    -- rate, 60 a second, whatever the room asks for), and how much of the
    -- time the room was working
    local period = 1000 / fps
    local load = busy / period
    -- The tables' computer players think a little each frame (PLAN_BUDGET
    -- seconds; 3 ms on their own). Here they get what the frame has to
    -- spare: the room aims to fill THINK_FILL of each 1/60 s, so whatever
    -- the rest of the room took last second (the tables' own scripts
    -- counted at their usual cost), the thinking gets the remainder,
    -- between THINK_MIN and THINK_MAX ms. Thinking then takes longer when
    -- the room is busy, rather than slowing the room down.
    local tables, tableScripts = 0, 0
    for _, g in ipairs({ pool, snooker, bumper }) do
      if g then tables = tables + 1; tableScripts = tableScripts + per(meter.scripts[g] or 0) end
    end
    local others = busy - tableScripts + 0.7 * tables
    local spare = THINK_FILL * 1000 / 60 - others
    thinkMs = math.max(THINK_MIN, math.min(THINK_MAX, spare))
    for _, g in ipairs({ pool, snooker, bumper }) do
      if g then g.env.PLAN_BUDGET = thinkMs / 1000 end
    end
    meterText = string.format(
      "COST METER -- ms per frame, averaged over the last second\n" ..
      "  %.0f frames a second: %.0f for the games, %.0f clock steps%s; longest frame %.0f ms\n" ..
      "  physics  games %.2f, clock %.2f%s\n" ..
      "  scripts  %s, room %.2f\n" ..
      "  garbage  %.2f      drawing %.2f      thinking up to %.1f\n" ..
      "%s%s" ..
      "  busy     %.1f ms of each %.1f ms frame (%.0f%%)%s\n\n",
      fps, meter.gameFrames / el, meter.clockFrames / el,
      clock and "" or " (no clock)", meter.longest,
      per(meter.physGames), per(meter.physClock), own,
      table.concat(parts, ", "), room,
      meter.gc / d, meter.draw / d, thinkMs,
      drawnLine(), timingLine(),
      busy, period, 100 * load,
      (load > 0.9 and fps < 0.95 * 1000 / budget) and "; the room can't keep up" or "")
  end
  if METER_PRINT > 0 and (not lastPrint or t - lastPrint >= METER_PRINT * 1000) then
    lastPrint = t
    print((meterText:gsub("\n\n$", "")))
  end
  meter.t0, meter.frames, meter.gameFrames, meter.clockFrames, meter.draws = t, 0, 0, 0, 0
  meter.longest = 0
  meter.physGames, meter.physClock, meter.room, meter.gc, meter.draw = 0, 0, 0, 0, 0
  meter.physOwn, meter.physOwnAll = {}, 0
  meter.scripts = {}
end

local function call(k, all)
  local err
  for _, g in ipairs(games) do
    local f = g.callbacks[k]
    if f and (all or not g.paused) then
      local t = now()
      local ok, e = pcall(f, g.N)
      meter.scripts[g] = (meter.scripts[g] or 0) + (now() - t)
      if not ok and not err then err = g.name .. ": " .. tostring(e) end
    end
  end
  return err
end
local tPre, tStep, scriptsHere = 0, 0, 0
local function scriptsTotal() local s = 0; for _, x in pairs(meter.scripts) do s = s + x end; return s end
-- The pace of a game with its own physics (the clock, and MORE_GAMES):
-- it's owed the frames it gets on its own (the clock 25, most others 25 too)
-- for each real second since it started (a stopwatch, never the time of
-- day). Returns how many it's owed now; after a hold-up of over MAX_OWED
-- seconds (bpp paused, say) it lets the rest go, and says so.
-- Each starts at a different point in its step (the clock at none): started
-- together, they all came due in the same frames -- three steps' physics
-- in 25 frames a second and none in the rest -- and those heavy frames
-- missed the screen. Spread out, a frame takes one or two.
local ownStarted = 0
local function owed(g)
  local fps = 1000 / g.physics.animationPeriod
  local t = v:getTime()
  if not g.start then
    local phase = (ownStarted * 0.618034) % 1     -- (spread evenly, however many there are)
    ownStarted = ownStarted + 1
    g.start, g.N0, g.lost, g.report = t - phase / fps, g.N, 0, { frames = 0 }
  end
  local report = g.report
  local n = (t - g.start) * fps - (g.N - g.N0)
  if n > MAX_OWED * fps then
    g.lost = g.lost + (n - MAX_OWED * fps) / fps
    g.start = t - ((g.N - g.N0) + MAX_OWED * fps) / fps
    n = MAX_OWED * fps
  end
  report.frames = report.frames + 1
  if not report.t then report.t = t end
  if t - report.t >= 10 then
    if g.lost > 0.05 then
      local el = t - report.t
      if CAN_STEP then
        print(string.format("REC ROOM: %s lost %.1f s in the last %.0f s: the room was held up for more than %.0f s.",
                            g.name, g.lost, el, MAX_OWED))
      else
        print(string.format("REC ROOM: %s lost %.1f s in the last %.0f s. The room ran at %.0f frames a second; " ..
                            "it needs %.0f of them, at most every other one, so it keeps time only when the room " ..
                            "manages %.0f or more (and isn't held up).",
                            g.name, g.lost, el, report.frames / el, fps, 2 * fps))
      end
    end
    g.lost, report.t, report.frames = 0, t, 0
  end
  return n
end

-- one of a game's callbacks, timed for the meter
local function callOne(g, k)
  local f = g.callbacks[k]
  if not f then return end
  local t = now()
  local ok, e = pcall(f, g.N)
  meter.scripts[g] = (meter.scripts[g] or 0) + (now() - t)
  if not ok then return g.name .. ": " .. tostring(e) end
end

v:preSim(function(N)
  tPre = now()
  local s0 = scriptsTotal()
  if clock and not CAN_STEP then
    -- (an older bpp: the clock takes turns with the games, a frame at a
    -- time, never two in a row)
    clockTurn = owed(clock) >= 1 and not lastWasClock
    lastWasClock = clockTurn
    if clockTurn then whose(clock) end
  end
  for _, g in ipairs(games) do if not g.paused then g.N = g.N + 1 end end
  local err = call("preSim")
  tStep = now()
  meter.room = meter.room + (tStep - tPre) - (scriptsTotal() - s0)
  if err then error(err, 0) end
end)
v:postSim(function(N)
  local t = now()
  if clockTurn then meter.physClock = meter.physClock + (t - tStep); meter.clockFrames = meter.clockFrames + 1
  else meter.physGames = meter.physGames + (t - tStep); meter.gameFrames = meter.gameFrames + 1 end
  local pc0 = meter.physClock + meter.physOwnAll
  meter.frames = meter.frames + 1
  local s0 = scriptsTotal()
  local err = call("postSim")
  if clockTurn then whose(nil); clockTurn = false end
  -- the steps of the clock and the others with their own physics, inside
  -- the same frame: the games wait while each takes the steps it's owed
  -- (usually none or one; a few after a hold-up), with its own settings
  -- and its own callbacks around them
  if CAN_STEP then
    local turned = false
    for _, g in ipairs(games) do
      if g == clock or g.ownPhysics then
        local k = math.min(math.floor(owed(g)), MAX_CATCHUP)
        if k > 0 then
          whose(g)
          turned = true
          local P = g.physics
          for _ = 1, k do
            g.N = g.N + 1
            err = callOne(g, "preSim") or err
            local tc = now()
            realV:stepSimulation(P.timeStep, P.maxSubSteps, P.fixedTimeStep)
            local dt = now() - tc
            if g == clock then meter.physClock = meter.physClock + dt
            else meter.physOwn[g] = (meter.physOwn[g] or 0) + dt; meter.physOwnAll = meter.physOwnAll + dt end
            err = callOne(g, "postSim") or err
          end
          if g == clock then meter.clockFrames = meter.clockFrames + k end
          if g.extra and g.N % 15 < k then checkExtra(g) end
        end
      end
    end
    if turned then whose(nil) end
  else
    for _, g in ipairs(extras) do if N % 15 == 0 then checkExtra(g) end end
  end
  roomTick(N)
  -- the view follows a game that walks about (moved, not turned, so the
  -- mouse still turns it round)
  if active and active.follow and active.lastMiddle and N % 2 == 0 then
    local m = active.middle()
    if m then
      local o = active.lastMiddle
      local dx, dy, dz = m.x - o.x, m.y - o.y, m.z - o.z
      if dx * dx + dy * dy + dz * dz > 0.01 then
        local c = realV.cam
        local p, l = c.pos, c.look
        c.pos = btVector3(p.x + dx, p.y + dy, p.z + dz)
        c.look = btVector3(l.x + dx, l.y + dy, l.z + dz)
        active.lastMiddle = m
      end
    end
  end
  meter.room = meter.room + (now() - t) - (scriptsTotal() - s0) - (meter.physClock + meter.physOwnAll - pc0)
  if err then error(err, 0) end
end)

-- Garbage: bpp keeps Lua's collector stopped, and each game used to
-- collect everything every couple of seconds -- here that would be the
-- whole room's garbage at once, a pause long enough to be felt. Instead
-- the room collects a little at a time, running the collector for up to
-- GC_BUDGET seconds a frame, then stopping it again.
--   GC_STEADY = true (the default): it collects every frame, so garbage
--     never piles up -- a steady millisecond or two a frame.
--   GC_STEADY = false: it waits until the heap has grown by half (and at
--     least GC_MIN_KB) since the last collection finished. Cheaper on
--     average, but the end of each collection can't be split up, and with
--     that much to finish it can pause the room for a few tenths of a
--     second (an overnight run saw one about every 9 seconds).
if GC_STEADY == nil then GC_STEADY = true end
GC_BUDGET = GC_BUDGET or 0.002
GC_MIN_KB = GC_MIN_KB or 2048
local gcBase, gcBusy = nil, false
local tDraw, drawScripts = 0, 0
v:preDraw(function(N)
  local tg = now()
  if not gcBase then gcBase = collectgarbage("count") end
  -- (a bpp that collects garbage itself, BPP_GC_AUTO, needs none of this:
  -- the collector then runs a little at a time as the scripts make garbage,
  -- and its work shows in their times rather than under "garbage")
  if BPP_GC_AUTO then
    -- nothing to do
  elseif GC_STEADY or gcBusy or collectgarbage("count") > gcBase * 1.5 + GC_MIN_KB then
    gcBusy = true
    local done
    repeat
      done = collectgarbage("step", 0)
    until done or now() - tg >= GC_BUDGET * 1000
    if done then gcBusy, gcBase = false, collectgarbage("count") end
  end
  collectgarbage("stop")
  local t1 = now()
  meter.gc = meter.gc + (t1 - tg)
  local s0 = scriptsTotal()
  local err = call("preDraw", true)
  drawScripts = scriptsTotal() - s0
  tDraw = now()
  if err then error(err, 0) end
end)
-- (the scene is drawn between preDraw and postDraw)
-- A frame that takes longer than FREEZE_LOG_MS is noted in the console with
-- the time of day, so it can be matched with the system's own log (the time
-- of day is only printed, never used for timing). 0: never.
FREEZE_LOG_MS = FREEZE_LOG_MS or 250
-- bpp builds with frame timing (v:setFrameTiming) also say which part of
-- bpp's own frame -- outside the room's code -- took the time.
if FREEZE_LOG_MS > 0 and v.setFrameTiming then v:setFrameTiming(FREEZE_LOG_MS) end
-- (the meter's running totals as the last frame was shown, so a long frame
-- can be broken down)
local snap = { scripts = {} }
local function takeSnap()
  snap.physGames, snap.physClock, snap.room, snap.gc, snap.draw =
    meter.physGames, meter.physClock + meter.physOwnAll, meter.room, meter.gc, meter.draw
  for k in pairs(snap.scripts) do snap.scripts[k] = nil end
  for g, x in pairs(meter.scripts) do snap.scripts[g] = x end
end
v:postDraw(function(N)
  local t = now()
  meter.draw = meter.draw + (t - tDraw)
  meter.draws = meter.draws + 1
  -- the longest time between two frames shown: a stall (a computer
  -- player thinking, a collection, anything else holding bpp up) shows here
  local tw = wall()
  if meter.lastDraw then
    local gap = tw - meter.lastDraw
    meter.longest = math.max(meter.longest, gap)
    meter.firstDraw = meter.firstDraw or tw
    -- (not in the first 10 s: loading holds the first frames up)
    if FREEZE_LOG_MS > 0 and gap > FREEZE_LOG_MS and tw - meter.firstDraw > 10000 then
      -- where that frame's time went: what each part of the room spent since
      -- the last frame was shown, and what's left over (outside the room's
      -- code: bpp's window, the graphics driver, the system)
      local parts, inside = {}, 0
      local function part(name, x)
        x = math.max(0, x)
        inside = inside + x
        if x >= 1 then parts[#parts + 1] = string.format("%s %.0f", name, x) end
      end
      part("physics", (meter.physGames - snap.physGames) + (meter.physClock + meter.physOwnAll - snap.physClock))
      for _, g in ipairs(games) do part(shortName(g), (meter.scripts[g] or 0) - (snap.scripts[g] or 0)) end
      part("room", meter.room - snap.room)
      part("garbage", meter.gc - snap.gc)
      part("drawing", meter.draw - snap.draw)
      print(string.format("REC ROOM: a %.0f ms freeze, ending at %s -- %s%soutside the room's code %.0f ms",
                          gap, os.date("%H:%M:%S"), table.concat(parts, ", "), #parts > 0 and ", " or "",
                          math.max(0, gap - inside)))
    end
  end
  meter.lastDraw = tw
  meterTick(wall())
  takeSnap()
  -- (the games' own end-of-frame code: counted with the next frame)
  local err = call("postDraw", true)
  if err then error(err, 0) end
end)

-- a slider moved: the game it belongs to hears of it, by its own name
-- (the games whose sliders are renamed first: a game whose aren't would
-- match every name)
v:onParamChanged(function(N, name, value)
  for pass = 1, 2 do
    for _, g in ipairs(games) do
      local f, p = g.callbacks.onParamChanged, g.prefix or ""
      if f and (p ~= "") == (pass == 1) and name:sub(1, #p) == p then
        local ok, e = pcall(f, g.N, name:sub(#p + 1), value)
        if not ok then print("REC ROOM: " .. g.name .. ": " .. tostring(e)) end
        -- (one of MORE_GAMES may have built itself again, as the walker does
        -- for its terrain: that's where it starts from now)
        if g.extra then g.started(true) end
        return
      end
    end
  end
end)

TF = { pinball = pinball, pool = pool, snooker = snooker, bumper = bumper, clock = clock, goTo = goTo, games = games,
       extras = extras, at = function() return active end }
-- with the clock stepped inside the games' frames, the room runs at the
-- games' 60 frames a second; an older bpp needs 83 a second (12 ms a
-- frame), 25 for the clock and the rest for the games
whose(nil)
if clock and v.animationPeriod then v.animationPeriod = CAN_STEP and 16 or 12 end
-- one step for each picture (a bpp with v.onePerFrame): the 16 ms timer is
-- a little faster than a 60 Hz screen, and without this, a few times a
-- second two steps fall between two pictures and that picture jumps
if v.onePerFrame ~= nil then v.onePerFrame = true end
goTo(pinball)
