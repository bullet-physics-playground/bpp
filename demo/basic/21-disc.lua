--
-- Disc primitive demo
--
-- Demonstrates the Disc primitive (flat cylinder, new primitive type from Moray integration).
--
-- Usage: bpp -f demo/basic/disc-demo.lua

local common = require "common"

common.setTiming(1/30)

-- Ground plane
plane = Plane(0,1,0,0,500)
plane.col = "#224422"
v:add(plane)

-- Disc with default parameters
d1 = Disc()
d1.col = "#ff6600"
d1.pos = btVector3(-5, 3, 0)
v:add(d1)

-- Larger disc
d2 = Disc(2.0, 0.5, 3)
d2.col = "#00ffff"
d2.pos = btVector3(0, 4, 0)
v:add(d2)

-- Thin disc
d3 = Disc(1.5, 0.1, 1)
d3.col = "#ff00ff"
d3.pos = btVector3(5, 3, 0)
v:add(d3)

common.setCamera(btVector3(15, 15, 15), btVector3(0, 3, 0), math.rad(45))
