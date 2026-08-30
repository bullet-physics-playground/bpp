--
-- Physicomimetics -- a physics-based swarm that self-assembles into a
-- hexagonal lattice
--
-- THE IDEA (Spears & Spears, "Physicomimetics: Physics-Based Swarm
-- Intelligence", Springer 2012 -- see especially the "Artificial Physics"
-- framework of Part I/II). Instead of the usual biology-inspired swarm
-- rules, every agent is treated as a point mass that feels a virtual
-- force from every nearby agent, and then just obeys F = m a. Nothing
-- schedules the formation; it falls out of the force law the same way a
-- real crystal falls out of interatomic forces -- "nature is lazy", so
-- the swarm does the least work needed to reach equilibrium.
--
-- THE FORCE LAW. The book's signature law is "split Newtonian" gravity:
--
--     |F| = G * m_i * m_j / r^p         clamped to Fmax
--       r < R  -> repulsive     R < r < Rcut -> attractive     r > Rcut -> 0
--
-- R is the desired inter-agent spacing (the lattice constant). That law
-- has a catch: |F| does not vanish at r = R, it just flips sign there, so
-- a finished lattice never actually stops -- every bond hunts back and
-- forth across the crossover forever. This demo defaults instead to a
-- Lennard-Jones-style WELL with its minimum exactly at r = R:
--
--     F = -(G/R^p) * ( (R/r)^2p - (R/r)^p )
--
-- -- same 1/r^p Newtonian character (repulsion still diverges as r -> 0,
-- so agents can never be crushed together), but it is a smooth restoring
-- well around R, so with a little friction the swarm anneals to a still
-- hexagonal crystal. Flip `rawLaw` on to watch the original, forever-
-- jiggling version.
--
-- WHY A HEXAGON, specifically. Set the cutoff at Rcut = 1.5 R. In a
-- triangular (hexagonal-close-packed) lattice each agent has exactly six
-- neighbours at distance R; the next ring sits at R*sqrt(3) ~= 1.73 R,
-- just past the cutoff, so it is not seen. Six mutually-repelling
-- neighbours held inside a disc of radius 1.5 R can only sit 60 degrees
-- apart -- a hexagon. A square lattice (4 near neighbours + 4 at 1.41 R)
-- is not a force balance under this law, so the swarm anneals away from
-- it. This is the book's central worked example.
--
-- FRICTION + ANNEALING. A viscous drag  F_drag = -kv * v  bleeds off
-- kinetic energy. On its own, though, it just quenches the swarm into a
-- ragged glass -- locally well-spaced, no long-range order. So the agents
-- also get a random "thermal" kick that starts at `heat` * (G/R^p) and
-- cools linearly to zero over `coolFrames` frames: early heat lets them
-- hop out of bad local minima, and as it cools they settle onto the
-- hexagonal lattice that is left. Exactly how you anneal a real crystal;
-- set coolFrames = 0 to skip it and watch the glass form instead.
--
-- HOW IT MAPS ONTO BPP. Each agent is a real dynamic Bullet sphere. Every
-- preSim step this script computes the pairwise AP forces (an O(N^2)
-- sweep -- trivial at this N) and hands each one to Bullet via
-- body:applyCentralForce(); Bullet then does the F = m a integration,
-- substep by substep, and resolves the odd real collision during the
-- messy opening moment. Agents are locked to the y = 0 plane with
-- body:setLinearFactor(1,0,1) so the whole thing stays 2-D, and
-- forceActivationState(4) stops Bullet from putting a slow-moving agent
-- to sleep.
--
-- CONTROLS:
--   R  -- re-scatter the agents and watch it crystallise again
--   GUI sliders, all live: rawLaw, G, R, p, Fmax, rangeMul, friction,
--   heat, coolFrames, centerPull, colorByNeighbors.
--
-- COLOR (when colorByNeighbors is on) shows the emergent structure
-- directly: green = 6 bonded neighbours (fully in the crystal), amber = 5
-- or 7 (a dislocation / grain boundary), red = fewer (a loose edge agent).
--
-- The console prints, once a second, the fraction of agents that have
-- reached 6 neighbours and the swarm's mean speed -- 6-neighbour climbs
-- past ~45% (the interior of a 61-agent hexagonal patch) as mean speed
-- decays to near zero once the anneal finishes.
--

