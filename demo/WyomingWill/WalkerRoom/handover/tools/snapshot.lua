-- Side view of a walker at chosen moments (SNAP_AT = { s, ... }): every part's outline in world x, y (its box's
-- face in its own x-y plane), its side (z against the body's), and the ground's height along the walk at the body's z.
local dims, ankles = {}, {}
local rH = btHingeConstraint
btHingeConstraint = function(...) local c = rH(...); local f = debug.getinfo(3, "n"); if f and f.name == "buildFoot" then ankles[#ankles + 1] = c end; return c end
local rC = Cube
Cube = function(a, b, c, m) local o = rC(a, b, c, m); dims[o] = { a, b, c }; return o end
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile("test-track.lua")
v = realv
Cube = rC; btHingeConstraint = rH
local w = room.walkers[1]
local at = {}
for _, s in ipairs(SNAP_AT or {}) do at[math.floor(s * 60 + 0.5)] = true end
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  if not at[N] then return end
  local c0 = w.cube.body:getCenterOfMassPosition()
  print(string.format("SNAP %.2f body %.2f %.2f %.2f", N / 60, c0.x, c0.y, c0.z))
  local q = w.cube.body:getCenterOfMassTransform():getRotation()
  local fx = 1 - 2 * (q:y() * q:y() + q:z() * q:z()); local fy = 2 * (q:x() * q:y() + q:w() * q:z())
  local a = {}
  for i, h in ipairs(ankles) do a[i] = string.format("%.0f", math.deg(h:getHingeAngle())) end
  print(string.format("POSE pitch %.1f deg (body's x axis up from level) | ankles against their legs: %s", math.deg(math.atan2(fy, fx)), table.concat(a, " ")))
  for _, o in ipairs(w.bodies) do
    local d = dims[o]
    if d and o.mass > 0 then
      local T = o.body:getCenterOfMassTransform():inverse()   -- (its inverse's invXform: the part's frame to the world)
      local p = o.body:getCenterOfMassPosition()
      local pts = {}
      for _, q in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
        local wpt = T:invXform(btVector3(q[1] * d[1] / 2, q[2] * d[2] / 2, 0))
        pts[#pts + 1] = string.format("%.3f,%.3f", wpt.x, wpt.y)
      end
      local k = rawequal(o, w.cube) and "body" or (w.madeBy[o] or "?")
      print(string.format("PART %s|%.2f|%s", k, p.z - c0.z, table.concat(pts, ";")))
    end
  end
  local g = {}
  for x = c0.x - 45, c0.x + 45, 0.25 do g[#g + 1] = string.format("%.2f,%.3f", x, room.groundAt(x, c0.z)) end
  print("GROUND " .. table.concat(g, ";"))
end)
