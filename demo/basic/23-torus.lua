--
-- Torus primitive demo
--
-- Demonstrates the Torus primitive (new primitive type from Moray integration).
--
-- Usage: bpp -f demo/basic/torus-demo.lua

local common = require "common"

common.setTiming(1/30)

-- Ground plane
plane = Plane(0,1,0,0,500)
plane.col = "#224422"
v:add(plane)

-- Torus with default parameters
t1 = Torus()
t1.col = "#ff6600"
t1.pos = btVector3(-5, 5, 0)
v:add(t1)

-- Larger torus
t2 = Torus(0.5, 2.0, 5)
t2.col = "#ff00ff"
t2.pos = btVector3(5, 5, 0)
v:add(t2)

-- Flat torus
t3 = Torus(0.2, 1.0, 2)
t3.col = "#00ffff"
t3.pos = btVector3(0, 8, 0)
v:add(t3)

common.setCamera(btVector3(15, 15, 15), btVector3(0, 5, 0), math.rad(45))
