hcw = require "module/hcw"

v:add(hcw.new({fn = 25, mass = 0}))

v.cam:setFieldOfView(0.25)
v.cam:setUpVector(btVector3(0,1,0), true)
v.cam:setHorizontalFieldOfView(0.003)
v.cam.pos  = btVector3(20000,10000,35000)
v.cam.look = btVector3(0,0,0) 

v.cam.focal_blur      = 0
v.cam.focal_aperture  = 5
v.cam.focal_point = btVector3(0,0,0)
