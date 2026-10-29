--
-- ch07/kerr.lua -- Kerr's 2004 kinetic-theory gas simulator (ch07/kerr/,
-- the code behind the theory experiments of the FAABS paper, his thesis
-- Ch. 5 and the book's Ch. 7.6-7.8) as plain Lua, operation for operation
--
-- It is Garcia's DSMC Couette program (A. L. Garcia, Numerical Methods for
-- Physics, 2nd ed., Prentice Hall 2000, program dsmcne; his code:
-- github.com/AlejGarcia/NM4P) made 2D by Kerr: positions in x (across the
-- channel) and y (along it), velocities in x and y, cells in both. Units are
-- Garcia's, SI: argon atoms (mass 6.63e-26 kg, diameter 3.66e-10 m) at
-- temperature T kelvin, a channel 1 micron wide; wall speeds are given as
-- Mach numbers, V = M sqrt(5/3 kT/m).
--
-- Three variants, one per experiment directory of ch07/kerr/ (each its own
-- ktphysics/CouettePhysics.java and Mover.java; Colider, Sorter the same):
--   "couette"  StandardCouette: side walls at x = 0 and L, the left moving
--              at dir0 VL, the right at dir1 VR along y; the channel open in
--              y (length L x PC.length for the cells only); particles start
--              uniform in the first L x L with Maxwellian velocities plus
--              Garcia's gradient VR 2 (x/L - 0.5) on vy (velocity profile)
--   "uniform"  UniformDistribution: an L x L box, walls at rest; particles
--              start uniform in the square [L/2, 3L/4]^2 (spatial
--              distribution)
--   "speed"    AverageSpeed: an L x L box; the walls at x thermalise, the
--              walls at y reflect vy (average speed)
--
-- THE STEP (CouettePhysics.timeStep): move (Mover), sort into cells
-- (Sorter), collide (Colider).
--   Mover: every particle moves by v tau; one that crossed x = 0 or L gets
--     vx = +-mpv sqrt(-ln(1-U)) (biased Maxwellian), vy = stdev N(0,1) plus
--     that wall's speed (stdev = mpv/sqrt 2 = sqrt(kT/m)) and flies on for
--     the rest of the step from where it struck. In the boxes the walls at y
--     are tested first; "uniform" gives vx = +mpv sqrt(-ln(1-U)) (always
--     positive) and |vy| = stdev |N| away from the wall, "speed" reflects
--     vy; both then place the particle from the line's crossing of y = 0
--     for either wall and clamp it into the box (so one that struck y = L
--     ends at y = 0; FINDINGS F93). Positions are then clamped to the box.
--   Sorter: cell (jx, jy) = (int)(x ncell_x / L), (int)(y ncell_y /
--     (length L)), clamped to the grid.
--   Colider: in each cell with n >= 2, select = coeff n^2 crmax + selxtra
--     candidate pairs (Garcia: n (n-1)); a pair with relative speed cr is
--     accepted if cr / crmax > U, and crmax is raised to the largest cr met
--     so far after every candidate (Garcia: after the cell); an accepted
--     pair gets v = vcm +- cr (cos th, sin th)/2 with cos th = 1 - 2U and
--     sin th = +sqrt(1 - cos^2), th from the x axis (Garcia's 3D draw with
--     its azimuth dropped; FINDINGS F93, F95). Momentum and energy are kept.
--   Random numbers: Kerr's PC.rand, Park and Miller's minimal standard
--     (seed = 16807 seed mod 2^31 - 1, U = seed / (2^31 - 1)); PC.randn =
--     sqrt(-2 ln(1 - U1)) cos(6.283185307 U2). Exact in Lua's doubles for
--     seeds below 5 x 10^11 (Kerr seeded from the clock in milliseconds; the
--     seeded Java, ch07/kerr_seed.diff, takes -Dkerr.seed).
--
-- o.fix (ours; all off by default, which is Kerr's code): a table of
-- switches, each correcting one thing in his code:
--   iso      the collision angle uniform on [0, 2 pi) (the book's text,
--            PDF 236; Garcia's in 2D)
--   walls    the boxes' walls at y as the walls at x are (Garcia's wall:
--            normal speed mpv sqrt(-ln(1-U)) away from the wall, tangential
--            stdev N(0,1), the particle placed from where it struck that
--            wall); "speed" keeps its reflection of vy but is placed right
--   garcia   Garcia's own collision counting: n (n - 1) candidates and
--            crmax updated after the cell
--   rest     ("couette") start without the gradient, at rest on average
--
-- DEFINITIONS (fields; SI units):
--   m.x[i], m.y[i], m.vx[i], m.vy[i]  position (m) and velocity (m/s), i = 0..n-1
--   m.colSum   accepted collisions since the start
--   m.mpv      sqrt(2 kT/m), most probable speed (m/s)
--   m.VL, m.VR the side walls' speeds (m/s), dir0 VL and dir1 VR in the mover
--   m.tau      the time step, 0.2 (L / ncell_x) / mpv (s)
--

local K = {}
local floor, ceil, sqrt, log, cos = math.floor, math.ceil, math.sqrt, math.log, math.cos

K.boltz, K.mass, K.diam, K.density = 1.3806e-23, 6.63e-26, 3.66e-10, 2.685e25
K.L = 1e-6
local A, M = 16807, 2147483647

local function int(x) if x >= 0 then return floor(x) else return ceil(x) end end
K.int = int

local function rand(m)
  m.seed = (A * m.seed) % M
  return m.seed / M
end
local function randn(m)
  local r = sqrt(-2.0 * log(1.0 - rand(m)))
  return r * cos(6.283185307 * rand(m))
end
K.rand, K.randn = rand, randn

-- o: variant ("couette" | "uniform" | "speed"), npart, ncell_x, ncell_y,
-- length, T (integer kelvin, as Kerr's PC.T), VLm, VRm (Mach), dir0, dir1,
-- seed, fix = { iso, walls, garcia, rest }
function K.new(o)
  local L = K.L
  local boltz, mass, diam, density = K.boltz, K.mass, K.diam, K.density
  local m = { variant = o.variant or "couette", n = o.npart or 500,
              ncx = o.ncell_x or 7, ncy = o.ncell_y or 70, length = o.length or 10,
              T = o.T or 273, dir0 = o.dir0 or -1, dir1 = o.dir1 or 1,
              seed = o.seed or 1, fix = o.fix or {}, colSum = 0,
              x = {}, y = {}, vx = {}, vy = {} }
  local n, T = m.n, m.T
  m.eff_num = density * L * L / n
  m.mpv = sqrt(2.0 * boltz * T / mass)
  if m.variant == "couette" then
    m.VL = (o.VLm or 0) * sqrt(5.0 / 3.0 * boltz * T / mass)
    m.VR = (o.VRm or 0) * sqrt(5.0 / 3.0 * boltz * T / mass)
  else
    m.VL, m.VR = 0, 0
  end
  local s0 = sqrt(boltz * T / mass)
  for i = 0, n - 1 do
    if m.variant == "uniform" then
      m.x[i] = (L / 4.0) * rand(m) + L / 2
      m.y[i] = (L / 4.0) * rand(m) + L / 2
    else
      m.x[i] = L * rand(m)
      m.y[i] = L * rand(m)
    end
    m.vx[i] = s0 * randn(m)
    m.vy[i] = s0 * randn(m)
    if m.variant == "couette" and not m.fix.rest then
      m.vy[i] = m.vy[i] + m.VR * 2 * (m.x[i] / L - 0.5)
    end
  end
  m.tau = 0.2 * (L / m.ncx) / m.mpv
  m.crmax, m.selxtra = {}, {}
  for c = 0, m.ncx * m.ncy - 1 do m.crmax[c], m.selxtra[c] = 3 * m.mpv, 0 end
  m.coeff = 0.5 * m.eff_num * math.pi * diam * diam * m.tau / (L * L / m.ncx)
  m.cell_n, m.index, m.Xref, m.xo, m.yo = {}, {}, {}, {}, {}
  return m
end

-- Garcia's wall, for a wall at y = yw (ours, fix.walls): the particle
-- crossed it during this step; give it a new velocity (dirn = +1 away from
-- y = 0, -1 away from y = L) and fly it on from the crossing
local function garciaWallY(m, i, yw, dirn, speedVariant)
  local X, Y, VX, VY, XO, YO, tau = m.x, m.y, m.vx, m.vy, m.xo, m.yo, m.tau
  local f = (Y[i] - yw) / (Y[i] - YO[i])                 -- share of the step after the strike
  local xs = X[i] - f * (X[i] - XO[i])                   -- where it struck
  if speedVariant then
    VY[i] = -VY[i]
  else
    VY[i] = dirn * sqrt(-log(1.0 - rand(m))) * m.mpv
    VX[i] = (m.mpv / sqrt(2.0)) * randn(m)
  end
  X[i] = xs + VX[i] * tau * f
  Y[i] = yw + VY[i] * tau * f
end

function K.move(m)
  local L, n, tau, mpv = K.L, m.n, m.tau, m.mpv
  local X, Y, VX, VY, XO, YO = m.x, m.y, m.vx, m.vy, m.xo, m.yo
  for i = 0, n - 1 do XO[i], YO[i] = X[i], Y[i] end
  for i = 0, n - 1 do
    X[i] = X[i] + VX[i] * tau
    Y[i] = Y[i] + VY[i] * tau
  end
  local stdev = mpv / sqrt(2.0)
  local box = m.variant ~= "couette"
  local vw0, vw1 = m.dir0 * m.VL, m.dir1 * m.VR
  for i = 0, n - 1 do
    if box then
      local flag = -1
      if Y[i] <= 0 then flag = 0 elseif Y[i] >= L then flag = 1 end
      if flag >= 0 then
        if m.fix.walls then
          garciaWallY(m, i, flag == 0 and 0 or L, flag == 0 and 1 or -1, m.variant == "speed")
        else
          local xint
          if (XO[i] - X[i]) == 0 then
            xint = X[i]
          else
            local x1, y1, x2, y2 = XO[i], YO[i], X[i], Y[i]
            local mm = (y1 - y2) / (x1 - x2)
            local b = y1 - (mm * x1)
            xint = (-b) / mm
          end
          if m.variant == "uniform" then
            VX[i] = sqrt(-log(1.0 - rand(m))) * mpv
            VY[i] = stdev * randn(m)
            if VY[i] < 0 and flag == 0 then VY[i] = VY[i] * -1 end
            if VY[i] > 0 and flag == 1 then VY[i] = VY[i] * -1 end
          else
            VY[i] = -1 * VY[i]
          end
          local dtr = tau * (X[i] - xint) / (X[i] - XO[i])
          X[i] = xint + VX[i] * dtr
          dtr = tau * (Y[i]) / (Y[i] - YO[i])
          Y[i] = VY[i] * dtr
        end
      end
    end
    local flag = -1
    if X[i] <= 0 then flag = 0 elseif X[i] >= L then flag = 1 end
    if flag >= 0 then
      local xwall = flag == 0 and 0.0 or L
      local direction = flag == 0 and 1 or -1
      VX[i] = direction * sqrt(-log(1.0 - rand(m))) * mpv
      VY[i] = stdev * randn(m) + (box and 0 or (flag == 0 and vw0 or vw1))
      local dtr = tau * (X[i] - xwall) / (X[i] - XO[i])
      local y, old_y = Y[i], YO[i]
      local a = old_y + ((y - old_y) * ((X[i] - xwall) / (X[i] - XO[i])))
      X[i] = xwall + VX[i] * dtr
      dtr = tau * (Y[i] - a) / (Y[i] - YO[i])
      Y[i] = a + VY[i] * dtr
    end
    if box then
      if Y[i] < 0 then Y[i] = 0 end
      if Y[i] > L then Y[i] = L end
      if X[i] < 0 then X[i] = 0 end
      if X[i] > L then X[i] = L end
    end
  end
end

function K.sort(m)
  local L, n, ncx, ncy = K.L, m.n, m.ncx, m.ncy
  local X, Y, cell_n, index, Xref = m.x, m.y, m.cell_n, m.index, m.Xref
  local cx, cy = m.cx or {}, m.cy or {}
  m.cx, m.cy = cx, cy
  for i = 0, n - 1 do
    local jx = int(X[i] * ncx / L)
    local jy = int(Y[i] * ncy / (m.length * L))
    cx[i] = (jx < ncx) and jx or ncx - 1
    if jy < 0 then cy[i] = 0 else cy[i] = (jy < ncy) and jy or ncy - 1 end
  end
  for c = 0, ncx * ncy - 1 do cell_n[c] = 0 end
  for i = 0, n - 1 do
    local c = cy[i] * ncx + cx[i]
    cell_n[c] = cell_n[c] + 1
  end
  local mm = 0
  for c = 0, ncx * ncy - 1 do index[c] = mm; mm = mm + cell_n[c] end
  local temp = {}
  for c = 0, ncx * ncy - 1 do temp[c] = 0 end
  for i = 0, n - 1 do
    local c = cy[i] * ncx + cx[i]
    Xref[index[c] + temp[c]] = i
    temp[c] = temp[c] + 1
  end
end

function K.collide(m)
  local VX, VY, crmax, selxtra, cell_n, index, Xref = m.vx, m.vy, m.crmax, m.selxtra, m.cell_n, m.index, m.Xref
  local coeff, iso, garcia = m.coeff, m.fix.iso, m.fix.garcia
  for c = 0, m.ncx * m.ncy - 1 do
    local number = cell_n[c]
    if number >= 2 then
      local select
      if garcia then select = coeff * number * (number - 1) * crmax[c] + selxtra[c]
      else select = coeff * number * number * crmax[c] + selxtra[c] end
      local nsel = int(select)
      selxtra[c] = select - nsel
      local crm = crmax[c]
      for _ = 1, nsel do
        local k = int(rand(m) * number)
        local kk = (int(k + rand(m) * (number - 1)) + 1) % number
        local ip1 = Xref[k + index[c]]
        local ip2 = Xref[kk + index[c]]
        local dx, dy = VX[ip1] - VX[ip2], VY[ip1] - VY[ip2]
        local cr = sqrt(dx * dx + dy * dy)
        if cr > crm then crm = cr end
        if cr / crmax[c] > rand(m) then
          m.colSum = m.colSum + 1
          local vcmx, vcmy = 0.5 * (VX[ip1] + VX[ip2]), 0.5 * (VY[ip1] + VY[ip2])
          local rx, ry
          if iso then
            local th = 6.283185307179586 * rand(m)
            rx, ry = cr * cos(th), cr * math.sin(th)
          else
            local cos_th = 1.0 - 2.0 * rand(m)
            local sin_th = sqrt(1.0 - cos_th * cos_th)
            rx, ry = cr * cos_th, cr * sin_th
          end
          VX[ip1], VY[ip1] = vcmx + 0.5 * rx, vcmy + 0.5 * ry
          VX[ip2], VY[ip2] = vcmx - 0.5 * rx, vcmy - 0.5 * ry
        end
        if not garcia then crmax[c] = crm end
      end
      if garcia then crmax[c] = crm end
    end
  end
end

function K.step(m, steps)
  for _ = 1, steps or 1 do
    K.move(m)
    K.sort(m)
    K.collide(m)
  end
end

-- theory values (SI)
function K.meanSpeedTheory(T) return 0.25 * sqrt(8.0 * math.pi * K.boltz * T / K.mass) end
function K.mach(T) return sqrt(5.0 / 3.0 * K.boltz * T / K.mass) end

return K
