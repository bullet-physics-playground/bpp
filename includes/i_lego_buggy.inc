#include "colors.inc"
#include "textures.inc"

#include "i_lego_buggy_2738.inc"
#include "i_lego_buggy_3739.inc"
#include "i_lego_buggy_3740.inc"

#include "i_lego_buggy_4275b.inc"
#include "i_lego_buggy_4276b.inc"

#include "i_lego_buggy_bolzen.inc"
#include "i_lego_buggy_lenkrad.inc"

/* control center----------------------------------------------------------- */

#declare fast = 0;
#declare use_area=1;         // 0=off, 1=on
#declare matrix_mode = 0;

/* l3go stone properties --------------------------------------------------- */

#declare rundung = 0.03;    // corner antialiasing of a lego stone
#declare b = 0.7;           // width of one s1x1x1
#declare h = 0.28;          // height of one s1x1x1
#declare nh = h*0.5;        // height of one burl

#ifndef (fast)
 #declare fast = 0;         // render fast or slow
 #debug "\n\nfast = off"
#end

/* materials --------------------------------------------------------------- */

#macro material_matrix()
  texture {
    pigment { rgb <0, 1, 0> }
    finish { ambient 1 phong 1 }
    normal { granite .02 scale .01 }
  }
  interior { ior 1.5 }
#end

#macro material_default(COLOR)
  texture {
    pigment { COLOR }
    finish { ambient 0.2 phong 1 }
    normal { granite .01 scale .01 }
  }
#end

#macro material_reflect(COLOR)
  texture {
    pigment { COLOR }
    finish { ambient 0.2 phong 1 reflection 0.05 }
    normal { granite .02 scale .01 }
  }
#end

#declare t_red = material {
#if (matrix_mode=1)
  material_matrix()
#else
  material_default(rgb<1,0,0>)
#end
}

#declare t_yellow = material {
#if (matrix_mode=1)
  material_matrix()
#else
  material_default(rgb<0,0.9,0>)
#end
}

#declare t_blue = material {
#if (matrix_mode=1)
  material_matrix()
#else
  material_default(rgb<0,0,1>)
#end
}

#declare t_green = material {
#if (matrix_mode=1)
  material_matrix()
#else
  material_default(rgb<0,0.8,0>)
#end
}

#declare t_gray = material {
#if (matrix_mode=1)
  material_matrix()
#else
  material_default(rgb<0.8,0.8,0.8>)
#end
}

#declare t_black = material {
#if (matrix_mode=1)
  material_matrix()
#else
  material_reflect(rgb<0.05,0.05,0.05>)
#end
}

#declare t_white = material {
#if (matrix_mode=1)
  material_matrix()
#else
  material_reflect(rgb<1,1,1>)
#end
}

/* burls with l3go logo --------------------------------------------------- */

#declare noppe =
 merge {
  cylinder { <0, h/2+nh-rundung, 0>, <0, h/2+nh+nh-rundung, 0>, 0.21 }
#if (fast=0)
  torus { 0.2, 0.01
   translate <0, h/2+nh+nh-0.005-rundung, 0>
  }

  text { ttf "Generic.ttf" "LEGO" 0.07, 0
    scale <-0.15, -0.15, -0.2>
    rotate x*90
    translate <0.175, h/2+nh+nh-rundung, 0.05>
  }
#end
 }

/* lego_stone_template => st  ---------------------------------------------- */

#macro st(XSIZE,YSIZE,ZSIZE,NOPPEN,WHOLE)
 #if (XSIZE>1) // FIXIT: isn't there any 'AND' expression in POV-Ray 3.1 ?
  #if (WHOLE=yes)
 merge {
  difference {
  #end
 #end
 #if (XSIZE>1)
   union {
 #end
    difference {
 #if (NOPPEN=yes)
     union {
 #end
 #if (fast=0)
       superellipsoid { <rundung, rundung>
        scale <0.35*XSIZE, h/2*YSIZE-0.0002, 0.35*ZSIZE>
        translate <b*XSIZE/2-b/2, h/2*YSIZE, b*ZSIZE/2-b/2>
       }
 #else
       box { <-0.35*XSIZE+0.007, -h/2*YSIZE+0.015, -0.35*ZSIZE+0.007>,
             <0.35*XSIZE-0.007, h/2*YSIZE-0.015, 0.35*ZSIZE-0.007>
        translate <b*XSIZE/2-b/2, h/2*YSIZE, b*ZSIZE/2-b/2>
       }
 #end
 #if (NOPPEN=yes)
  #local J = 0;
  #while (J < ZSIZE)
   #local I = 0;
   #while (I < XSIZE)
       object { noppe
        translate <I*b, h*(YSIZE-1), J*b>
       }
    #declare I = I+1;
   #end // while (I < XSIZE)
  #local J = J+1;
 #end // while (J < ZSIZE)
      }
 #end // if (NOPPEN=yes)
      box { <-0.21, -0.001, -0.21>, <0.21+b*(XSIZE-1), h*YSIZE-nh, 0.21+b*(ZSIZE-1)> }
     }
 #if (XSIZE>1)
  #local J = 0;
  #while (J < ZSIZE)
  #local I = 1;
  #while (I < XSIZE)
   #if (ZSIZE>1)
    #if (J < ZSIZE-1)
     difference {
      cylinder { <-b/2,0,b/2>, <-b/2, h*YSIZE-rundung*2, b/2>, 0.7/3 }
      cylinder { <-b/2,-0.01,b/2>, <-b/2, h*YSIZE*rundung*2, b/2>, 0.7/4 }
      translate <I*b,0,J*b> 
     }
    #end
   #else // if (ZSIZE>1)
     cylinder { <-b/2,0,0>, <-b/2, h*YSIZE-rundung*2, 0>, 0.7/6
      translate <I*b,0,0>
     }
   #end // if (ZSIZE>1)
   #if (XSIZE>1)
    #if (WHOLE=yes)
     #if (fast=0)
     box { <-0.7/2.05-b/2,h*1.7,-b/2+0.007>, <0.7/2.05-b/2,h*YSIZE-rundung*2,b/2-0.007>
      translate <I*b,0,0>
      material { t_yellow }
     }
     #end // if (fast=0)
    #end // if (WHOLE=yes)
   #end // if (XSIZE>1)
   #local I = I+1;
  #end // while (I < XSIZE)
  #local J = J+1;
  #end // while (J < ZSIZE)
    }
  #if (XSIZE>1)
   #if (WHOLE=yes)
    #local I = 1;
    #while (I < XSIZE)
    cylinder { <-b/2,h*1.7,-b/2-0.1>, <-b/2,h*1.7,b/2+0.1>, 0.7/2.5
     translate <I*b,0,0>
    }
     #local I = I+1;
    #end // while (I < XSIZE)
   }
    #local I = 1;
    #while (I < XSIZE)
   difference {
    cylinder { <-b/2,h*1.7,-b/2+b/14>, <-b/2,h*1.7,b/2-b/14>, 0.7/2.05
     translate <I*b,0,0>
    }
    cylinder { <-b/2,h*1.7,-b/2-0.1>, <-b/2,h*1.7,b/2+0.1>, 0.21
     translate <I*b,0,0>
    }
   }
     #local I = I+1;
    #end // while (I < XSIZE)
  }
   #end // if (WHOLE=yes)
  #end // if (XSIZE>1) 
 #end // if (XSIZE>1)
 translate <0,-h*0.5,0>
