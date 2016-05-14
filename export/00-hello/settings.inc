// settings.inc for Bullet Physics Playground POV-Ray export

// for LightSys see - http://www.ignorancia.org/en/index.php?page=Lightsys
#declare use_rad        = 1;  // 0/1/2
#declare use_lightsys   = 1;  // 0/1
#declare use_lightsys_setting = 1; // 0/1
#declare use_area_light = 1;  // 0/1
#declare use_background = 0;  // 0/1/2
#declare use_clouds     = 3;  // 0/1/2/3
#declare use_plane      = 0;  // 0/1
#declare use_plane_tex  = 0;  // 0/1/2
#declare use_photons    = 2;  // 0/1/2

#if (use_rad != 0)
#include "rad_def.inc"
#end

global_settings {
  assumed_gamma 1.0
  charset utf8
  max_trace_level 15
#if (use_rad = 1)
  radiosity { Rad_Settings(Radiosity_OutdoorLQ,off,off) }
#end
#if (use_rad = 2)
  radiosity { Rad_Settings(Radiosity_OutdoorHQ,off,off) }
#end

#switch (use_photons)
#case (1)
  photons {
    spacing 0.025
  }
#break
#case (2)
  photons {
    spacing 0.0125
  }
#break
#end
}

#default { finish {ambient 0.1 diffuse 0.9 specular 0.85 roughness 0.009} }

#include "colors.inc"

#if (use_clouds = 2)
  #include "fastclouds.inc"
#end

#if (use_lightsys)

#include "CIE.inc"
#include "CIE_tools.inc"
#include "lightsys.inc"
#include "lightsys_constants.inc"
#include "espd_lightsys.inc"

#declare lightsys_brightness = 1.0;
#switch (use_lightsys_setting)
#case (0)
#declare LC1 = EmissiveSpectrum(ES_Daylight_Fluor);
#declare LM  = Lm_GE_LinearR7S_500w;
#break
#case (1)
#declare LC1 = EmissiveSpectrum(ES_Osram_CoolFluor_36w);
#declare LM  = Lm_Incandescent_100w;
#break
#end
#if (use_area_light)
  object {
    Light(LC1, LM, x*40, z*40, on*4, on*4, off)
    translate <500,500,500>
  }
#end // use_area_light
#else // use_lightsys
#if (use_area_light)
  light_source {
    <500,500,500> color White * .5
#switch (use_photons)
#case (1)
  photons {
    reflection on
    refraction on
  }
#break
#end
  }
  light_source {
    <500,500,500>
    color White * .5
    area_light <40, 0, 0>, <0, 0, 40>, 4, 4
    adaptive 1
    jitter
  }
#else
  light_source{
    <500,500,500> color White
#switch (use_photons)
#case (1) 
  photons {
    reflection on
    refraction on
  }
#break
#end
  }
#end // use_area_light
#end // use_lightsys

#if (use_background = 1)
background { color Black }
#end

#if (use_background = 2)
background { color White }
#end

#if (use_clouds = 1)
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
           scale<1,1,1.5>*25
           translate<0,0,0>
           }
         finish {ambient 1 diffuse 0}
        }
       scale 1000}
#end

#if (use_clouds = 2)

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
  fastclouds(<500,500,500>*100,.3,.1,0,100,.05,0,<1.5,1.3,1.1>,1)

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

#if (use_clouds = 3)
sphere { // sky
  <0, 0, 0>, 1
  texture {
    pigment {
      gradient y
      color_map {
        [0.0 color rgb < 1.0, 1.0, 1.0 >]
        [0.3 color rgb < 0.5, 0.6, 1.0 >]
      }
    }
    finish { diffuse 0 ambient 0.75 }
  }
  scale 1000000
  hollow on
  no_shadow
}
#end

#if (use_plane = 1)

plane{ <0,1,0>, 0.1
  texture{
#if (use_plane_tex = 1)
    pigment{ color rgb<0.22,0.45,0>}
    normal { bumps 0.75 scale 0.015 }
    finish { phong 0.1 }
#end

#if (use_plane_tex = 2)
    pigment { color rgb <1,1,1>*1.5 }
      finish {
        specular 0.5
        roughness 0.1
        //reflection 0.3 // reflection seems superfluous and adds nothing to it
    }
#end
  }
}
#end

