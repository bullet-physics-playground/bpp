-- Where the force goes (stallprobe under it), each frame from FP_FROM to FP_TO s:
--   P <t>|pitch <deg, front up +>|vy <cm/s>|cranks <deg/s each, as driven: + = the way the motor turns them>|target <deg/s>
--   F <t>|<kind>|<F/B><L/R>|fx <N-ish>|fy|n <contacts>   ground force on that part (sum over its contacts: impulse x
--     normal / FIXED; units mass x cm/s^2; fx along the walk +, fy up), F/B by the part's x in the body frame, L/R by z
-- WEIGHT line at the start: the walker's weight (mass x GRAVITY), for scale.
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
local FROM, TO = FP_FROM * 60, FP_TO * 60
local out = io.open(FP_OUT, "w")
local mine, kind = {}, {}
for _, o in ipairs(w.bodies) do mine[#mine + 1] = o; kind[o] = w.madeBy[o] or "?" end
mine[#mine + 1] = cube; kind[cube] = "body"
local function find(o) for _, q in ipairs(mine) do if rawequal(q, o) then return q end end end
out:write(string.format("WEIGHT %.1f|motors %d\n", w.totalMass * GRAVITY, #w.motors))
-- the walk's direction in the world: the body's local +x or -x (forward = spec.forward)
local fwdSign = (w.spec and w.spec.forward) or 1
local last = {}
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:preDraw(function(N) if hooks.preDraw then hooks.preDraw(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  local rates, tg = {}, 0
  for i, m in ipairs(w.motors) do
    local a = m.hinge:getHingeAngle()
    if last[i] then
      local d = a - last[i]; d = d - 2 * math.pi * math.floor(d / (2 * math.pi) + 0.5)
      rates[i] = string.format("%.0f", math.deg(d) * 60 * m.sign)
    end
    last[i] = a; tg = math.deg(math.abs(m.speed))
  end
  if N < FROM or N > TO then return end
  local t = N / 60
  local T = cube.body:getCenterOfMassTransform(); local Ti = T:inverse()
  local c0 = cube.body:getCenterOfMassPosition()
  local ax = Ti:invXform(btVector3(fwdSign, 0, 0))   -- the body's forward axis in the world
  local fx, fy = ax.x - c0.x, ax.y - c0.y
  local walk = (fx >= 0) and 1 or -1                  -- (the track walks along world x)
  out:write(string.format("P %.4f|pitch %.2f|vy %.1f|cranks %s|target %.0f\n", t,
    math.deg(math.atan2(fy, math.abs(fx))), cube.body:getLinearVelocity().y, table.concat(rates, " "), tg))
  local acc = {}
  realv:eachContact(function(a, b, x, y, z, nx, ny, nz, d, imp)
    local pa, pb = find(a), find(b)
    if (pa and pb) or not (pa or pb) then return end
    local p = pa or pb
    local s = pa and 1 or -1                         -- (Bullet's normal is on b, pointing to a: force on a is +n, on b -n)
    local lp = T:invXform(btVector3(x, y, z))
    local key = kind[p] .. "|" .. ((lp.x * fwdSign > 0) and "F" or "B") .. ((lp.z > 0) and "L" or "R")
    local e = acc[key] or { 0, 0, 0 }
    local f = (imp or 0) / FIXED
    e[1] = e[1] + s * nx * f * walk; e[2] = e[2] + s * ny * f; e[3] = e[3] + 1
    acc[key] = e
  end)
  for k, e in pairs(acc) do out:write(string.format("F %.4f|%s|fx %.0f|fy %.0f|n %d\n", t, k, e[1], e[2], e[3])) end
  -- each foot: where it is and how it moves relative to the body (in the body's frame: along the walk +, up +), cm, cm/s
  local bv, bw = cube.body:getLinearVelocity(), cube.body:getAngularVelocity()
  for _, o in ipairs(mine) do
    if kind[o] == "buildFoot" then
      local p = o.body:getCenterOfMassPosition(); local fv = o.body:getLinearVelocity()
      local r = { p.x - c0.x, p.y - c0.y, p.z - c0.z }
      local rel = btVector3(fv.x - (bv.x + bw.y * r[3] - bw.z * r[2]), fv.y - (bv.y + bw.z * r[1] - bw.x * r[3]), fv.z - (bv.z + bw.x * r[2] - bw.y * r[1]))
      local lp = T:invXform(p)
      local lv = T:invXform(btVector3(c0.x + rel.x, c0.y + rel.y, c0.z + rel.z))
      out:write(string.format("V %.4f|%s%s|x %.2f|y %.2f|vx %.1f|vy %.1f\n", t, (lp.x * fwdSign > 0) and "F" or "B", (lp.z > 0) and "L" or "R",
        lp.x * fwdSign, lp.y, lv.x * fwdSign, lv.y))
    end
  end
  if N == TO then out:close() end
end)
