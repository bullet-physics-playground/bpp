--
-- The Dzhanibekov Effect -- Euler's Cabinet of Curiosities
--
-- In 1985 cosmonaut Vladimir Dzhanibekov, on Salyut 7, unscrewed a wing nut
-- that span off on its own -- and every few seconds flipped over, end for
-- end, then flipped back, again and again. It is the "tennis racket
-- theorem": a body with three different moments of inertia spins steadily
-- about the axes of its largest and its smallest moment, but not about the
-- middle one. Spun about that one, the slightest wobble grows until the
-- body turns over, and the motion repeats for ever.
--
-- Three identical aluminium T-handles, shaped like a wing nut (a 10 cm bar
-- and a short, thick 4 cm stem), float without gravity in glass boxes, each
-- spun about a different one of its axes, each with the same small extra
-- wobble ("nudge"):
--   left   (blue)   about the stem       -- middle moment:   flips over and
--                                           back, again and again, like
--                                           Dzhanibekov's wing nut
--   middle (red)    about the bar        -- smallest moment: steady
--   right  (green)  across both          -- largest moment:  steady
-- The shape matters: which axis is the middle one depends on proportions.
-- With a long stem (7 cm) the stem becomes the smallest moment and spin
-- about it is steady, while spin about the bar flips instead.
-- The console reports every flip and its period, and checks once in a
-- while that energy and angular momentum are conserved.
--
-- PHYSICS NOTE: Bullet's own handling of free rotation is not good enough
-- here. Tested against the exact solution of Euler's equations (inertia
-- 1:2:3, one minute): with its gyroscopic term off, nothing flips; with its
-- "explicit" term the spin gains energy (+59%); with its default
-- ("implicit") term the flips are on time but the spin drains away (energy
-- -44%, angular momentum -25%; still -3% a minute at 16x the steps). So the
-- gyroscopic term is switched off (setFlags(0)) and this script advances
-- each handle's spin by Euler's equations itself, with RK4, before every
-- physics step, holding kinetic energy and angular momentum exactly. That matched the exact
-- flip period to 0.2%, with energy and angular momentum exact. (This build
-- of Bullet uses single-precision numbers, so with a vanishingly small
-- nudge rounding noise starts the wobble a little sooner -- as any tiny
-- imperfection would in a real one.)
--
-- Keys
--   R   start all three again (with the current spin and nudge)
--   Z   slow motion (1/4) <-> real time
--
-- Sliders: spin (turns per second), nudge (% of the spin), speed, steps.
--
-- Units: centimetres, kilograms, seconds.
--
-- Headless testing: bpp -f demo/dzhanibekov/dzhanibekov.lua -n FRAMES with
-- DZ_SPIN, DZ_NUDGE, DZ_STEPS, DZ_LOG=file.csv.
--

local common = require "common"

local DIR = "dzhanibekov-meshes/"
local function loadData()
  for _, dir in ipairs({ DIR, "demo/dzhanibekov/" .. DIR }) do
    local ok, data = pcall(dofile, dir .. "t-handle-data.lua")
    if ok and data then DIR = dir; return data end
  end
  error("t-handle-data.lua not found")
end
local H = loadData()
local MASS = H.mass
local IV = H.inertia                         -- kg cm^2 about body x, y, z
local INERTIA = btVector3(IV[1], IV[2], IV[3])

