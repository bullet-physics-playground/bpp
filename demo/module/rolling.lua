--
-- rolling.lua - rolling resistance as a couple in Bullet's own step
--
-- Load with:  local rolling = require "rolling"
--
-- Rolling resistance is a couple of at most M = delta*m*g against rolling
-- (delta, the lever arm, a property of the materials). Kinetic: while the
-- body rolls, M against its rolling (the level part of its turning).
-- Static: once the rolling has stopped, whatever couple holds it still, up
-- to M: it stays put while gravity's lever about the contact (the level
-- distance from the contact to the centre of mass) is under delta, and
-- rolls again when it is over.
--
-- Why a couple through the step (btRigidBody:applyTorque before each
-- stepSimulation), not a change of speed before it: Bullet adds gravity and
-- the contact's push inside the step, then moves the body with the speed
-- they leave. A cut in speed made before the step (what the gallery's
-- exhibits did until 20 Oct 2026) cannot cancel what the step itself adds,
-- so a body that should be held rolls on at gravity's angular acceleration
-- times the step (a creep of about g*lever*dt/(k^2+r^2), proportional to the
-- step). A couple applied with the step enters the same solve as gravity.
--
-- The static couple balances the moment, about the centre of mass, of the
-- table's push where Bullet pushed (the centre of its contact impulses in
-- the last step, averaged over M.AVERAGE), plus what stops any turning
-- left; it breaks away when that moment is over M.
--
--   local st = {}                                -- one per body
--   local C = rolling.contacts(v, bodies)        -- once, before each step
--   rolling.couple(st, obj, body, C[obj], mass, g, delta, k2, dt)
--
-- bodies: a table whose keys are the objects (as added with v:add) to
-- track; C[obj] is { x, y, z } or nil when nothing else (static) touches it
-- from below. k2: squared radii of gyration about the body's own x, y, z.
-- Plain functions, no state but `st`.

local M = {}

-- the centre of each body's contact impulses with things that are not
-- bodies (the table), from Bullet's contact points as the last step left
-- them, by object; only contacts that push up (normal at most 60 degrees
-- from vertical)
function M.contacts(v, bodies)
  local acc = {}
  v:eachContact(function(oa, ob, x, y, z, nx, ny, nz, dist, imp)
    if math.abs(ny) < 0.5 then return end
    local o
    if bodies[oa] and not bodies[ob] then o = oa elseif bodies[ob] and not bodies[oa] then o = ob else return end
    local a = acc[o]
    if not a then a = { 0, 0, 0, 0, 0, 0, 0, 0 }; acc[o] = a end
    a[5], a[6], a[7], a[8] = a[5] + x, a[6] + y, a[7] + z, a[8] + 1
    if imp > 0 then a[1], a[2], a[3], a[4] = a[1] + imp * x, a[2] + imp * y, a[3] + imp * z, a[4] + imp end
  end)
  local out = {}
  for o, a in pairs(acc) do
    if a[4] > 0 then out[o] = { a[1] / a[4], a[2] / a[4], a[3] / a[4] }
    else out[o] = { a[5] / a[8], a[6] / a[8], a[7] / a[8] } end
  end
  return out
end

-- squared radius of gyration about the level unit axis (ax, 0, az)
local function k2about(body, k2, ax, az)
  local B = body:getCenterOfMassTransform():getBasis()
  local s = 0
  for c = 0, 2 do
    local e = B:getColumn(c)
    local d = ax * e.x + az * e.z
    s = s + k2[c + 1] * d * d
  end
  return s
end

-- how long the static couple averages the push's moment over (s): Bullet
-- shares a resting body's load among its contact points differently from
-- one step to the next (on a line of contact the centre of the push jumps
-- by up to millimetres along it); the hold follows the average, not each
-- step's share (a test sphere is held the same with 0.005 to 0.1 s)
M.AVERAGE = 0.02

-- the rolling-resistance couple for the coming step (applied with
-- applyTorque; Bullet clears it after the step)
function M.couple(st, obj, body, c, mass, g, delta, k2, dt)
  if not c or delta <= 0 then st.stuck, st.u, st.tb = false, nil, nil; return end
  local cx, _, cz = getPosXYZ(obj)
  local wx, _, wz = getAngVelXYZ(obj)
  local Mx = delta * mass * g
  -- the table's push (m g) where Bullet pushed: its moment about the centre of mass
  local tx, tz = -(c[3] - cz) * mass * g, (c[1] - cx) * mass * g
  local wh = math.sqrt(wx * wx + wz * wz)
  -- rolling the other way than the couple was against: it stopped in the step
  if not st.stuck and st.u and wx * st.u[1] + wz * st.u[2] <= 0 then st.stuck = true end
  if st.stuck and st.tb then
    local f = math.min(1, dt / M.AVERAGE)
    st.tb[1], st.tb[2] = st.tb[1] + f * (tx - st.tb[1]), st.tb[2] + f * (tz - st.tb[2])
  else
    st.tb = { tx, tz }
  end
  local bx, bz = st.tb[1], st.tb[2]
  local tb = math.sqrt(bx * bx + bz * bz)
  local Cx, Cz = 0, 0
  if st.stuck and tb <= Mx then
    -- static: balance the push's moment and stop what turning is left (as
    -- far as the centre of mass's own inertia goes), up to M in all
    Cx, Cz = -bx, -bz
    if wh > 0 then
      local i = mass * k2about(body, k2, wx / wh, wz / wh) / dt
      Cx, Cz = Cx - i * wx, Cz - i * wz
    end
    local cc = math.sqrt(Cx * Cx + Cz * Cz)
    if cc > Mx then Cx, Cz = Cx * Mx / cc, Cz * Mx / cc end
    st.u = nil
  else
    -- kinetic: M against the rolling (or, just breaking away, against the
    -- push's turn)
    local was = st.stuck
    st.stuck = false
    if wh > 0 then st.u = { wx / wh, wz / wh }
    elseif tb > 0 then st.u = { bx / tb, bz / tb }
    else st.u = nil end
    if wh == 0 and not was then st.stuck = true end
    if st.u then Cx, Cz = -Mx * st.u[1], -Mx * st.u[2] end
  end
  body:applyTorque(btVector3(Cx, 0, Cz))
end

return M
