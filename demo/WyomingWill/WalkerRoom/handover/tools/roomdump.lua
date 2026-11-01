-- The room's state after DUMP_AT frames (default 360, 6 simulated s), to tell whether two runs are the same move for
-- move: each walker's body position to 1/10000 cm, a sum over all its parts' positions, and how far it moved over
-- the ground from frame 60 (straight line). Also the wall time per
-- simulated second, as roomtime.lua. Run as roomtime.lua (set the room's globals, then dofile this).
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
local AT = DUMP_AT or 360
v = P
dofile("walker-room.lua")
v = realv
local c0
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  if hooks.preDraw then hooks.preDraw(N) end   -- (the room's marks and steering, as in the window)
  if N == 60 then
    c0 = os.clock()
    for _, w in ipairs(room.walkers) do local p = w.cube.body:getCenterOfMassPosition(); w._p0 = { p.x, p.z } end
  end
  if N == AT then
    for i, w in ipairs(room.walkers) do
      local p = w.cube.body:getCenterOfMassPosition()
      local s = 0
      for _, o in ipairs(w.objects or {}) do
        if o.body then local q = o.body:getCenterOfMassPosition(); s = s + q.x + 2 * q.y + 3 * q.z end
      end
      local d = math.sqrt((p.x - w._p0[1]) ^ 2 + (p.z - w._p0[2]) ^ 2)
      print(string.format("DUMP %d %s|%.4f %.4f %.4f|parts %.4f|moved %.2f cm", i, w.spec.name, p.x, p.y, p.z, s, d))
    end
    local t = os.clock() - c0
    print(string.format("DUMPTIME walkers %d  %.1f s wall for %.1f simulated s (%.2f x real time)", #room.walkers, t,
      (AT - 60) / 60, (AT - 60) / 60 / t))
  end
end)
