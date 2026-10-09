--
-- Bille Drop: the monostable tetrahedron
--
-- Bille (Almadi, Dawson & Domokos, 2025) is a tetrahedron that can rest on
-- only one of its four faces. Its frame is mostly hollow (carbon-fibre tubes
-- along the six edges) with a dense tungsten-carbide part placed so that the
-- centre of mass sits in a tiny "loading zone": put it down on any face and
-- it tips over, face to face, until it lands on face D.
--
-- THE SHAPE IS A RECONSTRUCTION. The paper (arXiv:2506.19244) gives the
-- vertex coordinates only in a figure image. This shape was fitted to the
-- numbers that are published in text: longest edge 500 mm, volume
-- 668.624 cm^3, and the four loading-zone volumes of Table 1 -- all five
-- matched exactly, and the obtuse path A-B-C-D the theory requires came out
-- of the fit by itself. The tungsten-carbide wedge along edge BC was then
-- designed (tubes 1/0.5 mm at 1.36 g/cm^3, WC at 14.15 g/cm^3, total 120 g)
-- to put the centre of mass 0.8 mm inside the face-D loading zone -- which
-- is itself only 1.5 mm deep at its deepest. See bille-meshes/bille-data.lua.
--
-- Faces are named by the opposite vertex. Predicted (quasi-static) falling
-- pattern: B -> A -> D <- C. Each gomboc-style colour is one Bille; it is
-- drawn dark until it is resting on face D. The console prints, for every
-- run, the faces it passed through, e.g. "C -> D".
--
-- Physics as in Gomboc Drop C: contact through the convex hull of the four
-- vertices with a 0.5 mm margin (= the real tube radius, so the hull is the
-- frame's own outline), exact mass and inertia, rolling resistance and spin
-- friction as constant moments at the table before every physics step, no
-- air drag, no taps. Once a Bille has been at rest for `redrop` seconds it
-- is lifted away and a new one of its colour dropped (0 = off).
-- The drawing thickens the tubes to 3 mm radius so they can be seen.
--
-- Units: centimetres, kilograms, seconds.
--
-- Tested: a single Bille, re-dropped 346 times at random orientations,
-- always ended on face D (13 times after first landing on A, B or C).
-- Set down gently on A it goes A -> D, on C it goes C -> D, on B it goes
-- B -> A -> D or, carried by its momentum, straight B -> D. With several on
-- the table, one can land on another's frame and be propped on the wrong
-- face (about 2% of drops with 6); the console flags these.
--
-- Keys
--   R   drop them all again, at random orientations
--   U   set them all down gently on face A, B or C (at random) and watch
--   K   kick: toss them all up with a spin
--   Z   slow motion (50x slower, the default) <-> 10x slower
--   ]   one more (and drop)      [   one fewer
--
-- Slow motion: in real time Bille is very quick -- nearly all its mass sits
-- in the wedge, 2 mm above face D, so a tip from one face to the next takes
-- about a twentieth of a second and a whole drop is over in under half a
-- second. It therefore starts at 1/50 speed ("speed" slider, 0.001-0.1).
-- Console times are simulated seconds; "redrop" counts on-screen seconds.
--
-- Headless testing: bpp -f demo/bille/bille-drop.lua -n FRAMES, with
-- BD_SEED, BD_COUNT, BD_SPEED, BD_STEPS, BD_ROLL, BD_SPIN, BD_DRAG, BD_REST,
-- BD_REDROP, BD_START=setdown and BD_LOG=file.csv.
--

local common = require "common"

-- ---------------------------------------------------------------------
-- data
-- ---------------------------------------------------------------------

local MESH_DIR = "bille-meshes/"
local function loadData()
  local tried = {}
  for _, dir in ipairs({ MESH_DIR, "demo/bille/" .. MESH_DIR, "demo/WyomingWill/Bille/" .. MESH_DIR }) do
    local ok, data = pcall(dofile, dir .. "bille-data.lua")
    if ok and data then MESH_DIR = dir; return data end
    tried[#tried + 1] = dir
  end
  error("bille-data.lua not found in " .. table.concat(tried, ", "))
end
local B = loadData()

local G = 981
local MASS = B.mass
local INERTIA = btVector3(B.inertia[1], B.inertia[2], B.inertia[3])
local K2 = { B.inertia[1] / MASS, B.inertia[2] / MASS, B.inertia[3] / MASS }
local MARGIN = B.tubeRadius
local FACES = { "A", "B", "C", "D" }
local HOME = "D"
local MAXH = 0
for _, f in ipairs(FACES) do MAXH = math.max(MAXH, B.height[f]) end
-- the largest distance from the centre of mass to a vertex
local REACH = 0
for _, f in ipairs(FACES) do
  local p = B.vertices[f]
  REACH = math.max(REACH, math.sqrt(p[1] ^ 2 + p[2] ^ 2 + p[3] ^ 2))
end

local HULL_SHAPE = btConvexHullShape()
for k, f in ipairs(FACES) do
  local p = B.vertices[f]
  HULL_SHAPE:addPoint(btVector3(p[1], p[2], p[3]), k == #FACES)
end
HULL_SHAPE:setMargin(MARGIN)

-- ---------------------------------------------------------------------
-- world, sliders, timing
-- ---------------------------------------------------------------------

common.gravity(-G)

local MAX_COUNT = 6
local function envnum(name, default) return tonumber(os.getenv(name) or "") or default end
local function param(name, value, lo, hi, step, info) v:addParam(name, value, lo, hi, step, info) end
param("count", envnum("BD_COUNT", 3), 1, MAX_COUNT, 1, "how many Billes to drop")
param("speed", envnum("BD_SPEED", 0.02), 0.001, .1, 0.001,
      "simulated seconds per real second (0.02 = 50x slow motion; Z toggles 0.02 / 0.1)")
param("steps", envnum("BD_STEPS", 1200), 300, 4800, 300, "physics steps per simulated second")
param("friction", 0.5, 0.05, 1.0, 0.05, "friction coefficient, 1 = grippiest (Bullet multiplies it by the table's 0.8)")
param("restitution", envnum("BD_REST", 0.1), 0.0, 0.8, 0.05, "bounciness")
param("rolling", envnum("BD_ROLL", 50), 0, 300, 5,
      "rolling resistance lever arm, microns (constant moment at the table)")
param("spin friction", envnum("BD_SPIN", 0.7), 0, 5, 0.1, "deceleration of spin about the vertical, rad/s^2")
param("air drag", envnum("BD_DRAG", 0), 0, 1.5, 0.05, "Bullet velocity damping; real air drag is ~0")
param("redrop", envnum("BD_REDROP", 5), 0, 30, 1,
      "real (on-screen) seconds at rest before a Bille is lifted away and a new one of its colour dropped (0 = off)")

local STEP, NSTEPS, FRAME_DT = 1 / 1200, 20, 1 / 60
local function applyTiming()
  local speed = v:getParam("speed")
  NSTEPS = math.max(1, math.floor(v:getParam("steps") * speed / 60 + 0.5))
  FRAME_DT = speed / 60
  STEP = FRAME_DT / NSTEPS
  v.animationPeriod = 16
  common.setTiming(STEP, 0, STEP)
end
applyTiming()

-- ---------------------------------------------------------------------
-- the table: version B's tray, sized for 50 cm tetrahedra
-- ---------------------------------------------------------------------

local SPACING = 62
local GRID_COLS, GRID_ROWS = 3, 2
local FLAT_W = GRID_COLS * SPACING + 40
local FLAT_D = GRID_ROWS * SPACING + 40
local RAMP_W, RAMP_DEG = 20, 8
local TABLE_W = FLAT_W + 2 * RAMP_W
local TABLE_D = FLAT_D + 2 * RAMP_W
local RAMP_TOP = RAMP_W * math.tan(math.rad(RAMP_DEG))

local WOOD, RIM_WOOD = "#7a4a24", "#4e2e15"
local function slab(sx, sy, sz, x, y, z, col, rot)
  local c = Cube(sx, sy, sz, 0)
  c.trans = btTransform(rot or btQuaternion(0, 0, 0, 1), btVector3(x, y, z))
  c.col = col
  c.friction = 0.8
  c.restitution = 0.2
  v:add(c)
  return c
end
slab(FLAT_W, 4, FLAT_D, 0, -2, 0, WOOD)
local T = 4
local a = math.rad(RAMP_DEG)
local function ramp(nx, nz, len)
  local half = (nx ~= 0) and FLAT_W / 2 or FLAT_D / 2
  local cx = half + RAMP_W / 2
  local cy = RAMP_W / 2 * math.tan(a)
  local tilt = btQuaternion(btVector3(-nz, 0, nx), a)
  local w = RAMP_W / math.cos(a)
  local ox, oy = -math.sin(a) * T / 2, -math.cos(a) * T / 2
  if nx ~= 0 then
    slab(w, T, len, nx * (cx - ox), cy + oy, 0, WOOD, tilt)
  else
    slab(len, T, w, 0, cy + oy, nz * (cx - ox), WOOD, tilt)
  end
end
ramp(1, 0, TABLE_D); ramp(-1, 0, TABLE_D); ramp(0, 1, TABLE_W); ramp(0, -1, TABLE_W)
local RIM_H, RIM_T = 5, 3
local rimY, rimH = (RAMP_TOP + RIM_H - 4) / 2, RAMP_TOP + RIM_H + 4
slab(TABLE_W + 2 * RIM_T, rimH, RIM_T, 0, rimY, TABLE_D / 2 + RIM_T / 2, RIM_WOOD)
slab(TABLE_W + 2 * RIM_T, rimH, RIM_T, 0, rimY, -TABLE_D / 2 - RIM_T / 2, RIM_WOOD)
slab(RIM_T, rimH, TABLE_D, TABLE_W / 2 + RIM_T / 2, rimY, 0, RIM_WOOD)
slab(RIM_T, rimH, TABLE_D, -TABLE_W / 2 - RIM_T / 2, rimY, 0, RIM_WOOD)
local floor = Plane(0, 1, 0, -80, 600)
floor.col = "#3b3f45"
v:add(floor)

local TAN_A = math.tan(a)
local function tableHeight(x, z)
  local ex = math.max(0, math.abs(x) - FLAT_W / 2)
  local ez = math.max(0, math.abs(z) - FLAT_D / 2)
  return math.min(RAMP_W, math.max(ex, ez)) * TAN_A
end

common.setCamera(btVector3(0, 125, 150), btVector3(0, 0, 0))

-- ---------------------------------------------------------------------
-- the Billes
-- ---------------------------------------------------------------------

local COLOURS = { "#e6194b", "#3cb44b", "#ffe119", "#4363d8", "#f58231", "#911eb4" }
local NAMES = { "Red", "Green", "Yellow", "Blue", "Orange", "Purple" }
local function hex(c) return tonumber(c:sub(2, 3), 16), tonumber(c:sub(4, 5), 16), tonumber(c:sub(6, 7), 16) end
local DARK, BRIGHT = {}, {}
for i, c in ipairs(COLOURS) do
  local r, g, b = hex(c)
  DARK[i] = string.format("#%02x%02x%02x", math.floor(r * 0.3), math.floor(g * 0.3), math.floor(b * 0.3))
  BRIGHT[i] = c
end

local billes = {}

local function newBille(i)
  local m = Mesh(MESH_DIR .. "bille.obj", 0, false)
  local ms = btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, -60, 0)))
  local body = btRigidBody(MASS, ms, HULL_SHAPE, INERTIA)
  m.body = body
  m.col = DARK[i]
  body:setActivationState(4)
  body:setContactProcessingThreshold(envnum("BD_CPT", 0.001))
  v:add(m)
  return { obj = m, body = body, i = i, lit = false }
