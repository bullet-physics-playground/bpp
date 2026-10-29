-- How much the body rocks, and how high the feet rise, while walking (stallprobe under it), WB_FROM to WB_TO s:
-- body pitch (nose up/down, along the walk) and roll (across) from its up axis, their spread and largest, pitch rate
-- rms; the body's up-down speed rms; each foot's highest bottom above the ground under it in each swing (off the
-- ground 0.15 s or more): mean and the top 10% of swings.
--   WB <name>|pitch sd .. max ..|roll sd .. max ..|pitch rate rms ..|body vy rms ..|swing peak mean .. top10 .. (n ..)
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
local feet, mine = {}, {}
for _, o in ipairs(w.bodies) do mine[o] = true; if w.madeBy[o] == "buildFoot" then feet[#feet + 1] = o end end
mine[cube] = true
local PI, RO, PR, VY, peaks = {}, {}, {}, {}, {}
local air, top, lastPitch = {}, {}, nil
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:preDraw(function(N) if hooks.preDraw then hooks.preDraw(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  if N < WB_FROM * 60 or N > WB_TO * 60 then return end
  local T = cube.body:getCenterOfMassTransform(); local Ti = T:inverse()
  local o = Ti:invXform(btVector3(0, 0, 0)); local u = Ti:invXform(btVector3(0, 1, 0))
  local ux, uz = u.x - o.x, u.z - o.z
  local pitch, roll = math.deg(math.asin(math.max(-1, math.min(1, ux)))), math.deg(math.asin(math.max(-1, math.min(1, uz))))
  PI[#PI + 1] = pitch; RO[#RO + 1] = roll; VY[#VY + 1] = cube.body:getLinearVelocity().y
  if lastPitch then PR[#PR + 1] = (pitch - lastPitch) * 60 end; lastPitch = pitch
  local touch = {}
  realv:eachContact(function(a, b) if mine[a] and not mine[b] then touch[a] = true elseif mine[b] and not mine[a] then touch[b] = true end end)
  for i, f in ipairs(feet) do
    local down = false; for q in pairs(touch) do if rawequal(q, f) then down = true end end
    if down then
      if air[i] and air[i] >= 9 and top[i] then peaks[#peaks + 1] = top[i] end
      air[i], top[i] = 0, nil
    else
      local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0); f.body:getAabb(lo, hi)
      local p = f.body:getCenterOfMassPosition()
      local h = lo.y - room.groundAt(p.x, p.z)
      air[i] = (air[i] or 0) + 1; top[i] = math.max(top[i] or -1e9, h)
    end
  end
  if N == WB_TO * 60 then
    local function sd(t) local m = 0; for _, x in ipairs(t) do m = m + x end; m = m / #t; local s = 0; for _, x in ipairs(t) do s = s + (x - m)^2 end; return math.sqrt(s / #t) end
    local function rms(t) local s = 0; for _, x in ipairs(t) do s = s + x * x end; return math.sqrt(s / #t) end
    local function amax(t) local s = 0; for _, x in ipairs(t) do s = math.max(s, math.abs(x)) end; return s end
    table.sort(peaks)
    local pm = 0; for _, x in ipairs(peaks) do pm = pm + x end; pm = #peaks > 0 and pm / #peaks or 0
    local t10 = 0; local k0 = math.floor(#peaks * 0.9) + 1; for k = k0, #peaks do t10 = t10 + peaks[k] end; t10 = (#peaks >= k0) and t10 / (#peaks - k0 + 1) or 0
    print(string.format("WB %s|pitch sd %.2f max %.2f|roll sd %.2f max %.2f|pitch rate rms %.1f|body vy rms %.2f|swing peak mean %.2f top10 %.2f (n %d)",
      w.spec.name, sd(PI), amax(PI), sd(RO), amax(RO), rms(PR), rms(VY), pm, t10, #peaks))
  end
end)
