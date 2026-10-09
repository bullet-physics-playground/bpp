--
-- Gomboc Variety: Gomboc-C, Sloan's beta shapes and the spiral polyhedra
--
-- The same table, physics and race as Gomboc Drop C (gomboc-drop-c.lua), but
-- every drop brings the next shape in a cycle:
--
--   Gomboc-C (9 cm)  ->  a beta shape  ->  Gomboc-C at 75%  ->  another beta
--   shape  ->  Gomboc-C at 125%  ->  another beta shape  ->  a spiral
--   polyhedron (21, 26 or 37 corners, in turn)  ->  and round again
--
-- Each colour keeps its colour and runs through that cycle: when it has been
-- at rest for `redrop` seconds it is lifted away and the NEXT shape is
-- dropped in its place. (The colours start at different places in the
-- cycle, so the table is mixed from the start.) Every one of these shapes
-- has one resting point and one balancing point -- but, as the console will
-- show, that alone does not make a good self-righter.
--
-- THE SHAPES (all in gomboc-meshes/):
--
--   Gomboc-C    the GOMBOC900 CAD model of Gomboc Drop C, uniform resin
--               (1.2 g/cm^3), at 9 cm and scaled to 75% and 125%. Rights
--               itself every time; a bigger one takes longer (time grows
--               with the square root of size).
--
--   Sloan beta  M. L. Sloan's analytic Gombocs ("An Analytical Gomboc", 2023,
--               via MathWorld): a lumpy ball whose radius in direction
--               (phi from the pole, theta round it) is
--                 form 1:  r^4 = 1 + 4 beta sin(phi) cos(theta - 5 phi)
--                 form 2:  r^4 = 1 + 4 beta sin(phi) cos(theta -
--                                     (3 pi/2)(cos phi - cos^3 phi / 3))
--               The radius has exactly one maximum and one minimum, so the
--               smooth body has one balancing and one resting point. Uniform
--               resin, 9 cm. Used here: form 1 at beta 0.06, 0.07, 0.08 and
--               form 2 at 0.04 -- the lumpiest that still work: above about
--               beta 0.04 the surface has dimples (not convex), a body rolls on
--               its convex hull, and from form 1 at 0.10 and form 2 at 0.05 on,
--               that hull has a second resting spot. (Strictly, a Gomboc must
--               be convex; these form-1 shapes are not quite.)
--               What to expect: they usually STOP ON THEIR SIDES. Their
--               resting valley and balancing peak differ in height by only
--               4-5 mm (Gomboc-C: 11 mm), and the slopes between are so
--               gentle that ordinary rolling resistance holds them almost
--               anywhere. In tests 3 of 15 came to rest upright at the
--               default rolling resistance, and they still wandered for a
--               minute with none at all. That is the real lesson of the
--               Gomboc: one resting point is easy to get in theory; a shape
--               that actually gets there needs the steep, sharp-edged design
--               of the real one. ("shapes" slider 1 leaves them out.)
--
--   21-vertex   after Domokos & Kovacs (2023): one apex above four horizontal
--               regular pentagons, with equal masses at its 21 corners -- the
--               fewest corners known for a polyhedron with one stable face
--               (the bottom pentagon) and one unstable vertex (the apex).
--               RECONSTRUCTED: the paper gives angles, not coordinates, so the
--               rings were re-fitted close to its spiral (see p21.lua). Drawn
--               as a closed polyhedron, 9 cm tall; the physics is the paper's
--               idealisation, all 109 g in the 21 corners and a weightless
--               skin (a real build is very hard -- see p21.lua). With its mass
--               in its corners and tall for its base, it topples and clatters
--               onto its pentagon: upright in 2-3.5 s, at rest in 4-5 s,
--               every time in tests.
--
--   26- and     the same construction with more corners: an apex above five
--   37-vertex   pentagons (26) or six hexagons (37). 21 is only the FEWEST
--               corners for which it can work; with more, the margins grow
--               (0.8 -> 2.8 -> 4.3 mm at 9 cm), enough to build them for
--               real. So these two are simulated as real objects: a 0.5 mm
--               polycarbonate shell with a 5.2 g tungsten weight centred 3 mm
--               inside each corner (142 g and 201 g), shape fitted for that
--               build. The 37 tolerates 0.5 mm build errors; the 26 barely
--               tolerates 0.2 mm (see p26.lua, p37.lua).
--
-- Physics as in Gomboc Drop C: convex-hull contact, exact mass and inertia,
-- rolling resistance and spin friction as constant moments at the table
-- before every physics step, 1200 steps per second, no air drag, no taps.
-- Rolling resistance (a lever arm in microns) is a property of the
-- materials, so it is the same for every shape and size.
--
-- Units are centimetres, kilograms and seconds.
--
-- Keys
--   R   drop them all again, at random orientations (each takes the next shape)
--   U   stand them all on their heads (the balancing point) and let go
--   K   kick: toss them all up with a spin
--   ]   one more (and drop)      [   one fewer
--
-- Sliders: count; shapes (0 = the cycle above, 1 = the cycle without the beta
-- shapes, 2 = Gomboc-C only, 3 = beta only, 4 = the polyhedra only); speed, steps,
-- friction, restitution, rolling (microns), spin friction, air drag, redrop.
-- The tally every minute (while re-dropping) lists each shape separately.
--
-- Hover the mouse over one (bpp with the hover patch) to see what it is.
--
-- Headless testing: bpp -f gomboc-variety.lua -n FRAMES, with GV_SEED,
-- GV_COUNT, GV_SHAPES, GV_STEPS, GV_ROLL, GV_SPIN, GV_DRAG, GV_REST,
-- GV_REDROP, GV_START=headstand.
--

local common = require "common"

-- ---------------------------------------------------------------------
-- the shapes
-- ---------------------------------------------------------------------

local MESH_DIR = "gomboc-meshes/"
do
  local found = false
  for _, dir in ipairs({ MESH_DIR, "demo/WyomingWill/Gomboc/" .. MESH_DIR, "demo/gomboc/" .. MESH_DIR }) do
    local f = io.open(dir .. "gomboc-hull.lua", "r")
    if f then f:close(); MESH_DIR = dir; found = true; break end
  end
  if not found then error("gomboc-meshes/ not found") end
end
local function load(name) return dofile(MESH_DIR .. name .. ".lua") end

local G = 981                             -- cm/s^2
local RESIN = 0.0012                      -- kg/cm^3

-- base shapes: hull points (flat x,y,z list), mass, squared radii of gyration
-- about the body axes, the resting normal ("down") and the balancing point
-- ("top") in body coordinates, and the collision margin
local BASE = {}
do
  local h = load("gomboc-hull")
  BASE.C = { title = "Gomboc-C", obj = "gomboc.obj", points = h.points, mass = h.volume * RESIN,
             K2 = h.inertia, down = { 0, -1, 0 }, top = { 0, h.topHeight, 0 },
             topHeight = h.topHeight, margin = 0.04 }
  for _, b in ipairs({ { "beta1-06", "Sloan beta 0.06 (form 1)" }, { "beta1-07", "Sloan beta 0.07 (form 1)" },
                       { "beta1-08", "Sloan beta 0.08 (form 1)" }, { "beta2-04", "Sloan beta 0.04 (form 2)" } }) do
    local d = load(b[1])
    BASE[b[1]] = { title = b[2], obj = b[1] .. ".obj", points = d.points, mass = d.volume * RESIN,
                   K2 = d.inertia, down = d.down, top = d.top, topHeight = d.topHeight, margin = 0.04 }
  end
  local p = load("p21")
  BASE.P21 = { title = "21-vertex polyhedron (ideal)", obj = "p21.obj", points = p.vertices, mass = p.mass,
               K2 = p.inertia, down = p.down, top = p.top, topHeight = p.topHeight,
               margin = p.margin or p.ballRadius }
  for _, nv in ipairs({ 26, 37 }) do
    local q = load("p" .. nv)
    BASE["P" .. nv] = { title = nv .. "-vertex shell polyhedron", obj = "p" .. nv .. ".obj", points = q.vertices,
                        mass = q.mass, K2 = q.inertia, down = q.down, top = q.top, topHeight = q.topHeight,
                        margin = q.margin }
  end
end

-- the cycle (shapes slider 0) and the single-kind cycles (1, 2, 3)
local C_SIZES = { 1.0, 0.75, 1.25 }
local BETAS = { "beta1-06", "beta2-04", "beta1-07", "beta1-08" }

-- a shape at a size: built once, then shared (Bullet allows sharing shapes)
local SPECS = {}
local KEEP = {}          -- one unused Mesh per file keeps bpp's mesh cache warm

local OBJ_LINES = {}
local function scaledObj(file, s)
  if s == 1 then return MESH_DIR .. file end
  if not OBJ_LINES[file] then
    local t = {}
    for line in io.lines(MESH_DIR .. file) do t[#t + 1] = line end
    OBJ_LINES[file] = t
  end
  local name = os.tmpname()
  local f = assert(io.open(name, "w"))
  for _, line in ipairs(OBJ_LINES[file]) do
    local x, y, z = line:match("^v%s+(%S+)%s+(%S+)%s+(%S+)")
    if x then f:write(string.format("v %.5f %.5f %.5f\n", tonumber(x) * s, tonumber(y) * s, tonumber(z) * s))
    else f:write(line, "\n") end
  end
  f:close()
  return name
end

local function spec(kind, s)
  s = s or 1
  local key = kind .. "@" .. s
  if SPECS[key] then return SPECS[key] end
  local b = BASE[kind]
  local hull = btConvexHullShape()
  local p = b.points
  for i = 1, #p, 3 do hull:addPoint(btVector3(p[i] * s, p[i + 1] * s, p[i + 2] * s), false) end
  hull:recalcLocalAabb()
  hull:setMargin(b.margin * s)
  local file = scaledObj(b.obj, s)
  KEEP[key] = Mesh(file, 0, false)
  if s ~= 1 then os.remove(file) end       -- (bpp has it cached now)
  local m = b.mass * s ^ 3
  local K2 = { b.K2[1] * s * s, b.K2[2] * s * s, b.K2[3] * s * s }
  local sp = {
    kind = kind, s = s, file = file, hull = hull, mass = m, K2 = K2,
    inertia = btVector3(K2[1] * m, K2[2] * m, K2[3] * m),
    down = b.down, top = { b.top[1] * s, b.top[2] * s, b.top[3] * s },
    topHeight = b.topHeight * s, margin = b.margin * s,
    title = (kind == "C" and s ~= 1) and string.format("%s at %d%%", b.title, math.floor(s * 100 + 0.5)) or b.title,
  }
  SPECS[key] = sp
  return sp
end

-- ---------------------------------------------------------------------
-- world
-- ---------------------------------------------------------------------

common.gravity(-G)

local MAX_COUNT = 12
local function param(name, value, lo, hi, step, info) v:addParam(name, value, lo, hi, step, info) end
local function envnum(name, default) return tonumber(os.getenv(name) or "") or default end
param("count", envnum("GV_COUNT", 6), 1, MAX_COUNT, 1, "how many to drop")
param("shapes", envnum("GV_SHAPES", 0), 0, 4, 1,
      "0 = Gomboc-C, beta, Gomboc-C resized, beta, ..., polyhedron; 1 = the same without the beta shapes; 2 = Gomboc-C only; 3 = beta only; 4 = polyhedra only (21, 26, 37 corners)")
param("speed", 1, 0.25, 4, 0.25, "simulated seconds per real second")
param("steps", envnum("GV_STEPS", 1200), 300, 4800, 300, "physics steps per simulated second")
param("friction", 0.5, 0.05, 1.0, 0.05, "friction coefficient, 1 = grippiest (Bullet multiplies it by the table's 0.8)")
param("restitution", envnum("GV_REST", 0.1), 0.0, 0.8, 0.05, "bounciness")
param("rolling", envnum("GV_ROLL", 150), 0, 300, 5, "rolling resistance lever arm, microns (constant moment, any tilt)")
param("spin friction", envnum("GV_SPIN", 0.7), 0, 5, 0.1, "deceleration of spin about the vertical, rad/s^2")
param("air drag", envnum("GV_DRAG", 0), 0, 1.5, 0.05, "Bullet velocity damping; real air drag is ~0")
param("redrop", envnum("GV_REDROP", 5), 0, 30, 1,
      "seconds at rest before one is lifted away and the next shape dropped in its colour (0 = off)")

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

-- the table: Gomboc Drop C's tray
local SPACING = 27
local GRID_COLS, GRID_ROWS = 4, 3
local FLAT_W = GRID_COLS * SPACING + 30
local FLAT_D = GRID_ROWS * SPACING + 30
local RAMP_W, RAMP_DEG = 14, 8
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
local RIM_H, RIM_T = 4, 3
local rimY, rimH = (RAMP_TOP + RIM_H - 4) / 2, RAMP_TOP + RIM_H + 4
slab(TABLE_W + 2 * RIM_T, rimH, RIM_T, 0, rimY, TABLE_D / 2 + RIM_T / 2, RIM_WOOD)
slab(TABLE_W + 2 * RIM_T, rimH, RIM_T, 0, rimY, -TABLE_D / 2 - RIM_T / 2, RIM_WOOD)
slab(RIM_T, rimH, TABLE_D, TABLE_W / 2 + RIM_T / 2, rimY, 0, RIM_WOOD)
slab(RIM_T, rimH, TABLE_D, -TABLE_W / 2 - RIM_T / 2, rimY, 0, RIM_WOOD)
local floor = Plane(0, 1, 0, -80, 400)
floor.col = "#3b3f45"
v:add(floor)

local TAN_A = math.tan(a)
local function tableHeight(x, z)
  local ex = math.max(0, math.abs(x) - FLAT_W / 2)
  local ez = math.max(0, math.abs(z) - FLAT_D / 2)
  return math.min(RAMP_W, math.max(ex, ez)) * TAN_A
end

common.setCamera(btVector3(0, 105, 140), btVector3(0, 0, 6))

-- ---------------------------------------------------------------------
-- the bodies
-- ---------------------------------------------------------------------

local COLOURS = { "#e6194b", "#3cb44b", "#ffe119", "#4363d8", "#f58231", "#911eb4",
                  "#42d4f4", "#f032e6", "#bfef45", "#fabed4", "#469990", "#dcbeff" }
local NAMES = { "Red", "Green", "Yellow", "Blue", "Orange", "Purple",
                "Cyan", "Magenta", "Lime", "Pink", "Teal", "Lavender" }
local function hex(c) return tonumber(c:sub(2, 3), 16), tonumber(c:sub(4, 5), 16), tonumber(c:sub(6, 7), 16) end
local SHADES = {}
for i, c in ipairs(COLOURS) do
  local r, g, b = hex(c)
  SHADES[i] = {}
  for k = 0, 10 do
    local f = 0.25 + 0.75 * k / 10
    SHADES[i][k] = string.format("#%02x%02x%02x", math.floor(r * f), math.floor(g * f), math.floor(b * f))
  end
end

-- the next shape: the cycle, or one kind only
-- each colour runs through the sequence for the "shapes" setting, starting
-- at a different place so the table is mixed from the first drop
local SEQ = {}
do
  local function C(sz) return { "C", sz } end
  local function Bt(k) return { BETAS[k] } end
  local POLY = { "P21", "P26", "P37" }
  local full, c, b, pp = {}, 0, 0, 0
  for n = 1, 12 * 7 do                        -- C, beta, C, beta, C, beta, polyhedron
    local k = (n - 1) % 7 + 1
    if k == 7 then pp = pp % #POLY + 1; full[#full + 1] = { POLY[pp] }
    elseif k % 2 == 1 then c = c % #C_SIZES + 1; full[#full + 1] = C(C_SIZES[c])
    else b = b % #BETAS + 1; full[#full + 1] = Bt(b) end
  end
  SEQ[0] = full
  SEQ[1] = { C(1.0), C(0.75), C(1.25), { "P21" }, C(1.0), C(0.75), C(1.25), { "P26" },
             C(1.0), C(0.75), C(1.25), { "P37" } }
  SEQ[2] = { C(1.0), C(0.75), C(1.25) }
  SEQ[3] = { Bt(1), Bt(2), Bt(3), Bt(4) }
  SEQ[4] = { { "P21" }, { "P26" }, { "P37" } }
end
local function nextSpec(g)
  local seq = SEQ[math.floor(v:getParam("shapes") + 0.5)] or SEQ[0]
  g.turn = (g.turn or (g.i - 1)) + 1
  local e = seq[(g.turn - 1) % #seq + 1]
  return spec(e[1], e[2])
end

local bodies = {}

local function applyMaterial(g)
  local d = v:getParam("air drag")
  g.body:setFriction(v:getParam("friction"))
  g.body:setRestitution(v:getParam("restitution"))
  g.body:setDamping(d, d)
end
local function applyMaterials() for _, g in ipairs(bodies) do applyMaterial(g) end end

-- give body g a new shape: a new Mesh and rigid body in its place
local function reshape(g, sp)
  if g.obj then v:remove(g.obj) end
  local m = Mesh(sp.file, 0, false)
  local ms = btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, -50, 0)))
  local body = btRigidBody(sp.mass, ms, sp.hull, sp.inertia)
  m.body = body
  m.col = SHADES[g.i][0]
  body:setActivationState(4)
  body:setContactProcessingThreshold(envnum("GV_CPT", 0.001))
  v:add(m)
  g.obj, g.body, g.sp, g.shade = m, body, sp, -1
  applyMaterial(g)
