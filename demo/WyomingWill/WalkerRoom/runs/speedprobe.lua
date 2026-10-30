-- One test-track run, measured (for run-table.sh): the walker's progress along the track (its body's x) at 5 s
-- and at RUN_SECS (default 20) s, and its cranks' speed (as a share of driven speed) and torque (weight x stride
-- units) from 2 s on. At the end, one line:
--   RUN <name>|speed <cm/s, from 5 s to the end>|x5 <cm>|xend <cm>|cranks <min>..<max>|torque p95 <..> max <..>
-- Run from the WalkerRoom folder, after the room's settings (ONLY, TERRAIN, AMP, SEED, ...).
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
local END = (RUN_SECS or 20) * 60
for _, m in ipairs(w.motors) do m.hinge:enableForces() end
local unit = w.totalMass * (GRAVITY or 981) * (STRIDE or 15)
local x0 = w.cube.body:getCenterOfMassPosition().x
local x5, lo, hi, last, T = nil, 9, -9, {}, {}
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
-- (the room's own drawing hook is not run, as in the probes behind the 28-29 October tables: it moves the
-- look-only body marks and the status line; with it the runs come out differently, as any small change does)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  for i, m in ipairs(w.motors) do
    local a = m.hinge:getHingeAngle()
    if last[i] and N >= 120 then
      local d = a - last[i]; d = d - 2 * math.pi * math.floor(d / (2 * math.pi) + 0.5)
      local r = d * 60 * m.sign / math.abs(m.speed); lo = math.min(lo, r); hi = math.max(hi, r)
      T[#T + 1] = math.abs(m.hinge:torqueB().z) / unit
    end
    last[i] = a
  end
  if N == 300 then x5 = w.cube.body:getCenterOfMassPosition().x - x0 end
  if N == END then
    local xe = w.cube.body:getCenterOfMassPosition().x - x0
    table.sort(T)
    print(string.format("RUN %s|speed %.3f|x5 %.2f|xend %.2f|cranks %.2f..%.2f|torque p95 %.4f max %.4f", w.spec.name,
      (xe - x5) / (END / 60 - 5), x5, xe, lo, hi, T[math.max(1, math.floor(0.95 * #T))], T[#T]))
  end
end)
