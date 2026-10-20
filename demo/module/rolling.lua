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
-- Why a couple, not a cut in the rolling speed: Bullet adds gravity and the
-- contact's push inside the step, then moves the body with the speed they
-- leave. A cut in speed made before the step (what the gallery's exhibits
-- did until 20 Oct 2026) cannot cancel what the step itself adds, so a
-- body that should be held rolls on at gravity's angular acceleration
-- times the step (a creep of about g*lever*dt/(k^2+r^2), proportional to
-- the step). The static couple balances the pull itself, and given as the
-- angular impulse C*dt just before the step it enters the same solve as
-- gravity.
--
-- Why an impulse (btRigidBody:applyTorqueImpulse) and not applyTorque
-- (changed 20 Oct 2026): Bullet 3.24 takes a torque set with applyTorque
-- into the contact's push and into the speed it leaves, but not into the
-- speed its friction holds to zero (btSequentialImpulseConstraintSolver::
-- setupFrictionConstraint has the external force but not the external
-- torque). So friction lets the contact point slide by what the torque
-- adds there in a step, h*C*dt/I (h: height of the centre of mass above
-- the contact, I: moment of inertia), every step: a test sphere held at
-- 5 deg slid 2.9 mm a minute (h*C*dt/I = 2.95), a test box under a steady
-- couple too, by exactly that, with 1000 solver iterations or two friction
-- directions. As an impulse before the step it is in every part of the
-- solve; the sphere then slides under 0.001 mm a minute.
--
-- The static couple balances the moment, about the centre of mass, of the
-- table's push where Bullet pushed (the centre of its contact impulses in
-- the last step, averaged over M.AVERAGE; along a line of contact points,
-- the point level with the centre of mass: see pushAt), plus what stops
-- any turning left; it breaks away when that moment is over M.
--
-- rolling.anchor is static friction where Bullet has too little of it: at
-- rest (sliding under 3.5 microns/s here) Bullet's friction acts along one
-- fixed direction only (world x on a level table), so a slow slide across
-- it is never stopped, nor a slow turning about the normal. Before each
-- step it stops the contact point's sliding (and, on a line of contact,
-- the turning about the normal) with an impulse there, if that is within
-- what Coulomb friction has left (mu times the normal impulse, less what
-- Bullet's friction gave; against turning, times a quarter of the line's
-- length); otherwise it does nothing.
--
--   local st = {}                                -- one per body
--   local C = rolling.contacts(v, bodies, cpt)   -- once, before each step
--   rolling.anchor(st, obj, body, C[obj], mu, g, dt)  -- then, per body
--   rolling.couple(st, obj, body, C[obj], mass, g, delta, k2, dt)
--
-- bodies: a table whose keys are the objects (as added with v:add) to
-- track; cpt: their contact processing threshold; C[obj] is { x, y, z,
-- j = normal impulse, n = normal, pts = x, z of the points within reach }
-- or nil when nothing else (static) touches it from below.
-- k2: squared radii of gyration about the body's own x, y, z. mu: the
-- friction coefficient at the table (Bullet's product of the two). Plain
-- functions, no state but `st`.

local M = {}

-- the centre of each body's contact impulses with things that are not
-- bodies (the table), from Bullet's contact points as the last step left
-- them, by object; only contacts that push up (normal at most 60 degrees
-- from vertical). reach: the bodies' contact processing threshold (the
-- points nearer than that are handed to Bullet's solver, so it may push
-- at any of them; default 0, only those it pushed at)
function M.contacts(v, bodies, reach)
  reach = reach or 0
  local acc = {}
  v:eachContact(function(oa, ob, x, y, z, nx, ny, nz, dist, imp)
    if math.abs(ny) < 0.5 then return end
    local o
    if bodies[oa] and not bodies[ob] then o = oa elseif bodies[ob] and not bodies[oa] then o = ob else return end
    local a = acc[o]
    if not a then a = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, pts = {} }; acc[o] = a end
    a[5], a[6], a[7], a[8] = a[5] + x, a[6] + y, a[7] + z, a[8] + 1
    if ny < 0 then nx, ny, nz = -nx, -ny, -nz end
    if imp > 0 then
      a[1], a[2], a[3], a[4] = a[1] + imp * x, a[2] + imp * y, a[3] + imp * z, a[4] + imp
      a[9], a[10], a[11] = a[9] + imp * nx, a[10] + imp * ny, a[11] + imp * nz
    end
    if imp > 0 or dist <= reach then
      local q = a.pts
      q[#q + 1], q[#q + 2] = x, z
    end
  end)
  local out = {}
  for o, a in pairs(acc) do
    if a[4] > 0 then
      local n = math.sqrt(a[9] * a[9] + a[10] * a[10] + a[11] * a[11])
      out[o] = { a[1] / a[4], a[2] / a[4], a[3] / a[4], j = a[4], n = { a[9] / n, a[10] / n, a[11] / n },
                 pts = a.pts }
    else out[o] = { a[5] / a[8], a[6] / a[8], a[7] / a[8], j = 0 } end
  end
  return out
