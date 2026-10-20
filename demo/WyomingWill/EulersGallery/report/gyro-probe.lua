-- How much energy Bullet's gyroscopic term makes or loses in an exhibit
-- (Checked 20 Oct 2026; see report/dossiers/Gomboc.md, Bille.md and Slinky.md).
--
-- Runs the exhibit GP_FILE (run from its folder) unchanged, and before
-- every physics step -- the exhibit's own v:stepSimulation calls and the
-- one bpp takes after preSim -- works out, for every dynamic body whose
-- gyroscopic flag is Bullet's default (8, BT_ENABLE_GYROSCOPIC_FORCE_
-- IMPLICIT_BODY), the change in spin Bullet's term is about to make: its
-- one Newton step of the backward-Euler step of Euler's equations
-- (btRigidBody::computeGyroscopicImpulseImplicit_Body), done here in double
-- precision, in the body's frame. The true gyroscopic torque does no work
-- (w . (Iw x w) = 0), so the kinetic energy that change makes is all error;
-- it is summed per body (cm^2 kg / s^2 in the gallery's units). (Bullet
-- leaves the term out if the 3x3 matrix's determinant is under single
-- precision's epsilon, 1.19e-7: those bodies are counted apart.)
--
-- Every GP_EVERY seconds (simulated, default 5) and at the end it prints,
-- for all such bodies together: the energy the term made (negative: lost);
-- all the losses (every fall in a body's mechanical energy, kinetic + m g y
-- with the world's gravity, from one step to the next: restitution,
-- friction, rolling resistance, and the term's own); the largest spin seen;
-- and, per body mass, the term's energy and the largest kinetic energy.
-- The simulated time is counted from the steps.
--
-- Run (headless, from the exhibit's folder; re-drops off so the same
-- bodies are followed from drop to rest):
--   GC_REDROP=0 HOLD_S=0 GP_FILE=gomboc-drop-c.lua bpp -f ../../report/gyro-probe.lua -n 1800
-- (It prints nothing else of its own; the exhibit's console is unchanged.)

local realv = v
local objs = {}
local P = setmetatable({}, {
  __index = function(t, k)
    local f = realv[k]
    if k == "add" then return function(self, o, ...) objs[#objs + 1] = o; return realv:add(o, ...) end end
    if k == "preSim" then return function(self, fn) realv:preSim(function(N) fn(N); GP_beforeStep(realv.fixedTimeStep); GP_frame(N) end) end end
    if k == "stepSimulation" then return function(self, a, b, c) GP_beforeStep(c or a); return realv:stepSimulation(a, b, c) end end
    if type(f) == "function" then return function(self, ...) return f(realv, ...) end end
    return f
  end,
  __newindex = function(t, k, val) realv[k] = val end })

local EVERY = tonumber(os.getenv("GP_EVERY") or "") or 5
-- GP_FIX=1: an A/B test instead. Bullet's term is switched off on those
-- bodies and before every step their spin is advanced by Euler's
-- equations with the implicit midpoint rule (energy and |L| exact), as a
-- change of spin before the step, which the contacts then see.
local FIX = os.getenv("GP_FIX") == "1"
local made, simT, wmax, nOff, lastPrint = 0, 0, 0, 0, 0
local offSeen = {}
local madeBy = {}              -- per body mass: energy the term made
FIXED = {}                     -- (GP_FIX) bodies whose term this script has taken over

local function basis(b)
  local R = b:getCenterOfMassTransform():getBasis()
  return { R:getColumn(0), R:getColumn(1), R:getColumn(2) }
end

local function solve33(J, f)
  local function det(M) return M[1][1] * (M[2][2] * M[3][3] - M[2][3] * M[3][2]) - M[1][2] * (M[2][1] * M[3][3] - M[2][3] * M[3][1]) + M[1][3] * (M[2][1] * M[3][2] - M[2][2] * M[3][1]) end
  local D = det(J)
  local x = {}
  for c = 1, 3 do
    local M = { { J[1][1], J[1][2], J[1][3] }, { J[2][1], J[2][2], J[2][3] }, { J[3][1], J[3][2], J[3][3] } }
    for r = 1, 3 do M[r][c] = f[r] end
    x[c] = det(M) / D
  end
  return x, D
end

local function bodies()
  local out = {}
  -- (keyed by the object's index: each o.body is a fresh Lua handle)
  for i, o in ipairs(objs) do
    local b = o.body
    if b and b:isInWorld() and b:getInvMass() > 0 then out[#out + 1] = { i = i, b = b } end
  end
  return out
end

function GP_beforeStep(dt)
  simT = simT + dt
  GP_mech()
  for _, ib in ipairs(bodies()) do
    local b = ib.b
    if b:getFlags() == 8 or b:getFlags() == 9 or FIXED[ib.i] then
      local iv = b:getInvInertiaDiagLocal()
      local I = { 1 / iv.x, 1 / iv.y, 1 / iv.z }
      local c = basis(b)
      local W = b:getAngularVelocity()
      local w = {}
      for k = 1, 3 do w[k] = c[k].x * W.x + c[k].y * W.y + c[k].z * W.z end
      local o = { I[1] * w[1], I[2] * w[2], I[3] * w[3] }
      local f = { dt * (w[2] * o[3] - w[3] * o[2]), dt * (w[3] * o[1] - w[1] * o[3]), dt * (w[1] * o[2] - w[2] * o[1]) }
      local S0 = { { 0, -w[3], w[2] }, { w[3], 0, -w[1] }, { -w[2], w[1], 0 } }
      local S1 = { { 0, -o[3], o[2] }, { o[3], 0, -o[1] }, { -o[2], o[1], 0 } }
      local J = {}
      for r = 1, 3 do
        J[r] = {}
        for k = 1, 3 do J[r][k] = (r == k and I[k] or 0) + dt * (S0[r][k] * I[k] - S1[r][k]) end
      end
      local x, D = solve33(J, f)
      if FIX then
        b:setFlags(b:getFlags() - 8)
        local w1 = { w[1], w[2], w[3] }
        for it = 1, 50 do
          local m = { (w[1] + w1[1]) / 2, (w[2] + w1[2]) / 2, (w[3] + w1[3]) / 2 }
          local om = { I[1] * m[1], I[2] * m[2], I[3] * m[3] }
          local n = { w[1] + dt * (om[2] * m[3] - om[3] * m[2]) / I[1],
                      w[2] + dt * (om[3] * m[1] - om[1] * m[3]) / I[2],
                      w[3] + dt * (om[1] * m[2] - om[2] * m[1]) / I[3] }
          local d = math.abs(n[1] - w1[1]) + math.abs(n[2] - w1[2]) + math.abs(n[3] - w1[3])
          w1 = n
          if d < 1e-15 * (1 + math.abs(w[1]) + math.abs(w[2]) + math.abs(w[3])) then break end
        end
        b:setAngularVelocity(btVector3(c[1].x * w1[1] + c[2].x * w1[2] + c[3].x * w1[3],
                                       c[1].y * w1[1] + c[2].y * w1[2] + c[3].y * w1[3],
                                       c[1].z * w1[1] + c[2].z * w1[2] + c[3].z * w1[3]))
        FIXED[ib.i] = true
      elseif math.abs(D) > 1.1920929e-7 then
        local dE = 0
        for k = 1, 3 do dE = dE + 0.5 * I[k] * ((w[k] - x[k]) ^ 2 - w[k] ^ 2) end
        made = made + dE
        local key = string.format("%.4g kg", 1 / b:getInvMass())
        madeBy[key] = (madeBy[key] or 0) + dE
      elseif not offSeen[ib.i] then
        offSeen[ib.i] = true; nOff = nOff + 1
      end
      local wm = math.sqrt(W.x ^ 2 + W.y ^ 2 + W.z ^ 2)
      if wm > wmax then wmax = wm end
    end
  end
end

local function mechOf(b)
  local g = realv.gravity
  local E = 0
  do
      local m = 1 / b:getInvMass()
      local iv = b:getInvInertiaDiagLocal()
      local I = { 1 / iv.x, 1 / iv.y, 1 / iv.z }
      local c = basis(b)
      local W, V = b:getAngularVelocity(), b:getLinearVelocity()
      local p = b:getCenterOfMassPosition()
      E = E + 0.5 * m * (V.x ^ 2 + V.y ^ 2 + V.z ^ 2) - m * (g.x * p.x + g.y * p.y + g.z * p.z)
      for k = 1, 3 do
        local w = c[k].x * W.x + c[k].y * W.y + c[k].z * W.z
        E = E + 0.5 * I[k] * w * w
      end
  end
  return E
end
-- the bodies now in the world with the term on: their mechanical energy,
-- summed; and, per body, every fall in it from one step to the next is
-- added to the losses (a rise -- a body put somewhere by the script, or
-- Bullet's own error -- is not), and its largest kinetic energy kept
local lastE, lost, keMax = {}, 0, {}
function GP_mech()
  local E = 0
  for _, ib in ipairs(bodies()) do
    local b = ib.b
    if b:getFlags() == 8 or b:getFlags() == 9 or FIXED[ib.i] then
      local e = mechOf(b)
      if lastE[ib.i] and e < lastE[ib.i] then lost = lost + lastE[ib.i] - e end
      lastE[ib.i] = e
      local g = realv.gravity
      local ke = e + (1 / b:getInvMass()) * (g.x * b:getCenterOfMassPosition().x + g.y * b:getCenterOfMassPosition().y + g.z * b:getCenterOfMassPosition().z)
      local key = string.format("%.4g kg", 1 / b:getInvMass())
      if ke > (keMax[key] or 0) then keMax[key] = ke end
      E = E + e
    end
  end
  return E
end

function GP_frame(N)
  if simT - lastPrint >= EVERY - 1e-9 then
    lastPrint = simT
    local E = GP_mech()
    local by = {}
    for k, x in pairs(keMax) do by[#by + 1] = string.format("%s: term %+.3e, largest KE %.4g", k, madeBy[k] or 0, x) end
    table.sort(by)
    print(string.format("GP t=%.3f gyro term made %+.4e; all losses %.6g; gyro/losses %+.2e; max spin %.3g rad/s; bodies with the term skipped (det < eps) %d; by mass: %s",
      simT, made, lost, made / lost, wmax, nOff, table.concat(by, "; ")))
  end
end

v = P
dofile(os.getenv("GP_FILE"))
