-- Test track, plus one STALL line a second (time s): x, z (cm from start), heading,
-- pitch, roll (deg), crank turns that second, feet down (which: F/B front/back by
-- body x, L/R by body z, as built), how fast the feet in contact slide (cm/s,
-- across the ground), and which non-foot parts touched the ground (share of frames).
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
-- GUIDES_FOR_BRACES = true (a test): a diag build's braces taken out (bodies and welds),
-- each leg's pendant instead held at its angle to the body as the guides hold them, and
-- its motors set as if it weighed what it does without the braces (motor strength goes
-- with total weight). What is left differs from its guides cousin only in its own build file.
if GUIDES_FOR_BRACES then
  local braces, isBrace, bmass = {}, {}, 0
  for _, o in ipairs(w.bodies) do
    if (w.madeBy[o] or ""):find("Crossbar") then braces[#braces + 1] = o; isBrace[o.body] = true; bmass = bmass + o.mass end
  end
  local function objOf(b) for _, o in ipairs(w.bodies) do if o.body == b then return o end end end
  local function braceBody(b) for _, o in ipairs(braces) do if o.body == b then return true end end return false end
  -- (the pendants: the links the feet are hinged to)
  local function footBody(b) for _, o in ipairs(w.bodies) do if o.body == b and w.madeBy[o] == "buildFoot" then return true end end return false end
  local pend = {}
  for _, j in ipairs(w.joints or {}) do
    if j[5] == "btHingeConstraint" and j[2] then
      local a, b = footBody(j[1]), footBody(j[2])
      if a ~= b then local o = objOf(a and j[2] or j[1]); if o then pend[o] = true end end
    end
  end
  -- DEAD_WEIGHT = true (with GUIDES_FOR_BRACES): each brace replaced by a copy with its mass, turning
  -- inertia, place and orientation, fixed rigidly to the body and touching nothing -- the braces'
  -- weight where it was, without the braces joining the legs. DEAD_DROP (cm): the copies that far lower.
  local dead = {}
  if DEAD_WEIGHT then
    local cubeT0 = w.cube.body:getCenterOfMassTransform()
    for _, o in ipairs(braces) do
      local inv = o.body:getInvInertiaDiagLocal()
      local bp = o.body:getCenterOfMassPosition()
      local fr = DEAD_FRACTION or 1   -- (DEAD_FRACTION: the copies weigh this share of the braces)
      dead[#dead + 1] = { bp = { bp.x, bp.y, bp.z }, m = o.mass * fr, I = btVector3(fr / inv.x, fr / inv.y, fr / inv.z), rel = cubeT0:inverseTimes(o.body:getCenterOfMassTransform()) }
    end
  end
  for _, o in ipairs(braces) do realv:remove(o) end
  local function qmul(a, b)   -- (Hamilton product of btQuaternions)
    local ax, ay, az, aw = a:x(), a:y(), a:z(), a:w()
    local bx, by, bz, bw = b:x(), b:y(), b:z(), b:w()
    return btQuaternion(aw*bx + ax*bw + ay*bz - az*by, aw*by - ax*bz + ay*bw + az*bx, aw*bz + ax*by - ay*bx + az*bw, aw*bw - ax*bx - ay*by - az*bz)
  end
  for _, d in ipairs(dead) do
    local cubeT = w.cube.body:getCenterOfMassTransform()
    local relP = d.rel:inverse():invXform(btVector3(0, 0, 0))   -- (its place in the body's frame)
    local wp = cubeT:inverse():invXform(relP)                    -- (in the world)
    local tt = btTransform(qmul(cubeT:getRotation(), d.rel:getRotation()), btVector3(wp.x, wp.y - (DEAD_DROP or 0), wp.z))
    local c = Cube(0.5, 0.5, 0.5, d.m)
    c.trans = tt
    realv:add(c)
    c.body:setCenterOfMassTransform(tt)
    c.body:setMassProps(d.m, d.I); c.body:updateInertiaTensor()
    c.body:setCollisionFlags(c.body:getCollisionFlags() + 4)
    c.body:setActivationState(4)
    local fx = btGeneric6DofConstraint(w.cube.body, c.body, cubeT:inverseTimes(tt), btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0)), true)
    fx:setLinearLowerLimit(btVector3(0, 0, 0)); fx:setLinearUpperLimit(btVector3(0, 0, 0))
    fx:setAngularLowerLimit(btVector3(0, 0, 0)); fx:setAngularUpperLimit(btVector3(0, 0, 0))
    if SOLVER_ITERATIONS then fx:setOverrideNumSolverIterations(SOLVER_ITERATIONS) end
    realv:addConstraint(fx)
    d.obj = c
    local cp = c.body:getCenterOfMassPosition()
    d.off = math.sqrt((cp.x - d.bp[1])^2 + (cp.y + (DEAD_DROP or 0) - d.bp[2])^2 + (cp.z - d.bp[3])^2)
  end
  DEAD_OBJS = dead
  if DEAD_WEIGHT then local mo = 0; for _, d in ipairs(dead) do mo = math.max(mo, d.off) end; print(string.format("DEAD %d copies, %.1f mass, dropped %.1f cm, placed within %.4f cm", #dead, bmass * (DEAD_FRACTION or 1), DEAD_DROP or 0, mo)) end
  local keep = {}
  for _, o in ipairs(w.bodies) do local br = false; for _, q in ipairs(braces) do if rawequal(q, o) then br = true end end; if not br then keep[#keep + 1] = o end end
  w.bodies = keep
  local ng, cubeT = 0, w.cube.body:getCenterOfMassTransform()
  for o in pairs(pend) do
    local g = btGeneric6DofConstraint(w.cube.body, o.body, cubeT:inverseTimes(o.body:getCenterOfMassTransform()),
                                      btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0)), true)
    g:setLinearLowerLimit(btVector3(1, 1, 1)); g:setLinearUpperLimit(btVector3(-1, -1, -1))
    g:setAngularLowerLimit(btVector3(0, 0, 0)); g:setAngularUpperLimit(btVector3(0, 0, 0))
    if SOLVER_ITERATIONS then g:setOverrideNumSolverIterations(SOLVER_ITERATIONS) end
    realv:addConstraint(g); ng = ng + 1
  end
  local f = DEAD_WEIGHT and (w.totalMass - bmass * (1 - (DEAD_FRACTION or 1))) / w.totalMass or (w.totalMass - bmass) / w.totalMass
  for _, m in ipairs(w.motors) do m.impulse = m.impulse * f; m.hinge:enableAngularMotor(true, m.speed, m.impulse) end
  print(string.format("SWAP %d brace pieces out (%.1f mass), %d pendants guided, motors x %.3f, mass now %.1f", #braces, bmass, ng, f, w.totalMass - bmass))
end
-- EXTRA_BLOCKS = { {m, x, y, z}, ... } (a test): blocks of mass m fixed rigidly to the body at (x, y, z) cm in its
-- own frame (x along the walk, y up, z across, from its centre), touching nothing; motors raised for the
-- walker's new weight, as the room would. Each block's drift from its place is measured (BLOCKS line).
if EXTRA_BLOCKS then
  local cubeT = w.cube.body:getCenterOfMassTransform()
  local add = 0
  EXTRA_LIST = {}
  for _, b in ipairs(EXTRA_BLOCKS) do
    local rel = btVector3(b[2], b[3], b[4])
    local wp = cubeT:inverse():invXform(rel)
    local tt = btTransform(cubeT:getRotation(), btVector3(wp.x, wp.y, wp.z))
    local c = Cube(0.5, 0.5, 0.5, b[1])
    c.trans = tt
    realv:add(c)
    c.body:setCenterOfMassTransform(tt)
    c.body:setCollisionFlags(c.body:getCollisionFlags() + 4)
    c.body:setActivationState(4)
    local fx = btGeneric6DofConstraint(w.cube.body, c.body, btTransform(btQuaternion(0, 0, 0, 1), rel), btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0)), true)
    fx:setLinearLowerLimit(btVector3(0, 0, 0)); fx:setLinearUpperLimit(btVector3(0, 0, 0))
    fx:setAngularLowerLimit(btVector3(0, 0, 0)); fx:setAngularUpperLimit(btVector3(0, 0, 0))
    if SOLVER_ITERATIONS then fx:setOverrideNumSolverIterations(SOLVER_ITERATIONS) end
    realv:addConstraint(fx)
    EXTRA_LIST[#EXTRA_LIST + 1] = { c = c, rel = rel, max = 0 }
    add = add + b[1]
  end
  local f = (w.totalMass + add) / w.totalMass
  for _, m in ipairs(w.motors) do m.impulse = m.impulse * f; m.hinge:enableAngularMotor(true, m.speed, m.impulse) end
  print(string.format("BLOCKS %d blocks, %.1f added, mass now %.1f, motors x %.3f", #EXTRA_BLOCKS, add, w.totalMass + add, f))
end
-- EXTRA_WEIGHT = m (a test): that much more weight fixed rigidly at the body's centre of mass
-- (a small block touching nothing), and the motors raised as the room would for a walker that heavy.
if EXTRA_WEIGHT then
  local cubeT = w.cube.body:getCenterOfMassTransform()
  -- (EXTRA_DROP, cm: the block that far below the body's centre, along the body's own up)
  local drop = EXTRA_DROP or 0
  local wp = cubeT:inverse():invXform(btVector3(0, -drop, 0))
  local tt = btTransform(cubeT:getRotation(), btVector3(wp.x, wp.y, wp.z))
  local c = Cube(0.5, 0.5, 0.5, EXTRA_WEIGHT)
  c.trans = tt
  realv:add(c)
  c.body:setCenterOfMassTransform(tt)
  EXTRA_BLOCK = { c = c, rel = btVector3(0, -drop, 0) }
  c.body:setCollisionFlags(c.body:getCollisionFlags() + 4)
  c.body:setActivationState(4)
  local fx = btGeneric6DofConstraint(w.cube.body, c.body, btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, -drop, 0)), btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0)), true)
  fx:setLinearLowerLimit(btVector3(0, 0, 0)); fx:setLinearUpperLimit(btVector3(0, 0, 0))
  fx:setAngularLowerLimit(btVector3(0, 0, 0)); fx:setAngularUpperLimit(btVector3(0, 0, 0))
  if SOLVER_ITERATIONS then fx:setOverrideNumSolverIterations(SOLVER_ITERATIONS) end
  realv:addConstraint(fx)
  local f = (w.totalMass + EXTRA_WEIGHT) / w.totalMass
  for _, m in ipairs(w.motors) do m.impulse = m.impulse * f; m.hinge:enableAngularMotor(true, m.speed, m.impulse) end
  print(string.format("EXTRA %.1f, %.1f cm below the body's centre, mass now %.1f, motors x %.3f", EXTRA_WEIGHT, drop, w.totalMass + EXTRA_WEIGHT, f))
end
-- GHOST_BRACES = true (a test): the low brace's pieces (DIAG_LOW) touch nothing -- the ground and the
-- walker's own parts pass through them -- but keep their weight and their welds to the legs.
if GHOST_BRACES or GHOST_ALL then   -- (GHOST_ALL: every brace, not just the low one)
  local n = 0
  for _, o in ipairs(w.bodies) do
    if w.madeBy[o] == "buildLowCrossbar" or (GHOST_ALL and (w.madeBy[o] or ""):find("Crossbar")) then o.body:setCollisionFlags(o.body:getCollisionFlags() + 4); n = n + 1 end
  end
  print("GHOST " .. n .. " brace pieces touch nothing")
end
-- MASS_SCALE = f (a test): every part of the walker (body, links, pendants, feet, braces) weighs f times as
-- much, its turning inertia scaled the same -- the weight spread exactly as before -- and the motors scaled
-- by f too. (Scale the ankle springs with ANKLE_SPRING to keep every force in proportion.)
if MASS_SCALE then
  local all = { w.cube }
  for _, o in ipairs(w.bodies) do if not rawequal(o, w.cube) then all[#all + 1] = o end end
  local before, after, n = 0, 0, 0
  for _, o in ipairs(all) do
    local im = o.body:getInvMass()
    if im > 0 then
      local m = 1 / im
      local inv = o.body:getInvInertiaDiagLocal()
      local f = MASS_SCALE
      o.body:setMassProps(m * f, btVector3(inv.x > 0 and f / inv.x or 0, inv.y > 0 and f / inv.y or 0, inv.z > 0 and f / inv.z or 0))
      o.body:updateInertiaTensor()
      -- (not o.mass = ...: in bpp that works the inertia out again from the part's shape, undoing the line above)
      before = before + m; after = after + m * f; n = n + 1
    end
  end
  for _, m in ipairs(w.motors) do m.impulse = m.impulse * MASS_SCALE; m.hinge:enableAngularMotor(true, m.speed, m.impulse) end
  w.totalMass = w.totalMass * MASS_SCALE
  print(string.format("MSCALE %d parts x %.3f: %.1f -> %.1f, motors x %.3f", n, MASS_SCALE, before, after, MASS_SCALE))
end
-- PENDANT_MASS = m (a test): each pendant (the link a foot hangs from) reweighed to m, its turning
-- inertia scaled the same, and the motors set for the walker's new total weight (as the room does).
if PENDANT_MASS then
  local function isFoot(b) for _, o in ipairs(w.bodies) do if o.body == b and w.madeBy[o] == "buildFoot" then return true end end return false end
  local function objOf(b) for _, o in ipairs(w.bodies) do if o.body == b then return o end end end
  local pend, dm, n = {}, 0, 0
  for _, j in ipairs(w.joints or {}) do
    if j[5] == "btHingeConstraint" and j[2] then
      local a, b = isFoot(j[1]), isFoot(j[2])
      if a ~= b then local o = objOf(a and j[2] or j[1]); if o then pend[o] = true end end
    end
  end
  local was = {}
  for o in pairs(pend) do
    local inv, f = o.body:getInvInertiaDiagLocal(), PENDANT_MASS / o.mass
    was[#was + 1] = string.format("%.2f", o.mass)
    o.body:setMassProps(PENDANT_MASS, btVector3(f / inv.x, f / inv.y, f / inv.z)); o.body:updateInertiaTensor()
    o.mass = PENDANT_MASS
    dm = dm + PENDANT_MASS - tonumber(was[#was]); n = n + 1   -- (o.mass reads back the new mass once set, so the old one is taken from was)
  end
  local f = (w.totalMass + dm) / w.totalMass
  for _, m in ipairs(w.motors) do m.impulse = m.impulse * f; m.hinge:enableAngularMotor(true, m.speed, m.impulse) end
  w.totalMass = w.totalMass + dm
  print(string.format("PMASS %d pendants %s -> %.2f each, mass now %.1f, motors x %.3f", n, table.concat(was, " "), PENDANT_MASS, w.totalMass, f))
end
-- PENDANT_GUIDES = true (a test): the braces kept as built, and each leg's pendant (the link its foot
-- hangs from) also held at its angle to the body, free to move -- as a rigid build's braces would hold
-- it, without the give of the long chain of joints between them.
if PENDANT_GUIDES then
  local function isFoot(b) for _, o in ipairs(w.bodies) do if o.body == b and w.madeBy[o] == "buildFoot" then return true end end return false end
  local function objOf(b) for _, o in ipairs(w.bodies) do if o.body == b then return o end end end
  local pend, n = {}, 0
  for _, j in ipairs(w.joints or {}) do
    if j[5] == "btHingeConstraint" and j[2] then
      local a, b = isFoot(j[1]), isFoot(j[2])
      if a ~= b then local o = objOf(a and j[2] or j[1]); if o then pend[o] = true end end
    end
  end
  local cubeT = w.cube.body:getCenterOfMassTransform()
  for o in pairs(pend) do
    local g = btGeneric6DofConstraint(w.cube.body, o.body, cubeT:inverseTimes(o.body:getCenterOfMassTransform()),
                                      btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0)), true)
    g:setLinearLowerLimit(btVector3(1, 1, 1)); g:setLinearUpperLimit(btVector3(-1, -1, -1))
    g:setAngularLowerLimit(btVector3(0, 0, 0)); g:setAngularUpperLimit(btVector3(0, 0, 0))
    if SOLVER_ITERATIONS then g:setOverrideNumSolverIterations(SOLVER_ITERATIONS) end
    realv:addConstraint(g); n = n + 1
  end
  print("PGUIDE " .. n .. " pendants held at their angle to the body, braces kept")
end
-- HOLD_BRACES = true: each diag brace piece also held at its angle to the body
-- (free to move), as the guides hold the legs: braces kept, their twisting removed
if HOLD_BRACES then
  local held = 0
  for _, o in ipairs(w.bodies) do
    local k = w.madeBy[o]
    if k and k:find("Crossbar") then
      local g = btGeneric6DofConstraint(w.cube.body, o.body,
        w.cube.body:getCenterOfMassTransform():inverseTimes(o.body:getCenterOfMassTransform()),
        btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0)), true)
      g:setLinearLowerLimit(btVector3(1, 1, 1)); g:setLinearUpperLimit(btVector3(-1, -1, -1))
      g:setAngularLowerLimit(btVector3(0, 0, 0)); g:setAngularUpperLimit(btVector3(0, 0, 0))
      if SOLVER_ITERATIONS then g:setOverrideNumSolverIterations(SOLVER_ITERATIONS) end
      v:addConstraint(g); held = held + 1
    end
  end
  print("HELD " .. held .. " brace pieces")
end
local mine = {}
for _, o in ipairs(w.bodies) do mine[o] = w.madeBy[o] or "body" end
mine[w.cube] = "body"
local function kind(o) for q, k in pairs(mine) do if rawequal(q, o) then return k, q end end end
-- (the body's look-only parts -- letters, rim, frame drawing -- overlap it and push nothing: not ground)
local deco = {}
for _, d in ipairs(w.decor or {}) do deco[#deco + 1] = d.o end
local function isDeco(o) for _, q in ipairs(deco) do if rawequal(q, o) then return true end end return false end
local label = {}    -- part -> F/B L/R by its place in the body frame at the start
local function where(o)
  local p = w.cube.body:getCenterOfMassTransform():invXform(o.body:getCenterOfMassPosition())
  return (p.x > 0 and "F" or "B") .. (p.z > 0 and "L" or "R")
end
local function hdg()
  local q = w.cube.body:getCenterOfMassTransform():getRotation()
  local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
  local fx, fz = 1 - 2 * (qy * qy + qz * qz), 2 * (qx * qz - qw * qy)
  local fy, sy = 2 * (qx * qy + qw * qz), 2 * (qy * qz - qw * qx)
  return math.deg(math.atan2(-fz, fx)), math.deg(math.asin(math.max(-1, math.min(1, fy)))), math.deg(math.asin(math.max(-1, math.min(1, sy))))
end
local h0, x0, z0
local last = {}     -- foot -> last position
local acc
local function reset() acc = { n = 0, feet = {}, slip = 0, slipN = 0, ground = {}, pmax = 0, rmax = 0 } end
reset()
for _, m in ipairs(w.motors) do m.spLast = m.hinge:getHingeAngle(); m.spTurn = 0 end
-- brace welds (the room's recorded 6-dof joints with two bodies): largest drift from start
local welds, wdmax, wamax = {}, 0, 0
for _, j in ipairs(w.joints or {}) do
  if j[5] == "btGeneric6DofConstraint" and j[2] then welds[#welds + 1] = { a = j[1], b = j[2] } end
end
local function wrel(wd)
  local ta, tb = wd.a:getCenterOfMassTransform(), wd.b:getCenterOfMassTransform()
  local p = ta:invXform(wd.b:getCenterOfMassPosition())
  local qa, qb = ta:getRotation(), tb:getRotation()
  local ax, ay, az, aw = -qa:x(), -qa:y(), -qa:z(), qa:w()
  local bx, by, bz, bw = qb:x(), qb:y(), qb:z(), qb:w()
  return p.x, p.y, p.z, { aw*bx + ax*bw + ay*bz - az*by, aw*by - ax*bz + ay*bw + az*bx, aw*bz + ax*by - ay*bx + az*bw, aw*bw - ax*bx - ay*by - az*bz }
end
realv:preSim(function(N) hooks.preSim(N) end)
realv:postSim(function(N)
  hooks.postSim(N)
  if N < 120 then return end
  if N == 120 then
    h0 = hdg(); x0, _, z0 = getPosXYZ(w.cube)
    for o, k in pairs(mine) do if k ~= "body" then label[o] = where(o) end end
  end
  if N == 120 then for _, wd in ipairs(welds) do wd.x, wd.y, wd.z, wd.q = wrel(wd) end end
  for _, wd in ipairs(welds) do
    local x, y, z, r = wrel(wd)
    local dot = math.abs(r[1]*wd.q[1] + r[2]*wd.q[2] + r[3]*wd.q[3] + r[4]*wd.q[4])
    wdmax = math.max(wdmax, math.sqrt((x - wd.x)^2 + (y - wd.y)^2 + (z - wd.z)^2))
    wamax = math.max(wamax, math.deg(2 * math.acos(math.min(1, dot))))
  end
  if EXTRA_LIST then
    local T = w.cube.body:getCenterOfMassTransform()
    local worst = 0
    for _, e in ipairs(EXTRA_LIST) do
      local p = T:invXform(e.c.body:getCenterOfMassPosition())
      e.max = math.max(e.max, math.sqrt((p.x - e.rel.x)^2 + (p.y - e.rel.y)^2 + (p.z - e.rel.z)^2)); worst = math.max(worst, e.max)
    end
    if N == 3699 then print(string.format("BLOCKS wobble max %.3f cm", worst)) end
  end
  if EXTRA_BLOCK then
    local p = w.cube.body:getCenterOfMassTransform():invXform(EXTRA_BLOCK.c.body:getCenterOfMassPosition())
    local r = EXTRA_BLOCK.rel
    EXTRA_BLOCK.max = math.max(EXTRA_BLOCK.max or 0, math.sqrt((p.x - r.x)^2 + (p.y - r.y)^2 + (p.z - r.z)^2))
    if N == 3699 then print(string.format("BLOCK wobble max %.3f cm", EXTRA_BLOCK.max)) end
  end
  if N == 3699 then print(string.format("WELD %d welds|drift max %.3f cm|angle max %.2f deg", #welds, wdmax, wamax)) end
  local h, p, r = hdg()
  acc.pmax = math.max(acc.pmax, math.abs(p)); acc.rmax = math.max(acc.rmax, math.abs(r))
  for _, m in ipairs(w.motors) do
    local a = m.hinge:getHingeAngle(); local d = a - m.spLast
    if d > math.pi then d = d - 2 * math.pi elseif d < -math.pi then d = d + 2 * math.pi end
    m.spTurn = m.spTurn + math.abs(d); m.spLast = a
  end
  local down, gr = {}, {}
  realv:eachContact(function(a, b, cx, cy, cz, nx, ny, nz, d, im)
    if d > 0.01 then return end
    local ka, oa = kind(a); local kb, ob = kind(b)
    if (ka == nil) == (kb == nil) or isDeco(a) or isDeco(b) then return end
    local k, o = ka or kb, oa or ob
    if k == "buildFoot" then down[o] = true else gr[k .. ":" .. (label[o] or "?")] = true end
  end)
  acc.n = acc.n + 1
  for o in pairs(down) do
    acc.feet[label[o]] = (acc.feet[label[o]] or 0) + 1
    local q = o.body:getCenterOfMassPosition()
    if last[o] then acc.slip = acc.slip + math.sqrt((q.x - last[o][1])^2 + (q.z - last[o][2])^2) * 60; acc.slipN = acc.slipN + 1 end
  end
  for o, k in pairs(mine) do if k == "buildFoot" then local q = o.body:getCenterOfMassPosition(); last[o] = { q.x, q.z } end end
  for k in pairs(gr) do acc.ground[k] = (acc.ground[k] or 0) + 1 end
  if N % 60 == 0 then
    local x, _, z = getPosXYZ(w.cube)
    local t = 0; for _, m in ipairs(w.motors) do t = t + m.spTurn end; t = t / #w.motors / (2 * math.pi)
    for _, m in ipairs(w.motors) do m.spTurn = 0 end
    local f = {}; for k, n in pairs(acc.feet) do f[#f + 1] = string.format("%s %.0f", k, 100 * n / acc.n) end; table.sort(f)
    local g = {}; for k, n in pairs(acc.ground) do g[#g + 1] = string.format("%s %.0f", k, 100 * n / acc.n) end; table.sort(g)
    print(string.format("STALL %d|x %.1f|z %.1f|hdg %.1f|pitch %.1f|roll %.1f|turns %.2f|feet %s|slip %.1f|ground %s",
      N / 60, x - x0, z - z0, h - h0, acc.pmax, acc.rmax, t, table.concat(f, " "), acc.slipN > 0 and acc.slip / acc.slipN or 0, table.concat(g, " ")))
    reset()
  end
end)
