--
--  Bolts and Nuts v1.9.5 OpenSCAD Library
--
--  Copyright (C) 2015 Cristiano Gariboldo - Pixel3Design.it
--
--  License:: GPL
--
-- http://www.thingiverse.com/thing:965737
--

local nutsnbolts  = require "scad/nutsnbolts"
local color       = require "color"
local trans       = require "scad/trans"
local common      = require "common"

v.pre_sdl = [==[

#include "colors.inc"
#include "textures.inc"
#include "metals.inc"

#include "rspd_jvp.inc"  // material samples

#include "lightsys.inc"
#include "lightsys_constants.inc"
#include "lightsys_colors.inc"

#declare use_blur  =50;  // blur samples (0=off)
#declare use_norm   =1;  // use micro-normals?
#declare r_l=seed(132);  // random light placement seed 
#declare use_area   =0;  // use area lights?
#declare hf_res  =1000;  // hf resolution

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


// *************************
// *** OLD BRUSHED METAL ***
// *************************
// + microsurface normal
#declare p_micro2=
pigment{
 crackle turbulence 1
 color_map{
  [0.00 White*.7]
  [0.01 White*.7]
  [0.02 White]
  [1.00 White]
 }
 scale 5
}
#declare p_micro1=
pigment{
 cells
 turbulence .5
 color_map{
  [0.0 White*.9]
  [1.0 White]
 }
 scale .01
}
// + average all the normals
#declare p_brushed_new=
pigment{
 average turbulence 0
 pigment_map{
  [0.0 p_micro1]
  [0.1 p_micro1 rotate 45*x]
  [0.2 p_micro1 rotate -45*x]
  [0.3 p_micro2]
  [0.4 p_micro1 rotate 45*y]
  [0.5 p_micro1 rotate -45*y]
  [0.6 p_micro1 rotate 90*z]
  [0.7 p_micro2 rotate 45]
  [0.8 p_micro1 rotate 45*z]
  [0.9 p_micro1 rotate 90*y]
  [1.0 p_micro1 rotate -45*z]
 }
 scale .1
}

// + declare the final normal as image_pattern
#declare n_brushed_new=
normal{pigment_pattern{p_brushed_new} .4}
// + declare the final metal texture
#declare t_metal=
texture{
 pigment{
//  rgb ReflectiveSpectrum(RS_BoltMetal2)
//  rgb ReflectiveSpectrum(RS_Nickel1)
//  rgb ReflectiveSpectrum(RS_NickelBrass1)
  rgb ReflectiveSpectrum(RS_NordicGold1)
//  rgb ReflectiveSpectrum(RS_Iron)
//  rgb ReflectiveSpectrum(RS_StainlessSteel1)
 }
 finish{
  Metal
 }
 #if (use_norm)
 normal{n_brushed_new .5}
 #end
}

// ground 
#declare RasterScale = 1.0 ;
#declare RasterHalfLine  = 0.045;
#declare RasterHalfLineZ = 0.045;

#macro Raster(RScale, HLine)
   pigment{ gradient x scale RScale
            color_map{[0.000   color rgbt<1,1,1,1>*0.6]
                      [0+HLine color rgbt<1,1,1,1>*0.6]
                      [0+HLine color rgbt<1,1,1,1>]
                      [1-HLine color rgbt<1,1,1,1>]
                      [1-HLine color rgbt<1,1,1,1>*0.6]
                      [1.000   color rgbt<1,1,1,1>*0.6]} }
   finish { ambient 0.15 diffuse 0.85}
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
  scale 4
 }
 translate 125*y
}
plane{y,0.1
 hollow
 pigment{checker color p_mortar color p_mortar*.1 scale 50}
}
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
 translate <0,0,2>
}

]==]


p = Plane(0,1,0,0,100)
p.pos = btVector3(0,0,0)
p.col = color.darkgray
v:add(p)

function bolts() 
  for i = 6,10 do
    o = nutsnbolts.new({
      fun  = "conical_allen_bolt (20, 3, 6, 4, 0.2, 32, \"metric\", 1, 2.5, 10, 0.4);",
    mass = 1 })

    o.trans = common.transform(
      math.random() * 2 * math.pi, math.random() * 2 * math.pi, math.random() * 2 * math.pi,
      math.random() * 80 - 40, 16 + i * 8, math.random() * 60 - 30)
    o.col = color.random_pastel()
    o.sdl = [[
      texture{ t_metal }
    ]]
    v:add(o)
  end
end

bolts();

common.setCamera(btVector3(250, 300, 1000), btVector3(-233834, -271237, -932527), nil,
                 { up = btVector3(-0.0660439, 0.962428, -0.263383),
                   focal_blur = 0, focal_aperture = 5 })
