--
-- AP: Newtonian -- flown by quadcopters
--
-- Formations-Newtonian.lua with every particle replaced by a physically
-- modelled quadcopter. Artificial Physics senses the drones' real
-- positions five times a second and turns the force law into each drone's
-- next waypoint; the drone's own flight controller has to fly there.
-- See quadcopter/swarm.lua for how the two are coupled and
-- quadcopter/flight.lua for the airframe, rotors, air and controller.
--
-- THE FORCE LAW is the original's: netF = G*m1*m2/r^power, hard-clamped to
-- forceMax, repulsive inside rad and attractive outside it (a hard switch,
-- using the same same-spin-discounted distance in square formation). The
-- per-dimension defaults are the original's too (ported there from
-- MyPanel.java's makeDefault()), re-applied on every 2/3 or F.
--
-- Because |F| flips sign at rad instead of vanishing, this swarm never
-- comes to rest -- with drones you can watch them keep jostling.
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

local Swarm = require "quadcopter.swarm"

Swarm.run({
  title    = "AP: Newtonian -- quadcopters",
  sepParam = "rad",
  friction = 0.6,
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
  defaultsByMode = {
    ["2DTriangle"] = { G = 1500, power = 2.2, range = 1.5, forceMax = 1.5, friction = 0.6, timeStep = 1.0, rad = 50, layerGain = 0 },
    ["2DSquare"]   = { G = 1500, power = 2.2, range = 1.5, forceMax = 1.5, friction = 0.6, timeStep = 1.0, rad = 50, layerGain = 0 },
    -- (3D triangle: range 1.25 and forceMax 5 against the 3D collapse, and
    -- flight levels; see Formations-Newtonian.lua's DEFAULTS_BY_MODE)
    ["3DTriangle"] = { G = 7500, power = 2.5, range = 1.25, forceMax = 5.0, friction = 0.6, timeStep = 1.0, rad = 50, layerGain = 0.1 },
    ["3DSquare"]   = { G = 7500, power = 2.5, range = 1.5, forceMax = 1.5, friction = 0.6, timeStep = 1.0, rad = 50, layerGain = 0.05 },
  },
})

-- EOF
