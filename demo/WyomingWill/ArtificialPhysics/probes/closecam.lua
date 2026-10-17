local Swarm = require "quadcopter.swarm"
local st = Swarm.state()
local cx, cz, n = 0, 0, 0
for _, d in ipairs(st.drones) do cx = cx + d.px; cz = cz + d.pz; n = n + 1 end
v.cam.pos = btVector3(cx / n + 3, 14, cz / n + 3)
