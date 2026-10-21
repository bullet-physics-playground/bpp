-- test track, plus body height (mean and lowest, cm above its start), roll, and how far joints pull apart
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
local y0 = select(2, getPosXYZ(w.cube))
local n, ysum, ymin, rmax = 0, 0, 1e9, 0
local spd = {}
realv:preSim(function(N) hooks.preSim(N) end)
realv:postSim(function(N)
  hooks.postSim(N)
  if N < 120 then return end
  local _, y = getPosXYZ(w.cube)
  n = n + 1; ysum = ysum + (y - y0); ymin = math.min(ymin, y - y0)
  local q = w.cube.body:getCenterOfMassTransform():getRotation()
  local sy = 2 * (q:y() * q:z() + q:w() * q:x())   -- (body z axis's height component: roll)
  rmax = math.max(rmax, math.abs(math.deg(math.asin(math.max(-1, math.min(1, sy))))))
  for i, m in ipairs(w.motors) do
    local a = m.hinge:getHingeAngle()
    if m.lastA then local d = a - m.lastA; if d > math.pi then d = d - 2 * math.pi elseif d < -math.pi then d = d + 2 * math.pi end; spd[i] = (spd[i] or 0) + math.abs(d) end
    m.lastA = a
  end
  if N == 3699 then
    local tot = 0; for _, s in pairs(spd) do tot = tot + s end
    print(string.format("STAND %s|body height mean %+.1f lowest %+.1f cm|roll max %.0f deg|crank turns %.1f (wanted %.1f)", w.spec.name, ysum / n, ymin, rmax, tot / #w.motors / (2 * math.pi), math.abs(w.crank) * n / 60 / (2 * math.pi)))
  end
end)
