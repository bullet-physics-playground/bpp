--
-- Parametric involute bevel and spur gears
--
-- http://www.thingiverse.com/thing:3575
--

require "module/color"
require "module/gearsv50"

v.timeStep      = 1/15
v.maxSubSteps   = 100
v.fixedTimeStep = 1/100

v.pre_sdl = [[

#include "textures.inc"
#include "metals.inc"

object {
  Light(
    EmissiveSpectrum(ES_GE_SW_Incandescent_100w),
    Lm_Incandescent_100w,
    x*25, z*25, 4, 4, on
  )
  translate <200, 400, 50>
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
  scale 1
  rotate 90*x
 }
 finish { F_MetalC reflection{1*.5,1*.75} }
 scale 10
}

]]

v.gravity = btVector3(0,-980.1, 0)

plane = Plane(0,1,0,0,1000)
plane.friction = 1
plane.col = "#ffffff"
plane.sdl = [[
  pigment { HuntersGreen }
  normal  { quilted scale 2 }
]]
v:add(plane)

function gear1(pitch, mass)
  g = gearsv50.new({fun=[[
  gear(
    circular_pitch=]]..tostring(pitch)..[[,
    gear_thickness = 12,
    rim_thickness = 15,
    hub_thickness = 17,
    circles=8
);]], mass = mass})
  return g
end

function gears1() 
  for i = 0,5 do
    g = gear1(500+i*100, 1)
    g.friction = 10
    g.pos = btVector3(8+i*i*9,12,-70)
    g.col = color.random_pastel()
    g.sdl = [[
      texture{ t_metal_copper }
    ]]
    v:add(g)
--   print(g)
  end
end

gears1()

function gear2(pitch, teeth, mass)
  g = gearsv50.new({fun=[[
  gear(
    circular_pitch=]]..tostring(pitch)..[[,
    number_of_teeth=]]..tostring(teeth)..[[,
    hub_diameter=0,
rim_width=65
);]], mass = mass})
  return g
end

function gears2() 
  for i = 0,5 do
    g = gear2(500, 6+i*2, 1)
    g.friction = 10
    g.pos = btVector3(8+i*i*9,12,-10)
    g.col = color.random_pastel()
    g.sdl = [[
      texture{ Polished_Chrome }
    ]]
    v:add(g)
  end
end

gears2()

v.cam:setUpVector(btVector3(0,1,0), true)
v.cam:setHorizontalFieldOfView(0.4)
v.cam.pos  = btVector3(500,600,500)
v.cam.look = btVector3(190,80,0) 

v.cam.focal_blur      = 0
v.cam.focal_aperture  = 5
v.cam.focal_point = btVector3(0,0,0)