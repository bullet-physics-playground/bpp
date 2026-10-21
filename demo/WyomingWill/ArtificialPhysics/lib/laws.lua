--
-- lib/laws.lua -- the two formation force laws, as lib/swarm.lua
-- configurations, shared by every Formations-*-<vehicle>.lua scene so the
-- cross-vehicle benchmark runs the same law with the same settings on
-- every vehicle (BOOK.md §6). Until milestone M2 these tables were written
-- out in the two quadcopter scenes; the values are theirs.
--
--   local cfg = require("lib.laws").newtonian()   -- a fresh table each call
--   cfg.title, cfg.vehicle = "AP: Newtonian -- ground robots", require "ground.vehicle"
--   require("lib.swarm").run(cfg)
--
-- SIGN: force(r, p, m1, m2) > 0 repels, < 0 attracts (lib/swarm.lua), r the
-- (spin-modified) distance in AP units.
--

local M = {}

-- THE SPLIT NEWTONIAN LAW is Formations-Newtonian.lua's: netF =
-- G*m1*m2/r^power, hard-clamped to forceMax, repulsive inside rad and
-- attractive outside it (a hard switch, using the same same-spin-
-- discounted distance in square formation). The per-dimension defaults are
-- the original's too (ported there from MyPanel.java's makeDefault()),
-- re-applied on every 2/3 or F.
--
-- Because |F| flips sign at rad instead of vanishing, the original law
-- never comes to rest on drones -- they keep jostling. So Ch. 13's AR
-- damping is ON by default (etaPower 1; the force goes smoothly to 0
-- within etaWidth x rad of rad: 0.2 in 2D, 0.5 in 3D), and the swarm
-- settles at rad. Set etaPower to 0 to see the original law
-- (quadcopter/README.md, "Ch. 13 on the drones"; FINDINGS.md F43-F55).
function M.newtonian()
  return {
    title    = "AP: Newtonian",
    sepParam = "rad",
    friction = 0.6,
    -- Ch. 13's AR damping, on by default: the split law's step at rad makes
    -- the drones jitter forever without it (FINDINGS F43-F56). etaPower 0
    -- gives the original law. Its band (etaWidth) is set per mode below.
    etaPower = 1,
    params = {
      -- name,     default, min,  max,   step, comment
      { "G",        7500,  100,  20000, 100,  "G in netF = G*m1*m2/r^power" },
      { "power",    2.5,   1,    10,    0.1,  "force falloff exponent" },
      { "forceMax", 1.5,   0.1,  10,    0.1,  "hard cap on the force magnitude" },
      { "rad",      50,    5,    100,   1,    "equilibrium/attract-repel-switch distance (Physics.java's RAD)" },
    },
    -- netF = G*m1*m2/r^power, clamped; > 0 repels (inside rad)
    force = function(modifiedR, p, m1, m2)
      local netF = p.G * m1 * m2 / (modifiedR ^ p.power)
      if netF > p.forceMax then netF = p.forceMax end
      return (modifiedR > p.rad) and -netF or netF
    end,
    -- etaWidth: wide enough that the damped force's slope at rad,
    -- F(rad) / (etaWidth rad), stays below ~0.035 per AP unit (steeper, and
    -- the drones' lag makes them jitter again), and in 2D narrow enough
    -- (< 0.26) that second neighbours cannot stall the expansion at 0.8 rad
    -- (FINDINGS F45, F50, F56): 2D 0.2, 3D 0.5.
    defaultsByMode = {
      ["2DTriangle"] = { G = 1500, power = 2.2, range = 1.5, forceMax = 1.5, friction = 0.6, timeStep = 1.0, rad = 50, layerGain = 0, etaWidth = 0.2 },
      ["2DSquare"]   = { G = 1500, power = 2.2, range = 1.5, forceMax = 1.5, friction = 0.6, timeStep = 1.0, rad = 50, layerGain = 0, etaWidth = 0.2 },
      -- (3D triangle: range 1.25 and forceMax 5 against the 3D collapse, and
      -- flight levels; see Formations-Newtonian.lua's DEFAULTS_BY_MODE)
      ["3DTriangle"] = { G = 7500, power = 2.5, range = 1.25, forceMax = 5.0, friction = 0.6, timeStep = 1.0, rad = 50, layerGain = 0.1, etaWidth = 0.5 },
      ["3DSquare"]   = { G = 7500, power = 2.5, range = 1.5, forceMax = 1.5, friction = 0.6, timeStep = 1.0, rad = 50, layerGain = 0.05, etaWidth = 0.5 },
    },
  }
end

-- THE LENNARD-JONES LAW is Formations-Lennard-Jones.lua's smooth
-- dual-power curve, independent of mass, crossing zero exactly at
-- desiredSeparation:
--   f = lennardJonesConstant * (d^2p / r^(2p+1) - d^p / r^(p+1)),
-- with the repulsive side capped at forceMaximum. It settles: once the
-- lattice forms, the agents come to a near-stop.
function M.lennardJones()
  return {
    title    = "AP: Lennard-Jones",
    sepParam = "desiredSeparation",
    layerGain = 0.05,   -- flight levels in 3D triangle (FIXES.md item 30)
    friction = 0.5,
    params = {
      -- name,                 default, min, max, step, comment
      { "lennardJonesConstant", 10,     1,   50,  1,    "overall strength of the particle-particle force" },
      { "power",                6,      1,   10,  0.1,  "steepness of the force curve" },
      { "forceMaximum",         1,      1,   5,   0.1,  "hard cap on the repulsive force magnitude" },
      { "desiredSeparation",    50,     2,   100, 1,    "particle-particle equilibrium distance" },
    },
    -- smooth dual-power curve, zero at desiredSeparation; > 0 repels
    force = function(modifiedR, p)
      local d = p.desiredSeparation
      local f = p.lennardJonesConstant * ((d ^ (2 * p.power)) / (modifiedR ^ (2 * p.power + 1))
                                          - (d ^ p.power) / (modifiedR ^ (p.power + 1)))
      if f > p.forceMaximum then f = p.forceMaximum end
      return f
    end,
  }
end

return M
