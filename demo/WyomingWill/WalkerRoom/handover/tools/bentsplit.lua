-- BENT_SPLIT (a test): Chebyshev-Spears-file builds' bent coupler (coupler A-M plus its welded couplerVis M-B, which
-- the room keeps at 2% of the bar's weight) reweighed by length: the two pieces share the bar's weight in proportion
-- to their lengths (the total unchanged), each piece's turning inertia scaled with its mass. Under it: BS_BASE (default
-- stallprobe.lua). Prints BENTSPLIT <n> bars|coupler <m> vis <m> (before -> after).
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile(BS_BASE or "/home/claude/work/stallprobe.lua")
v = realv
local w = room.walkers[1]
local function len(o) local h = o.body:getCollisionShape():getHalfExtentsWithMargin(); return 2 * math.max(h.x, h.y) end
local function reweigh(o, m)
  local inv = o.body:getInvInertiaDiagLocal(); local k = m / o.mass
  o.body:setMassProps(m, btVector3(k / inv.x, k / inv.y, k / inv.z)); o.body:updateInertiaTensor(); o.mass = m
end
local n, msg = 0, ""
if BENT_SPLIT ~= false then
  for i = 1, 4 do
    local lk = w.parts["linkage" .. i]
    if lk and lk.couplerVis then
      local c, s = lk.coupler, lk.couplerVis
      local tot, la, lb = c.mass + s.mass, len(c), len(s)
      msg = string.format("coupler %.3f vis %.3f -> ", c.mass, s.mass)
      reweigh(c, tot * la / (la + lb)); reweigh(s, tot * lb / (la + lb))
      msg = msg .. string.format("%.3f %.3f", c.mass, s.mass); n = n + 1
    end
  end
end
print("BENTSPLIT " .. n .. " bars|" .. msg)
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:postSim(function(N) if hooks.postSim then hooks.postSim(N) end end)
realv:preDraw(function(N) if hooks.preDraw then hooks.preDraw(N) end end)
