-- Static stability, every frame from frame 120 (2 s): the whole walker's centre of mass (CoM)
-- dropped straight down (gravity is -y), against the base of support = the convex hull, on the
-- ground plane (x, z), of every foot-ground contact point that frame.
-- Writes STAB_OUT (env), one line per frame:
--   t|feet down|contact points|margin cm|CoM height cm|tip angle deg
-- margin: distance from the dropped CoM to the nearest hull edge, + inside, - outside (with fewer
-- than 3 non-collinear points the hull has no inside, so the margin is minus the distance to it).
-- CoM height: above the mean height of the contact points. tip angle = atan(margin / height):
-- how far the walker could be tipped about that edge before its CoM passes over it.
-- Chains like pitchprobe: STAB_BASE (e.g. stallprobe.lua, for its switches) or test-track.lua.
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile(STAB_BASE or "test-track.lua")
v = realv
local w = room.walkers[1]
local all = { w.cube }
for _, o in ipairs(w.bodies) do if not rawequal(o, w.cube) then all[#all + 1] = o end end
local isFoot, mine = {}, {}
for _, o in ipairs(all) do mine[#mine + 1] = o end
local function find(o) for _, q in ipairs(mine) do if rawequal(q, o) then return q end end end
local deco = {}
for _, d in ipairs(w.decor or {}) do deco[#deco + 1] = d.o end
local function isDeco(o) for _, q in ipairs(deco) do if rawequal(q, o) then return true end end return false end
for _, o in ipairs(all) do if w.madeBy[o] == "buildFoot" then isFoot[o] = true end end

local function hull(pts)
  table.sort(pts, function(a, b) return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]) end)
  if #pts < 3 then return pts end
  local function cr(o, a, b) return (a[1] - o[1]) * (b[2] - o[2]) - (a[2] - o[2]) * (b[1] - o[1]) end
  local lo, up = {}, {}
  for _, p in ipairs(pts) do
    while #lo >= 2 and cr(lo[#lo - 1], lo[#lo], p) <= 1e-9 do lo[#lo] = nil end
    lo[#lo + 1] = p
  end
  for i = #pts, 1, -1 do local p = pts[i]
    while #up >= 2 and cr(up[#up - 1], up[#up], p) <= 1e-9 do up[#up] = nil end
    up[#up + 1] = p
  end
  lo[#lo] = nil; up[#up] = nil
  for _, p in ipairs(up) do lo[#lo + 1] = p end
  return lo   -- counter-clockwise
end
local function segd(p, a, b)
  local dx, dz = b[1] - a[1], b[2] - a[2]
  local L = dx * dx + dz * dz
  local t = L > 0 and math.max(0, math.min(1, ((p[1] - a[1]) * dx + (p[2] - a[2]) * dz) / L)) or 0
  return math.sqrt((p[1] - a[1] - t * dx)^2 + (p[2] - a[2] - t * dz)^2)
end
local function margin(p, H)
  if #H == 0 then return -99 end
  if #H == 1 then return -math.sqrt((p[1] - H[1][1])^2 + (p[2] - H[1][2])^2) end
  if #H == 2 then return -segd(p, H[1], H[2]) end
  local inside, dmin = true, 1e9
  for i = 1, #H do
    local a, b = H[i], H[i % #H + 1]
    local c = (b[1] - a[1]) * (p[2] - a[2]) - (b[2] - a[2]) * (p[1] - a[1])
    if c < 0 then inside = false end
    dmin = math.min(dmin, segd(p, a, b))
  end
  return inside and dmin or -dmin
end

local out = io.open(os.getenv("STAB_OUT"), "w")
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  if N < 120 or N > 3699 then return end
  local M, cx, cy, cz = 0, 0, 0, 0
  for _, o in ipairs(all) do
    local im = o.body:getInvMass()
    if im > 0 then local m = 1 / im; local q = o.body:getCenterOfMassPosition()
      M = M + m; cx = cx + m * q.x; cy = cy + m * q.y; cz = cz + m * q.z end
  end
  cx, cy, cz = cx / M, cy / M, cz / M
  local pts, ysum, feet = {}, 0, {}
  realv:eachContact(function(a, b, x, y, z, nx, ny, nz, d)
    if d > 0.01 or isDeco(a) or isDeco(b) then return end
    local oa, ob = find(a), find(b)
    if (oa == nil) == (ob == nil) then return end
    local o = oa or ob
    if not isFoot[o] then return end
    pts[#pts + 1] = { x, z }; ysum = ysum + y; feet[o] = true
  end)
  local nf = 0; for _ in pairs(feet) do nf = nf + 1 end
  local H = hull(pts)
  local mg = margin({ cx, cz }, H)
  local h = #pts > 0 and cy - ysum / #pts or 0
  out:write(string.format("%.4f|%d|%d|%.3f|%.3f|%.2f\n", N / 60, nf, #pts, mg, h, h > 0 and math.deg(math.atan(mg / h)) or 0))
  if N == 3699 then out:close() end
end)
