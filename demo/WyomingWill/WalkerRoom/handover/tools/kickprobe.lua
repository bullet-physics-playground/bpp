-- Frame by frame from KICK_FROM to KICK_TO s (stallprobe under it): the body's vertical speed and pitch rate, each
-- part's vertical speed (the fastest few), every ground contact on the walker (part kind, side by body z, depth: how far
-- it sits in the ground, negative), and each slider joint's twist and the block's drift (as slidertest.lua).
--   K <t>|body vy <cm/s>|body wz <deg/s>|fast <kind:zc:vy ...>
--   C <t>|<kind>|<zc>|x <x>|y <y>|depth <d>
--   J <t>|<linkage>|twist <deg>|off <cm>|drift <cm>
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
local cube = w.cube
local FROM, TO = KICK_FROM * 60, KICK_TO * 60
local out = io.open(KICK_OUT, "w")
local mine, kind = {}, {}
for _, o in ipairs(w.bodies) do mine[#mine + 1] = o; kind[o] = w.madeBy[o] or "?" end
kind[cube] = "body"
local function find(o) for _, q in ipairs(mine) do if rawequal(q, o) then return q end end; if rawequal(o, cube) then return cube end end
local L = {}
for i = 1, 4 do local lk = w.parts and w.parts["linkage" .. i]; if lk and lk.sliderO4 then L[i] = lk end end
local home = {}
for i, lk in pairs(L) do home[i] = cube.body:getCenterOfMassTransform():invXform(lk.block.body:getCenterOfMassPosition()) end
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:preDraw(function(N) if hooks.preDraw then hooks.preDraw(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  if N < FROM or N > TO then return end
  local t = N / 60
  local cb = cube.body:getCenterOfMassPosition()
  local lv, av = cube.body:getLinearVelocity(), cube.body:getAngularVelocity()
  local fast = {}
  for _, o in ipairs(mine) do
    local vy = o.body:getLinearVelocity().y
    fast[#fast + 1] = { math.abs(vy), string.format("%s:%.0f:%.0f", kind[o], o.body:getCenterOfMassPosition().z - cb.z, vy) }
  end
  table.sort(fast, function(a, b) return a[1] > b[1] end)
  local f = {}; for i = 1, 4 do f[i] = fast[i][2] end
  out:write(string.format("K %.4f|body vy %.1f|body w %.1f %.1f %.1f|fast %s\n", t, lv.y, math.deg(av.x), math.deg(av.y), math.deg(av.z), table.concat(f, " ")))
  realv:eachContact(function(a, b, x, y, z, nx, ny, nz, d, imp)
    local pa, pb = find(a), find(b)
    if (pa and not pb) or (pb and not pa) then
      local p = pa or pb
      local lp = cube.body:getCenterOfMassTransform():invXform(btVector3(x, y, z))
      local fb = ((lp.x * ((w.spec and w.spec.forward) or 1)) > 0) and "F" or "B"
      local g0, ga, gb = room.groundAt(x, z), room.groundAt(x + 0.6, z), room.groundAt(x - 0.6, z)
      local where = (math.abs(ga - gb) > 1) and string.format("face(%.1f..%.1f)", math.min(ga, gb), math.max(ga, gb)) or string.format("flat(%.1f)", g0)
      out:write(string.format("C %.4f|%s|%s%s|x %.2f|y %.2f|z %.2f|depth %.3f|imp %.4f|%s\n", t, kind[p], fb, (lp.z > 0) and "L" or "R", x, y, z, d, imp or 0, where))
    end
  end)
  local Tcube = cube.body:getCenterOfMassTransform()
  for i, lk in pairs(L) do
    local Tb, Tc = lk.block.body:getCenterOfMassTransform(), lk.coupler.body:getCenterOfMassTransform()
    local pb = lk.block.body:getCenterOfMassPosition()
    local q = Tc:invXform(pb)
    local dd = math.abs(Tb:getRotation():dot(Tc:getRotation())); if dd > 1 then dd = 1 end
    local h = Tcube:invXform(pb); local hm = home[i]
    out:write(string.format("J %.4f|linkage%d|twist %.3f|off %.3f|drift %.3f\n", t, i, math.deg(2 * math.acos(dd)),
      math.sqrt(q.y * q.y + q.z * q.z), math.sqrt((h.x - hm.x) ^ 2 + (h.y - hm.y) ^ 2 + (h.z - hm.z) ^ 2)))
  end
  if N == TO then out:close() end
end)
