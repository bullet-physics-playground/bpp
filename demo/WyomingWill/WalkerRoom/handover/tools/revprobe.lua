-- Why cranks turn backwards: each frame from RV_FROM to RV_TO s, for each foot, the crank nearest it (in the body's
-- frame, at the start), that crank's angle and spin relative to the body, the foot's x in the body's frame, and whether
-- the foot touches the ground (stallprobe under it).
--   R <t>|foot <i>|crank <j>|ang <deg>|spin <deg/s>|x <cm>|y <cm>|ground <0/1>
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
local cranks, feet, mine = {}, {}, {}
local b = w.parts
if b.legs then for _, lg in ipairs(b.legs) do cranks[#cranks + 1] = lg.crank end
else for i = 1, 4 do local lk = b["linkage" .. i]; if lk and lk.crank then cranks[#cranks + 1] = lk.crank end end end
for _, o in ipairs(w.bodies) do mine[o] = true; if w.madeBy[o] == "buildFoot" then feet[#feet + 1] = o end end
local function loc(o) return cube.body:getCenterOfMassTransform():invXform(o.body:getCenterOfMassPosition()) end
local map = {}   -- foot i -> its own crank: Spears-type files name foot<k> with linkage<k>; leg-list files (Jansen,
-- Klann): the leg whose foot point (footRod's footPivot, in the world) is nearest the foot
local wp = {}
if b.legs then for j, lg in ipairs(b.legs) do wp[j] = lg.footRod.body:getCenterOfMassTransform():inverse():invXform(lg.footPivot) end end
for i, f in ipairs(feet) do
  if b.legs then
    local pf, best = f.body:getCenterOfMassPosition(), 1e9
    for j, p in ipairs(wp) do local d = (pf.x - p.x) ^ 2 + (pf.y - p.y) ^ 2 + (pf.z - p.z) ^ 2; if d < best then best, map[i] = d, j end end
  else
    for k = 1, 4 do if b["foot" .. k] and rawequal(b["foot" .. k], f) then map[i] = k end end
  end
  assert(map[i], "no crank for foot " .. i)
end
-- the foot's point fixed in its leg bar (the ankle springs let the pad itself rock): the pad's centre at the start, in
-- the bar's frame (footRod for leg-list files, the pendant for Spears-type files)
local bar, pin = {}, {}
for i, f in ipairs(feet) do
  local lk = b.legs and b.legs[map[i]] or b["linkage" .. map[i]]
  bar[i] = lk.footRod or lk.pendant
  pin[i] = bar[i].body:getCenterOfMassTransform():invXform(f.body:getCenterOfMassPosition())
end
local function ang(c)   -- the crank's turn about the body's z axis: its own x axis seen in the body's frame
  local Tc, Tb = c.body:getCenterOfMassTransform(), cube.body:getCenterOfMassTransform()
  local o = Tb:invXform(Tc:inverse():invXform(btVector3(0, 0, 0)))
  local e = Tb:invXform(Tc:inverse():invXform(btVector3(1, 0, 0)))
  return math.deg(math.atan2(e.y - o.y, e.x - o.x))
end
local out = io.open(RV_OUT, "w")
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:preDraw(function(N) if hooks.preDraw then hooks.preDraw(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  if N < RV_FROM * 60 or N > RV_TO * 60 then return end
  local touch = {}
  realv:eachContact(function(a, bb) if mine[a] and not mine[bb] then touch[a] = true elseif mine[bb] and not mine[a] then touch[bb] = true end end)
  local wc = cube.body:getAngularVelocity()
  for i, f in ipairs(feet) do
    local c = cranks[map[i]]
    local p = cube.body:getCenterOfMassTransform():invXform(bar[i].body:getCenterOfMassTransform():inverse():invXform(pin[i]))
    local s = c.body:getAngularVelocity() - wc
    local g = 0; for o in pairs(touch) do if rawequal(o, f) then g = 1 end end
    out:write(string.format("R %.4f|foot %d|crank %d|ang %.2f|spin %.1f|x %.3f|y %.3f|ground %d\n", N / 60, i, map[i], ang(c), math.deg(s.z), p.x, p.y, g))
  end
  if N == RV_TO * 60 then out:close() end
end)
