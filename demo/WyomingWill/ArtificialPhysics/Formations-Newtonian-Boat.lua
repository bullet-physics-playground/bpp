--
-- AP: Newtonian -- sailed by surface boats
--
-- The same formation, law and settings as Formations-Newtonian-Quadcopter.lua
-- (lib/laws.lua), on holonomic round surface boats: the book's Ch. 6 ASV,
-- 0.46 m across, pushed in any direction by Voith-Schneider propellers
-- (boat/vehicle.lua; BOOK.md G11), on a still sea, ~0.8 m/s at most.
-- Artificial Physics senses the boats' real positions five times a second
-- and hands each one the point to reach by the next tick; the boat's
-- thrust controller gets it there. lib/swarm.lua couples the two;
-- boat/README.md has the measurements.
--
-- 2D only. Run it from this folder, in the GUI or headless:
--   bpp -f Formations-Newtonian-Boat.lua -n 3000
--
-- Keys as in the quadcopter scenes (S start/stop, R new start, D hold one,
-- F square formation, G goal, C clear, O obstacle, V lines, W waypoints,
-- T/P camera, =/- speed); boats cannot go 3D or leave ([).
--

local Swarm = require "lib.swarm"
local cfg = require("lib.laws").newtonian()      -- the law and its defaults (lib/laws.lua)
cfg.title = "AP: Newtonian -- boats"
cfg.vehicle = require "boat.vehicle"
Swarm.run(cfg)

-- EOF
