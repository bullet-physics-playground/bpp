-- GHOST_LINKS (a test, on when this file is used): every part of the walker but its body and feet touches nothing
-- (contacts give no push), so only the feet and the body meet the ground. Under it: stallprobe (TRACK, STALL).
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
local n = 0
for _, o in ipairs(w.bodies) do
  if not rawequal(o, w.cube) and w.madeBy[o] ~= "buildFoot" then o.body:setCollisionFlags(o.body:getCollisionFlags() + 4); n = n + 1 end
end
print("GHOSTLINKS " .. n .. " parts touch nothing")
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:postSim(function(N) if hooks.postSim then hooks.postSim(N) end end)
realv:preDraw(function(N) if hooks.preDraw then hooks.preDraw(N) end end)
