--
-- The Oloid and the Sphericon -- Euler's Cabinet of Curiosities
--
-- Three wooden rollers, each the convex hull of two circular arcs, given a
-- push along a level board. None of them is round, yet each rolls, and
-- as it rolls every part of its surface touches the board: it lays its
-- whole surface down, as a cylinder or a cone does, but in a wobbling,
-- weaving line.
--
--   back    the oloid (Paul Schatz, 1929): two circles in perpendicular
--           planes, each through the other's centre. Its centre of mass
--           rises and falls a little as it goes.
--   middle  the two-circle roller (A. T. Stewart, 1966): the same, but the
--           circles' centres R sqrt(2) apart. Its centre of mass stays at
--           exactly the same height as it rolls: on a level table it would
--           stay put wherever it was set down.
--   front   the sphericon: a double cone with right angles at its points,
--           cut along its axis and one half turned a quarter turn. It rolls
--           on one cone, then the other; its centre of mass stays at the
--           same height too (R / sqrt 2).
--
-- All three weave from side to side as they go, 4 to 6 cm; what tells
-- them apart is whether their centre stays at one height.
--
-- THE PENS: above each roller, on a dotted stem from its centre, a pen
-- draws its centre's height, 20 times over, straight above its lane, over
-- a thin rod at its height in theory: the oloid's red wave runs between
-- two rods (its lowest and highest), the two-circle roller's blue line and
-- the sphericon's green lie flat on theirs. On the board, a dotted track
-- under each marks its path: how it weaves from side to side.
--
-- Theory, from the shapes alone (worked out as the script loads): the
-- height of the centre of mass above the board for every way the roller
-- can lie on it touching it along a line -- constant for the two-circle
-- roller and the sphericon, between two limits for the oloid. The console
-- gives what each does as it rolls, and its energy: rolling without
-- slipping, it loses none but what the rolling resistance takes.
--
-- THE ROLLERS: arcs of radius 6 cm, a light wood (0.7 g/cm^3): the oloid
-- 462 g, the two-circle roller 496 g, the sphericon 317 g. Their volumes
-- and moments of inertia are worked out from their shapes
-- (reconstruction/gen-meshes.py). Each is pushed off at 15 cm/s.
--
-- PHYSICS: Bullet moves each roller (a rigid body); its contact with the
-- board is worked out here, before every physics step, exactly for its
-- shape: the lowest point of each of its two arcs (where it touches the
-- board, along the line between them), impulses that stop it going into
-- the board, and friction (0.6, so it doesn't slip) -- solved together a
-- few times over, as Bullet solves its contacts; Euler's equations for its
-- spin (Bullet's gyroscopic term off). A little rolling resistance (20
-- microns) slows it. 2400 physics steps a second.
--
-- Keys
--   R   set them rolling again
--   Z   slow motion (1/4) <-> real time
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: OL_SPEED, OL_STEPS, OL_PUSH (cm/s), OL_SLOPE (degrees: the
-- board tilted down along it), OL_LOG=file.csv.
--

local common = require "common"

local DIR = "oloid-meshes/"
for _, dir in ipairs({ DIR, "demo/WyomingWill/Oloid/" .. DIR }) do
  local f = io.open(dir .. "oloid.obj", "r")
  if f then f:close(); DIR = dir; break end
end
local SHAPES = dofile(DIR .. "rollers.lua")

local G = 981
local AR = 6.0                             -- the arcs' radius
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("speed", envnum("OL_SPEED", 1), 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
param("steps", envnum("OL_STEPS", 2400), 1200, 9600, 600, "physics steps per simulated second")

local STEP, NSTEPS, FRAME_DT = 1 / 2400, 40, 1 / 60
local function applyTiming()
  local speed = v:getParam("speed")
  NSTEPS = math.max(1, math.floor(v:getParam("steps") * speed / 60 + 0.5))
  FRAME_DT = speed / 60
  STEP = FRAME_DT / NSTEPS
  v.animationPeriod = 16
  common.setTiming(STEP, 0, STEP)
end

-- ---------------------------------------------------------------------
-- a pause at every start: one frame to put everything in place, then it
-- all stands still for HOLD_S seconds (half a second), so you see how it begins --
-- bpp's own physics step stopped too (a zero time step) -- and then it
-- carries on from there, exactly as if there had been no pause
-- ---------------------------------------------------------------------
local HOLD_FRAMES = math.floor(envnum("HOLD_S", 0.5) * 60 + 0.5)
local holdArm, holdLeft, holdNow = false, 0, false
local function holdStart() holdArm, holdLeft = true, 0 end
local function holdPre()            -- first thing before each step: true while it stands still
  if holdLeft > 0 then
    holdLeft = holdLeft - 1
    holdNow = true
    v.timeStep = 0
    return true
  end
  if holdNow then holdNow = false; applyTiming() end
  if holdArm then holdArm, holdLeft = false, HOLD_FRAMES end
  return false
end
applyTiming()
v.gravity = btVector3(0, -G, 0)
local MU, DELTA = 0.6, 0.002

local Q0 = btQuaternion(0, 0, 0, 1)
local function block(sx, sy, sz, x, y, z, col, q)
  local c = Cube(sx, sy, sz, 0)
  c.trans = btTransform(q or Q0, btVector3(x, y, z))
  c.col = col
  c.collides = false
  v:add(c)
  return c
end

-- ---------------------------------------------------------------------
-- the table and the sloping board
-- ---------------------------------------------------------------------
local TABLE_Y = 0
block(150, 3, 100, 0, TABLE_Y - 1.5, 0, "#7a4a24")
for _, x in ipairs({ -70, 70 }) do
  for _, z in ipairs({ -45, 45 }) do block(3, 72, 3, x, TABLE_Y - 3 - 36, z, "#4e2e15") end
end
local floor = Plane(0, 1, 0, TABLE_Y - 75, 300)
floor.col = "#3b3f45"
v:add(floor)

local SLOPE = math.rad(envnum("OL_SLOPE", 0))
local PUSH = envnum("OL_PUSH", 15)              -- cm/s, a push to start it
local BL, BW = 130, 96                     -- the board: length (down the slope), width
local BX0 = -BL / 2                        -- its top end, x
local BY0 = TABLE_Y + 2 + BL * math.sin(SLOPE)   -- its surface there
-- the board's surface: through (BX0, BY0, 0), normal n (tilted down toward +x)
local NX, NY = math.sin(SLOPE), math.cos(SLOPE)
local function boardY(x) return BY0 - (x - BX0) * math.tan(SLOPE) end
do
  local q = btQuaternion(btVector3(0, 0, 1), -SLOPE)
  local th = 1.5
  local cx = BX0 + BL / 2 * math.cos(SLOPE)
  local cy = BY0 - BL / 2 * math.sin(SLOPE)
  block(BL, th, BW, cx - NX * th / 2, cy - NY * th / 2, 0, "#c9a877", q)
  -- its legs at the top end, and the stop at the bottom
  block(3, BY0 - TABLE_Y, BW - 6, BX0 + 2, (BY0 + TABLE_Y) / 2 - 0.8, 0, "#6a4424")
end
local STOP_X = BX0 + BL * math.cos(SLOPE) - 2   -- the stop's face
block(3, 6, BW, STOP_X + 1.5, boardY(STOP_X) + 2.5, 0, "#6a4424")

-- ---------------------------------------------------------------------
-- the rollers
-- ---------------------------------------------------------------------
local ROLLERS = {
  { kind = "oloid", name = "Back, the oloid -- its centre rises and falls a little as it rolls", short = "Oloid", z = -32, yaw = -14.7,
    col = "#d9b36c" },
  { kind = "two-circle", name = "Middle, the two-circle roller -- its centre stays at one height", short = "2-circle", z = 0, yaw = 12.0,
    col = "#c98f52" },
  { kind = "sphericon", name = "Front, the sphericon -- its centre stays at one height", short = "Sphericon", z = 32, yaw = -25.6,
    col = "#e0c48e" },
}
local KEYS = {}
for _, r in ipairs(ROLLERS) do
  local S = SHAPES[r.kind]
  r.mass, r.I, r.arcs = S.mass, S.I, S.arcs
  local m = Mesh(DIR .. r.kind .. ".obj", 0, false)
  local body = btRigidBody(r.mass, btDefaultMotionState(btTransform(Q0, btVector3(0, 50, r.z))), btSphereShape(AR),
                           btVector3(r.I[1], r.I[2], r.I[3]))
  m.body = body
  m.col = r.col
  m.collides = false                         -- (its contacts are worked out below)
  v:add(m)
  body:setActivationState(4)
  body:setDamping(0, 0)
  body:setFlags(1)                           -- no world gravity, no gyroscopic term: both below
  body:setGravity(btVector3(0, 0, 0))
  local edges = Mesh(DIR .. r.kind .. "-edges.obj", 0, false)
  edges.col = "#5a3418"
  edges.collides = false
  v:add(edges)
  r.m, r.b, r.edges = m, body, edges
  KEYS[objectKey(m)] = r
  KEYS[objectKey(edges)] = r
end

-- ---------------------------------------------------------------------
-- the shapes: the point of an arc furthest along a direction (in the
-- roller's own frame)
-- ---------------------------------------------------------------------
local function arcSupport(a, d1, d2, d3)
  local c, u, w = a.c, a.u, a.w
  local du = d1 * u[1] + d2 * u[2] + d3 * u[3]
  local dw = d1 * w[1] + d2 * w[2] + d3 * w[3]
  local best = math.atan2(dw, du)
  if best < a.a0 or best > a.a1 then
    -- (outside a half circle: one of its ends)
    local v0 = du * math.cos(a.a0) + dw * math.sin(a.a0)
    local v1 = du * math.cos(a.a1) + dw * math.sin(a.a1)
    best = v0 > v1 and a.a0 or a.a1
  end
  local cs, sn = math.cos(best), math.sin(best)
  local p1 = c[1] + AR * (cs * u[1] + sn * w[1])
  local p2 = c[2] + AR * (cs * u[2] + sn * w[2])
  local p3 = c[3] + AR * (cs * u[3] + sn * w[3])
  return p1, p2, p3, d1 * p1 + d2 * p2 + d3 * p3
end

-- the theory: lying on the board along a line (both arcs touching), how
-- high is its centre? For every direction "down" in its own frame where
-- the two arcs reach equally far, that reach.
local function heights(r)
  local lo, hi = 1e9, -1e9
  local A1, A2 = r.arcs[1], r.arcs[2]
  local function diff(th, ph)
    local d1, d2, d3 = math.sin(th) * math.cos(ph), math.sin(th) * math.sin(ph), math.cos(th)
    local _, _, _, h1 = arcSupport(A1, d1, d2, d3)
    local _, _, _, h2 = arcSupport(A2, d1, d2, d3)
    return h1 - h2, h1
  end
  for i = 0, 719 do
    local ph = 2 * math.pi * i / 720
    local prev = diff(0.001, ph)
    for j = 1, 180 do
      local th = math.pi * j / 180 - (j == 180 and 0.001 or 0)
      local dcur = diff(th, ph)
      if (prev < 0) ~= (dcur < 0) then
        local a, b = math.pi * (j - 1) / 180, th
        for _ = 1, 40 do
          local mid = (a + b) / 2
          if (diff(mid, ph) < 0) == (prev < 0) then a = mid else b = mid end
        end
        local _, h = diff((a + b) / 2, ph)
        lo, hi = math.min(lo, h), math.max(hi, h)
      end
      prev = dcur
    end
  end
  return lo, hi
end
for _, r in ipairs(ROLLERS) do r.hlo, r.hhi = heights(r) end

-- ---------------------------------------------------------------------
-- the pens: above each roller, a trail of dots where its centre has been,
-- its height above the board drawn PEN_K times over (the oloid's rise and
-- fall of 0.26 cm becomes a wave 5 cm high; the others draw flat lines),
-- following it from side to side as it goes (all three weave). Under
-- each trail, a thin rod at its height in theory (R / sqrt 2: the lowest
-- the oloid's centre goes, the height the others' stays at), and for the
-- oloid a second rod at the highest its centre goes in theory.
-- ---------------------------------------------------------------------
local PEN_K, PEN_UP, PEN_N, STEM_N = 20, 13, 160, 7
local PEN_COL = { oloid = { "#d23a2a", "#8c2a20" }, ["two-circle"] = { "#2f74d0", "#234f8a" },
                  sphericon = { "#2fa34f", "#226f38" } }
local H_REF = AR / math.sqrt(2)
local Q0 = btQuaternion(0, 0, 0, 1)
local HIDDEN = btTransform(Q0, btVector3(0, -500, 0))
local function penY(x, h) return boardY(x) + PEN_UP + PEN_K * (h - H_REF) end
for _, r in ipairs(ROLLERS) do
  local pc = PEN_COL[r.kind]
  r.dots, r.stem = {}, {}
  for i = 1, STEM_N do
    local d = Sphere(i == STEM_N and 0.55 or 0.15, 0)
    d.col = pc[1]
    d.collides = false
    d.trans = HIDDEN
    v:add(d)
    r.stem[i] = d
  end
  r.track = {}
  for i = 1, PEN_N do
    local d = Sphere(0.22, 0)
    d.col = pc[2]
    d.collides = false
    d.trans = HIDDEN
    v:add(d)
    r.track[i] = d
  end
  for i = 1, PEN_N do
    local d = Sphere(0.3, 0)
    d.col = pc[1]
    d.collides = false
    d.trans = HIDDEN
    v:add(d)
    r.dots[i] = d
  end
  local x0, x1 = BX0 + 8, STOP_X - 2
  local qx = btQuaternion(btVector3(0, 1, 0), math.pi / 2)
  for _, h in ipairs(r.hhi - r.hlo > 1e-4 and { r.hlo, r.hhi } or { r.hlo }) do
    local rod = Cylinder(0.08, (x1 - x0) / math.cos(SLOPE), 0)
    rod.col = pc[2]
    rod.collides = false
    rod.trans = btTransform(btQuaternion(btVector3(0, 0, 1), -SLOPE) * qx, btVector3((x0 + x1) / 2, penY((x0 + x1) / 2, h), r.z))
    v:add(rod)
  end
end

-- ---------------------------------------------------------------------
-- before every physics step: gravity, Euler's equations, the board
-- ---------------------------------------------------------------------
local function load(e)
  local b = e.b
  local Bm = b:getCenterOfMassTransform():getBasis()
  local c1, c2, c3 = Bm:getColumn(0), Bm:getColumn(1), Bm:getColumn(2)
  e.c1x, e.c1y, e.c1z = c1.x, c1.y, c1.z
  e.c2x, e.c2y, e.c2z = c2.x, c2.y, c2.z
  e.c3x, e.c3y, e.c3z = c3.x, c3.y, c3.z
  local W, V, P = b:getAngularVelocity(), b:getLinearVelocity(), b:getCenterOfMassPosition()
  e.wx, e.wy, e.wz = W.x, W.y, W.z
  e.vx, e.vy, e.vz = V.x, V.y, V.z
  e.gx, e.gy, e.gz = P.x, P.y, P.z
end
local function iinv(e, x, y, z)
  local I = e.I
  local s1 = (e.c1x * x + e.c1y * y + e.c1z * z) / I[1]
  local s2 = (e.c2x * x + e.c2y * y + e.c2z * z) / I[2]
  local s3 = (e.c3x * x + e.c3y * y + e.c3z * z) / I[3]
  return s1 * e.c1x + s2 * e.c2x + s3 * e.c3x, s1 * e.c1y + s2 * e.c2y + s3 * e.c3y, s1 * e.c1z + s2 * e.c2z + s3 * e.c3z
end
local function imul(e, x, y, z)
  local I = e.I
  local s1 = (e.c1x * x + e.c1y * y + e.c1z * z) * I[1]
  local s2 = (e.c2x * x + e.c2y * y + e.c2z * z) * I[2]
  local s3 = (e.c3x * x + e.c3y * y + e.c3z * z) * I[3]
  return s1 * e.c1x + s2 * e.c2x + s3 * e.c3x, s1 * e.c1y + s2 * e.c2y + s3 * e.c3y, s1 * e.c1z + s2 * e.c2z + s3 * e.c3z
end
-- an arc's furthest point along a world direction, from the centre, in the world
local function worldSupport(e, a, dx, dy, dz)
  local d1 = e.c1x * dx + e.c1y * dy + e.c1z * dz
  local d2 = e.c2x * dx + e.c2y * dy + e.c2z * dz
  local d3 = e.c3x * dx + e.c3y * dy + e.c3z * dz
  local p1, p2, p3, h = arcSupport(a, d1, d2, d3)
  return p1 * e.c1x + p2 * e.c2x + p3 * e.c3x, p1 * e.c1y + p2 * e.c2y + p3 * e.c3y, p1 * e.c1z + p2 * e.c2z + p3 * e.c3z, h
end
local function apply(e, rx, ry, rz, jx, jy, jz)
  local m = e.mass
  e.vx, e.vy, e.vz = e.vx + jx / m, e.vy + jy / m, e.vz + jz / m
  local ax, ay, az = iinv(e, ry * jz - rz * jy, rz * jx - rx * jz, rx * jy - ry * jx)
  e.wx, e.wy, e.wz = e.wx + ax, e.wy + ay, e.wz + az
end
local function resp(e, rx, ry, rz, dx, dy, dz, ex, ey, ez)
  local ax, ay, az = iinv(e, ry * dz - rz * dy, rz * dx - rx * dz, rx * dy - ry * dx)
  local ux, uy, uz = ay * rz - az * ry, az * rx - ax * rz, ax * ry - ay * rx
  local m = e.mass
  return (dx / m + ux) * ex + (dy / m + uy) * ey + (dz / m + uz) * ez
end
local function velAt(e, rx, ry, rz)
  return e.vx + e.wy * rz - e.wz * ry, e.vy + e.wz * rx - e.wx * rz, e.vz + e.wx * ry - e.wy * rx
end
-- contacts: { r, n, gap } each; sequential impulses over all of them
local ITER = 8
local function solve(e, cs, h)
  for _, c in ipairs(cs) do
    local nx, ny, nz = c.nx, c.ny, c.nz
    local tx, ty, tz
    if math.abs(ny) > 0.7 then tx, ty, tz = 1, 0, 0 else tx, ty, tz = 0, 1, 0 end
    local d = tx * nx + ty * ny + tz * nz
    tx, ty, tz = tx - d * nx, ty - d * ny, tz - d * nz
    local tl = math.sqrt(tx * tx + ty * ty + tz * tz)
    c.tx, c.ty, c.tz = tx / tl, ty / tl, tz / tl
    c.sx, c.sy, c.sz = ny * c.tz - nz * c.ty, nz * c.tx - nx * c.tz, nx * c.ty - ny * c.tx
    local rx, ry, rz = c.rx, c.ry, c.rz
    c.Kn = resp(e, rx, ry, rz, nx, ny, nz, nx, ny, nz)
    c.a11 = resp(e, rx, ry, rz, c.tx, c.ty, c.tz, c.tx, c.ty, c.tz)
    c.a12 = resp(e, rx, ry, rz, c.sx, c.sy, c.sz, c.tx, c.ty, c.tz)
    c.a21 = resp(e, rx, ry, rz, c.tx, c.ty, c.tz, c.sx, c.sy, c.sz)
    c.a22 = resp(e, rx, ry, rz, c.sx, c.sy, c.sz, c.sx, c.sy, c.sz)
    c.det = c.a11 * c.a22 - c.a12 * c.a21
    c.bias = c.gap < 0 and (-0.2 * c.gap / h) or (-c.gap / h)
    c.jn, c.jt, c.js = 0, 0, 0
  end
  local W = 0
  for _ = 1, ITER do
    for _, c in ipairs(cs) do
      local rx, ry, rz = c.rx, c.ry, c.rz
      local ux, uy, uz = velAt(e, rx, ry, rz)
      local un = ux * c.nx + uy * c.ny + uz * c.nz
      local jnew = math.max(0, c.jn + (c.bias - un) / c.Kn)
      local dj = jnew - c.jn
      c.jn = jnew
      if dj ~= 0 then apply(e, rx, ry, rz, dj * c.nx, dj * c.ny, dj * c.nz) end
      ux, uy, uz = velAt(e, rx, ry, rz)
      local ut = ux * c.tx + uy * c.ty + uz * c.tz
      local us = ux * c.sx + uy * c.sy + uz * c.sz
      local nt = c.jt - (c.a22 * ut - c.a12 * us) / c.det
      local ns = c.js - (-c.a21 * ut + c.a11 * us) / c.det
      local nl = math.sqrt(nt * nt + ns * ns)
      local lim = MU * c.jn
      if nl > lim then nt, ns = nt * lim / nl, ns * lim / nl end
      local dt_, ds_ = nt - c.jt, ns - c.js
      c.jt, c.js = nt, ns
      if dt_ ~= 0 or ds_ ~= 0 then
        apply(e, rx, ry, rz, dt_ * c.tx + ds_ * c.sx, dt_ * c.ty + ds_ * c.sy, dt_ * c.tz + ds_ * c.sz)
        local vx, vy, vz = velAt(e, rx, ry, rz)
        W = W + dt_ * (ut + vx * c.tx + vy * c.ty + vz * c.tz) / 2 + ds_ * (us + vx * c.sx + vy * c.sy + vz * c.sz) / 2
      end
    end
  end
  return W
end

local function euler(e, h)
  local I1, I2, I3 = e.I[1], e.I[2], e.I[3]
  local w1 = e.c1x * e.wx + e.c1y * e.wy + e.c1z * e.wz
  local w2 = e.c2x * e.wx + e.c2y * e.wy + e.c2z * e.wz
  local w3 = e.c3x * e.wx + e.c3y * e.wy + e.c3z * e.wz
  local p, q, r = (I2 - I3) / I1, (I3 - I1) / I2, (I1 - I2) / I3
  local k11, k12, k13 = p * w2 * w3, q * w3 * w1, r * w1 * w2
  local a1, a2, a3 = w1 + h / 2 * k11, w2 + h / 2 * k12, w3 + h / 2 * k13
  local k21, k22, k23 = p * a2 * a3, q * a3 * a1, r * a1 * a2
  a1, a2, a3 = w1 + h / 2 * k21, w2 + h / 2 * k22, w3 + h / 2 * k23
  local k31, k32, k33 = p * a2 * a3, q * a3 * a1, r * a1 * a2
  a1, a2, a3 = w1 + h * k31, w2 + h * k32, w3 + h * k33
  local k41, k42, k43 = p * a2 * a3, q * a3 * a1, r * a1 * a2
  w1 = w1 + h / 6 * (k11 + 2 * k21 + 2 * k31 + k41)
  w2 = w2 + h / 6 * (k12 + 2 * k22 + 2 * k32 + k42)
  w3 = w3 + h / 6 * (k13 + 2 * k23 + 2 * k33 + k43)
  e.wx = e.c1x * w1 + e.c2x * w2 + e.c3x * w3
  e.wy = e.c1y * w1 + e.c2y * w2 + e.c3y * w3
  e.wz = e.c1z * w1 + e.c2z * w2 + e.c3z * w3
end

local function step(e, h)
  load(e)
  e.vy = e.vy - G * h
  euler(e, h)
  local cs = {}
  -- the board: each arc's lowest point (along -n)
  local N = 0
  for _, a in ipairs(e.arcs) do
    local rx, ry, rz = worldSupport(e, a, -NX, -NY, 0)
    local px, py = e.gx + rx, e.gy + ry
    local gap = (px - BX0) * NX + (py - BY0) * NY
    if gap < 0.05 then cs[#cs + 1] = { rx = rx, ry = ry, rz = rz, nx = NX, ny = NY, nz = 0, gap = gap } end
  end
  -- the stop at the bottom: each arc's furthest point along +x
  for _, a in ipairs(e.arcs) do
    local rx, ry, rz = worldSupport(e, a, 1, 0, 0)
    local gap = STOP_X - (e.gx + rx)
    if gap < 0.05 then cs[#cs + 1] = { rx = rx, ry = ry, rz = rz, nx = -1, ny = 0, nz = 0, gap = gap, stop = true } end
  end
  if #cs > 0 then
    e.Wf = e.Wf + solve(e, cs, h)
    for _, c in ipairs(cs) do
      if not c.stop then N = N + c.jn / h end
      if c.stop and c.jn > 0 then e.stopped = true end
    end
  end
  -- rolling resistance: a moment against the turning (but not about the
  -- board's normal), DELTA times the board's push
  if N > 0 and DELTA > 0 then
    local wn = e.wx * NX + e.wy * NY
    local hx, hy, hz = e.wx - wn * NX, e.wy - wn * NY, e.wz
    local wh = math.sqrt(hx * hx + hy * hy + hz * hz)
    if wh > 1e-9 then
      local ux, uy, uz = hx / wh, hy / wh, hz / wh
      local px, py, pz = iinv(e, ux, uy, uz)
      local tq = math.min(wh / (px * ux + py * uy + pz * uz), DELTA * N * h)
      local o0x, o0y, o0z = e.wx, e.wy, e.wz
      local ax, ay, az = iinv(e, -tq * ux, -tq * uy, -tq * uz)
      e.wx, e.wy, e.wz = e.wx + ax, e.wy + ay, e.wz + az
      e.Wr = e.Wr - tq * (ux * (o0x + e.wx) + uy * (o0y + e.wy) + uz * (o0z + e.wz)) / 2
    end
  end
  e.b:setLinearVelocity(btVector3(e.vx, e.vy, e.vz))
  e.b:setAngularVelocity(btVector3(e.wx, e.wy, e.wz))
end

-- ---------------------------------------------------------------------
-- setting them rolling, and watching them
-- ---------------------------------------------------------------------
local t = 0
local function energy(e)
  local Lx, Ly, Lz = imul(e, e.wx, e.wy, e.wz)
  return 0.5 * (Lx * e.wx + Ly * e.wy + Lz * e.wz) + 0.5 * e.mass * (e.vx * e.vx + e.vy * e.vy + e.vz * e.vz)
         + e.mass * G * e.gy
end
-- the centre's height above the board
local function heightOf(e) return (e.gx - BX0) * NX + (e.gy - BY0) * NY end

local function quatFromBasis(xx, xy, xz, yx, yy, yz, zx, zy, zz)
  local tr = xx + yy + zz
  local w, x, y, z
  if tr > 0 then
    local s = math.sqrt(tr + 1) * 2
    w, x, y, z = 0.25 * s, (yz - zy) / s, (zx - xz) / s, (xy - yx) / s
  elseif xx > yy and xx > zz then
    local s = math.sqrt(1 + xx - yy - zz) * 2
    w, x, y, z = (yz - zy) / s, 0.25 * s, (yx + xy) / s, (zx + xz) / s
  elseif yy > zz then
    local s = math.sqrt(1 + yy - xx - zz) * 2
    w, x, y, z = (zx - xz) / s, (yx + xy) / s, 0.25 * s, (zy + yz) / s
  else
    local s = math.sqrt(1 + zz - xx - yy) * 2
    w, x, y, z = (xy - yx) / s, (zx + xz) / s, (zy + yz) / s, 0.25 * s
  end
  return btQuaternion(x, y, z, w)
end

-- lay it on the board along a line, near the start
local function layDown(r)
  -- a direction "down" in its own frame with both arcs touching, as near
  -- as can be to straight across its axle
  local best, bd
  for k = 0, 359 do
    local ph = 2 * math.pi * k / 360
    local d1, d2, d3 = 0, math.cos(ph), math.sin(ph)
    local _, _, _, h1 = arcSupport(r.arcs[1], d1, d2, d3)
    local _, _, _, h2 = arcSupport(r.arcs[2], d1, d2, d3)
    local diff = math.abs(h1 - h2)
    if not best or diff < best then best, bd = diff, { d1, d2, d3, math.max(h1, h2) } end
  end
  -- its frame in the world: own "down" onto -n, its own x (the line of
  -- the circles' centres; the sphericon's axis) across the slope, turned
  -- by YAW about the board's normal so that on average it rolls straight
  -- down the board
  local dx, dy, dz = bd[1], bd[2], bd[3]
  local ex, ey, ez = 1 - dx * dx, -dx * dy, -dx * dz          -- x less its part along down
  local el = math.sqrt(ex * ex + ey * ey + ez * ez)
  ex, ey, ez = ex / el, ey / el, ez / el
  local fx, fy, fz = dy * ez - dz * ey, dz * ex - dx * ez, dx * ey - dy * ex
  -- world: down -> (-NX, -NY, 0), e -> (0, 0, 1), f -> down x e
  local Dw = { -NX, -NY, 0 }
  local yaw = math.rad(r.yaw + envnum("OL_YAW", 0))
  local Ew = { math.sin(yaw) * math.cos(SLOPE), -math.sin(yaw) * math.sin(SLOPE), math.cos(yaw) }
  local Fw = { Dw[2] * Ew[3] - Dw[3] * Ew[2], Dw[3] * Ew[1] - Dw[1] * Ew[3], Dw[1] * Ew[2] - Dw[2] * Ew[1] }
  -- rotation M = Dw dᵀ + Ew eᵀ + Fw fᵀ; its columns are where the own axes go
  local function col(i)
    local b = { { dx, dy, dz }, { ex, ey, ez }, { fx, fy, fz } }
    return Dw[1] * b[1][i] + Ew[1] * b[2][i] + Fw[1] * b[3][i],
           Dw[2] * b[1][i] + Ew[2] * b[2][i] + Fw[2] * b[3][i],
           Dw[3] * b[1][i] + Ew[3] * b[2][i] + Fw[3] * b[3][i]
  end
  local x1, x2, x3 = col(1)
  local y1, y2, y3 = col(2)
  local z1, z2, z3 = col(3)
  local q = quatFromBasis(x1, x2, x3, y1, y2, y3, z1, z2, z3)
  local h0 = bd[4] + 0.0005
  local px = BX0 + 14
  local tr = btTransform(q, btVector3(px + NX * h0, boardY(px) + NY * h0, r.z))
  r.b:setCenterOfMassTransform(tr)
  r.m.trans = tr
  -- a push: rolling about the line it lies on, its centre moving PUSH cm/s
  -- down the board
  load(r)
  local ax, ay, az = worldSupport(r, r.arcs[1], -NX, -NY, 0)
  local bx, by, bz = worldSupport(r, r.arcs[2], -NX, -NY, 0)
  local lx, ly, lz = bx - ax, by - ay, bz - az
  local ll = math.sqrt(lx * lx + ly * ly + lz * lz)
  lx, ly, lz = lx / ll, ly / ll, lz / ll
  local rx, ry, rz = -ax, -ay, -az                       -- from the contact to the centre
  local vx, vy, vz = ly * rz - lz * ry, lz * rx - lx * rz, lx * ry - ly * rx
  local down = vx * math.cos(SLOPE) - vy * math.sin(SLOPE)
  local w = PUSH / (math.abs(down) > 0.3 * math.sqrt(vx * vx + vy * vy + vz * vz) and down or math.sqrt(vx * vx + vy * vy + vz * vz))
  r.b:setAngularVelocity(btVector3(w * lx, w * ly, w * lz))
  r.b:setLinearVelocity(btVector3(w * vx, w * vy, w * vz))
end

local function setRolling()
  holdStart()
  t = 0
  print(string.format("\n--- pushed off along the board at %.0f cm/s%s ---", PUSH,
                      SLOPE > 0 and string.format(" (tilted %.1f degrees)", math.deg(SLOPE)) or ""))
  for _, r in ipairs(ROLLERS) do
    layDown(r)
    load(r)
    r.E0, r.Wf, r.Wr = energy(r), 0, 0
    r.KE0 = r.E0 - r.mass * G * r.gy
    r.hmin, r.hmax, r.zmin, r.zmax = 1e9, -1e9, 1e9, -1e9
    r.x0, r.y0 = r.gx, r.gy
    r.still, r.reported, r.stopped = 0, false, false
    for _, d in ipairs(r.dots) do d.trans = HIDDEN end
    for _, d in ipairs(r.track) do d.trans = HIDDEN end
    r.ndots = 0
    if r.hhi - r.hlo < 1e-4 then
      print(string.format("  %-9s %.1f g; lying along a line on the board, its centre is always %.4f cm up (theory%s)", r.short,
                          r.mass * 1000, (r.hlo + r.hhi) / 2,
                          r.kind == "sphericon" and string.format(": R/sqrt 2 = %.4f", AR / math.sqrt(2)) or ""))
    else
      print(string.format("  %-9s %.1f g; lying along a line on the board, its centre is between %.4f and %.4f cm up (theory)",
                          r.short, r.mass * 1000, r.hlo, r.hhi))
    end
  end
end

local LOGF = os.getenv("OL_LOG") and io.open(os.getenv("OL_LOG"), "w")
if LOGF then LOGF:write("t,roller,x,y,z,height,energy\n") end
local restAll = 0
v:postSim(function(N_)
  if holdNow then return end
  t = t + FRAME_DT
  local allStill = true
  for k, r in ipairs(ROLLERS) do
    load(r)
    copyTrans(r.edges, r.m)
    local h = heightOf(r)
    -- the pen: a dotted stem from the centre up to its tip, which draws the
    -- height straight above the roller's lane (its own side-to-side
    -- weaving left out); the weaving is drawn on the board, under it
    local py = penY(r.gx, h)
    for i = 1, STEM_N do
      local f = i / STEM_N
      r.stem[i].trans = btTransform(Q0, btVector3(r.gx, r.gy + (py - r.gy) * f, r.gz + (r.z - r.gz) * f))
    end
    if not r.stopped and N_ % 2 == 0 and r.ndots < PEN_N then
      r.ndots = r.ndots + 1
      r.dots[r.ndots].trans = btTransform(Q0, btVector3(r.gx, py, r.z))
      r.track[r.ndots].trans = btTransform(Q0, btVector3(r.gx, boardY(r.gx) + 0.1, r.gz))
    end
    if not r.stopped then
      r.hmin, r.hmax = math.min(r.hmin, h), math.max(r.hmax, h)
      r.zmin, r.zmax = math.min(r.zmin, r.gz), math.max(r.zmax, r.gz)
      local E = energy(r)
      r.ke = E - r.mass * G * r.gy
      r.lostR = -r.Wr
      r.resid = r.E0 + r.Wr - E                    -- (what it lost besides rolling resistance)
    elseif not r.reported then
      r.reported = true
      print(string.format("  %-9s reaches the far end at %.2f s, %.1f cm along the board, weaving %.1f cm side to side:" ..
                          "\n            its centre %.4f to %.4f cm up (theory: %.4f to %.4f);" ..
                          "\n            energy: of what the push gave it, %.1f%% went to rolling resistance, and %.3f%% otherwise" ..
                          " (rolling without slipping, it should lose none)",
                          r.short, t, (r.gx - r.x0) / math.cos(SLOPE), r.zmax - r.zmin, r.hmin, r.hmax, r.hlo, r.hhi,
                          r.lostR / r.KE0 * 100, r.resid / r.KE0 * 100))
    end
    local sp = math.sqrt(r.vx * r.vx + r.vy * r.vy + r.vz * r.vz)
    if sp < 0.3 then r.still = r.still + FRAME_DT else r.still = 0 end
    if r.still < 1 then allStill = false end
    if LOGF and N_ % 2 == 0 then
      LOGF:write(string.format("%.4f,%d,%.3f,%.3f,%.3f,%.5f,%.4f\n", t, k, r.gx, r.gy, r.gz, h, energy(r)))
    end
  end
  local allThere = true
  for _, r in ipairs(ROLLERS) do if not r.reported then allThere = false end end
  restAll = (allStill or allThere) and restAll + FRAME_DT or 0
  if restAll > 3 or t > 40 then setRolling() end
end)

v:preSim(function(N_)
  if holdPre() then return end
  for k = 1, NSTEPS - 1 do
    for _, r in ipairs(ROLLERS) do step(r, STEP) end
    v:stepSimulation(STEP, 0, STEP)
  end
  for _, r in ipairs(ROLLERS) do step(r, STEP) end
end)

-- ---------------------------------------------------------------------
-- keys, help
-- ---------------------------------------------------------------------
common.setCamera(btVector3(-30, 70, 120), btVector3(0, 8, 0))
v:addShortcut("R", function(N_) setRolling() end)
v:addShortcut("Z", function(N_)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N_, name, value)
  if name == "speed" or name == "steps" then applyTiming() end
end)
v:setHelpText(table.concat({
  "The oloid and the sphericon (Euler's Cabinet of Curiosities)",
  "",
  "Three rollers, each the hull of two circular arcs, pushed",
  "along a board, lay their whole surface on it as they roll.",
  "All three weave from side to side as they go (4 to 6 cm).",
  "What tells them apart is their centre's height:",
  "",
  "Back:   the oloid -- its centre rises and falls a little",
  "Middle: the two-circle roller -- its centre stays level",
  "Front:  the sphericon -- its centre stays level",
  "",
  "Above each, a pen on a dotted stem draws its centre's height,",
  "20 times over: the oloid's red line waves between its two",
  "rods (its theory's lowest and highest); the blue and green",
  "lie flat on theirs. On the board, dots mark each one's path:",
  "how it weaves from side to side.",
  "",
  "R   push them off again",
  "Z   slow motion (1/4) <-> real time",
  "Rest the mouse on a roller to see its centre's height.",
}, "\n"))
if v.onHover then
  v:onHover(function(N_, obj, x, y, z)
    local r = KEYS[objectKey(obj)]
    if not r then return nil end
    return string.format("%s\nits centre %.3f cm above the board (theory: %.3f to %.3f)", r.name, heightOf(r), r.hlo, r.hhi)
  end)
end

setRolling()
