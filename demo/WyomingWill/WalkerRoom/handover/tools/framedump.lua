-- Test track (stallprobe, so its switches work), plus a side-view dump for drawing: every FD_EVERY frames (default 6,
-- so 10 a second) from FD_FROM to FD_TO seconds, each box of the walker (body, links, feet, blocks) as its 8 corners'
-- x, y (cm; x along the track, y up) and its centre's z (across, relative to the body), and the ground's height along x
-- at the left and the right feet's z. Writes FD_OUT:
--   T <s>|body x <x>|body z <z>
--   B <kind>|<zc rel. body>|x,y;x,y;... (8 corners)
--   G <z of that line rel. body>|x0 <x>|dx <dx>|h,h,h,...
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile(FD_BASE or "/home/claude/work/stallprobe.lua")
v = realv
local w = room.walkers[1]
local EVERY, FROM, TO = FD_EVERY or 6, (FD_FROM or 0) * 60, (FD_TO or 60) * 60
local out = io.open(FD_OUT or os.getenv("FD_OUT"), "w")
local parts = { { o = w.cube, kind = "body" } }
for _, o in ipairs(w.bodies) do
  if not rawequal(o, w.cube) then
    local ok, sh = pcall(function() return o.body:getCollisionShape():getHalfExtentsWithMargin() end)
    if ok and sh then parts[#parts + 1] = { o = o, kind = w.madeBy[o] or "?", h = sh } end
  end
end
do   -- (the body's shape is not a plain box: its box from its bounds as built, in its own frame)
  local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0); w.cube.body:getAabb(lo, hi)
  local T = w.cube.body:getCenterOfMassTransform()
  local a, b = T:invXform(lo), T:invXform(hi)
  parts[1].lmin = { math.min(a.x, b.x) + 0.04, math.min(a.y, b.y) + 0.04, math.min(a.z, b.z) + 0.04 }
  parts[1].lmax = { math.max(a.x, b.x) - 0.04, math.max(a.y, b.y) - 0.04, math.max(a.z, b.z) - 0.04 }
end
local feetZ = {}
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:preDraw(function(N) if hooks.preDraw then hooks.preDraw(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  if N < FROM or N > TO or N % EVERY ~= 0 then return end
  local cb = w.cube.body:getCenterOfMassPosition()
  out:write(string.format("T %.3f|body x %.2f|body z %.2f\n", N / 60, cb.x, cb.z))
  if STEP_FACE_X then out:write(string.format("S %.2f|%.2f\n", STEP_FACE_X, STEP_H or 7)) end
  local zs = {}
  for _, p in ipairs(parts) do
    local T = p.o.body:getCenterOfMassTransform()
    local Ti = T:inverse()
    local h = p.h
    local c = {}
    for _, sx in ipairs({ -1, 1 }) do for _, sy in ipairs({ -1, 1 }) do for _, sz in ipairs({ -1, 1 }) do
      if h then c[#c + 1] = { sx * h.x, sy * h.y, sz * h.z }
      else c[#c + 1] = { sx < 0 and p.lmin[1] or p.lmax[1], sy < 0 and p.lmin[2] or p.lmax[2], sz < 0 and p.lmin[3] or p.lmax[3] } end
    end end end
    local pc = p.o.body:getCenterOfMassPosition()
    local s = {}
    for _, k in ipairs(c) do
      -- world point = T * local: invXform of T's inverse
      local wp = Ti:invXform(btVector3(k[1], k[2], k[3]))
      s[#s + 1] = string.format("%.2f,%.2f", wp.x, wp.y)
    end
    out:write(string.format("B %s|%.2f|%s\n", p.kind, pc.z - cb.z, table.concat(s, ";")))
    if p.kind == "buildFoot" then zs[#zs + 1] = pc.z end
  end
  -- the ground under the two rows of feet (their mean z on each side)
  local lo, hi, nl, nh = 0, 0, 0, 0
  for _, z in ipairs(zs) do if z > cb.z then hi, nh = hi + z, nh + 1 else lo, nl = lo + z, nl + 1 end end
  for _, z in ipairs({ nh > 0 and hi / nh or cb.z + 15, nl > 0 and lo / nl or cb.z - 15 }) do
    local hs = {}
    for i = 0, 160 do hs[#hs + 1] = string.format("%.2f", room.groundAt(cb.x - 40 + i * 0.5, z)) end
    out:write(string.format("G %.2f|x0 %.2f|dx 0.5|%s\n", z - cb.z, cb.x - 40, table.concat(hs, ",")))
  end
  if N + EVERY > TO then out:flush() end
end)