local common = require "common"

-- ---------------------------------------------------------------------
-- fixed scene constants
-- ---------------------------------------------------------------------

-- 61 = the 5th centred hexagonal number (1, 7, 19, 37, 61, ...), so the
-- minimum-energy state is a gap-free hexagon five rings across -- the
-- swarm has an exact target to find rather than settling for a ragged
-- patch.
local N          = 61
local AGENT_R    = 1.2      -- sphere radius (<< R, so agents read as
                             -- discrete dots and real contact only ever
                             -- happens deep inside the repulsion zone)
local SPAWN_R    = 28.0     -- agents start randomly inside this disc...
local MIN_SEP    = 4.0      -- ...but no two closer than this, so the
                             -- opening frame has no near-coincident pair
                             -- to fling apart

-- Integration: 1/60 s frame, 8 substeps of 1/480 s (exact). The force law
-- is soft (stiffness ~ G/R^2 against mass 1) so this is far finer than
-- stability needs -- it just keeps the assembly smooth.
common.setTiming(1 / 60, 8, 1 / 480)
common.gravity(0)           -- the only forces are the virtual AP ones

-- ---------------------------------------------------------------------
-- GUI knobs -- every one is read live inside preSim / postSim
-- ---------------------------------------------------------------------

v:addParam("rawLaw",     false,  "off = smooth well (crystallises and comes to rest); on = the book's raw split-Newtonian +-G/r^p (jiggles forever)")
v:addParam("G",          3000.0, 0.0,  20000.0, 100.0, "AP force strength (the natural force unit is G/R^p)")
v:addParam("R",          8.0,    2.0,  30.0,    0.5,   "desired inter-agent spacing (the lattice constant)")
v:addParam("p",          2.0,    1.0,  4.0,     0.1,   "force power-law exponent (well repulsion ~ 1/r^2p, attraction ~ 1/r^p)")
v:addParam("Fmax",       120.0,  1.0,  1000.0,  10.0,  "per-pair force-magnitude clamp (tames the r -> 0 repulsion spike)")
v:addParam("rangeMul",   1.5,    1.1,  3.0,     0.1,   "sensing cutoff, in multiples of R (1.5 -> hexagon)")
v:addParam("friction",   2.5,    0.0,  60.0,    0.5,   "viscous drag kv in F_drag = -kv * v (the dissipation that lets it settle)")
v:addParam("heat",       2.5,    0.0,  10.0,    0.5,   "simulated-annealing start temperature: initial random-kick amplitude, in units of the natural force G/R^p")
v:addParam("coolFrames", 2500.0, 0.0,  8000.0,  100.0, "anneal time: the kick amplitude cools linearly from `heat` to zero over this many frames (0 = no annealing, freezes as a glass)")
v:addParam("centerPull", 2.0,    0.0,  40.0,    1.0,   "gentle uniform pull holding the swarm centroid at the origin")
v:addParam("colorByNeighbors", true, "color each agent by its bonded-neighbour count (green = 6 = in the crystal)")

-- ---------------------------------------------------------------------
-- agents
-- ---------------------------------------------------------------------

-- a fresh scatter (and a different final crystal / set of defects) each
-- run; the seed is printed so any run can be reproduced by hard-coding it
local SEED = os.time()
math.randomseed(SEED)

local COL_PLAIN = "#4a90d9"
local COL_6     = "#33cc55" -- 6 neighbours: fully in the lattice
local COL_57    = "#e0b020" -- 5 or 7: a dislocation
local COL_LOW   = "#d94f3d" -- <5: a loose edge agent

local agents = {}           -- Object (dynamic sphere) per agent
local fx, fz = {}, {}       -- net-force accumulators, reused each frame
local nb     = {}           -- bonded-neighbour count per agent