end

local function randomQuat()
  local u1, u2, u3 = math.random(), 2 * math.pi * math.random(), 2 * math.pi * math.random()
  local a, b = math.sqrt(1 - u1), math.sqrt(u1)
  return btQuaternion(a * math.sin(u2), a * math.cos(u2), b * math.sin(u3), b * math.cos(u3))
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
    out[#out + 1] = { (c - (inRow - 1) / 2) * SPACING + (math.random() - 0.5) * 3,
                      (r - (rows - 1) / 2) * SPACING + (math.random() - 0.5) * 3 }
  end
  return out
end

-- a body-frame vector in world coordinates
local function toWorld(g, p)
  local B = g.body:getCenterOfMassTransform():getBasis()
  local x, y, z = 0, 0, 0
  for c = 0, 2 do
    local e = B:getColumn(c)
    x, y, z = x + e.x * p[c + 1], y + e.y * p[c + 1], z + e.z * p[c + 1]
  end
  return x, y, z
end

-- how far (degrees) it is from resting the right way up
local function tiltDeg(g)
  local d = g.sp.down
  local _, y, _ = toWorld(g, d)
  local n = math.sqrt(d[1] ^ 2 + d[2] ^ 2 + d[3] ^ 2)
  return math.deg(math.acos(math.max(-1, math.min(1, -y / n))))
