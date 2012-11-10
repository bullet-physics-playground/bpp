#declare Rad_Quality = 0;
#declare Phot_Quality = 0;

#include "colors.inc"
#include "stones.inc"
#include "woods.inc"

global_settings {
  assumed_gamma 1

#switch (Phot_Quality)
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

#switch (Rad_Quality) 
#case (1) 
  radiosity { // fast
    pretrace_start 0.08 
    pretrace_end 0.02 
    count 50 
    error_bound 0.5 
    recursion_limit 1 
  } 
#break 
#case (2) 
  radiosity { // medium quality
    pretrace_start 0.08 
    pretrace_end 0.01 
    count 120 
    error_bound 0.25 
    recursion_limit 1 
  } 
#break 
#case (3) 
  radiosity { // high quality
    pretrace_start 0.08 
    pretrace_end 0.005 
    count 400 
    error_bound 0.1 
    recursion_limit 1 
  } 
#break 
#case (4) 
  radiosity { // medium quality, recursion_limit 2
    pretrace_start 0.08 
    pretrace_end 0.005 
    count 350 
    error_bound 0.15 
    recursion_limit 2 
  } 
#break 
#end 

} 

light_source {
  <1000, 10000, 15000>
  color rgb <255.0/ 160.0, 255.0/158.0, 255.0/154.0>*.95

#switch (Phot_Quality)
#case (1)
  photons {
    reflection on
    refraction on
  }
#break
#end
}

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
  scale 10000 
  hollow on 
  no_shadow 
}