#end // macro

/* lego stones ------------------------------------------------------------- */

#declare sf1x1x1 = object { st(1,1,1,no,no) }
#declare sf2x1x1 = object { st(2,1,1,no,no) }
#declare sf3x1x1 = object { st(3,1,1,no,no) }
#declare sf4x1x1 = object { st(4,1,1,no,no) }
#declare sf6x1x1 = object { st(6,1,1,no,no) }
#declare sf8x1x1 = object { st(8,1,1,no,no) }
#declare sf10x1x1 = object { st(10,1,1,no,no) }
#declare sf12x1x1 = object { st(12,1,1,no,no) }

#declare s1x1x1 = object { st(1,1,1,yes,no) }
#declare s2x1x1 = object { st(2,1,1,yes,no) }
#declare s3x1x1 = object { st(3,1,1,yes,no) }
#declare s4x1x1 = object { st(4,1,1,yes,no) }
#declare s6x1x1 = object { st(6,1,1,yes,no) }
#declare s8x1x1 = object { st(8,1,1,yes,no) }
#declare s10x1x1 = object { st(10,1,1,yes,no) }
#declare s12x1x1 = object { st(12,1,1,yes,no) }

#declare s1x3x1 = object { st(1,3,1,yes,no) }
#declare s2x3x1 = object { st(2,3,1,yes,no) }
#declare s3x3x1 = object { st(3,3,1,yes,no) }
#declare s4x3x1 = object { st(4,3,1,yes,no) }
#declare s6x3x1 = object { st(6,3,1,yes,no) }
#declare s8x3x1 = object { st(8,3,1,yes,no) }
#declare s10x3x1 = object { st(10,3,1,yes,no) }
#declare s12x3x1 = object { st(12,3,1,yes,no) }

#declare s2x1x2 = object { st(2,1,2,yes,no) }
#declare s2x1x3 = object { st(2,1,3,yes,no) }
#declare s2x1x4 = object { st(2,1,4,yes,no) }
#declare s2x1x6 = object { st(2,1,6,yes,no) }
#declare s2x1x8 = object { st(2,1,8,yes,no) }
#declare s2x1x10 = object { st(2,1,10,yes,no) }
#declare s2x1x12 = object { st(2,1,12,yes,no) }
#declare s2x1x14 = object { st(2,1,14,yes,no) }
#declare s2x1x16 = object { st(2,1,16,yes,no) }

#declare s4x1x4 = object { st(4,1,4,yes,no) }
#declare s6x1x6 = object { st(6,1,6,yes,no) }
#declare s8x1x6 = object { st(8,1,6,yes,no) }
#declare s10x1x6 = object { st(10,1,6,yes,no) }

#declare t2x3x1 = object { st(2,3,1,yes,yes) }
#declare t4x3x1 = object { st(4,3,1,yes,yes) }
#declare t6x3x1 = object { st(6,3,1,yes,yes) }
#declare t8x3x1 = object { st(8,3,1,yes,yes) }
#declare t10x3x1 = object { st(10,3,1,yes,yes) }
#declare t12x3x1 = object { st(12,3,1,yes,yes) }
#declare t14x3x1 = object { st(14,3,1,yes,yes) }
#declare t16x3x1 = object { st(16,3,1,yes,yes) }

/* lego pole template => lp ------------------------------------------------ */

#macro lego_pole(XSIZE)
 difference {
  union {
   cylinder { <rundung,0,0> <b*XSIZE-rundung,0,0>, 0.21 }
   sphere { <rundung,0,0>, 0.21 scale <0.3,1,1> }
   sphere { <0,0,0>, 0.21 scale <0.3,1,1> translate <b*XSIZE-rundung,0,0>}
  }
  union {
   box { <-0.22,-0.21,-0.21> <b*XSIZE+0.22,-0.07,-0.07> }
   box { <-0.22,0.21,-0.21> <b*XSIZE+0.22,0.07,-0.07> }
   box { <-0.22,-0.21,0.21> <b*XSIZE+0.22,-0.07,0.07> }
   box { <-0.22,0.21,0.21> <b*XSIZE+0.22,0.07,0.07> }
   sphere { <rundung,0,0>, 0.1 }
   sphere { <0,0,0>, 0.1 translate <b*XSIZE-rundung,0,0>}
  }
  material {t_black}
 }
#end // macro

/* lego poles -------------------------------------------------------------- */

#declare lp2 = object { lego_pole(2) }
#declare lp3 = object { lego_pole(3) }
#declare lp4 = object { lego_pole(4) }
#declare lp6 = object { lego_pole(6) }
#declare lp8 = object { lego_pole(8) }
#declare lp10 = object { lego_pole(10) }
#declare lp12 = object { lego_pole(12) }
#declare lp14 = object { lego_pole(14) }
#declare lp16 = object { lego_pole(16) }

/* lego clip --------------------------------------------------------------- */

#declare lego_buggy_clip2 = 
difference {
 cylinder { <0,0,0> <b,0,0>, 0.333 }
 object { lp2 translate -x*0.22 }
 torus { 0.333, 0.08 rotate z*90 translate <b*.225,0,0> }
 torus { 0.333, 0.08 rotate z*90 translate <b-b*.225,0,0> }
 box { <b*.12,-0.334,-0.045> <b-b*.12,0.334,0.045> }
 cylinder { <0.1,0,0> <b+0.1,0,0>, 0.17 translate <0,.32,.32> }
 cylinder { <0.1,0,0> <b+0.1,0,0>, 0.17 translate <0,-.32,.32> }
 cylinder { <0.1,0,0> <b+0.1,0,0>, 0.17 translate <0,.32,-.32> }
 cylinder { <0.1,0,0> <b+0.1,0,0>, 0.17 translate <0,-.32,-.32> }
 difference {
  cylinder { <b*.225,0,0> <b-b*.225,0,0>, 0.334 }
  cylinder { <b*.225-0.01,0,0> <b-b*.225+0.01,0,0>, 0.253 }
 }
 material {t_gray}
}

#declare lego_buggy_clip3 =
 union {
 object { lego_buggy_clip2 rotate y*180 translate x*b}
 difference {
  union {
   cylinder { <0,0,0> <b*.333,0,0>, 0.333 translate x*b }
   cylinder { <b*1.5,0,-b*.5> <b*1.5,0,b*.5>, 0.333 }
   box { <b*1.31,-.333,-b*.5> <b*1.789,.333,b*.5> }
   cylinder { <b*1.5,1.5*h,0> <b*1.5,-1.5*h,0>, 0.21 }
  }
  cylinder { <b*1.5,0,-b*.51> <b*1.5,0,b*.51>, 0.25 }
 }
 material {t_gray}
}