end

-- ---------------------------------------------------------------------
-- rolling resistance and spin friction before every physics step
-- (as in Gomboc Drop C)
-- ---------------------------------------------------------------------
local ROLL_DELTA, SPIN_DECEL = 0.015, 0.7

local function resist(dt)
  if ROLL_DELTA <= 0 and SPIN_DECEL <= 0 then return end
  for _, g in ipairs(bodies) do
    local px, py, pz = getPosXYZ(g.obj)
    local r = py - tableHeight(px, pz) - g.sp.margin
    if r < g.sp.topHeight + 0.05 and r > 0 then
      local wx, wy, wz = getAngVelXYZ(g.obj)
      local vx, vy, vz = getVelXYZ(g.obj)
      local w = math.sqrt(wx * wx + wz * wz)
      if w > 0 and ROLL_DELTA > 0 then
        local B = g.body:getCenterOfMassTransform():getBasis()
        local ax, az = wx / w, wz / w
        local k2 = 0
        for c = 0, 2 do
          local e = B:getColumn(c)
          local d = ax * e.x + az * e.z
          k2 = k2 + g.sp.K2[c + 1] * d * d
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
-- the race: upright, then at rest
-- ---------------------------------------------------------------------

local UPRIGHT_DEG, HOLD = 15, 2.0
local REST_TURN = math.rad(0.2)
local REST_MOVE = 0.02
local REST_HOLD = 2.0
local RACE_LIMIT = 300

