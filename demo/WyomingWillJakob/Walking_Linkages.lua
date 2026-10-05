--
-- Walking Linkage Comparison Suite
--
-- Ported from the standalone C + OpenGL/GLUT reference tool at
-- linkage_c (its src/mechanisms.c
-- and src/metrics.c specifically), which independently reproduces the "full
-- comparison table, sorted by duty" for 10 walking linkages. This demo ports
-- the same forward-kinematics math and the same duty/flatness/mono metric
-- definitions straight into Lua, then drives them from BPP's own scene graph
-- instead of raw OpenGL calls.
--
-- KEYBOARD SHORTCUTS:
-- * F1 - show the previous mechanism
-- * F2 - show the next mechanism
--
-- WHY NO PHYSICS: every mechanism below is driven by ANALYTIC forward
-- kinematics (circle-circle intersection, exactly as in mechanisms.c), not
-- by Bullet rigid bodies + hinge motors. That matches how the C reference
-- tool's own OpenGL viewer works (main.c's display() calls compute(theta)
-- directly), and it sidesteps the whole class of Grashof/motor-torque
-- tuning problems that a from-scratch rigid-body version of 10 different
-- linkages would otherwise need (compare the effort that went into just ONE
-- physically-simulated linkage in cheby_diag4.lua). Every link/pivot/foot
-- object here has mass 0 and its .trans/.pos is simply overwritten every
-- frame from the current theta -- Object::render() reads the motion state
-- fresh each frame, so this works fine even for a "static" (mass 0) body.
--
-- WHY NO ATAN2: line_extension/line_extend_bent in the C source (TrotBot,
-- Strider) compute an angle via atan2() purely so they can immediately take
-- its cos/sin again -- i.e. they just want a unit direction vector. That
-- round trip is replaced below with direct vector normalization (and, for
-- the "bent" variant, the angle-addition formulas applied to that unit
-- vector) so nothing here ever calls atan2 at all -- following the same
-- portability caution already established in cheby_diag4.lua's zrotVec()
-- ("avoids atan2, which isn't in every Lua build").
--
-- WHY NORMALIZED COORDINATES: the 10 mechanisms span wildly different
-- native scales (Klann is ~1-2 units across, Jansen/TrotBot/Strider are
-- tens of units, Spears 4Bar-1 is ~200+ units). Rather than re-aiming the
-- camera per mechanism (what the C viewer's compute_view_bounds does),
-- every mechanism's own full-cycle bounding box is rescaled to fit the same
-- TARGET_EXTENT here, so ONE fixed camera frames all 10 without ever being
-- reset -- which also means the user's own mouse/arrow-key camera controls
-- keep working normally between switches, instead of being fought every
-- frame by a scripted camera.
--
-- LIMITATIONS (same honest caveats as the C reference's README):
-- * Chebyshev-Spears and Hoeckens-Spears are "needs_twin" designs -- the
--   original comparison mirrors them into a paired, crank-shared two-legged
--   walker. That pairing is NOT built here; only the single leg's own
--   mechanism and foot path are shown (this doesn't affect the metrics,
--   which were always computed on the single-leg path either way).
-- * duty/flatness/mono are idealized rigid-body kinematics -- no friction,
--   backlash, compliance, or dynamics.
--

local common = require "common"
local text    = require "scad/text"

local placeCylinder       = common.placeCylinder
local repositionCylinder  = common.repositionCylinder

common.setTiming(1/30, 10, 1/120)
common.gravity(0)   -- pure kinematic diagram -- nothing here should fall

-- ---------------------------------------------------------------------
-- geometry helpers (ported from mechanisms.c's circle_intersect(), plus
-- TrotBot/Strider's own two helper functions)
-- ---------------------------------------------------------------------

-- one of the two points where a circle (center p1, radius r1) meets a
-- circle (center p2, radius r2); branch = +1 or -1 picks which one.
local function circleIntersect(p1, r1, p2, r2, branch)
  local dx, dy = p2.x - p1.x, p2.y - p1.y
  local dist = math.sqrt(dx * dx + dy * dy)
  local a = (r1 * r1 - r2 * r2 + dist * dist) / (2.0 * dist)
  local h2 = r1 * r1 - a * a
  local h = (h2 > 0.0) and math.sqrt(h2) or 0.0
  local mx, my = p1.x + a * dx / dist, p1.y + a * dy / dist
  local px, py = -dy / dist, dx / dist
  return { x = mx + branch * h * px, y = my + branch * h * py }
end

-- TrotBot's own intersection convention: picks by explicit Y or X
-- comparison rather than a +-1 branch, so it's kept as a separate
-- function (matching mechanisms.c's circ_intersection_choice) rather
-- than shoehorned into circleIntersect's branch convention.
local CH_HIGH, CH_LOW, CH_LEFT, CH_RIGHT = 0, 1, 2, 3

local function circChoice(A, B, lengthA, lengthB, choice)
  local xa, ya, xb, yb = A.x, A.y, B.x, B.y
  local Lc = math.sqrt((xa - xb) * (xa - xb) + (ya - yb) * (ya - yb))
  local bb = (lengthB * lengthB - lengthA * lengthA + Lc * Lc) / (Lc * 2.0)
  local h2 = lengthB * lengthB - bb * bb
  local h = (h2 >= 0.0) and math.sqrt(h2) or 0.0
  local Xp, Yp = xb + (bb * (xa - xb)) / Lc, yb + (bb * (ya - yb)) / Lc
  local Xs1, Ys1 = Xp + (h * (yb - ya)) / Lc, Yp - (h * (xb - xa)) / Lc
  local Xs2, Ys2 = Xp - (h * (yb - ya)) / Lc, Yp + (h * (xb - xa)) / Lc
  local s1, s2 = { x = Xs1, y = Ys1 }, { x = Xs2, y = Ys2 }
  if choice == CH_HIGH then
    return (Ys1 > Ys2) and s1 or s2
  elseif choice == CH_LOW then
    return (Ys1 < Ys2) and s1 or s2
  elseif choice == CH_LEFT then
    return (Xs1 < Xs2) and s1 or s2
  else -- CH_RIGHT
    return (Xs1 > Xs2) and s1 or s2
  end
end

-- colinear extension of segment A->B, continuing BEYOND B by length Lb.
-- (see the "WHY NO ATAN2" note above -- this is atan2(dy,dx) then
-- cos/sin of it, algebraically simplified to a plain unit-vector step.)
local function lineExtension(A, B, Lb)
  local dx, dy = B.x - A.x, B.y - A.y
  local len = math.sqrt(dx * dx + dy * dy)
  return { x = B.x + Lb * dx / len, y = B.y + Lb * dy / len }
end

-- point at distance Length from A, in direction (slope(A->B) + AngleDeg),
-- continuing AWAY from B (subtracts from A). Same atan2-avoidance as
-- lineExtension, via the angle-addition formulas applied to A->B's own
-- unit vector instead of recovering its angle first.
local function lineExtendBent(A, B, Length, angleDeg)
  local dx, dy = B.x - A.x, B.y - A.y
  local len = math.sqrt(dx * dx + dy * dy)
  local cosSlope, sinSlope = dx / len, dy / len
  local a2 = math.rad(angleDeg)
  local ca, sa = math.cos(a2), math.sin(a2)
  local cosT = cosSlope * ca - sinSlope * sa
  local sinT = sinSlope * ca + cosSlope * sa
  return { x = A.x - Length * cosT, y = A.y - Length * sinT }
end

-- ---------------------------------------------------------------------
-- forward kinematics -- one compute(theta) function per mechanism,
-- transcribed directly from mechanisms.c. Each returns
--   { foot = {x,y}, segments = { {p1,p2}, ... }, pivots = { p, ... } }
-- ---------------------------------------------------------------------

-- 1. Chebyshev-Spears (needs twin)
local function compute_chebyshev_spears(theta)
  local crank, ground, coupler, rocker = 36.0, 48.0, 110.0, 110.0
  local ground_angle = math.rad(45.0)
  local leg_len, leg_angle = 110.0, math.rad(-90.0)

  local O1 = { x = 0.0, y = 0.0 }
  local O2 = { x = O1.x + ground * math.cos(ground_angle), y = O1.y + ground * math.sin(ground_angle) }
  local A  = { x = O1.x + crank * math.cos(theta), y = O1.y + crank * math.sin(theta) }
  local B  = circleIntersect(A, coupler, O2, rocker, 1)

  local ux, uy = (B.x - A.x) / coupler, (B.y - A.y) / coupler
  local ca, sa = math.cos(leg_angle), math.sin(leg_angle)
  local lx, ly = ux * ca - uy * sa, ux * sa + uy * ca
  local Leg = { x = B.x + leg_len * lx, y = B.y + leg_len * ly }

  return {
    foot = Leg,
    pivots = { O1, O2 },
    segments = { { O1, A }, { A, B }, { O2, B }, { B, Leg } },
  }
end

-- 2. Hoeckens-Spears (needs twin)
local function compute_hoeckens_spears(theta)
  local crank, ground, L = 36.0, 46.95, 168.98
  local ground_angle = math.rad(90.0)

  local O1 = { x = 0.0, y = 0.0 }
  local O2 = { x = O1.x + ground * math.cos(ground_angle), y = O1.y + ground * math.sin(ground_angle) }
  local A  = { x = O1.x + crank * math.cos(theta), y = O1.y + crank * math.sin(theta) }
  local dx, dy = O2.x - A.x, O2.y - A.y
  local d = math.sqrt(dx * dx + dy * dy)
  local P = { x = A.x + L * dx / d, y = A.y + L * dy / d }

  return {
    foot = P,
    pivots = { O1, O2 },
    segments = { { O1, A }, { A, P } },
  }
end

-- 3. Chebyshev Lambda (classical)
local function compute_chebyshev_lambda(theta)
  local crank, ground, rocker, AB, full_coupler = 1.0, 2.0, 2.5, 2.5, 5.0

  local O2 = { x = 0.0, y = 0.0 }
  local O4 = { x = ground, y = 0.0 }
  local A  = { x = O2.x + crank * math.cos(theta), y = O2.y + crank * math.sin(theta) }
  local B  = circleIntersect(A, AB, O4, rocker, 1)

  local ux, uy = (B.x - A.x) / AB, (B.y - A.y) / AB
  local P = { x = A.x + full_coupler * ux, y = A.y + full_coupler * uy }

  return {
    foot = P,
    pivots = { O2, O4 },
    segments = { { O2, A }, { A, B }, { O4, B }, { B, P } },
  }
end

-- 4. Original Hoecken Slider (a, 2a, 10a variant)
local function compute_hoecken_slider(theta)
  local crank, ground, L = 1.0, 2.0, 10.0
  local ground_angle = math.rad(90.0)

  local O1 = { x = 0.0, y = 0.0 }
  local O2 = { x = O1.x + ground * math.cos(ground_angle), y = O1.y + ground * math.sin(ground_angle) }
  local A  = { x = O1.x + crank * math.cos(theta), y = O1.y + crank * math.sin(theta) }
  local dx, dy = O2.x - A.x, O2.y - A.y
  local d = math.sqrt(dx * dx + dy * dy)
  local P = { x = A.x + L * dx / d, y = A.y + L * dy / d }

  return {
    foot = P,
    pivots = { O1, O2 },
    segments = { { O1, A }, { A, P } },
  }
end

-- 5. True 4-Bar Hoekens (classical)
local function compute_true_hoekens(theta)
  local crank, ground, coupler, rocker, tracer = 1.1, 2.3, 2.8, 2.8, 5.65

  local O2 = { x = 0.0, y = 0.0 }
  local O4 = { x = ground, y = 0.0 }
  local A  = { x = O2.x + crank * math.cos(theta), y = O2.y + crank * math.sin(theta) }
  local B  = circleIntersect(A, coupler, O4, rocker, 1)

  local ux, uy = (B.x - A.x) / coupler, (B.y - A.y) / coupler
  local P = { x = A.x + tracer * ux, y = A.y + tracer * uy }

  return {
    foot = P,
    pivots = { O2, O4 },
    segments = { { O2, A }, { A, B }, { O4, B }, { B, P } },
  }
end

-- 6. Spears 4Bar-1 (standalone, no twin required)
local function compute_spears4bar1(theta)
  local crank, ground, rocker, coupler = 36.0, 223.659, 121.37, 138.789
  local ground_angle = math.rad(54.459)
  local leg_len = 181.45
  local leg_angle = math.rad(-102.27)   -- clockwise from coupler direction
  local attach_frac = 0.25              -- 25% of the way from B to A

  local O1 = { x = 0.0, y = 0.0 }
  local O2 = { x = O1.x + ground * math.cos(ground_angle), y = O1.y + ground * math.sin(ground_angle) }
  local A  = { x = O1.x + crank * math.cos(theta), y = O1.y + crank * math.sin(theta) }
  local B  = circleIntersect(A, coupler, O2, rocker, -1)  -- the "other" Grashof-boundary path

  local attach = { x = B.x + attach_frac * (A.x - B.x), y = B.y + attach_frac * (A.y - B.y) }
  local ux, uy = (B.x - A.x) / coupler, (B.y - A.y) / coupler
  local ca, sa = math.cos(leg_angle), math.sin(leg_angle)
  local lx, ly = ux * ca - uy * sa, ux * sa + uy * ca
  local Leg = { x = attach.x + leg_len * lx, y = attach.y + leg_len * ly }

  return {
    foot = Leg,
    pivots = { O1, O2 },
    segments = { { O1, A }, { A, B }, { O2, B }, { attach, Leg } },
  }
end

-- 7. Jansen's Linkage (crossing-free branch)
local function compute_jansen(theta)
  local a, b, c, d, e, f, g, h, i, j, k, l, m =
      38.0, 41.5, 39.3, 40.1, 55.8, 39.4, 36.7, 65.7, 49.0, 50.0, 61.9, 7.8, 15.0

  local O  = { x = 0.0, y = 0.0 }
  local G  = { x = O.x - a, y = O.y - l }
  local J1 = { x = O.x + m * math.cos(theta), y = O.y + m * math.sin(theta) }
  local J2 = circleIntersect(J1, j, G, b, -1)
  local J3 = circleIntersect(J2, e, G, d, -1)
  local J4 = circleIntersect(J1, k, G, c, 1)
  local J5 = circleIntersect(J3, f, J4, g, -1)
  local F  = circleIntersect(J4, i, J5, h, 1)

  return {
    foot = F,
    pivots = { O, G },
    segments = {
      { O, J1 }, { J1, J2 }, { G, J2 }, { J2, J3 }, { G, J3 },
      { J1, J4 }, { G, J4 }, { J3, J5 }, { J4, J5 }, { J4, F }, { J5, F },
    },
  }
end

-- 8. Klann Linkage (US Patent 6,260,862)
local function compute_klann(theta)
  local P9  = { x = 1.366, y = 1.366 }
  local P11 = { x = 1.009, y = 0.574 }
  local P15 = { x = 1.599, y = 0.750 }
  local crank_len = 0.268
  local len_29_27, len_27_35, len_29_35 = 0.590, 0.5221, 1.1051
  local rocker_lower = 0.3206
  local len_35_37, len_35_33, len_33_37 = 0.8966, 0.8966, 1.732
  local rocker_upper = 0.5177

  local P29 = { x = P15.x + crank_len * math.cos(theta), y = P15.y + crank_len * math.sin(theta) }
  local P27 = circleIntersect(P29, len_29_27, P11, rocker_lower, -1)
  local P35 = circleIntersect(P29, len_29_35, P27, len_27_35, -1)
  local P37 = circleIntersect(P35, len_35_37, P9, rocker_upper, 1)
  local P33 = circleIntersect(P35, len_35_33, P37, len_33_37, -1)  -- foot

  return {
    foot = P33,
    pivots = { P15, P9, P11 },
    segments = {
      { P15, P29 }, { P29, P27 }, { P27, P35 }, { P29, P35 },
      { P11, P27 }, { P35, P37 }, { P35, P33 }, { P37, P33 }, { P9, P37 },
    },
  }
end

-- 9. TrotBot (Wade & Ben Vagle / Sam Korman, Team TrotBot, diywalkers.com)
local function compute_trotbot(theta)
  local crank, bar1, bar2, bar3, bar4, bar5, bar6, bar7, bar8, bar9, bar10, bar11, bar12, bar13, bar14, bar15 =
      4.0, 6.0, 8.0, 2.0, 6.0, 2.0, 11.0, 3.0, 9.0, 8.0, 1.0, -2.64, 2.55, 7.2, 1.0, 7.55

  local axleCenter = { x = 0.0, y = 10.0 }
  local joint_3    = { x = axleCenter.x - 7.0, y = 16.0 }

  local j1 = { x = axleCenter.x + crank * math.cos(theta), y = axleCenter.y + crank * math.sin(theta) }
  local j0, j3 = axleCenter, joint_3
  local j2  = circChoice(j1, j3, bar1, bar2, CH_HIGH)
  local j4  = lineExtension(j2, j3, bar3)
  local j5  = circChoice(j1, j4, bar6, bar4, CH_LOW)
  local j6  = lineExtension(j4, j5, bar5)
  local j9  = lineExtension(j2, j1, bar10)
  local j8  = circChoice(j1, j2, bar7, bar15, CH_LEFT)
  local j7  = circChoice(j6, j8, bar9, bar8, CH_LOW)   -- main foot
  local j10 = lineExtension(j8, j7, bar11)
  local j11 = circChoice(j10, j9, bar12, bar13, CH_LOW)
  local j12 = lineExtension(j10, j11, bar14)            -- retractable toe

  return {
    foot = j7,
    pivots = { j0, j3 },
    segments = {
      { j0, j1 }, { j1, j2 }, { j2, j3 }, { j3, j4 }, { j4, j5 }, { j5, j6 },
      { j6, j7 }, { j7, j8 }, { j8, j1 }, { j1, j9 }, { j2, j8 }, { j10, j12 },
    },
  }
end

-- 10. Strider (Team TrotBot, diywalkers.com)
local function compute_strider(theta)
  local bar0, bar1, bar2, bar3, bar4, bar5, bar7 = 4.0, 5.0, 14.0, 13.0, 10.0, 6.0, 1.0
  local xcenter, ycenter, frameX, frameY = 10.0, 10.0, 11.0, 8.0

  local center = { x = xcenter, y = ycenter }
  local joint2 = { x = xcenter - frameX, y = ycenter + frameY }
  local joint6 = { x = xcenter + frameX, y = ycenter + frameY }

  local joint1  = { x = xcenter + bar0 * math.cos(theta), y = ycenter + bar0 * math.sin(theta) }
  local joint3  = circleIntersect(joint2, bar1, joint1, bar2, -1)
  local joint9  = lineExtendBent(joint1, joint3, bar5, 0.0)
  local joint10 = lineExtendBent(joint9, joint1, bar7, 90.0)
  local joint7  = circleIntersect(joint1, bar2, joint6, bar1, -1)
  local joint5  = lineExtendBent(joint1, joint7, bar5, 0.0)
  local joint11 = lineExtendBent(joint5, joint1, bar7, -90.0)
  local joint4  = circleIntersect(joint3, bar3, joint11, bar4, -1)  -- foot
  local joint8  = circleIntersect(joint7, bar3, joint10, bar4, -1)  -- symmetric counterpart

  return {
    foot = joint4,
    pivots = { center, joint2, joint6 },
    segments = {
      { center, joint1 }, { joint1, joint11 }, { joint11, joint4 }, { joint4, joint3 },
      { joint3, joint2 }, { joint3, joint1 }, { joint1, joint10 }, { joint10, joint8 },
      { joint8, joint7 }, { joint7, joint6 },
    },
  }
end

-- ---------------------------------------------------------------------
-- mechanism table, in the same order as the C reference's own table
-- ---------------------------------------------------------------------

local MECHANISMS = {
  { name = "Chebyshev-Spears", links = 4, sliders = 0, twin = true,
    params = "crank=36  ground=48 @45deg  coupler=110  rocker=110  leg=110 @-90deg from coupler",
    compute = compute_chebyshev_spears },
  { name = "Hoeckens-Spears", links = 2, sliders = 1, twin = true,
    params = "crank=36  ground=46.95 @90deg  bar=168.98 (through pivoting slider O2)",
    compute = compute_hoeckens_spears },
  { name = "Chebyshev Lambda", links = 4, sliders = 0, twin = false,
    params = "crank=1  ground=2 @0deg  rocker=2.5 (to coupler midpoint)  full coupler=5",
    compute = compute_chebyshev_lambda },
  { name = "Orig. Hoecken Slider", links = 2, sliders = 1, twin = false,
    params = "crank=1  ground=2 @90deg  bar=10 (through pivoting slider O2)",
    compute = compute_hoecken_slider },
  { name = "True 4-Bar Hoekens", links = 4, sliders = 0, twin = false,
    params = "crank=1.1  ground=2.3 @0deg  coupler=2.8  rocker=2.8  tracer ext.=5.65",
    compute = compute_true_hoekens },
  { name = "Spears 4Bar-1", links = 4, sliders = 0, twin = false,
    params = "crank=36  ground=223.659 @54.459deg  rocker=121.37  coupler=138.789  leg=181.45",
    compute = compute_spears4bar1 },
  { name = "Jansen", links = 8, sliders = 0, twin = false,
    params = "crank(m)=15  a=38 b=41.5 c=39.3 d=40.1 e=55.8 f=39.4 g=36.7 h=65.7 i=49 j=50 k=61.9 l=7.8",
    compute = compute_jansen },
  { name = "Klann", links = 6, sliders = 0, twin = false,
    params = "crank=0.268  29-27=0.590 27-35=0.5221 29-35=1.1051  35-37=0.8966 35-33=0.8966 37-33=1.732",
    compute = compute_klann },
  { name = "TrotBot", links = 8, sliders = 0, twin = false,
    params = "crank=4  bar1-15 = 6, 8, 2, 6, 2, 11, 3, 9, 8, 1, -2.64, 2.55, 7.2, 1, 7.55",
    compute = compute_trotbot },
  { name = "Strider", links = 8, sliders = 0, twin = false,
    params = "bar0(crank)=4  bar1=5 bar2=14 bar3=13 bar4=10 bar5=6 bar7=1  frameX=11 frameY=8",
    compute = compute_strider },
}
local NUM_MECH = #MECHANISMS

-- ---------------------------------------------------------------------
-- metrics -- ported from metrics.c: duty / flatness / mono, computed
-- identically for every mechanism regardless of topology or scale.
-- ---------------------------------------------------------------------

local function computeMetrics(compute, N)
  N = N or 720
  local X, Y = {}, {}
  for i = 0, N - 1 do
    local fd = compute(2.0 * math.pi * i / N)
    X[i], Y[i] = fd.foot.x, fd.foot.y
  end

  local ymin, ymax, xmin, xmax = Y[0], Y[0], X[0], X[0]
  for i = 1, N - 1 do
    if Y[i] < ymin then ymin = Y[i] end
    if Y[i] > ymax then ymax = Y[i] end
    if X[i] < xmin then xmin = X[i] end
    if X[i] > xmax then xmax = X[i] end
  end
  local thresh = ymin + 0.15 * (ymax - ymin)
  local xspan = xmax - xmin

  local stanceCount = 0
  local stanceMin, stanceMax = math.huge, -math.huge
  for i = 0, N - 1 do
    if Y[i] < thresh then
      stanceCount = stanceCount + 1
      if Y[i] < stanceMin then stanceMin = Y[i] end
      if Y[i] > stanceMax then stanceMax = Y[i] end
    end
  end
  local duty = 100.0 * stanceCount / N
  local flatness = 100.0 * (stanceMax - stanceMin) / xspan

  local dtheta = 2.0 * math.pi / N
  local dX = {}
  for i = 0, N - 1 do
    if i == 0 then
      dX[i] = (X[1] - X[0]) / dtheta
    elseif i == N - 1 then
      dX[i] = (X[N - 1] - X[N - 2]) / dtheta
    else
      dX[i] = (X[i + 1] - X[i - 1]) / (2.0 * dtheta)
    end
  end

  local pos, neg = 0, 0
  for i = 0, N - 1 do
    if Y[i] < thresh then
      if dX[i] < 0 then neg = neg + 1
      elseif dX[i] > 0 then pos = pos + 1 end
    end
  end
  local mono = 0.0
  if stanceCount > 0 then
    mono = (pos > neg) and (pos / stanceCount) or (neg / stanceCount)
  end

  return { duty = duty, flatness = flatness, mono = mono }
end

-- ---------------------------------------------------------------------
-- scene: link rods (Cylinder), ground pivots + foot (Sphere), and a
-- static traced foot-path polyline, all rebuilt from scratch whenever
-- the mechanism switches. Everything is mass 0 -- see the "WHY NO
-- PHYSICS" header note.
-- ---------------------------------------------------------------------

local TARGET_EXTENT = 24.0    -- world units the larger bbox side is scaled to fit
local BOUNDS_SAMPLES = 240    -- samples/cycle used only to fit the normalization
local TRAIL_SAMPLES  = 160    -- segments in the drawn foot-path polyline
local SPEED = 1.2             -- crank angular speed, radians/second

local ROD_RADIUS   = TARGET_EXTENT * 0.010
local PIVOT_RADIUS = TARGET_EXTENT * 0.026
local FOOT_RADIUS  = TARGET_EXTENT * 0.030
local TRAIL_RADIUS = ROD_RADIUS * 0.4

local ROD_COLOR   = "#d9d9e6"
local PIVOT_COLOR = "#f87373"
local FOOT_COLOR  = "#33cc99"
local TRAIL_COLOR = "#f573a8"

local mechIndex = 1
local theta = 0.0
local scaleFactor, centerX, centerY = 1.0, 0.0, 0.0

local linkCyls     = {}   -- one Cylinder per segment, repositioned every frame
local pivotSpheres  = {}  -- one Sphere per ground pivot, fixed for the mechanism's lifetime
local footSphere    = nil
local trailCyls     = {}  -- static foot-path polyline, rebuilt only on switch
local nameLabel      = nil

-- samples a full crank rotation and returns the (x,y) bounding box over
-- every segment endpoint, pivot, and foot position -- not just the
-- current pose -- so the normalization below never clips as it rotates
-- (matches main.c's compute_view_bounds, which does the same sweep).
local function computeBounds(compute)
  local xmin, xmax, ymin, ymax = math.huge, -math.huge, math.huge, -math.huge
  local function grow(p)
    if p.x < xmin then xmin = p.x end
    if p.x > xmax then xmax = p.x end
    if p.y < ymin then ymin = p.y end
    if p.y > ymax then ymax = p.y end
  end
  for i = 0, BOUNDS_SAMPLES - 1 do
    local fd = compute(2.0 * math.pi * i / BOUNDS_SAMPLES)
    grow(fd.foot)
    for _, seg in ipairs(fd.segments) do grow(seg[1]); grow(seg[2]) end
    for _, pv in ipairs(fd.pivots) do grow(pv) end
  end
  return xmin, xmax, ymin, ymax
end

local function toWorld(p)
  return btVector3((p.x - centerX) * scaleFactor, (p.y - centerY) * scaleFactor, 0)
end

local function clearMechanism()
  for i = 1, #linkCyls do
    if linkCyls[i] ~= nil then v:remove(linkCyls[i]) end
  end
  for _, s in ipairs(pivotSpheres) do v:remove(s) end
  for _, c in ipairs(trailCyls) do v:remove(c) end
  if footSphere ~= nil then v:remove(footSphere) end
  if nameLabel ~= nil then v:remove(nameLabel) end
  linkCyls, pivotSpheres, trailCyls = {}, {}, {}
  footSphere, nameLabel = nil, nil
end

local function buildMechanism(idx)
  clearMechanism()
  mechIndex = idx
  local mech = MECHANISMS[mechIndex]

  local xmin, xmax, ymin, ymax = computeBounds(mech.compute)
  local maxDim = math.max(xmax - xmin, ymax - ymin, 1e-6)
  scaleFactor = TARGET_EXTENT / maxDim
  centerX, centerY = (xmin + xmax) / 2.0, (ymin + ymax) / 2.0
  theta = 0.0

  local fd = mech.compute(theta)

  for si = 1, #fd.segments do
    local seg = fd.segments[si]
    linkCyls[si] = placeCylinder(toWorld(seg[1]), toWorld(seg[2]), ROD_RADIUS, ROD_COLOR)
  end

  for _, pv in ipairs(fd.pivots) do
    local s = Sphere(PIVOT_RADIUS, 0)
    s.col = PIVOT_COLOR
    s.pos = toWorld(pv)
    v:add(s)
    table.insert(pivotSpheres, s)
  end

  footSphere = Sphere(FOOT_RADIUS, 0)
  footSphere.col = FOOT_COLOR
  footSphere.pos = toWorld(fd.foot)
  v:add(footSphere)

  -- traced foot path over one full crank cycle, drawn once as a dim
  -- polyline (a static reference curve -- the bright foot sphere above
  -- is what actually moves along it every frame).
  local prevP = toWorld(mech.compute(0.0).foot)
  for i = 1, TRAIL_SAMPLES do
    local p = toWorld(mech.compute(2.0 * math.pi * i / TRAIL_SAMPLES).foot)
    local cy = placeCylinder(prevP, p, TRAIL_RADIUS, TRAIL_COLOR)
    if cy ~= nil then
      cy.transparency = 0.6
      table.insert(trailCyls, cy)
    end
    prevP = p
  end

  -- floating name label above the mechanism, generated via OpenSCAD text
  -- extrusion (see demo/module/scad/text.lua) -- best-effort: pcall'd so
  -- a missing/misconfigured openscad binary just skips the label instead
  -- of aborting the whole demo.
  local topY = (ymax - centerY) * scaleFactor
  local ok, obj = pcall(function()
    return text.new({
      str = mech.name, size = TARGET_EXTENT * 0.09, height = 0.15,
      x = 0, y = topY + TARGET_EXTENT * 0.16, z = 0, mass = 0, col = "#eaeaf2",
    })
  end)
  if ok and obj ~= nil then
    nameLabel = obj
    v:add(nameLabel)
  end

  local m = computeMetrics(mech.compute, 720)
  print(string.format(
    "[%d/%d] %s  (links=%d sliders=%d twin=%s)  duty=%.1f%%  flatness=%.2f%%  mono=%.3f",
    mechIndex, NUM_MECH, mech.name, mech.links, mech.sliders,
    mech.twin and "yes" or "no", m.duty, m.flatness, m.mono))
  print("    " .. mech.params)
end

local function updatePose()
  local mech = MECHANISMS[mechIndex]
  local fd = mech.compute(theta)

  for si = 1, #fd.segments do
    local seg = fd.segments[si]
    repositionCylinder(linkCyls[si], toWorld(seg[1]), toWorld(seg[2]))
  end

  footSphere.pos = toWorld(fd.foot)
end

v:preSim(function(N)
  theta = theta + SPEED * v.timeStep
  if theta > 2.0 * math.pi then theta = theta - 2.0 * math.pi end
  updatePose()
end)

-- ******************
-- KEYBOARD SHORTCUTS
-- ******************

v:addShortcut("F1", function(N)
  local idx = mechIndex - 1
  if idx < 1 then idx = NUM_MECH end
  buildMechanism(idx)
end)

v:addShortcut("F2", function(N)
  local idx = mechIndex + 1
  if idx > NUM_MECH then idx = 1 end
  buildMechanism(idx)
end)

-- ---------------------------------------------------------------------
-- initial scene + fixed camera (see "WHY NORMALIZED COORDINATES" above
-- for why one framing works for every mechanism, and why this is set
-- only once here rather than re-aimed every frame from postSim/preDraw
-- -- that leaves the viewer's own mouse/arrow-key camera controls free
-- to use between switches).
-- ---------------------------------------------------------------------

print("Walking Linkage Comparison Suite -- F1: previous mechanism, F2: next mechanism")

buildMechanism(1)

common.setCamera(btVector3(0, TARGET_EXTENT * 0.15, TARGET_EXTENT * 3.7),
                  btVector3(0, TARGET_EXTENT * 0.15, 0), 0.5)

-- EOF
