--
-- btGeneric6DofSpringConstraint demo
--

plane = Plane(0,1,0,0,10)
plane.col = "#222222"
v:add(plane)

cube = Cube(1,2,1,1)
cube.pos = btVector3(0, 5, 0)
cube.col = "#444444"
v:add(cube)

link = Cube(1,2,1,1)
link.col = "#ff6600"
v:add(link)

local common = require "common"

frameInA = common.transform(0, 0, 0, 0, 1, 0)
frameInB = common.transform(0, 0, 0, 0, -1, 0)

con = btGeneric6DofSpringConstraint(
  cube.body, link.body,
  frameInA, frameInB,
  true)

con:setLinearUpperLimit(btVector3(1, 0, 0))
con:setLinearLowerLimit(btVector3(-1, 0, 0))

con:setAngularLowerLimit(btVector3(0, 0, -1.5))
con:setAngularUpperLimit(btVector3(0, 0, 1.5))

con:enableSpring(4, true)
con:setStiffness(5, 50)
con:setDamping(5, 0.3)

con:setEquilibriumPoint()

v:addConstraint(con)

common.setCamera(btVector3(-21.5418, 41.0771, 26.8821),
                 btVector3(404757, -735820, -542801), nil,
                 { up = btVector3(0.497141, 0.675332, -0.544773) })

-- EOF