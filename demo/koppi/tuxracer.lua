--
-- tuxracer.lua - a small Tux Racer for BPP
--
-- Tux belly-slides down a snowy mountain course: collect herring, dodge the
-- trees, hit the kickers, reach the finish line as fast as you can.
-- (An homage rather than a line-for-line port: Tux Racer's course is a
-- terrain bitmap plus an object map; here it is a height function turned into
-- a static triangle mesh, with the trees and fish placed from a fixed seed.)
--
--   Left / Right   turn            Up     paddle (a little speed)
--   Down           brake           Space  jump (when on the snow)
--   R              restart (reloads the script)
--
-- Run headless with TUX_AUTO=1 in the environment to let an autopilot drive
-- (smoke test: ./release/bpp -f demo/koppi/tuxracer.lua -n 1500).
--

local color  = require "color"
local common = require "common"

local sin, cos, sqrt, abs, floor, pi =
  math.sin, math.cos, math.sqrt, math.abs, math.floor, math.pi
local function clamp(x, lo, hi) return x < lo and lo or (x > hi and hi or x) end

-- ---------------------------------------------------------------------------
-- Course
-- ---------------------------------------------------------------------------

local SLOPE   = math.tan(math.rad(21))   -- drop per metre of run
local LENGTH  = 760                      -- run from z = 0 to the finish line
local HALF_W  = 60                       -- the mesh spans path +- HALF_W
local STEP    = 2                        -- mesh grid spacing (m)
local KICKERS = { 150, 330, 520 }        -- z where a jump starts

-- Where the middle of the run is at distance z.
local function pathX(z)
  return 14 * sin(z / 55) + 8 * sin(z / 23 + 1)
end

-- Snow height at (x, z): the slope, bumps, banked sides, and the kickers.
local function H(x, z)
  local d = x - pathX(z)
  local u = z - LENGTH                       -- past the finish line the slope eases out flat
  local h = -SLOPE * ((u > 0) and (LENGTH + u - u * u / 80) or z)
  if u > 40 then h = -SLOPE * (LENGTH + 20) end
  h = h + 0.30 * sin(x * 0.23 + z * 0.11) * sin(z * 0.29 + 0.7)
  h = h + 0.012 * d * d
  for _, z0 in ipairs(KICKERS) do
    local u = z - z0
    if u > 0 and u < 18 then                  -- curved ramp up ...
      h = h + 2.6 * (u / 18) ^ 2
    elseif u >= 18 and u < 22 then            -- ... and a short drop behind it
      h = h + 2.6 * (22 - u) / 4
    end
  end
  return h
end

local function normalAt(x, z)
  local e = 0.5
  local gx = (H(x + e, z) - H(x - e, z)) / (2 * e)
  local gz = (H(x, z + e) - H(x, z - e)) / (2 * e)
  local l = sqrt(gx * gx + 1 + gz * gz)
  return -gx / l, 1 / l, -gz / l
end

-- Write the heightfield out as a Wavefront .obj and load it as a static Mesh.
local function buildCourse()
  local nz = floor((LENGTH + 90) / STEP)
  local nx = floor(2 * HALF_W / STEP)
  local path = os.tmpname() .. ".obj"
  local f = assert(io.open(path, "w"))
  local zmin = -30
  for j = 0, nz do
    local z = zmin + j * STEP
    local cx = pathX(z)
    for i = 0, nx do
      local x = cx - HALF_W + i * STEP
      f:write(string.format("v %.3f %.3f %.3f\n", x, H(x, z), z))
    end
  end
  local function id(i, j) return j * (nx + 1) + i + 1 end
  for j = 0, nz - 1 do
    for i = 0, nx - 1 do
      -- wound to face up (+Y)
      f:write(string.format("f %d %d %d\n", id(i, j), id(i, j + 1), id(i + 1, j)))
      f:write(string.format("f %d %d %d\n", id(i + 1, j), id(i, j + 1), id(i + 1, j + 1)))
    end
  end
  f:close()
  local m = Mesh(path, 0, false)
  os.remove(path)
  return m
end

common.setTiming(1 / 60, 4, 1 / 120)
common.gravity(-9.81)

local course = buildCourse()
course.col = color.white
course.friction = 0.07
course.body:setFriction(0.07)
course.restitution = 0
v:add(course)

