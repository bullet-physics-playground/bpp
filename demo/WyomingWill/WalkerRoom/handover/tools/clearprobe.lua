-- Walking on flat ground (run with AMP=0): the body's lowest point above the ground,
-- mean and lowest over frames 300-600; the feet's lowest bottom (ground check);
-- and the braces' lowest point (brace gap).  CLEAR <name>|mean|min|feet|braces
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
local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0)
local sum, n, mn, fmn, bmn = 0, 0, 1e9, 1e9, 1e9
realv:preSim(function(N) hooks.preSim(N) end)
realv:postSim(function(N)
  hooks.postSim(N)
  if N < 300 or N > 600 then return end
  w.cube.body:getAabb(lo, hi); sum = sum + lo.y; n = n + 1; mn = math.min(mn, lo.y)
  for _, o in ipairs(w.bodies) do
    local k = w.madeBy[o]
    if k == "buildFoot" then o.body:getAabb(lo, hi); fmn = math.min(fmn, lo.y)
    elseif k and k:find("Crossbar") and k ~= "buildArchedCrossbar" then o.body:getAabb(lo, hi); bmn = math.min(bmn, lo.y) end
  end
  if N == 600 then print(string.format("CLEAR %s|mean %.3f|min %.3f|feet %.3f|braces %.3f", w.spec.name, sum / n, mn, fmn, bmn)) end
end)
