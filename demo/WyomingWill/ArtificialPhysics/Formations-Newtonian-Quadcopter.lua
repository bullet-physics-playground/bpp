--
-- AP: Newtonian -- flown by quadcopters
--
-- Formations-Newtonian.lua with every particle replaced by a physically
-- modelled quadcopter. Artificial Physics senses the drones' real
-- positions five times a second and turns the force law into each drone's
-- next waypoint; the drone's own flight controller has to fly there.
-- See lib/swarm.lua for how the two are coupled, quadcopter/vehicle.lua
-- for the drone behind the vehicle interface, and quadcopter/flight.lua
-- for the airframe, rotors, air and controller.
--
-- THE FORCE LAW is the original's: netF = G*m1*m2/r^power, hard-clamped to
-- forceMax, repulsive inside rad and attractive outside it (a hard switch,
-- using the same same-spin-discounted distance in square formation). The
-- per-dimension defaults are the original's too (ported there from
-- MyPanel.java's makeDefault()), re-applied on every 2/3 or F.
--
-- Because |F| flips sign at rad instead of vanishing, the original law
-- never comes to rest on drones -- they keep jostling. So Ch. 13's AR
-- damping is ON here by default (etaPower 1; the force goes smoothly to 0
-- within etaWidth x rad of rad: 0.2 in 2D, 0.5 in 3D), and the swarm
-- settles at rad.
-- Set etaPower to 0 to see the original law (quadcopter/README.md, "Ch. 13
-- on the drones"; FINDINGS.md F43-F55).
--
-- Run it from this folder (it loads quadcopter/*.lua and meshes by
-- relative path), in the GUI or headless:
--   bpp -f Formations-Newtonian-Quadcopter.lua -n 3000
--
-- Keys: S start/stop, R new launch, 2/3 dimension, ] launch one more,
-- [ land one, D hold one, F square formation, G goal, C clear obstacles,
-- arrows/IJKL/YH cursor, O obstacle, V lines, W waypoints, T follow
-- camera, P camera view, =/- sim speed. Full list in the Shortcuts panel.
--

local Swarm = require "lib.swarm"

Swarm.run({
  title    = "AP: Newtonian -- quadcopters",
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
})

-- EOF
