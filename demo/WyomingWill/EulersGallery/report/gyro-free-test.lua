-- Bullet's gyroscopic term on a free tumbling body, against the exact
-- torque-free motion (Checked 20 Oct 2026; report/dossiers/Gomboc.md,
-- Bille.md, Slinky.md and Dzhanibekov.md give the numbers).
--
-- One body per mode, side by side in one world, no gravity, nothing
-- touching; each frame takes HZ/60 physics steps. Modes:
--   0   Bullet's gyroscopic term off (setFlags(0))
--   2   BT_ENABLE_GYROSCOPIC_FORCE_EXPLICIT
--   4   BT_ENABLE_GYROSCOPIC_FORCE_IMPLICIT_WORLD
--   8   BT_ENABLE_GYROSCOPIC_FORCE_IMPLICIT_BODY (Bullet's default, and so
--       every body bpp makes unless its script calls setFlags)
--   M   term off; Euler's equations advanced in this script before each
--       step by the implicit midpoint rule (conserves energy and |L|
--       exactly, both being quadratic in the body-frame spin), as a
--       reference for what the harness itself can hold
--
-- GT_CASE:
--   top     symmetric top, I = (2, 2, 1), spin (2, 0, 8) rad/s in the body:
--           the spin precesses in the body at (I3 - I1)/I1 w3 = -4 rad/s
--   dzh     I = (1, 2, 3), 10 rad/s about the middle axis, nudged 0.01
--           about the first (Dzhanibekov/bullet-rotation-test.lua; GT_NUDGE
--           sets it: so near the unstable path, single-precision rounding
--           alone moves the flips, so 1.0 is the better-conditioned test)
--   gomboc  Gomboc C (gomboc-drop-c.lua): 0.3225 kg, I = (1.870, 2.189,
--           2.342) kg cm^2
--   bille   Bille (bille-meshes/bille-data.lua): 0.120 kg, I = (0.2191,
--           1.2249, 1.3209) kg cm^2
--   slinky  a piece of the Slinky on the stairs (falling-slinky.lua): two
--           coils, 5 g, I = (0.0289, 0.0578, 0.0289) kg cm^2
-- For gomboc, bille and slinky the spin is GT_W rad/s (default 5) along
-- (1, 2, 3)/|(1, 2, 3)| in the body; GT_PLANAR=1 instead spins it about
-- body z with the angular factor (0, 0, 1), as the Slinky's pieces are.
-- GT_HZ steps a second (default 1200), GT_T seconds (default 10).
--
-- Prints, every GT_EVERY seconds (default 1), for each mode: kinetic
-- energy and |L| relative to the start, the angle L has turned through in
-- the world (deg), and the body-frame spin; and every sign change of the
-- spin about body y (the flips, for dzh).
--
-- Run (headless):  GT_CASE=dzh GT_HZ=600 GT_T=60 bpp -f gyro-free-test.lua -n 3600

local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local CASE = os.getenv("GT_CASE") or "gomboc"
local HZ, T, EVERY = envnum("GT_HZ", 1200), envnum("GT_T", 10), envnum("GT_EVERY", 1)
local W, PLANAR = envnum("GT_W", 5), os.getenv("GT_PLANAR") == "1"
local NSTEP = math.floor(HZ / 60 + 0.5)
local STEP = 1 / (60 * NSTEP)
v.gravity = btVector3(0, 0, 0)
v.timeStep, v.maxSubSteps, v.fixedTimeStep = STEP, 0, STEP

local C = {
  top    = { m = 1, I = { 2, 2, 1 }, w = { 2, 0, 8 } },
  dzh    = { m = 1, I = { 1, 2, 3 }, w = { envnum("GT_NUDGE", 0.01), 10, 0 } },
  gomboc = { m = 0.3225, I = { 1.870, 2.189, 2.342 } },
  bille  = { m = 0.120, I = { 0.219124, 1.224880, 1.320906 } },
  slinky = { m = 0.005, I = { 0.0289, 0.0578, 0.0289 } },
}
local cs = C[CASE] or error("GT_CASE: top, dzh, gomboc, bille or slinky")
local I = cs.I
local w0 = cs.w
if not w0 then
  if PLANAR then w0 = { 0, 0, W } else
    local s = W / math.sqrt(14); w0 = { s, 2 * s, 3 * s }
  end
end

local MODES = { "0", "2", "4", "8", "M" }
local B = {}
for k, mode in ipairs(MODES) do
  local o = Sphere(0.5, cs.m)
  o.pos = btVector3(3 * k, 0, 0)
  o.collides = false
  v:add(o)
  local b = o.body
  b:setMassProps(cs.m, btVector3(I[1], I[2], I[3]))
  b:updateInertiaTensor()
  b:setFlags(mode == "M" and 0 or tonumber(mode))
  b:setActivationState(4)
  b:setDamping(0, 0)
  if PLANAR then b:setAngularFactor(btVector3(0, 0, 1)) end
  b:setAngularVelocity(btVector3(w0[1], w0[2], w0[3]))   -- identity orientation: body = world
  B[k] = { mode = mode, body = b, lastSign = 0, flips = {} }