#declare lego_buggy_clip4 =
/* FIXME */
difference {
 union {
  cylinder { <0.05,0,0> <b*1.5,0,0>, 0.333 }
  cylinder { <0,0,0> <0.272,0,0>, 0.333 rotate y*90 translate x*b*1.5}
  #local i=0;
  #while (i<16)
   box { <0,-0.06,-0.022> <0.05,0.06,0.022> translate <0,0.272,0> rotate x*i/16*360}
  #local i=i+1;
  #end
 }
 cylinder { <-0.1,0,0> <0.35,0,0>, 0.21 rotate y*90 translate x*b*1.5}
 box { <b,-0.34,0> <b*2,0.34,0.34> } 
 object { lp2 translate -x*0.22 }
 torus { 0.333, 0.08 rotate z*90 translate <b*.225,0,0> }
 torus { 0.333, 0.08 rotate z*90 translate <b-b*.225,0,0> }
 box { <b*.12,-0.334,-0.045> <b-b*.12,0.334,0.045> }
 cylinder { <-0.1,0,0> <b+0.1,0,0>, 0.17 translate <0,.32,.32> }
 cylinder { <-0.1,0,0> <b+0.1,0,0>, 0.17 translate <0,-.32,.32> }
 cylinder { <-0.1,0,0> <b+0.1,0,0>, 0.17 translate <0,.32,-.32> }
 cylinder { <-0.1,0,0> <b+0.1,0,0>, 0.17 translate <0,-.32,-.32> }
 difference {
  cylinder { <b*.225,0,0> <b-b*.225,0,0>, 0.334 }
  cylinder { <b*.225-0.01,0,0> <b-b*.225+0.01,0,0>, 0.253 }
 }
material {t_gray}
}

#declare lego_buggy_clip1 =
union {
 difference {
  cylinder { <0,0,0> <b*.45,0,0>, 0.333 }
  object { lp2 translate -x*0.22 }
  torus { 0.333, 0.08 rotate z*90 translate <b*.225,0,0> }
 }

#local i=0;
#while (i<16)
 box { <b*.45,-0.06,-0.022> <b*.45+0.05,0.06,0.022> translate <0,0.272,0> rotate x*i/16*360}
#local i=i+1;
#end
 material {t_gray}
}

#declare lego_buggy_clip =
difference {
 union {
  cylinder { <0,0,0> <2*b,0,0>, 0.21 }
  cylinder { <b-b/14,0,0> <b+b/14,0,0>, 0.7/2.5 }
  torus { 0.19, 0.04 rotate z*90 }
  torus { 0.19, 0.04 rotate z*90 translate x*2*b }
 }
 union {
  cylinder { <-0.1,0,0> <2*b+0.1,0,0>, 0.16 }
  box { <2*b+0.1,-0.03,-0.25> <2*b-b/3,0.03,0.25> }
  box { <-0.1,-0.25,-0.03> <b/3,0.25,0.03> }
 }
 material {t_black}
}

/* lego car ---------------------------------------------------------------- */

#declare lego_buggy_wheel = union {
  object { p3739 material { t_white } rotate <0,-90,0> translate <b*3,0,0> }
  object { p3740 material { t_black } rotate <0,-90,0> translate <b*1.25,0,0> }
  scale 0.875
}

#declare hinterradlager = union {
 union {
// left
  object { t6x3x1 }
  object { t6x3x1 translate z*b }
  object { s2x1x3 rotate y*90 translate <-b,3*h,b> }
  object { s2x1x2 translate <-b,4*h,0> }
  object { s2x1x1 rotate y*90 translate <5*b,3*h,b> }
  object { s2x1x1 rotate y*90 translate <5*b,4*h,b> }
  object { t2x3x1 rotate y*90 translate <-b,5*h,b> }
  object { t2x3x1 rotate y*90 translate <0,5*h,b> }
  object { s2x1x3 rotate y*90 translate <-b,9*h,b> }
  object { s2x1x2 translate <-b,8*h,0> }
  object { t6x3x1 translate <0,10*h,0>}
  object { t6x3x1 translate <0,10*h,b> }
  object { t6x3x1 rotate z*90 translate <b,0,-b> }
  object { t6x3x1 rotate z*90 translate <4*b,0,-b> }
  object { t6x3x1 rotate z*90 translate <b,0,2*b> }
  object { t6x3x1 rotate z*90 translate <4*b,0,2*b> }
// right
  object { t6x3x1 translate <12*b,0,0> }
  object { t6x3x1 translate <12*b,0,b> }
  object { s2x1x3 rotate y*90 translate <-b+17*b,3*h,b> }
  object { s2x1x2 translate <-b+18*b,4*h,0> }
  object { s2x1x1 rotate y*90 translate <5*b+7*b,3*h,b> }
  object { s2x1x1 rotate y*90 translate <5*b+7*b,4*h,b> }

  object { t2x3x1 rotate y*90 translate <-b+18*b,5*h,b> }
  object { t2x3x1 rotate y*90 translate <0+18*b,5*h,b> }
  object { s2x1x3 rotate y*90 translate <-b+17*b,9*h,b> }
  object { s2x1x2 translate <-b+18*b,8*h,0> }
  object { t6x3x1 translate <0+12*b,10*h,0>}
  object { t6x3x1 translate <0+12*b,10*h,b> }

  object { t6x3x1 rotate -z*90 translate <b+12*b,12.5*h,-b> }
  object { t6x3x1 rotate -z*90 translate <4*b+12*b,12.5*h,-b> }
  object { t6x3x1 rotate -z*90 translate <b+12*b,12.5*h,2*b> }
  object { t6x3x1 rotate -z*90 translate <4*b+12*b,12.5*h,2*b> }

  material {t_blue}
 }
 union {
// left
  object { t12x3x1 rotate y*90 translate <5*b,5*h,11*b> }
  object { s2x1x1 rotate y*90 translate <5*b,8*h,b> }
  object { s2x1x1 rotate y*90 translate <5*b,8*h,5*b> }
  object { s6x1x1 rotate y*90 translate <5*b,9*h,5*b> }
  object { t4x3x1 rotate y*90 translate <5*b,10*h,5*b> }
  object { s6x1x1 rotate y*90 translate <5*b,13*h,5*b> }
  object { t2x3x1 rotate <-90,0,90> translate <6*b,5*h,5*b> }
  object { s2x1x1 rotate <-90,0,90> translate <6*b,5*h,5*b-3*h> }
  object { s2x1x6 rotate <-90,0,-90> translate <6*b,7*h,5*b-4*h> }
  object { t12x3x1 rotate <-90,0,90> translate <6*b,5*h,5*b-5*h> }
// right
  object { t2x3x1 rotate <-90,0,90> translate <11*b,5*h,5*b> }
  object { s2x1x1 rotate <-90,0,90> translate <11*b,5*h,5*b-3*h> }
  object { t12x3x1 rotate <-90,0,90> translate <11*b,5*h,5*b-5*h> }
  object { t12x3x1 rotate y*90 translate <12*b,5*h,11*b> }
  object { s2x1x1 rotate y*90 translate <12*b,8*h,b> }
  object { s2x1x1 rotate y*90 translate <12*b,8*h,5*b> }
  object { s6x1x1 rotate y*90 translate <12*b,9*h,5*b> }
  object { t4x3x1 rotate y*90 translate <12*b,10*h,5*b> }
  object { s6x1x1 rotate y*90 translate <12*b,13*h,5*b> }

  material {t_gray}
 }
