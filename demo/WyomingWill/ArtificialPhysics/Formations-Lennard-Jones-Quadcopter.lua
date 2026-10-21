--
-- AP: Lennard-Jones -- flown by quadcopters
--
-- Formations-Lennard-Jones.lua with every particle replaced by a
-- physically modelled quadcopter. Artificial Physics senses the drones'
-- real positions five times a second and turns the force law into each
-- drone's next waypoint; the drone's own flight controller has to fly
-- there. See lib/swarm.lua for how the two are coupled,
-- quadcopter/vehicle.lua for the drone behind the vehicle interface, and
-- quadcopter/flight.lua for the airframe, rotors, air and controller.
--
-- THE FORCE LAW (lib/laws.lua) is the original's smooth dual-power
-- curve, independent of mass, crossing zero exactly at desiredSeparation:
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

local Swarm = require "lib.swarm"
local cfg = require("lib.laws").lennardJones()      -- the law and its defaults (lib/laws.lua)
cfg.title = "AP: Lennard-Jones -- quadcopters"
cfg.vehicle = require "quadcopter.vehicle"
Swarm.run(cfg)

-- EOF
