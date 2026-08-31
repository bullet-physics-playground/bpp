// ************************************************************
// Persistence Of Vision Ray Tracer Scene Description File
// File name  : studio-light-demo.pov
// Version    : POV-Ray 3.7
// Description: Demo showing usages of the Studio Lighting Kit.
// Date       : Feb-2013
// Author     : Jaime Vives Piqueres
// ************************************************************
// Rendering notes : aspect ratio 3/4 !!!
#version 3.7;

// *** standard includes ***
#include "colors.inc"

// *** control center ***
#declare demo_mode     =1;  // 1=direct, 2=HDRI
#declare use_blur    =7*0;  // blur samples (0=off)
#ifndef(use_radiosity) // pass this variable on the command line with the apropiate value depending on +RFO/+RFI
  #declare use_radiosity =1;  // 0=off, 1=load pass , 2=save pass
#end

// *** global ***
global_settings{
 assumed_gamma 1.0
 #if (use_radiosity)
   #include "rad_def.inc"
   radiosity{Rad_Settings(Radiosity_IndoorHQ, off, off)}
   //radiosity{Rad_Settings(Radiosity_OutdoorHQ, off, off)}
 #end
}
#default{texture{finish{ambient 0}}}


// *************************
// *** direct usage demo ***
// *************************
// uses ligthsys and the studio lighting kit includes
#if (demo_mode=1) 

// Include CIE color transformation macros by Ive
// needed by the Studio Lighting Kit
#include "bpp_CIE.inc"
CIE_ColorSystemWhitepoint(sRGB_ColSys, Illuminant_D65)
#include "lightsys.inc" 
#include "lightsys_constants.inc" 
#declare Lightsys_Brightness=.015; // adjust for brighter/dimmer radiosity on the first pass, and for brighter/dimmer reflections on the second pass

// *** STUDIO LIGHTING KIT ***
#include "i_studio_room.inc"     // generic room
#include "i_studio_lighting.inc" // studio lights and accesories
// studio set up examples (1-6)
#declare predefined_studio_setup=1;  // select predefined setup
#include "i_studio_sets.inc"     

#end // direct demo usage


// ***********************
// *** HDRI usage demo ***
// ***********************
// uses .hdr generated with studio-light-to-hdr.pov
#if (demo_mode=2)

sphere {
  0,1
  pigment { 
   image_map {
    hdr "studio-light-to-hdr" once interpolate 2 map_type 1
   } 
  }
  finish { emission .5 diffuse 0} // adjust emission for each .hdr
  scale <-1,1,1>*300 rotate -90*y
  hollow
}

#end // HDRI usage demo


// *******************************************
// *** common demo product on the backdrop ***
// *******************************************
#declare t_backdrop1=
texture{
 pigment{
  wrinkles
  color_map{
   [0 White]
   [1 SkyBlue]
  }
 }
 scale .25
}
#declare t_backdrop2=
texture{
 pigment{Gray10} 
 #if (use_radiosity<2)
 finish{reflection{.1,.33}}
 #end
}
//#declare t_backdrop=t_backdrop1
#include "i_studio_backdrop.inc" // curved studio backdrop
object{backdrop scale 60 translate 80*y}
#include "i_demo_subjects.inc"  // simple demo products
object{demo_products translate 80*y}


// **************
// *** camera ***
// **************
#declare cl=<1,45,-95>;
#declare cd=5*z; 
#declare la=<-4,17,0>;
camera{
 location cl
 up 3.2*y right 2.4*x
 direction cd
 look_at la
 #if (use_blur)
 focal_point la-12*z
 aperture pi*2
 blur_samples use_blur
 #end
 translate 80*y
}