// left
 object { lp4 rotate y*90 translate <0.5*b,1.2*h,2.5*b> }
 object { lp4 rotate y*90 translate <0.5*b,11.2*h,2.5*b> }
 object { lp12 translate <-3.5*b,6.2*h,0.5*b> }
 object { lego_buggy_clip translate <4.5*b,6.2*h,2.5*b> }
 object { lego_buggy_clip translate <4.5*b,6.2*h,4.5*b> }
 object { lego_buggy_clip rotate y*90 translate <3.5*b,1.2*h,2.5*b> }
 object { lego_buggy_clip rotate y*90 translate <3.5*b,11.2*h,2.5*b> }
 object { lego_buggy_clip rotate y*90 translate <3.5*b,1.2*h,.5*b> }
 object { lego_buggy_clip rotate y*90 translate <3.5*b,11.2*h,.5*b> }
// right
 object { lp4 rotate y*90 translate <0.5*b+13*b,1.2*h,2.5*b> }
 object { lp4 rotate y*90 translate <0.5*b+13*b,11.2*h,2.5*b> }
 object { lp12 translate <-3.5*b+12*b,6.2*h,0.5*b> }
 object { lego_buggy_clip translate <4.5*b+6*b,6.2*h,2.5*b> }
 object { lego_buggy_clip translate <4.5*b+6*b,6.2*h,4.5*b> }
 object { lego_buggy_clip rotate y*90 translate <3.5*b+13*b,1.2*h,2.5*b> }
 object { lego_buggy_clip rotate y*90 translate <3.5*b+13*b,11.2*h,2.5*b> }
 object { lego_buggy_clip rotate y*90 translate <3.5*b+13*b,1.2*h,.5*b> }
 object { lego_buggy_clip rotate y*90 translate <3.5*b+13*b,11.2*h,.5*b> }

}

#declare lego_buggy_seat = union {
 object { s6x1x6 }
 object { s3x1x1 translate <b*3,h,0> }
 object { s4x1x1 translate <b,h*2,0> }
 object { s3x1x1 translate <b*3,h,b*5> }
 object { s4x1x1 translate <b,h*2,b*5> }
 object { p4276b scale 0.875 rotate <0,90,180> translate <b*1.5,h*1.5,0> }
 object { p4276b scale 0.875 rotate <0,90,180> translate <b*1.5,h*1.5,b*5> }
 union {
  object { s8x1x6 translate <-b*8.25,0,0> }
  object { s6x1x1 translate <-b*8.25,h,0> }
  object { s6x1x1 translate <-b*8.25,h,b*5> }
  object { s4x1x1 translate <-b*4.25,2*h,0> }
  object { s4x1x1 translate <-b*4.25,2*h,b*5> }
  object { p4275b scale 0.875 rotate <0,90,180> translate <-b*1.75,h*1.5,0> }
  object { p4275b scale 0.875 rotate <0,90,180> translate <-b*1.75,h*1.5,b*5> }
  rotate <0,0,-65>
 }
 material {t_blue}
}

#declare lego_buggy_window = union {
 union {
  object { lp12 } 
  object { lego_buggy_clip4 rotate -x*90 translate x*b*11} 
  object { lego_buggy_clip4 rotate <-90,180,0> translate x*b } 
  object { lego_buggy_clip1 rotate -z*90 translate <-0.5*b,h*1.2,0> }
  object { lego_buggy_clip1 rotate -z*90 translate <12.5*b,h*1.2,0> } 
  translate y*h*3
 }
 union {
  object { lp12 }
  object { lego_buggy_clip4 rotate -x*90 translate x*b*11}
  object { lego_buggy_clip4 rotate <-90,180,0> translate x*b }
  object { lego_buggy_clip1 rotate -z*90 translate <-0.5*b,h*1.2,0> }
  object { lego_buggy_clip1 rotate -z*90 translate <12.5*b,h*1.2,0> }
  object { lego_buggy_clip1 rotate z*90 translate <-0.5*b,-2.2*h,0> }
  object { lego_buggy_clip1 rotate z*90 translate <12.5*b,-2.2*h,0> }
  translate y*h*19
 }
 object { lp8 rotate <0,0,90> translate -x*b*0.5}
 object { lp8 rotate <0,0,90> translate x*b*12.5 }
 object { lego_buggy_clip3 rotate <90,0,-90> translate <-b*0.5,2*h,0>}
 object { lego_buggy_clip3 rotate <90,0,-90> translate <b*12.5,2*h,0>}
 object { lego_buggy_clip translate <-b,-1.8*h,0> }
 object { lego_buggy_clip rotate y*180 translate <b*13,-1.8*h,0> }
}

#declare armatur = union {
 union {
  object { s2x1x4 }                                                      // 183
  object { s2x1x4 translate <0,0,-b*4> }                                 // 184
  object { s2x1x4 translate <0,0,b*4> }                                  // 182
  object { s2x1x10 translate <0,h,-3*b> }                                // 185
  object { t4x3x1 translate <0,2*h,-3*b> }                               // 186
  object { t4x3x1 translate <0,2*h,6*b> }                                // 187
  object { t4x3x1 rotate y*90 translate <0,2*h,b> }                      // 188
  object { t4x3x1 rotate y*90 translate <0,2*h,5*b> }                    // 189
  object { t4x3x1 translate <0,-3*h,-4*b> }                              // 190
  object { t4x3x1 translate <0,-3*h,7*b> }                               // 191
  object { lp4 rotate y*90 translate <2.5*b,3*h,-2*b> }                  // 192
  object { lego_buggy_clip1 rotate -y*90 translate <2.5*b,3*h,-2.5*b> }             // 194
  object { lp4 rotate -y*90 translate <2.5*b,3*h,5*b> }                  // 193
  object { lego_buggy_clip1 rotate y*90 translate <2.5*b,3*h,5.5*b> }               // 195
  object { lego_buggy_clip rotate y*90 translate <2.5*b,-2*h,-3.5*b> }              // 198
  object { lego_buggy_clip rotate y*90 translate <0.5*b,-2*h,-3.5*b> }              // 199
  object { lego_buggy_clip rotate -y*90 translate <2.5*b,-2*h,6.5*b> }              // 196
  object { lego_buggy_clip rotate -y*90 translate <0.5*b,-2*h,6.5*b> }              // 197
  object { s2x1x10 translate <0,h*5,-3*b> }                              // 200
  object { lego_buggy_clip1 rotate -y*90 translate <2.5*b,3*h,8.5*b> }              // 215
  object { lego_buggy_clip1 rotate y*90 translate <2.5*b,3*h,-5.5*b> }              // 220
  object { lego_buggy_clip rotate -y*90 translate <2.5*b,-2.5*b,7.5*b> }            // 216
  object { lego_buggy_clip rotate y*90 translate <2.5*b,-2.5*b,-5*b> }              // 221
  object { lego_buggy_clip2 rotate -y*90 translate <2.5*b,-4.5*b,9*b> }             // 222
  object { lego_buggy_clip2 rotate y*90 translate <2.5*b,-4.5*b,-6*b> }             // 223
  material {t_black}
 }
 union {
  object { t4x3x1 rotate z*90 translate <b,-3.2*h,8*b> }                 // 210
  object { t4x3x1 rotate z*90 translate <b,-3.2*h,-5*b> }                // 211
  object { s4x1x1 rotate z*90 translate <b+h,-3.2*h,8*b> }               // 212
  object { s4x1x1 rotate z*90 translate <b+h,-3.2*h,-5*b> }              // 217
  object { s4x1x4 rotate z*90 translate <b+2*h,-3.2*h,8*b> }             // 213
  object { s4x1x4 rotate z*90 translate <b+2*h,-3.2*h,-8*b> }            // 218
  object { t8x3x1 rotate z*90 translate <b+5*h,-13.2*h,8*b> }            // 214
  object { t8x3x1 rotate z*90 translate <b+5*h,-13.2*h,-5*b> }           // 219
  material {t_red}
 }
  
 object {lenkrad rotate <0,90,180> translate <-b+h,3*h,2.5*b> material{t_black}}
}

