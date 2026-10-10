--
-- Bille Drop: weighted monostable bodies -- Bille and the spiral polyhedra
--
-- Every body here works because of WHERE ITS MASS IS, not because of its
-- shape alone (the uniform-density Gombocs are in ../Gomboc/). Each colour
-- runs through a cycle; when it has been at rest for `redrop` seconds it is
-- lifted away and the next body in the cycle is dropped in its colour:
--
--   Red, Yellow, Orange:   always Billes
--   Green, Blue, Purple:   21-corner -> 26-corner -> 37-corner polyhedron -> ...
--
-- so the table holds Billes and polyhedra half and half (a Bille settles in
-- half a second, a polyhedron takes several, so alternating each colour's
-- drops would fill the table with polyhedra). Bodies are drawn dark until they rest on
-- their one stable face, then bright. When a Bille has an EDGE LYING FLAT on
-- the table -- exactly two corners touching, not resting on face D -- that
-- edge lights up white (for at least 0.6 s on screen), as it rolls from face
-- to face, so the moments between faces are easy to catch; the console lists
-- the edges it rolled on. The "polyhedra look" slider draws the
-- polyhedra as solids (0) or as frames, balls on rods (1); the physics is
-- the same either way.
--
-- BILLE (Almadi, Dawson & Domokos, 2025) is a tetrahedron that can rest on
-- only one of its four faces. Its frame is mostly hollow (carbon-fibre tubes
-- along the six edges) with a dense tungsten-carbide part placed so that the
-- centre of mass sits in a tiny "loading zone": put it down on any face and
-- it tips over, face to face, until it lands on face D. It has one stable
-- face but TWO unstable corners -- monostable, not a full Gomboc.
--   THE SHAPE IS A RECONSTRUCTION. The paper (arXiv:2506.19244) gives the
--   vertex coordinates only in a figure image. This shape was fitted to the
--   numbers that are published in text: longest edge 500 mm, volume
--   668.624 cm^3, and the four loading-zone volumes of Table 1 -- all five
--   matched exactly, and the obtuse path A-B-C-D the theory requires came out
--   of the fit by itself. The tungsten-carbide wedge along edge BC was then
--   designed (tubes 1/0.5 mm at 1.36 g/cm^3, WC at 14.15 g/cm^3, total 120 g)
--   to put the centre of mass 0.8 mm inside the face-D loading zone -- which
--   is itself only 1.5 mm deep at its deepest. See bille-meshes/bille-data.lua.
--   Faces are named by the opposite vertex. Predicted (quasi-static) falling
--   pattern: B -> A -> D <- C. Tested alone: re-dropped 346 times, always
--   ended on face D. The drawing thickens the tubes to 3 mm so they show.
--
-- THE SPIRAL POLYHEDRA (after Domokos & Kovacs, "Conway's spiral and a
-- discrete Gomboc with 21 point masses", 2023): an apex above n horizontal
-- regular k-gons, with equal weights in the corners. Each has ONE stable face
-- (the base) and ONE unstable vertex (the apex) -- a "discrete Gomboc".
-- Their side faces come in bands, S1 next to the base up to the apex band;
-- each band tips onto the one below it: S4 -> S3 -> S2 -> S1 -> base.
--   21 corners (4 pentagons): the fewest for which this design works. The
--      physics is the paper's idealisation -- all the mass in the corners, a
--      weightless skin; a real one is practically impossible to build.
--   26 corners (5 pentagons) and 37 corners (6 hexagons): simulated as REAL
--      objects -- a thin polycarbonate shell with a tungsten weight in each
--      corner -- with shapes fitted for that build. The 37 tolerates 0.5 mm
--      build errors. See bille-meshes/p21.lua, p26.lua, p37.lua and
--      ../Gomboc/variety-reconstruction/.
--   Here they are scaled up 4.5x (40 cm tall) to stand beside Bille; size
--   does not change where a body can rest, only how fast it tips (the
--   masses scale with size^3).
--
-- Physics as in Gomboc Drop C: contact through the convex hull, exact mass
-- and inertia, rolling resistance and spin friction as constant moments at
-- the table before every physics step, no air drag, no taps.
--
-- Sizes: each colour also has its own size (Red 1.0, Green 0.6, Yellow 1.3,
-- Blue 0.8, Orange 1.15, Purple 0.7, applied to whichever body it carries).
-- Tipping times grow as sqrt(size); drop heights are scaled with size.
-- Rolling resistance (a lever arm in microns) is a property of the materials
-- and is NOT scaled. The "size spread" slider runs from 0 (all size 1) to 1.
--
-- Units: centimetres, kilograms, seconds.
--
-- Keys
--   R   drop them all again, at random orientations (each takes its next body)
--   U   set them all down gently on a face other than the stable one, and watch
--   K   kick: toss them all up with a spin
--   Z   slow motion (50x slower, the default) <-> 10x slower
--   ]   one more (and drop)      [   one fewer
--
-- Slow motion: in real time these bodies are very quick -- nearly all their
-- mass sits low, so a tip from one face to the next takes a twentieth of a
-- second. The demo therefore starts at 1/50 speed ("speed" slider,
-- 0.001-0.1). Console times are simulated seconds; "redrop" counts on-screen
-- seconds.
--
-- Hover the mouse over a body (bpp with the hover patch) to see what it is.
--
-- Headless testing: bpp -f bille-drop.lua -n FRAMES, with BD_SEED, BD_COUNT,
-- BD_BODIES, BD_SPEED, BD_STEPS, BD_ROLL, BD_SPIN, BD_DRAG, BD_REST,
-- BD_REDROP, BD_SPREAD, BD_START=setdown and BD_LOG=file.csv.
--

local common = require "common"

-- ---------------------------------------------------------------------
-- data
-- ---------------------------------------------------------------------

local MESH_DIR = "bille-meshes/"
do
  local found = false
  for _, dir in ipairs({ MESH_DIR, "demo/bille/" .. MESH_DIR, "demo/WyomingWill/Bille/" .. MESH_DIR }) do
    local f = io.open(dir .. "bille-data.lua", "r")
    if f then f:close(); MESH_DIR = dir; found = true; break end
  end
  if not found then error("bille-meshes/ not found") end
end
local function load(name) return dofile(MESH_DIR .. name .. ".lua") end

local G = 981
local POLY_SCALE = 4.5              -- the 9 cm polyhedra, drawn 40 cm tall here

-- the body kinds: vertices (body frame, COM at the origin, principal axes),
-- faces { n = outward normal, h = COM height above it, name, next }, the
-- stable face, the top point, mass, squared radii of gyration, margin
local KIND = {}
do
  local B = load("bille-data")
  local faces, verts = {}, {}
  local NEXT = { A = "D", B = "A", C = "D" }
  for _, f in ipairs({ "A", "B", "C", "D" }) do
    faces[#faces + 1] = { n = B.normals[f], h = B.height[f], name = f, next = NEXT[f] }
    local p = B.vertices[f]
    verts[#verts + 1] = p[1]; verts[#verts + 1] = p[2]; verts[#verts + 1] = p[3]
  end
  KIND.bille = { title = "Bille", short = "Bille", obj = "bille.obj", scale = 1, points = verts, faces = faces,
                 vnames = { "A", "B", "C", "D" },
                 home = "D", top = B.vertices.D, mass = B.mass,
                 K2 = { B.inertia[1] / B.mass, B.inertia[2] / B.mass, B.inertia[3] / B.mass },
                 margin = B.tubeRadius, sizeName = "longest edge" , sizeRef = 50 }
  for _, nv in ipairs({ 21, 26, 37 }) do
    local p = load("p" .. nv)
    KIND["p" .. nv] = { title = nv .. "-corner polyhedron" .. (nv == 21 and " (ideal)" or " (shell + weights)"),
                        short = nv .. "-corner", obj = "p" .. nv .. ".obj", frameObj = "p" .. nv .. "-frame.obj",
                        scale = POLY_SCALE,
                        points = p.vertices, faces = p.faces, home = "base", top = p.top, mass = p.mass,
                        K2 = p.inertia, margin = p.margin, sizeName = "tall", sizeRef = 9 * POLY_SCALE }
  end
end
local CYCLE = { [1] = { "bille" }, [2] = { "p21", "p26", "p37" } }

-- size of each colour (1 = the real Bille / a 40 cm polyhedron)
local SIZES = { 1.0, 0.6, 1.3, 0.8, 1.15, 0.7 }

-- drawing meshes can't be scaled in bpp: a scaled copy of the OBJ is written
-- to a temporary file, loaded once (bpp caches it) and the file deleted
local OBJ_LINES = {}
local function scaledObj(file, s)
  if math.abs(s - 1) < 1e-9 then return MESH_DIR .. file end
  if not OBJ_LINES[file] then
    local t = {}
    for line in io.lines(MESH_DIR .. file) do t[#t + 1] = line end
    OBJ_LINES[file] = t
  end
  local name = ((package.config:sub(1, 1) == "\\" and (os.getenv("TEMP") or ".") or "") .. os.tmpname())
  local f = assert(io.open(name, "w"))
  for _, line in ipairs(OBJ_LINES[file]) do
    local x, y, z = line:match("^v%s+(%S+)%s+(%S+)%s+(%S+)")
    if x then f:write(string.format("v %.5f %.5f %.5f\n", tonumber(x) * s, tonumber(y) * s, tonumber(z) * s))
    else f:write(line, "\n") end
  end
  f:close()
  return name
end

-- a kind at a size: hull, mass, inertia and scaled faces, built once and shared
local SPECS, KEEP = {}, {}
local function spec(kind, size)
  local K0 = KIND[kind]
  local frame = K0.frameObj and math.floor(v:getParam("polyhedra look") + 0.5) == 1
  local key = kind .. "@" .. string.format("%.4f", size) .. (frame and "/frame" or "")
  if SPECS[key] then return SPECS[key] end
  local K = KIND[kind]
  local s = K.scale * size
  local hull = btConvexHullShape()
  local p = K.points
  for i = 1, #p, 3 do hull:addPoint(btVector3(p[i] * s, p[i + 1] * s, p[i + 2] * s), false) end
  hull:recalcLocalAabb()
  hull:setMargin(K.margin * s)
  local reach = 0
  for i = 1, #p, 3 do reach = math.max(reach, math.sqrt(p[i] ^ 2 + p[i + 1] ^ 2 + p[i + 2] ^ 2) * s) end
  local faces = {}
  for _, f in ipairs(K.faces) do faces[#faces + 1] = { n = f.n, h = f.h * s, name = f.name, next = f.next } end
  local objName = frame and K.frameObj or K.obj
  local file = scaledObj(objName, s)
  KEEP[key] = Mesh(file, 0, false)
  if file ~= MESH_DIR .. objName then os.remove(file) end
  local vtx = {}
  if K.vnames then
    for i = 1, #p, 3 do vtx[#vtx + 1] = { p[i] * s, p[i + 1] * s, p[i + 2] * s } end
  end
  local m = K.mass * s ^ 3
  local k2 = { K.K2[1] * s * s, K.K2[2] * s * s, K.K2[3] * s * s }
  local sp = { kind = kind, size = size, s = s, file = file, hull = hull, mass = m, k2 = k2,
               inertia = btVector3(k2[1] * m, k2[2] * m, k2[3] * m), margin = K.margin * s, reach = reach,
               faces = faces, home = K.home, top = { K.top[1] * s, K.top[2] * s, K.top[3] * s },
               title = K.title, short = K.short, vnames = K.vnames, vtx = vtx,
               sizeText = string.format("%.0f cm %s", K.sizeRef * size, K.sizeName) }
  local nxt = {}
  for _, f in ipairs(faces) do if f.next then nxt[f.name] = f.next end end
  sp.nextOf = nxt
  SPECS[key] = sp
  return sp
end

-- ---------------------------------------------------------------------
-- world, sliders, timing
-- ---------------------------------------------------------------------

common.gravity(-G)

local MAX_COUNT = 6
local function envnum(name, default) return tonumber(os.getenv(name) or "") or default end
local function param(name, value, lo, hi, step, info) v:addParam(name, value, lo, hi, step, info) end
param("count", envnum("BD_COUNT", 3), 1, MAX_COUNT, 1, "how many bodies to drop")
param("bodies", envnum("BD_BODIES", 0), 0, 2, 1,
      "0 = half and half (Red, Yellow, Orange Billes; Green, Blue, Purple polyhedra); 1 = Bille only; 2 = the polyhedra only")
param("polyhedra look", envnum("BD_LOOK", 0), 0, 1, 1,
      "0 = the polyhedra drawn as solids, 1 = as frames (balls at the corners, rods on the edges); the physics is the same")
param("speed", envnum("BD_SPEED", 0.02), 0.001, .1, 0.001,
      "simulated seconds per real second (0.02 = 50x slow motion; Z toggles 0.02 / 0.1)")
param("steps", envnum("BD_STEPS", 1200), 300, 4800, 300, "physics steps per simulated second")
param("friction", 0.5, 0.05, 1.0, 0.05, "friction coefficient, 1 = grippiest (Bullet multiplies it by the table's 0.8)")
param("restitution", envnum("BD_REST", 0.1), 0.0, 0.8, 0.05, "bounciness")
param("rolling", envnum("BD_ROLL", 50), 0, 300, 5,
      "rolling resistance lever arm, microns (constant moment at the table)")
param("spin friction", envnum("BD_SPIN", 0.7), 0, 5, 0.1, "deceleration of spin about the vertical, rad/s^2")
param("air drag", envnum("BD_DRAG", 0), 0, 1.5, 0.05, "Bullet velocity damping; real air drag is ~0")
param("size spread", envnum("BD_SPREAD", 1), 0, 1, 0.1,
      "0 = all size 1 (Bille 50 cm edge, polyhedra 40 cm tall); 1 = Red 1.0, Green 0.6, Yellow 1.3, Blue 0.8, Orange 1.15, Purple 0.7")
param("redrop", envnum("BD_REDROP", 5), 0, 30, 1,
      "real (on-screen) seconds at rest before a body is lifted away and the next of its colour dropped (0 = off)")

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
-- the table: version B's tray, sized for 50 cm bodies
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
-- the bodies
-- ---------------------------------------------------------------------

local COLOURS = { "#e6194b", "#3cb44b", "#ffe119", "#4363d8", "#f58231", "#911eb4" }
local NAMES = { "Red", "Green", "Yellow", "Blue", "Orange", "Purple" }
local function hex(c) return tonumber(c:sub(2, 3), 16), tonumber(c:sub(4, 5), 16), tonumber(c:sub(6, 7), 16) end
local DARK, BRIGHT = {}, {}
local EDGE_COL = "#ffffff"                    -- a Bille edge lying on the table
for i, c in ipairs(COLOURS) do
  local r, g, b = hex(c)
  DARK[i] = string.format("#%02x%02x%02x", math.floor(r * 0.3), math.floor(g * 0.3), math.floor(b * 0.3))
  BRIGHT[i] = c
end

local bodies = {}

local function sizeOf(i)
  return 1 + v:getParam("size spread") * (SIZES[i] - 1)
end

-- the next body in this colour's cycle (each colour starts at its own place)
local function nextSpec(g)
  local mode = math.floor(v:getParam("bodies") + 0.5)
  -- mode 0: odd colours (Red, Yellow, Orange) are always Billes, even ones
  -- (Green, Blue, Purple) cycle through the polyhedra -- an even split on the
  -- table, however long each kind takes to settle
  local cyc = (mode == 1 or (mode == 0 and g.i % 2 == 1)) and CYCLE[1] or CYCLE[2]
  g.turn = (g.turn or math.floor((g.i - 1) / 2)) + 1
  return spec(cyc[(g.turn - 1) % #cyc + 1], sizeOf(g.i))
end

local function applyMaterial(g)
  local d = v:getParam("air drag")
  g.body:setFriction(v:getParam("friction"))
  g.body:setRestitution(v:getParam("restitution"))
  g.body:setDamping(d, d)
end
local function applyMaterials() for _, g in ipairs(bodies) do applyMaterial(g) end end

-- the six edges of a Bille, each with a bar that is shown (drawn only, it
-- touches nothing) while that edge lies on the table
local HIDDEN = btVector3(0, -1000, 0)
local function makeBars(g, sp)
  g.bars = {}
  if not sp.vnames then return end
  local n = #sp.vtx
  for a = 1, n - 1 do
    for b = a + 1, n do
      local pa, pb = sp.vtx[a], sp.vtx[b]
      local L = math.sqrt((pa[1] - pb[1]) ^ 2 + (pa[2] - pb[2]) ^ 2 + (pa[3] - pb[3]) ^ 2)
      local w = 0.03 * sp.reach
      local bar = Cube(L, w, w, 0)
      bar.col = EDGE_COL
      pcall(function() bar.collides = false end)
      v:add(bar)
      bar.pos = HIDDEN
      g.bars[sp.vnames[a] .. sp.vnames[b]] = { obj = bar, a = a, b = b }
    end
  end
end
local function removeBars(g)
  for _, e in pairs(g.bars or {}) do v:remove(e.obj) end
  g.bars = {}
end

-- give body g a new shape: a new Mesh, rigid body (and edge bars) in its place
local function reshape(g, sp)
  if g.obj then v:remove(g.obj) end
  removeBars(g)
  makeBars(g, sp)
  local m = Mesh(sp.file, 0, false)
  local ms = btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, -60, 0)))
  local body = btRigidBody(sp.mass, ms, sp.hull, sp.inertia)
  m.body = body
  m.col = DARK[g.i]
  body:setActivationState(4)
  body:setContactProcessingThreshold(envnum("BD_CPT", 0.001))
  v:add(m)
  g.obj, g.body, g.sp, g.lit, g.barOn = m, body, sp, nil, nil
  applyMaterial(g)
end

local function randomQuat()
  local u1, u2, u3 = math.random(), 2 * math.pi * math.random(), 2 * math.pi * math.random()
  local a, b = math.sqrt(1 - u1), math.sqrt(u1)
  return btQuaternion(a * math.sin(u2), a * math.cos(u2), b * math.sin(u3), b * math.cos(u3))
end

-- rotation taking outward normal n (body frame) to world down, then a yaw
local function faceDownQuat(n, yaw)
  local nx, ny, nz = n[1], n[2], n[3]
  local ax, az = nz, -nx                 -- n x (0,-1,0)
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

-- world direction of a body-frame vector, and world position of a body point
local function toWorld(g, v3)
  local Bm = g.body:getCenterOfMassTransform():getBasis()
  local x, y, z = 0, 0, 0
  for c = 0, 2 do
    local e = Bm:getColumn(c)
    x, y, z = x + e.x * v3[c + 1], y + e.y * v3[c + 1], z + e.z * v3[c + 1]
  end
  return x, y, z
end
-- show the bar of edge name e (or hide the shown one when e is nil)
local function showBar(g, e)
  if g.barOn and g.barOn ~= e then g.bars[g.barOn].obj.pos = HIDDEN end
  g.barOn = e
  if not e then return end
  local bar = g.bars[e]
  local px, py, pz = getPosXYZ(g.obj)
  local ax, ay, az = toWorld(g, g.sp.vtx[bar.a])
  local bx, by, bz = toWorld(g, g.sp.vtx[bar.b])
  local dx, dy, dz = bx - ax, by - ay, bz - az
  local L = math.sqrt(dx * dx + dy * dy + dz * dz)
  dx, dy, dz = dx / L, dy / L, dz / L
  -- rotation taking the bar's x axis onto the edge: axis x * d = (0, -dz, dy)
  local s2 = math.sqrt(dz * dz + dy * dy)
  local q = (s2 < 1e-9) and btQuaternion(0, 0, 0, 1)
            or btQuaternion(btVector3(0, -dz / s2, dy / s2), math.acos(math.max(-1, math.min(1, dx))))
  bar.obj.trans = btTransform(q, btVector3(px + (ax + bx) / 2, py + (ay + by) / 2, pz + (az + bz) / 2))
end

-- which face it is lying on (normal within ON_DEG of straight down and
-- centre of mass at that face's resting height), or nil
local ON_DEG = 2.0
local function faceDown(g)
  local px, py, pz = getPosXYZ(g.obj)
  local h = py - tableHeight(px, pz) - g.sp.margin
  local best, bestAng = nil, 180
  for _, f in ipairs(g.sp.faces) do
    local _, wy, _ = toWorld(g, f.n)
    local ang = math.deg(math.acos(math.max(-1, math.min(1, -wy))))
    if ang < bestAng then best, bestAng = f, ang end
  end
  if bestAng < ON_DEG and math.abs(h - best.h) < 0.006 * g.sp.reach then return best.name, bestAng end
  return nil, bestAng
end

-- which edge of a Bille lies flat on the table: exactly two of its corners
-- touching (three = lying on a face), or nil
local EDGE_TOL = 0.0015          -- of the body's size (0.5 mm for a 50 cm Bille)
local function edgeDown(g)
  if not g.sp.vnames then return nil end
  local px, py, pz = getPosXYZ(g.obj)
  local tol, on = EDGE_TOL * g.sp.reach, {}
  for k, p in ipairs(g.sp.vtx) do
    local x, y, z = toWorld(g, p)
    if py + y - tableHeight(px + x, pz + z) - g.sp.margin < tol then on[#on + 1] = g.sp.vnames[k] end
  end
  if #on == 2 then return on[1] .. on[2] end
  return nil
end

-- ---------------------------------------------------------------------
-- rolling resistance and spin friction before every physics step
-- (as in Gomboc Drop C: constant moments at the contact, on the table only)
-- ---------------------------------------------------------------------
local ROLL_DELTA, SPIN_DECEL = 0.005, 0.7

local function resist(dt)
  if ROLL_DELTA <= 0 and SPIN_DECEL <= 0 then return end
  for _, g in ipairs(bodies) do
    local px, py, pz = getPosXYZ(g.obj)
    local r = py - tableHeight(px, pz) - g.sp.margin
    if r < g.sp.reach + 0.05 and r > 0 then
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
          k2 = k2 + g.sp.k2[c + 1] * d * d
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
local REST_HOLD = 0.4          -- simulated s (these settle within a fraction of a second)
local SETTLE = 0.03            -- simulated s on a face before it counts as part of the path
local FLASH = 0.6              -- on-screen s a Bille stays lit after an edge touch

local race = { t = 0, real = 0, nextReport = 1, nextTally = 60, done = {} }   -- t: simulated s, real: on-screen s

local function label(g)
  return (g.run > 1 and string.format("%s #%d", NAMES[g.i], g.run) or NAMES[g.i]) .. " (" .. g.sp.short .. ")"
end

local function predicted(g, f)
  local p = { f }
  while g.sp.nextOf[p[#p]] and #p < 12 do p[#p + 1] = g.sp.nextOf[p[#p]] end
  return table.concat(p, " -> ")
end

local function resetBody(g, startFace)
  g.t0 = race.t
  g.anchorT, g.restedAt, g.restSeenAt = nil, nil, nil
  g.path = startFace and { startFace } or {}
  g.cand, g.candSince = nil, race.t
  g.edges, g.edgeOn, g.flashUntil = {}, nil, 0
  g.homeAt = nil
  g.lit = nil
end

local function resetRace(what)
  race.t, race.real, race.nextReport, race.nextTally, race.done = 0, 0, 1, 60, {}
  print(string.format("\n--- %s: %d bod%s ---", what, #bodies, #bodies == 1 and "y" or "ies"))
  for _, g in ipairs(bodies) do
    print(string.format("    %-7s %s, %s, %.0f g", NAMES[g.i], g.sp.title, g.sp.sizeText, g.sp.mass * 1000))
  end
end

local function setCount(n)
  n = math.max(1, math.min(MAX_COUNT, math.floor(n)))
  while #bodies > n do
    local g = table.remove(bodies)
    v:remove(g.obj); removeBars(g)
  end
  while #bodies < n do bodies[#bodies + 1] = { i = #bodies + 1 } end
end

local function randomSpin()
  return btVector3((math.random() - 0.5) * 4, (math.random() - 0.5) * 4, (math.random() - 0.5) * 4)
end

-- drop height scaled with size, so each falls the same number of its own lengths
local function dropOne(g, x, z, k)
  local R = g.sp.reach
  place(g, randomQuat(), x, R * (1.2 + 0.16 * (k or 1) + 0.26 * math.random()), z, nil, randomSpin())
end

local function drop()
  setCount(v:getParam("count"))
  local s = spots(#bodies)
  for k, g in ipairs(bodies) do
    reshape(g, nextSpec(g))
    g.spot, g.run = s[k], 1
    dropOne(g, s[k][1], s[k][2], k)
    resetBody(g)
  end
  resetRace("Drop")
end

local function setdown()
  setCount(v:getParam("count"))
  local s = spots(#bodies)
  local starts = {}
  for k, g in ipairs(bodies) do
    reshape(g, nextSpec(g))
    local others = {}
    for _, f in ipairs(g.sp.faces) do if f.name ~= g.sp.home then others[#others + 1] = f end end
    local f = others[math.random(#others)]
    g.spot, g.run = s[k], 1
    place(g, faceDownQuat(f.n, math.random() * 2 * math.pi), s[k][1], f.h + g.sp.margin + 0.02, s[k][2])
    resetBody(g, f.name)
    starts[k] = f.name
  end
  resetRace("Set down on a face other than the stable one")
  for k, g in ipairs(bodies) do
    print(string.format("  %-7s set down on %s; predicted: %s", NAMES[g.i], starts[k], predicted(g, starts[k])))
  end
end

local function kick()
  for _, g in ipairs(bodies) do
    g.body:setLinearVelocity(btVector3((math.random() - 0.5) * 40, 150 + math.random() * 80, (math.random() - 0.5) * 40))
    g.body:setAngularVelocity(btVector3((math.random() - 0.5) * 12, (math.random() - 0.5) * 6, (math.random() - 0.5) * 12))
    g.body:activate(true)
  end
  resetRace("Kick")
  for _, g in ipairs(bodies) do g.run = 1; resetBody(g) end
end

local function clearOf(g, x, z)
  for _, o in ipairs(bodies) do
    if o ~= g then
      local ox, _, oz = getPosXYZ(o.obj)
      if math.sqrt((x - ox) ^ 2 + (z - oz) ^ 2) < g.sp.reach + o.sp.reach + 4 then return false end
    end
  end
  return true
end

-- another body close enough that they may touch (one can then be propped on
-- another and rest on the wrong face, as real ones can)
local function nearOther(g)
  local px, _, pz = getPosXYZ(g.obj)
  for _, o in ipairs(bodies) do
    if o ~= g then
      local ox, _, oz = getPosXYZ(o.obj)
      if math.sqrt((px - ox) ^ 2 + (pz - oz) ^ 2) < g.sp.reach + o.sp.reach then return NAMES[o.i] end
    end
  end
  return nil
end

local function redrop(g)
  local was = g.sp.short
  reshape(g, nextSpec(g))
  local x, z = g.spot[1], g.spot[2]
  for try = 1, 60 do
    if clearOf(g, x, z) then break end
    x = (math.random() - 0.5) * (FLAT_W - 2 * g.sp.reach)
    z = (math.random() - 0.5) * (FLAT_D - 2 * g.sp.reach)
  end
  g.run = g.run + 1
  dropOne(g, x, z, 1)
  resetBody(g)
  print(string.format("  %-7s %s lifted away after %g s at rest; dropping %s", NAMES[g.i], was,
                      v:getParam("redrop"), label(g)))
end

-- every on-screen minute: the finished runs, by body
local function tally()
  local n = #race.done
  if n == 0 then return end
  local by, order = {}, {}
  for _, d in ipairs(race.done) do
    if not by[d.title] then by[d.title] = { t = {}, home = 0, paths = {} }; order[#order + 1] = d.title end
    local b = by[d.title]
    b.t[#b.t + 1] = d.rest
    if d.home then b.home = b.home + 1 end
    b.paths[d.path] = (b.paths[d.path] or 0) + 1
  end
  table.sort(order)
  print(string.format("=== %.0f s: %d finished run%s ===", race.t, n, n == 1 and "" or "s"))
  for _, title in ipairs(order) do
    local b = by[title]
    table.sort(b.t)
    local ps = {}
    for p, c in pairs(b.paths) do ps[#ps + 1] = string.format("%s x%d", p, c) end
    table.sort(ps)
    print(string.format("    %-36s %3d run%s, %d on the stable face, time to rest median %.2f s; paths: %s",
                        title, #b.t, #b.t == 1 and " " or "s", b.home, b.t[math.floor((#b.t + 1) / 2)],
                        table.concat(ps, ", ")))
  end
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
  v:addParam("count", math.min(MAX_COUNT, v:getParam("count") + 1), 1, MAX_COUNT, 1, "how many bodies to drop")
  drop()
end)
v:addShortcut("[", function(N)
  v:addParam("count", math.max(1, v:getParam("count") - 1), 1, MAX_COUNT, 1, "how many bodies to drop")
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
  elseif name == "speed" or name == "steps" then
    applyTiming()
  elseif name == "rolling" or name == "spin friction" then
    applyResistance()
  elseif name == "size spread" then
    drop()
  elseif name == "polyhedra look" then
    drop()
  elseif name == "bodies" then
    for _, g in ipairs(bodies) do g.turn = nil end
    drop()
  else
    applyMaterials()
  end
end)

pcall(function()
  v:setHelpText("Bille Drop: weighted monostable bodies\n" ..
    "  R  drop at random orientations\n" ..
    "  U  set down on a face other than the stable one\n" ..
    "  K  kick them up with a spin\n" ..
    "  Z  slow motion (50x) <-> 10x slower\n" ..
    "  ]  one more     [  one fewer\n" ..
    "Red, Yellow, Orange: Billes. Green, Blue, Purple:\n" ..
    "spiral polyhedra, 21, 26, 37 corners in turn\n" ..
    "('bodies' slider: 1 = Billes only, 2 = polyhedra).\n" ..
    "A Bille's edge lights up white while it lies flat\n" ..
    "on the table (as it rolls from face to face).\n" ..
    "'polyhedra look': solid or frame.\n" ..
    "All work because of where their weight is.\n" ..
    "Dark = not yet on the\n" ..
    "stable face, bright = resting on it.\n" ..
    "Bille: B -> A -> D <- C.  Polyhedra: each band\n" ..
    "of side faces tips onto the next: ... S2 -> S1 -> base.\n" ..
    "Uniform-density Gombocs: see ../Gomboc/.")
end)

-- hover (needs bpp with the hover patch; harmless without it)
pcall(function()
  v:onHover(function(N, obj, x, y, z)
    local key = objectKey(obj)
    for _, g in ipairs(bodies) do
      if objectKey(g.obj) == key then
        local f = faceDown(g)
        return string.format("%s, run %d\n%s\n%s, %.0f g\n%s\nfaces so far: %s", NAMES[g.i], g.run, g.sp.title,
                             g.sp.sizeText, g.sp.mass * 1000,
                             f and ("on " .. f .. (f == g.sp.home and " (the stable face)" or "")) or "tipping",
                             #g.path > 0 and table.concat(g.path, " -> ") or "-")
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

local LOGF = os.getenv("BD_LOG") and io.open(os.getenv("BD_LOG"), "w")
if LOGF then LOGF:write("t,idx,name,body,run,face,angle_to_nearest_face_deg,angvel_deg_s,x,y,z\n") end

v:postSim(function(N)
  race.t = race.t + FRAME_DT
  race.real = race.real + 1 / 60
  for _, g in ipairs(bodies) do
    local f, ang = faceDown(g)
    -- a face joins the path once the body has lain on it for SETTLE seconds
    -- (so a body rocking across an edge doesn't fill the path with repeats)
    if f ~= g.cand then g.cand, g.candSince = f, race.t end
    if f and race.t - g.candSince >= SETTLE and g.path[#g.path] ~= f then
      g.path[#g.path + 1] = f
      if f == g.sp.home then g.homeAt = race.t end
    end
    -- a Bille edge lying on the table (not on its stable face) is lit up,
    -- for at least FLASH on-screen seconds so brief edge-rolls are visible,
    -- and noted for the console
    local e = (f ~= g.sp.home) and edgeDown(g) or nil
    if e then
      g.flashUntil, g.flashEdge = race.real + FLASH, e
      if e ~= g.edgeOn and g.edges[#g.edges] ~= e then g.edges[#g.edges + 1] = e end
    end
    g.edgeOn = e
    if g.sp.vnames then showBar(g, (race.real < (g.flashUntil or 0)) and (e or g.flashEdge) or nil) end
    local look = (f == g.sp.home) and "home" or "dark"
    if look ~= g.lit then g.lit = look; g.obj.col = (look == "home") and BRIGHT[g.i] or DARK[g.i] end

    if LOGF and N % 15 == 0 then
      local wx, wy, wz = getAngVelXYZ(g.obj)
      local px, py, pz = getPosXYZ(g.obj)
      LOGF:write(string.format("%.2f,%d,%s,%s,%d,%s,%.3f,%.4f,%.3f,%.3f,%.3f\n", race.t, g.i, NAMES[g.i], g.sp.kind,
        g.run, f or "-", ang, math.deg(math.sqrt(wx * wx + wy * wy + wz * wz)), px, py, pz))
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
        local home = (f == g.sp.home)
        local edges = (g.edges and #g.edges > 0) and ("; edges it rolled on: " .. table.concat(g.edges, ", ")) or ""
        local near = nearOther(g)
        print(string.format("  %-7s at rest on %s after %5.2f s; faces it lay on: %s%s%s%s -- %s", NAMES[g.i],
                            f and ("face " .. f) or "no face (propped?)", g.restedAt - g.t0, path, edges,
                            home and "" or "  ** NOT ON THE STABLE FACE **",
                            (not home and near) and ("  -- may be touching " .. near) or "", label(g)))
        g.result = { title = g.sp.title, home = home, rest = g.restedAt - g.t0, path = path }
      end
    elseif moved then
      g.anchorT, g.aq, g.ap = race.t, { qx, qy, qz, qw }, { px, py, pz }
      g.restedAt, g.restSeenAt = nil, nil
    end
  end

  local wait = v:getParam("redrop")
  if wait > 0 then
    for _, g in ipairs(bodies) do
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
    for _, g in ipairs(bodies) do
      local f = faceDown(g)
      st[#st + 1] = string.format("%s:%s%s", NAMES[g.i]:sub(1, 1), f or "-", g.restedAt and "." or "")
    end
    print(string.format("t=%5.1fs  on face (. = at rest): %s", race.t, table.concat(st, " ")))
  end
end)

math.randomseed(envnum("BD_SEED", os.time()))
-- build every body once up front at each colour's size, so a re-drop never waits for a mesh
for i = 1, MAX_COUNT do for _, k in ipairs({ "bille", "p21", "p26", "p37" }) do spec(k, sizeOf(i)) end end
if os.getenv("BD_START") == "setdown" then setdown() else drop() end
