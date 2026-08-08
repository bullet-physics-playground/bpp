--
-- btConeTwistConstraint demo
-- Based on bullet3 ConstraintDemo.cpp ConeTwist example
--

plane = Plane(0,1,0,0,10)
plane.col = "#222222"
v:add(plane)

cube = Cube(1,5,1,1)
cube.pos = btVector3(0, 0, 0)
cube.col = "#ff6600"
v:add(cube)

link = Sphere(1,10)
link.pos = btVector3(1, 1, 0)
link.col = "#444444"
v:add(link)

local common = require "common"

frameInA = common.transform(0, 0, math.pi / 2, 0, -3.5, 0)
frameInB = common.transform(0, 0, math.pi / 2, 0, 0, 0)

con = btConeTwistConstraint(
  cube.body, link.body,
  frameInA, frameInB)

con:setLimit(3, math.pi * 0.8)
con:setLimit(4, math.pi * 0.25)
con:setLimit(5, math.pi * 0.8)

v:addConstraint(con)

common.setCamera(btVector3(0, 8.1552, 45.2607), btVector3(0, 8.1552, -999955))

-- EOF