#declare lenklager = union {
 object { s2x1x4 translate <0,0,-b*1.5> }                                // 16a
 object { s1x1x1 translate <-b,0,-b*1.5> }                               // 17
 object { s1x1x1 translate <-b,0,b*1.5> }                                // 18
 union {
  object { p2738 scale 0.91 rotate <0,180,180> translate <b+7.5*h,8.2*h,b*5.55>  }
  object { p2738 scale 0.91 rotate <180,0,180> translate <b+7.5*h,-1.75*h,b*5.55> }
  object { p2738 scale 0.91 rotate <0,0,180> translate <b+7.5*h,8.2*h,-b*5.55>  }
  object { p2738 scale 0.91 rotate <180,180,180> translate <b+7.5*h,-1.75*h,-b*5.55> }
  material {t_blue}
 }
 union {
  object { bolzen scale 0.92 rotate <0,-90,0> translate <b+7.5*h,3*h,b*8.5> }
  object { bolzen scale 0.92 rotate <0,90,180> translate <b+7.5*h,3*h,-b*8.5> }
 }
 union {
  object { sf1x1x1 translate <b,h,b*.5> }                                // 19
  object { sf1x1x1 translate <b,h,-b*.5> }                               // 20
  object { s10x1x1 rotate -y*90 translate <0,20*h,-b*4.5> }              // 148
  object { s8x1x1 rotate -y*90 translate <0,21*h,-b*3.5> }               // 149
  object { t6x3x1 rotate -y*90 translate <0,22*h,-b*2.5> }               // 150
  object { t12x3x1 rotate <90,0,90> translate <-b,-h*3,-.5*b> }          // 154
   
  object { lego_buggy_clip2 rotate -y*90 translate <b+7.5*h,3*h,b*7> }            // lego_buggy_clip achse innen
  object { lego_buggy_clip2 rotate  y*90 translate <b+7.5*h,3*h,-b*7> }           // lego_buggy_clip achse innen
  object { lego_buggy_clip2 rotate -y*90 translate <b+7.5*h,3*h,b*9> }            // lego_buggy_clip achse mitte
  object { lego_buggy_clip2 rotate  y*90 translate <b+7.5*h,3*h,-b*9> }           // lego_buggy_clip achse mitte
  material {t_gray}
 }
 union {
  object { s2x1x1 translate <-b,h,-b*1.5> }                               // 21
  object { s2x1x1 translate <-b,h,b*1.5> }                                // 22
  object { t4x3x1 rotate -y*90 translate <0,2*h,-b*1.5> }                 // 23
  object { s1x3x1 translate <-b,2*h,-b*1.5> }                             // 24
  object { s1x3x1 translate <-b,2*h,b*1.5> }                              // 25
  object { s2x1x1 rotate -y*90 translate <0,5*h,-b*.5> }                  // 26
  object { s2x1x1 translate <-b,5*h,-b*1.5> }                             // 27
  object { s2x1x1 translate <-b,5*h,b*1.5> }                              // 28
  object { s4x1x1 rotate -y*90 translate <0,6*h,-b*1.5> }                 // 29
  object { s1x1x1 translate <-b,6*h,-b*1.5> }                             // 30
  object { s1x1x1 translate <-b,6*h,b*1.5> }                              // 31
  object { t2x3x1 rotate -y*90 translate <0,7*h,-b*.5> }                  // 32
  object { t2x3x1 translate <-b,7*h,-b*1.5> }                             // 33
  object { t2x3x1 translate <-b,7*h,b*1.5> }                              // 34
  object { s4x3x1 rotate -y*90 translate <0,10*h,-b*1.5> }                // 43
  object { s6x1x1 rotate -y*90 translate <0,13*h,b*.5> }                 // 140
  object { s6x1x1 rotate y*90 translate <0,13*h,-b*.5> }                 // 141
  object { s2x3x1 rotate -y*90 translate <0,14*h,-b*.5> }                // 142
  object { t2x3x1 rotate -y*90 translate <0,17*h,-b*.5> }                // 143
  object { s2x3x1 rotate y*90 translate <0,14*h,-b*4.5> }                // 144
  object { s2x1x1 rotate y*90 translate <0,17*h,-b*4.5> material {t_red}} // 152
  object { s2x3x1 rotate -y*90 translate <0,14*h,b*4.5> }                // 145
  object { s2x1x1 rotate -y*90 translate <0,17*h,b*4.5> material {t_red}} // 153
  object { lego_buggy_clip translate <-1.5*b,18.2*h,0> }                            // 146
  object { lego_buggy_clip translate <-1.5*b,3.2*h,0> }                             // 147
  object { lego_buggy_clip translate <-1.5*b,23.2*h,0> }                            // 151
   
  object { lp6 rotate -y*90 translate <b+7.5*h,3*h,b*7> }              // achse
  object { lp6 rotate  y*90 translate <b+7.5*h,3*h,-b*7> }             // achse
  material {t_black}
 }
 material {t_gray}
}