end

-- the line of the contact points within reach (M.contacts): its centre,
-- direction and the ends' distances along it (false if one point)
local function lineOf(c)
  if c.line ~= nil then return c.line end
  c.line = false
  local q = c.pts
  if not q or #q < 4 then return false end
  local n = #q / 2
  local mx, mz = 0, 0
  for i = 1, #q, 2 do mx, mz = mx + q[i], mz + q[i + 1] end
  mx, mz = mx / n, mz / n
  local sxx, sxz, szz = 0, 0, 0
  for i = 1, #q, 2 do
    local dx, dz = q[i] - mx, q[i + 1] - mz
    sxx, sxz, szz = sxx + dx * dx, sxz + dx * dz, szz + dz * dz
  end
  if sxx + szz <= 0 then return false end
  -- the line: the points' longest spread
  local th = 0.5 * math.atan2(2 * sxz, sxx - szz)
  local lx, lz = math.cos(th), math.sin(th)
  local lo, hi = math.huge, -math.huge
  for i = 1, #q, 2 do
    local s = (q[i] - mx) * lx + (q[i + 1] - mz) * lz
    if s < lo then lo = s end
    if s > hi then hi = s end
  end
  c.line = { mx, mz, lx, lz, lo, hi }
  return c.line
end

-- where the table's push acts, as far as the static couple is concerned:
-- the centre of Bullet's contact impulses, except along a line of contact
-- points (a body resting on a ruling or an edge), where any point between
-- its ends can carry the push: there, the point of the line level with
-- the centre of mass (cx, cz), or the nearer end. (Along the line Bullet's
-- share of the load among the points is not fixed by the physics, and
-- answers the couple itself: balancing it there let the couple wander to
-- delta*m*g and break the body away, 20 Oct 2026. Bullet often pushes at
-- one end of the line only, the other a few microns up: so the line is
-- every point within reach, see M.contacts.)
local function pushAt(c, cx, cz)
  local L = lineOf(c)
  if not L then return c[1], c[3] end
  local mx, mz, lx, lz, lo, hi = L[1], L[2], L[3], L[4], L[5], L[6]
  local s = math.max(lo, math.min(hi, (cx - mx) * lx + (cz - mz) * lz))
  -- across the line: the centre of the impulses, as before
  local u = (c[1] - mx) * -lz + (c[3] - mz) * lx
  return mx + s * lx - u * lz, mz + s * lz + u * lx
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

-- the rolling-resistance couple for the coming step (applied as the
-- angular impulse C*dt; st.Cx, st.Cz keep it)
function M.couple(st, obj, body, c, mass, g, delta, k2, dt)
  if not c or delta <= 0 then st.stuck, st.u, st.tb = false, nil, nil; return end
  local cx, _, cz = getPosXYZ(obj)
  local wx, _, wz = getAngVelXYZ(obj)
  local Mx = delta * mass * g
  -- the table's push (m g) where Bullet pushed: its moment about the centre of mass
  local px, pz = pushAt(c, cx, cz)
  local tx, tz = -(pz - cz) * mass * g, (px - cx) * mass * g
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
  -- (as an angular impulse, not applyTorque: see the header)
  st.Cx, st.Cz = Cx, Cz
  if Cx ~= 0 or Cz ~= 0 then body:applyTorqueImpulse(btVector3(Cx * dt, 0, Cz * dt)) end
end

