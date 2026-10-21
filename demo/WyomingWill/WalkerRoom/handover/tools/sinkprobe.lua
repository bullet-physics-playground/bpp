-- test track, plus how deep the feet go into the ground: deepest contact, and the mean of each frame's deepest (cm)
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
local feet, own = {}, {}
for _, o in ipairs(w.bodies) do own[#own + 1] = o; if w.madeBy[o] == "buildFoot" then feet[#feet + 1] = o end end
for _, d in ipairs(w.decor or {}) do own[#own + 1] = d.o end
local function isIn(t, o) for _, q in ipairs(t) do if rawequal(q, o) then return true end end return false end
local deepest, sum, n = 0, 0, 0
realv:preSim(function(N) hooks.preSim(N) end)
realv:postSim(function(N)
  hooks.postSim(N)
  if N < 120 then return end
  local d0 = 0
  realv:eachContact(function(a, b, x, y, z, nx, ny, nz, d, im)
    local fa, fb = isIn(feet, a), isIn(feet, b)
    if (fa and not isIn(own, b)) or (fb and not isIn(own, a)) then d0 = math.min(d0, d) end
  end)
  deepest = math.min(deepest, d0); sum = sum + d0; n = n + 1
  if N == 3699 then print(string.format("SINK %s|deepest %.2f cm|typical %.2f cm", w.spec.name, -deepest, -sum / n)) end
end)
