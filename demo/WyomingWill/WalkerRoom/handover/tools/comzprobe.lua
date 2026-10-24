-- The whole walker's centre of mass across the walk (z, in the body's own frame), extra blocks included. COMZ line.
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
local T = w.cube.body:getCenterOfMassTransform()
local M, mz = 0, 0
local list = { w.cube }
for _, o in ipairs(w.bodies) do if not rawequal(o, w.cube) then list[#list + 1] = o end end
for _, e in ipairs(EXTRA_LIST or {}) do list[#list + 1] = e.c end
for _, o in ipairs(list) do
  local im = o.body:getInvMass()
  if im > 0 then local m = 1 / im; local p = T:invXform(o.body:getCenterOfMassPosition()); M = M + m; mz = mz + m * p.z end
end
print(string.format("COMZ %s|mass %.2f|com z %.3f cm (body frame)", w.spec.name, M, mz / M))