end

local function applyMaterials()
  local f, r, d = v:getParam("friction"), v:getParam("restitution"), v:getParam("air drag")
  for _, g in ipairs(billes) do
    g.body:setFriction(f); g.body:setRestitution(r); g.body:setDamping(d, d)
  end
end

local function randomQuat()
  local u1, u2, u3 = math.random(), 2 * math.pi * math.random(), 2 * math.pi * math.random()
  local a, b = math.sqrt(1 - u1), math.sqrt(u1)
  return btQuaternion(a * math.sin(u2), a * math.cos(u2), b * math.sin(u3), b * math.cos(u3))
end

-- rotation taking face f's outward normal to world down, then a yaw
local function faceDownQuat(f, yaw)
  local n = B.normals[f]
  local nx, ny, nz = n[1], n[2], n[3]
  -- axis = n x (0,-1,0) = (nz, 0, -nx); angle = acos(-ny)
  local ax, az = nz, -nx
  local s = math.sqrt(ax * ax + az * az)
  local q1
  if s < 1e-9 then
    q1 = (ny < 0) and btQuaternion(0, 0, 0, 1) or btQuaternion(btVector3(1, 0, 0), math.pi)
  else
    q1 = btQuaternion(btVector3(ax / s, 0, az / s), math.acos(math.max(-1, math.min(1, -ny))))
  end
  return btQuaternion(btVector3(0, 1, 0), yaw) * q1
