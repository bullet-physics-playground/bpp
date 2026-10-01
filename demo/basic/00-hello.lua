--
-- Demo of basic BPP objects and functions
--
-- This demo shows how to create basic geometric objects:
-- Plane, Cube, Cylinder, Sphere, and OpenSCAD-generated shapes.
-- It also demonstrates callback functions like preStart, preStop,
-- preSim, postSim, preDraw, postDraw, and onCommand.
--
-- Usage: bpp -f demo/basic/00-hello.lua
--

-- Load the color module for predefined color names
local color  = require "color"
local common = require "common"
-- Load OpenSCAD geodesic sphere module
local gs    = require "scad/geodesic_sphere"
-- Load the RGB XYZ origin marker module
local origin = require "origin"

-- Set simulation timing: 25 fps, up to 120 substeps, 1/60s fixed timestep
common.setTiming(1/25, 120, 1/60)

-- Add parameters accessible from GUI
v:addParam("sphereColor", "red", "name of the sphere's color")
v:addParam("geoSphereColor", "gold", "name of the OpenSCAD geodesic sphere's color")
v:addParam("cubeMass", 1.0, "mass of the falling cube, in kg")
v:addParam("sphereMass", 1.0, 0.1, 5, 0.1, "mass of the sphere, in kg")
v:addParam("enableGravity", true, "toggle gravity on/off")
v:addParam("gravityStrength", 9.8, 0, 20, 0.5, "gravity magnitude, in m/s^2 (only applied while enableGravity is on)")
v:addParam("focalAperture", 1, 0, 20, 0.5, "camera depth-of-field aperture (0 = no blur)")
v:addParam("cam.fov", 0.03, 0.01, 0.1, 0.005, "camera field of view")

v.pre_sdl = [[

#include "colors.inc"
#include "textures.inc"
#include "metals.inc"

#declare use_area   =0;  // use area lights?
#declare hf_res  =1000;  // hf resolution
#declare r_l=seed(132);  // random light placement seed 

global_settings{
  ambient_light 0.0
  assumed_gamma 1.0
}

// ********************
// *** CIE+lightsys ***
// ********************
#include "bpp_CIE.inc"
#declare ColSys=sRGB_ColSys;
//CIE_ColorSystemWhitepoint(ColSys,Illuminant_A)
CIE_ColorSystemWhitepoint(ColSys,Blackbody2Whitepoint(4000))
//CIE_ColorSystemWhitepoint(ColSys,Daylight2Whitepoint(5500))
#include "rspd_jvp.inc" // material samples

#include "bpp_lightsys.inc"
#include "bpp_lightsys_constants.inc"
#include "bpp_lightsys_colors.inc"
#declare Lightsys_Brightness=1; 


// *******************
// *** build lamps ***
// *******************
#declare fl_lm=2000;
// + lamp object
#macro sheet(cl)
box{-.5,.5
 material{
  texture{
   pigment { color rgbf<1, 1, 1, 1> }
   finish {  diffuse 0 }
  }
  interior{
   media {
    method 1
    emission cl
    intervals 10
    samples 1, 10
    confidence 0.9999
    variance 1/1000
   }
  }
 }
 hollow
 no_shadow
}
#end
#macro bulb(cl)
sphere{0,.5
 material{
  texture{
   pigment { color rgbf<1, 1, 1, 1> }
   finish {  diffuse 0 }
  }
  interior{
   media {
    method 1
    emission cl
    intervals 10
    samples 1, 10
    confidence 0.9999
    variance 1/1000
   }
  }
 }
 hollow
 no_shadow
}
#end

// + build the lamps 
// try changin the r_l seed to find interesting lighting situations
union{
 Light(Cl_Incandescent_60w,400,<9,0,0>,<0,0,9>,4*use_area,4*use_area,1)
 object{bulb(Cl_Incandescent_60w)scale <2,3,2>}
 translate (-200+400*rand(r_l))*z
 translate (250*rand(r_l))*y
 rotate 360*rand(r_l)*y
}
#if (rand(r_l)>.5)
union{
 Light(Cl_Cool_White_Fluor,900,<48,0,0>,<0,0,48>,6*use_area,6*use_area,1)
 object{sheet(Cl_Cool_White_Fluor*900)scale <24,.1,3> translate .9*y}
 translate (-200+400*rand(r_l))*z
 translate (-200+400*rand(r_l))*x
 translate (250*rand(r_l))*y
}
#else
union{
 Light(Cl_SI_D65,3000,<100,0,0>,<0,0,100>,6*use_area,6*use_area,1)
 object{sheet(Cl_SI_D65*2000)scale <100,.1,100> translate .9*y}
 rotate -90*x
 translate (-249)*z
 translate (250*rand(r_l))*y
 rotate 360*rand(r_l)*y
}
#end

// *****************
// *** test room ***
// *****************
#declare p_mortar=rgb ReflectiveSpectrum(RS_ConstrStone2);
#declare p_brick =rgb ReflectiveSpectrum(RS_ConstrStone3);
box{-.5,.5
 hollow
 scale <500,250,500>
 pigment{brick 
  color p_mortar color p_brick
  scale 2
 }
 translate 125*y
}
//plane{y,1
// hollow
// pigment{checker color p_mortar color p_mortar*.1 scale 50}
//}
plane{y,249.9
 hollow
 pigment{rgb ReflectiveSpectrum(RS_White_Paint_1)}
}

// *** table ***
// - pigment for the table hf function -
#declare p_hf=
pigment{
 brick color 1 color rgb 0 mortar 2 rotate 90*x scale .001
}
// - height filed table -
#declare table=
height_field{
 function hf_res,hf_res{
  pigment{p_hf}
 }
 water_level 0.1
 translate -.5
 texture{
  pigment{rgb ReflectiveSpectrum(RS_Iron)}
  finish{Metal}
 }
 scale <50,.05,50>
}
object{table
 translate <0,0,0>
}
]]

