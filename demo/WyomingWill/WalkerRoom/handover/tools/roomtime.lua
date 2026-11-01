-- Time the room: wall-clock per simulated second from frame 60 to 360 (5 simulated s). (Wall time by v:getTime();
-- until November 2026 this used os.clock(), the processor time of all bpp's threads together, which is the same with
-- one thread but counts every thread's time with setThreads.)
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
local t0 = os.time()
if THREADS and THREADS > 0 then realv:setThreads(THREADS) end   -- (after the caller's setSolver)
v = P
dofile("walker-room.lua")
v = realv
local tBuilt = os.time()
local n = #room.walkers
local c0
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  if hooks.preDraw then hooks.preDraw(N) end   -- (the room's marks and steering, as in the window)
  if N == 60 then c0 = realv:getTime() end
  if N == 360 then
    local s = realv:getTime() - c0
    print(string.format("ROOMTIME walkers %d  start-up %d s  %.1f s wall for 5 simulated s (%.2f x real time)", n, tBuilt - t0, s, 5 / s))
  end
end)