#declare stossstange = union {
 union {
  object { s8x1x1 rotate y*90 translate <b*17,8*h,b*3.5> }               // 70
  object { s6x1x1 translate <b*12,14*h,b*3.5> }                          // 83
  object { s6x1x1 translate <b*12,14*h,-b*3.5> }                         // 84
  object { s6x1x1 rotate y*90 translate <b*17,14*h,b*2.5> }              // 160
  object { t8x3x1 rotate y*90 translate <b*17,15*h,b*3.5> }              // 161
  object { s1x1x1 translate <b*17,19*h,b*3.5> }                          // 164
  object { s1x1x1 translate <b*17,19*h,-b*3.5> }                         // 165
  object { s3x1x1 rotate -y*90 translate <b*17,20*h,b*3.5> }             // 166
  object { s3x1x1 rotate y*90 translate <b*17,20*h,-b*3.5> }             // 167
  object { t2x3x1 rotate -y*90 translate <b*17,21*h,b*3.5> }             // 168
  object { t2x3x1 rotate y*90 translate <b*17,21*h,-b*3.5> }             // 169
  object { t12x3x1 translate <b*6,21*h,b*5.5> }                          // 201
  object { t12x3x1 translate <b*6,21*h,-b*5.5> }                         // 202
  object { s10x1x6 translate <b*8,24*h,b*4.5> }                          // 230
  object { s10x1x6 translate <b*8,24*h,-b*9.5> }                         // 231
  object { s10x1x1 translate <b*8,25*h,b*5.5> }                          // 232
  object { s10x1x1 translate <b*8,25*h,-b*5.5> }                         // 233
  object { t12x3x1 translate <b*6,26*h,b*5.5> }                          // 234
  object { t12x3x1 translate <b*6,26*h,-b*5.5> }                         // 235
  object { s4x1x1 rotate y*90 translate <b*17,29*h,b*3.5> }              // 237
  object { s4x1x1 rotate -y*90 translate <b*17,29*h,-b*3.5> }            // 238
  object { s2x1x4 rotate y*90 translate <b*14,29*h,b*5.5> }              // 239
  object { s2x1x4 rotate -y*90 translate <b*17,29*h,-b*5.5> }            // 241
  object { s2x1x8 rotate y*90 translate <b*6,29*h,b*5.5> }               // 240
  object { s2x1x8 rotate -y*90 translate <b*13,29*h,-b*5.5> }            // 242
  object { s10x1x6 rotate y*90 translate <b*12,30*h,b*4.5> }             // 243
  object { s10x1x6 rotate y*90 translate <b*6,30*h,b*4.5> }              // 244
  material {t_red}
 }
 union {
  object { s4x1x1 rotate y*90 translate <b*12,14*h,b*.5> }                // 85
  object { s1x1x1 translate <b*17,18*h,b*3.5> }                          // 162
  object { s1x1x1 translate <b*17,18*h,-b*3.5> }                         // 163
  object { s8x1x1 rotate y*90 translate <b*17,24*h,b*3.5> }              // 170
  object { t6x3x1 rotate y*90 translate <b*17,25*h,b*2.5> }              // 171
  material {t_gray}
 }
 union {
  object { s4x1x1 translate <b*17,9*h,b*3.5> }                            // 71
  object { s4x1x1 translate <b*17,9*h,-b*3.5> }                           // 72
  object { s6x1x1 rotate y*90 translate <b*20,9*h,b*2.5> }                // 73
  object { t4x3x1 translate <b*16,10*h,b*3.5> }                           // 74
  object { t4x3x1 translate <b*16,10*h,-b*3.5> }                          // 75
  object { t4x3x1 rotate y*90 translate <b*20,10*h,b*1.5> }               // 76
  object { t8x3x1 rotate y*90 translate <b*20,10*h,b*9.5> }               // 77
  object { t8x3x1 rotate -y*90 translate <b*20,10*h,-b*9.5> }             // 78
  object { s4x1x1 translate <b*17,13*h,-b*3.5> }                          // 79
  object { s4x1x1 translate <b*17,13*h,b*3.5> }                           // 80
  object { s3x1x1 rotate y*90 translate <b*20,13*h,b*2.5> }               // 81
  object { s3x1x1 rotate -y*90 translate <b*20,13*h,-b*2.5> }             // 82
  object { s2x1x2 translate <b*12,14*h,b*1.5> }                           // 86
  object { s2x1x1 rotate y*90 translate <b*17,9*h,b*2.5> }               // 155
  object { s2x1x1 rotate -y*90 translate <b*17,9*h,-b*2.5> }             // 156
  object { t2x3x1 rotate y*90 translate <b*17,10*h,b*2.5> }              // 157
  object { t2x3x1 rotate -y*90 translate <b*17,10*h,-b*2.5> }            // 158
  object { s6x1x1 rotate y*90 translate <b*17,13*h,b*2.5> }              // 159
  object { t4x3x1 rotate -z*90 translate <b*16,12.4*h,b*4.5> }           // 203
  object { t4x3x1 rotate -z*90 translate <b*16,12.4*h,-b*4.5> }          // 204
  object { s10x1x1 rotate y*90 translate <b*17,28*h,b*4.5> }             // 236
  object { s2x1x1 rotate <90,90,0> translate <b*17.5,26.5*h,4.5*b> }     // 254
  object { s2x1x1 rotate <90,90,0> translate <b*17.5,26.5*h,-3.5*b> }    // 255
  material {t_black}
 }
  object { lego_buggy_clip translate <b*16,11*h,-b*2> }                             // 172
  object { lego_buggy_clip translate <b*16,11*h,b*2> }                              // 173
  object { lego_buggy_clip translate <b*16.5,26*h,-b*2> }                           // 174
  object { lego_buggy_clip translate <b*16.5,26*h,0> }                              // 175
  object { lego_buggy_clip translate <b*16.5,26*h,b*2> }                            // 176
  object { lego_buggy_clip translate <b*16.5,16*h,0> }                              // 177
  object { lego_buggy_clip rotate y*90 translate <b*16.5,11.2*h,4.5*b> }            // 205
  object { lego_buggy_clip rotate -y*90 translate <b*16.5,11.2*h,-4.5*b> }          // 206
  object { lp12 rotate y*90 translate <b*16.5,6*h,b*6> }                 // 207
  object { lego_buggy_clip2 rotate -y*90 translate <b*16.5,6*h,b*5> }               // 208
  object { lego_buggy_clip2 rotate y*90 translate <b*16.5,6*h,-b*5> }               // 209
  object { lp4 translate <b*14,16*h,-b*2> }                              // 178
  object { lp4 translate <b*14,16*h,b*2> }                               // 179
  object { lego_buggy_clip1 rotate y*180 translate <b*18.5,16*h,b*2> }              // 180
  object { lego_buggy_clip1 rotate y*180 translate <b*18.5,16*h,-b*2> }             // 181
  object { lego_buggy_clip3 rotate <90,0,-90> translate <b*18,19.7*h,0> }           // 245
  object { lego_buggy_clip3 rotate <90,0,90> translate <b*18,22.3*h,0> }            // 246
  object { lego_buggy_clip3 rotate <90,0,90> translate <b*18,22.3*h,-b*2> }         // 247
  object { lego_buggy_clip3 rotate <90,0,90> translate <b*18,22.3*h,b*2> }          // 248
  object { lp3 rotate <90,0,-90> translate <b*18,25*h,0> }               // 249
  object { lp3 rotate <90,0,-90> translate <b*18,25*h,-b*2> }            // 250
  object { lp3 rotate <90,0,-90> translate <b*18,25*h,b*2> }             // 251
  object { lego_buggy_clip4 rotate <90,0,-90> rotate y*180 translate
    <b*18,19.7*h,b*2> }  // 252
  object {
    lego_buggy_clip4
    rotate <90,0,-90>
    rotate y*180
    translate <b*18,19.7*h,-b*2>
  }                                                                      // 253

 union {
  cylinder { <b*17.5+nh,25.5*h,4*b> <b*17.5+h+nh,25.5*h,4*b>, 0.666
             material {t_white} }                                         // 256
  cylinder { <b*17.5+nh,25.5*h,-4*b> <b*17.5+h+nh,25.5*h,-4*b>, 0.666
             material {t_white} }                                         // 257
 }
}

