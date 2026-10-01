// ***********************************************************
// Persistence Of Vision Ray Tracer Scene Description File
// File name  : poolballs.pov
// Version    : 3.7
// Description: Pool Balls 
// Date       : Sep-Oct 2012
// Author     : Jaime Vives Piqueres
// ***********************************************************
#version 3.7;

// *** standard includes ***
#include "colors.inc"
#include "textures.inc"
#include "functions.inc"
#include "rad_def.inc"

// *** control center ***
#declare use_cue=1;
#declare use_chalk=1;
#declare use_rack=1;
#declare use_blur =7*5;  // blur samples (0=off)
#declare use_media=0;  // turn on for fake subsurface effect on the balls
#declare use_area=1;
global_settings{
  radiosity{
    Rad_Settings(Radiosity_IndoorLQ, off, off)
  }
}
#default{texture{finish{ambient 0 emission 0 diffuse 1}}}


// *** BALLS TEXTURES ***
#include "poolballs_textures.inc"

// *** POOL BALLS ***
#declare r_br=seed(3277);
#declare ball=
sphere{0,1 hollow
  interior{
    #if(use_media)
    media{
      scattering{1,1}
      absorption 1
    }
    #end
    ior 1.54
  }
  scale 3  
}
// triangle formation
#declare rsep=5.25;
#declare pos_bw=<20,80,20>;
#declare pos_b1=< 0,80,0>;
#declare pos_b2=<-3,80,rsep>;
#declare pos_b3=< 3,80,rsep>;
#declare pos_b4=<-6,80,rsep*2>;
#declare pos_b5=< 0,80,rsep*2>;
#declare pos_b6=< 6,80,rsep*2>;
#declare pos_b7=<-9,80,rsep*3>;
#declare pos_b8=<-3,80,rsep*3>;
#declare pos_b9=< 3,80,rsep*3>;
#declare pos_b10=<  9,80,rsep*3>;
#declare pos_b11=<-12,80,rsep*4>;
#declare pos_b12=< -6,80,rsep*4>;
#declare pos_b13=<  0,80,rsep*4>;
#declare pos_b14=<  6,80,rsep*4>;
#declare pos_b15=< 12,80,rsep*4>;
#declare all_balls=
union{
object{ball texture{t_ivory0}  rotate 360*rand(r_br) translate pos_bw}
object{ball texture{t_ivory1}  rotate 360*rand(r_br) translate pos_b1}
object{ball texture{t_ivory2}  rotate 360*rand(r_br) translate pos_b2}
object{ball texture{t_ivory3}  rotate 360*rand(r_br) translate pos_b3}
object{ball texture{t_ivory4}  rotate 360*rand(r_br) translate pos_b4}
object{ball texture{t_ivory5}  rotate 360*rand(r_br) translate pos_b5}
object{ball texture{t_ivory6}  rotate 360*rand(r_br) translate pos_b6}
object{ball texture{t_ivory7}  rotate 360*rand(r_br) translate pos_b7}
object{ball texture{t_ivory8}  rotate 360*rand(r_br) translate pos_b8}
object{ball texture{t_ivory9}  rotate 360*rand(r_br) translate pos_b9}
object{ball texture{t_ivory10}  rotate 360*rand(r_br)
 rotate 180*y
 translate pos_b10}
object{ball texture{t_ivory11}  rotate 360*rand(r_br) translate pos_b11}
object{ball texture{t_ivory12}  rotate 360*rand(r_br) translate pos_b12}
object{ball texture{t_ivory13}  rotate 360*rand(r_br) translate pos_b13}
object{ball texture{t_ivory14}  rotate 360*rand(r_br) translate pos_b14}
object{ball texture{t_ivory15}  rotate 360*rand(r_br) translate pos_b15}
translate 3*y
}
object{all_balls}


// *** triangle rack ***
#if (use_rack)
#include "poolballs_rack.inc"
object{triangle_rack
 interior{ior 1.51}
  scale <25,31,25>
  translate 82*y
  translate 10*z
}
#end


// *** POOL table ***
plane{y,80
  texture{ 
    pigment{
      image_map{jpeg "mayang-furry_fabric_6150133-gr" interpolate 2}
      warp{turbulence 1 lambda 4}
      rotate 90*x
      scale .04
    } 
    normal{function{f_mesh1(x*200,y*200,z*200,.2,.2,1,.2,2)}}
  }
  texture{
    pigment{
      wrinkles warp{turbulence 1 lambda 3}
      scale 1 frequency 8
      color_map{
        [0 rgbt 1]
        [0.200 rgbt 1]
        [0.201 White]
        [0.202 rgbt 1]
        [0.400 rgbt 1]
        [0.401 Firebrick]
        [0.402 rgbt 1]
        [0.600 rgbt 1]
        [0.601 Gold]
        [0.602 rgbt 1]
        [0.800 rgbt 1]
        [0.801 SlateBlue]
        [0.802 rgbt 1]
        [1.0 rgbt 1]
      }      
    }
  }
}

// *** billiard cue ***
#if (use_cue)
#include "poolballs_cue.inc"
object{billiard_cue
 interior{ior 1.51}
 scale 10
 // ah... good&old trial&error... :)
 rotate 80*x
 rotate 97*y
 translate 86*y
 translate 11*z
 translate -10*x
}
#end

// *** billiard chalk ***
#if (use_chalk)
#include "poolballs_chalk.inc"
object{billiard_chalk
  scale 1.25
  translate <12,80+1.25,7> 
}
#end

// *** lighting ***
sphere{
 0,500
 texture{
  pigment{image_map{hdr "jvp_thekitchen-ceil-1200x600" map_type 1 interpolate 2}}
  finish{emission .125 diffuse 0}
  rotate 180*y
 }
 hollow no_shadow 
 translate 80*y
}
light_source { 
 <0,150,0>
 rgb (White+Gold*2)*1000
 #if (use_area)
 area_light 12*x,12*z,4,4 jitter adaptive 1 orient circular
 #end
 fade_distance 1
 fade_power 2
} 


// **************
// *** camera ***
// **************
#declare la=pos_b5+2*y;
camera{
 location <30,110,-30>
 up 2.4*y
 right 3.2*x
 angle 28.8
 look_at la
 #if (use_blur)
 focal_point pos_b5+2*y
 aperture 2/3
 blur_samples use_blur
 variance 0
 #end
}

