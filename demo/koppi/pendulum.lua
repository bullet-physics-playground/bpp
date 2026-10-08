--
-- pendulum.lua - Double inverted pendulum on a cart
--
-- Lua port of https://github.com/koppi/pendulum (index.html). A cart runs on
-- a 5 m rail; a double pendulum is hinged to its front side, so it can swing
-- the full circle past the cart. All control is done in plain Lua, no
-- libraries:
--
--   * LQR balancing about the up-up equilibrium, gains from an exact solution
--     of the continuous-time algebraic Riccati equation (matrix sign function
--     of the Hamiltonian, polished with Kleinman iterations)
--   * swing-up from the hanging rest state by iLQR trajectory optimisation on
--     the full nonlinear model, with the LQR cost-to-go as terminal cost,
--     tracked by a time-varying LQR; the optimisation runs in small slices
--     inside the frame loop while the pendulum is being settled
--   * energy-pumping swing-up as a fallback if no trajectory can be found
--   * partial feedback linearisation for the settling phase
--
-- The dynamics are the Euler-Lagrange equations of the cart + 2 links,
-- integrated here with RK4 (the same equations the planner optimises over),
-- and the bodies you see are posed from that state every frame. Bullet is not
-- in the loop: the swing-up trajectory is open-loop unstable, so the control
-- design only holds up against the exact model it was made for.
--
-- State is [x, dx, th1, dth1, th2, dth2]; th = 0 is upright, th = pi hanging.
-- th1 is link 1 against the vertical, th2 link 2 against the vertical (not
-- relative to link 1), both positive towards +x.
--
-- Parameters (panel):   power, limits, adaptation, scenario, target,
--                       and the plant: cartMass, damping, mass1/len1,
--                       mass2/len2, gravity (len = pivot to centre of mass;
--                       a link is twice that long)
-- Keys:                 Z  reset to the chosen scenario
--                       K  shock test (random kick to cart and link 1)
--                       1 2 3 4  put both links at rest at (0,0) (0,pi)
--                                (pi,0) (pi,pi)
--
-- Left out of the browser original: the oscilloscope plots, the CSV download
-- and the mouse-wheel zoom / click-to-set-target (use the camera and the
-- `target` parameter). The status line printed every 2 s carries the same
-- telemetry.
--
-- Usage: bpp demo/koppi/pendulum.lua
--

local common = require "common"

local sin, cos, sqrt, abs, floor = math.sin, math.cos, math.sqrt, math.abs, math.floor
local max, min = math.max, math.min
local PI = math.pi

local function clamp(x, lo, hi) return x < lo and lo or (x > hi and hi or x) end
local function sign(x) return x > 0 and 1 or (x < 0 and -1 or 0) end
local function isfinite(x) return x == x and x ~= math.huge and x ~= -math.huge end

-- Wrap to [-pi, pi). Lua's % takes the sign of the divisor, so no fix-up.
local function normalizeAngle(a)
  return (a + PI) % (2 * PI) - PI
end

-- ---------------------------------------------------------------------------
-- Minimal dense linear algebra (matrices up to 12x12) for the Riccati solver
-- ---------------------------------------------------------------------------

local function matZeros(r, c)
  local A = {}
  for i = 1, r do
    local row = {}
    for j = 1, c do row[j] = 0 end
    A[i] = row
  end
  return A
end

local function matMul(A, B)
  local r, k, c = #A, #B, #B[1]
  local C = matZeros(r, c)
  for i = 1, r do
    local Ai, Ci = A[i], C[i]
    for m = 1, k do
      local a = Ai[m]
      if a ~= 0 then
        local Bm = B[m]
        for j = 1, c do Ci[j] = Ci[j] + a * Bm[j] end
      end
    end
  end
  return C
end

