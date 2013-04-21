// settings.inc for Bullet Physics Playground POV-Ray export

// for LightSys see - http://www.ignorancia.org/en/index.php?page=Lightsys
#declare use_lightsys   = 1;
#declare use_area_light = 1;

global_settings {
  assumed_gamma 1.0
}

#default { finish {ambient 0.1 diffuse 0.9 specular 0.85 roughness 0.009} }

#include "colors.inc"

#if (use_lightsys)

#include "CIE.inc"
#include "CIE_tools.inc"
#include "lightsys.inc"
#include "lightsys_constants.inc"
#include "espd_lightsys.inc"

#declare lightsys_brightness = 1.0;
#declare LC1 = EmissiveSpectrum(ES_Osram_CoolFluor_36w);
#declare LM  = Lm_Incandescent_100w;

#if (use_area_light)
  object {
    Light(LC1, LM, x*40, y*40, on*4, on*4, off)
    translate <200,200,200>
  }
#end // use_area_light

#else // use_lightsys

#if (use_area_light)
  light_source {
    <200,200,200> color White * .5
  }
  light_source {
    <200, 200, 200>
    color White * .5
    area_light <40, 0, 0>, <0, 0, 40>, 4, 4
    adaptive 1
    jitter
  }
#else
  light_source{
    <200,200,200> color White
  }
#end // use_area_light
#end // use_lightsys