#declare hinterteil = union {
 object { t16x3x1 translate <-b*12,10*h,-b*4.5> }                         // 87
 object { t16x3x1 translate <-b*12,10*h,b*4.5> }                          // 88
 object { s2x1x3 translate <-b*2,13*h,-b*4.5> }                           // 89
 object { s2x1x3 translate <-b*2,13*h,b*2.5> }                            // 90
 object { s4x1x1 translate <0,13*h,b*4.5> }                               // 91
 object { s4x1x1 translate <0,13*h,b*2.5> }                               // 92
 object { s4x1x1 translate <0,13*h,-b*4.5> }                              // 94
 object { s4x1x1 translate <0,13*h,-b*2.5> }                              // 93
 object { lego_buggy_clip rotate -y*90 translate <-b*5.5,h*11.2,4*b> }               // 95
 object { lego_buggy_clip rotate -y*90 translate <-b*7.5,h*11.2,4*b> }               // 96
 object { lego_buggy_clip rotate y*90 translate <-b*5.5,h*11.2,-4*b> }               // 97
 object { lego_buggy_clip rotate y*90 translate <-b*7.5,h*11.2,-4*b> }               // 98
 object { t4x3x1 translate <-b*8,10*h,b*5.5> }                            // 99
 object { t4x3x1 translate <-b*8,10*h,-b*5.5> }                          // 100
 object { lego_buggy_clip rotate -y*90 translate <-b*6.5,h*11.2,5*b> }              // 101
 object { lego_buggy_clip rotate y*90 translate <-b*6.5,h*11.2,-5*b> }              // 102
 object { t2x3x1 rotate y*90 translate <-b*12,7*h,b*4.5> }               // 103
 object { t2x3x1 rotate -y*90 translate <-b*12,7*h,-b*4.5> }             // 105
 object { s1x3x1 translate <-b*12,10*h,b*3.5> }                          // 104
 object { s1x3x1 translate <-b*12,10*h,-b*3.5> }                         // 106
 object { lego_buggy_clip translate <-b*13.5,h*8.2,4*b> }                           // 107
 object { lego_buggy_clip translate <-b*13.5,h*8.2,-4*b> }                          // 108
 object { s10x1x1 rotate y*90 translate <-b*12,h*13,b*4.5> }             // 109
 object { s1x3x1 translate <-b*12,14*h,b*4.5> }                          // 110
 object { s1x3x1 translate <-b*12,14*h,-b*4.5> }                         // 111
 union {
  object { s4x1x1 rotate -y*90 translate <-b,14*h,b*2.5> }               // 112
  object { s4x1x1 rotate -y*90 translate <0,14*h,b*2.5> }                // 113
  object { s4x1x1 rotate -y*90 translate <b,14*h,b*2.5> }                // 114
  object { s4x1x1 rotate y*90 translate <-b,14*h,-b*2.5> }               // 115
  object { s4x1x1 rotate y*90 translate <0,14*h,-b*2.5> }                // 116
  object { s4x1x1 rotate y*90 translate <b,14*h,-b*2.5> }                // 117
  object { t16x3x1 rotate y*90 translate <-b*12,h*17,b*7.5> }            // 118
  object { t16x3x1 rotate y*90 translate <-b*12,h*22,b*7.5> }            // 123
  object { s2x1x1 translate <-b*12,20*h,b*7.5> }                         // 119
  object { s2x1x1 translate <-b*12,21*h,b*7.5> }                         // 120
  object { s2x1x1 translate <-b*12,20*h,-b*7.5> }                        // 121
  object { s2x1x1 translate <-b*12,21*h,-b*7.5> }                        // 122
  object { lego_buggy_clip translate <-b*13.5,h*18.2,4*b> }                         // 124
  object { lego_buggy_clip translate <-b*13.5,h*18.2,-4*b> }                        // 125
  object { lego_buggy_clip translate <-b*13.5,h*18.2,7*b> }                         // 126
  object { lego_buggy_clip translate <-b*13.5,h*18.2,-7*b> }                        // 127
  object { lego_buggy_clip translate <-b*13.5,h*23.2,7*b> }                         // 128
  object { lego_buggy_clip translate <-b*13.5,h*23.2,-7*b> }                        // 129
  object { t4x3x1 rotate <90,0,90> translate <-b*13,17*h,6.5*b> }        // 130
  object { t4x3x1 rotate <-90,0,90> translate <-b*13,17*h,-6.5*b> }      // 131
  object { t6x3x1 rotate <90,0,90> translate <-b*13,7*h,3.5*b> }         // 132
  object { t6x3x1 rotate <-90,0,90> translate <-b*13,7*h,-3.5*b> }       // 133
  object { t8x3x1 translate <-b*11,22*h,b*7.5> }                         // 134
  object { t8x3x1 translate <-b*11,22*h,-b*7.5> }                        // 135
  object { lego_buggy_clip rotate -y*90 translate <-b*5.5,h*23.2,6*b> }             // 136
  object { lego_buggy_clip rotate y*90 translate <-b*5.5,h*23.2,-6*b> }             // 137
  object { lego_buggy_clip rotate -y*90 translate <-b*4.5,h*23.2,7*b> }             // 138
  object { lego_buggy_clip rotate y*90 translate <-b*4.5,h*23.2,-7*b> }             // 139
  object { lego_buggy_clip rotate -y*90 translate <-b*2.1,h*15.4,7*b> }             // 226
  object { lego_buggy_clip rotate y*90 translate <-b*2.1,h*15.4,-7*b> }             // 227
  object { t8x3x1 translate <-b*2.6,14.4*h,b*7.5> }                      // 224
  object { t8x3x1 translate <-b*2.6,14.4*h,-b*7.5> }                     // 225
  object { t6x3x1 rotate -z*52 translate <-b*5.2,23.5*h,b*8.5> }         // 228
  object { t6x3x1 rotate -z*52 translate <-b*5.2,23.5*h,-b*8.5> }        // 229
  material {t_red}
 }
 material {t_gray}
}