-- ---------------------------------------------------------------------
-- sliders and timing
-- ---------------------------------------------------------------------
local function envnum(name, default) return tonumber(os.getenv(name) or "") or default end
local function param(...) v:addParam(...) end
param("spin", envnum("DZ_SPIN", 1.0), 0.2, 3.0, 0.1, "turns per second")
param("nudge", envnum("DZ_NUDGE", 1.0), 0.1, 10, 0.1, "extra wobble, % of the spin")
param("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
param("steps", envnum("DZ_STEPS", 600), 120, 2400, 60, "physics steps per simulated second")

local STEP, NSTEPS, FRAME_DT = 1 / 600, 10, 1 / 60
local function applyTiming()
  local speed = v:getParam("speed")
  NSTEPS = math.max(1, math.floor(v:getParam("steps") * speed / 60 + 0.5))
  FRAME_DT = speed / 60
  STEP = FRAME_DT / NSTEPS
  v.animationPeriod = 16
  common.setTiming(STEP, 0, STEP)
end
applyTiming()

v.gravity = btVector3(0, 0, 0)               -- (the boxes and pedestals are fixed)

-- ---------------------------------------------------------------------
-- the gallery: three glass boxes on pedestals
-- ---------------------------------------------------------------------
local SPACING, BOX, PED_H = 32, 22, 70
local floor = Plane(0, 1, 0, 0, 300)
floor.col = "#3b3f45"
v:add(floor)

local function block(sx, sy, sz, x, y, z, col, alpha)
  local c = Cube(sx, sy, sz, 0)
  c.pos = btVector3(x, y, z)
  c.col = col
  c.collides = false
  if alpha then c.transparency = alpha end
  v:add(c)
  return c
end

local HANDLES = {
  { name = "Left (blue), spun about the stem -- flips",      short = "Left",   axis = 2, col = "#4363d8" },
  { name = "Middle (red), spun about the bar -- steady",     short = "Middle", axis = 1, col = "#e6194b" },
  { name = "Right (green), spun across both -- steady",      short = "Right",  axis = 3, col = "#3cb44b" },
}

for k, h in ipairs(HANDLES) do
  local x = (k - 2) * SPACING
  h.centre = btVector3(x, PED_H + BOX / 2 + 1, 0)
  block(BOX - 4, PED_H, BOX - 4, x, PED_H / 2, 0, "#6b4a2e")                 -- pedestal
  block(BOX, 1, BOX, x, PED_H + 0.5, 0, "#2b2b2b")                           -- base plate
  block(BOX, BOX, BOX, x, PED_H + 1 + BOX / 2, 0, "#bfe6ff", 0.85)           -- the glass box
end

common.setCamera(btVector3(0, PED_H + 28, 85), btVector3(0, PED_H + 10, 0))

-- ---------------------------------------------------------------------
-- the handles
-- ---------------------------------------------------------------------
-- Collision shape: the handle's own outline (convex hull of its mesh). The
-- handles touch nothing -- no gravity, and the glass boxes don't collide --
-- so it changes nothing physically; it is what the mouse hover finds.
local OUTLINE = btConvexHullShape()
do
  local pts = {}
  for line in io.lines(DIR .. "t-handle.obj") do
    local x, y, z = line:match("^v%s+(%S+)%s+(%S+)%s+(%S+)")
    if x then pts[#pts + 1] = btVector3(tonumber(x), tonumber(y), tonumber(z)) end
  end
  for k, p in ipairs(pts) do OUTLINE:addPoint(p, k == #pts) end
  OUTLINE:setMargin(0.02)
end

for _, h in ipairs(HANDLES) do
  local m = Mesh(DIR .. "t-handle.obj", 0, false)
  local body = btRigidBody(MASS, btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1), h.centre)),
                           OUTLINE, INERTIA)
  m.body = body
  m.col = h.col
  body:setActivationState(4)
  body:setDamping(0, 0)
  body:setFlags(0)                           -- Bullet's gyroscopic term off: Euler's equations below
  v:add(m)
  h.m, h.body = m, body
end

-- body axis c (1..3) as a world vector, and a body vector to world
local function basis(b)
  local B = b:getCenterOfMassTransform():getBasis()
  return { B:getColumn(0), B:getColumn(1), B:getColumn(2) }
end

-- quaternion turning body axis `a` to world up (0,1,0)
local function axisUp(a)
  if a == 2 then return btQuaternion(0, 0, 0, 1) end
  if a == 1 then return btQuaternion(btVector3(0, 0, 1), math.pi / 2) end   -- body x -> world y
  return btQuaternion(btVector3(1, 0, 0), -math.pi / 2)                      -- body z -> world y
end

local t, flips = 0, {}

local function start()
  local W = 2 * math.pi * v:getParam("spin")
  local eps = v:getParam("nudge") / 100
  t = 0
  for _, h in ipairs(HANDLES) do
    local b = h.body
    b:setCenterOfMassTransform(btTransform(axisUp(h.axis), h.centre))
    b:setLinearVelocity(btVector3(0, 0, 0))
    -- body-frame spin: W about its axis, eps*W about the next one
    local w = { 0, 0, 0 }
    w[h.axis] = W
    w[h.axis % 3 + 1] = eps * W
    local c = basis(b)
    b:setAngularVelocity(btVector3(c[1].x * w[1] + c[2].x * w[2] + c[3].x * w[3],
                                   c[1].y * w[1] + c[2].y * w[2] + c[3].y * w[3],
                                   c[1].z * w[1] + c[2].z * w[2] + c[3].z * w[3]))
    b:activate(true)
    h.E0 = IV[1] * w[1] ^ 2 + IV[2] * w[2] ^ 2 + IV[3] * w[3] ^ 2
    h.L0 = math.sqrt((IV[1] * w[1]) ^ 2 + (IV[2] * w[2]) ^ 2 + (IV[3] * w[3]) ^ 2)
    h.sign, h.lastFlip, h.nflips, h.maxTilt, h.period = 1, nil, 0, 0, nil
    h.W, h.eps = W, eps
  end
  print(string.format("\n--- spin %.1f turns/s, nudge %.1f%% ---", v:getParam("spin"), v:getParam("nudge")))
  for _, h in ipairs(HANDLES) do print("  " .. h.name) end
