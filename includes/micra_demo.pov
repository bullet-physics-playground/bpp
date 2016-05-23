// Persistence of Vision Ray Tracer Scene Description File
// File: micra_demo.pov
// Vers: 3.5-3.6
// Desc: Study of Nissan Micra (k11) car at Uffizi Allee
// Date: may 2006
// Auth: Rene Bui - http://rene.bui.free.fr
//
// Note: To render this image properly you need "uffizi_probe.hdr" file 
// downloadable for free at http://www.debevec.org/Probes/
// --------------------------------------------------------------------

// -----------------------
// REQUIRED STANDARD INCLUDES
// -----------------------

#include "colors.inc"
#include "textures.inc"
#include "metals.inc"
#include "glass.inc"
#include "functions.inc"
#include "transforms.inc"

// -----------------------
// SETTINGS
// -----------------------
#declare use_Rad=1;
#declare Cam_1=1;
#declare Cam_2=1;


global_settings {
  adc_bailout 0.003922
  //ambient_light 1 // version 3.5
  ambient_light 0 // version 3.6
  assumed_gamma 2
  hf_gray_16 off
  irid_wavelength <0.247059,0.176471,0.137255>
  max_intersections 64
  max_trace_level 10
  number_of_waves 10
  noise_generator 2
  charset ascii

#if (use_Rad)
  radiosity {
    pretrace_start 0.08           // start pretrace at this size
    pretrace_end   0.04           // end pretrace at this size
    count 100                     // higher -> higher quality (1..1600) [35]
    nearest_count 10              // higher -> higher quality (1..10) [5]
    error_bound 1.8               // higher -> smoother, less accurate [1.8]
    recursion_limit 1             // how much interreflections are calculated (1..5+) [3]
    low_error_factor .5           // reduce error_bound during last pretrace step
    gray_threshold 0              // increase for weakening colors (0..1) [0]
    minimum_reuse 0.015           // reuse of old radiosity samples [0.015]
    //brightness 1  // v.3.5    // brightness of radiosity effects (0..1) [1]
    brightness .1 // v.3.6

    adc_bailout 0.01/2
    normal on                     // take surface normals into account [off]
    //media on                    // take media into account [off]
    //save_file "file_name"       // save radiosity data
    //load_file "file_name"       // load saved radiosity data
    //always_sample off           // turn sampling in final trace off [on]
    //max_sample 1.0              // maximum brightness of samples
  }
#end  
  
}

// -----------------------
// LIGHTS
// -----------------------

light_source {
  0*x                 
  color rgb <.9,.95,1> *1.5
  area_light
  <8, 0, 0> <0, 0, 8> 
  4, 4                
  adaptive 0          
  jitter              
  circular            
  orient              
  translate <0, 30, 0>   
  scale <5,0,100>
}

// -----------------------
// HDRI MAP & BACKGROUND
// -----------------------
sphere { 
  0,5000
  pigment { image_map { hdr "uffizi_probe.hdr" once interpolate 2 map_type 7 }
  rotate <0,240,0> scale 0.6 } 
  finish { ambient .9 diffuse .5 } 
  hollow
  no_image
}


// -----------------------
// GROUND
// -----------------------
// tileable height_field
        #declare P_Tile=pigment{image_map{jpeg "paves2.jpg" interpolate 2}} 
        #declare F_Tile=finish{ambient 0 diffuse 0.8 specular 0.4 roughness 0.05}// reflection{0,0.05}}

        
        #declare Tilingunit=height_field{
            jpeg "paves2_hf.jpg"
            smooth
            texture{
                pigment{P_Tile}
                finish{F_Tile}
                rotate x*90
            }
        }
        
        #declare Tilingbase=union{
            object{Tilingunit}
            object{Tilingunit translate z}
            object{Tilingunit translate z*2}
            object{Tilingunit translate z*3}
            object{Tilingunit translate z*4}
            object{Tilingunit translate z*5}

            scale <.7,.001,.5>*10 
            translate y*-1.049
            
        }
        
        #declare Tiling=union{
            object{Tilingbase translate x*27}
            object{Tilingbase translate x*20} 
            object{Tilingbase translate x*13}
            object{Tilingbase translate x*6}
            object{Tilingbase translate x*-1}
            object{Tilingbase translate x*-8}
            object{Tilingbase translate x*-15}
            object{Tilingbase translate x*-22}
            object{Tilingbase translate x*-29}
            object{Tilingbase translate x*-36}
            object{Tilingbase translate x*-43}
            object{Tilingbase translate x*-50}
        }
        object{Tiling rotate y*60 translate x*-15}


// -----------------------
// MICRA CAR
// ----------------------- 
// Copyright 2006 Rene Bui - http://rene.bui.free.fr
// -----------------------
// This work is licensed under the Creative Commons Attribution License. 
// To view a copy of this license, visit http://creativecommons.org/licenses/by/2.0/ 
// or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
// You are free:
// - to copy, distribute, display, and perform the work
// - to make derivative works
// - to make commercial use of the work
// Under the following conditions:
// - Attribution. You must give the original author credit.
// - For any reuse or distribution, you must make clear to others the license terms of this work.
// - Any of these conditions can be waived if you get permission from the copyright holder.
// Your fair use and other rights are in no way affected by the above. 
// ----------------------- 
// 
// Files needed to run the Micra car model:
// ----------------------------------------
// Materials:
// micra_mat.inc
//
// Maps:
// micra_blinker_l.jpg
// micra_blinker_r.jpg
// micra_cover_lf.jpg
// micra_cover_lr.jpg
// micra_cover_rf.jpg
// micra_cover_rr.jpg
// micra_headlight_l.jpg
// micra_headlight_r.jpg
// micra_taillight_l.jpg
// micra_taillight_r.jpg
// micra_wunderbaum.jpg
// micra_rearwindow_1.png
// micra_rearwindow_2.png
// micra_windshield.png
//
// Geometry:
#include "i_micra_body.inc"
#include "i_micra_accessories.inc"
#include "i_micra_glass.inc"
#include "i_micra_plates.inc"
#include "i_micra_r_wheel.inc" 
#include "i_micra_lf_wheel.inc" 
#include "i_micra_rf_wheel.inc"
#include "i_micra_inner.inc"
#include "i_wunderbaum.inc"

#declare Micra=union {
  object{micra_body_}
  object{micra_inner_}
  object{micra_accessories_}
  object{micra_glass_ interior{fade_power 1001 fade_distance 10}}      
  object{micra_plates_} 
  object{micra_R_wheel_}
  object{micra_LF_wheel_ Rotate_Around_Trans(y*20, <-1, 0, 1.55>)} // rotate front left wheel
  object{micra_RF_wheel_ Rotate_Around_Trans(y*20, <1, 0, 1.55>)}  // rotate front right wheel
  object{wunderbaum_}
}

object{Micra
      rotate y*340  // 160
      translate z*4
      translate y*.45
      scale 2
      }

object{Micra  
      rotate y*210  // 30   
      translate x*-2.6      
      translate z*8
      translate y*.45
      scale 2  
      }      
     
// -----------------------
// CAMERAS
// -----------------------

camera {
  right     x*image_width/image_height
  angle 22
  
  #if (Cam_1)
  location  <0, 5, -12>
  look_at   <-.5, 2.6, -1>
  #end

  #if (Cam_2)
  location  <-20, 15, -3>
  look_at   <-.05, 0.5, 8>
  #end  
  
}