-- a random point in the spawn disc that clears every agent placed so far
local function scatterPoint()
  while true do
    local a  = math.random() * 2 * math.pi
    local rr = math.sqrt(math.random()) * SPAWN_R   -- sqrt -> uniform over area
    local x, z = rr * math.cos(a), rr * math.sin(a)
    local ok = true
    for i = 1, #agents do
      local q = agents[i].pos
      local dx, dz = q.x - x, q.z - z
      if dx * dx + dz * dz < MIN_SEP * MIN_SEP then ok = false; break end
    end
    if ok then return x, z end
  end
end

for i = 1, N do
  local x, z = scatterPoint()
  local s = Sphere(AGENT_R, 1.0)
  s.col = COL_PLAIN
  s.pos = btVector3(x, 0, z)
  s.friction = 0.0
  s.restitution = 0.0
  v:add(s)
  s.body:setLinearFactor(btVector3(1, 0, 1))  -- confine to the y = 0 plane
  s.body:forceActivationState(4)              -- DISABLE_DEACTIVATION: a
                                               -- settled agent must not sleep
  agents[i] = s
  fx[i], fz[i], nb[i] = 0, 0, 0
end

-- faint ground grid, well below the agents (they are pinned to y = 0, so
-- it never collides) -- just depth reference for the camera / POV export
local ground = Plane(0, 1, 0, 0, 400)
ground.col = "#1b1b1b"
ground.pos = btVector3(0, -12, 0)
v:add(ground)

-- ---------------------------------------------------------------------
-- the swarm rule: pairwise Artificial Physics forces, every step
-- ---------------------------------------------------------------------

-- the frame the current anneal started on -- 0 at launch, reset to "now"
-- by the R shortcut so a re-scatter gets its own full cool-down
local annealStart = 0

v:preSim(function(frame)
  local G      = v:getParam("G")
  local R      = v:getParam("R")
  local p      = v:getParam("p")
  local Fmax   = v:getParam("Fmax")
  local cut    = v:getParam("rangeMul") * R
  local cut2   = cut * cut
  local kv     = v:getParam("friction")
  local kc     = v:getParam("centerPull")
  local np     = #agents

  for i = 1, np do fx[i], fz[i] = 0, 0 end

  -- every unordered pair once; equal and opposite contribution (Newton's
  -- third law) so the swarm's total momentum only changes through drag
  -- and the centring pull
  local raw  = v:getParam("rawLaw")
  local Gs   = G / (R ^ p)   -- natural force unit: |F| at r = R under the
                              -- raw law; also the well's overall scale

  for i = 1, np - 1 do
    local pi = agents[i].pos
    local xi, zi = pi.x, pi.z
    for j = i + 1, np do
      local pj = agents[j].pos
      local dx, dz = pj.x - xi, pj.z - zi
      local d2 = dx * dx + dz * dz
      if d2 < cut2 and d2 > 1e-9 then
        local r   = math.sqrt(d2)
        -- mag > 0 pulls the pair together, mag < 0 pushes it apart
        local mag
        if raw then
          -- the book's raw "split Newtonian" law: |F| = G / r^p, repulsive
          -- inside R and attractive outside. |F| does NOT vanish at r = R
          -- -- it flips sign there -- so a finished lattice keeps jostling
          -- forever. Historically what the AP hexagon demos used; kept as a
          -- toggle so you can watch the difference.
          mag = G / (r ^ p)
          if r < R then mag = -mag end
        else
          -- default: a Lennard-Jones-style well with its minimum exactly at
          -- r = R.  Repulsion ~ (R/r)^2p diverges as r -> 0 (agents can
          -- never be crushed together); attraction ~ (R/r)^p; the two
          -- cancel at r = R, and it is a smooth restoring well around that
          -- point, so with a little friction the swarm anneals to a still
          -- hexagonal crystal instead of chattering across a sign flip.
          local a = (R / r) ^ p
          mag = -Gs * (a * a - a)          -- <0 (repel) for r<R, >0 (attract) for r>R
        end
        if mag >  Fmax then mag =  Fmax end
        if mag < -Fmax then mag = -Fmax end
        local ux, uz = dx / r, dz / r       -- unit vector i -> j
        fx[i] = fx[i] + mag * ux;  fz[i] = fz[i] + mag * uz
        fx[j] = fx[j] - mag * ux;  fz[j] = fz[j] - mag * uz
      end
    end
  end

  -- swarm centroid, for the centring pull below
  local cx, cz = 0.0, 0.0
  for i = 1, np do
    local q = agents[i].pos
    cx = cx + q.x;  cz = cz + q.z
  end
  cx, cz = cx / np, cz / np

  -- simulated-annealing temperature: a random "thermal" force that starts
  -- at `heat` times the natural force unit and cools linearly to zero over
  -- `coolFrames` frames. The early heat lets agents hop out of the ragged
  -- local minima they would otherwise freeze into (a glass); as it cools
  -- they settle onto the hexagonal lattice that is left -- exactly how you
  -- anneal a real crystal.
  local cool = v:getParam("coolFrames")
  local kick = (cool > 0)
    and v:getParam("heat") * Gs * math.max(0.0, 1.0 - (frame - annealStart) / cool)
    or 0.0

  -- apply: AP force + viscous drag + thermal kick + a uniform pull that
  -- nudges the whole centroid back to the origin. The centring term is the
  -- SAME vector on every agent, so it only translates the swarm -- it adds
  -- no internal stress and cannot distort the lattice.
  for i = 1, np do
    local s   = agents[i]
    local vel = s.vel
    s.body:applyCentralForce(btVector3(
      fx[i] - kv * vel.x - kc * cx + kick * (math.random() * 2.0 - 1.0),
      0,
      fz[i] - kv * vel.z - kc * cz + kick * (math.random() * 2.0 - 1.0)))
  end
end)

