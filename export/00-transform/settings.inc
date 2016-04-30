// settings.inc for Bullet Physics Playground POV-Ray export

// for LightSys see - http://www.ignorancia.org/en/index.php?page=Lightsys
#declare use_rad        = 0;
#declare use_lightsys   = 0;
#declare use_area_light = 0;
#declare use_fastclouds = 0;
#declare use_plane_tex  = 0;

#if (use_rad = 1)
#include "rad_def.inc"
#end

global_settings {
  assumed_gamma 1.0
  charset utf8
  max_trace_level 15
#if (use_rad = 1)
  radiosity { Rad_Settings(Radiosity_OutdoorHQ,off,off) }
#end
}

#default { finish {ambient 0.1 diffuse 0.9 specular 0.85 roughness 0.009} }

#include "colors.inc"

#if (use_fastclouds = 1)
  #include "fastclouds.inc"
#end

#if (use_lightsys)

#include "CIE.inc"
#include "CIE_tools.inc"
#include "lightsys.inc"
#include "lightsys_constants.inc"
#include "espd_lightsys.inc"

#declare lightsys_brightness = 100.0;
#declare LC1 = EmissiveSpectrum(ES_Osram_CoolFluor_36w);
#declare LM  = Lm_Incandescent_100w;
#if (use_area_light)
  object {
    Light(LC1, LM, x*40, z*40, on*4, on*4, off)
    translate <-100,200,-100>
  }
#end // use_area_light
#else // use_lightsys
#if (use_area_light)
  light_source {
    <-1000,100,-1000> color White * .5
  }
  light_source {
    <-1000, 200, -1000>
    color White * .5
    area_light <40, 0, 0>, <0, 0, 40>, 4, 4
    adaptive 1
    jitter
  }
#else
  light_source{
    <-1000,1000,-1000> color White
  }
#end // use_area_light
#end // use_lightsys

#if (use_fastclouds = 0)
plane{ <0,1,0>,1 hollow
       texture{
         pigment{ bozo turbulence 0.92
           color_map{
                 [0.00 rgb<0.05,0.15,0.45>]
                 [0.50 rgb<0.05,0.15,0.45>]
                 [0.70 rgb<1,1,1>        ]
                 [0.85 rgb<0.2,0.2,0.2>  ]
                 [1.00 rgb<0.5,0.5,0.5>  ]
                       } //
           scale<1,1,1.5>*2.5
           translate<0,0,0>
           } // end of pigment
         finish {ambient 1 diffuse 0}
        } // end of texture
       scale 10000}
  background { color White }
#end

#if (use_fastclouds = 1)

  /*
  These are the macro-arguments:
  1. Sun Location
  2. cloud 'Cast' (0=no clouds, 1=fully clouded sky, can be >1)
  3. 'Fluffyness', controls the sharpness (or lack thereof) of the clouds
  4. Translate-vector for the cloud-pattern
  5. Size of the cloud-skysphere (*500)
  6. Size of the cloud-pattern
  7. Minimum transparency, or: the main-transparency of the clouds (could be 
  seen as the cloud-thickness)
  8. Color of the Sun
  9. Color of the clouds
  */
  fastclouds(<500,500,500>*1000,.455,.1,0,10,.05,0,<1.5,1.3,1.1>,1)

  sky_sphere {
    pigment {
      planar
      color_map {
        [0 rgb <22,44,68>/255]
        [.5 rgb <88,120,179>/255]
        [1 rgb <213,205,194>/255]
      }
    }
  }
#end

// ground ----------------------------------

plane{ <0,1,0>, 0.1
  texture{
#if (use_plane_tex = 0)
    pigment{ color rgb<0.22,0.45,0>}
    normal { bumps 0.75 scale 0.015 }
    finish { phong 0.1 }
#end

#if (use_plane_tex = 1)
    pigment { color rgb <1,1,1>*1.5 }
      finish {
        specular 0.5
        roughness 0.1
        //reflection 0.3 // reflection seems superfluous and adds nothing to it
    }
#end
  }
}
