--
-- The solar system's engine: the gravity, worked out here (not by Bullet).
-- Loaded by solar-system.lua; returns a constructor, given the data
-- (solar-data.lua).
--
-- THE MAIN INTEGRATION: the Sun, the planets (Mars, Jupiter, Saturn,
-- Uranus, Neptune and Pluto as their systems' barycentres), the Earth and
-- the Moon separately, and five asteroids: every one pulling every other
-- (Newton), plus Einstein's correction for the Sun's pull (the
-- Schwarzschild term, to first order: what turns Mercury's orbit 43
-- seconds of arc a century more than Newton does), plus the Earth's
-- flattening (J2) pulling on the Moon. Stepped by Bulirsch-Stoer (Gragg's
-- modified midpoint with 2, 4, 6, 8, 10 substeps, extrapolated: tenth
-- order), one day at a time, in the ICRF, AU and days.
--
-- THE MOON SYSTEMS (Mars, Jupiter, Saturn, Uranus, Neptune, Pluto): each
-- moon's position from its planet, stepped by Wisdom and Holman's mapping:
-- each moon's Kepler orbit about its planet followed exactly for half a
-- step, then the rest -- the other moons (with the planet's own wobble),
-- the planet's flattening (J2, J4, about its pole; Mars's C22, S22, turning
-- with it), the Sun's tide --
-- given as a kick, then Kepler again. Sixteen steps to the innermost
-- moon's orbit. The Sun's position comes from the main integration.
--
-- THE ASTEROID BELT (belt0: starting states, barycentric): massless, so
-- it changes nothing above. Each is pulled by the Sun, the planets, the
-- Moon and the five asteroids with masses (Newton), their places from the
-- main integration's steps; stepped by RK4 a day at a time, after each of
-- its days. A twin of one of the five (belt0[k].skip, its index) isn't
-- pulled by itself.
--

local sqrt, sin, cos, abs, floor = math.sqrt, math.sin, math.cos, math.abs, math.floor

return function(D, belt0)
  local E = {}
  local C2 = D.C * D.C

  -- -------------------------------------------------------------------
  -- the main integration
  -- -------------------------------------------------------------------
  local N = #D.main
  local GM, NAME = {}, {}
  local X, Y, Z, VX, VY, VZ = {}, {}, {}, {}, {}, {}
  local IDX = {}
  for i, b in ipairs(D.main) do
    GM[i], NAME[i] = b.gm, b.name
    X[i], Y[i], Z[i] = b.x[1], b.x[2], b.x[3]
    VX[i], VY[i], VZ[i] = b.v[1], b.v[2], b.v[3]
    IDX[b.name] = i
  end
  local iSun, iMerc, iEarth, iMoon = IDX.Sun, IDX.Mercury, IDX.Earth, IDX.Moon
  -- a massless Mercury without Einstein, alongside (index N + 1)
  local NN = N + 1
  X[NN], Y[NN], Z[NN], VX[NN], VY[NN], VZ[NN] = X[iMerc], Y[iMerc], Z[iMerc], VX[iMerc], VY[iMerc], VZ[iMerc]
  GM[NN] = 0
  E.N, E.NAME, E.IDX, E.GM = N, NAME, IDX, GM
  E.GR = true

  local AX, AY, AZ = {}, {}, {}
  local GS, J2E, RE2 = GM[iSun], D.J2E, D.RE * D.RE
  -- accelerations of the state (x, y, z, vx, vy, vz arrays) into AX, AY, AZ
  local function accel(x, y, z, vx, vy, vz)
    for i = 1, NN do AX[i], AY[i], AZ[i] = 0, 0, 0 end
    for i = 1, N - 1 do
      local xi, yi, zi, gi = x[i], y[i], z[i], GM[i]
      local ax, ay, az = AX[i], AY[i], AZ[i]
      for j = i + 1, N do
        local dx, dy, dz = x[j] - xi, y[j] - yi, z[j] - zi
        local r2 = dx * dx + dy * dy + dz * dz
        local f = 1 / (r2 * sqrt(r2))
        local fi, fj = GM[j] * f, gi * f
        ax, ay, az = ax + fi * dx, ay + fi * dy, az + fi * dz
        AX[j], AY[j], AZ[j] = AX[j] - fj * dx, AY[j] - fj * dy, AZ[j] - fj * dz
      end
      AX[i], AY[i], AZ[i] = ax, ay, az
    end
    -- the Newtonian Mercury: pulled by all, pulling none
    do
      local xi, yi, zi = x[NN], y[NN], z[NN]
      local ax, ay, az = 0, 0, 0
      for j = 1, N do
        if j ~= iMerc then
          local dx, dy, dz = x[j] - xi, y[j] - yi, z[j] - zi
          local r2 = dx * dx + dy * dy + dz * dz
          local f = GM[j] / (r2 * sqrt(r2))
          ax, ay, az = ax + f * dx, ay + f * dy, az + f * dz
        end
      end
      AX[NN], AY[NN], AZ[NN] = ax, ay, az
    end
    -- Einstein: the Sun's field, to first order (on everything but the
    -- Newtonian Mercury)
    if E.GR then
      local sx, sy, sz, svx, svy, svz = x[iSun], y[iSun], z[iSun], vx[iSun], vy[iSun], vz[iSun]
      for i = 1, N do
        if i ~= iSun then
          local rx, ry, rz = x[i] - sx, y[i] - sy, z[i] - sz
          local ux, uy, uz = vx[i] - svx, vy[i] - svy, vz[i] - svz
          local r2 = rx * rx + ry * ry + rz * rz
          local r = sqrt(r2)
          local f = GS / (C2 * r2 * r)
          local a = 4 * GS / r - (ux * ux + uy * uy + uz * uz)
          local b = 4 * (rx * ux + ry * uy + rz * uz)
          AX[i], AY[i], AZ[i] = AX[i] + f * (a * rx + b * ux), AY[i] + f * (a * ry + b * uy), AZ[i] + f * (a * rz + b * uz)
        end
      end
    end
    -- the Earth's J2 on the Moon (the Earth's pole: the ICRF's z, near enough)
    do
      local rx, ry, rz = x[iMoon] - x[iEarth], y[iMoon] - y[iEarth], z[iMoon] - z[iEarth]
      local r2 = rx * rx + ry * ry + rz * rz
      local r = sqrt(r2)
      local s = rz / r
      local F1 = 1.5 * J2E * RE2 / (r2 * r2 * r) * (5 * s * s - 1)
      local F2 = -3 * J2E * RE2 * s / (r2 * r2)
      local gx, gy, gz = F1 * rx, F1 * ry, F1 * rz + F2
      local ge, gm = GM[iEarth], GM[iMoon]
      AX[iMoon], AY[iMoon], AZ[iMoon] = AX[iMoon] + ge * gx, AY[iMoon] + ge * gy, AZ[iMoon] + ge * gz
      AX[iEarth], AY[iEarth], AZ[iEarth] = AX[iEarth] - gm * gx, AY[iEarth] - gm * gy, AZ[iEarth] - gm * gz
    end
  end

  -- Bulirsch-Stoer
  local SEQ = { 2, 4, 6, 8, 10 }
  local TAB = {}
  for j = 1, #SEQ do TAB[j] = { {}, {}, {}, {}, {}, {} } end
  local x0, y0, z0, u0, v0, w0 = {}, {}, {}, {}, {}, {}
  local x1, y1, z1, u1, v1, w1 = {}, {}, {}, {}, {}, {}
  local A0X, A0Y, A0Z = {}, {}, {}
  local function bsStep(H)
    accel(X, Y, Z, VX, VY, VZ)
    for i = 1, NN do A0X[i], A0Y[i], A0Z[i] = AX[i], AY[i], AZ[i] end
    for j, n in ipairs(SEQ) do
      local h = H / n
      for i = 1, NN do
        x0[i], y0[i], z0[i], u0[i], v0[i], w0[i] = X[i], Y[i], Z[i], VX[i], VY[i], VZ[i]
        x1[i], y1[i], z1[i] = X[i] + h * VX[i], Y[i] + h * VY[i], Z[i] + h * VZ[i]
        u1[i], v1[i], w1[i] = VX[i] + h * A0X[i], VY[i] + h * A0Y[i], VZ[i] + h * A0Z[i]
      end
      local h2 = 2 * h
      for _ = 1, n - 1 do
        accel(x1, y1, z1, u1, v1, w1)
        for i = 1, NN do
          x0[i], x1[i] = x1[i], x0[i] + h2 * u1[i]
          y0[i], y1[i] = y1[i], y0[i] + h2 * v1[i]
          z0[i], z1[i] = z1[i], z0[i] + h2 * w1[i]
          u0[i], u1[i] = u1[i], u0[i] + h2 * AX[i]
          v0[i], v1[i] = v1[i], v0[i] + h2 * AY[i]
          w0[i], w1[i] = w1[i], w0[i] + h2 * AZ[i]
        end
      end
      accel(x1, y1, z1, u1, v1, w1)
      local T = TAB[j]
      for i = 1, NN do
        T[1][i] = 0.5 * (x0[i] + x1[i] + h * u1[i])
        T[2][i] = 0.5 * (y0[i] + y1[i] + h * v1[i])
        T[3][i] = 0.5 * (z0[i] + z1[i] + h * w1[i])
        T[4][i] = 0.5 * (u0[i] + u1[i] + h * AX[i])
        T[5][i] = 0.5 * (v0[i] + v1[i] + h * AY[i])
        T[6][i] = 0.5 * (w0[i] + w1[i] + h * AZ[i])
      end
    end
    local k = #SEQ
    for j = 2, k do
      for m = k, j, -1 do
        local r = 1 / ((SEQ[m] / SEQ[m - j + 1]) ^ 2 - 1)
        local Tm, Tp = TAB[m], TAB[m - 1]
        for c = 1, 6 do
          local a, b = Tm[c], Tp[c]
          for i = 1, NN do a[i] = a[i] + (a[i] - b[i]) * r end
        end
      end
    end
    local T = TAB[k]
    for i = 1, NN do
      X[i], Y[i], Z[i], VX[i], VY[i], VZ[i] = T[1][i], T[2][i], T[3][i], T[4][i], T[5][i], T[6][i]
    end
  end

  -- the step before and after the present, for drawing in between
  local H = 1
  local tB = 0
  local PA, PB = { {}, {}, {}, {}, {}, {} }, { {}, {}, {}, {}, {}, {} }
  local function keep(P)
    for i = 1, NN do P[1][i], P[2][i], P[3][i], P[4][i], P[5][i], P[6][i] = X[i], Y[i], Z[i], VX[i], VY[i], VZ[i] end
  end
  keep(PA)
  keep(PB)
  E.H = H

  -- the main bodies' position (barycentric, ICRF) at time t in [tB - H, tB]: cubic Hermite
  function E.mainPos(i, t)
    local s = (t - (tB - H)) / H
    if s >= 1 then return PB[1][i], PB[2][i], PB[3][i] end
    local s2, s3 = s * s, s * s * s
    local h00, h10, h01, h11 = 2 * s3 - 3 * s2 + 1, s3 - 2 * s2 + s, -2 * s3 + 3 * s2, s3 - s2
    return h00 * PA[1][i] + H * h10 * PA[4][i] + h01 * PB[1][i] + H * h11 * PB[4][i],
           h00 * PA[2][i] + H * h10 * PA[5][i] + h01 * PB[2][i] + H * h11 * PB[5][i],
           h00 * PA[3][i] + H * h10 * PA[6][i] + h01 * PB[3][i] + H * h11 * PB[6][i]
  end
  function E.mainState(i)
    return X[i], Y[i], Z[i], VX[i], VY[i], VZ[i]
  end
  E.iNewtonMercury = NN

  -- energy and angular momentum (Newtonian), barycentric
  function E.invariants()
    local KE, PE, Lx, Ly, Lz = 0, 0, 0, 0, 0
    for i = 1, N do
      local m = GM[i]
      KE = KE + 0.5 * m * (VX[i] ^ 2 + VY[i] ^ 2 + VZ[i] ^ 2)
      Lx = Lx + m * (Y[i] * VZ[i] - Z[i] * VY[i])
      Ly = Ly + m * (Z[i] * VX[i] - X[i] * VZ[i])
      Lz = Lz + m * (X[i] * VY[i] - Y[i] * VX[i])
      for j = i + 1, N do
        PE = PE - m * GM[j] / sqrt((X[j] - X[i]) ^ 2 + (Y[j] - Y[i]) ^ 2 + (Z[j] - Z[i]) ^ 2)
      end
    end
    return KE + PE, sqrt(Lx * Lx + Ly * Ly + Lz * Lz)
  end

  -- -------------------------------------------------------------------
  -- Kepler: a body's two-body orbit followed for dt (elliptic), by f and g
  -- -------------------------------------------------------------------
  local function kepler(x, y, z, vx, vy, vz, mu, dt)
    local r0 = sqrt(x * x + y * y + z * z)
    local v2 = vx * vx + vy * vy + vz * vz
    local a = 1 / (2 / r0 - v2 / mu)
    local n = sqrt(mu / (a * a * a))
    local sig = (x * vx + y * vy + z * vz) / sqrt(mu * a)
    local ec = 1 - r0 / a
    local dM = n * dt
    local dE = dM
    for _ = 1, 30 do
      local s, c = sin(dE), cos(dE)
      local f = dE - ec * s + sig * (1 - c) - dM
      local d = f / (1 - ec * c + sig * s)
      dE = dE - d
      if abs(d) < 1e-14 then break end
    end
    local s, c = sin(dE), cos(dE)
    local r = a * (1 - ec * c + sig * s)
    local F = 1 - a / r0 * (1 - c)
    local G = dt - (dE - s) / n
    local Fd = -sqrt(mu * a) * s / (r * r0)
    local Gd = 1 - a / r * (1 - c)
    return F * x + G * vx, F * y + G * vy, F * z + G * vz, Fd * x + Gd * vx, Fd * y + Gd * vy, Fd * z + Gd * vz
  end
  E.kepler = kepler

  -- -------------------------------------------------------------------
  -- the moon systems
  -- -------------------------------------------------------------------
  local SYS = {}
  for _, s in ipairs(D.systems) do
    local S = { planet = s.planet, gmp = s.gm, j2 = s.j2, j4 = s.j4, R2 = s.rref * s.rref, R4 = s.rref ^ 4,
                c22 = s.c22, s22 = s.s22, w0 = s.w0, wdot = s.wdot,
                px = s.pole[1], py = s.pole[2], pz = s.pole[3], ibary = IDX[s.planet], moons = {}, t = 0 }
    local pmin = math.huge
    for k, m in ipairs(s.moons) do
      local M = { name = m.name, gm = m.gm, mu = s.gm + m.gm, r = m.r, source = m.source,
                  x = m.x[1], y = m.x[2], z = m.x[3], vx = m.v[1], vy = m.v[2], vz = m.v[3] }
      local r0 = sqrt(M.x ^ 2 + M.y ^ 2 + M.z ^ 2)
      local a = 1 / (2 / r0 - (M.vx ^ 2 + M.vy ^ 2 + M.vz ^ 2) / M.mu)
      pmin = math.min(pmin, 2 * math.pi * sqrt(a ^ 3 / M.mu))
      S.moons[k] = M
    end
    S.h = pmin / 16
    S.gmsys = s.gm
    for _, M in ipairs(S.moons) do S.gmsys = S.gmsys + M.gm end
    SYS[#SYS + 1] = S
  end
  E.SYS = SYS

  -- the kick: everything but each moon's Kepler orbit about its planet
  local D2000 = D.JD0 - 2451545.0
  local function kick(S, t, dt)
    local ms = S.moons
    local nm = #ms
    -- a planet that isn't round about its axis (C22, S22: Mars): its
    -- equator's axes, turning with it (W, its prime meridian's angle)
    local bx1, by1, bz1, bx2, by2, bz2
    if S.c22 then
      local W = math.rad(S.w0 + S.wdot * (D2000 + t))
      local qx, qy = -S.py, S.px                 -- the equator's node on the ICRF's equator (z x pole)
      local qn = sqrt(qx * qx + qy * qy)
      qx, qy = qx / qn, qy / qn
      local rx, ry, rz = S.py * 0 - S.pz * qy, S.pz * qx - S.px * 0, S.px * qy - S.py * qx   -- pole x node
      local cw, sw = cos(W), sin(W)
      bx1, by1, bz1 = cw * qx + sw * rx, cw * qy + sw * ry, sw * rz
      bx2, by2, bz2 = S.py * bz1 - S.pz * by1, S.pz * bx1 - S.px * bz1, S.px * by1 - S.py * bx1
    end
    -- the Sun, from the planet (its system's barycentre, near enough)
    local bx, by, bz = E.mainPos(S.ibary, t)
    local sx, sy, sz = E.mainPos(iSun, t)
    sx, sy, sz = sx - bx, sy - by, sz - bz
    local s2 = sx * sx + sy * sy + sz * sz
    local fs = 1 / (s2 * sqrt(s2))
    local isx, isy, isz = sx * fs, sy * fs, sz * fs
    -- the indirect term: the planet's own pull toward each moon
    local ix, iy, iz = 0, 0, 0
    for k = 1, nm do
      local m = ms[k]
      local r2 = m.x * m.x + m.y * m.y + m.z * m.z
      local f = m.gm / (r2 * sqrt(r2))
      ix, iy, iz = ix + f * m.x, iy + f * m.y, iz + f * m.z
    end
    for k = 1, nm do
      local m = ms[k]
      local x, y, z = m.x, m.y, m.z
      local r2 = x * x + y * y + z * z
      local r = sqrt(r2)
      -- the planet's own acceleration, less this moon's share (in its Kepler mu)
      local f0 = m.gm / (r2 * r)
      local ax, ay, az = -(ix - f0 * x), -(iy - f0 * y), -(iz - f0 * z)
      -- the other moons
      for j = 1, nm do
        if j ~= k then
          local o = ms[j]
          local dx, dy, dz = o.x - x, o.y - y, o.z - z
          local d2 = dx * dx + dy * dy + dz * dz
          local f = o.gm / (d2 * sqrt(d2))
          ax, ay, az = ax + f * dx, ay + f * dy, az + f * dz
        end
      end
      -- the planet's flattening, about its pole
      if S.j2 ~= 0 then
        local s = (x * S.px + y * S.py + z * S.pz) / r
        local mu = S.gmp
        local r4 = r2 * r2
        local F1 = 1.5 * S.j2 * mu * S.R2 / (r4 * r) * (5 * s * s - 1)
        local F2 = -3 * S.j2 * mu * S.R2 * s / r4
        if S.j4 ~= 0 then
          local g = 0.625 * S.j4 * mu * S.R4 / (r4 * r2 * r)
          F1 = F1 + g * (63 * s ^ 4 - 42 * s * s + 3)
          F2 = F2 + g * r * s * (12 - 28 * s * s)
        end
        ax, ay, az = ax + F1 * x + F2 * S.px, ay + F1 * y + F2 * S.py, az + F1 * z + F2 * S.pz
      end
      if S.c22 then
        -- U22 = 3 mu R^2 (C22 (X^2 - Y^2) + 2 S22 X Y) / r^5, X, Y along the equator's turning axes
        local X = x * bx1 + y * by1 + z * bz1
        local Y = x * bx2 + y * by2 + z * bz2
        local mu = S.gmp
        local k = 3 * mu * S.R2 / (r2 * r2 * r)
        local U = S.c22 * (X * X - Y * Y) + 2 * S.s22 * X * Y
        local gX = k * (2 * S.c22 * X + 2 * S.s22 * Y)
        local gY = k * (-2 * S.c22 * Y + 2 * S.s22 * X)
        local gr = -5 * k * U / r2
        ax = ax + gX * bx1 + gY * bx2 + gr * x
        ay = ay + gX * by1 + gY * by2 + gr * y
        az = az + gX * bz1 + gY * bz2 + gr * z
      end
      -- the Sun's tide
      local dx, dy, dz = sx - x, sy - y, sz - z
      local d2 = dx * dx + dy * dy + dz * dz
      local f = 1 / (d2 * sqrt(d2))
      ax, ay, az = ax + GS * (dx * f - isx), ay + GS * (dy * f - isy), az + GS * (dz * f - isz)
      m.ax, m.ay, m.az = ax, ay, az
    end
    for k = 1, nm do
      local m = ms[k]
      m.vx, m.vy, m.vz = m.vx + dt * m.ax, m.vy + dt * m.ay, m.vz + dt * m.az
    end
  end
  local function drift(S, dt)
    for _, m in ipairs(S.moons) do
      m.x, m.y, m.z, m.vx, m.vy, m.vz = kepler(m.x, m.y, m.z, m.vx, m.vy, m.vz, m.mu, dt)
    end
  end
  -- advance a system to the last step at or before t
  local function advanceSys(S, t)
    local h = S.h
    while S.t + h <= t + 1e-12 do
      drift(S, h / 2)
      kick(S, S.t + h / 2, h)
      drift(S, h / 2)
      S.t = S.t + h
    end
  end
  -- a moon's position from its planet at time t (from the last step, by its Kepler orbit)
  function E.moonPos(S, k, t)
    local m = S.moons[k]
    local dt = t - S.t
    if abs(dt) < 1e-12 then return m.x, m.y, m.z end
    local x, y, z = kepler(m.x, m.y, m.z, m.vx, m.vy, m.vz, m.mu, dt)
    return x, y, z
  end
  -- the planet's offset from its system's barycentre (at time t)
  function E.planetOffset(S, t)
    local ox, oy, oz = 0, 0, 0
    for k, m in ipairs(S.moons) do
      local x, y, z = E.moonPos(S, k, t)
      ox, oy, oz = ox - m.gm * x, oy - m.gm * y, oz - m.gm * z
    end
    return ox / S.gmsys, oy / S.gmsys, oz / S.gmsys
  end

  -- -------------------------------------------------------------------
  -- the asteroid belt
  -- -------------------------------------------------------------------
  local belt = belt0 or {}
  local NB = #belt
  local BS, BA, BB = {}, {}, {}           -- state now (end of the day), and at the day's start and end, for drawing
  local PULL = {}                          -- who pulls (all but the Newtonian Mercury)
  for i = 1, N do PULL[#PULL + 1] = i end
  local function beltReset()
    for k, b in ipairs(belt) do
      BS[k] = { b[1], b[2], b[3], b[4], b[5], b[6] }
      BA[k] = { b[1], b[2], b[3], b[4], b[5], b[6] }
      BB[k] = { b[1], b[2], b[3], b[4], b[5], b[6] }
    end
  end
  beltReset()
  local PX, PY, PZ = {}, {}, {}
  local function places(t)                -- (the pullers at time t, from the main integration's step)
    for _, i in ipairs(PULL) do PX[i], PY[i], PZ[i] = E.mainPos(i, t) end
  end
  local function beltAcc(k, x, y, z)
    local sk = belt[k].skip
    local ax, ay, az = 0, 0, 0
    for _, j in ipairs(PULL) do
      if j ~= sk then
        local dx, dy, dz = PX[j] - x, PY[j] - y, PZ[j] - z
        local r2 = dx * dx + dy * dy + dz * dz
        local f = GM[j] / (r2 * sqrt(r2))
        ax, ay, az = ax + f * dx, ay + f * dy, az + f * dz
      end
    end
    return ax, ay, az
  end
  -- one day, t0 to t0 + 1 (the main integration already at its end)
  local K = {}
  local function beltDay(t0)
    local h = 1
    for k = 1, NB do K[k] = {} end
    places(t0)
    for k = 1, NB do local s = BS[k]; K[k][1], K[k][2], K[k][3] = beltAcc(k, s[1], s[2], s[3]) end
    places(t0 + h / 2)
    for k = 1, NB do
      local s, q = BS[k], K[k]
      q[4], q[5], q[6] = beltAcc(k, s[1] + h / 2 * s[4], s[2] + h / 2 * s[5], s[3] + h / 2 * s[6])
      q[7], q[8], q[9] = beltAcc(k, s[1] + h / 2 * s[4] + h * h / 4 * q[1], s[2] + h / 2 * s[5] + h * h / 4 * q[2],
                                 s[3] + h / 2 * s[6] + h * h / 4 * q[3])
    end
    places(t0 + h)
    for k = 1, NB do
      local s, q, a = BS[k], K[k], BA[k]
      local ax, ay, az = beltAcc(k, s[1] + h * s[4] + h * h / 2 * q[4], s[2] + h * s[5] + h * h / 2 * q[5],
                                 s[3] + h * s[6] + h * h / 2 * q[6])
      for c = 1, 6 do a[c] = s[c] end
      s[1] = s[1] + h * (s[4] + h / 6 * (q[1] + q[4] + q[7]))
      s[2] = s[2] + h * (s[5] + h / 6 * (q[2] + q[5] + q[8]))
      s[3] = s[3] + h * (s[6] + h / 6 * (q[3] + q[6] + q[9]))
      s[4] = s[4] + h / 6 * (q[1] + 2 * q[4] + 2 * q[7] + ax)
      s[5] = s[5] + h / 6 * (q[2] + 2 * q[5] + 2 * q[8] + ay)
      s[6] = s[6] + h / 6 * (q[3] + 2 * q[6] + 2 * q[9] + az)
      local b = BB[k]
      for c = 1, 6 do b[c] = s[c] end
    end
  end
  E.NB = NB
  -- asteroid k of the belt at time t in [tB - H, tB] (cubic Hermite, as mainPos)
  function E.beltPos(k, t)
    local s = (t - (tB - H)) / H
    local A, B = BA[k], BB[k]
    if s >= 1 then return B[1], B[2], B[3] end
    local s2, s3 = s * s, s * s * s
    local h00, h10, h01, h11 = 2 * s3 - 3 * s2 + 1, s3 - 2 * s2 + s, -2 * s3 + 3 * s2, s3 - s2
    return h00 * A[1] + H * h10 * A[4] + h01 * B[1] + H * h11 * B[4],
           h00 * A[2] + H * h10 * A[5] + h01 * B[2] + H * h11 * B[5],
           h00 * A[3] + H * h10 * A[6] + h01 * B[3] + H * h11 * B[6]
  end
  function E.beltState(k) local s = BS[k]; return s[1], s[2], s[3], s[4], s[5], s[6] end

  -- -------------------------------------------------------------------
  -- the present: advance everything to time t (days from the start)
  -- -------------------------------------------------------------------
  -- (the moons' steps inside the present day are finished before the next
  -- day is stepped, so each kick takes the Sun from the day it falls in --
  -- or, for the step that straddles the day's end, the next -- however the
  -- frames fall: the same answer at any speed)
  E.t = 0
  function E.advance(t)
    while tB < t do
      for _, S in ipairs(SYS) do advanceSys(S, tB) end
      for c = 1, 6 do
        local a, b = PA[c], PB[c]
        for i = 1, NN do a[i] = b[i] end
      end
      bsStep(H)
      tB = tB + H
      keep(PB)
      if NB > 0 then beltDay(tB - H) end
      for _, S in ipairs(SYS) do advanceSys(S, math.min(tB, t)) end
    end
    for _, S in ipairs(SYS) do advanceSys(S, t) end
    E.t = t
  end
  function E.mainTime() return tB end

  -- Mercury's orbit alone about the Sun, with Einstein: the perihelion's
  -- turning, by its Laplace-Runge-Lenz vector (a separate two-body run)
  do
    local i = iMerc
    local rx, ry, rz = X[i] - X[iSun], Y[i] - Y[iSun], Z[i] - Z[iSun]
    local ux, uy, uz = VX[i] - VX[iSun], VY[i] - VY[iSun], VZ[i] - VZ[iSun]
    local mu = GS + GM[i]
    local M2 = { x = rx, y = ry, z = rz, vx = ux, vy = uy, vz = uz, t = 0 }
    local function a2(x, y, z, vx, vy, vz)
      local r2 = x * x + y * y + z * z
      local r = sqrt(r2)
      local f = -mu / (r2 * r)
      local g = GS / (C2 * r2 * r)
      local a = 4 * GS / r - (vx * vx + vy * vy + vz * vz)
      local b = 4 * (x * vx + y * vy + z * vz)
      return f * x + g * (a * x + b * vx), f * y + g * (a * y + b * vy), f * z + g * (a * z + b * vz)
    end
    -- RK4, a hundredth of a day (Mercury's orbit: 8800 steps)
    local function step(h)
      local x, y, z, vx, vy, vz = M2.x, M2.y, M2.z, M2.vx, M2.vy, M2.vz
      local k1x, k1y, k1z = a2(x, y, z, vx, vy, vz)
      local h2 = h / 2
      local k2x, k2y, k2z = a2(x + h2 * vx, y + h2 * vy, z + h2 * vz, vx + h2 * k1x, vy + h2 * k1y, vz + h2 * k1z)
      local k3x, k3y, k3z = a2(x + h2 * (vx + h2 * k1x), y + h2 * (vy + h2 * k1y), z + h2 * (vz + h2 * k1z),
                               vx + h2 * k2x, vy + h2 * k2y, vz + h2 * k2z)
      local k4x, k4y, k4z = a2(x + h * (vx + h2 * k2x), y + h * (vy + h2 * k2y), z + h * (vz + h2 * k2z),
                               vx + h * k3x, vy + h * k3y, vz + h * k3z)
      M2.x = x + h * (vx + h / 6 * (k1x + k2x + k3x))
      M2.y = y + h * (vy + h / 6 * (k1y + k2y + k3y))
      M2.z = z + h * (vz + h / 6 * (k1z + k2z + k3z))
      M2.vx = vx + h / 6 * (k1x + 2 * k2x + 2 * k3x + k4x)
      M2.vy = vy + h / 6 * (k1y + 2 * k2y + 2 * k3y + k4y)
      M2.vz = vz + h / 6 * (k1z + 2 * k2z + 2 * k3z + k4z)
    end
    local function lrl()
      local x, y, z, vx, vy, vz = M2.x, M2.y, M2.z, M2.vx, M2.vy, M2.vz
      local hx, hy, hz = y * vz - z * vy, z * vx - x * vz, x * vy - y * vx
      local r = sqrt(x * x + y * y + z * z)
      local ex = (vy * hz - vz * hy) / mu - x / r
      local ey = (vz * hx - vx * hz) / mu - y / r
      local ez = (vx * hy - vy * hx) / mu - z / r
      return ex, ey, ez, hx, hy, hz
    end
    local _, _, _, hx, hy, hz = lrl()
    local hn = sqrt(hx * hx + hy * hy + hz * hz)
    local r0 = sqrt(rx * rx + ry * ry + rz * rz)
    local a = 1 / (2 / r0 - (ux * ux + uy * uy + uz * uz) / mu)
    local e = sqrt((lrl()) ^ 2 + select(2, lrl()) ^ 2 + select(3, lrl()) ^ 2)
    -- the theory: 6 pi G M / (c^2 a (1 - e^2)) a turn, in radians a day
    E.mercGR = { theory = 6 * math.pi * GS / (C2 * a * (1 - e * e)) / (2 * math.pi * sqrt(a ^ 3 / mu)) }
    -- the orbit's own wobble (Einstein's force depends on the speed) is
    -- averaged out: the Laplace-Runge-Lenz vector averaged over each whole
    -- orbit, perihelion to perihelion; then a straight line through their
    -- directions
    local sx, sy, sz, st = 0, 0, 0, 0
    local started, lastRV = false, nil
    local first, fit = nil, { n = 0, t = 0, a = 0, tt = 0, ta = 0 }
    function E.mercGR.advance(t)
      local h = 0.01
      while M2.t + h <= t + 1e-9 do
        step(h)
        M2.t = M2.t + h
        local rv = M2.x * M2.vx + M2.y * M2.vy + M2.z * M2.vz
        if lastRV and lastRV < 0 and rv >= 0 then
          -- perihelion
          if started and st > 0 then
            local ax, ay, az = sx / st, sy / st, sz / st
            if not first then
              first = { ax, ay, az }
            else
              local cx, cy, cz = first[2] * az - first[3] * ay, first[3] * ax - first[1] * az, first[1] * ay - first[2] * ax
              local ang = math.atan2((cx * hx + cy * hy + cz * hz) / hn, first[1] * ax + first[2] * ay + first[3] * az)
              local tm = M2.t
              fit.n, fit.t, fit.a, fit.tt, fit.ta = fit.n + 1, fit.t + tm, fit.a + ang, fit.tt + tm * tm, fit.ta + tm * ang
            end
          end
          started, sx, sy, sz, st = true, 0, 0, 0, 0
        end
        lastRV = rv
        if started then
          local ex, ey, ez = lrl()
          sx, sy, sz, st = sx + ex * h, sy + ey * h, sz + ez * h, st + h
        end
      end
      -- the slope, radians a day, and how many orbits it's from
      if fit.n < 2 then return nil, fit.n end
      local d = fit.n * fit.tt - fit.t * fit.t
      return (fit.n * fit.ta - fit.t * fit.a) / d, fit.n + 1
    end
  end

  -- restart from the data
  function E.reset()
    for i, b in ipairs(D.main) do
      X[i], Y[i], Z[i] = b.x[1], b.x[2], b.x[3]
      VX[i], VY[i], VZ[i] = b.v[1], b.v[2], b.v[3]
    end
    X[NN], Y[NN], Z[NN], VX[NN], VY[NN], VZ[NN] = X[iMerc], Y[iMerc], Z[iMerc], VX[iMerc], VY[iMerc], VZ[iMerc]
    tB = 0
    keep(PA)
    keep(PB)
    beltReset()
    for si, s in ipairs(D.systems) do
      local S = SYS[si]
      S.t = 0
      for k, m in ipairs(s.moons) do
        local M = S.moons[k]
        M.x, M.y, M.z, M.vx, M.vy, M.vz = m.x[1], m.x[2], m.x[3], m.v[1], m.v[2], m.v[3]
      end
    end
    E.t = 0
  end
  return E
end
