-- Each crank's turning relative to the body, two ways, each frame from CP_FROM to CP_TO s (stallprobe under it):
-- from its hinge angle (as lockCranks reads it) and from the two bodies' spin (about the body's z axis).
-- CP <t>|<i>|hinge <deg/s>|spin <deg/s>|target <deg/s>   (+ = the way its motor turns it)
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
local out = io.open(CP_OUT, "w")
local cranks = {}
for i = 1, 4 do local lk = w.parts["linkage" .. i]; cranks[i] = lk and lk.crank end
local last = {}
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:preDraw(function(N) if hooks.preDraw then hooks.preDraw(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  local T = w.cube.body:getCenterOfMassTransform()
  local wc = w.cube.body:getAngularVelocity()
  for i, m in ipairs(w.motors) do
    local a = m.hinge:getHingeAngle()
    if last[i] and N >= CP_FROM * 60 and N <= CP_TO * 60 then
      local d = a - last[i]; d = d - 2 * math.pi * math.floor(d / (2 * math.pi) + 0.5)
      local c = cranks[i]
      local s = 0
      if c then
        local wv = c.body:getAngularVelocity()
        local rel = btVector3(wv.x - wc.x, wv.y - wc.y, wv.z - wc.z)
        local o = T:invXform(btVector3(0, 0, 0)); local lz = T:invXform(rel)   -- (rotate into the body's frame)
        s = (lz.z - o.z)
      end
      out:write(string.format("CP %.4f|%d|hinge %.1f|spin %.1f|target %.1f\n", N / 60, i, math.deg(d) * 60 * m.sign, math.deg(s) * m.sign, math.deg(m.speed) * m.sign))
    end
    last[i] = a
  end
  if N == CP_TO * 60 then out:close(); print(string.format("SOLVER %s|fallbacks %d|frames %d", tostring(realv.solver), realv.solverFallbacks or -1, N)) end
end)
