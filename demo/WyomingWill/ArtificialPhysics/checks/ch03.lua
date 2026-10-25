--
-- checks/ch03.lua -- Ch. 3's formation results (book/ch03.md, PDF 96-121)
-- on ch03/models.lua, the .nlogo models' own step
--
-- The split Newtonian law's clustering transition G_t (Eq. 3.4, 3.5) in
-- 2D, its 3D counterpart (ours), hysteresis and robustness (Fig. 3.16);
-- Hooke's law and its parameter cases (Figs. 3.9-3.12); the goal, Disable
-- One and the obstacle fields of Figs. 3.25-3.26; the honeycomb
-- (honeycomb.nlogo) with and without its lattice switching. Each line says what the
-- book reports and what we get.
--
-- DEFINITIONS (printed values; NetLogo units, patches and ticks):
--   nodes      lattice nodes occupied: particles closer than D/3 count as
--              one node (union-find); "shared" = share of the particles
--              that share a node with another (clustered)
--   G/G_t      the gravitational constant over Eq. 3.4's G_t =
--              Fmax D^p / (2 sqrt 3) (square: Eq. 3.5, Fmax D^p / (2 + 2
--              sqrt 2); 3D: ours, Fmax D^p / (2 sqrt 6), see ch03/README)
--   break-up   a lattice formed at 2 G_t (1500 ticks), then G lowered by
--              0.02 G_t (3D 0.04) every 200 ticks: the first G/G_t with
--              at most two pairs left (the last pairs, caught in lattice
--              defects with more than six neighbours around them, can
--              hold to 0.8 G_t)
--   nn         mean distance from each particle to the nearest particle
--              at another node, over D; rg the radius of gyration
--   v          mean particle speed, patches per tick
--   |P|, L     total linear momentum and angular momentum about the
--              centre of mass
--   stay       particles left within 1.5 D of a disabled particle after
--              4000 ticks of the goal force
--   arrived    tick at which every particle is within 120 patches of the
--              goal (the formation's radius is ~80)
--   honeycomb  share of particles with two neighbours (0.85-1.15 D) under
--              90 degrees apart (none in a perfect honeycomb, 120; a
--              particle trapped at a cell's centre makes 60), and with
--              exactly 3 such neighbours
--
-- Run from the ArtificialPhysics folder (about a minute):
--   lua5.1 checks/ch03.lua
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local C = require "ch03.models"
local World = require "lib.world"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-58s %s", ok and "ok  " or "FAIL", name, detail or ""))
end
local sqrt, abs = math.sqrt, math.abs
local unpack = unpack or table.unpack
local t0 = os.clock()
print("ch03: " .. _VERSION)

local Gt, Gt2, Gt3 = C.Gt(1, 30, 2), C.Gt(1, 30, 2, true), 900 / (2 * sqrt(6))
check("Eq. 3.4: G_t 259.81 (Fmax 1), 1299.04 (Fmax 5)", abs(Gt - 259.81) < 0.01 and abs(C.Gt(5, 30, 2) - 1299.04) < 0.01,
  string.format("%.2f, %.2f", Gt, C.Gt(5, 30, 2)))

local function list(t) return table.concat(t, " ") end

-- 1. the default lattice (G 400): clusters at Fmax 1, none at Fmax 5
do
  local n1, n5, sh5, P, L = {}, {}, 0, 0, 0
  for seed = 1, 3 do
    local m = C.new({ seed = seed }); C.run(m, 1000)
    n1[#n1 + 1] = (C.nodes(m))
    local _, _, p, l = C.momenta(m); P, L = math.max(P, p), math.max(L, abs(l))
    local q = C.new({ seed = seed, Fmax = 5 }); C.run(q, 1000)
    local n, sh = C.nodes(q); n5[#n5 + 1] = n; sh5 = math.max(sh5, sh)
  end
  check("Fig. 3.14: G 400, Fmax 1 clusters (book: 50 on 21 nodes)", math.max(unpack(n1)) <= 26 and math.min(unpack(n1)) >= 18,
    "nodes " .. list(n1))
  check("Fig. 3.14: Fmax 5 does not cluster", sh5 == 0, "nodes " .. list(n5))
  check("Fig. 3.10: momenta conserved (|P|, L ~ 0)", P < 1e-9 and L < 1e-9, string.format("|P| %.1e, L %.1e", P, L))
end

-- 2. the transition from a cloud, and when clusters break up (hysteresis)
local function breakUp(o, from, step)
  local m = C.new(o)
  C.run(m, 1500)
  local f = from
  while f > 0.5 do
    m.G = f * o.Gref; C.run(m, 200)
    local _, sh = C.nodes(m)
    if sh * #m.ps <= 4 then return f end
    f = f - step
  end
end
do
  local below, above = {}, {}
  for seed = 1, 4 do
    local m = C.new({ seed = seed, G = 0.9 * Gt }); C.run(m, 1000); below[#below + 1] = string.format("%.2f", select(2, C.nodes(m)))
    m = C.new({ seed = seed, G = 1.2 * Gt }); C.run(m, 1000); above[#above + 1] = string.format("%.2f", select(2, C.nodes(m)))
  end
  local okB, okA = true, true
  for i = 1, 4 do okB = okB and tonumber(below[i]) == 0; okA = okA and tonumber(above[i]) >= 0.4 end
  check("Eq. 3.4: none at 0.9 G_t, clusters at 1.2 G_t (shared)", okB and okA, "0.9: " .. list(below) .. "  1.2: " .. list(above))
  local b = {}
  for seed = 1, 2 do b[#b + 1] = breakUp({ seed = seed, G = 2 * Gt, Gref = Gt }, 2, 0.02) end
  check("Sec. 3.2.2: lowering G, clusters break up near G_t", b[1] and b[2] and b[1] >= 0.85 and b[1] <= 1.05 and b[2] >= 0.85 and b[2] <= 1.05,
    string.format("at %.2f, %.2f G_t", b[1] or 0, b[2] or 0))
  -- raising G on a formed lattice makes no clusters; raising G and adding
  -- particles does
  local raised, added = {}, {}
  for seed = 1, 2 do
    local m = C.new({ seed = seed, G = 0.8 * Gt }); C.run(m, 1000)
    m.G = 400; C.run(m, 500)
    raised[#raised + 1] = string.format("%.2f", select(2, C.nodes(m)))
    for _ = 1, 10 do C.born(m) end
    C.run(m, 1000)
    added[#added + 1] = string.format("%.2f", select(2, C.nodes(m)))
  end
  check("Sec. 3.2.2: raising G to 400 after forming: few pairs at most", tonumber(raised[1]) <= 0.15 and tonumber(raised[2]) <= 0.15,
    "shared " .. list(raised))
  check("Sec. 3.2.2: ... raising G and adding 10 particles: clusters", tonumber(added[1]) >= 0.2 and tonumber(added[2]) >= 0.2,
    "shared " .. list(added))
end

-- 3. robustness (Fig. 3.16): remove 25 of 50 clustered particles
do
  local before, after = {}, {}
  for seed = 2, 3 do
    local m = C.new({ seed = seed }); C.run(m, 1000)
    before[#before + 1] = (C.nodes(m))
    for _ = 1, 25 do C.kill(m) end
    C.run(m, 1000)
    after[#after + 1] = (C.nodes(m))
  end
  check("Fig. 3.16: 25 of 50 removed, most nodes kept (book 21 -> 19)", after[1] >= 0.75 * before[1] and after[2] >= 0.75 * before[2],
    string.format("%d -> %d, %d -> %d nodes", before[1], after[1], before[2], after[2]))
end

-- 4. the square lattice: Eq. 3.5 holds for the Java app's and our BPP
-- scene's force direction; the .nlogo's (sqrt 2 longer for like pairs)
-- moves the break-up to ~1.2 G_t2
do
  local c1, c5 = {}, {}
  for seed = 1, 2 do
    local m = C.new({ seed = seed, square = true }); C.run(m, 1500); c1[#c1 + 1] = string.format("%.2f", select(2, C.nodes(m)))
    m = C.new({ seed = seed, square = true, Fmax = 5 }); C.run(m, 1500); c5[#c5 + 1] = string.format("%.2f", select(2, C.nodes(m)))
  end
  check("Fig. 3.18: square, Fmax 1 clusters, Fmax 5 does not (shared)", tonumber(c1[1]) > 0.2 and tonumber(c1[2]) > 0.2 and tonumber(c5[1]) == 0 and tonumber(c5[2]) == 0,
    "Fmax 1: " .. list(c1) .. "  Fmax 5: " .. list(c5))
  local nl, raw = {}, {}
  for seed = 1, 2 do
    nl[#nl + 1] = breakUp({ seed = seed, square = true, G = 2 * Gt2, Gref = Gt2 }, 2, 0.02)
    raw[#raw + 1] = breakUp({ seed = seed, square = true, rawDirection = true, G = 2 * Gt2, Gref = Gt2 }, 2, 0.02)
  end
  check("Eq. 3.5 (G_t2 186.4): break-up near it, true-distance direction", raw[1] >= 0.9 and raw[1] <= 1.15 and raw[2] >= 0.9 and raw[2] <= 1.15,
    string.format("at %.2f, %.2f G_t2", raw[1], raw[2]))
  check("... the .nlogo's direction: ~1.2 G_t2 (ours: Fmax D^p / 4)", nl[1] >= 1.1 and nl[1] <= 1.35 and nl[2] >= 1.1 and nl[2] <= 1.35,
    string.format("at %.2f, %.2f G_t2", nl[1], nl[2]))
end

-- 5. 3D (ours): G_t3 = Fmax D^p / (2 sqrt 6); the view must stay below
-- the second shell (sqrt 2 D)
do
  local b1 = breakUp({ seed = 1, dim = 3, view = 1.3, G = 2 * Gt3, Gref = Gt3 }, 2, 0.04)
  local b2 = breakUp({ seed = 2, dim = 3, view = 1.3, G = 2 * Gt3, Gref = Gt3 }, 2, 0.04)
  check("3D: clusters break up near G_t3 = 183.7 (view 1.3)", b1 and b2 and b1 >= 0.85 and b1 <= 1.15 and b2 >= 0.85 and b2 <= 1.15,
    string.format("at %.2f, %.2f G_t3", b1 or 0, b2 or 0))
  local m13 = C.new({ seed = 1, dim = 3, view = 1.3, G = 0.8 * Gt3 }); C.run(m13, 1500)
  local m15 = C.new({ seed = 1, dim = 3, view = 1.5, G = 0.8 * Gt3 }); C.run(m15, 1500)
  local nn13, nn15 = C.lattice(m13), C.lattice(m15)
  check("3D: the book's view 1.5 reaches the second shell and shrinks", nn15 < 0.7 and nn13 > 0.75, string.format("nn %.2f (1.3) vs %.2f (1.5)", nn13, nn15))
end

-- 6. Hooke's law (Figs. 3.9, 3.12)
do
  local function hooke(o) o.law, o.dt = "hooke", 0.5; return C.new(o) end
  local m = hooke({ seed = 1 }); C.run(m, 200)
  local nn200 = C.lattice(m); C.run(m, 300)
  local nn500, _, rg500 = C.lattice(m)
  check("Fig. 3.9: Hooke, a good lattice by 200 steps, then still", nn200 >= 0.93 and nn500 >= 0.95 and C.speed(m) < 0.01,
    string.format("nn %.2f at 200, %.2f at 500, rg %.0f, v %.3f", nn200, nn500, rg500, C.speed(m)))
  local f3 = hooke({ seed = 1, Fmax = 3 }); C.run(f3, 500)
  local f5 = hooke({ seed = 1, Fmax = 5 }); C.run(f5, 500)
  local _, _, rg3 = C.lattice(f3)
  local _, _, rg5 = C.lattice(f5)
  check("Fig. 3.12: Fmax 3 cannot expand", rg3 < 40 and C.speed(f3) < 0.01, string.format("rg %.0f (default %.0f), v %.3f", rg3, rg500, C.speed(f3)))
  check("Fig. 3.12: Fmax 5 is in flux", rg5 < 40 and C.speed(f5) > 3, string.format("rg %.0f, v %.1f", rg5, C.speed(f5)))
  local k = hooke({ seed = 1, k = 0.25 }); C.run(k, 500)
  local nnk = C.lattice(k)
  check("Sec. 3.2.1: k 0.25 works poorly", nnk < 0.6, string.format("nn %.2f", nnk))
  local r25 = hooke({ seed = 1, view = 2.5 }); C.run(r25, 500)
  local _, _, rgr = C.lattice(r25)
  check("Fig. 3.8: range 2.5 D cannot expand (less is more)", rgr < 40, string.format("rg %.0f", rgr))
  C.kill(m); C.run(m, 500)
  local vk = C.speed(m)
  local b = C.born(m); C.run(m, 1000)
  local best = math.huge
  for _, a in ipairs(m.ps) do if a ~= b then best = math.min(best, sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)) end end
  local _, _, P = C.momenta(m)
  check("Kill One / One is Born: absorbed, still again", vk < 0.01 and C.speed(m) < 0.01 and best > 0.9 * 30 and best < 1.1 * 30 and P < 1e-9,
    string.format("v %.3f / %.3f, newborn's nearest %.2f D, |P| %.0e", vk, C.speed(m), best / 30, P))
end

-- 7. the goal, Disable One, obstacles (formation_goal_obs.nlogo)
local g = World.CH03_GOAL
do
  local arr, rgs = {}, {}
  for _, gf in ipairs({ 0.25, 2 }) do
    local m = C.new({ cx = 175.25, goal = g, seed = 1, goalF = gf })
    C.run(m, 300); m.goalOn = true
    local t
    for i = 1, 2000 do C.step(m); if not t and C.momenta(m) < g[1] + 10 then t = i end end
    arr[#arr + 1] = t or -1
    local _, _, rg = C.lattice(m); rgs[#rgs + 1] = string.format("%.0f", rg)
  end
  check("Fig. 3.24: goal force 2 arrives fast and compresses", arr[2] > 0 and arr[2] < arr[1] / 4 and tonumber(rgs[2]) < 0.85 * tonumber(rgs[1]),
    string.format("centre arrives at %d vs %d ticks, rg %s vs %s", arr[2], arr[1], rgs[2], rgs[1]))
  -- one bonded neighbour alone: it leaves only when goalF > Fmax = 1
  local stays = {}
  for _, gf in ipairs({ 0.99, 1.01 }) do
    local q = C.new({ n = 0, goal = { -1000, 0 }, goalF = gf })
    local d = C.add(q, 0, 0); d.mass = C.HEAVY
    local a = C.add(q, -36, 0)
    q.goalOn = true; C.run(q, 3000)
    stays[#stays + 1] = sqrt((a.x - d.x) ^ 2 + (a.y - d.y) ^ 2) / 30
  end
  check("Abandon Goal Force 1: a lone neighbour leaves above Fmax", stays[1] < 1.5 and stays[2] > 10,
    string.format("goalF 0.99: %.1f D away, 1.01: %.1f D", stays[1], stays[2]))
  local st = {}
  for seed = 1, 2 do
    local m = C.new({ cx = 175.25, goal = g, seed = seed, goalF = 0.25 })
    C.run(m, 300)
    local d = C.disable(m)
    m.goalOn = true; C.run(m, 4000)
    local near, at = 0, 0
    for _, a in ipairs(m.ps) do
      if a ~= d then
        if (a.x - d.x) ^ 2 + (a.y - d.y) ^ 2 < 45 ^ 2 then near = near + 1 end
        if (a.x - g[1]) ^ 2 + (a.y - g[2]) ^ 2 < 150 ^ 2 then at = at + 1 end
      end
    end
    st[#st + 1] = near .. " stay, " .. at .. " at the goal"
  end
  check("Disable One, goalF 0.25: most go, a neighbour may stay", st[1]:match("^[0-3] stay, 4[6-9]") and st[2]:match("^[0-3] stay, 4[6-9]"),
    table.concat(st, "; "))
  local function field(m, discs, r)
    m.obstacleF = r
    for _, d in ipairs(discs) do C.addObstacle(m, d[1], d[2]) end
  end
  local sx, sy = World.CH03_SHIFT[1], World.CH03_SHIFT[2]
  local discs, wall = {}, {}
  for _, d in ipairs(World.CH03_DISCS) do discs[#discs + 1] = { 48 + sx + d[1], -7 + sy + d[2] } end
  for _, d in ipairs(World.CH03_WALL_DISCS) do wall[#wall + 1] = { d[1] + sx, d[2] + sy } end
  local res = {}
  for _, case in ipairs({ { discs, 10 }, { wall, 50 } }) do
    local m = C.new({ cx = 175.25, goal = g, seed = 1 })
    field(m, case[1], case[2])
    C.run(m, 300); m.goalOn = true
    local north, t = {}, nil
    for i = 1, 3000 do
      C.step(m)
      for _, a in ipairs(m.ps) do if a.x > -60 and a.x < 60 and a.y > 60 then north[a] = true end end
      if not t then
        local all = true
        for _, a in ipairs(m.ps) do if (a.x - g[1]) ^ 2 + (a.y - g[2]) ^ 2 > 120 ^ 2 then all = false; break end end
        if all then t = i end
      end
    end
    local n = 0
    for _ in pairs(north) do n = n + 1 end
    res[#res + 1] = { t = t, north = n }
  end
  check("Fig. 3.25: 12 discs of size 10, all reach the goal", res[1].t ~= nil, string.format("arrived at %s ticks", tostring(res[1].t)))
  check("Fig. 3.26: size 50, the whole formation goes round the north end", res[2].t ~= nil and res[2].north == 50,
    string.format("%d of 50 passed north of the wall, arrived at %s", res[2].north, tostring(res[2].t)))
end

-- 8. the honeycomb (honeycomb.nlogo: 201 particles, D 20, G = G_t)
do
  local function hc(sw)
    local m = C.new({ n = 201, D = 20, G = C.Gt(1, 20, 2), honeycomb = true, switch = sw, seed = 1 })
    C.run(m, 500)
    local three, bad = C.honeycombQuality(m)
    local u, l = {}, {}
    for _, a in ipairs(m.ps) do
      local bu, bl = math.huge, math.huge
      for _, b in ipairs(m.ps) do
        if b ~= a then
          local d = sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
          if a.who % 2 == b.who % 2 then bl = math.min(bl, d) else bu = math.min(bu, d) end
        end
      end
      u[#u + 1], l[#l + 1] = bu / 20, bl / 20
    end
    table.sort(u); table.sort(l)
    return three, bad, u[101], l[101]
  end
  local _, badH = hc(nil)
  local threeS, badS, uS, lS = hc("nlogo")
  check("Sec. 3.2.4: honeycomb alone traps particles at cell centres", badH >= 0.2, string.format("%.0f%% with neighbours under 90 deg apart", 100 * badH))
  check("Sec. 3.2.4: honeycomb.nlogo's switching frees them", badS <= 0.1, string.format("%.0f%% (3 neighbours: %.0f%%)", 100 * badS, 100 * threeS))
  check("... its lattice: unlike at D, like between sqrt 2 and sqrt 3 D", uS > 0.85 and uS < 1.05 and lS > 1.45 and lS < 1.7,
    string.format("median nearest unlike %.2f D, like %.2f D", uS, lS))
end

print(string.format("ch03: %d checks, %d failed, %.0f s", count, fails, os.clock() - t0))
print(fails == 0 and "PASS ch03: " .. count .. " tests" or "FAIL ch03")
