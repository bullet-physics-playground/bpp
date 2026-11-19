// ************************************************************
// Persistence Of Vision Ray Tracer Scene Description File
// File name  : studio-light-to-hdr.pov
// Version    : POV-Ray 3.7
// Description: Tool to generate HDRI probes from SLK setups.
// Date       : Feb-2013
// Author     : Jaime Vives Piqueres
// Note       : remember to switch on HDR/EXR output!
// ************************************************************
#include "colors.inc"


// *** control center ***
#declare use_blur    =7*0;  // blur samples (0=off)
#ifndef(use_radiosity) // pass this variable on the command line with the apropiate value depending on +RFO/+RFI
  #declare use_radiosity =1;  // 0=off, 1=load pass , 2=save pass
#end
#declare rad_brightness=1;  
global_settings{
 assumed_gamma 1.0
 #if (use_radiosity)
   #include "rad_def.inc"
   radiosity{Rad_Settings(Radiosity_IndoorHQ, off, off)}
   //radiosity{Rad_Settings(Radiosity_OutdoorHQ, off, off)}
 #end
}
#default{texture{finish{ambient 0}}}


// Include CIE color transformation macros by Ive
// needed by the Studio Lighting Kit
#include "bpp_CIE.inc"
CIE_ColorSystemWhitepoint(sRGB_ColSys, Illuminant_D65)
#include "bpp_lightsys.inc" 
#include "bpp_lightsys_constants.inc" 
#declare Lightsys_Brightness=.02; // adjust for a brighter/dimmer hdr


// *** STUDIO LIGHTING KIT ***
#include "i_studio_room.inc"     // generic room
#include "i_studio_lighting.inc" // studio lights and accesories
#declare predefined_studio_setup=1; 
#include "i_studio_sets.inc"     // studio set up example (1-5)


// **************
// *** camera ***
// **************
// spherical camera used to generate HDR maps
camera{
 spherical
 up y right 2*x
 location <0,0,-1>
 look_at <0,0,0>
 #if (use_blur)
 focal_point 0
 aperture .1
 blur_samples use_blur
 #end
 translate 80*y
}
