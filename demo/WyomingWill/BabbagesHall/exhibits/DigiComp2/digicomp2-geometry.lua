-- digicomp2-geometry.lua -- Babbage's Hall, the Digi-Comp II (step 2b: counting, adding, multiplying)
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
-- ---------------------------------------------------------------------
-- the flip-flops: thirteen, all alike
-- ---------------------------------------------------------------------
-- A ball that finds a flip-flop at 0 (apex left) sets it to 1 and leaves to
-- the right; one that finds it at 1 sets it to 0 and leaves to the left.
-- Where each side leads makes the register:
--   the ACCUMULATOR, A1 (1s) to A7 (64s), down a staircase to the left:
--     right, through a done hole to the lower level; left, the carry, down
--     to the next (out of A7, the overflow hole)
--   the DISTRIBUTOR, D1 to D3, a tree: D1 sends the balls to D2 and D3 by
--     turns, and each of those by turns to its two outlets, so four balls go
--     four ways, round and round
--   the MQ (multiplier-quotient), MQ1 to MQ3, a staircase like A's, read
--     the other way (1 with the apex LEFT): so each ball takes one away. Its
--     right side is done; a borrow out of MQ3 (MQ was 0) drops through STOP
G.NBITS = 7
G.DX, G.DZ = 3.5, 8.0         -- each flip-flop of a staircase this far across and down from the last
G.ADZ = 14.75                 -- (the accumulator's: farther down, for the done lanes between, below)
G.FUNNEL = { 2.0, 1.4 }       -- a funnel's half-width at its mouth, and its depth
G.JOIN = { 3.5, 1.565, 2.6, 2.8 }   -- a joining funnel: one wall long, out to JOIN[1] across and
                              -- JOIN[2] up from the throat; a lane coming in ends JOIN[3] across, JOIN[4] up
G.DONE = { 3.1, 1.3 }         -- a done hole's centre from its flip-flop's pin (a square HOLE's)
G.DONE_L = 2.0                -- the accumulator's done holes run this far down the slope (from the same
                              -- top edge), so a ball drops in with no wall below to stop it ...
G.DONE_W = 1.8                -- ... and this far across (out to the left: their right edges as before), so
                              -- it drops in even running down off the hole's middle (a square one, 1.45,
                              -- left only 0.9 mm either side of the ball: tilted, it rode the edge and on)
G.DONE_LANE = { 0.5, 1.0 }    -- a done lane: straight down this far past its hole, and into the next funnel
G.XC = 1.45                   -- the clear lane's centre, right of each pin (on the lower level)
G.CLEAR_MARGIN = 0.05         -- past each foot, the lane narrows to hold the ball this far clear of
                              -- the wedge of a rocker at 0 (see footWalls, below)
G.MINSLOPE = 35               -- no lane runs flatter than this (degrees down from across)
G.warnings = {}

local RUNTOP = F.A + 1.4 + G.R + F.RUN       -- a flip-flop's run: its top (the funnel's throat), up from the pin
local function runTop(t) return t.z - RUNTOP end
local function mouthZ(t) return runTop(t) - G.FUNNEL[2] end

