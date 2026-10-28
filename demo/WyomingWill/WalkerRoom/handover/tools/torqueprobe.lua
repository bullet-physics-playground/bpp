-- Each crank's motor torque (the torque its hinge puts on the crank about the axle, from bpp's enableForces), in
-- units of the walker's weight x STRIDE, and its speed (share of driven), each frame from TQ_FROM to TQ_TO s; at the
-- end per crank and over all: median, 95th percentile and the largest |torque|, and how far the speed strayed.
-- TQ <name>|iterations ..|friction ..|torque median .. p95 .. max ..|speed ..-..   (stallprobe under it)
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile("/home/claude/work/stallprobe.lua")
v = realv
local w = room.walkers[1]
for _, m in ipairs(w.motors) do m.hinge:enableForces() end
local unit = w.totalMass * (GRAVITY or 981) * (STRIDE or 15)
local T, lo, hi, last = {}, 9, -9, {}
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:preDraw(function(N) if hooks.preDraw then hooks.preDraw(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  for i, m in ipairs(w.motors) do
    local a = m.hinge:getHingeAngle()
    if last[i] and N >= TQ_FROM * 60 and N <= TQ_TO * 60 then
      local d = a - last[i]; d = d - 2 * math.pi * math.floor(d / (2 * math.pi) + 0.5)
      local r = d * 60 * m.sign / math.abs(m.speed); lo = math.min(lo, r); hi = math.max(hi, r)
      local tq = m.hinge:torqueB(); T[#T + 1] = math.abs(tq.z) / unit
    end
    last[i] = a
  end
  if N == TQ_TO * 60 then
    table.sort(T)
    local function q(p) return T[math.max(1, math.floor(p * #T))] end
    print(string.format("TQ %s|iterations %s|friction %s|torque median %.4f p95 %.4f max %.4f|motor max %.4f|speed %.2f-%.2f", w.spec.name,
      tostring(SOLVER_ITERATIONS), JOINT_FRICTION and string.format("mu %.2f pin %.2f", JOINT_FRICTION.mu, JOINT_FRICTION.pin) or "off",
      q(0.5), q(0.95), T[#T], (MOTOR_STRENGTH or 0) / #w.motors, lo, hi))
  end
end)
