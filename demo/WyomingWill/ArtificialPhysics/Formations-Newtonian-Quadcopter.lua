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
-- THE FORCE LAW (lib/laws.lua) is the original's: netF = G*m1*m2/r^power,
-- hard-clamped to forceMax, repulsive inside rad and attractive outside
-- it (a hard switch, using the same same-spin-discounted distance in
-- square formation). The
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
local cfg = require("lib.laws").newtonian()      -- the law and its defaults (lib/laws.lua)
cfg.title = "AP: Newtonian -- quadcopters"
cfg.vehicle = require "quadcopter.vehicle"
Swarm.run(cfg)

-- EOF
