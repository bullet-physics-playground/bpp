-- Test track, plus one STALL line a second (time s): x, z (cm from start), heading,
-- pitch, roll (deg), crank turns that second, feet down (which: F/B front/back by
-- body x, L/R by body z, as built), how fast the feet in contact slide (cm/s,
-- across the ground), and which non-foot parts touched the ground (share of frames).
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile("test-track.lua")
v = realv
local w = room.walkers[1]
-- HOLD_BRACES = true: each diag brace piece also held at its angle to the body
-- (free to move), as the guides hold the legs: braces kept, their twisting removed
if HOLD_BRACES then
  local held = 0
  for _, o in ipairs(w.bodies) do
    local k = w.madeBy[o]
    if k == "buildDiagonalCrossbar" or k == "buildArchedCrossbar" then
      local g = btGeneric6DofConstraint(w.cube.body, o.body,
        w.cube.body:getCenterOfMassTransform():inverseTimes(o.body:getCenterOfMassTransform()),
        btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0)), true)
      g:setLinearLowerLimit(btVector3(1, 1, 1)); g:setLinearUpperLimit(btVector3(-1, -1, -1))
      g:setAngularLowerLimit(btVector3(0, 0, 0)); g:setAngularUpperLimit(btVector3(0, 0, 0))
      if SOLVER_ITERATIONS then g:setOverrideNumSolverIterations(SOLVER_ITERATIONS) end
      v:addConstraint(g); held = held + 1
    end
  end
  print("HELD " .. held .. " brace pieces")
end
local mine = {}
for _, o in ipairs(w.bodies) do mine[o] = w.madeBy[o] or "body" end
mine[w.cube] = "body"
local function kind(o) for q, k in pairs(mine) do if rawequal(q, o) then return k, q end end end
local label = {}    -- part -> F/B L/R by its place in the body frame at the start
local function where(o)
  local p = w.cube.body:getCenterOfMassTransform():invXform(o.body:getCenterOfMassPosition())
  return (p.x > 0 and "F" or "B") .. (p.z > 0 and "L" or "R")
end
local function hdg()
  local q = w.cube.body:getCenterOfMassTransform():getRotation()
  local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
  local fx, fz = 1 - 2 * (qy * qy + qz * qz), 2 * (qx * qz - qw * qy)
  local fy, sy = 2 * (qx * qy + qw * qz), 2 * (qy * qz - qw * qx)
  return math.deg(math.atan2(-fz, fx)), math.deg(math.asin(math.max(-1, math.min(1, fy)))), math.deg(math.asin(math.max(-1, math.min(1, sy))))
end
local h0, x0, z0
local last = {}     -- foot -> last position
local acc
local function reset() acc = { n = 0, feet = {}, slip = 0, slipN = 0, ground = {}, pmax = 0, rmax = 0 } end
reset()
for _, m in ipairs(w.motors) do m.spLast = m.hinge:getHingeAngle(); m.spTurn = 0 end
realv:preSim(function(N) hooks.preSim(N) end)
realv:postSim(function(N)
  hooks.postSim(N)
  if N < 120 then return end
  if N == 120 then
    h0 = hdg(); x0, _, z0 = getPosXYZ(w.cube)
    for o, k in pairs(mine) do if k ~= "body" then label[o] = where(o) end end
  end
  local h, p, r = hdg()
  acc.pmax = math.max(acc.pmax, math.abs(p)); acc.rmax = math.max(acc.rmax, math.abs(r))
  for _, m in ipairs(w.motors) do
    local a = m.hinge:getHingeAngle(); local d = a - m.spLast
    if d > math.pi then d = d - 2 * math.pi elseif d < -math.pi then d = d + 2 * math.pi end
    m.spTurn = m.spTurn + math.abs(d); m.spLast = a
  end
  local down, gr = {}, {}
  realv:eachContact(function(a, b, cx, cy, cz, nx, ny, nz, d, im)
    if d > 0.01 then return end
    local ka, oa = kind(a); local kb, ob = kind(b)
    if (ka == nil) == (kb == nil) then return end
    local k, o = ka or kb, oa or ob
    if k == "buildFoot" then down[o] = true else gr[k .. ":" .. (label[o] or "?")] = true end
  end)
  acc.n = acc.n + 1
  for o in pairs(down) do
    acc.feet[label[o]] = (acc.feet[label[o]] or 0) + 1
    local q = o.body:getCenterOfMassPosition()
    if last[o] then acc.slip = acc.slip + math.sqrt((q.x - last[o][1])^2 + (q.z - last[o][2])^2) * 60; acc.slipN = acc.slipN + 1 end
  end
  for o, k in pairs(mine) do if k == "buildFoot" then local q = o.body:getCenterOfMassPosition(); last[o] = { q.x, q.z } end end
  for k in pairs(gr) do acc.ground[k] = (acc.ground[k] or 0) + 1 end
  if N % 60 == 0 then
    local x, _, z = getPosXYZ(w.cube)
    local t = 0; for _, m in ipairs(w.motors) do t = t + m.spTurn end; t = t / #w.motors / (2 * math.pi)
    for _, m in ipairs(w.motors) do m.spTurn = 0 end
    local f = {}; for k, n in pairs(acc.feet) do f[#f + 1] = string.format("%s %.0f", k, 100 * n / acc.n) end; table.sort(f)
    local g = {}; for k, n in pairs(acc.ground) do g[#g + 1] = string.format("%s %.0f", k, 100 * n / acc.n) end; table.sort(g)
    print(string.format("STALL %d|x %.1f|z %.1f|hdg %.1f|pitch %.1f|roll %.1f|turns %.2f|feet %s|slip %.1f|ground %s",
      N / 60, x - x0, z - z0, h - h0, acc.pmax, acc.rmax, t, table.concat(f, " "), acc.slipN > 0 and acc.slip / acc.slipN or 0, table.concat(g, " ")))
    reset()
  end
end)
