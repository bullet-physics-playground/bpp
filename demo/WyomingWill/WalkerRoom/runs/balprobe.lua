-- Balance as built (14 November; handover section 7, "Balance"), for runs/balance.sh: the walker held 200 cm up, its
-- body still, cranked at its gait until every crank has turned once; at every third step the whole walker's centre of
-- mass (every body: the body's load, links, feet, braces) and its feet's centres, relative to the body's centre of
-- mass (x along the track, z across). At the end, one line:
--   BAL <name>|along <cm>|across <cm>|across held <cm>|mass <total>|braces <mass>|feet|samples|com|mids|turned <deg>
-- along: the centre of mass, averaged over the turn, from the middle of the feet's path middles (BALANCE's target,
-- as handover/tools/balance.py measures it, but with every body, braces too); across: from the middle of the feet,
-- side to side, as built; across held: the same averaged over the turn in the air (legs sag out of their planes);
-- braces: the mass of bodies that are not links, feet or the body; turned: each crank's turn in the window (under
-- 360: it stalled in the air and along is void -- Chebyshev-Spears lift 62 diag's cranks 1 and 4 do, as built).
-- BAL_T0 (s, default 4): when the window starts. BAL_KINDS (env): list each body's maker and mass.
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile("lib/test-track.lua")
v = realv
local w = room.walkers[1]
for _, o in ipairs(w.bodies) do
  local b = o.body
  local t = b:getCenterOfMassTransform(); local p = b:getCenterOfMassPosition()
  local nt = btTransform(t:getRotation(), btVector3(p.x, p.y + 200, p.z))
  b:setCenterOfMassTransform(nt); o.trans = nt
end
w.cube.body:setLinearFactor(btVector3(0, 0, 0)); w.cube.body:setAngularFactor(0)
setVelXYZ(w.cube, 0, 0, 0); setAngVelXYZ(w.cube, 0, 0, 0)
local feet, mass, other = {}, 0, 0
for _, o in ipairs(w.bodies) do
  if o.mass > 0 then
    mass = mass + o.mass
    local k = w.madeBy and w.madeBy[o]
    if k == "buildFoot" then feet[#feet + 1] = { o = o, lo = 1e9, hi = -1e9, z = 0 } end
    if k ~= "makeLink" and k ~= "buildFoot" and k ~= "bodyFrame" and not rawequal(o, w.cube) then other = other + o.mass end
    if os.getenv("BAL_KINDS") then print(string.format("KIND %s %.3f", tostring(k), o.mass)) end
  end
end
-- across, as built (before a step: once the sim runs, the legs held in the air sag out of their planes by up to a
-- cm, varying over the turn, which swamps what the braces do); links and braces keep their planes, so it holds
-- for the whole turn
local function across()
  local c0 = w.cube.body:getCenterOfMassPosition()
  local mz, fz = 0, 0
  for _, o in ipairs(w.bodies) do if o.mass > 0 then mz = mz + o.mass * (o.body:getCenterOfMassPosition().z - c0.z) end end
  for _, f in ipairs(feet) do fz = fz + f.o.body:getCenterOfMassPosition().z - c0.z end
  return mz / mass - fz / #feet
end
local built = across()
local T0 = (BAL_T0 or 4) * 60
local TMAX = T0 + 30 * 60   -- (a crank that stalls in the air: the window runs on until every crank has turned once)
local sx, sz, n = 0, 0, 0
local done
local turned, lastA = {}, {}   -- (each crank's angle turned in the window: a whole turn, or the sweep is void)
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  local whole = #w.motors > 0
  for i in ipairs(w.motors) do if math.abs(turned[i] or 0) < 2 * math.pi then whole = false end end
  if N >= T0 and not whole and N < TMAX and N % 3 == 0 then
    local c0 = w.cube.body:getCenterOfMassPosition()
    local mx, mz = 0, 0
    for _, o in ipairs(w.bodies) do
      if o.mass > 0 then local p = o.body:getCenterOfMassPosition(); mx = mx + o.mass * (p.x - c0.x); mz = mz + o.mass * (p.z - c0.z) end
    end
    for i, m in ipairs(w.motors) do
      local a = m.hinge:getHingeAngle()
      if lastA[i] then local d = a - lastA[i]; d = d - 2 * math.pi * math.floor(d / (2 * math.pi) + 0.5); turned[i] = (turned[i] or 0) + d end
      lastA[i] = a
    end
    sx, sz, n = sx + mx / mass, sz + mz / mass, n + 1
    for _, f in ipairs(feet) do
      local p = f.o.body:getCenterOfMassPosition()
      f.lo, f.hi, f.z = math.min(f.lo, p.x - c0.x), math.max(f.hi, p.x - c0.x), f.z + (p.z - c0.z)
    end
  end
  if N >= T0 and (whole or N >= TMAX) and not done then
    done = true
    local ax, az = 0, 0
    for _, f in ipairs(feet) do ax = ax + (f.lo + f.hi) / 2; az = az + f.z / n end
    ax, az = ax / #feet, az / #feet
    print(string.format("BAL %s|along %+.3f|across %+.3f|across held %+.3f|mass %.2f|braces %.2f|feet %d|samples %d|com %.3f|mids %s|turned %s",
      w.spec.name, sx / n - ax, built, sz / n - az, mass, other, #feet, n, sx / n, (function() local t = {} for _, f in ipairs(feet) do t[#t + 1] = string.format("%.2f(%.2f..%.2f)", (f.lo + f.hi) / 2, f.lo, f.hi) end return table.concat(t, " ") end)(), (function() local t = {} for i in ipairs(w.motors) do t[#t + 1] = string.format("%.0f", math.deg(turned[i] or 0)) end return table.concat(t, " ") end)()))
    os.exit(0)
  end
end)