-- ---------------------------------------------------------------------
-- neighbour colouring + convergence readout
-- ---------------------------------------------------------------------

local STATS_EVERY = 60   -- frames (~1 s)

v:postSim(function(frame)
  local np      = #agents
  local byColor = v:getParam("colorByNeighbors")
  local R       = v:getParam("R")
  local lo2     = (0.6 * R) ^ 2
  local hi2     = (v:getParam("rangeMul") * R) ^ 2

  for i = 1, np do
    local c  = 0
    local pi = agents[i].pos
    local xi, zi = pi.x, pi.z
    for j = 1, np do
      if j ~= i then
        local q = agents[j].pos
        local dx, dz = q.x - xi, q.z - zi
        local d2 = dx * dx + dz * dz
        if d2 >= lo2 and d2 <= hi2 then c = c + 1 end
      end
    end
    nb[i] = c
    if byColor then
      agents[i].col = (c == 6) and COL_6
                   or (c == 5 or c == 7) and COL_57
                   or COL_LOW
    else
      agents[i].col = COL_PLAIN
    end
  end

  if frame % STATS_EVERY == 0 then
    local six, sumsq = 0, 0.0
    for i = 1, np do
      if nb[i] == 6 then six = six + 1 end
      local vel = agents[i].vel
      sumsq = sumsq + vel.x * vel.x + vel.z * vel.z
    end
    printf("frame %5d   6-neighbour: %2d/%d (%2.0f%%)   mean speed: %.3f",
           frame, six, np, 100 * six / np, math.sqrt(sumsq / np))
  end
end)

-- ---------------------------------------------------------------------
-- re-scatter shortcut
-- ---------------------------------------------------------------------

v:addShortcut("R", function(frame)
  -- park every agent far away first, so scatterPoint()'s separation test
  -- only sees agents already given their new spot this pass
  for i = 1, #agents do agents[i].pos = btVector3(1e6 + i * 10, 0, 0) end
  for i = 1, #agents do
    local x, z = scatterPoint()
    agents[i].pos = btVector3(x, 0, z)
    agents[i].vel = btVector3(0, 0, 0)
  end
  annealStart = frame                     -- restart the cool-down
  print("re-scattered " .. #agents .. " agents")
end)

-- ---------------------------------------------------------------------
-- camera -- above the y = 0 plane, tilted enough to read as 3-D spheres
-- ---------------------------------------------------------------------

common.setCamera(btVector3(0, 78, 46), btVector3(0, 0, 0))

v:preStart(function(frame)
  printf("Physicomimetics: %d agents -> hexagonal lattice via Artificial Physics" ..
         "  (seed %d).  R: re-scatter", N, SEED)
end)

-- EOF
