--
-- BRIO bricks train
--

require "module/color"
require "module/brio"

v.timeStep      = 1/2
v.maxSubSteps   = 100
v.fixedTimeStep = 1/5

v.pre_sdl =  [[
#include "textures.inc"
#include "finish.inc"

#declare F_Wood = finish {
  ambient   0
  diffuse   1
  specular  1
  roughness 0.02 
  reflection { 0,1 fresnel }
}

#declare T_Wood = texture {
  pigment {Tan_Wood} 
  finish { F_Wood }
}

]]

p = Plane(0,1,0,0,1250)
p.col = "#000"
p.sdl = [[ pigment { color Black } ]]
p.friction = 10
v:add(p)

tex = "texture{ Yellow_Pine rotate y*90 scale 10 }"

b = brio.new({ cmd = "brio_straight(LENGTH/2);", mass = 0  })
b.pos = btVector3(-110,0,0)
b.trans = btTransform(btQuaternion(0,1,0,1), btVector3(320,0,34))
b.friction = 10
b.sdl = tex
v:add(b)

b = brio.new({ cmd = "brio_straight(LENGTH-40);", mass = 0  })
b.pos = btVector3(-110,0,0)
b.trans = btTransform(btQuaternion(0,0,0,1), btVector3(-70,0,0))
b.friction = 10
b.sdl = tex
v:add(b)

c = brio.new({ cmd = "brio_cross(LENGTH/2);", mass = 0 })
c.pos = btVector3(-120,0,-20)
c.friction = 10
c.sdl = "texture{ Yellow_Pine rotate x*90 rotate y*90 scale 10 }"
v:add(c)

bridge1 = brio.new({ cmd = "brio_bridge();", mass = 0  })
bridge1.pos = btVector3(300,0,-40)
bridge1.friction = 10
bridge1.sdl = tex
v:add(bridge1)

bridge2 = brio.new({ cmd = "rotate([0,0,180])brio_bridge();", mass = 0  })
bridge2.pos = btVector3(300,0,0)
bridge2.friction = 10
bridge2.sdl = tex
v:add(bridge2)

tex = "texture{ Yellow_Pine rotate x*90 scale 30 }"

bridge3 = brio.new({ cmd = "brio_curved(ROUND_R, 2);", mass = 0  })
bridge3.trans = btTransform(btQuaternion(0,0,0,1), btVector3(-99,0,-70))
bridge3.friction = 10
bridge3.sdl = tex
v:add(bridge3)

bridge3 = brio.new({ cmd = "brio_curved(ROUND_R, 2);", mass = 0  })
bridge3.trans = btTransform(btQuaternion(0,1,0,0), btVector3(279,0,35))
bridge3.friction = 10
bridge3.sdl = tex
v:add(bridge3)

s = Sphere(10,1)
s.pos = btVector3(260,65,-35)
s.col = "#ff0000"
v:add(s)

v.cam:setFieldOfView(0.25)

v:preDraw(function(N)
--  v.cam.up   = btVector3(0,1,0)
--  v.cam.pos  = btVector3(2002,130,1700)
--  v.cam.look = b.pos - btVector3(0,-0.5,0)
end)

