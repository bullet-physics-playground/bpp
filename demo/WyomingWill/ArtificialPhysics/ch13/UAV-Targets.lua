--
-- UAV-Targets -- Ch. 13's surveillance experiment (§13.4.2, PDF 465-467,
-- Fig. 13.16; book/ch13.md E12): 5 fixed-wing UAVs (13 m/s, at most
-- 0.129 rad/s, so loops of at least 101 m; fixedwing/model.lua) over 10
-- targets in a 60 x 80 m rectangle (dark red). Targets always attract;
-- UAVs within 50 m repel each other.
--
--   law 0  the point-mass ("gravity") law: inverse-square forces, turning
--          by the force's sideways part (Eq. 13.8)
--   law 1  the heading-particle torque law: a torsion spring to each
--          target and neighbour (Eqs. 13.15-13.18)
--
-- What to see: with the torque law the UAVs settle into overlapping loops
-- that cross the target area once per orbit; with the gravity law they
-- wander more widely, chasing the force. The status line measures it
-- (ch13/uavscene.lua defines the fields; ch13/README.md has 20 seeds).
-- seed picks the targets and starts (0: a new one each R). R restarts.
--
package.path = "../?.lua;" .. package.path
local scene = require "ch13.uavscene"
local U = require "ch13.uav"
v:addParam("law", 1, 0, 1, 1, "0 = point-mass (gravity) law, 1 = torque law")
v:addParam("seed", 1, 0, 1000, 1, "targets and starts (0 = a new one each R)")
scene.run({
  title = "Ch. 13: UAVs over targets",
  build = function()
    local s = math.floor(v:getParam("seed"))
    if s == 0 then s = os.time() % 100000 end
    return U.newWorld({ law = v:getParam("law") >= 0.5 and "torque" or "gravity", seed = s })
  end,
  help = "R restart | law 0 gravity, 1 torque | ticksPerFrame: speed",
})
