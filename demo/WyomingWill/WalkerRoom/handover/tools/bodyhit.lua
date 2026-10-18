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
local mine = {}
for _, o in ipairs(w.bodies) do mine[o] = true end
local seen = 0
realv:preSim(function(N) hooks.preSim(N) end)
realv:postSim(function(N)
  hooks.postSim(N)
  if N < 120 or seen > 6 then return end
  realv:eachContact(function(a, b, x, y, z, nx, ny, nz, d, im)
    local other
    if rawequal(a, w.cube) and not mine[b] then other = b elseif rawequal(b, w.cube) and not mine[a] then other = a end
    if other and d < 0.01 and seen <= 6 then
      seen = seen + 1
      local lo, hi = btVector3(0,0,0), btVector3(0,0,0); other.body:getAabb(lo, hi)
      local blo, bhi = btVector3(0,0,0), btVector3(0,0,0); w.cube.body:getAabb(blo, bhi)
      print(string.format("HIT N%d other mass %.3f aabb y %.2f..%.2f x %.1f..%.1f z %.1f..%.1f | contact y %.2f d %.3f | body aabb y %.2f..%.2f", N, other.mass or -1, lo.y, hi.y, lo.x, hi.x, lo.z, hi.z, y, d, blo.y, bhi.y))
    end
  end)
end)
