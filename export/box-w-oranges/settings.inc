/*
  A box of Oranges 
  --
  Jaime Vives Piqueres, Oct-2012
   
  POV-Ray rendering of the demonstration LUA script included into Koppi's
  Bullet Physics Playground
  
  The included image map textures are from www.mayang.com/textures

*/
#version 3.7;
#include "colors.inc"
#include "textures.inc"
#include "transforms.inc"
#include "rad_def.inc"

// *** CONTROL CENTER ***
#declare use_area = 0;
#declare use_blur =7*0;  // blur samples (0=off)
#declare n_blades=50000*.1; // number of grass blades (use as many as you can afford, of course)
global_settings{
  assumed_gamma 1.0
  //radiosity{Rad_Settings(Radiosity_OutdoorHQ, off, off)}
  radiosity{Rad_Settings(Radiosity_OutdoorLQ, off, off)}
}
#default{texture{finish{ambient 0 emission 0 diffuse 1}}}

// *** ISOSURFACE ORANGE ***
#include "isorange.inc"

// *** WOODEN FRUITS BOX ***
#include "fruits_woodbox.inc"

// *** TERRAIN WITH GRASS ***
#include "grassy_bank.inc"

// *** SKY AND SUNLIGHT ***
#include "CIE.inc"
#declare Lightsys_Scene_Scale=1;
#include "lightsys.inc"
#include "lightsys_constants.inc"
#declare Cl_Daylight =Daylight(6500);
#declare Cl_Skylight =Daylight(7500);
#declare Lightsys_Brightness=.75;
#declare r_sun=seed(990);
#declare North=z; #declare Az=360*rand(r_sun); #declare Al=5+55*rand(r_sun);
#declare Intensity_Mult=1; // brightness of the sky dome and sunlight
#declare fiLuminous=finish{ambient 0 emission 1 diffuse 0 specular 0 phong 0 reflection 0 crand 0 irid{0}}
#declare Max_Vertices=1000;
#include "CIE_Skylight"
#declare Cl_Sunlight =Daylight(4000+3000*Al/90);
light_source{
  SolarPosition
  Light_Color(Cl_Sunlight,SunColor.gray*2)
  parallel
  #if (use_area)
    area_light 5000*x,5000*z,5,5 jitter adaptive 1 orient circular
  #end
}
