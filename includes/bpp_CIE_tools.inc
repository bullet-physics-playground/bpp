/*
  Persistence of Vision Ray Tracer Include File

  Some additional macros for the use with CIE.inc
  
  The Imagemap* macros are based on Jaimes's idea to process image maps 
  through the RGB working space as currently defined by the settings 
  from CIE.inc.

  Ive, Mai-2003

  Needs CIE.inc

*/


#ifndef (CIE_tools_Inc_Temp)
#declare CIE_tools_Inc_Temp = 1;

#ifdef(View_POV_Include_Stack)
  #debug "Including bpp_CIE_tools.inc\n"
#end

//==============================================================
// Image map stuff
//==============================================================

/* Simple macro to process image maps and use the settings from CIE.inc.
 * Image has to be defined like: pigment{image_map{png "my_image.png"}}
 */
#macro CIE_Imagemap(Image)
  #local K  = ReferenceRGB(<0,0,0>)*3; 
  #local R1 = ReferenceRGB(<1,0,0>)*3;
  #local G1 = ReferenceRGB(<0,1,0>)*3;
  #local B1 = ReferenceRGB(<0,0,1>)*3;
  #local fn = function { pigment{Image} }
  pigment{
    average
    pigment_map{
      [function{fn(x,y,z).red}   color_map{[0 rgb K][1 rgb R1]}]
      [function{fn(x,y,z).green} color_map{[0 rgb K][1 rgb G1]}]
      [function{fn(x,y,z).blue}  color_map{[0 rgb K][1 rgb B1]}]
    }
  }
#end


/* Same as above but also brightness and contrast can be changed
 * similar to tv control or image processing software.
 * In opposite to some other implementation contrast of 0 gives
 * 50% gray and not black.
 * Brightness and Contrast can be either a single value or a
 * rgb color vector to adjust each channel separately.
 */
#macro CIE_Imagemap_BC(Image, Brightness, Contrast)
  #local Brightness = Brightness*<0.5,0.5,0.5>;
  #local Contrast   = Contrast*<0.5,0.5,0.5>;
  #local C_min = -Contrast+Brightness;
  #local C_max =  Contrast+Brightness;
  #local R0 = ReferenceRGB2RGB(<C_min.red,0,0>)*3;
  #local G0 = ReferenceRGB2RGB(<0,C_min.green,0>)*3;
  #local B0 = ReferenceRGB2RGB(<0,0,C_min.blue>)*3;
  #local R1 = ReferenceRGB2RGB(<C_max.red,0,0>)*3;
  #local G1 = ReferenceRGB2RGB(<0,C_max.green,0>)*3;
  #local B1 = ReferenceRGB2RGB(<0,0,C_max.blue>)*3;
  #local fn = function { pigment{Image} }
  pigment{
    average
    pigment_map{
      [function{fn(x,y,z).red}   color_map{[0 rgb R0][1 rgb R1]}]
      [function{fn(x,y,z).green} color_map{[0 rgb G0][1 rgb G1]}]
      [function{fn(x,y,z).blue}  color_map{[0 rgb B0][1 rgb B1]}]
    }
  }
#end


/* Process image map through LCH color space where:
 * - Lightness is *not* the same as brightness
 * - Chroma = 0 produces grayscale images
 * - HueShift is in the range of 0..1 so 0.5 does rotate 180°
 */
#macro CIE_Imagemap_LCH(Image, Lightness, Chroma, HueShift)
  #local Lightness = sqrt(Lightness);
  #local Hue = 2*pi*HueShift;
  #local CM = ChromaMatchFunction;
  CIE_ChromaticAdaption(off)
  #local K = RGB2Lch(<0,0,0>);
  #local R = RGB2Lch(<1,0,0>);
  #local G = RGB2Lch(<0,1,0>);
  #local B = RGB2Lch(<0,0,1>);
  CIE_ChromaticAdaption(CM)
  #local K = Lch2RGB(<K.x*Lightness, K.y*Chroma, K.z+Hue>)*3;
  #local R = Lch2RGB(<R.x*Lightness, R.y*Chroma, R.z+Hue>)*3;
  #local G = Lch2RGB(<G.x*Lightness, G.y*Chroma, G.z+Hue>)*3;
  #local B = Lch2RGB(<B.x*Lightness, B.y*Chroma, B.z+Hue>)*3;
  #local fn = function { pigment{Image} }
  pigment{
    average
    pigment_map{
      [function{fn(x,y,z).red}   color_map{[0 rgb K][1 rgb R]}]
      [function{fn(x,y,z).green} color_map{[0 rgb K][1 rgb G]}]
      [function{fn(x,y,z).blue}  color_map{[0 rgb K][1 rgb B]}]
    }
  }
#end


//==============================================================
// Gamma correction stuff
//==============================================================

// simple gamma correction
// Ive: note I've renamed the gamma parameter, as using the same
// as local later, lead to strange results. 
#macro GammaRGB(RGB, pGamma)
  #local Gamma = <1,1,1>/pGamma;//make sure it's a vector
  <pow(RGB.red, Gamma.red), 
   pow(RGB.green, Gamma.green), 
   pow(RGB.blue, Gamma.blue)>
#end


// sRGB gamma 2.2 correction IEC 61966-2-1 
// (International Electrotechnical Commission)
// This sRGB gamma correction uses a fixed value of 2.2 and
// is composed of two separate functions 
#macro GammaCorrectXYZ2RGB(C)
  (C<=0.0031308 ? (12.92*C) : (1.055*pow(C,1/2.4)-0.055))
#end

#macro GammaXYZ2RGB(RGB)
  <GammaCorrectXYZ2RGB(RGB.red), 
   GammaCorrectXYZ2RGB(RGB.green), 
   GammaCorrectXYZ2RGB(RGB.blue)>
#end

// sRGB gamma (the inverse of the function above)
#macro GammaCorrectRGB2XYZ(C)
  (C<=0.04045 ? (C/12.92) : pow((C+0.055)/1.055,2.4))
#end

#macro GammaRGB2XYZ(RGB)
  <GammaCorrectRGB2XYZ(RGB.red), 
   GammaCorrectRGB2XYZ(RGB.green), 
   GammaCorrectRGB2XYZ(RGB.blue)>
#end
   
//==============================================================

// EOF
#end
