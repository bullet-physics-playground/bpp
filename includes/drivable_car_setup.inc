#include "colors.inc"
#include "textures.inc"
#include "glass.inc"
#include "metals.inc"
#include "rad_def.inc"
#include "functions.inc"
#include "transforms.inc"

// *** CONTROL CENTER ***
#declare use_radiosity=0;   // 0=off, 1=on
#declare use_final_text=1;   // use final textures (0=test textures)
#declare use_blur=0;         // # of samples (0=off)
#declare use_area=0;         // 0=off, 1=on
#declare rad_brightness=1; // radiosity brightness

// *** GLOBAL ***
global_settings{
 max_trace_level 6  // for the glass sheets
 assumed_gamma 1.5  // raised a bit for outdoor
 #if (use_radiosity>0)
   radiosity{Rad_Settings(Radiosity_OutdoorLQ, off, off)}
 #end
}
#default{texture{finish{ambient 0}}}

// *****************
// *** SUN & SKY ***
// *****************
// CIE & LIGHTSYS 
#include "CIE.inc"
#include "lightsys.inc"          
#include "lightsys_constants.inc" 
#declare Lightsys_Brightness=.75; 
// sun position
#declare r_sun=seed(54);
#declare Al=20+30*rand(r_sun);
#declare Az=360*rand(r_sun);
#declare North=<-1+2*rand(r_sun),0,-1+2*rand(r_sun)>;
// Skylight parameters
#declare Intensity_Mult=1;
#declare Current_Turbidity=3;
#declare Max_Vertices=800;
//#include "CIE_Skylight"
// LightSys based sun to replace skylight SunColor
#declare lct=4000+2500*Al/90; 
#declare lc=Daylight(lct);
light_source{
  0, Light_Color(lc,2*Intensity_Mult)
  #if (use_area)
    area_light 4000*x,4000*z,4,4 jitter adaptive 1 orient circular
  #end
  translate SolarPosition // from Skylight
}

// ***********************************************
// setup the objects used on the simulation export
// ***********************************************

#include "i_micra_k11.inc"

// car parts
#declare front_axe=
cylinder{
  -2*z,2*z,.5
}
#declare rear_axe=
cylinder{
  -2*z,2*z,.5
}
#declare t_paint=
texture{
  pigment{SlateBlue*.5+NavyBlue*.5}
  finish{specular albedo .1 roughness .005 reflection{.01,.25}}
}
#include "i_citroen_gs.inc"
#declare citroen_gs=object{jvp_citroen_gs(t_paint,20)
 scale 10*<-1,1,1>
 rotate 90*y
 translate <-3,-4,0>
 }
#declare gs_tyre=object{wheel(1,0) scale .1 rotate 90*y}

// ground
#declare ground=
plane{y,0
  pigment{Gray20}
}

// ground mrks
#declare r_marks=seed(2543);
#declare t_marks_paint=
texture{
  pigment{Orange*.5+Yellow*.5}
}
#macro track_mark()
box{-.5,.5
  scale <5,.01,1>
  texture{t_marks_paint
  }
}
#end

// obstacle
#declare ramp=
box{-.5,.5
  scale <30,.01,30>
  pigment{Orange}
}

#declare disk=
box{-1,1 // invisible
  no_shadow
  no_reflection
  no_image
  no_radiosity
}

#declare spindle=
box{-1,1 // invisible
  no_shadow
  no_reflection
  no_image
  no_radiosity
}

#declare control_arm=
box{-1,1 // invisible
  no_shadow
  no_reflection
  no_image
  no_radiosity
}

// these additional scenery objects were not on the simulation

/*
box{-.5,.5
  scale <1,50,1000>  
  pigment{Gray}
  translate <-100,25,0>
}
box{-.5,.5
  scale <1000,50,1>  
  pigment{Gray}
  translate <400,25,-40>
}
box{-.5,.5
  scale <1,50,1000>  
  pigment{Gray}
  translate <800,25,0>
}*/
