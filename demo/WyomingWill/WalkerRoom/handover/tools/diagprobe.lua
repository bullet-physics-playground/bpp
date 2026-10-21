-- Test track, plus a diagnosis of why a walker slows or sticks:
--   TILT   largest pitch and roll (deg)
--   CRANK  crank turns made against wanted; seconds with the cranks nearly stopped
--   WELD   how far the brace welds give: largest and mean drift of each welded
--          pair from its start (cm, deg)
--   SELF   share of frames the walker's own parts touch (not through a joint), by pair
--   GROUND share of frames each non-foot part touches the ground, by part
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile("test-track.lua")
v = realv
local w = room.walkers[1]
local name = w.spec.name
local mine = {}
for _, o in ipairs(w.bodies) do mine[o] = w.madeBy[o] or "body" end
mine[w.cube] = "body"
local deco = {}
for _, d in ipairs(w.decor or {}) do deco[#deco + 1] = d.o end
for _, t in ipairs(w.tips or {}) do deco[#deco + 1] = t.o or t end
local function isDeco(o) for _, q in ipairs(deco) do if rawequal(q, o) then return true end end return false end
local function kind(o) for q, k in pairs(mine) do if rawequal(q, o) then return k end end end
-- welds: the 6-dof joints the room recorded (the diag bars' welds)
local welds = {}
for _, j in ipairs(w.joints or {}) do
  if j[5] == "btGeneric6DofConstraint" and j[2] then welds[#welds + 1] = { a = j[1], b = j[2] } end
end
local function rel(wd)
  local ta, tb = wd.a:getCenterOfMassTransform(), wd.b:getCenterOfMassTransform()
  local p = ta:invXform(wd.b:getCenterOfMassPosition())
  local qa, qb = ta:getRotation(), tb:getRotation()
  -- qa^-1 * qb
  local ax, ay, az, aw = -qa:x(), -qa:y(), -qa:z(), qa:w()
  local bx, by, bz, bw = qb:x(), qb:y(), qb:z(), qb:w()
  return p.x, p.y, p.z, { aw*bx + ax*bw + ay*bz - az*by, aw*by - ax*bz + ay*bw + az*bx, aw*bz + ax*by - ay*bx + az*bw, aw*bw - ax*bx - ay*by - az*bz }
end
local frames, pmax, rmax, slow, run0 = 0, 0, 0, 0, nil
local selfT, selfAny, groundT = {}, 0, {}
local dmax, dsum, amax, asum, dn = 0, 0, 0, 0, 0
local q0 = w.cube.body:getCenterOfMassTransform():getRotation()
for _, m in ipairs(w.motors) do m.dgLast = m.hinge:getHingeAngle(); m.dgTurn = 0 end
local turnsAt = {}
realv:preSim(function(N) hooks.preSim(N) end)
realv:postSim(function(N)
  hooks.postSim(N)
  if N < 120 then return end
  if N == 120 then
    for _, wd in ipairs(welds) do wd.x, wd.y, wd.z, wd.q = rel(wd) end
    frameRel = {}
    for _, o in ipairs(w.bodies) do
      if not rawequal(o, w.cube) and o.mass > 0 then
        local wd = { a = w.cube.body, b = o.body }; local x, y, z, q = rel(wd)
        frameRel[#frameRel + 1] = { wd = wd, q = q, k = w.madeBy[o] or "?", max = 0, sum = 0 }
      end
    end
  end
  for _, f in ipairs(frameRel) do
    local _, _, _, r = rel(f.wd)
    local dot = math.abs(r[1]*f.q[1] + r[2]*f.q[2] + r[3]*f.q[3] + r[4]*f.q[4])
    local ang = math.deg(2 * math.acos(math.min(1, dot)))
    f.max = math.max(f.max, ang); f.sum = f.sum + ang
  end
  frames = frames + 1
  -- tilt (as standprobe/tiltprobe: body axes' height components)
  local q = w.cube.body:getCenterOfMassTransform():getRotation()
  local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
  local fy = 2 * (qx * qy + qw * qz)
  local sy = 2 * (qy * qz - qw * qx)
  pmax = math.max(pmax, math.abs(math.deg(math.asin(math.max(-1, math.min(1, fy))))))
  rmax = math.max(rmax, math.abs(math.deg(math.asin(math.max(-1, math.min(1, sy))))))
  -- cranks
  local tot = 0
  for _, m in ipairs(w.motors) do
    local a = m.hinge:getHingeAngle(); local d = a - m.dgLast
    if d > math.pi then d = d - 2 * math.pi elseif d < -math.pi then d = d + 2 * math.pi end
    m.dgTurn = m.dgTurn + math.abs(d); m.dgLast = a; tot = tot + m.dgTurn
  end
  turnsAt[N] = tot / #w.motors
  if N >= 150 and turnsAt[N - 30] and (turnsAt[N] - turnsAt[N - 30]) < 0.1 * math.abs(w.crank) * 0.5 then slow = slow + 1 end
  -- welds
  for _, wd in ipairs(welds) do
    local x, y, z, r = rel(wd)
    local d = math.sqrt((x - wd.x)^2 + (y - wd.y)^2 + (z - wd.z)^2)
    local dot = math.abs(r[1]*wd.q[1] + r[2]*wd.q[2] + r[3]*wd.q[3] + r[4]*wd.q[4])
    local ang = math.deg(2 * math.acos(math.min(1, dot)))
    dmax = math.max(dmax, d); amax = math.max(amax, ang); dsum = dsum + d; asum = asum + ang; dn = dn + 1
  end
  -- contacts
  local sf, gf = {}, {}
  realv:eachContact(function(a, b, x, y, z, nx, ny, nz, d, im)
    if d > 0.01 then return end
    local ka, kb = kind(a), kind(b)
    if ka and kb then
      local key = ka < kb and (ka .. "-" .. kb) or (kb .. "-" .. ka); sf[key] = true
    elseif ka and not kb and not isDeco(b) and not isDeco(a) and ka ~= "buildFoot" then gf[ka] = true
    elseif kb and not ka and not isDeco(a) and not isDeco(b) and kb ~= "buildFoot" then gf[kb] = true end
  end)
  local any = false
  for k in pairs(sf) do selfT[k] = (selfT[k] or 0) + 1; any = true end
  if any then selfAny = selfAny + 1 end
  for k in pairs(gf) do groundT[k] = (groundT[k] or 0) + 1 end
  if N == 3699 then
    local function list(t) local r = {} for k, n in pairs(t) do r[#r + 1] = string.format("%s %.1f%%", k, 100 * n / frames) end table.sort(r) return table.concat(r, ", ") end
    print(string.format("TILT %s|pitch max %.1f|roll max %.1f", name, pmax, rmax))
    print(string.format("CRANK %s|turns %.1f|wanted %.1f|nearly stopped %.1f s", name, turnsAt[N] / (2 * math.pi), math.abs(w.crank) * frames / 60 / (2 * math.pi), slow / 60))
    print(string.format("WELD %s|%d welds|drift max %.3f cm, mean %.4f cm|angle max %.2f, mean %.3f deg", name, #welds, dmax, dn > 0 and dsum / dn or 0, amax, dn > 0 and asum / dn or 0))
    print(string.format("SELF %s|any %.1f%%|%s", name, 100 * selfAny / frames, list(selfT)))
    print(string.format("GROUND %s|%s", name, list(groundT)))
    table.sort(frameRel, function(x, y) return x.sum < y.sum end)
    local r = {}
    for i = 1, math.min(8, #frameRel) do r[#r + 1] = string.format("%s %.2f/%.1f", frameRel[i].k, frameRel[i].sum / frames, frameRel[i].max) end
    print(string.format("FRAME %s|parts turning least against the body, mean/max deg|%s", name, table.concat(r, ", ")))
  end
end)
