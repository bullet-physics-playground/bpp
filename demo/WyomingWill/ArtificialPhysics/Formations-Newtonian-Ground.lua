--
-- AP: Newtonian -- driven by ground robots
--
-- The same formation, law and settings as Formations-Newtonian-Quadcopter.lua
-- (lib/laws.lua), on differential-drive ground robots: the book's
-- Pioneer 3-AT from Ch. 13 (ground/vehicle.lua; BOOK.md G10), 0.5 m/s at
-- most, 0.4 rad/s turns, and no wheel slower than 0.1 m/s. Artificial
-- Physics senses the robots' real positions five times a second and
-- hands each one the point to reach by the next tick; the robot turns
-- toward it and drives (forwards or backwards). lib/swarm.lua couples the
-- two; ground/README.md has the measurements.
--
-- 2D only. Run it from this folder, in the GUI or headless:
--   bpp -f Formations-Newtonian-Ground.lua -n 3000
--
-- Keys as in the quadcopter scenes (S start/stop, R new start, D hold one,
-- F square formation, G goal, C clear, O obstacle, V lines, W waypoints,
-- T/P camera, =/- speed); robots cannot go 3D or leave ([).
--

local Swarm = require "lib.swarm"
local cfg = require("lib.laws").newtonian()      -- the law and its defaults (lib/laws.lua)
cfg.title = "AP: Newtonian -- ground robots"
cfg.vehicle = require "ground.vehicle"
Swarm.run(cfg)

-- EOF
