-- Everything one walker is built from, as the room builds it (test track, flat, frame 2), for
-- comparing two builds. Writes DUMP_OUT (env):
--   BODY  <kind>|<side F/B L/R>|mass|inertia x y z|half extents|shape|pos rel. body (x along walk, y up, z across)|
--         turn rel. body (deg about x, y, z)|damping lin ang|friction|rolling|restitution|flags|activation
--   JOINT <type>|<made in>|<kind A>|<kind B>|pivot rel. body
-- plus TOTAL lines. Joints are recorded as they are built (bpp can't read most of them back).
local made, joints = {}, {}
local rC = Cube
local wrapped = {}
for _, n in ipairs({ "btHingeConstraint", "btSliderConstraint", "btGeneric6DofConstraint", "btGeneric6DofSpring2Constraint", "btPoint2PointConstraint", "btConeTwistConstraint", "btFixedConstraint" }) do
  local f = _G[n]
  if f then
    wrapped[n] = f
    _G[n] = function(A, B, ...)
      local c = f(A, B, ...)
      local info = debug.getinfo(2, "n")
      joints[#joints + 1] = { n = n, A = A, B = (type(B) == "userdata") and B or nil, args = { B, ... }, by = info and info.name or "?" }
      return c
    end
  end
end
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile("test-track.lua")
v = realv
for n, f in pairs(wrapped) do _G[n] = f end
local w = room.walkers[1]
local cubeT = w.cube.body:getCenterOfMassTransform()
local function kindOfBody(b)
  if b == w.cube.body then return "body" end
  for _, o in ipairs(w.bodies) do if o.body == b then return w.madeBy[o] or "?" end end
  return "notwalker"
end
local function rel(T)   -- (a world transform in the body's frame: position, and turning angles)
  local r = cubeT:inverseTimes(T)
  local p = r:inverse():invXform(btVector3(0, 0, 0))
  local q = r:getRotation()
  local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
  local ax = math.deg(math.atan2(2 * (qw * qx + qy * qz), 1 - 2 * (qx * qx + qy * qy)))
  local ay = math.deg(math.asin(math.max(-1, math.min(1, 2 * (qw * qy - qz * qx)))))
  local az = math.deg(math.atan2(2 * (qw * qz + qx * qy), 1 - 2 * (qy * qy + qz * qz)))
  return p, ax, ay, az
end
local out = io.open(os.getenv("DUMP_OUT"), "w")
local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0)
local all = { w.cube }
for _, o in ipairs(w.bodies) do if not rawequal(o, w.cube) then all[#all + 1] = o end end
local tm = 0
for _, o in ipairs(all) do
  local b = o.body
  local k = rawequal(o, w.cube) and "body" or (w.madeBy[o] or "?")
  local inv = b:getInvInertiaDiagLocal()
  local im = b:getInvMass()
  local m = im > 0 and 1 / im or 0
  tm = tm + m
  local sh = b:getCollisionShape()
  local he = "-"
  local ok, h = pcall(function() return sh:getHalfExtentsWithMargin() end)
  if ok and h then he = string.format("%.3f %.3f %.3f", h.x, h.y, h.z) end
  local p, ax, ay, az = rel(b:getCenterOfMassTransform())
  local side = (p.x > 0 and "F" or "B") .. (p.z > 0 and "L" or "R")
  local fr = b:getFriction()
  local okr, rf = pcall(function() return b:getRollingFriction() end)
  out:write(string.format("BODY %s|%s|mass %.3f|inertia %.3f %.3f %.3f|half %s|shape %d|pos %.2f %.2f %.2f|turn %.1f %.1f %.1f|damp %.3f %.3f|friction %.2f|rolling %s|restitution %.2f|flags %d|act %d\n",
    k, side, m, inv.x > 0 and 1 / inv.x or 0, inv.y > 0 and 1 / inv.y or 0, inv.z > 0 and 1 / inv.z or 0, he, sh:getShapeType(),
    p.x, p.y, p.z, ax, ay, az, b:getLinearDamping(), b:getAngularDamping(), fr, okr and string.format("%.3f", rf) or "?", b:getRestitution(), b:getCollisionFlags(), b:getActivationState()))
end
for _, j in ipairs(joints) do
  local ka, kb = kindOfBody(j.A), j.B and kindOfBody(j.B) or "world"
  -- (its pivot: a hinge/point joint's pivot in A, or a 6-dof/slider joint's frame in A)
  local piv = j.args[2]
  local s = "-"
  local okp, wp = pcall(function()
    local TA = j.A:getCenterOfMassTransform()
    if type(piv) == "userdata" and piv.getRotation then return TA:inverse():invXform(piv:inverse():invXform(btVector3(0, 0, 0)))
    elseif type(piv) == "userdata" then return TA:inverse():invXform(piv) end
  end)
  if okp and wp then local r = cubeT:invXform(wp); s = string.format("%.2f %.2f %.2f", r.x, r.y, r.z) end
  out:write(string.format("JOINT %s|%s|%s|%s|pivot %s\n", j.n, j.by, ka, kb, s))
end
out:write(string.format("TOTAL %s|bodies %d|joints %d|mass %.2f|room totalMass %.2f|motors %d|crank %.4f\n", w.spec.name, #all, #joints, tm, w.totalMass, #w.motors, w.crank))
for i, m in ipairs(w.motors) do out:write(string.format("MOTOR %d|speed %.4f|impulse %.4f\n", i, m.speed, m.impulse)) end
out:close()
