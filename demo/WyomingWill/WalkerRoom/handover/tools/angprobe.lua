-- Each frame AP_FROM..AP_TO s (stallprobe under it): per linkage, crank speed (share of driven), the crank-coupler angle
-- and the coupler-rocker angle (deg, 0 = in line, folded to 0-90).
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
local out = io.open(AP_OUT, "w")
local function xa(o) local T2 = o.body:getCenterOfMassTransform():inverse(); local a, b = T2:invXform(btVector3(0, 0, 0)), T2:invXform(btVector3(1, 0, 0)); return b.x - a.x, b.y - a.y end
local function ang(p, q) local ux, uy = xa(p); local vx, vy = xa(q); local c = math.abs(ux * vx + uy * vy) / math.sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy)); return math.deg(math.acos(math.min(1, c))) end
local last = {}
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:preDraw(function(N) if hooks.preDraw then hooks.preDraw(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  local s = {}
  for i, m in ipairs(w.motors) do
    local a = m.hinge:getHingeAngle(); local r = 0
    if last[i] then local d = a - last[i]; d = d - 2 * math.pi * math.floor(d / (2 * math.pi) + 0.5); r = d * 60 * m.sign / math.abs(m.speed) end
    last[i] = a
    local lk = w.parts["linkage" .. i]
    if lk then s[#s + 1] = string.format("%d %.2f %.1f %.1f", i, r, ang(lk.crank, lk.coupler), lk.rocker and ang(lk.coupler, lk.rocker) or -1) end
  end
  if N >= AP_FROM * 60 and N <= AP_TO * 60 then out:write(string.format("AP %.4f|%s\n", N / 60, table.concat(s, "|"))) end
  if N == AP_TO * 60 then out:close() end
end)
