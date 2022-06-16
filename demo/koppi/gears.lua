--
-- Parametric involute bevel and spur gears
--
-- http://www.thingiverse.com/thing:3575
--

color = require "module/color"
gearsv50 = require "module/gearsv50"

v.timeStep      = 1/25
v.maxSubSteps   = 60
v.fixedTimeStep = 1/50

v.pre_sdl = [[

#include "textures.inc"
#include "metals.inc"

sky_sphere {
  pigment {
    gradient y
    color_map {
      [0.0 rgb ReferenceRGB(<0.6,0.7,1.0>*Lightsys_Brightness) ]
      [0.7 rgb ReferenceRGB(<0.0,0.1,0.8>*Lightsys_Brightness) ]
    }
  }
}

object {
  Light(Daylight(5500), 300, x*70, z*70, 4, 4, off)
  translate <0, 50, 100>
}

#declare n_scratchs =
normal{
 bump_map {png "hf_scratch2"}
}

#declare t_metal_copper =
texture {
  pigment{ rgb Copper }
  normal {
  wrinkles turbulence .1
  normal_map {
    [0 n_scratchs]
    [1 n_scratchs translate .5 scale .5]
  }
  scale 25
  rotate 90*x
 }
 finish { Metal ambient 0 reflection{.1,.9} }
}
]]

plane = Plane(0,1,0,0,1000)
plane.friction = 1
plane.col = "#111"
plane.sdl = [[
  pigment { color ReferenceRGB(<0.9,0.8,0.3>) }
]]

v:add(plane)

function gear2(pitch, teeth, mass)
  g = gearsv50.new({fun=[[
  gear(
    circular_pitch=]]..tostring(pitch)..[[,
    number_of_teeth=]]..tostring(teeth)..[[,
    hub_diameter=10, rim_width=7
);]], mass = mass})
  return g
end

c1 = Cylinder(2.25,17,0)
c1.pos = btVector3(0, 15, 0);
c1.col = "#ccc"
v:add(c1)

pitch = 500
mass = 1

g1 = gear2(pitch, 6, mass)
g1.friction = 0.11
g1.pos = btVector3(0,15,0)
g1.col = color.random_google()
g1.sdl = [[
  texture{ t_metal_copper }
]]
v:add(g1)

pivot0 = btVector3(0,0,0)
axis0  = btVector3(0,0,1)

pivot1 = btVector3(0,0,0)
axis1  = btVector3(0,0,1)

con0 = btHingeConstraint(
  c1.body, g1.body,
  pivot0, pivot1, axis0, axis1)

con0:enableAngularMotor(true, 4, 50000)

v:addConstraint(con0)

function gs(teeth, x, y, z)
  c2 = Cylinder(2.25,17,0)
  c2.pos = btVector3(x, y, z);
  c2.col = "#ccc"
  v:add(c2)

  g2 = gear2(pitch, teeth, mass)
  g2.friction = 0.1
  g2.pos = btVector3(x,y,z)
  g2.col = color.random_pastel()
  g2.sdl = [[
  texture{ t_metal_copper }
]]
  v:add(g2)

  pivot2 = btVector3(0,0,0)
  axis2  = btVector3(0,0,1)

  pivot3 = btVector3(0,0,0)
  axis3  = btVector3(0,0,1)

  con1 = btHingeConstraint(
    c2.body, g2.body,
    pivot2, pivot3, axis2, axis3)

  v:addConstraint(con1)
end

gs(10, 21.5, 17, 0)
gs(26, 56.5, 53, 0)
gs(14, 0, 53, 0)
gs(8, 0, 84, 0)
gs(6, 0, 103, 0)
gs(26, -56.5, 53, 0)
gs(26, 0, 147, 0)

v.cam:setUpVector(btVector3(0,1,0), false)
v.cam:setHorizontalFieldOfView(0.0075)
v.cam.pos  = btVector3(-10000,10000,35000)
v.cam.look = btVector3(0,95,0) 

v.cam.focal_blur      = 0
v.cam.focal_aperture  = 5
v.cam.focal_point = btVector3(0,0,0)