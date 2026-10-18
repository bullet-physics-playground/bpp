--
-- EULER'S GALLERY -- an 18th-century walnut hall for the Bullet
-- Physics Playground, L-shaped, holding WyomingWill's rigid-body
-- curiosities (each in its own folder in exhibits/): the gombocs, Bille and the weighted polyhedra, the
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
-- HOW IT WORKS: each exhibit is the unchanged script, in a Bullet world of
-- its own (bpp's v:newWorld), at its own coordinates, drawn in its bay
-- (v:placeWorld) -- so it runs exactly as it does on its own, number for
-- number. It's loaded into a sandbox of its own (its own set of globals)
-- that finds its files in its own folder, gets its own random numbers,
-- keeps its sliders apart (named "Exhibit: slider" in the Params pane), and
-- collects its per-frame callbacks, keys and help, which this file passes
-- on only while you're at it. Only the world of the exhibit you're at is
-- stepped; the others wait exactly as they are, costing nothing. NEEDS a
-- bpp with the separate-worlds patch (v:newWorld).
--
-- UNITS: centimetres; the floor is at y = 0.
--

local realV = v
-- (bpp has already drawn from Lua's random numbers before any script runs:
-- an exhibit on its own starts from there. How far in, counted from seed 1.)
local RANDOM_BASE = 0
do
  local first = math.random()
  math.randomseed(1)
  for k = 0, 1000 do if math.random() == first then RANDOM_BASE = k; break end end
end
local realCube, realSphere, realCylinder, realMesh = Cube, Sphere, Cylinder, Mesh
local realCone, realPlane = Cone, Plane
local unpack = unpack or table.unpack

local function findDir(cands, file)
  for _, d in ipairs(cands) do
    local f = io.open(d .. file, "r")
    if f then f:close(); return d end
  end
  error("Euler's Gallery: can't find " .. file)
end
local HERE = findDir({ "./", "demo/WyomingWill/EulersGallery/" }, "gallery.lua")
local MESH = HERE .. "gallery-meshes/"
local LABELS = dofile(MESH .. "labels.lua")

-- ---------------------------------------------------------------------
-- the exhibits, in the order you walk past them
-- ---------------------------------------------------------------------
--   dir, file  the script (dir from this folder: the exhibits are in
--              exhibits/). Not there: a covered bay.
--   name       what the header and Tab call it
--   label      its placard (a key of gallery-meshes/labels.lua)
--   prefix     its sliders in the Params pane are named prefix .. name
--   floorY     the height of its own ground plane, in its own units: that
--              is where the hall's floor goes
--   stand      { w, d }: a walnut stand under it, up to its own y = -4 (for
--              the trays, which float above their ground plane on their own)
--   about      what the placard says when the mouse rests on it
EXHIBITS = EXHIBITS or {
  -- WING A, "TURNING": things that roll, tumble and spin, where the body's
  -- shape and spin decide what it does. Facing pairs across the aisle.
  { dir = "exhibits/Gomboc/", file = "gomboc-variety.lua", name = "Gömböc Variety", label = "gomboc-variety",
    prefix = "Variety: ", floorY = -80, stand = { 172, 145 },
    about = "Gömböc Variety: Gomboc-C at three sizes and the lumpier Sloan beta shapes,\n" ..
            "all of uniform density. The white dot is each one's balancing point." },
  { dir = "exhibits/Bille/", file = "bille-drop.lua", name = "Bille and the polyhedra", label = "bille",
    prefix = "Bille: ", floorY = -80, stand = { 272, 210 },
    about = "Bille Drop: the weighted monostable tetrahedron (Bille), the 21-, 26- and 37-\n" ..
            "corner spiral polyhedra and a PLA-only one. Edges and corners light up on the table." },
  { dir = "exhibits/GalileoRamp/", file = "galileo-ramp.lua", name = "Galileo's ramp", label = "galileo-ramp",
    prefix = "Ramp: ", floorY = -75,
    about = "Galileo's ramp: a ball, a disc, a hoop and a can of soup race down a ramp.\n" ..
            "The soup wins; the hoop comes last." },
  { dir = "exhibits/DoubleCone/", file = "double-cone.lua", name = "the double cone", label = "double-cone",
    prefix = "Cone: ", floorY = -75,
    about = "The double cone: on rails that rise and spread apart it rolls 'uphill',\n" ..
            "though its centre of mass goes down." },
  { dir = "exhibits/Oloid/", file = "oloid.lua", name = "the oloid and the sphericon", label = "oloid",
    prefix = "Oloid: ", floorY = -75,
    about = "The oloid, the two-circle roller and the sphericon: not round, yet they\n" ..
            "roll, laying their whole surface on the board as they go." },
  { dir = "exhibits/EulersDisk/", file = "eulers-disk.lua", name = "Euler's disk", label = "eulers-disk",
    prefix = "Disk: ", floorY = -75,
    about = "Euler's disk: a steel disc rolls round on a mirror, leaning further over and\n" ..
            "going round faster and faster, until it stops, flat." },
  { dir = "exhibits/Rattleback/", file = "rattleback.lua", name = "the rattlebacks", label = "rattleback",
    prefix = "Rattleback: ", floorY = -75,
    about = "The rattleback: spun one way it spins; spun the other way it wobbles,\n" ..
            "stops and spins back." },
  { dir = "exhibits/SpinningEgg/", file = "spinning-egg.lua", name = "the spinning eggs", label = "spinning-egg",
    prefix = "Egg: ", floorY = -75,
    about = "The spinning egg: spun fast on its side, a hard-boiled egg rises onto its end\n" ..
            "(and, spun faster, jumps as it rises); a raw one won't." },
  { dir = "exhibits/TippeTop/", file = "tippe-top.lua", name = "the tippe tops", label = "tippe-top",
    prefix = "Tippe top: ", floorY = -75,
    about = "The tippe top: spin it on its ball and it turns itself over onto its stem,\n" ..
            "raising its centre of mass as it goes." },
  { dir = "exhibits/Dzhanibekov/", file = "dzhanibekov.lua", name = "the Dzhanibekov effect", label = "dzhanibekov",
    prefix = "Dzhanibekov: ", floorY = 0,
    about = "The Dzhanibekov effect: three T-handles spinning in zero gravity. Spun about\n" ..
            "the middle axis, the handle flips over and back, again and again." },
  { dir = "exhibits/Gyroscope/", file = "gyroscope.lua", name = "the gyroscopes", label = "gyroscope",
    prefix = "Gyroscope: ", floorY = -75,
    about = "The gyroscope: held by one end of its axle, on a pedestal or a string, it\n" ..
            "doesn't fall but goes round; on a tightrope it balances on its foot, and\n" ..
            "slides to and fro, upright, as the wire is tipped one way, then the other." },
  { dir = "exhibits/BicycleWheel/", file = "bicycle-wheel.lua", name = "the bicycle wheel", label = "bicycle-wheel",
    prefix = "Wheel: ", floorY = 0,
    about = "The bicycle wheel: on a swivel stool, turn a spinning wheel over and the\n" ..
            "stool starts to turn the other way; push the wheel out and it slows." },
  -- WING B, "SWINGING": pendulums, collisions and many bodies, ending with
  -- gravity at the largest scale.
  { dir = "exhibits/NewtonsCradle/", file = "newtons-cradle.lua", name = "Newton's cradle", label = "newtons-cradle",
    prefix = "Cradle: ", floorY = -75,
    about = "Newton's cradle: lift one ball and one flies out at the far end; two, and\n" ..
            "two. Steel on steel, by Hertz's law." },
  { dir = "exhibits/HuygensClocks/", file = "huygens-clocks.lua", name = "Huygens' clocks", label = "huygens-clocks",
    prefix = "Clocks: ", floorY = 0,
    about = "Huygens' clocks: two pendulum clocks on one beam, started out of step, end\n" ..
            "up swinging in exact opposition -- 'an odd kind of sympathy'." },
  { dir = "exhibits/Kapitza/", file = "kapitza.lua", name = "Kapitza's pendulum", label = "kapitza",
    prefix = "Kapitza: ", floorY = -75,
    about = "Kapitza's pendulum: an upside-down pendulum on a pivot shaken fast up and\n" ..
            "down stays up, rocking slowly about the upright." },
  { dir = "exhibits/DoublePendulum/", file = "double-pendulum.lua", name = "the double pendulum", label = "double-pendulum",
    prefix = "Double: ", floorY = -75,
    about = "The double pendulum: seven let go a billionth of a radian apart swing as one,\n" ..
            "then fly apart; its two pure swings; and upside down on shaken pivots." },
  { dir = "exhibits/PendulumsTwist/", file = "pendulums-twist.lua", name = "pendulums with a twist", label = "pendulums-twist",
    prefix = "Twist: ", floorY = -75,
    about = "Pendulums with a twist: when a double pendulum can flip over, and when it\n" ..
            "won't; the swinging Atwood machine's hidden constant, kept only at 3 to 1;\n" ..
            "the swinging spring." },
  { dir = "exhibits/ChainFountain/", file = "chain-fountain.lua", name = "the chain fountain", label = "chain-fountain",
    prefix = "Fountain: ", floorY = 0,
    about = "The chain fountain (the Mould effect): a bead chain pouring out of a jar\n" ..
            "rises in an arch above the rim on its way to the floor." },
  { dir = "exhibits/Slinky/", file = "falling-slinky.lua", name = "the falling Slinky", label = "slinky",
    prefix = "Slinky: ", floorY = 0,
    about = "The falling Slinky: let a hanging Slinky go, and its bottom hangs still\n" ..
            "in mid-air until the collapsing coils reach it, while a ball beside it falls.\n" ..
            "Beside it, the same Slinky walks down a flight of stairs." },
  { dir = "exhibits/BrazilNut/", file = "brazil-nut.lua", name = "the Brazil-nut effect", label = "brazil-nut",
    prefix = "Brazil: ", floorY = -75,
    about = "The Brazil-nut effect, in real glass: two boxes of glass beads shaken hard.\n" ..
            "With rough walls the beads go round and the big bead comes up; with smooth\n" ..
            "glass walls they go round the other way and it stays down." },
  { dir = "exhibits/SolarSystem/", file = "solar-system.lua", name = "the solar system", label = "solar-system",
    prefix = "Solar: ", floorY = -75,
    about = "The solar system: the Sun, the planets, Pluto, five asteroids and 21 moons,\n" ..
            "moved by gravity (and Einstein) from where JPL had them on 2026-01-01,\n" ..
            "each turning as it does: the Moon keeps one face to us." },
}
-- empty bays at the far end, for ideas still to come (none now:
-- twenty-one exhibits: wing A's twelve bays, "Turning", hold the first
-- twelve; wing B's nine, "Swinging", the rest)
SPARE_BAYS = SPARE_BAYS or 0
-- (opened from elsewhere, as from the repository's top folder: the
-- exhibits' folders are found from this one)
if HERE ~= "./" then
  for _, e in ipairs(EXHIBITS) do
    if not e.dir:match("^/") then e.dir = HERE .. e.dir end
  end
end

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
-- physics: each exhibit has a Bullet world of its own (v:newWorld, which
-- needs a bpp from October 2026 or later), made exactly as bpp makes the
-- scene's own, holding only what the exhibit builds, at its own
-- coordinates. So it runs exactly as it does on its own, number for
-- number. It's drawn in its bay (v:placeWorld). The hall is in the scene's
-- own world (0), which nothing moves in. Only the world of the exhibit
-- you're at is stepped; the others wait exactly as they are.
-- ---------------------------------------------------------------------
if not realV.newWorld then
  error("Euler's Gallery needs a bpp with separate worlds (v:newWorld): rebuild bpp with the worlds patch")
end
local BPP_TIMING = { timeStep = 1 / 25, fixedTimeStep = 1 / 100, maxSubSteps = 7, animationPeriod = 16 }
local IDLE = { timeStep = 1 / 60, fixedTimeStep = 1 / 60, maxSubSteps = 1, animationPeriod = 16 }
-- (the step sizes are bpp's, not a world's: each exhibit's, while you're at it)
local function applyTiming(p)
  realV.timeStep, realV.fixedTimeStep, realV.maxSubSteps = p.timeStep, p.fixedTimeStep, p.maxSubSteps
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

local CALLBACKS = { preSim = true, postSim = true, preDraw = true, postDraw = true, onKey = true,
                    onParamChanged = true, onCommand = true, onJoystick = true, onSpaceNavigator = true,
                    onHover = true, cycleObject = true,
                    onEnter = true, onLeave = true }      -- (the hall's own: you come into its bay, and leave it)
local TIMING = { timeStep = true, fixedTimeStep = true, maxSubSteps = true, animationPeriod = true }

-- Runs fn with the exhibit's world in use (and its random numbers), then
-- puts back the world that was (see setRandom, below)
local setRandom
local LIGHTS, applyLight         -- (an exhibit's lights: see bayLight, below)
local function inWorld(g, fn, ...)
  local was = realV:currentWorld()
  realV:useWorld(g.world)
  local r = { pcall(fn, ...) }
  realV:useWorld(was)
  return unpack(r)
end

-- makeExhibit(e, bay): a sandbox for one exhibit. Everything it builds is
-- left as it is (its own world keeps it apart); what it has of its own is
-- its globals, its folder, its sliders, its keys and callbacks, and its
-- camera, which is moved to its bay.
local function makeExhibit(e, bay)
  local g = { e = e, name = e.name, dir = e.dir, callbacks = {}, shortcuts = {}, help = "", down = {},
              timing = {}, N = 0, draws = 0, prefix = e.prefix or (e.name .. ": "), vset = {}, view = {} }
  for k, val in pairs(BPP_TIMING) do g.timing[k] = val end
  g.world = realV:newWorld()
  -- its bay: where its world is drawn, turned to face the aisle (its +z,
  -- the side it's seen from on its own, toward the aisle)
  local ox, oy, oz, a = bay.x, bay.y, bay.z, bay.a
  local cs, sn = math.cos(a), math.sin(a)
  realV:placeWorld(g.world, btTransform(btQuaternion(btVector3(0, 1, 0), a), btVector3(ox, oy, oz)))
  local function toScene(p) return btVector3(p.x * cs + p.z * sn + ox, p.y + oy, -p.x * sn + p.z * cs + oz) end
  local function toLocal(q)
    local x, z = q.x - ox, q.z - oz
    return btVector3(x * cs - z * sn, q.y - oy, x * sn + z * cs)
  end
  g.toScene, g.toLocal = toScene, toLocal
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

  -- the camera: what it sets as it loads is kept as its view; while you're
  -- at it, it moves the camera, from its bay
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
        elseif active == g then realV.cam[k] = toScene(val) end
        return
      end
      if active == g or loading == g then realV.cam[k] = val end
    end,
  })

  -- the viewer, as the exhibit sees it
  local vpFns = {}
  local special = {
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
    -- (the worlds are the gallery's to arrange)
    newWorld = function() error("an exhibit can't make worlds of its own in the gallery") end,
    useWorld = function() end,
    placeWorld = function() end,
  }
  local vp = setmetatable({}, {
    __index = function(_, k)
      if k == "cam" then return cam end
      if TIMING[k] then return g.timing[k] end
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
      if TIMING[k] then g.timing[k] = val; return end
      if k == "gravity" then realV.gravity = val; return end      -- (its world's)
      g.vset[k] = val        -- (lights, shadows and the like: the hall's own stay)
      -- (its lights, while you're at it, at once: see LIGHTS)
      if LIGHTS[k] and active == g then applyLight(g, k) end
    end,
  })

  local env = setmetatable({}, { __index = _G })
  env._G = env
  env.v = vp
  env.Mesh = function(path, ...) return realMesh(fix(path), ...) end
  -- (a file of its own, found from the hall: for what bpp opens itself, as
  -- an object's tex)
  env.galleryPath = fix
  env.cabinetPath = fix        -- (its old name, kept)
  -- its ground plane: in its own world, as on its own, but not drawn (the
  -- hall's floor is drawn there, at the same height: it's drawn a hundredth
  -- of a centimetre across)
  env.Plane = function(nx, ny, nz, c)
    return realPlane(nx, ny, nz, c, 0.01)      -- (drawn a hundredth of a cm across)
  end
  -- its random numbers: the same sequence it gets on its own (see setRandom)
  env.math = setmetatable({
    random = function(...) g.draws = g.draws + 1; return math.random(...) end,
    randomseed = function(sd) g.seed, g.draws = sd, 0; return math.randomseed(sd) end,
  }, { __index = math })
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
  return g
end

-- Random numbers: Lua has one sequence for everyone. An exhibit on its own
-- starts it from where bpp leaves it and draws from it alone; here the
-- sequence is put back to where that exhibit had got to whenever it's the
-- one drawing (as it loads, and while you're at it).
setRandom = function(g)
  math.randomseed(g.seed or 1)
  for _ = 1, (g.seed and 0 or RANDOM_BASE) + g.draws do math.random() end
end

-- ---------------------------------------------------------------------
-- the hall
-- ---------------------------------------------------------------------
local UP = btQuaternion(btVector3(1, 0, 0), math.pi / 2)
local function yq(a) return btQuaternion(btVector3(0, 1, 0), a) end
local HOVER = {}           -- objectKey -> text, for the hall's own things
local function hallAdd(o)
  realV:add(o)
  return o
end
-- Shadows: bpp's shadows come from one light above, as from the Sun, so
-- in a closed hall its architecture (ceiling, walls, pilasters, frames,
-- the wings' boards, the chandeliers) would shade everything under it. Only
-- what stands on the floor casts: the exhibits (in their own worlds), their
-- stands and plinths, the placards and the armillary sphere -- built with
-- CASTING set. (An older bpp has no castShadow: everything casts, as before.)
local CASTING = false
local function noCast(o)
  if not CASTING then pcall(function() o.castShadow = false end) end
  return o
end
local function vis(o, col, tr)
  noCast(o)
  o.col = col
  pcall(function() o.collides = false end)
  if tr then pcall(function() o.transparency = tr end) end
  return hallAdd(o)
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
  noCast(c)
  hallAdd(c)
  if hover and objectKey then HOVER[objectKey(c)] = hover end
  return c
end
local function cyl(x, y, z, r, h, col, q)
  local c = realCylinder(r, h, 0)
  c.trans = btTransform(q or UP, btVector3(x, y, z))
  return vis(c, col)
end
-- What's overhead (the ceiling, its coffers, the walls and their cornices)
-- throws no shadow: bpp's light 0 shines from far above, so they would
-- shadow the whole hall. Everything in the hall is still lit, and the
-- chandeliers, exhibits and furniture still throw shadows. (An older bpp
-- without obj.castShadow: as before.)
local function overhead(o)
  pcall(function() o.castShadow = false end)
  return o
end
local function mesh(file, x, y, z, col, q)
  local m = realMesh(file, 0, false)
  m.trans = btTransform(q or ident, btVector3(x, y, z))
  return vis(m, col)
end

local WALNUT, DARK, PANEL, GILT, GOLD = "#4a2c14", "#2a1a0c", "#5a3418", "#b8932e", "#d4af37"
local FELT, CREAM = "#1f4d3a", "#b9ae94"
local HALL_LIGHT0 = btVector4(HW + LB / 2, 1600, -WW / 2 + 400, 0.4)
local HALL_LIGHT1 = btVector4(-200, 100, 200, 0.2)            -- (bpp's own)
realV.glLight0 = HALL_LIGHT0
-- At an exhibit, its lights come from where they would on its own (bpp's
-- defaults, or what it set), turned with its bay: so it is lit in the hall
-- as on its own, whichever way its bay faces.
local function bayLight(g, L)
  -- (a lamp, w = 1, is a place in the exhibit: it goes where the bay is;
  -- bpp's far lights, w below 1, are a direction, only turned)
  if L:getW() == 1 then
    local a = g.toScene(btVector3(L.x, L.y, L.z))
    return btVector4(a.x, a.y, a.z, 1)
  end
  local a, b = g.toScene(btVector3(L.x, L.y, L.z)), g.toScene(btVector3(0, 0, 0))
  return btVector4(a.x - b.x, a.y - b.y, a.z - b.z, L:getW())
end
-- The rest of an exhibit's lighting -- its ambient light, its lights'
-- colours and its highlights (glSpecular) -- is its own too while you're
-- at it (set as it runs, at once), and the hall's (bpp's) again when you
-- leave.
local HALL_LIGHTS = { glAmbient = realV.glAmbient, glModelAmbient = realV.glModelAmbient, glSpecular = realV.glSpecular,
                      glLight0Color = realV.glLight0Color, glLight1Color = realV.glLight1Color }
LIGHTS = { glLight0 = true, glLight1 = true, glAmbient = true, glModelAmbient = true, glSpecular = true,
           glLight0Color = true, glLight1Color = true }
applyLight = function(g, k)
  local val = g and g.vset[k]
  if k == "glLight0" then realV.glLight0 = g and bayLight(g, val or btVector4(500, 500, 500, 0.4)) or HALL_LIGHT0
  elseif k == "glLight1" then realV.glLight1 = g and bayLight(g, val or HALL_LIGHT1) or HALL_LIGHT1
  else
    if val == nil then val = HALL_LIGHTS[k] end
    realV[k] = val
  end
end

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
  overhead(box(cx, H / 2, cz, L, H, 4, WALNUT, q))
  box(cx, 95, cz, L, 6, 7, DARK, q)                                      -- dado rail
  overhead(box(cx, H - 14, cz, L, 6, 7, DARK, q))                        -- cornice
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
overhead(box(-HW / 2 - 50, H / 2, ZS, HW - 100, H, 4, WALNUT))
overhead(box(HW / 2 + 50, H / 2, ZS, HW - 100, H, 4, WALNUT))
overhead(box(0, (H + 260) / 2, ZS, 200, H - 260, 4, WALNUT))
box(-104, 130, ZS - 3, 10, 270, 8, GILT); box(104, 130, ZS - 3, 10, 270, 8, GILT); box(0, 265, ZS - 3, 218, 12, 8, GILT)
box(0, 130, ZS + 6, 200, 260, 2, "#1a0f06")

-- the ceiling, coffered
overhead(box(0, H, ZS / 2, WW, 4, ZS, "#3a2210"))
overhead(box((XE - HW) / 2, H, ZN / 2, XE + HW, 4, -ZN, "#3a2210"))
for z = 0, ZS, 140 do overhead(box(0, H - 7, z, WW, 12, 9, DARK)) end
for x = -HW, XE, 140 do overhead(box(x, H - 7, ZN / 2, 9, 12, -ZN, DARK)) end

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
  CASTING = true
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
  hallAdd(s)
  if objectKey then HOVER[objectKey(s)] = "An armillary sphere: the heavens in brass rings,\nwith the Earth in the middle." end
  CASTING = false
end

-- the wings' titles, each on a board hung over the aisle where its wing
-- begins: wing A's facing the entrance, wing B's facing the corner
local function wingTitle(key, subKey, x, z, a, hover)
  local q = yq(a)
  local function at(dx, dy, dz)
    local rx, rz = rot(a, dx, dz)
    return x + rx, dy, z + rz
  end
  local bx, by, bz = at(0, 300, -1.5)
  local w = math.max(LABELS[key].w, LABELS[subKey].w) + 40
  local board = box(bx, by, bz, w, 46, 3, DARK, q)
  local ex, ey, ez = at(0, 300, -3.2)
  box(ex, ey, ez, w + 8, 54, 1, GILT, q)
  for _, side in ipairs({ -1, 1 }) do
    local cx, cy, cz = at(side * (w / 2 - 15), 300 + 27 + (H - 300 - 27) / 2, -1.5)
    cyl(cx, cy, cz, 0.8, H - 300 - 27, GILT)
  end
  local tx, ty, tz = at(0, 300 + 2, 0)
  mesh(MESH .. LABELS[key].file, tx, ty, tz, GOLD, q)
  local sx, sy, sz = at(0, 300 - 18, 0)
  mesh(MESH .. LABELS[subKey].file, sx, sy, sz, GOLD, q)
  if objectKey then HOVER[objectKey(board)] = hover end
end
if LABELS["wing-a"] and LABELS["wing-b"] then
  wingTitle("wing-a", "wing-a-sub", 0, ZS - 250, 0,
            "Wing A, Turning: things that roll, tumble and spin, where the body's\n" ..
            "shape and spin decide what it does. Exhibits facing each other make pairs.")
  wingTitle("wing-b", "wing-b-sub", HW + 80, ZN / 2, -math.pi / 2,
            "Wing B, Swinging: pendulums, collisions and many bodies, ending with\n" ..
            "gravity at the largest scale: the solar system.")
end

-- a bay: its rug, pilasters either side on the wall behind, and the
-- placard at the aisle edge (its board leant back only a little: leant back
-- 35 degrees, from up in the aisle it caught the light and showed white)
local PLACARD_TILT = 12
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
  CASTING = true
  box(px, 45, pz, 6, 90, 6, DARK, q)
  local tiltQ = q * btQuaternion(btVector3(1, 0, 0), -math.rad(PLACARD_TILT))
  local bw = L.w + 12
  local board = solid(px, 95, pz, bw, 14, 2.5, DARK, tiltQ, hoverText)
  box(px, 95, pz, bw + 2, 16, 2, GILT, tiltQ)
  -- (the lettering stands on the board's face)
  local ux, uz = rot(a, 0, 1)
  local nY, nH = math.cos(math.rad(PLACARD_TILT)), math.sin(math.rad(PLACARD_TILT))     -- the face's normal: up and out
  local lx, ly, lz = px + ux * 1.3 * nY, 95 + 1.3 * nH, pz + uz * 1.3 * nY
  -- (its letters are L.h tall from y = 0: centred on the board)
  local dy = -L.h / 2
  local cx, cy, cz = lx + ux * (-dy * nH), ly + dy * nY, lz + uz * (-dy * nH)
  mesh(MESH .. L.file, cx, cy, cz, GOLD, tiltQ)
  CASTING = false
  return px, pz
end

-- a covered bay: a plinth with a dust sheet over what's coming
local function coveredBay(b, e)
  bayFrame(b, e.label, e.about)
  local q = yq(b.a)
  CASTING = true
  box(b.x, 40, b.z, 110, 80, 110, WALNUT, q)
  box(b.x, 81, b.z, 118, 3, 118, GILT, q)
  solid(b.x, 125, b.z, 92, 86, 92, CREAM, q, e.about)       -- the dust sheet, hanging in folds
  box(b.x, 98, b.z, 104, 34, 104, "#a99e84", q)
  box(b.x, 167, b.z, 80, 4, 80, "#c4b99e", q)
  local L = LABELS["in-preparation"]
  local dx, dz = rot(b.a, 0, 46.2)
  mesh(MESH .. L.file, b.x + dx, 150, b.z + dz, "#6a5a3a", q)
  CASTING = false
end
local function emptyBay(b)
  local text = "An empty bay, waiting for the next curiosity."
  bayFrame(b, "reserved", text)
  local q = yq(b.a)
  CASTING = true
  solid(b.x, 40, b.z, 110, 80, 110, WALNUT, q, text)
  box(b.x, 81, b.z, 118, 3, 118, GILT, q)
  CASTING = false
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
    -- (in a world of its own, at its own coordinates, drawn in its bay)
    local g = makeExhibit(e, { x = b.x, y = -(e.floorY or 0), z = b.z, a = b.a })
    g.bay = b
    bayFrame(b, e.label, e.about)
    if e.stand then
      CASTING = true
      local top, q = off.y - 4, yq(b.a)
      box(b.x, top / 2, b.z, e.stand[1] - 10, top, e.stand[2] - 10, WALNUT, q)
      box(b.x, top - 3, b.z, e.stand[1] - 4, 6, e.stand[2] - 4, DARK, q)
      box(b.x, 5, b.z, e.stand[1], 10, e.stand[2], DARK, q)
      box(b.x, top - 8, b.z, e.stand[1] - 6, 2, e.stand[2] - 6, GILT, q)
      CASTING = false
    end
    loading = g
    setRandom(g)
    local ok, err = inWorld(g, g.load)
    loading = nil
    if ok then
      exhibits[#exhibits + 1] = g
      print(string.format("GALLERY: %s is in its bay (%s%s)", g.name, e.dir, e.file))
      -- its first frame, now: everything put where it begins, so it shows
      -- from anywhere in the hall, not only once you're at it (and it then
      -- stands still until you arrive, as each exhibit does when it starts)
      inWorld(g, function()
        g.N = g.N + 1
        local f = g.callbacks.preSim
        if f then local ok2, err2 = pcall(f, g.N); if not ok2 then print("GALLERY: " .. g.name .. " preSim: " .. tostring(err2)) end end
        local tm = g.timing
        realV:stepSimulation(tm.timeStep, tm.maxSubSteps, tm.fixedTimeStep)
        f = g.callbacks.postSim
        if f then local ok2, err2 = pcall(f, g.N); if not ok2 then print("GALLERY: " .. g.name .. " postSim: " .. tostring(err2)) end end
      end)
    else
      print("GALLERY: " .. g.name .. " didn't load: " .. tostring(err))
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
local STOP_PARAM, stopShown = "Gallery: stop", nil

local function nextStop(s, d)
  local i = indexOf(s) or 1
  return stops[(i - 1 + d) % #stops + 1]
end
local function header(g)
  return function()
    return "EULER'S GALLERY -- at " .. g.name ..
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
  return "EULER'S GALLERY -- " .. s.name ..
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
  -- let go of any keys still held at the exhibit we're leaving (its world
  -- then waits, untouched, until you come back)
  if active then
    local f = active.callbacks.onKey
    for key in pairs(active.down) do if f then pcall(f, active.N, key, false) end end
    active.down = {}
    -- (and tell it you're leaving, if it asked: v:onLeave)
    f = active.callbacks.onLeave
    if f then local ok, err = pcall(f, active.N); if not ok then print("GALLERY: " .. active.name .. " onLeave: " .. tostring(err)) end end
  end
  here = s
  -- (and where you are as a slider, "Gallery: stop": bpp's Restart runs the
  -- hall again from the start, then puts every slider back as it was --
  -- this one included, which brings you back here. Drag it to jump.)
  local i = indexOf(s)
  if i and stopShown ~= i then
    stopShown = i
    realV:addParam(STOP_PARAM, i, 1, #stops, 1,
                   "where you are: 1 the entrance, then on round (Tab, Shift+Tab); drag to go there")
  end
  local c = realV.cam
  c:setUpVector(btVector3(0, 1, 0), true)
  if s.isView then
    active = nil
    realV:useWorld(0)
    applyTiming(IDLE)
    -- (the Params pane: none of the exhibits' sliders)
    if realV.showParams then realV:showParams("Gallery: ") end
    -- (bpp's markers on joints: not in the hall views)
    realV.showConstraints = false
    for k in pairs(LIGHTS) do applyLight(nil, k) end          -- (the hall's lights)
    c.pos = s.pos
    c.look = s.look        -- (in that order: the look turns the view from where it now is)
    realV:setHelpText(hallHelp(s))
  else
    active = s
    realV:useWorld(s.world)
    setRandom(s)
    applyTiming(s.timing)
    -- (the Params pane: only this exhibit's sliders)
    if realV.showParams then realV:showParams(s.prefix) end
    -- (and bpp's markers on joints as the exhibit has them: on, unless it
    -- turns them off)
    realV.showConstraints = s.vset.showConstraints ~= false
    for k in pairs(LIGHTS) do applyLight(s, k) end            -- (its lights, as on its own)
    local view = s.view
    local pos = view.pos or btVector3(0, 150, 200)
    local look = view.look or btVector3(0, 0, 0)
    c.pos = s.toScene(pos)
    c.look = s.toScene(look)
    realV:setHelpText(s.header() .. s.help)
    -- (and tell it you've come, if it asked: v:onEnter)
    local f = s.callbacks.onEnter
    if f then local ok, err = pcall(f, s.N); if not ok then print("GALLERY: " .. s.name .. " onEnter: " .. tostring(err)) end end
  end
end

-- ---------------------------------------------------------------------
-- passing things on to the exhibit you're at
-- ---------------------------------------------------------------------
local function report(g, k, err)
  print("GALLERY: " .. g.name .. " " .. k .. ": " .. tostring(err))
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
    if active then applyTiming(active.timing) end
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
      if down then print("GALLERY: P (save every frame for POV-Ray) is held back here; use the POV-Ray menu.") end
      return true
    end
    return false
  end
  local sc = g.shortcuts[key]
  if sc then
    if down then
      local ok, err = pcall(sc, g.N)
      if not ok then print("GALLERY: " .. g.name .. " key " .. key .. ": " .. tostring(err)) end
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
  if name == STOP_PARAM then
    local i = math.max(1, math.min(#stops, math.floor(value + 0.5)))
    stopShown = i
    if stops[i] ~= here then goTo(stops[i]) end
    return
  end
  for _, g in ipairs(exhibits) do
    local p = g.prefix
    if name:sub(1, #p) == p then
      local f = g.callbacks.onParamChanged
      if f then
        -- (in its own world; the one you're at gets its random numbers back)
        local ok, err = inWorld(g, f, g.N, name:sub(#p + 1), value)
        if not ok then print("GALLERY: " .. g.name .. ": " .. tostring(err)) end
        if active and active ~= g then setRandom(active) end
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
local START = os.getenv("GALLERY_START") or os.getenv("CABINET_START")   -- (CABINET_START: its old name)
if START then
  for _, g in ipairs(exhibits) do if g.name:lower():find(START:lower(), 1, true) then here = g end end
  if START == "corner" then here = VIEW_B end
end
goTo(here)
print(string.format("GALLERY: %d exhibits on show, %d in preparation, %d empty bays; wings %.0f and %.0f m long",
                    #exhibits, #EXHIBITS - #exhibits, #BAYS - #EXHIBITS, (LA + WW) / 100, (LB + WW) / 100))