end

local function place(g, q, x, y, z, vel, spin)
  local b = g.body
  b:setCenterOfMassTransform(btTransform(q, btVector3(x, y, z)))
  b:setLinearVelocity(vel or btVector3(0, 0, 0))
  b:setAngularVelocity(spin or btVector3(0, 0, 0))
  b:clearForces()
  b:activate(true)
end

local function spots(n)
  local cols = math.min(GRID_COLS, math.ceil(math.sqrt(n * GRID_COLS / GRID_ROWS)))
  local rows = math.ceil(n / cols)
  local out = {}
  for k = 0, n - 1 do
    local c, r = k % cols, math.floor(k / cols)
    local inRow = math.min(cols, n - r * cols)
    out[#out + 1] = { (c - (inRow - 1) / 2) * SPACING + (math.random() - 0.5) * 4,
                      (r - (rows - 1) / 2) * SPACING + (math.random() - 0.5) * 4 }
  end
  return out
end

-- world direction of a body-frame vector
local function toWorld(g, v3)
  local Bm = g.body:getCenterOfMassTransform():getBasis()
  local x, y, z = 0, 0, 0
  for c = 0, 2 do
    local e = Bm:getColumn(c)
    x, y, z = x + e.x * v3[c + 1], y + e.y * v3[c + 1], z + e.z * v3[c + 1]
  end
  return x, y, z