--
-- SCENE SETUP
--

-- Create a ground plane at y=0, size 5x5 units
p = Plane(0,1,0,0,5)
p.pos = btVector3(0,0,0)
p.col = color.darkgray
v:add(p)

-- Create a cube at position (-2, 0.5, 0)
cu = Cube(1,1,1,1)  -- dimensions 1x1x1, mass 1
cu.col = color.aquamarine
cu.pos = btVector3(-3, 1.5, 0);
v:add(cu)

-- Create a cylinder at position (-1, 0.5, 0)
cy = Cylinder(0.5,1,1)  -- radius 0.5, height 1, mass 1
cy.col = color.brown
cy.pos = btVector3(-1, 0.5, 0)
v:add(cy)

-- Create a sphere at position (1, 0.5, 0)
sp = Sphere(.5,1)  -- radius 0.5, mass 1
sp.col = color.coral
sp.pos = btVector3(1, 0.5, 0)
v:add(sp)

-- Create an OpenSCAD-generated geodesic sphere at position (2, 0.5, 0)
s1 = gs.new({ fun  = "geodesic_sphere(r = 0.5, $fn=6);", mass = 1})
s1.col = color.gold
s1.pos = btVector3(2,0.5,0)
v:add(s1)

-- Add an RGB XYZ origin marker at (0,0,0)
v:add(origin.new(btVector3(0,0,0)))

-- preStart: Called once before simulation starts
v:preStart(function(N)
  print("preStart("..tostring(N)..")")
end)

-- preStop: Called once when simulation stops
v:preStop(function(N)
  print("preStop("..tostring(N)..")")
end)

-- preSim: Called before each physics simulation step
v:preSim(function(N)
  
  sp.col = tostring(v:getParam("sphereColor"))
  s1.col = tostring(v:getParam("geoSphereColor"))

  mass = v:getParam("cubeMass")
  if (mass ~= cu.mass) then
    cu.mass = v:getParam("cubeMass")
  end

  mass = v:getParam("sphereMass")
  if (mass ~= sp.mass) then
    sp.mass = mass
  end

  if v:getParam("enableGravity") then
    v.gravity = btVector3(0, -v:getParam("gravityStrength"), 0)
  else
    v.gravity = btVector3(0, 0, 0)
  end
end)

-- postSim: Called after each physics simulation step
v:postSim(function(N)
  --print("postSim("..tostring(N)..")")
  local aperture = v:getParam("focalAperture")
  v.cam.focal_blur      = (aperture > 0) and 1 or 0
  v.cam.focal_aperture  = aperture
  -- set blur point to sphere shape position
  v.cam.focal_point = sp.pos
end)

-- preDraw: Called before each frame is drawn
v:preDraw(function(N)
--  print("preDraw("..tostring(N)..")")
end)

-- postDraw: Called after each frame is drawn
v:postDraw(function(N)
--  print("postDraw("..tostring(N)..")")
end)

-- onCommand: Called when a command is entered in the GUI
v:onCommand(function(N, cmd)
  print("onCommand("..tostring(N).."): '"..cmd.."'")
  local f = assert(loadstring(cmd))
  f(v)
end)

-- onParamChanged: Called when a parameter value is changed in the GUI
v:onParamChanged(function(N, name, value)
  print("onParamChanged("..tostring(N).."): "..name.." = "..tostring(value))
  if (name == "cam.fov") then
    v.cam:setFieldOfView(tonumber(value))
  elseif (name == "focalAperture") then
    -- postSim only runs while the simulation is stepping, so apply this
    -- immediately too, otherwise it has no effect while paused.
    local aperture = tonumber(value)
    v.cam.focal_blur     = (aperture > 0) and 1 or 0
    v.cam.focal_aperture = aperture
  end
end)

-- EOF