-- ---------------------------------------------------------------------------
-- Trees and herring (deterministic scatter)
-- ---------------------------------------------------------------------------

local seed = 20260610
local function rnd()                              -- small LCG, same on every run
  seed = (seed * 1103515245 + 12345) % 2147483648
  return seed / 2147483648
end

local UP_TO_Y = btQuaternion(btVector3(1, 0, 0), -pi / 2)   -- local +Z -> world +Y

local trees = {}
local function addTree(x, z, s)
  local y = H(x, z)
  local trunk = Cylinder(0.35 * s, 2 * s, 0)
  trunk.col = color.saddlebrown
  trunk.trans = btTransform(UP_TO_Y, btVector3(x, y + 1 * s, z))
  v:add(trunk)
  for k = 0, 2 do
    local cone = Cone((2.2 - 0.55 * k) * s, 3.2 * s, 0)
    cone.col = color.forestgreen
    cone.trans = btTransform(UP_TO_Y, btVector3(x, y + (3.0 + 1.8 * k) * s, z))
    v:add(cone)
  end
  trees[#trees + 1] = { x = x, z = z }
end

for z = 20, LENGTH + 20, 4 do
  for _ = 1, 2 do
    local side = rnd() < 0.5 and -1 or 1
    local off = 10 + rnd() * rnd() * 40          -- denser near the run
    if rnd() < 0.3 then off = 7 + rnd() * 9 end
    local x = pathX(z) + side * off
    local s = 0.8 + rnd() * 0.9
    local near = false
    for _, k in ipairs(KICKERS) do if z > k - 6 and z < k + 30 then near = true end end
    if not near then addTree(x, z + rnd() * 3, s) end
  end
end

-- the start gate and the finish line
local function banner(z, c)
  for _, sx in ipairs({ -1, 1 }) do
    local x = pathX(z) + sx * 11
    local post = Cylinder(0.25, 6, 0)
    post.col = c
    post.trans = btTransform(UP_TO_Y, btVector3(x, H(x, z) + 3, z))
    v:add(post)
  end
  local bar = Cube(22, 0.6, 0.4, 0)
  bar.col = c
  bar.trans = btTransform(btQuaternion(), btVector3(pathX(z), H(pathX(z), z) + 6, z))
  v:add(bar)
end
banner(0, color.red)
banner(LENGTH, color.black)

-- Rotate the vector (x, y, z) by the quaternion q (pure numbers, no bindings).
local function rot(q, x, y, z)
  local qx, qy, qz, qw = q:getX(), q:getY(), q:getZ(), q:getW()
  local tx = 2 * (qy * z - qz * y)
  local ty = 2 * (qz * x - qx * z)
  local tz = 2 * (qx * y - qy * x)
  return x + qw * tx + (qy * tz - qz * ty),
         y + qw * ty + (qz * tx - qx * tz),
         z + qw * tz + (qx * ty - qy * tx)
end

-- A static Mesh ellipsoid with semi-axes (a, b, c), written out as an .obj
-- (the pole vertices are single points, so there are no degenerate triangles).
-- One .obj per distinct shape: later Meshes of the same shape reuse it, and
-- the files are deleted once the scene is built (see cleanupMeshFiles).
local objFiles = {}
local function ellipsoidFile(a, b, c, nlon, nlat)
  local key = string.format("%g,%g,%g,%d,%d", a, b, c, nlon, nlat)
  if objFiles[key] then return objFiles[key] end
  local path = os.tmpname() .. ".obj"
  local f = assert(io.open(path, "w"))
  f:write(string.format("v 0 %.4f 0\nv 0 %.4f 0\n", -b, b))      -- 1: south, 2: north
  for j = 1, nlat - 1 do
    local la = -pi / 2 + pi * j / nlat
    for i = 0, nlon - 1 do
      local lo = 2 * pi * i / nlon
      f:write(string.format("v %.4f %.4f %.4f\n",
        a * cos(la) * cos(lo), b * sin(la), c * cos(la) * sin(lo)))
    end
  end
  local function id(i, j) return 2 + (j - 1) * nlon + (i % nlon) + 1 end
  for i = 0, nlon - 1 do
    f:write(string.format("f 1 %d %d\n", id(i + 1, 1), id(i, 1)))
    f:write(string.format("f 2 %d %d\n", id(i, nlat - 1), id(i + 1, nlat - 1)))
  end
  for j = 1, nlat - 2 do
    for i = 0, nlon - 1 do
      f:write(string.format("f %d %d %d\n", id(i, j), id(i + 1, j), id(i + 1, j + 1)))
      f:write(string.format("f %d %d %d\n", id(i, j), id(i + 1, j + 1), id(i, j + 1)))
    end
  end
  f:close()
  objFiles[key] = path
  return path
end

local function ellipsoid(a, b, c, col, nlon, nlat)
  local m = Mesh(ellipsoidFile(a, b, c, nlon or 28, nlat or 16), 0, false)
  m.col = col
  m.body:setCollisionFlags(m.body:getCollisionFlags() + 4)      -- visual only
  v:add(m)
  return m
end

local function axq(x, y, z, ang) return btQuaternion(btVector3(x, y, z), ang) end

-- A herring: silver body, blue-green back, forked tail, dorsal fin and eyes.
-- Parts are listed in the fish's own frame (x right, y up, z = nose).
local FISH = {
  { 0.12, 0.16, 0.66, color.lightsteelblue,  0,  0.00,  0.00 },             -- body
  { 0.095, 0.08, 0.62, color.teal,           0,  0.09, -0.03 },             -- back
  { 0.02, 0.27, 0.16, color.steelblue,       0,  0.15, -0.88, -0.45 },      -- tail, upper fork
  { 0.02, 0.27, 0.16, color.steelblue,       0, -0.15, -0.88,  0.45 },      -- tail, lower fork
  { 0.015, 0.11, 0.16, color.steelblue,      0,  0.22, -0.08, -0.30 },      -- dorsal fin
  { 0.045, 0.045, 0.045, color.black,       -0.10, 0.05, 0.52 },            -- eyes
  { 0.045, 0.045, 0.045, color.black,        0.10, 0.05, 0.52 },
}

local herring = {}
local function addHerring(x, z)
  local h = { x = x, z = z, alive = true, y = H(x, z) + 0.9, parts = {} }
  for _, f in ipairs(FISH) do
    local m = ellipsoid(f[1], f[2], f[3], f[4], 12, 8)
    h.parts[#h.parts + 1] = { o = m, off = { f[5], f[6], f[7] }, q = axq(1, 0, 0, f[8] or 0) }
  end
  herring[#herring + 1] = h
end

local function hideHerring(h)
  for _, pt in ipairs(h.parts) do
    pt.o.trans = btTransform(btQuaternion(), btVector3(h.x, h.y - 500, h.z))
  end
end

-- (the fish turn on the spot, bob a little, and swing their tails)
local function placeHerring(h, t)
  local q = axq(0, 1, 0, t * 2 + h.x) * axq(1, 0, 0, -0.2)
  local y = h.y + 0.12 * sin(t * 3 + h.z)
  for i, pt in ipairs(h.parts) do
    local dx, dy, dz = rot(q, pt.off[1], pt.off[2], pt.off[3])
    local lq = pt.q
    if i == 3 or i == 4 then lq = lq * axq(0, 1, 0, 0.25 * sin(t * 8 + h.z)) end   -- tail wag
    pt.o.trans = btTransform(q * lq, btVector3(h.x + dx, y + dy, h.z + dz))
  end
end

for z = 25, LENGTH - 20, 11 do
  local x = pathX(z) + (rnd() - 0.5) * 16
  addHerring(x, z)
end
for _, k in ipairs(KICKERS) do                    -- a bonus fish in the air
  local z = k + 21
  addHerring(pathX(z), z)
  herring[#herring].y = H(pathX(z), z) + 3.2
end
for _, h in ipairs(herring) do placeHerring(h, 0) end

-- ---------------------------------------------------------------------------
-- Tux
-- ---------------------------------------------------------------------------

-- The physics body is a small box; the egg-shaped Tux below is drawn around it
-- (the box sits wholly inside the body; the body's rounded underside dips a
-- few cm into the snow).
local tux = Cube(0.44, 0.24, 0.8, 12)
tux.col = color.black
tux.friction = 1.0
tux.body:setFriction(1.0)
tux.restitution = 0
tux.damp_lin = 0.02
tux.damp_ang = 0.6
tux.pos = btVector3(pathX(2), H(pathX(2), 2) + 1.0, 2)
v:add(tux)
tux.body:forceActivationState(4)               -- never fall asleep
tux.body:setCcdMotionThreshold(0.3)
tux.body:setCcdSweptSphereRadius(0.25)

local keys = {}

-- Visual-only parts, glued to the torso in its local frame (x right, y up,
-- z forward). A part is either fixed (off, q) or animated (fn() -> off, q).
local parts = {}
local function part(obj, lx, ly, lz, rq)
  parts[#parts + 1] = { o = obj, off = { lx, ly, lz }, q = rq or btQuaternion() }
end

local YELLOW = color.orange
part(ellipsoid(0.52, 0.40, 0.92, color.black, 36, 20), 0, 0.20, -0.02)    -- body
part(ellipsoid(0.46, 0.34, 0.82, color.white, 36, 20), 0, 0.14, 0.10)    -- belly (shows low at the sides)
part(ellipsoid(0.33, 0.30, 0.34, color.black, 32, 18), 0, 0.52, 0.74)    -- head
part(ellipsoid(0.17, 0.20, 0.07, color.white),  -0.14, 0.60, 0.99, axq(0, 1, 0,  0.35))   -- eyes
part(ellipsoid(0.17, 0.20, 0.07, color.white),   0.14, 0.60, 0.99, axq(0, 1, 0, -0.35))
part(ellipsoid(0.055, 0.075, 0.04, color.black), -0.12, 0.60, 1.04)  -- pupils
part(ellipsoid(0.055, 0.075, 0.04, color.black),  0.12, 0.60, 1.04)
part(ellipsoid(0.16, 0.05, 0.26, YELLOW),        0,  0.50,  1.06)    -- upper beak
part(ellipsoid(0.13, 0.035, 0.20, YELLOW),       0,  0.42,  1.03)    -- lower beak
part(ellipsoid(0.15, 0.04, 0.27, YELLOW),       -0.27, 0.02, -0.84, axq(0, 1, 0,  0.35))  -- feet
part(ellipsoid(0.15, 0.04, 0.27, YELLOW),        0.27, 0.02, -0.84, axq(0, 1, 0, -0.35))
part(ellipsoid(0.07, 0.07, 0.17, color.black),   0,  0.18, -0.92)    -- tail

-- Flippers swing: they sweep back and dip on the inside of a turn, and flap
-- when paddling. s = -1 for the left flipper (-x), +1 for the right.
local flapT = 0
local function flipper(s)
  local m = ellipsoid(0.34, 0.045, 0.14, color.black)
  parts[#parts + 1] = { o = m, fn = function()
    local turn = (keys.analog or ((keys.Left and 1 or 0) - (keys.Right and 1 or 0)))
    local flap = keys.Up and 0.35 * sin(flapT * 9) or 0
    local sweep = 0.55 + 0.3 * abs(turn) + flap
    local droop = 0.30 - 0.30 * turn * s + 0.2 * flap
    local q = axq(0, 1, 0, s * sweep) * axq(0, 0, 1, -s * droop)
    -- (centre = shoulder + half the flipper length along its own x axis)
    local ox, oy, oz = rot(q, s * 0.30, 0, 0)
    return { s * 0.46 + ox, 0.24 + oy, 0.18 + oz }, q
  end }
end

flipper(-1)
flipper(1)

local function syncParts(t)
  local q, p = tux.trans:getRotation(), tux.pos
  flapT = flapT + v.timeStep
  for _, pt in ipairs(parts) do
    local off, lq = pt.off, pt.q
    if pt.fn then off, lq = pt.fn() end
    local dx, dy, dz = rot(q, off[1], off[2], off[3])
    pt.o.trans = btTransform(q * lq, btVector3(p.x + dx, p.y + dy, p.z + dz))
  end
end

-- ---------------------------------------------------------------------------
-- Game state and controls
-- ---------------------------------------------------------------------------

local st     = { t = 0, fish = 0, over = false, landed = false, still = 0 }
local MAX_FISH = #herring

v:onKey(function(N, key, down)
  if key == "Left" or key == "Right" or key == "Up" or key == "Down" then
    keys[key] = down or nil
    return true
  elseif key == "Space" then
    if down then keys.jump = true end
    return true
  end
  return false
end)

local function status(N)
  local p, vel = tux.pos, tux.body:getLinearVelocity()
  local speed = sqrt(vel:length2()) * 3.6
  local txt
  if st.over then
    txt = string.format("FINISH!  time %.1f s   herring %d / %d   (R restarts)",
                        st.t, st.fish, MAX_FISH)
  else
    txt = string.format("time %5.1f s   speed %3.0f km/h   herring %d / %d   to go %3.0f m",
                        st.t, speed, st.fish, MAX_FISH, math.max(0, LENGTH - p.z))
  end
  v:setHelpText("Tux Racer\n" .. txt ..
    "\nLeft/Right turn   Up paddle   Down brake   Space jump   R restart")
end

local AUTO = os.getenv("TUX_AUTO") ~= nil
local function autopilot()
  keys = {}
  local p = tux.pos
  local fx, _, fz = rot(tux.trans:getRotation(), 0, 0, 1)
  local tx = pathX(p.z + 14)
  for _, h in ipairs(herring) do               -- prefer the next fish ahead
    if h.alive and h.z > p.z + 5 and h.z < p.z + 40 and abs(h.x - p.x) < 8 then
      tx = h.x; break
    end
  end
  for _, tr in ipairs(trees) do                 -- steer clear of trunks
    if tr.z > p.z - 1 and tr.z < p.z + 32 and abs(tr.x - p.x) < 4.5 then
      tx = tr.x + (p.x >= tr.x and 6 or -6); break
    end
  end
  local err = math.atan2(tx - p.x, 14) - math.atan2(fx, fz)
  keys.analog = clamp(err * 2.5, -1, 1)
end

local camPos, camLook

local function control(N)
  if AUTO then autopilot() end
  local p   = tux.pos
  local q   = tux.trans:getRotation()
  local body = tux.body
  local vel = body:getLinearVelocity()
  local m   = tux.mass

  local nx, ny, nz = normalAt(p.x, p.z)
  local gh = p.y - H(p.x, p.z)
  local onSnow = gh < 0.8
  st.landed = onSnow

  -- body axes in the world
  local fx, fy, fz = rot(q, 0, 0, 1)
  local ux, uy, uz = rot(q, 0, 1, 0)

  -- flat heading (forward projected into the snow plane)
  local fd = fx * nx + fy * ny + fz * nz
  local hx, hy, hz = fx - fd * nx, fy - fd * ny, fz - fd * nz
  local hl = sqrt(hx * hx + hy * hy + hz * hz)
  if hl < 1e-6 then hx, hy, hz, hl = 0, 0, 1, 1 end
  hx, hy, hz = hx / hl, hy / hl, hz / hl
  -- snow-plane lateral (right-hand) axis
  local rx, ry, rz = hy * nz - hz * ny, hz * nx - hx * nz, hx * ny - hy * nx

  local vx, vy, vz = vel:getX(), vel:getY(), vel:getZ()
  local vf = vx * hx + vy * hy + vz * hz
  local vl = vx * rx + vy * ry + vz * rz

  local turn = keys.analog or ((keys.Left and 1 or 0) - (keys.Right and 1 or 0))   -- +1 = left
  -- (z points downhill, so "left" is toward +x when facing +z.)

  if onSnow then
    -- edge grip: kill sideways slip, more so with the skis dug in
    local grip = 6 + 3 * abs(turn)
    body:applyCentralForce(btVector3(-rx * vl * m * grip, -ry * vl * m * grip, -rz * vl * m * grip))
    if keys.Up then
      local f = 90 * (vf < 14 and 1 or 0.3)
      body:applyCentralForce(btVector3(hx * f, hy * f, hz * f))
    end
    if keys.Down then
      local f = 2.5 * m * (1 + vf * 0.1)
      if vf > 0 then body:applyCentralForce(btVector3(-hx * f, -hy * f, -hz * f)) end
    end
    -- hold the body flat on the snow: pull its up axis onto the slope normal
    local cx, cy, cz = uy * nz - uz * ny, uz * nx - ux * nz, ux * ny - uy * nx
    local av = body:getAngularVelocity()
    local ax, ay, az = av:getX(), av:getY(), av:getZ()
    local k, c = 90, 14
    local avn = ax * nx + ay * ny + az * nz           -- spin about the normal is left alone
    body:applyTorque(btVector3(cx * k - (ax - avn * nx) * c,
                               cy * k - (ay - avn * ny) * c,
                               cz * k - (az - avn * nz) * c))
    -- steer: set the yaw rate about the snow normal; turn tighter when slower
    local want = turn * clamp(2.4 - vf * 0.04, 0.9, 2.4)
    local av2 = body:getAngularVelocity()
    local d = want - (av2:getX() * nx + av2:getY() * ny + av2:getZ() * nz)
    body:setAngularVelocity(btVector3(av2:getX() + nx * d, av2:getY() + ny * d, av2:getZ() + nz * d))
    if keys.jump then
      body:applyCentralImpulse(btVector3(nx * m * 4.2, ny * m * 4.2, nz * m * 4.2))
    end
  else
    -- in the air: lean the nose along the flight path, no steering
    local sp = sqrt(vx * vx + vy * vy + vz * vz)
    if sp > 2 then
      local dx, dy, dz = vx / sp, vy / sp, vz / sp
      local cx, cy, cz = fy * dz - fz * dy, fz * dx - fx * dz, fx * dy - fy * dx
      local av = body:getAngularVelocity()
      body:applyTorque(btVector3(cx * 25 - av:getX() * 6,
                                 cy * 25 - av:getY() * 6,
                                 cz * 25 - av:getZ() * 6))
    end
  end
  keys.jump = nil
end

local function collect()
  local p = tux.pos
  for _, h in ipairs(herring) do
    if h.alive then
      local dx, dy, dz = h.x - p.x, h.y - p.y, h.z - p.z
      if dx * dx + dy * dy + dz * dz < 2.2 * 2.2 then
        h.alive = false
        st.fish = st.fish + 1
        hideHerring(h)
      end
    end
  end
end

local function updateCamera()
  local p = tux.pos
  local vel = tux.body:getLinearVelocity()
  local vx, vz = vel:getX(), vel:getZ()
  local sp = sqrt(vx * vx + vz * vz)
  local dx, dz = 0, 1
  if sp > 1.5 then dx, dz = vx / sp, vz / sp end
  local wantPos  = btVector3(p.x - dx * 9, p.y + 4.2, p.z - dz * 9)
  local wantLook = btVector3(p.x + dx * 8, p.y - 0.5, p.z + dz * 8)
  if not camPos then
    camPos, camLook = wantPos, wantLook
  else
    camPos  = camPos  + (wantPos  - camPos)  * 0.12
    camLook = camLook + (wantLook - camLook) * 0.2
  end
  v.cam.pos  = camPos
  v.cam.look = camLook
end

for _, path in pairs(objFiles) do os.remove(path) end   -- (all the meshes are loaded)

common.setCamera(btVector3(pathX(2), H(pathX(2), -8) + 5, -8),
                 btVector3(pathX(2), H(pathX(2), 12), 12), 1.0,
                 { horizontal = true })

v:preSim(function(N)
  if not st.over then
    st.t = st.t + v.timeStep
    control(N)
  end
end)

v:postSim(function(N)
  local p = tux.pos
  syncParts(N)
  if not st.over then
    collect()
    if p.z >= LENGTH then
      st.over = true
      tux.body:setDamping(0.9, 0.9)            -- coast to a stop on the runout
    end
    -- fell off the world, or wedged against a tree for two seconds: put Tux
    -- back on the path (a stuck Tux costs 3 s)
    local vel = tux.body:getLinearVelocity()
    st.still = (vel:length2() < 1 and st.t > 1) and st.still + 1 or 0
    if p.y < H(p.x, p.z) - 5 or st.still > 120 then
      local z = p.z + 2
      tux.trans = btTransform(common.quat(0, 0, 0), btVector3(pathX(z), H(pathX(z), z) + 1, z))
      tux.body:setLinearVelocity(btVector3(0, 0, 0))
      tux.body:setAngularVelocity(btVector3(0, 0, 0))
      st.still = 0
      st.t = st.t + 3
    end
  end
  if N % 6 == 0 then
    for _, h in ipairs(herring) do if h.alive then placeHerring(h, N / 60) end end
  end
  updateCamera()
  if N % 6 == 0 then status(N) end
  if os.getenv("TUX_LOG") and N % 60 == 0 then
    local vel = tux.body:getLinearVelocity()
    printf("N=%d t=%.1f pos=(%.1f %.1f %.1f) speed=%.1f m/s fish=%d snow=%s over=%s",
           N, st.t, p.x, p.y, p.z, sqrt(vel:length2()), st.fish,
           tostring(st.landed), tostring(st.over))
  end
end)

status(0)