G.toggles = {}
for k = 0, G.NBITS - 1 do G.toggles[k + 1] = { x = -k * G.DX, z = k * G.ADZ, name = "A" .. (k + 1), kind = "A" } end
G.D1 = { -13.0, -34.0 }       -- the distributor's first flip-flop
G.D3OFF = { 8.0, 14.2 }       -- D3, from D1 (D2 is the next step of a staircase down to the left)
G.routers = {}
do
  local function at(name, x, z, kind) local t = { x = x, z = z, name = name, kind = kind }; G.routers[#G.routers + 1] = t; return t end
  local d1 = at("D1", G.D1[1], G.D1[2], "D")
  local d2 = at("D2", d1.x - G.DX, d1.z + G.DZ, "D")
  at("D3", d1.x + G.D3OFF[1], d1.z + G.D3OFF[2], "D")
  for k = 1, 3 do at("MQ" .. k, d2.x - k * G.DX, d2.z + k * G.DZ, "MQ") end
end
G.rockers = {}
for _, t in ipairs(G.toggles) do G.rockers[#G.rockers + 1] = t end
for _, t in ipairs(G.routers) do G.rockers[#G.rockers + 1] = t end
G.rocker = {}
for _, t in ipairs(G.rockers) do G.rocker[t.name] = t end

-- ---------------------------------------------------------------------
-- the switches, set by hand
-- ---------------------------------------------------------------------
--   MULTIPLY: on, the ball goes left, to the distributor; off, right, down to CLEAR
--   CLEAR:    on, right: it drops into the clear lane; off, left, on to COUNT
--   COUNT:    on, left, into A1; off, right: it drops to the lower level
--   M1 .. M4, the memory: 1, right, into A1 .. A4; 0, left: it drops
G.switches, G.switchList = {}, {}
local function newSwitch(name, x, z, on)
  local s = { name = name, x = x, z = z, on = on }
  G.switches[name] = s
  G.switchList[#G.switchList + 1] = s
  return s
end
local function inletTop(s) return s.z - S.FL - S.DROP end
-- where a lane coming into a joining funnel (its throat at x, zt; its long
-- wall on side) ends
local function joinEnd(x, zt, side) return { x + side * G.JOIN[3], zt - G.JOIN[4] } end
do
  local a1 = G.toggles[1]
  -- COUNT's left outlet ends over the long right wall of A1's funnel (A1's
  -- has two: M1 comes in on the left). Its ball has run down from MULTIPLY,
  -- 40 cm: falling straight into A1's run, it came too fast, and with the
  -- pins' friction at 2 or more left A1 near the middle; dropped onto the
  -- wall, it rolls in as slowly as the memory's
  local e = joinEnd(a1.x, runTop(a1), 1)
  local cnt = newSwitch("COUNT", e[1] + S.OX, e[2] - S.OUT, -1)
  newSwitch("CLEAR", cnt.x + S.OX, inletTop(cnt) - S.OUT, 1)
  for k = 1, 4 do
    local t = G.toggles[k]
    local e = joinEnd(t.x, runTop(t), -1)
    newSwitch("M" .. k, e[1] - S.OX, e[2] - S.OUT, 1)
  end
  local d1 = G.rocker.D1
  newSwitch("MULTIPLY", d1.x + S.OX, mouthZ(d1) - 0.15 - S.OUT, -1)
  -- (how the hand sets them up, for the parts' overlap check: 1, the flap
  -- against the left wall; -1, the right)
  for _, s in ipairs(G.switchList) do s.rest = (s.name == "MULTIPLY") and 1 or -1 end
end

-- the feeder: a wheel with four notches, at the foot of a channel of balls.
-- Each quarter turn of its knob (by hand: START) carries one ball round from
-- the top and lets it out at the bottom, into the MULTIPLY switch.
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
  local k = G.switches.MULTIPLY
  local rr = Wh.R + Wh.GAP + G.WALL_T / 2
  local C = G.CHAN / 2 + G.WALL_T / 2
  Wh.x = k.x
  Wh.z = inletTop(k) - math.sqrt(rr * rr - C * C) - 0.2
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

-- START and AUTO (not on the board yet: tests/escapement.lua tries them).
-- A weight the hand winds up turns the wheel, as a clock's turns its
-- train, through a fly (an air brake) that keeps it slow; an ANCHOR holds
-- it, a quarter turn at a time, as a clock's escapement holds its wheel.
-- (The balls' own weight can't turn it: letting one ball go means pushing
-- the next back up against all the balls above it. FINDINGS.md.) On the
-- wheel, above the balls, is the escape star: four pins. The anchor, on a
-- pin to the wheel's right, has two fingers: at rest the first stops a pin;
-- tripped (by START), the first lets it go and the second stops the next
-- pin an eighth of a turn on; let go again, the first stops the pin after
-- that. So each trip lets the wheel round one quarter turn, however long it
-- lasts, and lets one ball out. Each finger lies along the line from the
-- anchor's pin through the point where it stops a pin, so the wheel's push
-- on it passes through the anchor's pin and can't turn the anchor. The
-- first stops a pin coming toward the anchor's pin, so it lies on the near
-- side of that point; the second stops one moving away, so it lies beyond
-- it, carried by a bar over the pins. The anchor's arm runs up the slope;
-- START pushes its end across.
Wh.STAR_Y0, Wh.STAR_H = 1.32, 0.10            -- the star's disc and spokes (just over the balls)
Wh.PIN_RP, Wh.PIN_R, Wh.PIN_Y1 = 2.0, 0.15, 1.82  -- its pins: their circle, radius, top
Wh.PIN_A0 = 22.5                              -- the pins' angles, clockwise from the top: this + 90 k
do
  local pcs = {}
  local function circ(x, z, r, n)
    local pc = {}
    for j = 0, n - 1 do local a = 2 * math.pi * j / n; pc[#pc + 1] = { x + r * math.cos(a), z + r * math.sin(a) } end
    return pc
  end
  pcs[#pcs + 1] = { circ(0, 0, 0.7, 12), Wh.STAR_Y0, Wh.STAR_H }
  -- (its stem, down onto the wheel's hub, where it is glued)
  pcs[#pcs + 1] = { circ(0, 0, 0.55, 12), Wh.Y0 + Wh.H, Wh.STAR_Y0 - (Wh.Y0 + Wh.H) }
  Wh.pins = {}
  for k = 0, 3 do
    local a = math.rad(Wh.PIN_A0 + 90 * k)
    local px, pz = Wh.PIN_RP * math.sin(a), -Wh.PIN_RP * math.cos(a)
    local ux, uz = math.sin(a), -math.cos(a)
    local nx, nz = -uz, ux
    local w = 0.12
    pcs[#pcs + 1] = { { { 0.5 * ux - w * nx, 0.5 * uz - w * nz }, { px - w * nx, pz - w * nz },
                        { px + w * nx, pz + w * nz }, { 0.5 * ux + w * nx, 0.5 * uz + w * nz } }, Wh.STAR_Y0, Wh.STAR_H }
    pcs[#pcs + 1] = { circ(px, pz, Wh.PIN_R, 10), Wh.STAR_Y0, Wh.PIN_Y1 - Wh.STAR_Y0 }
    Wh.pins[k + 1] = { px, pz }
  end
  Wh.starPieces = pcs
  local m, I = 0, 0
  for _, p in ipairs(pcs) do
    local pm, px, pz, pI = G.massOf({ p[1] }, p[3], nil, 0.02)
    m = m + pm; I = I + pI + pm * (px * px + pz * pz)
  end
  Wh.starMass, Wh.starI = m, I
end
local A = {}
G.ANCHOR = A
A.FW = 0.3                    -- its fingers' width
A.Y0, A.Y1 = 1.46, 1.86       -- the fingers' height: the pins'
A.ARM_Y0, A.ARM_Y1 = 1.92, 2.22   -- the hub and arm, over the star
A.ARM = 6.0                   -- the arm's length, up the slope from the anchor's pin
A.LEAN = 8                    -- degrees: at rest it is turned this far one way, tripped the other
A.HOOK = 1.9                  -- AUTO: the thread from the trip lever hooks into the START lever this far
                              -- from the anchor's pin; pulled to the right, across, it trips the anchor
                              -- (as the hand does, pushing the lever's end)
A.CW_X = -2.6                 -- its counterweight (a 1/2 inch steel ball, as the machine's), on an arm
                              -- this far across, toward the wheel: it turns the anchor back to rest
do
  local b = math.rad(67.5)                    -- (half the angle between the two pins it stops)
  local d = Wh.PIN_RP / math.cos(b)
  A.d = d
  A.x, A.z = Wh.x + d, Wh.z                   -- its pin: to the wheel's right
  -- (in its own frame: its pin at 0, 0, x right, z down the slope, turned
  -- neither way)
  -- (each finger lies along its line when the anchor is turned to where
  -- that finger stops a pin: the first at rest (REST), the second tripped
  -- (TRIP); so in its own frame each is turned back by that much)
  local function rot(px, pz, phi) return px * math.cos(phi) + pz * math.sin(phi), -px * math.sin(phi) + pz * math.cos(phi) end
  local finger0
  local function finger(ang, engaged, far)
    local pts, c, e = finger0(ang, far)
    for i, p in ipairs(pts) do pts[i] = { rot(p[1], p[2], -engaged) } end
    if e then e = { rot(e[1], e[2], -engaged) } end
    return pts, c, e
  end
  finger0 = function(ang, far)
    local a = math.rad(ang)
    local cx, cz = -d + Wh.PIN_RP * math.sin(a), -Wh.PIN_RP * math.cos(a)   -- (where it stops a pin)
    local l = math.sqrt(cx * cx + cz * cz)
    local ux, uz = cx / l, cz / l
    local nx, nz = -uz, ux
    local t = l - Wh.PIN_R - 0.01
    local h = A.FW / 2
    if far then
      -- (beyond the stop point, along the same line: for a pin moving away
      -- from the anchor's pin; a bar over the pins carries it)
      local t0, t1 = l + Wh.PIN_R + 0.01, l + Wh.PIN_R + 0.9
      return { { t0 * ux - h * nx, t0 * uz - h * nz }, { t1 * ux - h * nx, t1 * uz - h * nz },
               { t1 * ux + h * nx, t1 * uz + h * nz }, { t0 * ux + h * nx, t0 * uz + h * nz } }, { cx, cz }, { t1 * ux, t1 * uz }
    end
    return { { 0.2 * ux - h * nx, 0.2 * uz - h * nz }, { t * ux - h * nx, t * uz - h * nz },
             { t * ux + h * nx, t * uz + h * nz }, { 0.2 * ux + h * nx, 0.2 * uz + h * nz } }, { cx, cz }
  end
  local L = math.rad(A.LEAN)
  A.REST, A.TRIP = L, -L
  local f1, c1 = finger(Wh.PIN_A0, A.REST)   -- (the first: at rest it stops the pin at 157.5 degrees)
  local f2, c2, e2 = finger(Wh.PIN_A0 + 135, A.TRIP, true)   -- (the second, tripped: the next, at 22.5)
  A.stops = { c1, c2 }
  local hub = {}
  for j = 0, 11 do local a = 2 * math.pi * j / 12; hub[#hub + 1] = { 0.4 * math.cos(a), 0.4 * math.sin(a) } end
  local w = 0.15
  local el = math.sqrt(e2[1] ^ 2 + e2[2] ^ 2)
  local bx, bz = -e2[2] / el * 0.15, e2[1] / el * 0.15
  local bar = { { bx, bz }, { e2[1] + bx, e2[2] + bz }, { e2[1] - bx, e2[2] - bz }, { -bx, -bz } }
  A.pieces = {
    { f1, A.Y0, A.ARM_Y1 - A.Y0 }, { f2, A.Y0, A.ARM_Y1 - A.Y0 }, { bar, A.ARM_Y0, A.ARM_Y1 - A.ARM_Y0 },
    { hub, A.Y0, A.ARM_Y1 - A.Y0 },
    { { { -w, -A.ARM }, { w, -A.ARM }, { w, 0 }, { -w, 0 } }, A.ARM_Y0, A.ARM_Y1 - A.ARM_Y0 },
    -- (the counterweight's arm, on past the ball to the push rod's pin, AUTO)
    { { { A.CW_X - 0.2, -w }, { 0, -w }, { 0, w }, { A.CW_X - 0.2, w } }, A.ARM_Y0, A.ARM_Y1 - A.ARM_Y0 },
  }
  local m, sx, sz, I = 0, 0, 0, 0
  for _, p in ipairs(A.pieces) do
    local pm, px, pz, pI = G.massOf({ p[1] }, p[3], nil, 0.01)
    m = m + pm; sx = sx + pm * px; sz = sz + pm * pz; I = I + pI + pm * (px * px + pz * pz)
  end
  -- (and the counterweight, on top of the arm's left end)
  m = m + G.BALL_MASS; sx = sx + G.BALL_MASS * A.CW_X; I = I + G.BALL_MASS * A.CW_X ^ 2
  A.mass, A.cx, A.cz = m, sx / m, sz / m
  A.I = I - m * (A.cx ^ 2 + A.cz ^ 2)
  A.CW_Y = A.ARM_Y1 + G.R
  -- its stops: two posts either side of the arm's end, standing on the
  -- plate up past the arm, where the arm is at rest and tripped
  A.POST_R = 0.25
  A.posts = {}
  local ex, ez = 0, -A.ARM + 0.4
  for _, sgn in ipairs({ -1, 1 }) do
    local a = L * -sgn
    -- (across, (half the arm + the post) / cos: square to the leaning arm
    -- that is the two together, and 0.1 mm more, so they only touch)
    A.posts[#A.posts + 1] = { A.x + ex * math.cos(a) + ez * math.sin(a) + sgn * ((0.15 + A.POST_R) / math.cos(a) + 0.01),
                              A.z - ex * math.sin(a) + ez * math.cos(a), A.POST_R, A.ARM_Y1 + 0.2 }
  end
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
-- a hole beside a flip-flop (side -1 left, 1 right) that the ball leaving
-- that side drops through, a wall beyond it and below it
local function sideHole(t, side, role)
  local hx, hz = t.x + side * G.DONE[1], t.z + G.DONE[2]
  hole(hx, hz, role)
  wall(hx + side * (HS / 2 + 0.15), hz - HS / 2 - 0.6, hx + side * (HS / 2 + 0.15), hz + HS / 2 + 0.15, role)
  wall(hx - side * HS / 2, hz + HS / 2 + 0.15, hx + side * (HS / 2 + 0.15), hz + HS / 2 + 0.15, role)
  return { hx, hz }
end
-- a funnel, its throat at (x, zt); join (-1 or 1, or 2 for both): that
-- side's wall long, for a lane coming in (see joinEnd)
local function funnel(x, zt, join, role)
  for _, s in ipairs({ -1, 1 }) do
    if join == s or join == 2 then wall(x + s * C, zt, x + s * G.JOIN[1], zt - G.JOIN[2], role)
    else wall(x + s * C, zt, x + s * G.FUNNEL[1], zt - G.FUNNEL[2], role) end
  end
end
-- a lane's walls from its centre line P { {x, z}, ... }, mitred at the bends;
-- gaps { side (-1 left, 1 right), z0, z1 } leave a wall open over that
-- stretch of z (on a straight run down the slope)
local function laneWalls(P, gaps, add, role)
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
      for _, pc in ipairs(pieces) do add(pc[1][1], pc[1][2], pc[2][1], pc[2][2], role) end
    end
  end
end
-- a lane on the upper level, from a to b: on straight down a0 from a, then
-- across (through the points via), and straight down the last b0 into b
G.lanes = {}
local function lane(name, a, b, a0, b0, via, role)
  local P = { a }
  local function add(p)
    local q = P[#P]
    if math.abs(p[1] - q[1]) > 1e-6 or math.abs(p[2] - q[2]) > 1e-6 then P[#P + 1] = p end
  end
  if a0 > 0 then add({ a[1], a[2] + a0 }) end
  for _, p in ipairs(via or {}) do add(p) end
  if b0 > 0 then add({ b[1], b[2] - b0 }) end
  add(b)
  for i = 1, #P - 1 do
    local dx, dz = P[i + 1][1] - P[i][1], P[i + 1][2] - P[i][2]
    local deg = math.deg(math.atan2(dz, math.abs(dx)))
    if deg < G.MINSLOPE - 1e-6 then
      G.warnings[#G.warnings + 1] = string.format("lane %s: its leg %d runs %.1f degrees down (under %d)", name, i, deg, G.MINSLOPE)
    end
  end
  laneWalls(P, {}, wall, role or "lane")
  G.lanes[name] = P
  return P
end

-- the switches' walls; a switch's drop side (s.drop: -1, 1) ends at once in
-- a hole, close under the flap
local function switchWalls(sw)
  local x, z = sw.x, sw.z
  local half = S.IW / 2
  local CI = half + G.WALL_T / 2
  local OC = G.CHAN / 2 + G.WALL_T / 2
  local top = z - S.FL - S.DROP
  wall(x - CI, top, x - CI, z - S.FL + 0.2, "switch"); wall(x + CI, top, x + CI, z - S.FL + 0.2, "switch")
  for _, s in ipairs({ -1, 1 }) do
    local ox = x + s * S.OX
    wall(x + s * CI, z - S.FL + 0.2, ox + s * OC, z + 0.6, "switch")
    wall(x, z + 0.55, ox - s * OC, z + 1.8, "switch")
    if sw.drop == s then
      -- (the hole just under the outlet's mouth; its inner wall begins where
      -- the divider's slope ends, so nothing stands in the ball's way)
      local hz = z + 0.6 + HS / 2 + 0.05
      hole(ox, hz, "drop")
      wall(ox + s * OC, z + 0.6, ox + s * OC, z + 0.6 + HS + 0.2, "drop")
      wall(ox - s * OC, z + 1.8, ox - s * OC, z + 0.6 + HS + 0.2, "drop")
      wall(ox - OC, z + 0.6 + HS + 0.25, ox + OC, z + 0.6 + HS + 0.25, "drop")
      sw.dropHole = { ox, hz }
    else
      wall(ox + s * OC, z + 0.6, ox + s * OC, z + S.OUT, "switch")
      wall(ox - s * OC, z + 1.8, ox - s * OC, z + S.OUT, "switch")
    end
  end
  sw.top = top
  sw.left, sw.right = { x - S.OX, z + S.OUT }, { x + S.OX, z + S.OUT }
end
for k = 1, 4 do G.switches["M" .. k].drop = -1 end
for _, s in ipairs(G.switchList) do switchWalls(s) end
-- CLEAR's right outlet: into the clear lane; COUNT's right: to the collector
do
  local r = G.switches.CLEAR.right
  G.clearDrop = { dropAt(r[1], r[2], "clear") }
  r = G.switches.COUNT.right
  G.countOffDrop = { dropAt(r[1], r[2], "drop") }
end

-- each flip-flop: its run and funnel, stop pegs, the boss on the lower
-- board its foot stands on, the square hole its stem comes up through
local function flipWalls(t, join, role)
  local x, z = t.x, t.z
  local rb = z - F.A - 1.4 - G.R
  local rt = rb - F.RUN
  wall(x - C, rt, x - C, rb, role); wall(x + C, rt, x + C, rb, role)
  funnel(x, rt, join, role)
  G.pegs[#G.pegs + 1] = { x - F.pegX, z + F.pegZ, F.PEG_R }
  G.pegs[#G.pegs + 1] = { x + F.pegX, z + F.pegZ, F.PEG_R }
  G.bosses[#G.bosses + 1] = { x, z }
  hole(x, z, "stem", 2 * (F.STEM_R + 0.05))
end
-- where a ball leaving a flip-flop on side s is caught by a funnel: the
-- funnel's throat (where the next flip-flop's would be)
local function catchAt(t, s) return { t.x + s * G.DX, t.z + G.DZ - RUNTOP } end

-- the accumulator: every funnel has both walls long. A1 .. A4's take the
-- memory's lanes from the left; every one takes a lane from the right (A1's
-- from COUNT, the others' the done lane from the one before). (A5 .. A7's
-- left walls are long for the carry: falling the length of a step, it drifts
-- left, and a short wall let it by)
for k, t in ipairs(G.toggles) do flipWalls(t, 2) end
-- (and A5 .. A7's long left walls go on straight up the slope, to above
-- the flip-flop before: a guide for the carry, which drifts out to the very
-- end of that wall (at 1200 steps a second, or tilted 2 degrees across,
-- past it). A2 .. A4's have the memory's lanes there instead)
for k = 5, G.NBITS do
  local t, u = G.toggles[k], G.toggles[k - 1]
  local x = t.x - G.JOIN[1]
  wall(x, runTop(t) - G.JOIN[2], x, u.z - 2.0, "guide")
end
-- OVERFLOW: the carry out of A7 comes to the overflow hole, and the
-- OVERFLOW switch is a shutter over it, sliding up and down the slope in a
-- groove, its knob up the slope and to the left, out of every ball's way.
-- RUN (closed, the knob down the slope): the ball rolls over it, down a
-- lane to the plate's end, off it onto the lower level, and on to the
-- collector and the trip lever, as every ball does. HALT (open, the knob
-- pushed up the slope): the ball drops through into a pocket on the lower
-- level, and reaches no trip lever: in AUTO the machine stops, as at STOP.
do
  local t = G.toggles[G.NBITS]
  local hx, hz = t.x - G.DONE[1], t.z + G.DONE[2]
  hole(hx, hz, "overflow")
  G.overflow = { hx, hz }
  local O, m = {}, 0.1
  G.OVF = O
  O.T = 0.2                                     -- (its thickness, its groove's depth: as COMPLEMENT's)
  O.TRAVEL = HS + 2 * m + 0.1                   -- (open: this far up the slope)
  local x0, x1 = hx - HS / 2 - m, hx + HS / 2 + 0.1
  local zt = hz - HS / 2 - 1.6                  -- (its top edge, closed: up the slope past the hole)
  O.knob = { hx - HS / 2 - 1.7, zt + 0.3 }
  O.KNOB_R, O.KNOB_H = 0.4, 1.8                 -- (over the walls)
  O.pieces = { { { x0, zt }, { x1, zt }, { x1, hz + HS / 2 + m }, { x0, hz + HS / 2 + m } },
               { { O.knob[1] - 0.5, zt }, { x0, zt }, { x0, zt + 0.6 }, { O.knob[1] - 0.5, zt + 0.6 } } }
end
-- COMPLEMENT: A1 .. A6's done holes are long (DONE_L) and open below, onto a
-- lane, the DONE LANE, that runs down and across into the next flip-flop's
-- funnel (on its long right wall). Open, the hole takes the ball, as any
-- done hole. Closed by its SHUTTER, the ball rolls over it and down the lane
-- into the next flip-flop, so every ball goes on through every flip-flop
-- below where it came in, turning each over, whichever way it finds it.
-- A7's done hole is square and walled below, as before.
-- Each shutter is a thin tile sliding flush in a groove in the plate,
-- across the slope: to the left, it covers the hole; to the right, it lies
-- under the lane's right wall and beyond it, out of the lane (so the groove
-- it leaves is never in a ball's way). A pin stands up from its right end,
-- outside the lane. One bar, high over the walls (a ball passes under it),
-- joins the six pins: the COMPLEMENT switch. Its handle is at its top end,
-- beside A1: to the left, every hole is covered (COMPLEMENT on); to the
-- right, every one is open.
local SH = {}
G.SHUTTER = SH
SH.T = 0.2                    -- the shutter's thickness (its groove's depth)
SH.M = 0.1                    -- it reaches this far past the hole all round
SH.TRAVEL = G.DONE_W + 2 * SH.M   -- how far it slides: open, it is this far to the right
SH.EXT = 1.6                  -- closed, it reaches this far right of the hole's centre
SH.PIN = { 1.35, 0.15 }       -- the pin: this far right of the hole's centre (closed), its radius
SH.BAR_Y0, SH.BAR_H, SH.BAR_W = 1.6, 0.3, 0.5   -- the bar: over the walls (1.2) and the balls (1.27)
SH.HANDLE = 3.0               -- the bar runs on this far up the slope past A1's pin, to the handle
SH.KNOB_R, SH.KNOB_H = 0.5, 1.2                 -- the handle: a knob standing on the bar's end
G.shutters = {}
for k, t in ipairs(G.toggles) do
  if k < G.NBITS then
    local hx, hz0 = t.x + G.DONE[1], t.z + G.DONE[2] - HS / 2
    local hz1 = hz0 + G.DONE_L
    local hx0 = hx + HS / 2 - G.DONE_W
    G.holes[#G.holes + 1] = { hx0, hx + HS / 2, hz0, hz1, role = "done" }
    t.done = { hx, (hz0 + hz1) / 2 }
    local m = SH.M
    G.shutters[k] = { x = hx, z0 = hz0, z1 = hz1,
      hole = { hx0, hx + HS / 2, hz0, hz1 },
      -- (closed; open, each is TRAVEL farther to the right)
      pieces = { { { hx0 - m, hz0 - m }, { hx + SH.EXT, hz0 - m }, { hx + SH.EXT, hz1 + m }, { hx0 - m, hz1 + m } } },
      pin = { hx + SH.PIN[1], (hz0 + hz1) / 2 } }
    local n = G.toggles[k + 1]
    local e = joinEnd(n.x, runTop(n), 1)
    local P = { { hx, hz0 - 0.6 }, { hx, hz1 + G.DONE_LANE[1] }, { e[1], e[2] - G.DONE_LANE[2] }, e }
    -- (its left wall open beside the hole and above it, where the ball comes in)
    laneWalls(P, { { -1, hz0 - 0.6, hz1 + 0.15 } }, wall, "doneLane")
    G.lanes["done " .. k] = P
    local dx, dz = P[2][1] - P[3][1], P[3][2] - P[2][2]
    if math.deg(math.atan2(dz, dx)) < G.MINSLOPE - 1e-6 then
      G.warnings[#G.warnings + 1] = string.format("done lane %d runs %.1f degrees down (under %d)", k, math.deg(math.atan2(dz, dx)), G.MINSLOPE)
    end
  else
    t.done = sideHole(t, 1, "done")
  end
end
-- the bar (closed: COMPLEMENT on), along the pins, on up to the handle
do
  local p1, p6 = G.shutters[1].pin, G.shutters[G.NBITS - 1].pin
  local dx, dz = p6[1] - p1[1], p6[2] - p1[2]
  local l = math.sqrt(dx * dx + dz * dz)
  local ux, uz = dx / l, dz / l
  local nx, nz = -uz, ux
  local a = { p1[1] - ux * SH.HANDLE, p1[2] - uz * SH.HANDLE }
  local b = { p6[1] + ux * 0.4, p6[2] + uz * 0.4 }
  local w = SH.BAR_W / 2
  SH.bar = { { a[1] - w * nx, a[2] - w * nz }, { b[1] - w * nx, b[2] - w * nz },
             { b[1] + w * nx, b[2] + w * nz }, { a[1] + w * nx, a[2] + w * nz } }
  SH.knob = { a[1] + ux * SH.KNOB_R, a[2] + uz * SH.KNOB_R }
end

-- the distributor and the MQ
do
  local R = G.rocker
  for _, t in ipairs(G.routers) do flipWalls(t, nil, "router") end
  local M = G.switches
  local function inlet(s) return { s.x, inletTop(s) } end
  -- MULTIPLY's right outlet (off) runs down to CLEAR
  local r = M.MULTIPLY.right
  lane("MULTIPLY off", r, inlet(M.CLEAR), 0.5, 1.2, { { r[1] + 0.8, r[2] + 1.2 } })
  -- D1's right outlet runs to D3 (its left drops straight into D2's funnel)
  local c = catchAt(R.D1, 1)
  funnel(c[1], c[2], nil, "router")
  lane("D1 to D3", c, { R.D3.x, mouthZ(R.D3) - 0.1 }, 0.5, 0.6)
  -- D2's left drops into MQ1; its right, D3's two run to the memory
  -- (a lane into M2, M3 or M4 keeps left of the switch above's drop hole
  -- until it is past it)
  local function past(s) return s.dropHole[2] + HS / 2 + 0.35 + 0.6 end
  c = catchAt(R.D2, 1); funnel(c[1], c[2], nil, "router")
  lane("D2 to M3", c, inlet(M.M3), 0, 0.6, { { c[1], past(M.M2) } })
  c = catchAt(R.D3, -1); funnel(c[1], c[2], nil, "router")
  lane("D3 to M2", c, inlet(M.M2), 0, 1.0, { { c[1], past(M.M1) } })
  c = catchAt(R.D3, 1); funnel(c[1], c[2], nil, "router")
  lane("D3 to M1", c, inlet(M.M1), 0.5, 1.0)
  -- the MQ's done sides: each one's funnel takes the lane from the last, and
  -- the last runs to M4; a borrow out of MQ3 drops through STOP
  local prev
  for k = 1, 3 do
    local t = R["MQ" .. k]
    c = catchAt(t, 1)
    funnel(c[1], c[2], k > 1 and 1 or nil, "router")
    if prev then lane("MQ" .. (k - 1) .. " on", prev, joinEnd(c[1], c[2], 1), 0.5, 0.5) end
    prev = c
  end
  lane("MQ to M4", prev, inlet(M.M4), 0.5, 1.0)
  G.stop = sideHole(R.MQ3, -1, "stop")
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
G.ZCOL = G.toggles[G.NBITS].z + 6.0         -- the collector's wall, on the lower level
G.COL_H = 3.0                                -- its height
do
  local d = G.clearDrop
  local t1 = G.toggles[1]
  -- (from CLEAR's drop it bends left at once, past the lane's line, to pass
  -- left of where COUNT's off balls land; then it comes back a little to
  -- the right, so the ball meets A1's foot running along the right wall, as
  -- at every other foot: coming straight, it was pushed past the narrowing
  -- into the wedge, and with the pins' friction at 0.1 dragged A1 over)
  local P = { { d[1], d[2] - HS / 2 - 0.6 }, { d[1], d[2] + 0.6 },
              { t1.x + G.XC - 0.85, G.countOffDrop[2] - HS / 2 - 0.9 } }
  local gaps = {}
  for k, t in ipairs(G.toggles) do
    local x, zf = t.x + G.XC, t.z - F.LF
    P[#P + 1] = { x, zf - 1.6 }
    -- (past the foot: the left wall open from 1.6 above the wedge to 2.3
    -- below, past the narrowing (the right wall there, below); under the
    -- done hole, the right wall open)
    gaps[#gaps + 1] = { -1, zf - 1.6, zf + 2.3 }
    local zd = t.z + 2.2 + (k < G.NBITS and G.DONE_L - HS or 0)    -- (past the done hole)
    gaps[#gaps + 1] = { 1, zf - 1.0, zd }
    for _, w in ipairs(G.footWalls(t)) do lwall(w[1], w[2], w[3], w[4], "clear") end
    if k < G.NBITS then P[#P + 1] = { x, zd } end
  end
  local last = G.toggles[G.NBITS]
  P[#P + 1] = { last.x + G.XC, G.ZCOL - 3.5 }        -- (it ends well short of the collector's wall,
                                                     -- so balls can roll along the wall past it)
  laneWalls(P, gaps, lwall, "clear")
  lwall(d[1] - C, P[1][2], d[1] + C, P[1][2], "clear")             -- (its top)
  G.clearLane = P
end

-- the board's edges
do
  local x0, x1, z0, z1 = 1e9, -1e9, 1e9, -1e9
  local function see(x, z) x0 = math.min(x0, x); x1 = math.max(x1, x); z0 = math.min(z0, z); z1 = math.max(z1, z) end
  for _, w in ipairs(G.walls) do see(w[1], w[2]); see(w[3], w[4]) end
  for _, h in ipairs(G.holes) do see(h[1], h[3]); see(h[2], h[4]) end
  see(Wh.x - Wh.R - 1, Wh.z)
  -- the return lane down the left edge of the lower level (below): its
  -- centre under STOP
  G.XRET = G.stop[1]
  see(G.XRET - C - 1.4 + 1.5, z0)
  -- the queue's channel and the wheel's housing (below) are inside these
  local M = 1.5
  G.board = { x0 = x0 - M, x1 = x1 + M, z0 = Wh.z - Wh.R - Wh.QUEUE - 1.5, z1 = z1 + M }
  G.lower = { x0 = G.board.x0, x1 = G.board.x1, z0 = G.board.z0, z1 = G.ZCOL + 9.5 }
end

-- the lower level's left side: what drops through the memory's holes rolls
-- down a wall to the left, into the return lane down the board's left edge,
-- and on down to the collector (STOP drops straight into it)
do
  local t = math.tan(math.rad(40))
  local xr = G.XRET + C                       -- (the walls end at the return lane's right side)
  G.returns = {}
  for k = 1, 4 do
    local h = G.switches["M" .. k].dropHole
    local x1 = h[1] + HS / 2 + 0.15
    local z1 = h[2] + HS / 2 + 0.3
    lwall(x1, z1, xr, z1 + (x1 - xr) * t, "return")
    G.returns[k] = { x1, z1, xr, z1 + (x1 - xr) * t }
  end
  lwall(G.XRET - C, G.stop[2] - HS / 2 - 0.3, G.XRET - C, G.ZCOL - 1.5, "return")
  -- (AUTO: STOP's ball stays in a pocket under its hole, and lets no
  -- ball go: the machine stops. The hand empties it)
  local zb = G.stop[2] + HS / 2 + 0.7
  lwall(G.XRET + C, G.stop[2] - HS / 2 - 0.3, G.XRET + C, zb, "stop")
  lwall(G.XRET - C, zb, G.XRET + C, zb, "stop")
  G.stopPocket = { G.XRET, G.stop[2] }
  -- (and OVERFLOW's, under its hole: its ball stays there when it is set
  -- to HALT)
  do
    local hx, hz = G.overflow[1], G.overflow[2]
    local w = HS / 2 + 0.15
    lwall(hx - w, hz - HS / 2 - 0.3, hx - w, hz + HS / 2 + 0.85, "overflow")
    lwall(hx + w, hz - HS / 2 - 0.3, hx + w, hz + HS / 2 + 0.85, "overflow")
    lwall(hx - w, hz + HS / 2 + 0.85, hx + w, hz + HS / 2 + 0.85, "overflow")
    G.overflowPocket = { hx, hz }
    -- (on the plate: the hole's outer wall, on down to the plate's end: the
    -- lane a ball takes over the closed shutter, RUN)
    wall(hx - w, hz - HS / 2 - 0.6, hx - w, G.board.z1 - 0.05, "overflow")
  end
end

-- the feeder's housing (a ring of short walls, open at the top to the
-- channel of balls and at the bottom to the MULTIPLY switch) and the channel
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
  local it = G.switches.MULTIPLY.top
  if it > bot + 0.01 then
    wall(Wh.x - C, bot, Wh.x - C, it); wall(Wh.x + C, bot, Wh.x + C, it)
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
  -- (AUTO: the collector's wall stops short of the right side: every ball
  -- turns down the trip channel there, under the trip lever, and on to the
  -- store, a second wall below, sloping down to the left, where the balls
  -- wait for the hand)
  local T = {}
  G.TRIP = T
  T.xc = l.x1 - 0.3 - G.CHAN / 2 - 0.05          -- the channel's centre (its right side the rim)
  T.xe = T.xc - C                                 -- where the collector's wall ends: on the channel's left
                                                  -- wall, which leaves a ball's width (and 2 mm) to the rim
  T.ze = G.ZCOL - 1.0 + 2.0 * (T.xe - l.x0) / (l.x1 - l.x0)
  T.ZB = G.ZCOL + 7.0                             -- the store's wall, at the right
  lwall(l.x0, G.ZCOL - 1.0, T.xe, T.ze, "collector", G.COL_H)
  lwall(T.xc - C, T.ze - 0.2, T.xc - C, T.ZB - 2.0, "collector", G.COL_H)
  lwall(l.x1, T.ZB, l.x0, T.ZB + 1.5, "collector", G.COL_H)
  G.collector = { x0 = l.x0 + 0.3, x1 = l.x1 - 0.3, z = T.ZB }
  -- the trip lever: a short arm on an axle across the channel, trailing
  -- down the slope from it, its end resting just above a ball's middle. A
  -- ball rolls under the axle, then under the arm, and lifts it (by 4.5 mm,
  -- at most: the ball's own size sets it).
  -- (An arm reaching up the slope was tried first: a ball meets the end of
  -- such an arm below the line to its axle, and only jams it down.)
  T.zp = G.ZCOL + 3.2                             -- the axle
  T.A = 1.2                                       -- the arm, down the slope from it
  T.yA = G.YL + 2 * G.R + 0.35                    -- the axle's height (clear over a ball)
  T.yEnd = G.YL + 0.82                            -- the arm's end, underneath: over a ball's middle
  T.W = 1.0                                       -- its width across the channel

  T.mass = 0.0006
  T.AXLE_R = 0.1                                  -- its axle: a 2 mm steel wire, through the
                                                  -- channel's wall and the rim
  -- (its pieces, each a hull of corners, in its own frame: the axle at 0,
  -- across the channel along x, y up off the board, z down the slope)
  local W, yE = T.W / 2, T.yEnd - T.yA
  local arm, arm2, hub = {}, {}, {}
  for _, x in ipairs({ -W, W }) do
    -- (its underside high, clear of the balls, out to 0.6 cm, then down to
    -- the end: a ball meets it far from the axle, where it lifts it easily;
    -- a straight underside met the balls 3 mm from the axle, and now and
    -- then a ball stopped there: FINDINGS)
    -- (two hulls: one hull of all would be straight underneath again)
    arm[#arm + 1] = { x, yE, T.A }; arm[#arm + 1] = { x, yE + 0.3, T.A }
    arm[#arm + 1] = { x, -0.28, 0.6 }; arm[#arm + 1] = { x, 0.15, 0.6 }
    arm2[#arm2 + 1] = { x, -0.28, 0.6 }; arm2[#arm2 + 1] = { x, 0.15, 0.6 }
    arm2[#arm2 + 1] = { x, -0.15, -0.1 }; arm2[#arm2 + 1] = { x, 0.15, -0.1 }
    for _, y in ipairs({ -0.2, 0.2 }) do for _, z in ipairs({ -0.2, 0.2 }) do hub[#hub + 1] = { x, y, z } end end
  end
  -- the thread (AUTO) pulls; it can't push. So it is tied to an arm that
  -- hangs down from the axle, glued on the axle's end where it comes out
  -- through the rim, beside the board: lifting the lever swings that arm's
  -- end down the slope. From there the thread runs straight up the slope
  -- beside the board's right edge, outside everything, to an eye on a post
  -- at the edge level with the START lever, turns there, and runs across
  -- the board to the START lever, which it pulls to the right, as the hand
  -- does: the anchor trips. Its counterweight pulls everything back.
  local DA = { L = 1.4, W = 0.2 }                  -- (its end 1 mm over the lower board's face)
  DA.x = (l.x1 + 0.3 + DA.W) - T.xc               -- (beside the board, past the rim)
  local darm = {}
  for _, x in ipairs({ DA.x - DA.W, DA.x + DA.W }) do
    for _, y in ipairs({ 0.15, -DA.L - 0.1 }) do for _, z in ipairs({ -0.15, 0.15 }) do darm[#darm + 1] = { x, y, z } end end
  end
  T.DA, T.downArm = DA, darm
  T.hulls = { arm, arm2, hub }
  -- (the eye: on a post at the board's right edge, level with the hook in
  -- the START lever, at the anchor's arm's height)
  local A = G.ANCHOR
  local hy = (A.ARM_Y0 + A.ARM_Y1) / 2
  T.hook = { x = A.x - math.sin(A.REST) * A.HOOK, y = hy, z = A.z - math.cos(A.REST) * A.HOOK }
  T.EYE = { x = T.xc + DA.x, y = hy, z = T.hook.z, R = 0.25 }
  T.ROD_PIN_R = 0.08                              -- (the hole in the START lever the thread hooks into)
end
-- the posts holding the plate up (round its edge, out of every ball's way)
G.posts = {}
do
  local b = G.board
  for z = b.z0 + 2, b.z1 - 1, 12 do
    G.posts[#G.posts + 1] = { b.x0 + 0.6, z }; G.posts[#G.posts + 1] = { b.x1 - 0.6, z }
  end
end

-- ---------------------------------------------------------------------
-- the lettering on the plate { text, x, z, size (mm) }
-- ---------------------------------------------------------------------
G.marks = {}
do
  local function mark(t, x, z, size) G.marks[#G.marks + 1] = { t, x, z, size or 5 } end
  for k, t in ipairs(G.toggles) do
    mark("0", t.x - 1.7, t.z - 1.9, 6); mark("1", t.x + 1.7, t.z - 1.9, 6)
    mark(string.format("%d", 2 ^ (k - 1)), t.x - 3.1, t.z - 4.6, 7)
  end
  for _, t in ipairs(G.routers) do
    -- (the MQ reads the other way: 1 with its apex left)
    local l, r = "0", "1"
    if t.kind == "MQ" then l, r = "1", "0" end
    mark(l, t.x - 1.7, t.z - 1.9, 6); mark(r, t.x + 1.7, t.z - 1.9, 6)
    mark(t.name, t.x - 3.3, t.z - 4.0, 5)
  end
  local function swMark(name, dx, dz, on, off)
    local s = G.switches[name]
    mark(name, s.x + dx, s.z + dz, 5)
    local onX, offX = s.x + s.on * S.OX, s.x - s.on * S.OX
    mark(on, onX + s.on * 1.6, s.z + 1.6, 4); mark(off, offX - s.on * 1.6, s.z + 1.6, 4)
  end
  swMark("MULTIPLY", -4.6, -1.2, "on", "off")
  swMark("CLEAR", 3.4, -1.2, "on", "off")
  swMark("COUNT", 3.6, -1.6, "on", "off")
  for k = 1, 4 do swMark("M" .. k, -3.2, -1.6, "1", "0") end
  mark("START", Wh.x + 4.2, Wh.z, 5)
  mark("OVERFLOW", G.overflow[1] + 0.3, G.overflow[2] + 2.0, 4)
  mark("STOP", G.stop[1] + 0.3, G.stop[2] + 2.0, 4)
  -- (COMPLEMENT: its handle, up the slope (on: the holes covered) or down)
  local kx, kz = G.SHUTTER.knob[1], G.SHUTTER.knob[2]
  mark("COMPLEMENT", kx + 0.8, kz - 3.0, 4)
  mark("on", kx, kz - 1.5, 4); mark("off", kx + G.SHUTTER.TRAVEL + 0.2, kz - 1.5, 4)
end
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
  -- (the escape star on the wheel, and the anchor: pieces { outline, y0, h })
  local function piece(pc) return "[" .. outline(pc[1]) .. string.format(",%.5f,%.5f]", pc[2], pc[3]) end
  list("STAR_PIECES", Wh.starPieces, piece)
  local A = G.ANCHOR
  list("ANCHOR_PIECES", A.pieces, piece)
  f:write(string.format("ANCHOR_AT = [%.5f,%.5f];\nANCHOR_REST = %.5f;\nANCHOR_CW = [%.5f,%.5f];\n", A.x, A.z, math.deg(A.REST), A.CW_X, A.CW_Y))
  list("ANCHOR_POSTS", A.posts, function(p) return string.format("[%.5f,%.5f,%.5f,%.5f]", p[1], p[2], p[3], p[4]) end)
  do
    local T = G.TRIP
    local o = {}
    for _, q in ipairs(T.downArm) do o[#o + 1] = string.format("[%.5f,%.5f,%.5f]", q[1], q[2], q[3]) end
    f:write("TRIP_DOWN_ARM = [" .. table.concat(o, ",") .. "];\n")
    f:write(string.format("TRIP_DA = [%.5f,%.5f];\nTRIP_EYE = [%.5f,%.5f,%.5f,%.5f];\n", T.DA.x, T.DA.L, T.EYE.x, T.EYE.y, T.EYE.z, T.EYE.R))
  end
  f:write(string.format("ROD_PIN_R = %.5f;\nANCHOR_HOOK = %.5f;\n", G.TRIP.ROD_PIN_R, A.HOOK))
  f:write(string.format("TRIP_AXLE = [%.5f,%.5f,%.5f,%.5f,%.5f,%.5f];\n", G.TRIP.xc, G.TRIP.yA, G.TRIP.zp,
                        G.TRIP.xc - C - 0.4, G.TRIP.xc + G.TRIP.DA.x + G.TRIP.DA.W + 0.1, G.TRIP.AXLE_R))
  list("TRIP_HULLS", G.TRIP.hulls, function(h)
    local o = {}
    for _, q in ipairs(h) do o[#o + 1] = string.format("[%.5f,%.5f,%.5f]", q[1], q[2], q[3]) end
    return "[" .. table.concat(o, ",") .. "]"
  end)
  f:write(string.format("WHEEL_AT = [%.5f,%.5f];\n", Wh.x, Wh.z))
  list("TOGGLES", G.rockers, function(t) return pts2({ t.x, t.z }) end)
  -- (COMPLEMENT: the shutters closed, and their pins; the bar and its knob;
  -- open, all TRAVEL farther to the right)
  do
    local O = G.OVF
    num("OVF_T", O.T); num("OVF_TRAVEL", O.TRAVEL); num("OVF_KNOB_R", O.KNOB_R); num("OVF_KNOB_H", O.KNOB_H)
    list("OVF_PIECES", O.pieces, outline)
    f:write(string.format("OVF_KNOB = [%.5f,%.5f];\n", O.knob[1], O.knob[2]))
  end
  local SH = G.SHUTTER
  num("SH_T", SH.T); num("SH_TRAVEL", SH.TRAVEL); num("SH_PIN_R", SH.PIN[2])
  num("SH_BAR_Y0", SH.BAR_Y0); num("SH_BAR_H", SH.BAR_H); num("SH_KNOB_R", SH.KNOB_R); num("SH_KNOB_H", SH.KNOB_H)
  list("SHUTTERS", G.shutters, function(sh) return outline(sh.pieces[1]) end)
  list("SH_PINS", G.shutters, function(sh) return pts2(sh.pin) end)
  f:write("SH_BAR = " .. outline(SH.bar) .. ";\n")
  f:write(string.format("SH_KNOB = [%.5f,%.5f];\n", SH.knob[1], SH.knob[2]))
  -- (each switch: where its pin is, and which way its flap leans set up as
  -- the hand sets it: 1 against the left wall, -1 the right)
  list("SWITCHES", G.switchList, function(s) return string.format("[%.5f,%.5f,%d]", s.x, s.z, s.rest or 1) end)
  local function seg(w) return string.format("[%.5f,%.5f,%.5f,%.5f]", w[1], w[2], w[3], w[4]) end
  list("WALLS", G.walls, seg)
  list("LWALLS", G.lwalls, function(w) return string.format("[%.5f,%.5f,%.5f,%.5f,%.5f]", w[1], w[2], w[3], w[4], w[5]) end)
  list("HOLES", G.holes, seg)
  list("PEGS", G.pegs, function(p) return string.format("[%.5f,%.5f,%.5f]", p[1], p[2], p[3]) end)
  list("POSTS", G.posts, pts2)
  local b, l = G.board, G.lower
  f:write(string.format("BOARD = [%.5f,%.5f,%.5f,%.5f];\n", b.x0, b.x1, b.z0, b.z1))
  f:write(string.format("LOWER = [%.5f,%.5f,%.5f,%.5f];\n", l.x0, l.x1, l.z0, l.z1))
  list("MARKS", G.marks, function(m) return string.format("[\"%s\",%.5f,%.5f,%d]", m[1], m[2], m[3], m[4]) end)
  f:close()
end

return G