end

local function basis(b)
  local R = b:getCenterOfMassTransform():getBasis()
  return { R:getColumn(0), R:getColumn(1), R:getColumn(2) }
end
local function bodyW(b, c)
  local w = b:getAngularVelocity()
  return { c[1].x * w.x + c[1].y * w.y + c[1].z * w.z,
           c[2].x * w.x + c[2].y * w.y + c[2].z * w.z,
           c[3].x * w.x + c[3].y * w.y + c[3].z * w.z }
end
local function state(b)
  local c = basis(b)
  local w = bodyW(b, c)
  local E, Lw = 0, { 0, 0, 0 }
  for i = 1, 3 do
    E = E + 0.5 * I[i] * w[i] ^ 2
    Lw[1] = Lw[1] + c[i].x * I[i] * w[i]; Lw[2] = Lw[2] + c[i].y * I[i] * w[i]; Lw[3] = Lw[3] + c[i].z * I[i] * w[i]
  end
  return E, Lw, w
end

-- the implicit midpoint rule for Euler's equations, I w' = (I w) x w
local function midpoint(b, dt)
  local c = basis(b)
  local w = bodyW(b, c)
  local w1 = { w[1], w[2], w[3] }
  for it = 1, 50 do
    local m = { (w[1] + w1[1]) / 2, (w[2] + w1[2]) / 2, (w[3] + w1[3]) / 2 }
    local o = { I[1] * m[1], I[2] * m[2], I[3] * m[3] }
    local n = { w[1] + dt * (o[2] * m[3] - o[3] * m[2]) / I[1],
                w[2] + dt * (o[3] * m[1] - o[1] * m[3]) / I[2],
                w[3] + dt * (o[1] * m[2] - o[2] * m[1]) / I[3] }
    local d = math.abs(n[1] - w1[1]) + math.abs(n[2] - w1[2]) + math.abs(n[3] - w1[3])
    w1 = n
    if d < 1e-15 * (1 + math.abs(w[1]) + math.abs(w[2]) + math.abs(w[3])) then break end
  end
  b:setAngularVelocity(btVector3(c[1].x * w1[1] + c[2].x * w1[2] + c[3].x * w1[3],
                                 c[1].y * w1[1] + c[2].y * w1[2] + c[3].y * w1[3],
                                 c[1].z * w1[1] + c[2].z * w1[2] + c[3].z * w1[3]))
end

local E0, L0 = {}, {}
for k, s in ipairs(B) do local E, L = state(s.body); E0[k], L0[k] = E, L end
print(string.format("GT case %s, I = (%g, %g, %g), body spin (%.4g, %.4g, %.4g) rad/s, %d steps/s, %g s%s",
  CASE, I[1], I[2], I[3], w0[1], w0[2], w0[3], 60 * NSTEP, T, PLANAR and ", planar" or ""))

local t = 0
local function pre()
  for _, s in ipairs(B) do if s.mode == "M" then midpoint(s.body, STEP) end end
end
v:preSim(function(N)
  for k = 1, NSTEP - 1 do pre(); v:stepSimulation(STEP, 0, STEP) end
  pre()
end)
v:postSim(function(N)
  t = N * NSTEP * STEP
  for k, s in ipairs(B) do
    local _, _, w = state(s.body)
    local sg = w[2] > 0 and 1 or -1
    if s.lastSign ~= 0 and sg ~= s.lastSign then s.flips[#s.flips + 1] = t end
    s.lastSign = sg
  end
  if math.abs(t / EVERY - math.floor(t / EVERY + 0.5)) < 1e-9 then
    local parts = {}
    for k, s in ipairs(B) do
      local E, L, w = state(s.body)
      local l0 = math.sqrt(L0[k][1] ^ 2 + L0[k][2] ^ 2 + L0[k][3] ^ 2)
      local l = math.sqrt(L[1] ^ 2 + L[2] ^ 2 + L[3] ^ 2)
      local cosA = (L[1] * L0[k][1] + L[2] * L0[k][2] + L[3] * L0[k][3]) / (l * l0)
      local ang = math.deg(math.acos(math.max(-1, math.min(1, cosA))))
      parts[#parts + 1] = string.format("[%s] dE %+.3e dL %+.3e Lturn %.3g deg w (%.5f %.5f %.5f) flips %d",
        s.mode, E / E0[k] - 1, l / l0 - 1, ang, w[1], w[2], w[3], #s.flips)
    end
    print(string.format("GT t=%.2f %s", t, table.concat(parts, " | ")))
  end
  if t >= T - 1e-9 then
    for k, s in ipairs(B) do
      local f = {}
      for i, x in ipairs(s.flips) do f[i] = string.format("%.4f", x) end
      print(string.format("GT flips [%s] %d: %s", s.mode, #s.flips, table.concat(f, " ")))
    end
  end
end)
