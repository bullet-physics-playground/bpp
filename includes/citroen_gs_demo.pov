// **********************************************************
// Persistence Of Vision Ray Tracer Scene Description File
// File name  : citroen_gs_demo.pov
// Version    : 3.6.1
// Description: simple test scene for my Citroen GS model
// Date       : Jul-Oct. 2005
// Author     : Jaime Vives Piqueres
// Note	      : Two pass radiosity!
// **********************************************************
// Rendering notes: 
// + To get a quick preview, just render with the defaults:
// 	use_radiosity=0;
//	use_final_text=1;
//      use_blur=0;
//      use_area=0;
// + To save radiosity, just set:
//	use_radiosity=1;
//      use_final_text=0;
// + To load radiosity for the final render:
//      use_radiosity=2;
//	use_final_text=1;
//   and optionally:
//      use_blur=number_of_samples (recommended >35); 
//      use_area=1; 
// **********************************************************

// *** REQUIRED STANDARD INCLUDES ***
#include "colors.inc"
#include "textures.inc"
#include "metals.inc"
#include "glass.inc"
#include "functions.inc"

	
// *** CONTROL CENTER ***
#declare use_radiosity=0;    // 0=off, 1=first pass (save), 2=second pass (load)
#declare use_final_text=1;   // use final textures (0=test textures)
#declare use_blur=0;         // # of samples (0=off)
#declare use_area=0;         // 0=off, 1=on
#declare rad_brightness=1.5; // radiosity brightness
// camera params for the car paint (also used for the camera)
#declare clo=<6,2.1,2.5>;    // location
#declare cla=<-1.2,.2,0>;    // look_at


// *** GLOBAL ***
global_settings{
 max_trace_level 6  // for the glass sheets
 assumed_gamma 1.5  // raised a bit for outdoor
 #if (use_radiosity>0)
  radiosity{#include "i_rad.inc"}
 #end
}
#default{texture{finish{ambient 0}}}


// *****************
// *** SUN & SKY ***
// *****************
// CIE & LIGHTSYS 
#include "bpp_CIE.inc"
#include "bpp_lightsys.inc"          
#include "bpp_lightsys_constants.inc" 
#declare Lightsys_Brightness=.75; 
// sun position
#declare r_sun=seed(544);
#declare Al=20+30*rand(r_sun);
#declare Az=360*rand(r_sun);
#declare North=<-1+2*rand(r_sun),0,-1+2*rand(r_sun)>;
// Skylight parameters
#declare Intensity_Mult=2;
#declare Current_Turbidity=3;
#declare Max_Vertices=800;
#include "bpp_CIE_Skylight"
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


// *********************
// *** WALLS & FLOOR ***
// *********************
// scenery textures
#declare t_wall=
texture{
 pigment{brick color White*.5 color Firebrick*.5+Orange*.1+Gray10}
 normal{brick}
 scale .015
}
#declare t_floor=
texture{
 pigment{checker color White*.5 color Gray10} 
 scale .25 
 translate .1*x
}
// simple scenery
plane{y,0
#if (use_final_text)
 texture{t_floor rotate 90*x scale 3}
#else
 pigment{Gray}
#end
}
#declare wall=
box{-.5,.5 scale <.5,4,10>
 #if (use_final_text)
  texture{t_wall translate -.5 rotate 90*y scale 4}
 #else
  pigment{Gray}
 #end
}
object{wall translate <-3,2,0>}
object{wall translate <8,2,0>}
object{wall rotate 90*y translate <0,2,10>}
object{wall rotate 90*y translate <2,2,-10>}


// ******************
// *** Citroen GS ***
// ******************
// required includes
#include "i_car-paints.inc"
#include "i_citroen_gs.inc"
// 1) custom colors for paints:
#declare c1=Blue*.75+Green*.25; #declare c2=Black; // for metallic blackened
//#declare c1=Red*.5; #declare c2=Blue*.5; // for metallic bicolor
//#declare c1=Gray; #declare c2=SteelBlue*.5;// for metallic pearlish
//#declare c1=Brass*.5; #declare c2=c1; // for simple metallic or plain paint
// 2) texture with paint colors and predefined finish macros
#if (use_final_text)
 #declare t_custom_paint=
 metallized_paint(c1,c2,cv,f_matte,f_varnish)  // metallized paint
 //texture{ pigment{c1} finish{f_varnish}}  // plain paint
#else 
 #declare t_custom_paint=texture{pigment{Gray}}
#end
// 3) create and place the car:
#declare car=object{jvp_citroen_gs(t_custom_paint,20)}
object{car rotate (25)*y translate -.025*y}


// **************
// *** camera ***
// **************
#if (use_blur)
// trace to find the focal point (sort of autofocus)
#declare Norm = <0, 0, 0>; 
#declare Inter=trace(car, clo, cla-clo, Norm ); 
#end
#declare cd=.005*z;
camera{
 location clo
 up .0024*y
 right .0036*x
 direction cd
 look_at cla
 #if (use_blur)
 focal_point Inter
 aperture .125
 blur_samples use_blur
 #end
}

