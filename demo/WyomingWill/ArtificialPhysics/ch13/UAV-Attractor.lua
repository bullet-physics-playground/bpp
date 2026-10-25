--
-- UAV-Attractor -- one fixed-wing UAV and one attractor (Ch. 13, PDF
-- 458-459, Fig. 13.13; book/ch13.md E8). The UAV starts at the origin
-- heading east (+x); its smallest turn circles (radius 101 m, centred
-- 101 m to its left and right) are the book's "unreachable zones".
--
--   case 1  attractor 200 m directly behind: the gravity law's sideways
--           force is zero, so the UAV flies away for good; the torque law
--           turns it round (the spring is strongest behind)
--   case 2  attractor outside both zones (150, 150): it overflies it in a
--           continuous loop
--   case 3  attractor inside the left zone (0, 50): it orbits for ever,
--           never closer than 101 - 51 = 50 m
--   law 0 gravity (point-mass), 1 torque (as UAV-Targets.lua)
--
-- The status line is ch13/uavscene.lua's; "spread" is the distance to the
-- attractor. R restarts.
--
package.path = "../?.lua;" .. package.path
local scene = require "ch13.uavscene"
local U = require "ch13.uav"
local FW = require "fixedwing.model"
local CASES = { { -200, 0 }, { 150, 150 }, { 0, 50 } }
v:addParam("case", 1, 1, 3, 1, "1 behind, 2 outside the unreachable zones, 3 inside one")
v:addParam("law", 0, 0, 1, 1, "0 = point-mass (gravity) law, 1 = torque law")
scene.run({
  title = "Ch. 13: one UAV, one attractor",
  camHeight = 700,
  build = function()
    local c = CASES[math.floor(v:getParam("case"))] or CASES[1]
    return U.newWorld({ law = v:getParam("law") >= 0.5 and "torque" or "gravity",
                        uavs = { FW.new(0, 0, 0) }, targets = { { x = c[1], y = c[2] } } })
  end,
  help = "R restart | case 1-3 | law 0 gravity, 1 torque | ticksPerFrame: speed",
})
