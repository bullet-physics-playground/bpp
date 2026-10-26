-- digicomp2-geometry.lua -- Babbage's Hall, the Digi-Comp II (step 1: the counter)
--
-- Every shape of the machine in one place: the simulation builds its bodies
-- and walls from these, and make-stls.sh writes them out for OpenSCAD
-- (parts/geometry.scad), which builds the printed parts from the very same
-- numbers. So what is printed is what was simulated.
--
-- The board's own frame (cm): x across it, to the right as you face it; y
-- out of the board (up from its face); z down the slope, toward you. The
-- board's face is y = 0. Its walls stand on it, WALL_H high; the balls roll
-- on it; the flip-flops turn on pins standing out of it.
--
-- Every number here was tuned in the simulation (see FINDINGS.md).

local G = {}

G.TH = 15                     -- the board's slope, degrees
G.R, G.BALL_MASS = 0.635, 0.00835   -- 1/2 inch steel balls (12.7 mm, 8.35 g)
G.PLA = 1.24e-3               -- kg per cm^3 (printed solid)
G.WALL_H, G.WALL_T = 1.2, 0.3 -- the walls: 12 mm high, 3 mm thick
G.CHAN = 2 * G.R + 0.15       -- a channel's width inside: the ball and 1.5 mm
G.BOARD_T = 0.4               -- the printed board's thickness (on a backing sheet)
G.BACK = 0.6                  -- the backing sheet (6 mm plywood)
G.FOOT = 1.0                  -- the board's front edge stands this high on its stand

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
F.BOSS_R = 0.4                -- the boss on the board the hub rests on
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
  -- (each outline anticlockwise as the board's frame has it, for OpenSCAD)
  -- the printed part (less its pin hole and the weight's pocket), then the weight
  local pm, pcx, pcz, pI = G.massOf(P, F.H, { { 0, 0, F.PIN_R } })
  -- (less the pocket: as deep as the steel ball and 0.2 mm, from the top face)
  local km = math.pi * F.WEIGHT_R ^ 2 * (2 * F.WEIGHT_R + 0.02) * G.PLA
  local qm = pm - km
  local qcx, qcz = pm * pcx / qm, (pm * pcz - km * F.WEIGHT_Z) / qm
  pI = pI + pm * ((pcx - qcx) ^ 2 + (pcz - qcz) ^ 2) - km * (qcx ^ 2 + (F.WEIGHT_Z - qcz) ^ 2)
  pm, pcx, pcz = qm, qcx, qcz
  local wm = F.WEIGHT
  local m = pm + wm
  local cx, cz = pm * pcx / m, (pm * pcz + wm * F.WEIGHT_Z) / m
  F.printed = pm
  F.I = pI + pm * ((pcx - cx) ^ 2 + (pcz - cz) ^ 2) + wm * (cx * cx + (F.WEIGHT_Z - cz) ^ 2)
  F.mass, F.cx, F.cz = m, cx, cz
  -- the stop pegs: the tail (width W) rests on one at a lean of ALPHA
  local a = math.rad(F.ALPHA)
  F.pegZ = F.T - 0.25
  F.pegX = (F.PEG_R + F.W / 2 + F.pegZ * math.sin(a)) / math.cos(a)
end

-- ---------------------------------------------------------------------
-- the counter: three flip-flops down a staircase, each the next bit
-- ---------------------------------------------------------------------
-- A ball that finds a flip-flop at 0 sets it to 1 and goes right, into
-- that flip-flop's bin: done. One that finds it at 1 sets it to 0 and goes
-- left, down to the next flip-flop: the carry. So the flip-flops count the
-- balls in binary. The fourth path, out of the last flip-flop's carry, is
-- the overflow (the eighth ball).
G.NBITS = 3
G.DX, G.DZ = 3.5, 8.0         -- each flip-flop this far left and down from the last
G.LANE_X = 2.8                -- a done lane's centre, right of its flip-flop's pivot
G.LANE_Z = 1.2                -- where its walls begin, below the pivot
G.BIN_Z = 24.0                -- the bins' floor (a wall across the lanes)
G.FUNNEL = { 2.0, 1.4 }       -- a funnel's half-width at its mouth, and its depth

G.toggles = {}
for k = 0, G.NBITS - 1 do G.toggles[k + 1] = { x = -k * G.DX, z = k * G.DZ } end

-- the feeder: a wheel with four notches, at the foot of a channel of balls.
-- Each quarter turn of its knob (by hand) carries one ball round from the
-- top and lets it out at the bottom, into the first flip-flop's run.
local Wh = {}
G.WHEEL = Wh
Wh.R = 2.05                   -- its radius
Wh.NOTCH_W = 2 * G.R + 0.1    -- a notch's width
Wh.HUB = Wh.NOTCH_W / 2 + 0.05  -- the hub, a square this far each way: a little wider than the
                              -- notches, so the teeth join it (one solid part)
Wh.NOTCH_D = Wh.R - Wh.HUB    -- a notch's depth from the rim (a ball sits wholly inside it)
Wh.Y0, Wh.H = 0.15, 0.9       -- (as the flip-flops)
Wh.GAP = 0.06                 -- between its rim and the housing
Wh.QUEUE = 10.0               -- the channel of balls above it
do
  local f = G.toggles[1]
  local runTop = f.z - F.A - 1.4 - G.R - F.RUN    -- (the top of the first flip-flop's run)
  Wh.x = f.x
  Wh.z = runTop - (Wh.R + Wh.GAP + G.WALL_T)
  Wh.ballR = Wh.R - Wh.NOTCH_D + G.R              -- a ball's centre in a notch, from the wheel's
  -- its pieces (convex, in its frame: x, z): the hub and four teeth
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
-- the fixed walls and pegs: { x1, z1, x2, z2 } centre lines, WALL_T thick
-- ---------------------------------------------------------------------
G.walls, G.pegs, G.bosses = {}, {}, {}
local function wall(x1, z1, x2, z2, role) G.walls[#G.walls + 1] = { x1, z1, x2, z2, role = role } end
local C = G.CHAN / 2 + G.WALL_T / 2          -- a channel's wall, from its centre line
for k, t in ipairs(G.toggles) do
  local x, z = t.x, t.z
  local runBot = z - F.A - 1.4 - G.R
  local runTop = runBot - F.RUN
  -- the run down to the apex
  wall(x - C, runTop, x - C, runBot); wall(x + C, runTop, x + C, runBot)
  -- the funnel above it (the first is fed by the feeder instead)
  if k > 1 then
    wall(x - C, runTop, x - G.FUNNEL[1], runTop - G.FUNNEL[2])
    wall(x + C, runTop, x + G.FUNNEL[1], runTop - G.FUNNEL[2])
  end
  -- the stop pegs and the boss
  G.pegs[#G.pegs + 1] = { x - F.pegX, z + F.pegZ, F.PEG_R }
  G.pegs[#G.pegs + 1] = { x + F.pegX, z + F.pegZ, F.PEG_R }
  G.bosses[#G.bosses + 1] = { x, z }
  -- the done lane on its right, down to the bins; its outer wall flared
  local lx = x + G.LANE_X
  wall(lx - C, z + G.LANE_Z, lx - C, G.BIN_Z, "lane")
  wall(lx + C, z + G.LANE_Z, lx + C, G.BIN_Z, "lane")
  wall(lx + C, z + G.LANE_Z, lx + C + 0.6, z + G.LANE_Z - 1.2, "lane")
  t.lane = lx
end
-- the overflow lane, on the last flip-flop's left
do
  local t = G.toggles[#G.toggles]
  local lx = t.x - G.LANE_X
  wall(lx - C, t.z + G.LANE_Z, lx - C, G.BIN_Z, "lane")
  wall(lx + C, t.z + G.LANE_Z, lx + C, G.BIN_Z, "lane")
  wall(lx - C, t.z + G.LANE_Z, lx - C - 0.6, t.z + G.LANE_Z - 1.2, "lane")
  G.overflow = lx
end
-- the feeder's housing (a ring of short walls, open at the top to the
-- channel of balls and at the bottom to the first run) and the channel
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
  -- (and down from the housing to the first run)
  local bot = Wh.z + math.sqrt(rr * rr - C * C) + 0.2
  local runTop = G.toggles[1].z - F.A - 1.4 - G.R - F.RUN
  if runTop > bot + 0.01 then
    wall(Wh.x - C, bot, Wh.x - C, runTop); wall(Wh.x + C, bot, Wh.x + C, runTop)
  end
  Wh.queueTop, Wh.queueBot = top - Wh.QUEUE, top
end
-- the bins' floor, and the board's edges
do
  local x0, x1 = 1e9, -1e9
  local z0, z1 = 1e9, -1e9
  for _, w in ipairs(G.walls) do
    x0 = math.min(x0, w[1], w[3]); x1 = math.max(x1, w[1], w[3])
    z0 = math.min(z0, w[2], w[4]); z1 = math.max(z1, w[2], w[4])
  end
  wall(x0, G.BIN_Z, x1, G.BIN_Z, "bins")
  local M = 1.5
  G.board = { x0 = x0 - M, x1 = x1 + M, z0 = z0 - M, z1 = G.BIN_Z + M }
  -- the rim round the board, so nothing rolls off it
  local b = G.board
  wall(b.x0 + 0.15, b.z0, b.x0 + 0.15, b.z1, "rim"); wall(b.x1 - 0.15, b.z0, b.x1 - 0.15, b.z1, "rim")
  wall(b.x0, b.z1 - 0.15, b.x1, b.z1 - 0.15, "rim"); wall(b.x0, b.z0 + 0.15, b.x1, b.z0 + 0.15, "rim")
end

-- ---------------------------------------------------------------------
-- for OpenSCAD
-- ---------------------------------------------------------------------
function G.writeScad(path)
  local f = assert(io.open(path, "w"))
  local function num(n, x) f:write(string.format("%s = %.5f;\n", n, x)) end
  f:write("// made by digicomp2.lua from digicomp2-geometry.lua (DC_EXPORT=1): do not edit (cm)\n")
  num("TH", G.TH); num("BALL_R", G.R); num("WALL_H", G.WALL_H); num("WALL_T", G.WALL_T)
  num("CHAN", G.CHAN); num("BOARD_T", G.BOARD_T); num("BACK", G.BACK); num("FOOT", G.FOOT)
  num("F_Y0", F.Y0); num("F_H", F.H); num("F_W", F.W); num("F_PIN_R", F.PIN_R); num("F_HUB_R", F.HUB_R)
  num("F_BOSS_R", F.BOSS_R); num("F_ALPHA", F.ALPHA); num("F_A", F.A)
  num("F_WEIGHT_R", F.WEIGHT_R); num("F_WEIGHT_Z", F.WEIGHT_Z)
  local function pieces(name, list)
    local P = {}
    for _, pc in ipairs(list) do
      local q = {}
      for _, p in ipairs(pc) do q[#q + 1] = string.format("[%.5f,%.5f]", p[1], p[2]) end
      P[#P + 1] = "[" .. table.concat(q, ",") .. "]"
    end
    f:write(name .. " = [" .. table.concat(P, ",\n  ") .. "];\n")
  end
  pieces("F_PIECES", F.pieces)
  num("W_Y0", Wh.Y0); num("W_H", Wh.H); num("W_R", Wh.R)
  pieces("W_PIECES", Wh.pieces)
  f:write(string.format("WHEEL_AT = [%.5f,%.5f];\n", Wh.x, Wh.z))
  local T = {}
  for _, t in ipairs(G.toggles) do T[#T + 1] = string.format("[%.5f,%.5f]", t.x, t.z) end
  f:write("TOGGLES = [" .. table.concat(T, ",") .. "];\n")
  local Wl = {}
  for _, w in ipairs(G.walls) do Wl[#Wl + 1] = string.format("[%.5f,%.5f,%.5f,%.5f]", w[1], w[2], w[3], w[4]) end
  f:write("WALLS = [" .. table.concat(Wl, ",\n  ") .. "];\n")
  local Pg = {}
  for _, p in ipairs(G.pegs) do Pg[#Pg + 1] = string.format("[%.5f,%.5f,%.5f]", p[1], p[2], p[3]) end
  f:write("PEGS = [" .. table.concat(Pg, ",") .. "];\n")
  local b = G.board
  f:write(string.format("BOARD = [%.5f,%.5f,%.5f,%.5f];\n", b.x0, b.x1, b.z0, b.z1))
  local L = {}
  for k, t in ipairs(G.toggles) do L[#L + 1] = string.format("[%.5f,%.5f]", t.lane, G.BIN_Z) end
  f:write("LANES = [" .. table.concat(L, ",") .. string.format(",[%.5f,%.5f]];\n", G.overflow, G.BIN_Z))
  f:close()
end

return G
