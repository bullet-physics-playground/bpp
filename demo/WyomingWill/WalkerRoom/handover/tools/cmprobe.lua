-- The whole walker's centre of mass while it walks (stallprobe under it), each frame from CM_FROM to CM_TO s, in the
-- body's frame (x along the walk, + the way it walks; y up; z across) and against its feet: height above the lowest
-- foot's bottom, along-walk offset from the middle of its four feet and from the middle of the feet on the ground.
-- Mass by kind. At the end:
--   CM <name>|mass total ..|by kind ..|height over feet mean .. min .. max|x from feet middle mean .. range ..|
--     x from grounded feet mean ..|z mean ..|over body centre ..
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
local cube, f = w.cube, (w.forward or 1)
local parts, feet, mine, kinds = {}, {}, {}, {}
for _, o in ipairs(w.bodies) do mine[o] = true; parts[#parts + 1] = o; if w.madeBy[o] == "buildFoot" then feet[#feet + 1] = o end end
local seen = false; for _, o in ipairs(parts) do if rawequal(o, cube) then seen = true end end
if not seen then parts[#parts + 1] = cube end
local M = 0
for _, o in ipairs(parts) do
  local k = rawequal(o, cube) and "body" or (w.madeBy[o] or "?")
  local m = 1 / o.body:getInvMass(); M = M + m; kinds[k] = (kinds[k] or 0) + m
end
local H, X, XG, Z, Y = {}, {}, {}, {}, {}
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:preDraw(function(N) if hooks.preDraw then hooks.preDraw(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  if N < CM_FROM * 60 or N > CM_TO * 60 then return end
  local T = cube.body:getCenterOfMassTransform()
  local cx, cy, cz = 0, 0, 0
  for _, o in ipairs(parts) do
    local p = T:invXform(o.body:getCenterOfMassPosition()); local m = 1 / o.body:getInvMass()
    cx, cy, cz = cx + m * p.x, cy + m * p.y, cz + m * p.z
  end
  cx, cy, cz = f * cx / M, cy / M, cz / M
  local fy, fx, gx, gn = 1e9, 0, 0, 0
  local touch = {}
  realv:eachContact(function(a, b) if mine[a] and not mine[b] then touch[a] = true elseif mine[b] and not mine[a] then touch[b] = true end end)
  for _, o in ipairs(feet) do
    local p = T:invXform(o.body:getCenterOfMassPosition()); fy = math.min(fy, p.y); fx = fx + f * p.x
    for q in pairs(touch) do if rawequal(q, o) then gx, gn = gx + f * p.x, gn + 1 end end
  end
  H[#H + 1] = cy - fy; X[#X + 1] = cx - fx / #feet; Z[#Z + 1] = cz; Y[#Y + 1] = cy
  if gn > 0 then XG[#XG + 1] = cx - gx / gn end
  if N == CM_TO * 60 then
    local function mean(t) local s = 0; for _, x in ipairs(t) do s = s + x end; return s / #t end
    local function mn(t) local s = 1e9; for _, x in ipairs(t) do s = math.min(s, x) end; return s end
    local function mx(t) local s = -1e9; for _, x in ipairs(t) do s = math.max(s, x) end; return s end
    local ks = {}; for k, m in pairs(kinds) do ks[#ks + 1] = string.format("%s %.1f", k, m) end; table.sort(ks)
    print(string.format("CM %s|mass total %.1f|by kind %s|height over feet mean %.2f min %.2f max %.2f|x from feet middle mean %+.2f range %+.2f..%+.2f|x from grounded feet mean %+.2f|z mean %+.2f|over body centre %+.2f",
      w.spec.name, M, table.concat(ks, ", "), mean(H), mn(H), mx(H), mean(X), mn(X), mx(X), mean(XG), mean(Z), mean(Y)))
  end
end)
