-- (letterprobe.lua with the letters' box taken in the body's frame, and the report at CONTACT_AT.)
-- Every frame: how far the top outside brace's underside is above the body's raised letters and top panel
-- (look-only parts: they push nothing in the simulation), where it passes over them. Prints LETTERS min gap.
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile(LETTER_BASE or "test-track.lua")
v = realv
local w = room.walkers[1]
local cubeT0 = w.cube.body:getCenterOfMassTransform()
local deco = {}
local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0)
local c0 = w.cube.body:getCenterOfMassPosition()
for _, d in ipairs(w.decor or {}) do
  d.o.body:getAabb(lo, hi)
  -- (the letters' box in the body's own frame, as the brace points below are: the room turns most walkers 180 degrees)
  local x0, x1, z0, z1, ty = 1e9, -1e9, 1e9, -1e9, -1e9
  for _, cx in ipairs({ lo.x, hi.x }) do for _, cy in ipairs({ lo.y, hi.y }) do for _, cz in ipairs({ lo.z, hi.z }) do
    local q = cubeT0:invXform(btVector3(cx, cy, cz))
    x0, x1, z0, z1, ty = math.min(x0, q.x), math.max(x1, q.x), math.min(z0, q.z), math.max(z1, q.z), math.max(ty, q.y)
  end end end
  if lo.y - c0.y > 1.0 then deco[#deco + 1] = { x0 = x0, x1 = x1, z0 = z0, z1 = z1, top = ty } end
end
local top = {}
for _, o in ipairs(w.bodies) do
  if w.madeBy[o] == "buildOutsideCrossbar" then
    local p = cubeT0:invXform(o.body:getCenterOfMassPosition()); if p.y > -2 then top[#top + 1] = o end
  end
end
local worst = 1e9
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  local C = w.cube.body:getCenterOfMassTransform()
  local Ci = C:inverse()
  for _, o in ipairs(top) do
    local T = o.body:getCenterOfMassTransform()
    local sh = o.body:getCollisionShape()
    local h = sh:getHalfExtentsWithMargin()
    for s = -10, 10 do
      local q = T:inverse():invXform(btVector3(h.x * s / 10, -h.y, 0))   -- (T * point: a point on its underside)
      local b = Ci:inverse():invXform(q)                                  -- (into the body's frame... see below)
      local bb = C:invXform(q)
      for _, d in ipairs(deco) do
        if bb.x > d.x0 and bb.x < d.x1 and bb.z > d.z0 and bb.z < d.z1 then worst = math.min(worst, bb.y - d.top) end
      end
    end
  end
  if N == (CONTACT_AT or 3699) then print(string.format("LETTERS %s|top brace's underside over the letters and panel: min gap %.2f cm", w.spec.name, worst)) end
end)