local race = { t = 0, running = false, nextReport = 1, nextTally = 60, done = {} }

local function label(g)
  return (g.run > 1 and string.format("%s #%d", NAMES[g.i], g.run) or NAMES[g.i]) .. " (" .. g.sp.title .. ")"
end

local function resetBody(g)
  g.t0 = race.t
  g.restSince, g.rightedAt, g.anchorT, g.restedAt, g.restSeenAt, g.touching = nil, nil, nil, nil, nil, nil
  g.shade = -1
end

local function resetRace(what)
  race.t, race.running, race.nextReport, race.nextTally, race.done = 0, true, 1, 60, {}
  print(string.format("\n--- %s: %d bod%s ---", what, #bodies, #bodies == 1 and "y" or "ies"))
  for _, g in ipairs(bodies) do
    resetBody(g); g.run = 1
    print(string.format("  %-7s %s, %.0f g", NAMES[g.i], g.sp.title, g.sp.mass * 1000))
  end
end

local function setCount(n)
  n = math.max(1, math.min(MAX_COUNT, math.floor(n)))
  while #bodies > n do v:remove(table.remove(bodies).obj) end
  while #bodies < n do bodies[#bodies + 1] = { i = #bodies + 1 } end
end

local function randomSpin()
  return btVector3((math.random() - 0.5) * 6, (math.random() - 0.5) * 6, (math.random() - 0.5) * 6)
end

local function drop()
  setCount(v:getParam("count"))
  local s = spots(#bodies)
  for k, g in ipairs(bodies) do
    reshape(g, nextSpec(g))
    g.spot = s[k]
    place(g, randomQuat(), s[k][1], g.sp.topHeight + 7.5 + 4 * k + math.random() * 6, s[k][2], nil, randomSpin())
  end
  resetRace("Drop")
end

local function clearOf(g, x, z)
  for _, o in ipairs(bodies) do
    if o ~= g then
      local ox, _, oz = getPosXYZ(o.obj)
      if math.sqrt((x - ox) ^ 2 + (z - oz) ^ 2) < g.sp.topHeight + o.sp.topHeight + 3 then return false end
    end
  end
  return true
end

local function touching(g)
  local px, _, pz = getPosXYZ(g.obj)
  local R = g.sp.topHeight
  if TABLE_W / 2 - math.abs(px) < R or TABLE_D / 2 - math.abs(pz) < R then return "the rim" end
  for _, o in ipairs(bodies) do
    if o ~= g then
      local ox, _, oz = getPosXYZ(o.obj)
      if math.sqrt((px - ox) ^ 2 + (pz - oz) ^ 2) < R + o.sp.topHeight then return NAMES[o.i] end
    end
  end
  return nil
end

local function redrop(g)
  race.done[#race.done + 1] = { title = g.sp.title, upright = g.rightedAt and g.rightedAt - g.t0,
                                rest = g.restedAt - g.t0, tilt = g.tilt }
  local was = g.sp.title
  reshape(g, nextSpec(g))
  local x, z = g.spot and g.spot[1] or 0, g.spot and g.spot[2] or 0
  for try = 1, 40 do
    if clearOf(g, x, z) then break end
    x = (math.random() - 0.5) * (FLAT_W - 20)
    z = (math.random() - 0.5) * (FLAT_D - 20)
  end
  g.run = g.run + 1
  place(g, randomQuat(), x, g.sp.topHeight + 9.5 + math.random() * 8, z, nil, randomSpin())
  resetBody(g)
  print(string.format("  %-7s %s lifted away after %g s at rest; dropping %s", NAMES[g.i], was,
                      v:getParam("redrop"), label(g)))
end

-- every minute while re-dropping: how the finished runs went, by shape
local function tally()
  local n = #race.done
  if n == 0 then return end
  local by, order = {}, {}
  for _, d in ipairs(race.done) do
    if not by[d.title] then by[d.title] = { t = {}, notUp = 0 }; order[#order + 1] = d.title end
    local b = by[d.title]
    b.t[#b.t + 1] = d.rest
    if d.tilt >= UPRIGHT_DEG then b.notUp = b.notUp + 1 end
  end
  table.sort(order)
  print(string.format("=== %.0f s: %d finished run%s ===", race.t, n, n == 1 and "" or "s"))
  for _, title in ipairs(order) do
    local b = by[title]
    table.sort(b.t)
    print(string.format("    %-26s %3d run%s, time to rest median %5.1f s (%.1f-%.1f)%s", title, #b.t,
                        #b.t == 1 and " " or "s", b.t[math.floor((#b.t + 1) / 2)], b.t[1], b.t[#b.t],
                        b.notUp > 0 and string.format(", %d not upright", b.notUp) or ""))
  end
end

-- rotation taking body vector p to world (0, -1, 0)
local function pointDown(p)
  local n = math.sqrt(p[1] ^ 2 + p[2] ^ 2 + p[3] ^ 2)
  local x, y, z = p[1] / n, p[2] / n, p[3] / n
  local ax, az = z, -x                          -- p x (0,-1,0) = (z, 0, -x)
  local s = math.sqrt(ax * ax + az * az)
  if s < 1e-9 then
    return (y < 0) and btQuaternion(0, 0, 0, 1) or btQuaternion(btVector3(1, 0, 0), math.pi)
  end
  return btQuaternion(btVector3(ax / s, 0, az / s), math.acos(math.max(-1, math.min(1, -y))))
end

local function headstand()
  setCount(v:getParam("count"))
  local s = spots(#bodies)
  for k, g in ipairs(bodies) do
    reshape(g, nextSpec(g))
    local yaw = btQuaternion(btVector3(0, 1, 0), math.random() * 2 * math.pi)
    local a = math.random() * 2 * math.pi
    local nudge = btQuaternion(btVector3(math.cos(a), 0, math.sin(a)), math.rad(1 + 2 * math.random()))
    g.spot = s[k]
    place(g, nudge * yaw * pointDown(g.sp.top), s[k][1], g.sp.topHeight + g.sp.margin + 0.1, s[k][2])
  end
  resetRace("Headstand")
end

local function kick()
  for _, g in ipairs(bodies) do
    g.body:setLinearVelocity(btVector3((math.random() - 0.5) * 40, 120 + math.random() * 80, (math.random() - 0.5) * 40))
    g.body:setAngularVelocity(btVector3((math.random() - 0.5) * 30, (math.random() - 0.5) * 10, (math.random() - 0.5) * 30))
    g.body:activate(true)
  end
  resetRace("Kick")
end

v:addShortcut("R", function(N) drop() end)
v:addShortcut("U", function(N) headstand() end)
v:addShortcut("K", function(N) kick() end)
v:addShortcut("]", function(N)
  v:addParam("count", math.min(MAX_COUNT, v:getParam("count") + 1), 1, MAX_COUNT, 1, "how many to drop")
  drop()
end)
v:addShortcut("[", function(N)
  v:addParam("count", math.max(1, v:getParam("count") - 1), 1, MAX_COUNT, 1, "how many to drop")
  drop()
end)

local function applyResistance()
  ROLL_DELTA = v:getParam("rolling") * 1e-4
  SPIN_DECEL = v:getParam("spin friction")
end
applyResistance()

v:onParamChanged(function(N, name, value)   -- bpp passes (frame, name, value)
  if name == "count" then
    if math.floor(tonumber(value)) ~= #bodies then drop() end
  elseif name == "shapes" then
    for _, g in ipairs(bodies) do g.turn = nil end
    drop()
  elseif name == "speed" or name == "steps" then
    applyTiming()
  elseif name == "rolling" or name == "spin friction" then
    applyResistance()
  else
    applyMaterials()
  end
end)

pcall(function()
  v:setHelpText(
    "Gomboc Variety\n" ..
    "  R  drop at random orientations\n" ..
    "  U  stand them on their heads\n" ..
    "  K  kick them up with a spin\n" ..
    "  ]  one more     [  one fewer\n" ..
    "Each drop brings the next shape: Gomboc-C,\n" ..
    "a Sloan beta shape, Gomboc-C at 75%, another\n" ..
    "beta, Gomboc-C at 125%, another beta, and\n" ..
    "every seventh a spiral polyhedron (21, 26,\n" ..
    "37 corners in turn).\n" ..
    "All have one resting and one balancing point,\n" ..
    "but the beta shapes are so gently sloped that\n" ..
    "rolling resistance usually stops them on their\n" ..
    "sides ('shapes' 1 leaves them out).\n" ..
    "Dark = tipped over, bright = upright.\n" ..
    "Hover over one to see what it is.")
end)

-- hover (needs bpp with the hover patch; harmless without it)
pcall(function()
  v:onHover(function(N, obj, x, y, z)
    local key = objectKey(obj)
    for _, g in ipairs(bodies) do
      if objectKey(g.obj) == key then
        local state = g.restedAt and "at rest" or (g.rightedAt and "upright, still moving" or "on its way")
        return string.format("%s, run %d\n%s\nmass %.0f g, %.1f cm across\ntilt %.1f deg  (%s)",
                             NAMES[g.i], g.run, g.sp.title, g.sp.mass * 1000, 2 * g.sp.topHeight,
                             g.tilt or 0, state)
      end
    end
    return nil
  end)
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

v:postSim(function(N)
  if not race.running then return end
  race.t = race.t + FRAME_DT
  local upright, rested = 0, 0
  for _, g in ipairs(bodies) do
    local tilt = tiltDeg(g)
    g.tilt = tilt
    local k = g.rightedAt and 10 or math.floor(10 * math.max(0, 1 - tilt / 90) + 0.5)
    if k ~= g.shade then g.shade = k; g.obj.col = SHADES[g.i][k] end

    if tilt < UPRIGHT_DEG then
      upright = upright + 1
      g.restSince = g.restSince or race.t
      if not g.rightedAt and race.t - g.restSince >= HOLD then
        g.rightedAt = g.restSince
        print(string.format("  %-7s upright after %6.2f s -- %s", NAMES[g.i], g.rightedAt - g.t0, label(g)))
      end
    else
      g.restSince = nil
    end

    local q = g.body:getOrientation()
    local qx, qy, qz, qw = q:getX(), q:getY(), q:getZ(), q:getW()
    local px, py, pz = getPosXYZ(g.obj)
    local moved = true
    if g.anchorT then
      local dot = math.abs(qx * g.aq[1] + qy * g.aq[2] + qz * g.aq[3] + qw * g.aq[4])
      local turnA = 2 * math.acos(math.min(1, dot))
      local dx, dy, dz = px - g.ap[1], py - g.ap[2], pz - g.ap[3]
      moved = turnA > REST_TURN or math.sqrt(dx * dx + dy * dy + dz * dz) > REST_MOVE
    end
    if not moved and race.t - g.anchorT >= REST_HOLD then
      g.anchorT, g.aq, g.ap = race.t, { qx, qy, qz, qw }, { px, py, pz }
      if not g.restedAt then
        g.restedAt, g.restSeenAt = race.t - REST_HOLD, race.t
        local why = touching(g)
        g.touching = why
        print(string.format("  %-7s at rest after %6.2f s, %.1f deg off upright%s%s -- %s", NAMES[g.i],
                            g.restedAt - g.t0, tilt, tilt < UPRIGHT_DEG and "" or "  ** NOT UPRIGHT **",
                            why and ("  (touching " .. why .. ")") or "", label(g)))
      end
    elseif moved then
      g.anchorT, g.aq, g.ap = race.t, { qx, qy, qz, qw }, { px, py, pz }
      g.restedAt, g.restSeenAt = nil, nil
    end
    if g.restedAt then rested = rested + 1 end
  end

  local wait = v:getParam("redrop")
  if wait > 0 then
    for _, g in ipairs(bodies) do
      if g.restSeenAt and race.t - g.restSeenAt >= wait then
        rested = rested - 1
        redrop(g)
      end
    end
    if race.t >= race.nextTally then
      race.nextTally = race.nextTally + 60
      tally()
    end
  end

  if race.t >= race.nextReport then
    race.nextReport = race.nextReport + (race.t < 20 and 1 or 5)
    local tilts = {}
    for _, g in ipairs(bodies) do tilts[#tilts + 1] = string.format("%3.0f", g.tilt) end
    print(string.format("t=%5.1fs  upright %d/%d  at rest %d/%d  tilt(deg): %s", race.t,
                        upright, #bodies, rested, #bodies, table.concat(tilts, " ")))
  end

  if wait <= 0 and (rested == #bodies or race.t >= RACE_LIMIT) then
    race.running = false
    print(rested == #bodies and string.format("--- all %d at rest after %.2f s ---", #bodies, race.t)
          or string.format("--- %d of %d at rest after %.0f s; stopped watching ---", rested, #bodies, race.t))
    print("R: drop again   U: headstands   K: kick")
  end
end)

math.randomseed(envnum("GV_SEED", os.time()))
-- build every shape once up front, so a re-drop never waits for a mesh to load
for _, s in ipairs(C_SIZES) do spec("C", s) end
for _, b in ipairs(BETAS) do spec(b) end
spec("P21"); spec("P26"); spec("P37")
if os.getenv("GV_START") == "headstand" then headstand() else drop() end