end

-- ---------------------------------------------------------------------
-- Euler's equations, RK4, before every physics step
-- ---------------------------------------------------------------------
local function deriv(w)
  return { (IV[2] - IV[3]) * w[2] * w[3] / IV[1],
           (IV[3] - IV[1]) * w[3] * w[1] / IV[2],
           (IV[1] - IV[2]) * w[1] * w[2] / IV[3] }
end
local function plus(a, d, s) return { a[1] + s * d[1], a[2] + s * d[2], a[3] + s * d[3] } end

local function bodyW(b, c)
  local w = b:getAngularVelocity()
  return { c[1].x * w.x + c[1].y * w.y + c[1].z * w.z,
           c[2].x * w.x + c[2].y * w.y + c[2].z * w.z,
           c[3].x * w.x + c[3].y * w.y + c[3].z * w.z }
end

local function euler(dt)
  for _, h in ipairs(HANDLES) do
    local b = h.body
    local c = basis(b)
    local w = bodyW(b, c)
    local k1 = deriv(w)
    local k2 = deriv(plus(w, k1, dt / 2))
    local k3 = deriv(plus(w, k2, dt / 2))
    local k4 = deriv(plus(w, k3, dt))
    for i = 1, 3 do w[i] = w[i] + dt / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) end
    -- hold energy (sum I w^2) and angular momentum (sum I^2 w^2) exactly:
    -- one Newton step along their two gradients
    for it = 1, 2 do
      local E, L2 = 0, 0
      local gE, gL = {}, {}
      for i = 1, 3 do
        E = E + IV[i] * w[i] ^ 2; L2 = L2 + (IV[i] * w[i]) ^ 2
        gE[i] = 2 * IV[i] * w[i]; gL[i] = 2 * IV[i] ^ 2 * w[i]
      end
      local a11, a12, a22 = 0, 0, 0
      for i = 1, 3 do a11 = a11 + gE[i] * gE[i]; a12 = a12 + gE[i] * gL[i]; a22 = a22 + gL[i] * gL[i] end
      local r1, r2 = h.E0 - E, h.L0 ^ 2 - L2
      local det = a11 * a22 - a12 * a12
      if det > 1e-30 then
        local p = (r1 * a22 - r2 * a12) / det
        local q = (a11 * r2 - a12 * r1) / det
        for i = 1, 3 do w[i] = w[i] + p * gE[i] + q * gL[i] end
      else
        local sc = math.sqrt(h.E0 / E)
        for i = 1, 3 do w[i] = w[i] * sc end
      end
    end
    b:setAngularVelocity(btVector3(c[1].x * w[1] + c[2].x * w[2] + c[3].x * w[3],
                                   c[1].y * w[1] + c[2].y * w[2] + c[3].y * w[3],
                                   c[1].z * w[1] + c[2].z * w[2] + c[3].z * w[3]))
  end
end

v:preSim(function(N)
  for k = 1, NSTEPS - 1 do
    euler(STEP)
    v:stepSimulation(STEP, 0, STEP)
  end
  euler(STEP)
end)

-- ---------------------------------------------------------------------
-- watching: flips, tilt, conservation
-- ---------------------------------------------------------------------
local LOGF = os.getenv("DZ_LOG") and io.open(os.getenv("DZ_LOG"), "w")
if LOGF then LOGF:write("t,handle,w1,w2,w3,tilt_deg\n") end
local nextCheck = 10

