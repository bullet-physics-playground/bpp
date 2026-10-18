-- Plan view of one walker as the room builds it: every body's outline
-- (x along the walk, z across), its kind, and its height range.
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
local lo, hi = btVector3(0,0,0), btVector3(0,0,0)
local out = {}
for _, o in ipairs(w.bodies) do
  if o.mass > 0 or rawequal(o, w.cube) then
    local kind = rawequal(o, w.cube) and "body" or (w.madeBy[o] or "?")
    local T = o.body:getCenterOfMassTransform():inverse()   -- (invXform of the inverse: body -> world)
    local ok, he = pcall(function() return o.body:getCollisionShape():getHalfExtentsWithMargin() end)
    local pts = {}
    if ok and he then
      for _, s in ipairs({ {-1,-1,-1},{1,-1,-1},{1,1,-1},{-1,1,-1},{-1,-1,1},{1,-1,1},{1,1,1},{-1,1,1} }) do
        local p = T:invXform(btVector3(s[1]*he.x, s[2]*he.y, s[3]*he.z))
        pts[#pts+1] = string.format("%.3f,%.3f,%.3f", p.x, p.y, p.z)
      end
    else
      o.body:getAabb(lo, hi)
      for _, s in ipairs({ {lo.x,lo.y,lo.z},{hi.x,lo.y,lo.z},{hi.x,hi.y,lo.z},{lo.x,hi.y,lo.z},{lo.x,lo.y,hi.z},{hi.x,lo.y,hi.z},{hi.x,hi.y,hi.z},{lo.x,hi.y,hi.z} }) do
        pts[#pts+1] = string.format("%.3f,%.3f,%.3f", s[1], s[2], s[3])
      end
    end
    print("PLAN " .. w.spec.name .. "|" .. kind .. "|" .. table.concat(pts, ";"))
  end
end
do local p = w.cube.body:getCenterOfMassPosition(); local e = 0.6
  local pts = {}
  for _, q in ipairs({ {-e,-e},{e,-e},{e,e},{-e,e},{-e,-e},{e,-e},{e,e},{-e,e} }) do pts[#pts+1] = string.format("%.3f,%.3f,%.3f", p.x+q[1], p.y, p.z+q[2]) end
  print("PLAN " .. w.spec.name .. "|load|" .. table.concat(pts, ";")) end
