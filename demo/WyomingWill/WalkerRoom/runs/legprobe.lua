-- How a front leg gives when its foot is pushed back (13 November; handover section 4f, steps 7): the walker held
-- 200 cm up, its body still, cranked at its gait until a front foot rises through LEG_AT cm (default 4: where the
-- slider's front feet meet steps 7's faces) on its way forward; then every crank is held there by its own motor (at
-- the runs' strength, MOTOR_STRENGTH, so a crank may give as it would on the track) and the foot is pushed back --
-- toward the walker's back, level -- at the bottom of its front edge, where a step's face meets it, with a force
-- that steps up each second through LEG_FORCES (shares of the walker's weight; default 0.05 0.1 0.2 0.3 0.5). After
-- each second, one line:
--   LEG <name>|force <share of weight>|back <cm>|up <cm>|toe up <deg>|crank <deg>
-- back, up: how far the foot's pushed point has moved since the push began (along the walk, backward + ; up +);
-- toe up: the foot's turn, toe up +; crank: the most any crank has been turned by the push.
-- Run from the WalkerRoom folder after the room's settings (ONLY, ...), as runs/legs.sh does.
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
local AT = LEG_AT or 4
local FORCES = LEG_FORCES or { 0.05, 0.1, 0.2, 0.3, 0.5 }
local feet = {}
for _, o in ipairs(w.bodies) do if w.madeBy[o] == "buildFoot" then feet[#feet + 1] = { o = o, path = {} } end end
local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0)
local function corner(f)   -- (the bottom of its front edge, in the world; the room walks toward +x)
  f.o.body:getAabb(lo, hi)
  local c = f.o.body:getCenterOfMassPosition()
  return hi.x, lo.y, c.z
end
local function pitch(b)
  local q = b:getCenterOfMassTransform():getRotation()
  local x, y, z, s = q:x(), q:y(), q:z(), q:w()
  local p = math.deg(math.atan2(2 * (s * z + x * y), 1 - 2 * (y * y + z * z)))
  if math.abs(p) > 90 then p = p > 0 and p - 180 or p + 180 end
  return p
end
local TURN = math.floor(2 * math.pi / math.abs(w.crank) * 60 + 0.5)
local T0 = 240
local front, base, prevY, held, k0, start, crank0, pitch0
local weight = w.totalMass * (GRAVITY or 981)
local function angle(m) return m.hinge:getHingeAngle() end
realv:preSim(function(N)
  if not held then if hooks.preSim then hooks.preSim(N) end; return end
  if N < k0 then return end   -- (settling, held)
  -- the push: level, backward, at the corner as it now is
  local step = math.floor((N - k0) / 60) + 1
  if step > #FORCES then return end
  local x, y, z = corner(front)
  local c = front.o.body:getCenterOfMassPosition()
  front.o.body:activate(true)
  front.o.body:applyForce(btVector3(-FORCES[step] * weight, 0, 0), btVector3(x - c.x, y - c.y, z - c.z))
end)
realv:postSim(function(N)
  if not held then
    if hooks.postSim then hooks.postSim(N) end
    if N < T0 then return end
    if N < T0 + TURN then
      for _, f in ipairs(feet) do local _, y = corner(f); local x = f.o.body:getCenterOfMassPosition().x; f.path[#f.path + 1] = { x, y } end
      return
    end
    if not front then
      local best
      for _, f in ipairs(feet) do
        local s = 0
        for _, p in ipairs(f.path) do s = s + p[1] end
        f.mean = s / #f.path
        if not best or f.mean > best.mean then best = f end
      end
      front = best
      base = 1e9
      for _, p in ipairs(front.path) do base = math.min(base, p[2]) end
    end
    local x, y = corner(front)
    local vx = front.o.body:getLinearVelocity().x - 0
    -- rising through AT, moving forward (toward +x), before its highest point
    if prevY and prevY - base < AT and y - base >= AT and vx > 0 then
      held, k0 = true, N + 30   -- (half a second to settle, held, before the push)
      -- (each crank pinned where it is: its motor off and its hinge limited to that angle -- a motor at speed 0
      -- doesn't hold Chebyshev-Spears diag's second pair, which creeps back about 20 degrees a second)
      for i, m in ipairs(w.motors) do local a = m.hinge:getHingeAngle(); m.hinge:enableAngularMotor(false, 0, 0); m.hinge:setLimit(a - 0.001, a + 0.001, 0.9, 0.3, 1.0) end
    end
    prevY = y
    return
  end
  if N == k0 then
    local x, y = corner(front)
    start, pitch0, crank0 = { x, y }, pitch(front.o.body), {}
    for i, m in ipairs(w.motors) do crank0[i] = angle(m) end
  end
  if N > k0 and (N - k0) % 60 == 0 then
    local step = (N - k0) / 60
    local x, y = corner(front)
    local d = 0   -- (the crank turned furthest by the push: the foot's own, or one braced to it)
    for i, m in ipairs(w.motors) do
      local e = angle(m) - crank0[i]; e = e - 2 * math.pi * math.floor(e / (2 * math.pi) + 0.5)
      if math.abs(e) > math.abs(d) then d = e end
    end
    print(string.format("LEG %s|force %.2f|back %.2f|up %.2f|toe up %.1f|crank %.1f", w.spec.name, FORCES[step],
      start[1] - x, y - start[2], (pitch(front.o.body) - pitch0) * -(w.forward or 1), math.deg(math.abs(d))))
    if step == #FORCES then os.exit(0) end
  end
end)
