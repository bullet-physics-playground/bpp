--
-- AP: Lennard-Jones -- flown by quadcopters
--
-- Formations-Lennard-Jones.lua with every particle replaced by a
-- physically modelled quadcopter. Artificial Physics senses the drones'
-- real positions five times a second and turns the force law into each
-- drone's next waypoint; the drone's own flight controller has to fly
-- there. See quadcopter/swarm.lua for how the two are coupled and
-- quadcopter/flight.lua for the airframe, rotors, air and controller.
--
-- THE FORCE LAW is the original's smooth dual-power curve, independent of
-- mass, crossing zero exactly at desiredSeparation:
--   f = lennardJonesConstant * (d^2p / r^(2p+1) - d^p / r^(p+1)),
-- with the repulsive side capped at forceMaximum. It settles: once the
-- lattice forms, the drones come to a near-stop.
--
-- Run it from this folder (it loads quadcopter/*.lua and meshes by
-- relative path), in the GUI or headless:
--   bpp -f Formations-Lennard-Jones-Quadcopter.lua -n 3000
--
-- Keys: S start/stop, R new launch, 2/3 dimension, ] launch one more,
-- [ land one, D hold one, F square formation, G goal, C clear obstacles,
-- arrows/IJKL/YH cursor, O obstacle, V lines, W waypoints, T follow
-- camera, P camera view, =/- sim speed. Full list in the Shortcuts panel.
--

local Swarm = require "quadcopter.swarm"

Swarm.run({
  title    = "AP: Lennard-Jones -- quadcopters",
  sepParam = "desiredSeparation",
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
})

-- EOF