-- Static friction, where Bullet leaves it out: before the step, the
-- impulse at the contact (the centre of the last step's contact impulses)
-- that stops its sliding along the table, if that is within what Coulomb
-- friction has left: mu times the last step's normal impulse, less the
-- friction Bullet itself gave in the last step (from the body's change of
-- momentum: so a sliding impact gets no more than mu times its normal
-- impulse in all); otherwise Bullet's own friction is left to it. On a
-- line of contact points (see lineOf) it also stops the turning about the
-- normal, with an angular impulse up to that friction times a quarter of
-- the line's length (what friction gives with the push spread evenly
-- along it); if more is needed, only the sliding. g: the gravity (straight
-- down). Call it before rolling.couple, with the same st.
function M.anchor(st, obj, body, c, mu, g, dt)
  local vx, vy, vz = getVelXYZ(obj)
  local v0 = st.v0
  st.v0 = nil
  if not c or not c.j or c.j <= 0 then return end
  local nx, ny, nz = c.n[1], c.n[2], c.n[3]
  local left = mu * c.j
  local im = body:getInvMass()
  if v0 then
    -- the table's push along it in the last step: the change of momentum
    -- less gravity's and the normal impulses
    local m = 1 / im
    local fx, fy, fz = m * (vx - v0[1]), m * (vy - v0[2]) + m * g * dt, m * (vz - v0[3])
    local fn = fx * nx + fy * ny + fz * nz
    fx, fy, fz = fx - fn * nx, fy - fn * ny, fz - fn * nz
    left = left - math.sqrt(fx * fx + fy * fy + fz * fz)
  end
  st.v0 = { vx, vy, vz }
  if left <= 0 then return end
  local cx, cy, cz = getPosXYZ(obj)
  local rx, ry, rz = c[1] - cx, c[2] - cy, c[3] - cz
  local wx, wy, wz = getAngVelXYZ(obj)
  -- the contact point's velocity
  local ux, uy, uz = vx + wy * rz - wz * ry, vy + wz * rx - wx * rz, vz + wx * ry - wy * rx
  -- two directions along the table at the contact
  local ax, ay, az = 1, 0, 0
  if math.abs(nx) > 0.7 then ax, ay, az = 0, 0, 1 end
  local d = ax * nx + ay * ny + az * nz
  ax, ay, az = ax - d * nx, ay - d * ny, az - d * nz
  d = math.sqrt(ax * ax + ay * ay + az * az)
  ax, ay, az = ax / d, ay / d, az / d
  local bx, by, bz = ny * az - nz * ay, nz * ax - nx * az, nx * ay - ny * ax
  -- the contact point's change of velocity, and of the turning about the
  -- normal, for an impulse J there and an angular impulse T about the
  -- normal: J/m + (I^-1 (r x J + T n)) x r, and n . I^-1 (r x J + T n)
  local B = body:getCenterOfMassTransform():getBasis()
  local e = { B:getColumn(0), B:getColumn(1), B:getColumn(2) }
  local ii = body:getInvInertiaDiagLocal()
  local inv = { ii.x, ii.y, ii.z }
  local function response(tx, ty, tz, T)
    local qx, qy, qz = ry * tz - rz * ty + T * nx, rz * tx - rx * tz + T * ny, rx * ty - ry * tx + T * nz
    local px, py, pz = 0, 0, 0
    for k = 1, 3 do
      local s = (e[k].x * qx + e[k].y * qy + e[k].z * qz) * inv[k]
      px, py, pz = px + s * e[k].x, py + s * e[k].y, pz + s * e[k].z
    end
    local dx, dy, dz = im * tx + py * rz - pz * ry, im * ty + pz * rx - px * rz, im * tz + px * ry - py * rx
    return ax * dx + ay * dy + az * dz, bx * dx + by * dy + bz * dz, nx * px + ny * py + nz * pz
  end
  local Kaa, Kba, Kna = response(ax, ay, az, 0)
  local Kab, Kbb, Knb = response(bx, by, bz, 0)
  local Kat, Kbt, Knt = response(0, 0, 0, 1)
  local ua, ub = ax * ux + ay * uy + az * uz, bx * ux + by * uy + bz * uz
  local un = nx * wx + ny * wy + nz * wz
  local ja, jb, T
  -- along a line of contact the table also holds the body against turning
  -- about the normal, up to mu*N*L/4 (L: the line's length; even pressure
  -- along it): stop the contact's sliding and that turning together
  local Ln = lineOf(c)
  local arm = Ln and (Ln[6] - Ln[5]) / 4 or 0
  if arm > 0 then
    local det3 = Kaa * (Kbb * Knt - Kbt * Knb) - Kab * (Kba * Knt - Kbt * Kna) + Kat * (Kba * Knb - Kbb * Kna)
    if det3 > 0 then
      local ra, rb, rn = -ua, -ub, -un
      ja = (ra * (Kbb * Knt - Kbt * Knb) - Kab * (rb * Knt - Kbt * rn) + Kat * (rb * Knb - Kbb * rn)) / det3
      jb = (Kaa * (rb * Knt - Kbt * rn) - ra * (Kba * Knt - Kbt * Kna) + Kat * (Kba * rn - rb * Kna)) / det3
      T = (Kaa * (Kbb * rn - rb * Knb) - Kab * (Kba * rn - rb * Kna) + ra * (Kba * Knb - Kbb * Kna)) / det3
      if ja * ja + jb * jb > left * left or math.abs(T) > left * arm then ja = nil end
    end
  end
  if not ja then
    -- the sliding alone
    local det = Kaa * Kbb - Kab * Kba
    if det <= 0 then return end
    ja = -(Kbb * ua - Kab * ub) / det
    jb = -(Kaa * ub - Kba * ua) / det
    T = 0
    if ja * ja + jb * jb > left * left then return end
  end
  local jx, jy, jz = ja * ax + jb * bx, ja * ay + jb * by, ja * az + jb * bz
  body:applyImpulse(btVector3(jx, jy, jz), btVector3(rx, ry, rz))
  if T ~= 0 then body:applyTorqueImpulse(btVector3(T * nx, T * ny, T * nz)) end
  st.v0[1], st.v0[2], st.v0[3] = vx + jx * im, vy + jy * im, vz + jz * im
end

return M