#declare carosserie = union {
 object { t6x3x1 translate <-b*2,0,-b*2.5> }                              // 1
 object { lego_buggy_clip rotate -y*90 translate <-b*1.5,h*1.2,-b*3> }            // lego_buggy_clip1
 object { lego_buggy_clip rotate y*90 translate <b/2,h*1.2,-b> }                  // lego_buggy_clip3
 object { lego_buggy_clip rotate y*90 translate <b*2.5,h*1.2,-b> }                // lego_buggy_clip4
 object { lego_buggy_clip rotate y*90 translate <b*7.5,h*1.2,-b> }                // lego_buggy_clip7
 object { lego_buggy_clip rotate y*90 translate <b*7.5,h*11.2,-b> }              // lego_buggy_clip13
 object { lego_buggy_clip rotate y*90 translate <b*10.5,h*1.2,0> }                // lego_buggy_clip9
 object { lego_buggy_clip rotate y*90 translate <b*10.5,h*6.2,0> }               // lego_buggy_clip11
 object { t6x3x1 translate <-b*2,0,b*2.5> }                               // 2
 object { lego_buggy_clip rotate y*90 translate <-b*1.5,h*1.2,b*3> }              // lego_buggy_clip2
 object { lego_buggy_clip rotate -y*90 translate <b/2,h*1.2,b> }                  // lego_buggy_clip5
 object { lego_buggy_clip rotate -y*90 translate <b*2.5,h*1.2,b> }                // lego_buggy_clip6
 object { lego_buggy_clip rotate -y*90 translate <b*7.5,h*1.2,b> }                // lego_buggy_clip8
 object { lego_buggy_clip rotate -y*90 translate <b*7.5,h*11.2,b> }              // lego_buggy_clip14
 object { lego_buggy_clip rotate -y*90 translate <b*10.5,h*1.2,0> }              // lego_buggy_clip10
 object { lego_buggy_clip rotate -y*90 translate <b*10.5,h*6.2,0> }              // lego_buggy_clip12
 object { s2x1x1 translate <-b*2,3*h,-b*2.5> }                         // 5
 object { s2x1x1 translate <-b*2,3*h,b*2.5> }                          // 6
 object { s4x1x1 translate <b*10,3*h,-b*1.5> }                         // 7
 object { s4x1x1 translate <b*10,3*h,b*1.5> }                          // 9
 object { s4x1x1 translate <b*10,4*h,-b*1.5> }                         // 8
 object { s4x1x1 translate <b*10,4*h,b*1.5> }                          // 10
 object { t12x3x1 translate <0,0,-b*1.5> }                             // 3
 object { t12x3x1 translate <0,0,b*1.5> }                              // 4
 object { t4x3x1 rotate -z*90 translate <b*10,b*3,-b/2> }              // 13
 object { t4x3x1 rotate -z*90 translate <b*10,b*3,b/2> }               // 14
 object { s6x1x1 rotate y*90  translate <b*3,3*h,b*2.5> }              // 15
 object { t8x3x1 rotate y*90  translate <b*12,0,b*3.5> }               // 16
 object { t8x3x1 rotate y*90  translate <b*12,10*h,b*3.5> }            // 69
  
 object { lp3 translate <b*10.5,h*1.2,b*3>}                            // 63a
 object { lego_buggy_clip1 translate <b*13,h*1.2,b*3> }                           // 65a
 object { lego_buggy_clip1 rotate z*180 translate <b*11,h*1.2,b*3> }              // 66a
 object { lp3 translate <b*10.5,h*1.2,-b*3>}                           // 64a
 object { lego_buggy_clip1 translate <b*13,h*1.2,-b*3> }                          // 67a
 object { lego_buggy_clip1 rotate z*180 translate <b*11,h*1.2,-b*3> }             // 68a
  
 object { lp3 translate <b*10.5,h*11.2,b*3>}                           // 63b
 object { lego_buggy_clip1 translate <b*13,h*11.2,b*3> }                          // 65b
 object { lego_buggy_clip1 rotate z*180 translate <b*11,h*11.2,b*3> }             // 66b
 object { lp3 translate <b*10.5,h*11.2,-b*3>}                          // 64b
 object { lego_buggy_clip1 translate <b*13,h*11.2,-b*3> }                         // 67b
 object { lego_buggy_clip1 rotate z*180 translate <b*11,h*11.2,-b*3> }            // 68b

 object { s6x1x1 translate <-b*2,4*h,-b*2.5> }                         // 35
 object { s6x1x1 translate <-b*2,4*h,b*2.5> }                          // 36
 object { t6x3x1 translate <-b*2,10*h,-b*2.5> }                        // 56
 object { t6x3x1 translate <-b*2,10*h,b*2.5> }                         // 57
 object { s6x1x1 translate <-b*2,8*h,-b*2.5> }                         // 48
 object { s6x1x1 translate <-b*2,8*h,b*2.5> }                          // 49
 object { s2x1x3 translate <-b*2,9*h,-b*4.5> }                         // 50
 object { s2x1x3 translate <b*2,9*h,-b*4.5> }                          // 51
 object { s2x1x3 translate <-b*2,9*h,b*2.5> }                          // 53
 object { s2x1x3 translate <b*2,9*h,b*2.5> }                           // 52
 object { s1x1x1 translate <b*12,8*h,-b*1.5> }                         // 37
 object { s1x1x1 translate <b*12,9*h,-b*1.5> }                         // 38
 object { s1x1x1 translate <b*12,8*h,b*1.5> }                          // 39
 object { s1x1x1 translate <b*12,9*h,b*1.5> }                          // 40
 object { t2x3x1 translate <b*2,5*h,-b*2.5> }                          // 44
 object { t2x3x1 translate <-b*2,5*h,-b*2.5> }                         // 45
 object { t2x3x1 translate <b*2,5*h,b*2.5> }                           // 46
 object { t2x3x1 translate <-b*2,5*h,b*2.5> }                          // 47
 object { t6x3x1 rotate z*90 translate <8*b,0,-b*2.5> }                // 41
 object { t6x3x1 rotate z*90 translate <8*b,0,b*2.5> }                 // 42
 object { t6x3x1 rotate z*90 translate <-1*b,0,-b*1.5> }               // 54
 object { t6x3x1 rotate z*90 translate <-1*b,0,b*1.5> }                // 55
 object { t6x3x1 rotate -z*90 translate <b,b*5,-b*.5> }                // 61
 object { t6x3x1 rotate -z*90 translate <b,b*5,b*.5> }                 // 62
 union {
  object { t8x3x1 translate <b*10,5*h,-b*1.5>}                         // 11
  object { t8x3x1 translate <b*10,5*h,b*1.5> }                         // 12
  object { lp12 rotate y*90 translate <-1.5*b,6.2*h,b*6> }             // 58
  object { lp10 rotate y*90 translate <-1.5*b,11.2*h,b*5> }            // 59
  object { lp10 rotate y*90 translate <1.5*b,1.2*h,5*b> }              // 258
  object { lego_buggy_clip2 rotate y*90 translate <1.5*b,1.2*h,5*b> }             // 259
  object { lego_buggy_clip2 rotate -y*90 translate <1.5*b,1.2*h,-5*b> }           // 260
  object { lp10 rotate y*90 translate <-.5*b,11.2*h,b*5> }             // 60
  object { lp10 rotate y*90 translate <1.5*b,11.2*h,b*5> }             // 63
  material {t_black}
 }
 material {t_gray}
}

#declare lego_buggy = union {
 object { lego_buggy_seat translate <-3*b,15*h,b*1.5>  }
 object { lego_buggy_seat translate <-3*b,15*h,-b*6.5> }
  
 object { lego_buggy_window rotate <0,90,20> translate <7.5*b,29*h,6*b> }
 object { armatur rotate -z*45 translate <3.9*b,24.46*h,-1.5*b> }

 object { lenklager translate <8*b,3*h,0> }
 object { stossstange }
  
 object { hinterteil }
 object { carosserie }
 object { hinterradlager rotate <0,90,0> translate <-9*b,-5*h,8.5*b> }

 /*
 object { lego_buggy_wheel rotate <0,-90,0> translate <-8.5*b,0.5*b,10*b> }
 object { lego_buggy_wheel rotate <0,90,0>  translate <-8.5*b,0.5*b,-10*b> }
 object { lego_buggy_wheel rotate <0,-90,0> translate <12*b,2.5*b,10*b> }
 object { lego_buggy_wheel rotate <0,90,0>  translate <12*b,2.5*b,-10*b> }
 */
}

/* scene objects ----------------------------------------------------------- */

// object { lego_buggy rotate <0,0,-5.7> translate <0,2.5,0> rotate y*-5.7}