end

-- which face it is lying on (normal within ON_DEG of straight down and
-- centre of mass at that face's resting height), or nil
local ON_DEG = 2.0
local function faceDown(g)
  local px, py, pz = getPosXYZ(g.obj)
  local h = py - tableHeight(px, pz) - MARGIN
  local best, bestAng = nil, 180
  for _, f in ipairs(FACES) do
    local _, wy, _ = toWorld(g, B.normals[f])
    local ang = math.deg(math.acos(math.max(-1, math.min(1, -wy))))
    if ang < bestAng then best, bestAng = f, ang end
  end
  if bestAng < ON_DEG and math.abs(h - B.height[best]) < 0.3 then return best, bestAng end
  return nil, bestAng
end

-- ---------------------------------------------------------------------
-- rolling resistance and spin friction before every physics step
-- (as in Gomboc Drop C: constant moments at the contact, on the table only)
-- ---------------------------------------------------------------------
local ROLL_DELTA, SPIN_DECEL = 0.005, 0.7

local function resist(dt)
  if ROLL_DELTA <= 0 and SPIN_DECEL <= 0 then return end
  for _, g in ipairs(billes) do
    local px, py, pz = getPosXYZ(g.obj)
    local r = py - tableHeight(px, pz) - MARGIN
    if r < REACH + 0.05 and r > 0 then
      local wx, wy, wz = getAngVelXYZ(g.obj)
      local vx, vy, vz = getVelXYZ(g.obj)
      local w = math.sqrt(wx * wx + wz * wz)
      if w > 0 and ROLL_DELTA > 0 then
        local Bm = g.body:getCenterOfMassTransform():getBasis()
        local ax, az = wx / w, wz / w
        local k2 = 0
        for c = 0, 2 do
          local e = Bm:getColumn(c)
          local d = ax * e.x + az * e.z
          k2 = k2 + K2[c + 1] * d * d
        end
        local alpha = ROLL_DELTA * G / (k2 + r * r)
        local dw = math.min(w, alpha * dt)
        local dwx, dwz = -dw * ax, -dw * az
        wx, wz = wx + dwx, wz + dwz
        vx, vz = vx - dwz * r, vz + dwx * r
      end
      if SPIN_DECEL > 0 then
        local dws = math.min(math.abs(wy), SPIN_DECEL * dt)
        wy = wy - (wy > 0 and dws or -dws)
      end
      setAngVelXYZ(g.obj, wx, wy, wz)
      setVelXYZ(g.obj, vx, vy, vz)
    end
  end
end

-- ---------------------------------------------------------------------
-- runs, rest detection, the console
-- ---------------------------------------------------------------------

local REST_TURN = math.rad(0.2)
local REST_MOVE = 0.03
local REST_HOLD = 0.4          -- simulated s (Bille settles within a fraction of a second)
local NEXT = { A = "D", B = "A", C = "D" }        -- predicted (quasi-static) falling pattern

local race = { t = 0, real = 0, nextReport = 1, nextTally = 60, done = {} }   -- t: simulated s, real: on-screen s

local function label(g) return g.run > 1 and string.format("%s #%d", NAMES[g.i], g.run) or NAMES[g.i] end

local function predicted(f)
  local p = { f }
  while NEXT[p[#p]] do p[#p + 1] = NEXT[p[#p]] end
  return table.concat(p, " -> ")
end

local function resetBille(g, startFace)
  g.t0 = race.t
  g.anchorT, g.restedAt, g.restSeenAt = nil, nil, nil
  g.path = startFace and { startFace } or {}
  g.homeAt = nil
  g.lit = nil
end

local function resetRace(what)
  race.t, race.real, race.nextReport, race.nextTally, race.done = 0, 0, 1, 60, {}
  print(string.format("\n--- %s: %d Bille%s ---", what, #billes, #billes == 1 and "" or "s"))
end

local function setCount(n)
  n = math.max(1, math.min(MAX_COUNT, math.floor(n)))
  while #billes > n do v:remove(table.remove(billes).obj) end
  while #billes < n do billes[#billes + 1] = newBille(#billes + 1) end
  applyMaterials()
end

local function randomSpin()
  return btVector3((math.random() - 0.5) * 4, (math.random() - 0.5) * 4, (math.random() - 0.5) * 4)
end

local function dropOne(g, x, z, k)
  place(g, randomQuat(), x, REACH + 6 + 5 * (k or 1) + math.random() * 8, z, nil, randomSpin())
end

local function drop()
  setCount(v:getParam("count"))
  resetRace("Drop")
  local s = spots(#billes)
  for k, g in ipairs(billes) do
    g.spot, g.run = s[k], 1
    dropOne(g, s[k][1], s[k][2], k)
    resetBille(g)
  end
end

local function setdown()
  setCount(v:getParam("count"))
  resetRace("Set down on A, B or C")
  local s = spots(#billes)
  for k, g in ipairs(billes) do
    local f = ({ "A", "B", "C" })[math.random(3)]
    g.spot, g.run = s[k], 1
    place(g, faceDownQuat(f, math.random() * 2 * math.pi), s[k][1], B.height[f] + MARGIN + 0.02, s[k][2])
    resetBille(g, f)
    print(string.format("  %-9s set down on face %s; predicted: %s", label(g), f, predicted(f)))
  end
end

local function kick()
  for _, g in ipairs(billes) do
    g.body:setLinearVelocity(btVector3((math.random() - 0.5) * 40, 150 + math.random() * 80, (math.random() - 0.5) * 40))
    g.body:setAngularVelocity(btVector3((math.random() - 0.5) * 12, (math.random() - 0.5) * 6, (math.random() - 0.5) * 12))
    g.body:activate(true)
  end
  resetRace("Kick")
  for _, g in ipairs(billes) do g.run = 1; resetBille(g) end
end

local function clearOf(g, x, z)
  for _, o in ipairs(billes) do
    if o ~= g then
      local ox, _, oz = getPosXYZ(o.obj)
      if math.sqrt((x - ox) ^ 2 + (z - oz) ^ 2) < 2 * REACH + 4 then return false end
    end
  end
  return true
end

-- another Bille close enough that their frames may touch (one can then be
-- propped on another's frame and rest on the wrong face, as real ones can)
local function nearOther(g)
  local px, _, pz = getPosXYZ(g.obj)
  for _, o in ipairs(billes) do
    if o ~= g then
      local ox, _, oz = getPosXYZ(o.obj)
      if math.sqrt((px - ox) ^ 2 + (pz - oz) ^ 2) < 2 * REACH then return NAMES[o.i] end
    end
  end
  return nil
end

local function redrop(g)
  local x, z = g.spot[1], g.spot[2]
  for try = 1, 60 do
    if clearOf(g, x, z) then break end
    x = (math.random() - 0.5) * (FLAT_W - 2 * REACH)
    z = (math.random() - 0.5) * (FLAT_D - 2 * REACH)
  end
  g.run = g.run + 1
  dropOne(g, x, z, 1)
  resetBille(g)
  print(string.format("  %-9s lifted away after %g s at rest; dropping %s", NAMES[g.i], v:getParam("redrop"), label(g)))
end

local function tally()
  local n = #race.done
  if n == 0 then return end
  local onD, times, paths = 0, {}, {}
  for _, d in ipairs(race.done) do
    if d.face == HOME then onD = onD + 1 end
    times[#times + 1] = d.rest
    paths[d.path] = (paths[d.path] or 0) + 1
  end
  table.sort(times)
  local ps = {}
  for p, c in pairs(paths) do ps[#ps + 1] = string.format("%s x%d", p, c) end
  table.sort(ps)
  print(string.format("=== %.0f s: %d finished run%s, %d on face D; time to rest: median %.1f s, slowest %.1f s; paths: %s ===",
                      race.t, n, n == 1 and "" or "s", onD, times[math.floor((n + 1) / 2)], times[n],
                      table.concat(ps, ", ")))
end

v:addShortcut("R", function(N) drop() end)
v:addShortcut("U", function(N) setdown() end)
v:addShortcut("K", function(N) kick() end)
-- Z: slow motion (0.02) <-> faster (0.1)
v:addShortcut("Z", function(N)
  local sp = v:getParam("speed") < 0.05 and 0.1 or 0.02
  v:addParam("speed", sp, 0.001, .1, 0.001,
             "simulated seconds per real second (0.02 = 50x slow motion; Z toggles 0.02 / 0.1)")
  applyTiming()
  print(string.format("speed %.2f (%dx slower than real time)", sp, math.floor(1 / sp + 0.5)))
end)
v:addShortcut("]", function(N)
  v:addParam("count", math.min(MAX_COUNT, v:getParam("count") + 1), 1, MAX_COUNT, 1, "how many Billes to drop")
  drop()
end)
v:addShortcut("[", function(N)
  v:addParam("count", math.max(1, v:getParam("count") - 1), 1, MAX_COUNT, 1, "how many Billes to drop")
  drop()
end)

local function applyResistance()
  ROLL_DELTA = v:getParam("rolling") * 1e-4
  SPIN_DECEL = v:getParam("spin friction")
end
applyResistance()

v:onParamChanged(function(N, name, value)   -- bpp passes (frame, name, value)
  if name == "count" then
    if math.floor(tonumber(value)) ~= #billes then drop() end
  elseif name == "speed" or name == "steps" then
    applyTiming()
  elseif name == "rolling" or name == "spin friction" then
    applyResistance()
  else
    applyMaterials()
  end
end)

pcall(function()
  v:setHelpText("Bille Drop (monostable tetrahedron, reconstructed)\n" ..
    "  R  drop at random orientations\n" ..
    "  U  set down on face A, B or C\n" ..
    "  K  kick them up with a spin\n" ..
    "  Z  slow motion (50x) <-> 10x slower\n" ..
    "  ]  one more     [  one fewer\n" ..
    "Dark = not on face D, bright = resting on face D.\n" ..
    "Predicted falling pattern: B -> A -> D <- C")
end)

-- ---------------------------------------------------------------------
-- every frame
-- ---------------------------------------------------------------------

v:preSim(function(N)
  for k = 1, NSTEPS - 1 do
    resist(STEP)
    v:stepSimulation(STEP, 0, STEP)
  end
  resist(STEP)
end)

local LOGF = os.getenv("BD_LOG") and io.open(os.getenv("BD_LOG"), "w")
if LOGF then LOGF:write("t,idx,name,run,face,angle_to_nearest_face_deg,angvel_deg_s,x,y,z\n") end

v:postSim(function(N)
  race.t = race.t + FRAME_DT
  race.real = race.real + 1 / 60
  for _, g in ipairs(billes) do
    local f, ang = faceDown(g)
    if f and g.path[#g.path] ~= f then
      g.path[#g.path + 1] = f
      if f == HOME then g.homeAt = race.t end
    end
    local lit = (f == HOME)
    if lit ~= g.lit then g.lit = lit; g.obj.col = lit and BRIGHT[g.i] or DARK[g.i] end

    if LOGF and N % 15 == 0 then
      local wx, wy, wz = getAngVelXYZ(g.obj)
      local px, py, pz = getPosXYZ(g.obj)
      LOGF:write(string.format("%.2f,%d,%s,%d,%s,%.3f,%.4f,%.3f,%.3f,%.3f\n", race.t, g.i, NAMES[g.i], g.run,
        f or "-", ang, math.deg(math.sqrt(wx * wx + wy * wy + wz * wz)), px, py, pz))
    end

    -- at rest: no visible movement in a REST_HOLD-second window
    local q = g.body:getOrientation()
    local qx, qy, qz, qw = q:getX(), q:getY(), q:getZ(), q:getW()
    local px, py, pz = getPosXYZ(g.obj)
    local moved = true
    if g.anchorT then
      local dot = math.abs(qx * g.aq[1] + qy * g.aq[2] + qz * g.aq[3] + qw * g.aq[4])
      local turn = 2 * math.acos(math.min(1, dot))
      local dx, dy, dz = px - g.ap[1], py - g.ap[2], pz - g.ap[3]
      moved = turn > REST_TURN or math.sqrt(dx * dx + dy * dy + dz * dz) > REST_MOVE
    end
    if not moved and race.t - g.anchorT >= REST_HOLD then
      g.anchorT, g.aq, g.ap = race.t, { qx, qy, qz, qw }, { px, py, pz }
      if not g.restedAt then
        g.restedAt, g.restSeenAt = race.t - REST_HOLD, race.real
        local path = #g.path > 0 and table.concat(g.path, " -> ") or "?"
        local near = nearOther(g)
        print(string.format("  %-9s at rest on %s after %5.2f s; faces it lay on: %s%s%s", label(g),
                            f and ("face " .. f) or "no face (propped?)", g.restedAt - g.t0, path,
                            f == HOME and "" or "  ** NOT ON FACE D **",
                            (f ~= HOME and near) and ("  -- frames may be touching " .. near) or ""))
        g.result = { face = f, rest = g.restedAt - g.t0, path = path }
      end
    elseif moved then
      g.anchorT, g.aq, g.ap = race.t, { qx, qy, qz, qw }, { px, py, pz }
      g.restedAt, g.restSeenAt = nil, nil
    end
  end

  local wait = v:getParam("redrop")
  if wait > 0 then
    for _, g in ipairs(billes) do
      if g.restSeenAt and race.real - g.restSeenAt >= wait then
        race.done[#race.done + 1] = g.result
        redrop(g)
      end
    end
  end
  if race.real >= race.nextTally then          -- every on-screen minute
    race.nextTally = race.nextTally + 60
    tally()
  end
  if race.real >= race.nextReport then         -- every 2 on-screen seconds
    race.nextReport = race.nextReport + 2
    local st = {}
    for _, g in ipairs(billes) do
      local f = faceDown(g)
      st[#st + 1] = string.format("%s:%s%s", NAMES[g.i]:sub(1, 1), f or "-", g.restedAt and "." or "")
    end
    print(string.format("t=%5.1fs  on face (. = at rest): %s", race.t, table.concat(st, " ")))
  end
end)

math.randomseed(envnum("BD_SEED", os.time()))
if os.getenv("BD_START") == "setdown" then setCount(v:getParam("count")); setdown() else drop() end
