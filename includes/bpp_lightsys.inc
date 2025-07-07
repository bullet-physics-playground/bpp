/*
  Persistence of Vision Ray Tracer Scene Description File

  LightSysIV : main lighting macros.
  
  Macros to automate the simulation of common illuminants through the use of
  real data for color, intensity and attenuation. Now uses CIE.inc by Ive for 
  the color calculations.

  Jaime Vives Piqueres, Apr-2003.
  
  Changes on version 4b (08/11/09):
  
    + removed all #version statements as they were not necessary, and were generating
    warnings on version 3.7 (jaime, recommended by Ive)
  
  Changes on version 4b (11/24/06):
  
    + New Lightsys_Scene_Scale controls scene scale respect to the fade distance (Jaime)
    + falloff decreased to 89.9 to avoid media artifacts (?!) (Jaime)
    + corrected bug in Light_Color_Filtered() which used .Gray instead .gray (Stefan Sittler)

  Changes on version 4:

    + Global variable WHITE_POINT deprecated. Use CIE.inc white point instead.
    + Global variable BRIGHTNESS renamed to Lightsys_Brightness.
    + Global variable COLOR_FILTER renamed to Lightsys_Filter.
    + Added Lightsys_ExposureFake for an experimental, non-phisically-correct exposure
      control effect.
    + Added new macro Light_Color_Filtered(), used to simulate lights inside filtering
      envelopes (useful to speed up rendering of enclosed lights).
    + Removed tool to save colors, as the CIE macros are now much faster.
    + Moved spectrums from lightsys_constants.inc to espd_lightsys.inc, but
      they are included from this file automatically.
    + Moved precalculation of light colors from lightsys_constants.inc to 
      lightsys_colors.inc, which must be included manually after the constants.
    + Removed Precalculate_Colors switch as consecuence of the prior change.

  See readme_lightsys.txt for details.

*/


// *** AUXILIARY LIGHT MACROS ***
//
// Macros for alternative usage in complex light_sources, proposed by Philippe Debar 
// also used now inside the main "light()" macro for clarity and economy.

// --- Light_Color() ---
//
// Obtain light_source color for a given light color and lumens intensity
// Parameters: 
//  + basic light color (rgb from kelvin temp. or spectrum) 
//  + lumens intensity 
#macro Light_Color(Lct,Lm)

 // test defaults and set proper values for missing ones:
 #ifndef(Lightsys_Filter)
   #declare Lightsys_Filter=<1,1,1>; // no color filter by default (all color passes)
 #else
   #declare Lightsys_Filter=Lightsys_Filter*<1,1,1>; // if exists, ensure it's a vector
 #end 
 #ifndef(Lightsys_Brightness)
   #declare Lightsys_Brightness=1; // no brightness correction by default
 #end 
 #ifndef(Lightsys_Scene_Scale)
   #declare Lightsys_Scene_Scale=1; // scale=1 by default
 #end 

 // normalization?
// #local NormLct=Lct/(Lct.red+Lct.green+Lct.blue);
 #local NormLct=vnormalize(Lct);

 // color correction filter 
 #local Corrected_Color=NormLct*Lightsys_Filter; 

 // multiply intensity by lumens and adjust overall brightness
 #local Result_Color=Corrected_Color*Lm*Lightsys_Brightness; 

 (Result_Color)

#end

// --- Light_Color_Filtered() --
//
// Obtain light_source color for a given light color and lumens intensity,
// filtered through a given filter color.
// Parameters: 
//  + basic light color (rgb from kelvin temp. or spectrum) 
//  + lumens intensity 
//  + Color filter
#macro Light_Color_Filtered(Lct,Lm,Flt)

  #local filtered=Lct*Flt;

  Light_Color(Lct*Flt,Lm*filtered.gray/Lct.gray)

#end

// --- Light_Spot_Cos_Falloff() ---
// 
// Cosine falloff trick for spotlights, after Kari Kivisalo
// parameter: point_at
#macro Light_Spot_Cos_Falloff(Point_At)

 spotlight radius -89.9 falloff 89.9 tightness 1 point_at Point_At
 
#end

// --- Light_Fading() ---
//
// Realistic light fading, now uses fixed distance again.
#macro Light_Fading()

  #ifndef(Lightsys_Scene_Scale)
    #declare Lightsys_Scene_Scale=1;
  #end

  #ifndef (Lightsys_ExposureFake)
    // realistic fading
    fade_distance 2*pi*Lightsys_Scene_Scale
    fade_power 2
  #else
    // experimental exposure fake feature
    #ifndef(e) #local e = exp(1); #end // if conts.inc is not included
    #if (Lightsys_ExposureFake < 0.1) 
      #declare Lightsys_ExposureFake := 0.1; // no such small values!
    #end            
    fade_distance 2*pi*Lightsys_Scene_Scale*pow(Lightsys_ExposureFake,e)
    fade_power    1+pow(Lightsys_ExposureFake,2)                         
  #end

#end


// *** MAIN MACRO ***

// -- Light() ---
//
// Main macro, intended to replace the use of light_source for simple lights
// Parameters:
//  + color temperature rgb
//  + intensity in lumens
//  + area_light axis 1
//  + area_light axis 2
//  + area_light size 1
//  + area_light size 2
//  + cosine falloff spotlight switch
#macro Light(Lct,Lm,Ala1,Ala2,Als1,Als2,Cfall)

 // return a light source for this setup
 light_source{

   // placed at the origin
   0
   
   // obtain color+intensity
   Light_Color(Lct,Lm)

   // cosine fallof support
   #if (Cfall)
     Light_Spot_Cos_Falloff(vcross(Ala1,Ala2))
   #end

   // area light?
   #if (Als1+Als2>0)
     area_light Ala1,Ala2,Als1,Als2
     jitter
     adaptive 1
   #end

   // realistic fading
   Light_Fading()
 
 }

#end