v:postSim(function(N)
  t = t + FRAME_DT
  for k, h in ipairs(HANDLES) do
    local c = basis(h.body)
    local w = bodyW(h.body, c)
    -- tilt of the spin axis from straight up, and flips of its spin component
    local up = c[h.axis].y
    local tilt = math.deg(math.acos(math.max(-1, math.min(1, up))))
    h.maxTilt = math.max(h.maxTilt, math.min(tilt, 180 - tilt))
    h.tilt, h.w = tilt, w
    local sg = (w[h.axis] >= 0) and 1 or -1
    if sg ~= h.sign then
      h.sign = sg
      h.nflips = h.nflips + 1
      local per = h.lastFlip and string.format(", %.2f s after the last", t - h.lastFlip) or ""
      print(string.format("  %-6s flipped at %6.2f s%s  (flip %d)", h.short, t, per, h.nflips))
      if h.lastFlip then h.period = t - h.lastFlip end
      h.lastFlip = t
    end
    if LOGF and N % 4 == 0 then
      LOGF:write(string.format("%.4f,%d,%.6f,%.6f,%.6f,%.3f\n", t, k, w[1], w[2], w[3], tilt))
    end
  end
  if t >= nextCheck then
    nextCheck = nextCheck + 10
    local parts = {}
    for _, h in ipairs(HANDLES) do
      local c = basis(h.body)
      local w = bodyW(h.body, c)
      local E = IV[1] * w[1] ^ 2 + IV[2] * w[2] ^ 2 + IV[3] * w[3] ^ 2
      local L = math.sqrt((IV[1] * w[1]) ^ 2 + (IV[2] * w[2]) ^ 2 + (IV[3] * w[3]) ^ 2)
      parts[#parts + 1] = string.format("%s: flips %d, axis wandered up to %.0f deg, energy %+.1e, ang. mom. %+.1e",
                                        h.short, h.nflips, h.maxTilt, E / h.E0 - 1, L / h.L0 - 1)
    end
    print(string.format("t=%5.0fs  %s", t, table.concat(parts, " | ")))
  end
  if LOGF and N % 60 == 0 then LOGF:flush() end
end)

-- ---------------------------------------------------------------------
-- keys and sliders
-- ---------------------------------------------------------------------
v:addShortcut("R", function(N) start(); nextCheck = 10 end)
v:addShortcut("Z", function(N)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N, name, value)       -- bpp passes (frame, name, value)
  if name == "speed" or name == "steps" then
    applyTiming()
  elseif name == "spin" or name == "nudge" then
    start(); nextCheck = 10
  end
end)
pcall(function()
  v:setHelpText("The Dzhanibekov effect (Euler's Cabinet of Curiosities)\n" ..
    "  left  : spun about the stem (middle moment)    -- flips\n" ..
    "  middle: spun about the bar (smallest moment)   -- steady\n" ..
    "  right : spun across both (largest moment)      -- steady\n" ..
    "  R  start again     Z  slow motion <-> real time")
end)

-- ---------------------------------------------------------------------
-- mouse hover (needs a bpp with v:onHover): rest the mouse on a handle
-- ---------------------------------------------------------------------
local AXIS = { "the bar", "the stem", "across both" }
local ROLE = {}
do
  local order = { 1, 2, 3 }
  table.sort(order, function(a, b) return IV[a] < IV[b] end)
  ROLE[order[1]], ROLE[order[2]], ROLE[order[3]] = "SMALLEST", "MIDDLE", "LARGEST"
end
if v.onHover then
  local KEY = {}
  for _, h in ipairs(HANDLES) do KEY[objectKey(h.m)] = h end
  v:onHover(function(N, obj, x, y, z)
    local h = KEY[objectKey(obj)]
    if not h or not h.w then return nil end
    local w = h.w
    local E = IV[1] * w[1] ^ 2 + IV[2] * w[2] ^ 2 + IV[3] * w[3] ^ 2
    local L = math.sqrt((IV[1] * w[1]) ^ 2 + (IV[2] * w[2]) ^ 2 + (IV[3] * w[3]) ^ 2)
    local lines = {
      h.name,
      string.format("spun about %s: its %s moment of inertia", AXIS[h.axis], ROLE[h.axis]),
      ROLE[h.axis] == "MIDDLE" and "  -> unstable: it flips over and back, again and again"
                               or "  -> stable: it just spins",
      "",
      string.format("spin          %.2f turns/s, nudge %.1f%%", h.W / (2 * math.pi), 100 * h.eps),
      string.format("spin axis     %3.0f deg from straight up (most so far %.0f)", h.tilt, h.maxTilt),
      string.format("flips so far  %d%s", h.nflips, h.period and string.format(", every %.2f s", h.period) or ""),
      string.format("conserved     energy %+.1e, angular momentum %+.1e", E / h.E0 - 1, L / h.L0 - 1),
      "",
      string.format("mass %.1f g; moments (kg cm^2): bar %.3f, stem %.3f, across %.3f",
                    1000 * MASS, IV[1], IV[2], IV[3]),
    }
    return table.concat(lines, "\n")
  end)
end

start()
