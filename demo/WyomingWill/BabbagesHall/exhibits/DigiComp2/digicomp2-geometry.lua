-- digicomp2-geometry.lua -- Babbage's Hall, the Digi-Comp II (step 2a: the accumulator)
--
-- Every shape of the machine in one place: the simulation builds its bodies
-- and walls from these, and make-stls.sh writes them out for OpenSCAD
-- (parts/geometry.scad), which builds the printed parts from the very same
-- numbers. So what is printed is what was simulated.
--
-- The board's own frame (cm): x across it, to the right as you face it; y
-- out of the board (up from its face); z down the slope, toward you.
--
-- TWO LEVELS, as E.S.R.'s: the upper plate (its face y = 0, PT thick), on
-- which the balls compute, and under it the lower level (its face y = YL),
-- GAP high, on which balls that are done roll down to the collector, out of
-- the way of everything above. A ball leaves the upper level by dropping
-- through a hole. Walls stand on both levels; the flip-flops turn on pins
-- standing up from the lower board, through the plate.
--
-- Every number here was tuned in the simulation (see FINDINGS.md).

local G = {}

G.TH = 15                     -- the board's slope, degrees
G.R, G.BALL_MASS = 0.635, 0.00835   -- 1/2 inch steel balls (12.7 mm, 8.35 g)
G.PLA = 1.24e-3               -- kg per cm^3 (printed solid)
G.WALL_H, G.WALL_T = 1.2, 0.3 -- the walls: 12 mm high, 3 mm thick
G.CHAN = 2 * G.R + 0.15       -- a channel's width inside: the ball and 1.5 mm
G.PT = 0.4                    -- the upper plate's thickness (printed in tiles)
G.GAP = 2 * G.R + 0.25        -- the lower level's clear height: a ball and 2.5 mm
G.YL = -G.PT - G.GAP          -- the lower level's face
G.BACK = 0.6                  -- the lower board (6 mm plywood), under the lower level
G.FOOT = 1.0                  -- the board's front edge stands this high on its stand
G.HOLE = 1.45                 -- a hole a ball drops through: 14.5 mm square