local function matT(A)
  local T = matZeros(#A[1], #A)
  for i = 1, #A do
    for j = 1, #A[1] do T[j][i] = A[i][j] end
  end
  return T
end

-- A + s*B (s defaults to 1)
local function matAdd(A, B, s)
  s = s or 1
  local C = {}
  for i = 1, #A do
    local row = {}
    for j = 1, #A[i] do row[j] = A[i][j] + s * B[i][j] end
    C[i] = row
  end
  return C
end

local function matMaxAbs(A)
  local m = 0
  for i = 1, #A do
    for j = 1, #A[i] do m = max(m, abs(A[i][j])) end
  end
  return m
end

local function matFrob(A)
  local s = 0
  for i = 1, #A do
    for j = 1, #A[i] do s = s + A[i][j] * A[i][j] end
  end
  return sqrt(s)
end

-- Gauss-Jordan inverse with partial pivoting
local function matInv(A)
  local n = #A
  local W = {}
  for i = 1, n do
    local row = {}
    for j = 1, n do
      row[j] = A[i][j]
      row[n + j] = (i == j) and 1 or 0
    end
    W[i] = row
  end
  for col = 1, n do
    local piv = col
    for r = col + 1, n do
      if abs(W[r][col]) > abs(W[piv][col]) then piv = r end
    end
    if abs(W[piv][col]) < 1e-14 then error("singular matrix") end
    W[col], W[piv] = W[piv], W[col]
    local Wc = W[col]
    local d = Wc[col]
    for j = 1, 2 * n do Wc[j] = Wc[j] / d end
    for r = 1, n do
      if r ~= col then
        local Wr = W[r]
        local f = Wr[col]
        if f ~= 0 then
          for j = 1, 2 * n do Wr[j] = Wr[j] - f * Wc[j] end
        end
      end
    end
  end
  local inv = {}
  for i = 1, n do
    local row = {}
    for j = 1, n do row[j] = W[i][n + j] end
    inv[i] = row
  end
  return inv
end

-- Gaussian elimination for a dense square system
local function solveLinear(A, b)
  local n = #b
  local W = {}
  for i = 1, n do
    local row = {}
    for j = 1, n do row[j] = A[i][j] end
    row[n + 1] = b[i]
    W[i] = row
  end
  for col = 1, n do
    local piv = col
    for r = col + 1, n do
      if abs(W[r][col]) > abs(W[piv][col]) then piv = r end
    end
    if abs(W[piv][col]) < 1e-14 then error("singular system") end
    W[col], W[piv] = W[piv], W[col]
    local Wc = W[col]
    local d = Wc[col]
    for j = col, n + 1 do Wc[j] = Wc[j] / d end
    for r = 1, n do
      if r ~= col then
        local Wr = W[r]
        local f = Wr[col]
        if f ~= 0 then
          for j = col, n + 1 do Wr[j] = Wr[j] - f * Wc[j] end
        end
      end
    end
  end
  local x = {}
  for i = 1, n do x[i] = W[i][n + 1] end
  return x
end

-- Lyapunov equation  F*X + X*F' + Q = 0  (X symmetric), solved as an n^2 x n^2 system
local function lyapSolve(F, Q)
  local n = #F
  local sz = n * n
  local A, b = matZeros(sz, sz), {}
  for i = 1, n do
    for j = 1, n do
      local row = (i - 1) * n + j
      for k = 1, n do
        A[row][(k - 1) * n + j] = A[row][(k - 1) * n + j] + F[i][k]   -- (F*X)_ij
        A[row][(i - 1) * n + k] = A[row][(i - 1) * n + k] + F[j][k]   -- (X*F')_ij
      end
      b[row] = -Q[i][j]
    end
  end
  local x, X = solveLinear(A, b), matZeros(n, n)
  for i = 1, n do
    for j = 1, n do X[i][j] = x[(i - 1) * n + j] end
  end
  for i = 1, n do
    for j = i + 1, n do
      local val = 0.5 * (X[i][j] + X[j][i])
      X[i][j] = val
      X[j][i] = val
    end
  end
  return X
end

-- Continuous-time algebraic Riccati equation   A'P + PA - P B R^-1 B' P + Q = 0
--
-- Solved through the matrix sign function of the Hamiltonian
--   Ham = [[A, -B R^-1 B'], [-Q, -A']]
-- Newton's iteration Z <- (cZ + (cZ)^-1)/2 converges quadratically to sign(Ham);
-- the stable invariant subspace spanned by the columns of (I - sign(Ham)) has
-- the form [u; P*u], so P follows from a least-squares fit. A few
-- Newton/Kleinman steps then polish P to machine precision.
local function solveCARE(A, B, Q, R)
  local n = #A
  local At, Bt, Rinv = matT(A), matT(B), matInv(R)
  local G = matMul(matMul(B, Rinv), Bt)

  local Ham = matZeros(2 * n, 2 * n)
  for i = 1, n do
    for j = 1, n do
      Ham[i][j] = A[i][j]
      Ham[i][j + n] = -G[i][j]
      Ham[i + n][j] = -Q[i][j]
      Ham[i + n][j + n] = -At[i][j]
    end
  end

  local Z = {}
  for i = 1, 2 * n do
    Z[i] = {}
    for j = 1, 2 * n do Z[i][j] = Ham[i][j] end
  end
  for _ = 1, 60 do
    local Zi = matInv(Z)
    local c = sqrt(matFrob(Zi) / matFrob(Z))
    if c ~= c or c == 0 then c = 1 end
    local diff = 0
    local Zn = matZeros(2 * n, 2 * n)
    for i = 1, 2 * n do
      for j = 1, 2 * n do
        Zn[i][j] = 0.5 * (c * Z[i][j] + Zi[i][j] / c)
        diff = max(diff, abs(Zn[i][j] - Z[i][j]))
      end
    end
    Z = Zn
    if diff < 1e-12 * max(1, matMaxAbs(Z)) then break end
  end

  local U1, U2 = matZeros(n, 2 * n), matZeros(n, 2 * n)
  for i = 1, n do
    for j = 1, 2 * n do
      U1[i][j] = (i == j and 1 or 0) - Z[i][j]
      U2[i][j] = (i + n == j and 1 or 0) - Z[i + n][j]
    end
  end
  local U1t = matT(U1)
  local P = matMul(matMul(U2, U1t), matInv(matMul(U1, U1t)))
  for i = 1, n do
    for j = i + 1, n do
      local val = 0.5 * (P[i][j] + P[j][i])
      P[i][j] = val
      P[j][i] = val
    end
  end

  for _ = 1, 12 do
    local Kk = matMul(matMul(Rinv, Bt), P)
    local Ac = matAdd(A, matMul(B, Kk), -1)
    local Qc = matAdd(Q, matMul(matMul(matT(Kk), R), Kk))
    local ok, Pn = pcall(lyapSolve, matT(Ac), Qc)
    if not ok then break end
    local d = 0
    for i = 1, n do
      for j = 1, n do d = max(d, abs(Pn[i][j] - P[i][j])) end
    end
    P = Pn
    if d < 1e-10 * max(1, matMaxAbs(P)) then break end
  end
  return { P = P, K = matMul(matMul(Rinv, Bt), P)[1] }
end

-- ---------------------------------------------------------------------------
-- Plant
-- ---------------------------------------------------------------------------

-- Physical parameters. l1/l2 are pivot-to-centre-of-mass distances: a link is
-- twice that long, L1 being the length of link 1.
local M, m1, m2 = 1.5, 0.5, 0.5     -- cart, link 1, link 2 mass (kg)
local l1, l2 = 0.2, 0.2
local L1 = 2 * l1
local I1 = (1 / 12) * m1 * (0.02 + 4 * l1 * l1)
local I2 = (1 / 12) * m2 * (0.02 + 4 * l2 * l2)
local g, c_damping = 9.81, 0.0
local adaptiveMode = true
local K = { 3.2, 6.5, -303.4, -8.9, 343.9, 41.4 }   -- balancing LQR gain
local P_lqr = nil                  -- Riccati matrix of the balancing LQR
local catchLevel = 0               -- e'Pe below which the LQR is handed control
local CATCH_MARGIN = 1.0           -- safety factor on the catch region

local state = { 0, 0, PI, 0, PI, 0 }     -- x, dx, th1, dth1, th2, dth2
local x_soll = 0                         -- cart position target

-- LQR weights. Light on cart position, heavy on angular rates: this maximises
-- the basin of attraction reachable inside the +-U_MAX actuator limit, which
-- is what the swing-up has to aim at.
local LQR_Q = { 5.0, 0.1, 10.0, 50.0, 10.0, 50.0 }
local LQR_R = 0.5
local U_MAX = 50.0                 -- actuator limit (N)

-- Linearisation of  M(q) q'' + C(q,q') q' + G(q) = [u,0,0]'  at th1 = th2 = 0,
-- q' = 0. There M(q) is constant, C vanishes and G is linear, so
--   q'' = M0^-1 ([u,0,0]' - dG/dq * q - D * q')
local function linearizeUpUp()
  local a1 = m1 * l1 + m2 * L1
  local a2 = m2 * l2
  local M0 = {
    { M + m1 + m2, a1, a2 },
    { a1, I1 + m1 * l1 * l1 + m2 * L1 * L1, m2 * L1 * l2 },
    { a2, m2 * L1 * l2, I2 + m2 * l2 * l2 },
  }
  local N = matInv(M0)
  local A, B = matZeros(6, 6), matZeros(6, 1)
  A[1][2] = 1; A[3][4] = 1; A[5][6] = 1
  local rows = { 2, 4, 6 }                    -- x'', th1'', th2''
  for i = 1, 3 do
    local row = rows[i]
    A[row][3] = N[i][2] * a1 * g              -- d/dth1 (destabilising gravity)
    A[row][5] = N[i][3] * a2 * g              -- d/dth2
    A[row][4] = -N[i][2] * c_damping          -- joint damping
    A[row][6] = -N[i][3] * c_damping
    B[row][1] = N[i][1]
  end
  return A, B
end

local function synthesizeLQR()
  I1 = (1 / 12) * m1 * (0.02 + 4 * l1 * l1)
  I2 = (1 / 12) * m2 * (0.02 + 4 * l2 * l2)
  local ok, err = pcall(function()
    local A, B = linearizeUpUp()
    local Q = matZeros(6, 6)
    for i = 1, 6 do Q[i][i] = LQR_Q[i] end
    local sol = solveCARE(A, B, Q, { { LQR_R } })
    for i = 1, 6 do
      if not isfinite(sol.K[i]) then error("non-finite gain") end
    end
    -- P (and with it the catch test and the planner's terminal cost) always
    -- follows the current plant; only the feedback gain is frozen when
    -- adaptation is switched off, which is the point of that switch.
    P_lqr = sol.P
    if adaptiveMode then K = sol.K end
    -- Largest sub-level set {e: e'Pe <= catchLevel} on which the unsaturated
    -- LQR force stays within +-U_MAX:  max|Ke| over e'Pe <= c  is sqrt(c K P^-1 K').
    -- Monte-Carlo sweeps show this set sits well inside the true basin, so it
    -- is a safe hand-over test from swing-up to balancing.
    local Pinv = matInv(P_lqr)
    local kpk = 0
    for i = 1, 6 do
      for j = 1, 6 do kpk = kpk + K[i] * Pinv[i][j] * K[j] end
    end
    catchLevel = CATCH_MARGIN * U_MAX * U_MAX / kpk
  end)
  if not ok then
    print("LQR synthesis failed, keeping previous gains: " .. tostring(err))
  end
end

-- State derivative [dx, ddx, dth1, ddth1, dth2, ddth2] for cart force u,
-- written into `out`.
local function eom(x, u, out)
  local dx, th1, dth1, th2, dth2 = x[2], x[3], x[4], x[5], x[6]
  local s1, c1, s2, c2 = sin(th1), cos(th1), sin(th2), cos(th2)
  local s12, c12 = sin(th1 - th2), cos(th1 - th2)
  local a1, a2, b12 = m1 * l1 + m2 * L1, m2 * l2, m2 * L1 * l2

  -- Inertia matrix M(q) - symmetric
  local M11 = M + m1 + m2
  local M12 = a1 * c1
  local M13 = a2 * c2
  local M22 = I1 + m1 * l1 * l1 + m2 * L1 * L1
  local M23 = b12 * c12
  local M33 = I2 + m2 * l2 * l2

  -- Right-hand side  H(u) - C(q,q') q' - G(q) - damping
  local r0 = u + a1 * s1 * dth1 * dth1 + a2 * s2 * dth2 * dth2
  local r1 = -b12 * s12 * dth2 * dth2 + a1 * g * s1 - c_damping * dth1
  local r2 = b12 * s12 * dth1 * dth1 + a2 * g * s2 - c_damping * dth2

  -- Solve M q'' = rhs with the symmetric adjugate (cofactors written out)
  local cA = M22 * M33 - M23 * M23
  local cB = M13 * M23 - M12 * M33
  local cC = M12 * M23 - M13 * M22
  local cD = M11 * M33 - M13 * M13
  local cE = M13 * M12 - M11 * M23
  local cF = M11 * M22 - M12 * M12
  local det = M11 * cA + M12 * cB + M13 * cC

  out[1] = dx
  out[2] = (cA * r0 + cB * r1 + cC * r2) / det
  out[3] = dth1
  out[4] = (cB * r0 + cD * r1 + cE * r2) / det
  out[5] = dth2
  out[6] = (cC * r0 + cE * r1 + cF * r2) / det
  return out
end

-- Classical Runge-Kutta 4 step of length h - used by both the simulation and
-- the trajectory optimiser. Writes into `out` (may be x itself) or a new table.
local k1, k2, k3, k4, rkS = {}, {}, {}, {}, {}
local function rk4(x, u, h, out)
  out = out or {}
  eom(x, u, k1)
  for i = 1, 6 do rkS[i] = x[i] + 0.5 * h * k1[i] end
  eom(rkS, u, k2)
  for i = 1, 6 do rkS[i] = x[i] + 0.5 * h * k2[i] end
  eom(rkS, u, k3)
  for i = 1, 6 do rkS[i] = x[i] + h * k3[i] end
  eom(rkS, u, k4)
  for i = 1, 6 do
    out[i] = x[i] + (h / 6) * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i])
  end
  return out
end

-- Partial Feedback Linearization: the force u that realises a commanded cart
-- acceleration v. Splitting M(q) q'' + C q' + G = [u,0,0]' into the cart row
-- and the 2x2 pendulum block gives th'' = th''_p + th''_v * v, hence
-- u = alpha*v + phi.
local function pflForce(acc, th1, dth1, th2, dth2)
  local s1, c1, s2, c2 = sin(th1), cos(th1), sin(th2), cos(th2)
  local s12, c12 = sin(th1 - th2), cos(th1 - th2)
  local M11 = M + m1 + m2
  local M12 = (m1 * l1 + m2 * L1) * c1
  local M13 = m2 * l2 * c2
  local M21 = M12
  local M22, M23 = I1 + m1 * l1 ^ 2 + m2 * L1 ^ 2, m2 * L1 * l2 * c12
  local M31, M32, M33 = M13, M23, I2 + m2 * l2 ^ 2

  -- Coriolis/centrifugal terms (C q') - quadratic in the joint rates
  local C1 = -(m1 * l1 + m2 * L1) * s1 * dth1 * dth1 - m2 * l2 * s2 * dth2 * dth2
  local C2 = m2 * L1 * l2 * s12 * dth2 * dth2
  local C3 = -m2 * L1 * l2 * s12 * dth1 * dth1
  local G1, G2, G3 = 0, -(m1 * l1 + m2 * L1) * g * s1, -m2 * g * l2 * s2

  -- Pendulum subsystem inertia (2x2)
  local detP = M22 * M33 - M23 * M32
  -- th'' components without v
  local th1ddP = (M33 * (-C2 - G2 - c_damping * dth1) - M23 * (-C3 - G3 - c_damping * dth2)) / detP
  local th2ddP = (-M32 * (-C2 - G2 - c_damping * dth1) + M22 * (-C3 - G3 - c_damping * dth2)) / detP
  -- th'' per unit acc
  local th1ddV = (-M33 * M21 + M23 * M31) / detP
  local th2ddV = (M32 * M21 - M22 * M31) / detP

  -- u = M11 acc + M12 (th1ddP + th1ddV acc) + M13 (th2ddP + th2ddV acc) + C1 + G1
  local alpha = M11 + M12 * th1ddV + M13 * th2ddV
  local phi = M12 * th1ddP + M13 * th2ddP + C1 + G1
  return alpha * acc + phi
end

-- ---------------------------------------------------------------------------
-- Energy-based swing-up (fallback) and the energy terms the settling uses
-- ---------------------------------------------------------------------------
-- With the cart acceleration v as the (PFL) input, the energy of the pendulum
-- pair obeys exactly
--     E' = -v W - c (th1'^2 + th2'^2),   W = a1 cos(th1) th1' + a2 cos(th2) th2'
-- with a1 = m1 l1 + m2 L1, a2 = m2 l2. Choosing v ~ (E - Ed) W therefore makes
-- (E - Ed)^2 / 2 a Lyapunov function and drives the energy to its up-up value.

-- Result is one shared table, overwritten by the next call.
local EN = {}
local function pendulumEnergy(th1, dth1, th2, dth2)
  local a1, a2 = m1 * l1 + m2 * L1, m2 * l2
  local M22 = I1 + m1 * l1 * l1 + m2 * L1 * L1
  local M23 = m2 * L1 * l2 * cos(th1 - th2)
  local M33 = I2 + m2 * l2 * l2
  EN.E = 0.5 * (M22 * dth1 * dth1 + 2 * M23 * dth1 * dth2 + M33 * dth2 * dth2)
       + a1 * g * cos(th1) + a2 * g * cos(th2)
  EN.Ed = (a1 + a2) * g
  EN.W = a1 * cos(th1) * dth1 + a2 * cos(th2) * dth2
  EN.E1 = 0.5 * M22 * dth1 * dth1 + a1 * g * cos(th1)
  EN.E1d = a1 * g
  EN.W1 = a1 * cos(th1) * dth1
  EN.E2 = 0.5 * M33 * dth2 * dth2 + a2 * g * cos(th2)
  EN.E2d = a2 * g
  EN.W2 = a2 * cos(th2) * dth2
  return EN
end

-- Sensitivity of the joint accelerations to the commanded cart acceleration.
local function thetaDDotPerV(th1, th2)
  local M12 = (m1 * l1 + m2 * L1) * cos(th1)
  local M13 = m2 * l2 * cos(th2)
  local M22 = I1 + m1 * l1 ^ 2 + m2 * L1 ^ 2
  local M23 = m2 * L1 * l2 * cos(th1 - th2)
  local M33 = I2 + m2 * l2 ^ 2
  local detP = M22 * M33 - M23 * M23
  return (-M33 * M12 + M23 * M13) / detP, (M23 * M12 - M22 * M13) / detP
end

-- Fallback energy pumping, used only when no swing-up trajectory could be found.
local SWING = { kE = 3.412, k1 = 0.822, k2 = 0, eSat = 3.3, kRel = 1.934, kRelD = 5.157,
                relMax = 2.66, kx = 0.393, kd = 1.052, vMax = 9.405, kick = 2.779, kickW = 8.23 }

local function sat(val) return clamp(val, -SWING.eSat, SWING.eSat) end

-- Commanded cart acceleration during the fallback swing-up.
local function swingAccel(t)
  local th1, th2 = normalizeAngle(state[3]), normalizeAngle(state[5])
  local dth1, dth2 = state[4], state[6]
  local e = pendulumEnergy(th1, dth1, th2, dth2)

  -- Energy pumping: total energy plus a per-link share so the energy cannot
  -- all end up spinning the outer link while the inner one hangs.
  local acc = SWING.kE * sat(e.E - e.Ed) * e.W
            + SWING.k1 * sat(e.E1 - e.E1d) * e.W1
            + SWING.k2 * sat(e.E2 - e.E2d) * e.W2

  -- Relative-angle shaping: pushes the two links towards moving as one body.
  -- Inverting the coupling d(th1''-th2'')/dv turns a PD law on th1-th2 into a
  -- v command.
  if SWING.kRel ~= 0 or SWING.kRelD ~= 0 then
    local d, dd = normalizeAngle(th1 - th2), dth1 - dth2
    local s1, s2 = thetaDDotPerV(th1, th2)
    local dv = s1 - s2
    if abs(dv) > 1e-6 then
      acc = acc + clamp(-(SWING.kRel * sin(d) + SWING.kRelD * dd) / dv, -SWING.relMax, SWING.relMax)
    end
  end

  -- Keep the cart near its set point so the rail stops are not hit.
  acc = acc + (-SWING.kx * (state[1] - x_soll) - SWING.kd * state[2])

  -- Hanging at rest is an exact equilibrium (W = 0 and th' = 0), so nothing
  -- would ever start: dither the cart until the pendulums are moving.
  if abs(dth1) + abs(dth2) < 0.05 and abs(e.W) < 0.02 and e.E - e.Ed < -0.1 then
    acc = acc + SWING.kick * sin(SWING.kickW * t)
  end
  return clamp(acc, -SWING.vMax, SWING.vMax)
end

-- ---------------------------------------------------------------------------
-- Swing-up by trajectory optimisation (iLQR) + time-varying LQR tracking
-- ---------------------------------------------------------------------------
-- Energy pumping on its own cannot bring a double pendulum to the up-up
-- position: it drives the total energy to its upright value but says nothing
-- about how that energy is split between the links, and the balancing LQR only
-- accepts a very small neighbourhood of the equilibrium. The swing-up is
-- therefore solved as an optimal control problem - iLQR on the full nonlinear
-- model, starting from the hanging rest state, with the LQR cost-to-go e'Pe as
-- terminal cost - and the resulting trajectory is tracked by a time-varying
-- LQR, which is what absorbs the model/discretisation mismatch.
--
-- The optimisation runs in small slices inside the animation loop while the
-- controller is still damping the pendulums, so nothing blocks the UI.

-- Restarts alternate between a coarse and a fine discretisation. Neither wins
-- everywhere: the coarse grid converges more often on the default plant, while
-- very long links only ever produced usable trajectories on the fine one.
local PLAN_N_COARSE = 125
local PLAN_N_MAX = 220
local PLAN_STEP_MAX = 0.02    -- trajectory is refined to at least this step
                              -- before the tracking gains are computed
local PLAN_T_REF = 2.5        -- horizon for the default plant (s)
local PLAN_OMEGA_REF = 4.22   -- its slow hanging mode (rad/s)
local PLAN_ITERS = 120        -- iLQR iterations per restart
local PLAN_RESTARTS = 20      -- random restarts before giving up
local PLAN_GOOD = 5.0         -- terminal e'Pe that counts as solved
local PLAN_BUDGET_MS = 8      -- optimisation work per animation frame
local PLAN_INIT = 0.3         -- amplitude of the random initial force profile
-- A restart that is still far off after PLAN_CHECK_AT iterations essentially
-- never recovers, so it is abandoned instead of burning the full budget.
local PLAN_CHECK_AT = 30
-- The checkpoint is relative to the catch region, because the scale of e'Pe
-- changes with the plant. Measured over seven plants, every restart that ended
-- up usable was below ~21x at the checkpoint, so anything above that is dropped.
local PLAN_CHECK_FACTOR = 22
local PLAN_ACCEPT = 60        -- terminal e'Pe worth verifying at all
local PLAN_ROUNDS = 10        -- extra search rounds after a failed swing-up
local BALANCE_REF_TAU = 1.5   -- s, time constant for walking the cart home

local function nowMs() return v:getTime() * 1000 end

-- Slow hanging mode of the two links, from det(K_g - w^2 M_p) = 0. The swing-up
-- horizon is scaled by it so long or low-gravity pendulums get proportionally
-- more time, while the number of knots - and so the cost of a sweep - is fixed.
local function hangingMode()
  local a1, a2 = m1 * l1 + m2 * L1, m2 * l2
  local M22 = I1 + m1 * l1 * l1 + m2 * L1 * L1
  local M23 = m2 * L1 * l2
  local M33 = I2 + m2 * l2 * l2
  local D = M22 * M33 - M23 * M23
  local B = g * (a1 * M33 + a2 * M22)
  local C = a1 * a2 * g * g
  local disc = max(0, B * B - 4 * D * C)
  local w2 = (B - sqrt(disc)) / (2 * D)
  return w2 > 1e-9 and sqrt(w2) or PLAN_OMEGA_REF
end
local function planHorizon()
  return max(1.5, min(9.0, PLAN_T_REF * PLAN_OMEGA_REF / hangingMode()))
end

-- xlim is the soft rail barrier used while planning. Keeping it well inside
-- the +-2.5 m stops leaves room for tracking error and, as it turns out, also
-- makes the optimiser converge more often.
local PLAN_COST = { rw = 0.02, qx = 0.5, wf = 60, xlim = 1.2, qup = 25, qv = 0.2, ramp = 3 }

-- The force is parameterised as u = U_MAX*tanh(w), so the actuator limit holds
-- by construction and the optimisation stays unconstrained.
local function squashForce(w) return U_MAX * math.tanh(w) end

-- State error with angles wrapped, into `out`
local function planErr(x, out)
  out[1] = x[1]
  out[2] = x[2]
  out[3] = normalizeAngle(x[3])
  out[4] = x[4]
  out[5] = normalizeAngle(x[5])
  out[6] = x[6]
  return out
end

-- e'Pe
local function quadForm(Pm, e)
  local s = 0
  for i = 1, 6 do
    local Pi, r = Pm[i], 0
    for j = 1, 6 do r = r + Pi[j] * e[j] end
    s = s + e[i] * r
  end
  return s
end

-- Central-difference Jacobians of one RK4 step about (xk, uk): A (6x6, w.r.t.
-- the state) and B (6-vector, w.r.t. the control), written into the given
-- tables. The control perturbation is passed as the two perturbed forces
-- ukp / ukm, because the caller differentiates w.r.t. w in u = squashForce(w)
-- (iLQR) or w.r.t. u itself (tracking gains).
local jXp, jXm, jFp, jFm = {}, {}, {}, {}
local function stepJacobian(xk, uk, ukp, ukm, dtP, A, B)
  local h = 1e-5
  for j = 1, 6 do
    for i = 1, 6 do jXp[i] = xk[i]; jXm[i] = xk[i] end
    jXp[j] = jXp[j] + h
    jXm[j] = jXm[j] - h
    rk4(jXp, uk, dtP, jFp)
    rk4(jXm, uk, dtP, jFm)
    for i = 1, 6 do A[i][j] = (jFp[i] - jFm[i]) / (2 * h) end
  end
  rk4(xk, ukp, dtP, jFp)
  rk4(xk, ukm, dtP, jFm)
  for i = 1, 6 do B[i] = (jFp[i] - jFm[i]) / (2 * h) end
end

local function makeSwingSolver(x0, seed, dtP, N)
  local a1, a2 = m1 * l1 + m2 * L1, m2 * l2
  local cst = PLAN_COST
  local rng = seed
  -- JS-compatible LCG: the 53-bit double product is what the original reduces
  -- mod 2^31, so reducing the same double here reproduces its sequence.
  local function rnd()
    rng = (rng * 1103515245 + 12345) % 2147483648
    return rng / 2147483647 * 2 - 1
  end

  local rho, rhov = {}, {}
  for k = 1, N do
    rho[k] = cst.qup * (k / N) ^ cst.ramp
    rhov[k] = cst.qv * (k / N) ^ cst.ramp
  end

  local eT = {}
  local function runCost(x, w, k)
    local c = 0.5 * cst.rw * w * w + 0.5 * cst.qx * x[1] * x[1]
    local o = abs(x[1]) - cst.xlim
    if o > 0 then c = c + 200 * o * o end
    c = c + rho[k] * (a1 * (1 - cos(x[3])) + a2 * (1 - cos(x[5])))
    c = c + 0.5 * rhov[k] * (x[4] * x[4] + x[6] * x[6])
    return c
  end
  local function termCost(x)
    return 0.5 * cst.wf * quadForm(P_lqr, planErr(x, eT))
  end
  local function total(X, W)
    local c = 0
    for k = 1, N do c = c + runCost(X[k], W[k], k) end
    return c + termCost(X[N + 1])
  end

  -- trajectory buffers: X[1..N+1], W[1..N]; (Xn, Wn) are the line-search candidate
  local W, X, Wn, Xn = {}, {}, {}, {}
  for k = 1, N + 1 do X[k] = {}; Xn[k] = {} end
  for k = 1, N do W[k] = rnd() * PLAN_INIT end
  for i = 1, 6 do X[1][i] = x0[i]; Xn[1][i] = x0[i] end
  for k = 1, N do rk4(X[k], squashForce(W[k]), dtP, X[k + 1]) end
  local J = total(X, W)
  local mu, iter = 1e-3, 0
  local kff, Kfb = {}, {}
  for k = 1, N do kff[k] = 0; Kfb[k] = {} end

  -- per-sweep scratch
  local A, B = matZeros(6, 6), {}
  local lx, lxx, Qx = {}, matZeros(6, 6), {}
  local VA, VB, Qxx, Qux = matZeros(6, 6), {}, matZeros(6, 6), {}
  local Vx, Vxx, Vn = {}, matZeros(6, 6), matZeros(6, 6)

  local solver = { N = N }
  function solver.iterations() return iter end
  function solver.done() return iter >= PLAN_ITERS end
  function solver.terminal()
    return quadForm(P_lqr, planErr(X[N + 1], eT))
  end
  function solver.result()
    local U = {}
    for k = 1, N do U[k] = squashForce(W[k]) end
    return { X = X, U = U }
  end

  -- one iLQR sweep: backward Riccati recursion, then a line-searched rollout
  function solver.iterate()
    iter = iter + 1
    local e = planErr(X[N + 1], eT)
    for i = 1, 6 do
      local s = 0
      for j = 1, 6 do s = s + P_lqr[i][j] * e[j] end
      Vx[i] = cst.wf * s
      for j = 1, 6 do Vxx[i][j] = cst.wf * P_lqr[i][j] end
    end
    local okPass = true
    for k = N, 1, -1 do
      local x, w = X[k], W[k]
      stepJacobian(x, squashForce(w), squashForce(w + 1e-5), squashForce(w - 1e-5), dtP, A, B)

      for i = 1, 6 do lx[i] = 0 end
      for i = 1, 6 do for j = 1, 6 do lxx[i][j] = 0 end end
      lx[1] = cst.qx * x[1]
      local o = abs(x[1]) - cst.xlim
      if o > 0 then lx[1] = lx[1] + 400 * o * sign(x[1]) end
      lx[3] = rho[k] * a1 * sin(x[3])
      lx[5] = rho[k] * a2 * sin(x[5])
      lx[4] = rhov[k] * x[4]
      lx[6] = rhov[k] * x[6]
      lxx[1][1] = cst.qx + (o > 0 and 400 or 0)
      lxx[3][3] = max(0, rho[k] * a1 * cos(x[3]))
      lxx[5][5] = max(0, rho[k] * a2 * cos(x[5]))
      lxx[4][4] = rhov[k]
      lxx[6][6] = rhov[k]
      local lu, luu = cst.rw * w, cst.rw

      for i = 1, 6 do
        local s = lx[i]
        for j = 1, 6 do s = s + A[j][i] * Vx[j] end
        Qx[i] = s
      end
      local Qu = lu
      for j = 1, 6 do Qu = Qu + B[j] * Vx[j] end
      for i = 1, 6 do
        for j = 1, 6 do
          local s = 0
          for m = 1, 6 do s = s + Vxx[i][m] * A[m][j] end
          VA[i][j] = s
        end
        local s2 = 0
        for m = 1, 6 do s2 = s2 + Vxx[i][m] * B[m] end
        VB[i] = s2
      end
      for i = 1, 6 do
        for j = 1, 6 do
          local s = lxx[i][j]
          for m = 1, 6 do s = s + A[m][i] * VA[m][j] end
          Qxx[i][j] = s
        end
      end
      local Quu = luu
      for m = 1, 6 do Quu = Quu + B[m] * VB[m] end
      for j = 1, 6 do
        local s = 0
        for m = 1, 6 do s = s + B[m] * VA[m][j] end
        Qux[j] = s
      end

      local Quur = Quu + mu
      if not (Quur > 1e-9) then okPass = false; break end
      local kk = -Qu / Quur
      local KK = Kfb[k]
      for i = 1, 6 do KK[i] = -Qux[i] / Quur end
      kff[k] = kk
      for i = 1, 6 do
        Vx[i] = Qx[i] + KK[i] * Quu * kk + KK[i] * Qu + Qux[i] * kk
      end
      for i = 1, 6 do
        for j = 1, 6 do
          Vn[i][j] = Qxx[i][j] + KK[i] * Quu * KK[j] + KK[i] * Qux[j] + Qux[i] * KK[j]
        end
      end
      for i = 1, 6 do
        for j = i, 6 do
          local val = 0.5 * (Vn[i][j] + Vn[j][i])
          Vn[i][j] = val
          Vn[j][i] = val
        end
      end
      Vxx, Vn = Vn, Vxx
    end
    if not okPass then mu = mu * 10; return end

    local alphas = { 1, 0.5, 0.25, 0.1, 0.05, 0.02, 0.01, 0.003, 0.001 }
    for ai = 1, #alphas do
      local al = alphas[ai]
      local bad = false
      for k = 1, N do
        local dw = al * kff[k]
        local Kf, xnk, xk = Kfb[k], Xn[k], X[k]
        for j = 1, 6 do dw = dw + Kf[j] * (xnk[j] - xk[j]) end
        Wn[k] = max(-6, min(6, W[k] + dw))
        local xn1 = rk4(xnk, squashForce(Wn[k]), dtP, Xn[k + 1])
        for j = 1, 6 do
          if not isfinite(xn1[j]) then bad = true; break end
        end
        if bad then break end
      end
      if not bad then
        local Jn = total(Xn, Wn)
        if Jn < J - 1e-9 then
          W, Wn = Wn, W
          X, Xn = Xn, X
          J = Jn
          mu = max(1e-6, mu * 0.5)
          return
        end
      end
    end
    mu = mu * 4
  end
  return solver
end

-- Discrete time-varying LQR along the planned trajectory. Returns the tracking
-- gains Ks[k] for  u = u_nom[k] - Ks[k]*(x - x_nom[k]).
local TV_Q = { 1, 1, 20, 2, 20, 2 }
local TV_R = 0.05
local function trackingGains(Xn, Un, dtP)
  local N = #Un
  local S = {}
  for i = 1, 6 do
    S[i] = {}
    for j = 1, 6 do S[i][j] = P_lqr[i][j] end
  end
  local Sn, SA = matZeros(6, 6), matZeros(6, 6)
  local A, B, SB, BSA = matZeros(6, 6), {}, {}, {}
  local Ks = {}
  for k = N, 1, -1 do
    local uk = Un[k]
    stepJacobian(Xn[k], uk, uk + 1e-5, uk - 1e-5, dtP, A, B)

    for i = 1, 6 do
      local s = 0
      for m = 1, 6 do s = s + S[i][m] * B[m] end
      SB[i] = s
    end
    local BSB = TV_R
    for m = 1, 6 do BSB = BSB + B[m] * SB[m] end
    for i = 1, 6 do
      for j = 1, 6 do
        local s = 0
        for m = 1, 6 do s = s + S[i][m] * A[m][j] end
        SA[i][j] = s
      end
    end
    local Kk = {}
    for j = 1, 6 do
      local s = 0
      for m = 1, 6 do s = s + B[m] * SA[m][j] end
      BSA[j] = s
      Kk[j] = s / BSB
    end
    Ks[k] = Kk
    for i = 1, 6 do
      for j = 1, 6 do
        local s = TV_Q[i] * (i == j and 1 or 0)
        for m = 1, 6 do s = s + A[m][i] * SA[m][j] end
        s = s - BSA[i] * BSA[j] / BSB
        Sn[i][j] = s
      end
    end
    for i = 1, 6 do
      for j = i, 6 do
        local val = 0.5 * (Sn[i][j] + Sn[j][i])
        Sn[i][j] = val
        Sn[j][i] = val
      end
    end
    S, Sn = Sn, S
  end
  return Ks
end

-- The plan always starts from the hanging rest state, with the cart position
-- measured relative to the set point, so it stays valid when x_soll is moved.
local planner = {
  plan = nil,          -- {X, U, Kfb, N, dt, T} ready for execution
  signature = "",      -- plant parameters the current plan was made for
  solver = nil,
  attempt = 0,
  best = nil,
  bestQ = math.huge,
  bestDt = 0,          -- grid the best candidate was optimised on
  bestT = 0,
  failed = false,
  searching = false,   -- a round of restarts is in progress
  rounds = 0,
  status = "idle",
  iterMs = 0,          -- measured cost of one iLQR sweep
  horizon = PLAN_T_REF,
  knots = PLAN_N_COARSE,
  dt = PLAN_T_REF / PLAN_N_COARSE,
}

local function paramSignature()
  return table.concat({ M, m1, m2, l1, l2, g, c_damping }, ",")
end

function planner.invalidate()
  planner.plan = nil
  planner.solver = nil
  planner.attempt = 0
  planner.best = nil
  planner.bestQ = math.huge
  planner.bestDt = 0
  planner.bestT = 0
  planner.failed = false
  planner.searching = true
  planner.rounds = 0
  planner.status = "planning"
end

-- A swing-up that ran its course without the LQR taking over means the
-- trajectory was not good enough. Start another round of restarts while the
-- controller settles again, keeping the current plan to fall back on.
function planner.retry()
  if planner.bestQ <= PLAN_GOOD and planner.plan then return end
  if planner.searching or planner.rounds >= PLAN_ROUNDS then return end
  planner.attempt = 0
  planner.solver = nil
  planner.failed = false
  planner.searching = true
  planner.status = "replanning"
end

-- Restarts alternate between knot counts, so the grid a candidate was
-- optimised on has to travel with it - the tracking gains depend on it.
local function recordBest(q, res)
  planner.bestQ = q
  planner.best = res
  planner.bestDt = planner.dt
  planner.bestT = planner.horizon
end

-- Reaching the catch region is not quite the same as being held there: the
-- region is derived from the linearised model, and on slow plants (low g in
-- particular) a few per cent of the states it accepts are not actually
-- recoverable. So the hand-over is simulated too, and the trajectory is only
-- accepted if the LQR really brings the pendulum to rest upright.
local function holds(s0, h)
  local s = {}
  for i = 1, 6 do s[i] = s0[i] end
  local ref = s[1]
  -- The settling horizon has to follow the plant: at g = 1 m/s^2 the closed
  -- loop is several times slower than at 9.81, and a fixed window would
  -- reject perfectly good trajectories for not having finished yet.
  local span = floor(4 * planner.horizon / h + 0.5)
  for _ = 1, span do
    ref = ref + (0 - ref) * h / BALANCE_REF_TAU
    local a1, a2 = normalizeAngle(s[3]), normalizeAngle(s[5])
    local u = clamp(-(K[1] * (s[1] - ref) + K[2] * s[2] + K[3] * a1 + K[4] * s[4]
                      + K[5] * a2 + K[6] * s[6]), -U_MAX, U_MAX)
    rk4(s, u, h, s)
    for i = 1, 6 do
      if not isfinite(s[i]) then return false end
    end
    if abs(normalizeAngle(s[3])) > 0.9 or abs(normalizeAngle(s[5])) > 0.9 then return false end
    if abs(s[1]) > 2.4 then return false end
  end
  return abs(normalizeAngle(s[3])) < 0.03 and abs(normalizeAngle(s[5])) < 0.03
     and abs(s[1]) < 0.25 and abs(s[4]) < 0.15 and abs(s[6]) < 0.15
end

-- A swing-up trajectory is open-loop unstable, so the nominal by itself says
-- little: re-integrating the same forces at a different step size makes it
-- diverge (measured: a candidate scoring e'Pe = 0.1 on its own grid drifts to
-- e'Pe > 12000 when replayed open loop). What matters is the tracked
-- behaviour, so a candidate is flown in closed loop at simulation resolution
-- and accepted only if it actually reaches the catch region.
local vE = {}
local function verify(X, U, Kfb, dtP)
  local h = 1 / 2000
  local N = #U
  local steps = floor(N * dtP / h + 0.5)
  local s = {}
  for i = 1, 6 do s[i] = X[1][i] end
  for k = 0, steps - 1 do
    local ki = min(N - 1, floor(k * h / dtP)) + 1
    local xn, Kf = X[ki], Kfb[ki]
    local u = U[ki]
    u = u - Kf[1] * (s[1] - xn[1])
    u = u - Kf[2] * (s[2] - xn[2])
    u = u - Kf[3] * normalizeAngle(s[3] - xn[3])
    u = u - Kf[4] * (s[4] - xn[4])
    u = u - Kf[5] * normalizeAngle(s[5] - xn[5])
    u = u - Kf[6] * (s[6] - xn[6])
    rk4(s, clamp(u, -U_MAX, U_MAX), h, s)
    for i = 1, 6 do
      if not isfinite(s[i]) then return -1 end
    end
    if abs(s[1]) > 2.3 then return -1 end          -- would run into a stop
    vE[1] = 0; vE[2] = s[2]; vE[3] = normalizeAngle(s[3]); vE[4] = s[4]
    vE[5] = normalizeAngle(s[5]); vE[6] = s[6]
    if abs(vE[3]) < 0.6 and abs(vE[5]) < 0.6 and abs(vE[4]) < 4 and abs(vE[6]) < 4 then
      local q = quadForm(P_lqr, vE)
      if q < catchLevel then return holds(s, h) and q or -1 end
    end
  end
  return -1
end

function planner.finish(res)
  local dtP = planner.bestDt ~= 0 and planner.bestDt or planner.dt
  local T = planner.bestT ~= 0 and planner.bestT or planner.horizon
  local Kfb = trackingGains(res.X, res.U, dtP)
  local q = verify(res.X, res.U, Kfb, dtP)
  if q < 0 then return false end
  planner.plan = { X = res.X, U = res.U, N = #res.U, dt = dtP, T = T, Kfb = Kfb }
  planner.bestQ = q
  planner.status = "ready"
  return true
end

local START_STATE = { 0, 0, PI, 0, PI, 0 }

-- Called once per animation frame; spends at most PLAN_BUDGET_MS on iLQR.
function planner.work()
  local sig = paramSignature()
  if planner.signature ~= sig then
    planner.signature = sig
    planner.invalidate()
  end
  if not P_lqr or not planner.searching then return end
  -- Always run one sweep per frame, then keep going while the measured cost
  -- of a sweep still fits in the slice. (Running none whenever the estimate
  -- exceeds the budget would stall the planner forever after a slow first
  -- frame.)
  local t0 = nowMs()
  local firstSweep = true
  while firstSweep or nowMs() - t0 + planner.iterMs < PLAN_BUDGET_MS do
    firstSweep = false
    local tIter = nowMs()
    if not planner.solver then
      if planner.attempt >= PLAN_RESTARTS then
        planner.searching = false
        planner.rounds = planner.rounds + 1
        -- The terminal cost is only a screen - cheap, and deliberately
        -- generous, because the closed-loop flight in finish() is the
        -- decision that counts. Screening at exactly catchLevel threw
        -- away candidates that missed it by a fraction and would have
        -- flown fine.
        local screen = max(PLAN_ACCEPT, 3 * catchLevel)
        if planner.best and planner.bestQ < screen and planner.finish(planner.best) then return end
        if not planner.plan then planner.failed = true; planner.status = "no plan" end
        return
      end
      -- Restarts cycle through four (horizon, resolution) combinations.
      -- Neither choice wins everywhere - a coarse grid converges more
      -- often on the default plant, long links need the fine one, and a
      -- stretched or shortened horizon sometimes succeeds where the
      -- nominal one does not. The closed-loop check in finish() means
      -- extra diversity here can only help.
      local variant = planner.attempt % 4
      local stretch = (variant == 2) and 1.5 or ((variant == 3) and 0.75 or 1.0)
      planner.horizon = max(1.0, min(9.0, planHorizon() * stretch))
      planner.knots = (variant % 2 == 0) and PLAN_N_COARSE
          or max(PLAN_N_COARSE, min(PLAN_N_MAX, floor(planner.horizon / PLAN_STEP_MAX + 0.5)))
      planner.dt = planner.horizon / planner.knots
      planner.solver = makeSwingSolver(START_STATE, 7717 * (planner.attempt + 1) + 13,
                                       planner.dt, planner.knots)
      planner.attempt = planner.attempt + 1
    end
    planner.solver.iterate()
    -- remember how long one sweep costs so the slice never overruns badly
    planner.iterMs = 0.7 * planner.iterMs + 0.3 * (nowMs() - tIter)
    -- Give the last few restarts the full budget: on slow plants a run
    -- can still be far off at the checkpoint and yet end up usable.
    local mayAbandon = planner.attempt <= PLAN_RESTARTS - 6
    if mayAbandon and planner.solver.iterations() == PLAN_CHECK_AT
        and planner.solver.terminal() > PLAN_CHECK_FACTOR * catchLevel then
      local q = planner.solver.terminal()
      if q < planner.bestQ then recordBest(q, planner.solver.result()) end
      planner.solver = nil
    elseif planner.solver.done() then
      local q = planner.solver.terminal()
      if q < planner.bestQ then recordBest(q, planner.solver.result()) end
      planner.solver = nil
      if planner.bestQ < PLAN_GOOD then
        if planner.finish(planner.best) then planner.searching = false; return end
        planner.best = nil           -- discretisation artefact
        planner.bestQ = math.huge
      end
    end
  end
  planner.status = "planning " .. planner.attempt .. "/" .. PLAN_RESTARTS
end

-- ---------------------------------------------------------------------------
-- Controller state machine
--   0 = balancing   - LQR about the up-up equilibrium
--   1 = settling    - drain the pendulum energy, re-centre the cart
--   2 = swing-up    - execute the planned trajectory (or pump energy)
-- ---------------------------------------------------------------------------

local MODE_BALANCE, MODE_SETTLE, MODE_SWING = 0, 1, 2
local STATE_LABELS = { [0] = "LQR Balance", [1] = "Settling", [2] = "Swing-up" }

-- Settling drives the system to the hanging rest state the trajectory is
-- planned from. Since E' = -v W, the choice v = +kw W gives E' = -kw W^2 <= 0
-- and bleeds energy off unconditionally. On its own that stalls: the
-- out-of-phase mode of the two links is only weakly coupled to the cart (its
-- modal input gain is ~5x smaller than the in-phase mode), so W stays near
-- zero while the links counter-oscillate. A second term damps that mode
-- directly by inverting d(th1''-th2'')/dv, which is what makes settling
-- finish in a few seconds.
local SETTLE = { kw = 6.0, kRelD = 3.0, relMax = 8.0, kx = 1.5, kd = 1.5, vMax = 12.0 }

local recoveryState = MODE_SETTLE
local recoveryTimer = 0
local mpcDivergedCount = 0
local swingTimer = 0
local balanceRef = 0         -- cart reference used while balancing, ramped to x_soll
local activePlan = nil       -- trajectory currently being executed

-- Error vector used by every mode: cart relative to its set point, angles
-- wrapped. One shared table, overwritten by the next call.
local ERR = {}
local function stateError()
  ERR[1] = state[1] - x_soll
  ERR[2] = state[2]
  ERR[3] = normalizeAngle(state[3])
  ERR[4] = state[4]
  ERR[5] = normalizeAngle(state[5])
  ERR[6] = state[6]
  return ERR
end

-- True when the LQR is known to recover from here - the hand-over test.
--
-- Where the cart happens to sit is deliberately left out of the quadratic form:
-- at hand-over the LQR reference is moved to the current cart position and only
-- then ramped back to x_soll (see balanceRef), so the whole force budget goes
-- into catching the links instead of into a position error that is about to be
-- cancelled anyway. Cart velocity still counts, and the offset is bounded so
-- the hand-over cannot happen right at a rail stop.
local EC = {}
local function insideCatchRegion(e)
  if not P_lqr then return false end
  EC[1] = 0; EC[2] = e[2]; EC[3] = e[3]; EC[4] = e[4]; EC[5] = e[5]; EC[6] = e[6]
  -- The sub-level set decides; the explicit bounds are only a sanity guard
  -- against handing over on the far side of a wrap or right at a rail stop.
  return abs(e[3]) < 0.6 and abs(e[5]) < 0.6
     and abs(e[4]) < 4.0 and abs(e[6]) < 4.0
     and abs(e[1]) < 2.0
     and quadForm(P_lqr, EC) < catchLevel
end

-- Close enough to the state the trajectory was planned from?
local function atPlanStart()
  return abs(state[1] - x_soll) < 0.20 and abs(state[2]) < 0.20
     and abs(normalizeAngle(state[3] - PI)) < 0.20
     and abs(normalizeAngle(state[5] - PI)) < 0.20
     and abs(state[4]) < 0.40 and abs(state[6]) < 0.40
end

local function enterSettle() recoveryState = MODE_SETTLE; recoveryTimer = 0; swingTimer = 0 end
-- The plan is latched at entry: a background round may publish a better one
-- mid-swing, and switching trajectories half-way through would be nonsense.
local function enterSwingUp() recoveryState = MODE_SWING; swingTimer = 0; activePlan = planner.plan end
local function enterBalance()
  recoveryState = MODE_BALANCE
  mpcDivergedCount = 0
  balanceRef = state[1]      -- catch here, drift back to x_soll afterwards
end

-- Pick the starting mode for the current state: balance directly when the LQR
-- can already hold it, otherwise calm down and swing up.
local function engageController()
  if insideCatchRegion(stateError()) then enterBalance() else enterSettle() end
end

-- Commanded cart acceleration that drains energy and re-centres the cart.
local function settleAccel()
  local th1, th2 = normalizeAngle(state[3]), normalizeAngle(state[5])
  local en = pendulumEnergy(th1, state[4], th2, state[6])
  local acc = SETTLE.kw * en.W
  local s1, s2 = thetaDDotPerV(th1, th2)
  local dv = s1 - s2
  if abs(dv) > 1e-6 then
    acc = acc + clamp(-SETTLE.kRelD * (state[4] - state[6]) / dv, -SETTLE.relMax, SETTLE.relMax)
  end
  acc = acc + (-SETTLE.kx * (state[1] - x_soll) - SETTLE.kd * state[2])
  return clamp(acc, -SETTLE.vMax, SETTLE.vMax)
end

local function controlStep(h)
  local e = stateError()
  local th1, th2 = e[3], e[5]
  local u = 0

  if recoveryState == MODE_BALANCE then
    balanceRef = balanceRef + (x_soll - balanceRef) * h / BALANCE_REF_TAU
    local ex = state[1] - balanceRef
    u = -(K[1] * ex + K[2] * e[2] + K[3] * e[3] + K[4] * e[4] + K[5] * e[5] + K[6] * e[6])
    if abs(th1) > 0.8 or abs(th2) > 0.8 then
      mpcDivergedCount = mpcDivergedCount + 1
      if mpcDivergedCount > 20 then enterSettle() end
    else
      mpcDivergedCount = 0
    end
  elseif recoveryState == MODE_SETTLE then
    recoveryTimer = recoveryTimer + h
    u = pflForce(settleAccel(), th1, state[4], th2, state[6])
    -- launch the swing-up once the system is at rest and a trajectory exists
    if atPlanStart() and (planner.plan or (planner.failed and recoveryTimer > 1.0)) then
      enterSwingUp()
    end
  else
    swingTimer = swingTimer + h
    if activePlan then
      local pl = activePlan
      local ki = min(pl.N, floor(swingTimer / pl.dt) + 1)
      local xn, Kf = pl.X[ki], pl.Kfb[ki]
      u = pl.U[ki]
      u = u - Kf[1] * (e[1] - xn[1])
      u = u - Kf[2] * (e[2] - xn[2])
      u = u - Kf[3] * normalizeAngle(state[3] - xn[3])
      u = u - Kf[4] * (e[4] - xn[4])
      u = u - Kf[5] * normalizeAngle(state[5] - xn[5])
      u = u - Kf[6] * (e[6] - xn[6])
      -- the trajectory ran out without the LQR taking over: look for a better
      -- one while the controller calms the pendulums down again
      if swingTimer > pl.T + 0.4 then planner.retry(); enterSettle() end
    else
      u = pflForce(swingAccel(swingTimer), th1, state[4], th2, state[6])
      if swingTimer > 30 then planner.retry(); enterSettle() end
    end
    if insideCatchRegion(e) then enterBalance() end
  end
  return clamp(u, -U_MAX, U_MAX)
end

-- ---------------------------------------------------------------------------
-- Simulation loop
-- ---------------------------------------------------------------------------

local SIM_DT = 1 / 2000          -- integration + control step (s)
local RAIL_X = 2.5               -- cart travel limit (+-m)

local halted = false
local systemPower = false
local railLimitsEnabled = true
local lastU = 0

-- One integration + control step of length h.
local function simStep(h)
  local u = systemPower and controlStep(h) or 0

  -- Soft rail limit: throttle the force when heading into a stop
  if railLimitsEnabled then
    local margin = 0.5
    local distToLimit = RAIL_X - abs(state[1])
    if distToLimit < margin then
      local scale = max(0, distToLimit / margin)
      if (state[1] > 0 and state[2] > 0) or (state[1] < 0 and state[2] < 0) then u = u * scale end
    end
  end
  u = clamp(u, -U_MAX, U_MAX)
  lastU = u
  rk4(state, u, h, state)

  -- Hard rail stop - checked every integration step, not once per frame
  if railLimitsEnabled and abs(state[1]) > RAIL_X then
    state[1] = sign(state[1]) * RAIL_X
    state[2] = 0
    if systemPower and recoveryState ~= MODE_SETTLE then
      if recoveryState == MODE_SWING then planner.retry() end
      enterSettle()
    end
  end
end

local function setState(x, dx, th1, dth1, th2, dth2)
  state[1], state[2], state[3], state[4], state[5], state[6] = x, dx, th1, dth1, th2, dth2
end

-- scenario 0 = A upright stabilisation, 1 = B uncontrolled free fall, 2 = C swing-up
local function resetSystem(scenario)
  if scenario == 0 then
    setState(0, 0, 0.05, 0, -0.03, 0)
  elseif scenario == 1 then
    setState(0, 0, 1.57, 0, 0, 0)
  else
    setState(0, 0, 3.1416, 0, 3.1416, 0)
  end
  halted = false
  if systemPower then engageController() else recoveryState = MODE_BALANCE end
  swingTimer = 0
end

local function setTargetState(th1, th2)
  state[3] = th1
  state[5] = th2
  state[2] = 0
  state[4] = 0
  state[6] = 0
  if systemPower then engageController() end
end

-- ===========================================================================
-- Scene
-- ===========================================================================

common.setTiming(1 / 60, 1, 1 / 60)
v.animationPeriod = 16

-- Geometry in metres, the rail top being y = 0. The cart is the original's
-- (drawn there at 140 px/m). The pendulum hangs from a stub axle on the
-- cart's front side, in a plane clear of the wheels and chassis, so it can
-- swing through the full circle - straight down past the cart included - with
-- link 2 running one step further out so the two links can fold onto each other.
local CART_W, CART_H, CART_D = 0.6, 0.157, 0.30
local WHEEL_R, WHEEL_T = 0.0714, 0.04
local RAIL_H = 0.05
local WHEEL_Y = WHEEL_R
local CHASSIS_Y = WHEEL_Y + CART_H / 2           -- chassis sits on the wheel axles
local PIVOT_Y = CHASSIS_Y                        -- link 1 hinges at mid-height of the cart
local PLANE_Z = CART_D / 2 + WHEEL_T + 0.06      -- plane link 1 swings in (wheels end at z = 0.19)
local LINK_DZ = 0.045                            -- link 2 runs this much further out

local QID = common.quat(0, 0, 0)
local AXIS_Z = btVector3(0, 0, 1)

-- A mass-0 body posed by hand every frame: never sleeps, never collides.
local function ghost(obj, col)
  obj.col = col
  v:add(obj)
  obj.body:forceActivationState(4)                                 -- DISABLE_DEACTIVATION
  obj.body:setCollisionFlags(obj.body:getCollisionFlags() + 4)     -- CF_NO_CONTACT_RESPONSE
  return obj
end

local function setPose(obj, q, x, y, z)
  obj.trans = btTransform(q, btVector3(x, y, z))
end

-- rotation taking a Cylinder's local +Z axis onto the in-plane direction
-- (sin th, cos th, 0) of a link at angle th
local function linkQuat(th)
  return btQuaternion(btVector3(-cos(th), sin(th), 0), PI / 2)
end

-- rail with the end stops; the cart centre stops at +-RAIL_X, so the buffers
-- sit half a cart width further out. (No floor: the pendulum hangs below the
-- rail, up to four metres with the longest links.)
local STOP_X = RAIL_X + CART_W / 2 + 0.02
setPose(ghost(Cube(2 * STOP_X, RAIL_H, 0.14, 0), "#2d3142"), QID, 0, -RAIL_H / 2, 0)
for _, sx in ipairs({ -STOP_X, STOP_X }) do
  setPose(ghost(Cube(0.05, 0.21, CART_D, 0), "#ff5555"), QID, sx, 0.105, 0)
end
-- scale ticks every 0.5 m on the front of the rail, the zero mark highlighted
for i = -5, 5 do
  setPose(ghost(Cube(0.012, 0.03, 0.01, 0), i == 0 and "#ffb86c" or "#6272a4"),
          QID, i * 0.5, -RAIL_H / 2, 0.075)
end

-- cart: chassis on four wheels (each with a spoke, so the rolling shows)
local chassis = ghost(Cube(CART_W, CART_H, CART_D, 0), "#00ecb3")
local wheels = {}
for _, dx in ipairs({ -0.2, 0.2 }) do
  for _, dz in ipairs({ -(CART_D / 2 + WHEEL_T / 2), CART_D / 2 + WHEEL_T / 2 }) do
    wheels[#wheels + 1] = {
      dx = dx, dz = dz,
      tyre  = ghost(Cylinder(WHEEL_R, WHEEL_T, 0), "#3a3d4a"),
      spoke = ghost(Cube(2 * WHEEL_R * 0.9, 0.012, WHEEL_T + 0.006, 0), "#ffb86c"),
    }
  end
end
-- stub axle carrying link 1, from the cart's front face out to its plane
local STUB_Z0, STUB_Z1 = CART_D / 2, PLANE_Z + 0.03
local stub = ghost(Cylinder(0.025, STUB_Z1 - STUB_Z0, 0), "#4f5d75")
-- pin joining the two links
local knuckle = ghost(Cylinder(0.03, LINK_DZ + 0.06, 0), "#ff007f")

-- cart position set point
local targetLine = ghost(Cube(0.01, 2.2, 0.01, 0), "#ff9f43")
targetLine.transparency = 0.6

-- The two links and the tip weight. Their size follows the length / mass
-- parameters, and a cylinder's length is fixed when it is made, so they are
-- rebuilt whenever one of those changes.
local pend = {}
local function buildPendulum()
  for _, o in pairs(pend) do v:remove(o) end
  pend.link1 = ghost(Cylinder(0.02, 2 * l1, 0), "#00e5ff")
  pend.link2 = ghost(Cylinder((4 + 1.5 * m2) / 280, 2 * l2, 0), "#ff007f")
  pend.tip   = ghost(Sphere((6 + 2 * m2) / 140, 0), "#f1faee")
end

local function poseScene()
  local xc = state[1]
  setPose(chassis, QID, xc, CHASSIS_Y, 0)
  local roll = btQuaternion(AXIS_Z, -xc / WHEEL_R)            -- rolling to +x turns clockwise
  for _, w in ipairs(wheels) do
    setPose(w.tyre,  roll, xc + w.dx, WHEEL_Y, w.dz)
    setPose(w.spoke, roll, xc + w.dx, WHEEL_Y, w.dz)
  end
  setPose(stub, QID, xc, PIVOT_Y, (STUB_Z0 + STUB_Z1) / 2)

  local th1, th2 = state[3], state[5]
  local x1, y1 = xc + L1 * sin(th1), PIVOT_Y + L1 * cos(th1)
  local x2, y2 = x1 + 2 * l2 * sin(th2), y1 + 2 * l2 * cos(th2)
  local z2 = PLANE_Z + LINK_DZ
  setPose(pend.link1, linkQuat(th1), (xc + x1) / 2, (PIVOT_Y + y1) / 2, PLANE_Z)
  setPose(knuckle,    QID, x1, y1, (PLANE_Z + z2) / 2)
  setPose(pend.link2, linkQuat(th2), (x1 + x2) / 2, (y1 + y2) / 2, z2)
  setPose(pend.tip,   QID, x2, y2, z2)
  setPose(targetLine, QID, x_soll, 0, 0)
end

-- ---------------------------------------------------------------------------
-- Parameters, keys
-- ---------------------------------------------------------------------------

v:addParam("power", true, "controller on: swing up and balance (off = the pendulum moves freely)")
v:addParam("limits", true, "rail limits: force throttled near the ends, hard stops at +-2.5 m")
v:addParam("adaptation", true, "re-synthesise the LQR gains when the plant changes")
v:addParam("scenario", 2, 0, 2, 1, "start used by Z: 0 upright stabilisation, 1 free fall, 2 swing-up")
v:addParam("target", 0.0, -RAIL_X, RAIL_X, 0.05, "cart position set point (m)")
v:addParam("cartMass", 1.5, 0.5, 5.0, 0.1, "cart mass M (kg)")
v:addParam("damping", 0.0, 0.0, 0.5, 0.01, "joint friction (Nms/rad)")
v:addParam("mass1", 0.5, 0.05, 2.0, 0.05, "link 1 mass (kg)")
v:addParam("len1", 0.2, 0.1, 1.0, 0.05, "link 1 pivot to centre of mass (m); the link is twice as long")
v:addParam("mass2", 0.5, 0.05, 3.5, 0.05, "link 2 mass, the top weight (kg)")
v:addParam("len2", 0.2, 0.1, 1.0, 0.05, "link 2 pivot to centre of mass (m); the link is twice as long")
v:addParam("gravity", 9.81, 1.0, 35.0, 0.2, "local gravity (m/s^2)")

-- Reads the panel. Plant changes re-synthesise the LQR, which in turn makes
-- the planner start over (it keys on the plant parameters).
local function applyParams()
  railLimitsEnabled = v:getParam("limits")
  x_soll = v:getParam("target")

  local power = v:getParam("power")
  if power ~= systemPower then
    systemPower = power
    if systemPower then
      engageController()
    else
      recoveryState = MODE_BALANCE
      mpcDivergedCount = 0
    end
  end

  local adaptive = v:getParam("adaptation")
  local adaptationOn = adaptive and not adaptiveMode
  adaptiveMode = adaptive

  local nM, nc = v:getParam("cartMass"), v:getParam("damping")
  local nm1, nl1 = v:getParam("mass1"), v:getParam("len1")
  local nm2, nl2 = v:getParam("mass2"), v:getParam("len2")
  local ng = v:getParam("gravity")
  local shape = nl1 ~= l1 or nl2 ~= l2 or nm2 ~= m2
  local plant = shape or nM ~= M or nc ~= c_damping or nm1 ~= m1 or ng ~= g
  M, c_damping, m1, l1, m2, l2, g = nM, nc, nm1, nl1, nm2, nl2, ng
  L1 = 2 * l1
  -- (the original leaves the gains alone when only the damping moves; the
  -- linearisation does depend on it, so here it counts as a plant change)
  if plant or adaptationOn then synthesizeLQR() end
  if shape then buildPendulum() end
end

v:addShortcut("Z", function()
  resetSystem(floor(v:getParam("scenario") + 0.5))
end)
v:addShortcut("K", function()                      -- shock test
  state[2] = state[2] + (math.random() - 0.5) * 4
  state[4] = state[4] + (math.random() - 0.5) * 5
end)
v:addShortcut("1", function() setTargetState(0, 0) end)
v:addShortcut("2", function() setTargetState(0, PI) end)
v:addShortcut("3", function() setTargetState(PI, 0) end)
v:addShortcut("4", function() setTargetState(PI, PI) end)

v:setHelpText([[
Double inverted pendulum on a cart - LQR balance, iLQR swing-up

Z       reset to the scenario chosen in the panel
K       shock test: random kick to the cart and link 1
1 2 3 4 both links at rest at (0,0) (0,pi) (pi,0) (pi,pi); 0 is up

Panel: power, limits, adaptation, scenario, target (cart set point) and the
plant (cart mass, joint damping, mass/length of each link, gravity).
The swing-up trajectory is planned in the background after start and after
every plant change; the output pane shows its progress.
]])

-- ---------------------------------------------------------------------------
-- Frame loop
-- ---------------------------------------------------------------------------

local simTime = 0
local nextReport = 0
local lastMode, lastPlanner

local function plannerStatus()
  if planner.searching then return planner.status end
  if planner.plan then
    return string.format("plan verified (e'Pe %.1f < %.1f)", planner.bestQ, catchLevel)
  end
  return planner.failed and "no plan - energy pumping" or planner.status
end

-- Mode and planner changes as they happen, plus a status line every 2 s of
-- simulated time (what the original shows in its telemetry panel and plots).
local function report()
  local mode = systemPower and STATE_LABELS[recoveryState] or "power off"
  if mode ~= lastMode then
    lastMode = mode
    print("controller: " .. mode)
  end
  local status = plannerStatus()
  if status ~= lastPlanner then
    lastPlanner = status
    print("planner: " .. status)
  end
  if simTime >= nextReport then
    nextReport = simTime + 2
    local en = pendulumEnergy(normalizeAngle(state[3]), state[4], normalizeAngle(state[5]), state[6])
    local V = (m1 * l1 + m2 * L1) * g * cos(state[3]) + m2 * l2 * g * cos(state[5])
    printf("t=%6.1fs  x=%+6.3f m  th1=%+7.3f  th2=%+7.3f rad  F=%+6.1f N  Epot=%+7.3f  Ekin=%6.3f J  %s%s",
           simTime, state[1], normalizeAngle(state[3]), normalizeAngle(state[5]), lastU,
           V - en.Ed, en.E - V, mode,
           recoveryState == MODE_SWING and systemPower and string.format(" (%.2f s)", swingTimer) or "")
  end
end

local FRAME_DT = 1 / 60
local SUBSTEPS = math.ceil(FRAME_DT / SIM_DT - 1e-9)

v:preSim(function(N)
  applyParams()
  if not halted then
    local h = FRAME_DT / SUBSTEPS
    for _ = 1, SUBSTEPS do simStep(h) end
    simTime = simTime + FRAME_DT
    for i = 1, 6 do
      if state[i] ~= state[i] then
        halted = true
        print("SIMULATION HALTED: NaN in the state - press Z to reset")
        break
      end
    end
  end
  planner.work()
  poseScene()
  report()
end)

-- ---------------------------------------------------------------------------
-- Start
-- ---------------------------------------------------------------------------

synthesizeLQR()
buildPendulum()
resetSystem(floor(v:getParam("scenario") + 0.5))
applyParams()
poseScene()

-- (horizontal field of view, so the whole rail fits whatever the window shape)
common.setCamera(
  btVector3(0.8, 0.8, 5.6),
  btVector3(0, 0.05, 0),
  1.1,
  { up = btVector3(0, 1, 0), horizontal = true })

-- EOF