-- ---------------------------------------------------------------------
-- the flip-flop: a rocker on a pin, in its own frame (its pivot at 0, 0)
-- ---------------------------------------------------------------------
-- An inverted V (a roof), its apex A up the slope from the pivot, with a
-- cup at each end (the roof's end and a lip) and a tail below the pivot.
-- Its centre of mass is up the slope from the pivot, so it falls over to
-- one side or the other and rests there, its tail on a stop peg: it is
-- over-centre, and stays as it is left. A ball coming straight down the
-- slope meets the roof on the side that is raised, rolls into that side's
-- cup, and its weight takes the rocker over to the other side; at the end
-- of the swing the cup tips it out. So each ball leaves on the other side
-- from the last: a flip-flop, by its shape and weight alone.
local F = {}
G.FLIP = F
F.A = 1.0                     -- the apex, up the slope from the pivot
F.BETA = 30                   -- the roof's slope, degrees
F.L = 1.6                     -- the roof's half-width
F.W = 0.35                    -- its strips' width (in the board's plane)
F.Y0, F.H = 0.15, 0.9         -- it stands 1.5 mm off the board (on the pin's boss), 9 mm high
F.T = 0.9                     -- the tail, down the slope from the pivot
F.LIP, F.GAM = 0.5, 67        -- the lips: 5 mm long, leaning out 67 degrees from straight up the slope
F.WEIGHT, F.WEIGHT_R = 0.00104, 0.3175    -- a 1/4 inch steel ball (1.04 g) pressed into the rocker ...
F.WEIGHT_Z = -0.58            -- ... this far up the slope from the pin: it makes the rocker's two
                              -- leanings deep enough that it never bounces back out of one
F.ALPHA = 12                  -- its lean either way, degrees (where the tail meets a stop)
F.PEG_R = 0.25                -- the stop pegs' radius
F.PIN_R = 0.15                -- the pin (3 mm steel)
F.HUB_R = 0.45                -- the hub round the pin
F.BOSS_R = 0.4                -- the boss on the lower board the foot rests on
-- its foot, on the lower level (for CLEAR): an arm up the slope from the pin,
-- ending in a wedge that leans out to the right when the rocker reads 1. A
-- ball rolling down the clear lane beside it meets the wedge's sloping face
-- and pushes it left, which turns the rocker to 0; at 0 the wedge is out of
-- the lane and the ball passes. A stem (STEM_R) joins it to the rocker up
-- through a hole in the plate.
F.LF, F.FP = 2.0, 0.8         -- the arm's length up the slope; how far the wedge reaches right
F.STEM_R = 0.35               -- the stem through the plate
F.FY0 = G.YL + 0.3            -- the foot stands 3 mm off the lower board (on its boss) ...
F.FY1 = -G.PT - 0.2           -- ... up to 2 mm under the plate
F.RUN = 2.0                   -- the straight run of channel above each flip-flop

-- the mass, centre of mass and moment of inertia (about the board's normal)
-- of a union of convex pieces { {x, z}, ... }, h high: by summing it over
-- a fine grid (the pieces overlap where they join)
local function inside(pc, x, z)
  local sgn = 0
  for i = 1, #pc do
    local a, b = pc[i], pc[i % #pc + 1]
    local c = (b[1] - a[1]) * (z - a[2]) - (b[2] - a[2]) * (x - a[1])
    if c ~= 0 then
      local s = c > 0 and 1 or -1
      if sgn == 0 then sgn = s elseif s ~= sgn then return false end
    end
  end
  return true
end
function G.massOf(pieces, h, holes, step)
  step = step or 0.01
  local x0, x1, z0, z1 = 1e9, -1e9, 1e9, -1e9
  for _, pc in ipairs(pieces) do
    for _, p in ipairs(pc) do
      x0 = math.min(x0, p[1]); x1 = math.max(x1, p[1]); z0 = math.min(z0, p[2]); z1 = math.max(z1, p[2])
    end
  end
  local n, sx, sz, sxx = 0, 0, 0, 0
  for x = x0 + step / 2, x1, step do
    for z = z0 + step / 2, z1, step do
      local out = false
      for _, c in ipairs(holes or {}) do
        if (x - c[1]) ^ 2 + (z - c[2]) ^ 2 < c[3] ^ 2 then out = true; break end
      end
      if not out then
        for _, pc in ipairs(pieces) do
          if inside(pc, x, z) then n = n + 1; sx = sx + x; sz = sz + z; sxx = sxx + x * x + z * z; break end
        end
      end
    end
  end
  local area = n * step * step
  local m = area * h * G.PLA
  local cx, cz = sx / n, sz / n
  local I = m * (sxx / n - cx * cx - cz * cz)
  return m, cx, cz, I, area
end
local function circle(r, n)
  local pc = {}
  for j = 0, n - 1 do local a = 2 * math.pi * j / n; pc[#pc + 1] = { r * math.cos(a), r * math.sin(a) } end
  return pc
end

-- its pieces (convex outlines { {x, z}, ... } in its frame): the roof's two
-- faces (their upper edges meet at the apex), the strut and tail, the
-- lips, the corners joining lips to faces, and the hub
do
  local b, g = math.rad(F.BETA), math.rad(F.GAM)
  local zEnd = -F.A + F.L * math.tan(b)
  F.zEnd = zEnd
  local W = F.W
  local P = {}
  local function add(...) P[#P + 1] = { ... } end
  local ax, az = 0, -F.A
  local hw = W / 2
  -- the strut, its top cut to the roof's slope (nothing stands above the roof)
  add({ ax, az }, { hw, az + hw * math.tan(b) }, { hw, F.T }, { -hw, F.T }, { -hw, az + hw * math.tan(b) })
  for _, s in ipairs({ -1, 1 }) do
    local ex, ez = s * F.L, zEnd
    local nx, nz = -s * math.sin(b), math.cos(b)                  -- (into the face, away from its upper edge)
    add({ ax, az }, { ex, ez }, { ex + W * nx, ez + W * nz }, { ax + W * nx, az + W * nz })
    local ux, uz = s * math.sin(g), -math.cos(g)                   -- (up the lip's inner face)
    local mx, mz = s * math.cos(g), math.sin(g)                    -- (out of the cup)
    add({ ex, ez }, { ex + F.LIP * ux, ez + F.LIP * uz }, { ex + F.LIP * ux + W * mx, ez + F.LIP * uz + W * mz },
        { ex + W * mx, ez + W * mz })
    add({ ex, ez }, { ex + W * mx, ez + W * mz }, { ex + W * nx, ez + W * nz })
  end
  P[#P + 1] = circle(F.HUB_R, 16)
  -- the block under the apex that holds the weight (its upper edges on the roof's)
  local bx, bz = 0.75, 0.45
  add({ ax, az }, { bx, az + bx * math.tan(b) }, { bz, -0.15 }, { -bz, -0.15 }, { -bx, az + bx * math.tan(b) })
  F.pieces = P
  -- the stem and the foot: { outline, y0, height }
  F.lower = {
    { circle(F.STEM_R, 16), F.FY0, F.Y0 - F.FY0 },
    { { { -hw, -F.LF }, { hw, -F.LF }, { hw, 0 }, { -hw, 0 } }, F.FY0, F.FY1 - F.FY0 },
    { { { -hw, -F.LF }, { hw, -F.LF }, { F.FP, -F.LF + F.FP - hw }, { F.FP, -F.LF + F.FP - hw + 0.4 }, { -hw, -F.LF + 0.6 } },
      F.FY0, F.FY1 - F.FY0 },
  }
  -- the printed rocker (less its pin hole and the weight's pocket), the
  -- weight, then the stem and foot (printed, less the pin hole)
  local pm, pcx, pcz, pI = G.massOf(P, F.H, { { 0, 0, F.PIN_R } })
  -- (less the pocket: as deep as the steel ball and 0.2 mm, from the top face)
  local km = math.pi * F.WEIGHT_R ^ 2 * (2 * F.WEIGHT_R + 0.02) * G.PLA
  local qm = pm - km
  local qcx, qcz = pm * pcx / qm, (pm * pcz - km * F.WEIGHT_Z) / qm
  pI = pI + pm * ((pcx - qcx) ^ 2 + (pcz - qcz) ^ 2) - km * (qcx ^ 2 + (F.WEIGHT_Z - qcz) ^ 2)
  local parts = { { m = qm, x = qcx, z = qcz, i = pI }, { m = F.WEIGHT, x = 0, z = F.WEIGHT_Z, i = 0 } }
  F.printed = qm
  F.footMass = 0
  -- (the foot and the stem where they overlap, as one; then the stem above
  -- the foot, and the 4 mm of it glued up into the rocker's hub, in place of
  -- the socket's PLA: no change there)
  local stem, arm, wedge = F.lower[1][1], F.lower[2][1], F.lower[3][1]
  for _, l in ipairs({ { { stem, arm, wedge }, F.FY1 - F.FY0 }, { { stem }, F.Y0 - F.FY1 } }) do
    local lm, lx, lz, lI = G.massOf(l[1], l[2], { { 0, 0, F.PIN_R } })
    parts[#parts + 1] = { m = lm, x = lx, z = lz, i = lI }
    F.footMass = F.footMass + lm
  end
  local m, cx, cz = 0, 0, 0
  for _, q in ipairs(parts) do m = m + q.m; cx = cx + q.m * q.x; cz = cz + q.m * q.z end
  cx, cz = cx / m, cz / m
  local I = 0
  for _, q in ipairs(parts) do I = I + q.i + q.m * ((q.x - cx) ^ 2 + (q.z - cz) ^ 2) end
  F.mass, F.cx, F.cz, F.I = m, cx, cz, I
  -- the stop pegs: the tail (width W) rests on one at a lean of ALPHA
  local a = math.rad(F.ALPHA)
  F.pegZ = F.T - 0.25
  F.pegX = (F.PEG_R + F.W / 2 + F.pegZ * math.sin(a)) / math.cos(a)
end

-- ---------------------------------------------------------------------
-- the switches: set by hand, a ball goes one way or the other
-- ---------------------------------------------------------------------
-- A flap on a pin at the tip of the divider between two outlets, its free
-- end up the slope against one wall of the inlet, closing that outlet. A
-- ball pushes it harder against the wall and leaves by the other outlet; its
-- centre of mass is up the slope from its pin, so it stays either way.
local S = {}
G.SWITCH = S
S.FL = 2.0                    -- the flap's length
S.FT = 0.3                    -- its thickness
S.Y0, S.H = 0.15, 0.9
S.IW = G.CHAN + S.FT + 0.1    -- the inlet's width inside: a ball beside the flap
S.OX = S.IW / 2 + G.CHAN / 2 + 0.05      -- each outlet's centre, from the switch's
S.DROP = 0.8                  -- the straight inlet above the flap's end
S.OUT = 2.4                   -- the outlets' length below the flap's pin
S.ANG = math.deg(math.asin((S.IW / 2 - S.FT / 2) / S.FL))   -- its lean either way
S.mass = S.FL * S.FT * S.H * G.PLA
S.I = S.mass * S.FL * S.FL / 3

-- ---------------------------------------------------------------------
-- the accumulator: seven flip-flops down a staircase, A1 (1s) to A7 (64s)
-- ---------------------------------------------------------------------
-- A ball that finds a flip-flop at 0 sets it to 1 and leaves to the right,
-- through a hole to the lower level: done. One that finds it at 1 sets it
-- to 0 and leaves to the left, down to the next flip-flop: the carry. A
-- carry out of A7 (the 128th ball) drops through the overflow hole.
G.NBITS = 7
G.DX, G.DZ = 3.5, 8.0         -- each flip-flop this far left and down from the last
G.FUNNEL = { 2.0, 1.4 }       -- a funnel's half-width at its mouth, and its depth
G.DONE = { 3.1, 1.3 }         -- a done hole's centre from its flip-flop's pin
G.XC = 1.45                   -- the clear lane's centre, right of each pin (on the lower level)
G.CLEAR_MARGIN = 0.05         -- past each foot, the lane narrows to hold the ball this far clear of
                              -- the wedge of a rocker at 0 (see footWalls, below)
G.toggles = {}
for k = 0, G.NBITS - 1 do G.toggles[k + 1] = { x = -k * G.DX, z = k * G.DZ } end
local function runTop(t) return t.z - F.A - 1.4 - G.R - F.RUN end

-- above A1, down the slope: the feeder, the CLEAR switch, the COUNT switch
--   COUNT: its left outlet runs into A1 (ON); its right drops to the lower level (OFF)
--   CLEAR: its left outlet drops into the clear lane (ON); its right runs into COUNT (OFF)
G.switches = {}
do
  local t = G.toggles[1]
  local cz = runTop(t) - S.OUT
  G.switches.COUNT = { x = t.x + S.OX, z = cz, name = "COUNT" }
  local kz = cz - S.FL - S.DROP - S.OUT
  G.switches.CLEAR = { x = t.x, z = kz, name = "CLEAR" }
end

-- the feeder: a wheel with four notches, at the foot of a channel of balls.
-- Each quarter turn of its knob (by hand: START) carries one ball round from
-- the top and lets it out at the bottom, into the CLEAR switch.
local Wh = {}
G.WHEEL = Wh
Wh.R = 2.05                   -- its radius
Wh.NOTCH_W = 2 * G.R + 0.1    -- a notch's width
Wh.HUB = Wh.NOTCH_W / 2 + 0.05  -- the hub, a square this far each way: a little wider than the
                              -- notches, so the teeth join it (one solid part)
Wh.NOTCH_D = Wh.R - Wh.HUB    -- a notch's depth from the rim (a ball sits wholly inside it)
Wh.Y0, Wh.H = 0.15, 0.9       -- (as the flip-flops)
Wh.GAP = 0.06                 -- between its rim and the housing
Wh.QUEUE = 13.5               -- the channel of balls above it (ten of them)
do
  local k = G.switches.CLEAR
  local inletTop = k.z - S.FL - S.DROP
  local rr = Wh.R + Wh.GAP + G.WALL_T / 2
  local C = G.CHAN / 2 + G.WALL_T / 2
  Wh.x = k.x
  Wh.z = inletTop - math.sqrt(rr * rr - C * C) - 0.2
  Wh.ballR = Wh.R - Wh.NOTCH_D + G.R              -- a ball's centre in a notch, from the wheel's
  local h = Wh.R - Wh.NOTCH_D
  local w = Wh.NOTCH_W / 2
  Wh.pieces = { { { -h, -h }, { h, -h }, { h, h }, { -h, h } } }
  for q = 0, 3 do
    local c, s = math.cos(q * math.pi / 2), math.sin(q * math.pi / 2)
    local pts = {}
    local a0 = math.asin(w / Wh.R)                  -- (the tooth's arc: from one notch's edge to the next)
    local function add(x, z) pts[#pts + 1] = { c * x - s * z, s * x + c * z } end
    add(w, w)
    for j = 0, 6 do
      local a = a0 + (math.pi / 2 - 2 * a0) * j / 6
      add(Wh.R * math.sin(a), Wh.R * math.cos(a))
    end
    Wh.pieces[#Wh.pieces + 1] = pts
  end
  local cx, cz
  Wh.mass, cx, cz, Wh.I = G.massOf(Wh.pieces, Wh.H, { { 0, 0, F.PIN_R } }, 0.02)
end

-- ---------------------------------------------------------------------
-- the fixed parts: walls { x1, z1, x2, z2 } (centre lines, WALL_T thick)
-- on the upper level and on the lower; pegs; holes { x0, x1, z0, z1 }
-- ---------------------------------------------------------------------
G.walls, G.lwalls, G.pegs, G.holes, G.bosses = {}, {}, {}, {}, {}
local function wall(x1, z1, x2, z2, role) G.walls[#G.walls + 1] = { x1, z1, x2, z2, role = role } end
local function lwall(x1, z1, x2, z2, role, h) G.lwalls[#G.lwalls + 1] = { x1, z1, x2, z2, h or G.GAP, role = role } end
local function hole(x, z, role, s) s = s or G.HOLE; G.holes[#G.holes + 1] = { x - s / 2, x + s / 2, z - s / 2, z + s / 2, role = role } end
local C = G.CHAN / 2 + G.WALL_T / 2          -- a channel's wall, from its centre line
local HS = G.HOLE
-- a drop hole at the end of a channel coming straight down at x, ending at z:
-- the hole just past the end, walled round on three sides
local function dropAt(x, z, role)
  hole(x, z + HS / 2 + 0.05, role)
  wall(x - C, z, x - C, z + HS + 0.2, role); wall(x + C, z, x + C, z + HS + 0.2, role)
  wall(x - C, z + HS + 0.25, x + C, z + HS + 0.25, role)
  return x, z + HS / 2 + 0.05
end

-- the switches' walls
local function switchWalls(sw)
  local x, z = sw.x, sw.z
  local half = S.IW / 2
  local CI = half + G.WALL_T / 2
  local OC = G.CHAN / 2 + G.WALL_T / 2
  local top = z - S.FL - S.DROP
  wall(x - CI, top, x - CI, z - S.FL + 0.2, "switch"); wall(x + CI, top, x + CI, z - S.FL + 0.2, "switch")
  wall(x - CI, z - S.FL + 0.2, x - S.OX - OC, z + 0.6, "switch"); wall(x + CI, z - S.FL + 0.2, x + S.OX + OC, z + 0.6, "switch")
  wall(x - S.OX - OC, z + 0.6, x - S.OX - OC, z + S.OUT, "switch"); wall(x + S.OX + OC, z + 0.6, x + S.OX + OC, z + S.OUT, "switch")
  wall(x, z + 0.55, x - S.OX + OC, z + 1.8, "switch"); wall(x, z + 0.55, x + S.OX - OC, z + 1.8, "switch")
  wall(x - S.OX + OC, z + 1.8, x - S.OX + OC, z + S.OUT, "switch"); wall(x + S.OX - OC, z + 1.8, x + S.OX - OC, z + S.OUT, "switch")
  sw.top = top
  sw.left, sw.right = { x - S.OX, z + S.OUT }, { x + S.OX, z + S.OUT }
end
switchWalls(G.switches.CLEAR)
switchWalls(G.switches.COUNT)
-- CLEAR's left outlet: into the clear lane; COUNT's right: to the collector
do
  local l = G.switches.CLEAR.left
  G.clearDrop = { dropAt(l[1], l[2], "clear") }
  local r = G.switches.COUNT.right
  G.countOffDrop = { dropAt(r[1], r[2], "drop") }
end

-- the flip-flops
for k, t in ipairs(G.toggles) do
  local x, z = t.x, t.z
  local rb = z - F.A - 1.4 - G.R
  local rt = rb - F.RUN
  wall(x - C, rt, x - C, rb); wall(x + C, rt, x + C, rb)
  if k > 1 then
    wall(x - C, rt, x - G.FUNNEL[1], rt - G.FUNNEL[2])
    wall(x + C, rt, x + G.FUNNEL[1], rt - G.FUNNEL[2])
  end
  G.pegs[#G.pegs + 1] = { x - F.pegX, z + F.pegZ, F.PEG_R }
  G.pegs[#G.pegs + 1] = { x + F.pegX, z + F.pegZ, F.PEG_R }
  G.bosses[#G.bosses + 1] = { x, z }
  hole(x, z, "stem", 2 * (F.STEM_R + 0.05))
  -- the done hole on its right, a wall beyond it and below it
  local hx, hz = x + G.DONE[1], z + G.DONE[2]
  hole(hx, hz, "done")
  wall(hx + HS / 2 + 0.15, hz - HS / 2 - 0.6, hx + HS / 2 + 0.15, hz + HS / 2 + 0.15, "done")
  wall(hx - HS / 2, hz + HS / 2 + 0.15, hx + HS / 2 + 0.15, hz + HS / 2 + 0.15, "done")
  t.done = { hx, hz }
end
-- the overflow: A7's carry drops through a hole on its left
do
  local t = G.toggles[G.NBITS]
  local hx, hz = t.x - G.DONE[1], t.z + G.DONE[2]
  hole(hx, hz, "overflow")
  wall(hx - HS / 2 - 0.15, hz - HS / 2 - 0.6, hx - HS / 2 - 0.15, hz + HS / 2 + 0.15, "overflow")
  wall(hx - HS / 2 - 0.15, hz + HS / 2 + 0.15, hx + HS / 2, hz + HS / 2 + 0.15, "overflow")
  G.overflow = { hx, hz }
end

-- the clear lane on the lower level: from under CLEAR's drop hole down past
-- each flip-flop's foot (its left wall open where the foot swings, its
-- right wall open under the done hole), then on to the next, and at last
-- down to the collector
-- the clear lane's right wall beside a flip-flop's foot: it narrows so the
-- ball passes the wedge with its left side just clear of where the wedge is
-- when the rocker is at 0 (against its stop). So a ball meeting a wedge at
-- 1 must push it all the way back to 0, and one finding it at 0 touches
-- nothing. (Left to roll free, a ball pushed the wedge only until it could
-- squeeze by, which left the rocker near the middle: see FINDINGS.md.)
function G.footWalls(t)
  local a = math.rad(F.ALPHA)
  local tip = -1e9                                 -- (the wedge's right edge at 0: turned ALPHA right-handed)
  for _, p in ipairs(F.lower[3][1]) do tip = math.max(tip, p[1] * math.cos(a) + p[2] * math.sin(a)) end
  local xn = t.x + tip + G.CLEAR_MARGIN + G.R       -- (the ball's centre as it passes the wedge)
  local x = t.x + G.XC
  local zf = t.z - F.LF
  local c = C
  -- (it begins 1.0 above the wedge, below where the lane's bend from the
  -- last flip-flop has brought its right wall in line)
  return { { x + c, zf - 1.0, xn + c, zf - 0.5 }, { xn + c, zf - 0.5, xn + c, zf + 1.6 },
           { xn + c, zf + 1.6, x + c, zf + 2.1 }, { x + c, zf + 2.1, x + c, t.z + 0.3 } }
end

-- a lane's walls from its centre line, mitred at the bends; gaps { side
-- (-1 left, 1 right), z0, z1 } leave a wall open over that stretch of z
-- (on a straight run down the slope)
local function laneWalls(P, gaps, add)
  local n = #P
  local function dir(i)
    local dx, dz = P[i + 1][1] - P[i][1], P[i + 1][2] - P[i][2]
    local l = math.sqrt(dx * dx + dz * dz)
    return dx / l, dz / l
  end
  for _, side in ipairs({ -1, 1 }) do
    local Q = {}
    for i = 1, n do
      local nx, nz
      if i == 1 then local dx, dz = dir(1); nx, nz = dz, -dx
      elseif i == n then local dx, dz = dir(n - 1); nx, nz = dz, -dx
      else
        local ax, az = dir(i - 1)
        local bx, bz = dir(i)
        local mx, mz = az + bz, -(ax + bx)               -- (the bisector of the two normals)
        local ml = math.sqrt(mx * mx + mz * mz)
        mx, mz = mx / ml, mz / ml
        local c = mx * az - mz * ax                      -- (its cosine with either normal)
        nx, nz = mx / c, mz / c
      end
      if nx < 0 or (nx == 0 and nz > 0) then nx, nz = -nx, -nz end   -- (n points right, +x)
      Q[i] = { P[i][1] + side * C * nx, P[i][2] + side * C * nz }
    end
    for i = 1, n - 1 do
      local pieces = { { Q[i], Q[i + 1] } }
      for _, g in ipairs(gaps) do
        if g[1] == side then
          local out = {}
          for _, pc in ipairs(pieces) do
            local a, b = pc[1], pc[2]
            local z0, z1 = math.min(a[2], b[2]), math.max(a[2], b[2])
            if g[3] <= z0 or g[2] >= z1 or math.abs(a[1] - b[1]) > 1e-6 then out[#out + 1] = pc
            else
              if g[2] > z0 then out[#out + 1] = { { a[1], z0 }, { a[1], g[2] } } end
              if g[3] < z1 then out[#out + 1] = { { a[1], g[3] }, { a[1], z1 } } end
            end
          end
          pieces = out
        end
      end
      for _, pc in ipairs(pieces) do add(pc[1][1], pc[1][2], pc[2][1], pc[2][2], "clear") end
    end
  end
end
G.ZCOL = G.toggles[G.NBITS].z + 6.0         -- the collector's wall, on the lower level
G.COL_H = 3.0                                -- its height
do
  local d = G.clearDrop
  local P = { { d[1], d[2] - HS / 2 - 0.6 }, { d[1], d[2] + 0.6 } }
  local gaps = {}
  for k, t in ipairs(G.toggles) do
    local x, zf = t.x + G.XC, t.z - F.LF
    P[#P + 1] = { x, zf - 1.6 }
    -- (past the foot: the left wall open from 1.6 above the wedge to 2.3
    -- below, past the narrowing (the right wall there, below); under the
    -- done hole, the right wall open)
    gaps[#gaps + 1] = { -1, zf - 1.6, zf + 2.3 }
    gaps[#gaps + 1] = { 1, zf - 1.0, t.z + 2.2 }
    for _, w in ipairs(G.footWalls(t)) do lwall(w[1], w[2], w[3], w[4], "clear") end
    if k < G.NBITS then P[#P + 1] = { x, t.z + 2.2 } end
  end
  local last = G.toggles[G.NBITS]
  P[#P + 1] = { last.x + G.XC, G.ZCOL - 3.5 }        -- (it ends well short of the collector's wall,
                                                     -- so balls can roll along the wall past it)
  laneWalls(P, gaps, lwall)
  lwall(d[1] - C, P[1][2], d[1] + C, P[1][2], "clear")             -- (its top)
  G.clearLane = P
end

-- the board's edges, the rims, the collector
do
  local x0, x1, z0, z1 = 1e9, -1e9, 1e9, -1e9
  local function see(x, z) x0 = math.min(x0, x); x1 = math.max(x1, x); z0 = math.min(z0, z); z1 = math.max(z1, z) end
  for _, w in ipairs(G.walls) do see(w[1], w[2]); see(w[3], w[4]) end
  for _, h in ipairs(G.holes) do see(h[1], h[3]); see(h[2], h[4]) end
  see(Wh.x - Wh.R - 1, Wh.z)
  -- the queue's channel and the wheel's housing (below) are inside these
  local M = 1.5
  G.board = { x0 = x0 - M, x1 = x1 + M, z0 = Wh.z - Wh.R - Wh.QUEUE - 1.5, z1 = z1 + M }
  G.lower = { x0 = G.board.x0, x1 = G.board.x1, z0 = G.board.z0, z1 = G.ZCOL + 2.5 }
end

-- the feeder's housing (a ring of short walls, open at the top to the
-- channel of balls and at the bottom to the CLEAR switch) and the channel
do
  local rr = Wh.R + Wh.GAP + G.WALL_T / 2
  local open = math.asin((C + G.WALL_T / 2) / rr)
  local N = 24
  for j = 0, N - 1 do
    local a0, a1 = 2 * math.pi * j / N, 2 * math.pi * (j + 1) / N
    -- (a measured from the top, clockwise as you look: x = sin a, z = -cos a)
    local function inOpen(a)
      local d = math.min(math.abs(a), math.abs(a - 2 * math.pi))
      local e = math.abs(a - math.pi)
      return d < open or e < open
    end
    local am = (a0 + a1) / 2
    if not inOpen(a0) and not inOpen(a1) and not inOpen(am) then
      local e = 0.04                            -- (each a little longer, so they overlap)
      wall(Wh.x + rr * math.sin(a0 - e), Wh.z - rr * math.cos(a0 - e),
           Wh.x + rr * math.sin(a1 + e), Wh.z - rr * math.cos(a1 + e), "housing")
    end
  end
  -- (a wall's box runs WALL_T / 2 past its ends: these start far enough out
  -- that their corners clear the wheel's rim)
  local top = Wh.z - math.sqrt(rr * rr - C * C) - 0.2
  wall(Wh.x - C, top, Wh.x - C, top - Wh.QUEUE, "queue")
  wall(Wh.x + C, top, Wh.x + C, top - Wh.QUEUE, "queue")
  wall(Wh.x - C - G.WALL_T / 2, top - Wh.QUEUE, Wh.x + C + G.WALL_T / 2, top - Wh.QUEUE, "queue")
  local bot = Wh.z + math.sqrt(rr * rr - C * C) + 0.2
  local inletTop = G.switches.CLEAR.top
  if inletTop > bot + 0.01 then
    wall(Wh.x - C, bot, Wh.x - C, inletTop); wall(Wh.x + C, bot, Wh.x + C, inletTop)
  end
  Wh.queueTop, Wh.queueBot = top - Wh.QUEUE, top
end
-- the rims (upper: round the plate; lower: its sides and the collector's
-- wall across the bottom, sloping down to the right so the balls line up
-- there, away from the clear lane and the overflow, which come in at the
-- left: lined up to the left, they had blocked the clear lane's end)
do
  local b, l = G.board, G.lower
  local B_Z1 = b.z1
  wall(b.x0 + 0.15, b.z0, b.x0 + 0.15, b.z1, "rim"); wall(b.x1 - 0.15, b.z0, b.x1 - 0.15, b.z1, "rim")
  wall(b.x0, b.z0 + 0.15, b.x1, b.z0 + 0.15, "rim")
  lwall(l.x0 + 0.15, l.z0, l.x0 + 0.15, l.z1, "rim"); lwall(l.x1 - 0.15, l.z0, l.x1 - 0.15, l.z1, "rim")
  -- (and its ends, as high)
  lwall(l.x0 + 0.15, B_Z1 + 0.35, l.x0 + 0.15, l.z1, "rim", G.COL_H); lwall(l.x1 - 0.15, B_Z1 + 0.35, l.x1 - 0.15, l.z1, "rim", G.COL_H)
  -- (the collector's wall is past the plate's end, with nothing over it: 3 cm
  -- high, so a ball that has rolled the length of the board can't jump it)
  lwall(l.x0, G.ZCOL - 1.0, l.x1, G.ZCOL + 1.0, "collector", G.COL_H)
  G.collector = { x0 = l.x0 + 0.3, x1 = l.x1 - 0.3, z = G.ZCOL }
end
-- the bosses on the lower board the feet stand on, and the posts holding the
-- plate up (round its edge, out of every ball's way)
G.posts = {}
do
  local b = G.board
  for z = b.z0 + 2, b.z1 - 1, 12 do
    G.posts[#G.posts + 1] = { b.x0 + 0.6, z }; G.posts[#G.posts + 1] = { b.x1 - 0.6, z }
  end
end

-- ---------------------------------------------------------------------
-- for OpenSCAD
-- ---------------------------------------------------------------------
function G.writeScad(path)
  local f = assert(io.open(path, "w"))
  local function num(n, x) f:write(string.format("%s = %.5f;\n", n, x)) end
  local function pts2(p) return string.format("[%.5f,%.5f]", p[1], p[2]) end
  local function list(name, items, fmt)
    local t = {}
    for _, it in ipairs(items) do t[#t + 1] = fmt(it) end
    f:write(name .. " = [" .. table.concat(t, ",\n  ") .. "];\n")
  end
  local function outline(pc) local q = {}; for _, p in ipairs(pc) do q[#q + 1] = pts2(p) end; return "[" .. table.concat(q, ",") .. "]" end
  f:write("// made by digicomp2.lua from digicomp2-geometry.lua (DC_EXPORT=1): do not edit (cm)\n")
  num("TH", G.TH); num("BALL_R", G.R); num("WALL_H", G.WALL_H); num("WALL_T", G.WALL_T)
  num("CHAN", G.CHAN); num("PT", G.PT); num("GAP", G.GAP); num("YL", G.YL); num("BACK", G.BACK); num("FOOT", G.FOOT)
  num("F_Y0", F.Y0); num("F_H", F.H); num("F_W", F.W); num("F_PIN_R", F.PIN_R); num("F_HUB_R", F.HUB_R)
  num("F_BOSS_R", F.BOSS_R); num("F_ALPHA", F.ALPHA); num("F_A", F.A)
  num("F_WEIGHT_R", F.WEIGHT_R); num("F_WEIGHT_Z", F.WEIGHT_Z)
  num("F_STEM_R", F.STEM_R); num("F_FY0", F.FY0); num("F_FY1", F.FY1)
  list("F_PIECES", F.pieces, outline)
  list("F_FOOT", { F.lower[2][1], F.lower[3][1] }, outline)
  num("S_FL", S.FL); num("S_FT", S.FT); num("S_Y0", S.Y0); num("S_H", S.H); num("S_ANG", S.ANG)
  num("W_Y0", Wh.Y0); num("W_H", Wh.H); num("W_R", Wh.R)
  list("W_PIECES", Wh.pieces, outline)
  f:write(string.format("WHEEL_AT = [%.5f,%.5f];\n", Wh.x, Wh.z))
  list("TOGGLES", G.toggles, function(t) return pts2({ t.x, t.z }) end)
  local sw = { G.switches.CLEAR, G.switches.COUNT }
  list("SWITCHES", sw, function(s) return pts2({ s.x, s.z }) end)
  local function seg(w) return string.format("[%.5f,%.5f,%.5f,%.5f]", w[1], w[2], w[3], w[4]) end
  list("WALLS", G.walls, seg)
  list("LWALLS", G.lwalls, function(w) return string.format("[%.5f,%.5f,%.5f,%.5f,%.5f]", w[1], w[2], w[3], w[4], w[5]) end)
  list("HOLES", G.holes, seg)
  list("PEGS", G.pegs, function(p) return string.format("[%.5f,%.5f,%.5f]", p[1], p[2], p[3]) end)
  list("POSTS", G.posts, pts2)
  local b, l = G.board, G.lower
  f:write(string.format("BOARD = [%.5f,%.5f,%.5f,%.5f];\n", b.x0, b.x1, b.z0, b.z1))
  f:write(string.format("LOWER = [%.5f,%.5f,%.5f,%.5f];\n", l.x0, l.x1, l.z0, l.z1))
  f:write(string.format("OVERFLOW = %s;\nCOUNT_OFF = %s;\nCLEAR_DROP = %s;\n", pts2(G.overflow), pts2(G.countOffDrop), pts2(G.clearDrop)))
  f:close()
end

return G
