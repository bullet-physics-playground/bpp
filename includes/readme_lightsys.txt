============================================
BPP LightSys 4 - lighting macros for POV-Ray 
============================================

  Macros for realistic lighting using the CIE XYZ color space macros by Ive.

  Jaime Vives Piqueres, Oct 2003 (jaimevives@ignorancia.org)

  http://www.ignorancia.org/t_lightsys.php

  Contributors:

   * Ive 
   * Philippe Debar 


================
1 - INTRODUCTION
================

  More than a year ago, I started to write an include file to automate the task 
of creating a light source, specifically the aspects about color, intensity and 
fading. I was tired of always having to find by trial and error the right
combination of these factors for each light_source on each scene.

  I had in mind a set of macros wich will allow to automatically calculate the
color, intensity and fading based on a few fixed rules. I started then learning 
about light on the Internet, searching with google and surfing link after link. 
After some time, I ended up with some basic principles to apply as rules for my
POV-Ray light sources:

 
  A) FADING: INVERSE SQUARE LAW

     First of all, light follows the famous inverse square law. So, fade_power
     must be set to 2. The fade_distance is set to have an arbitrary and fixed
     value. In the former versions it was sqrt(sqrt(area)), but I've later 
     changed it to a fixed value because the intensity implementation already 
     uses lumen values with an implicit area.


  B) INTENSITY: HIGH RANGE AND PROPORTIONAL BRIGTHNESS

     Light intensity must be very high, to achieve a high range of lighting 
     levels across the scene (this is also the reason for the very small value
     for fade_distance). The actual intensity is not that important, but to 
     have realistic proportions between the different light sources. 

     So, I decided to simply use the "real" lumen value of the real light as a
     sort of intensity multiplier, using a global variable to allow increasing 
     or decreasing "brightness" equally for all lights on the scene. 


  B) COLOR: REALISTIC LIGHT COLORS

     In real world, (light) color is the perception of a spectrum, and as any 
     perceptual matter, it is very subjective. However, scientists of course 
     developed numerical systems to represent the color of a spectrum, being 
     the CIE XYZ Tristimulus model the scientific standard. 

     I used at first a simplified algorithm, based on the work by Dan Bruton, 
     to calculate the color at each wavelength, weighting later all the samples 
     to obtain the final rgb color. Although it worked "artistically" for light
     color proportionality, the method was not accurate enough as it's based on 
     heuristic tristimulus curves modeled to display visually pleasant colors
     for presentation purposes (also known as "false colors").

     Later, starting it as a replacement for my spectral macros, Ive created
     an amazing set of macros to manage CIE XYZ color space with the SDL, so
     I've droped all the spectrum macros to use Ive macros instead. This gives 
     to Lightsys an accurate and very proportional way to calculate the rgb 
     colors for light spectrums, based on the human eye perception. Ive done 
     all the CIE XYZ color space implementation by himself, and I've only acted
     as betatester and later adapted Lightsys to use it (this also helped me a 
     lot to start understanding this color mess), contributing also with some
     demo scenes showing other uses of these macros with and without Lightsys. 

     Additionally, I provide another global variable to act as a typical "color
     correction" filter. Although this is more a "photography thing", I have
     implemented it for completeness. 


==============
2 - HOW TO USE
==============

  * BASIC USAGE

    To use lightsys on your scenes, you need to previously include the CIE XYZ
    color space macros (which you must have as they are part of this package). 
    This is because lightsys no longer performs spectral calculations, then you 
    will need a color model to obtain rgb values to feed the lighting macros, 
    and the CIE model offers the best one I know of. 

    Also, the predefined spectrums for common illuminants are now a separate 
    file, part of the CIE SPD database, called espd_lightsys.inc, so it is 
    required at least when using precalculated colors.

    The main lightsys include, lightsys.inc, contains several macros to create
    light sources or to customize your own ones. Anyhow, you don't have to deal 
    with all the macros nor learn the complexity of the spectrum and temperature 
    conversion to rgb: use the precalculated values to feed the main light macro 
    and the global controls to obtain basic lights with realistic fadding and 
    color.

    For actual examples of code, please look at the /demos and /tests folders.


  * ADVANCED USAGE:

    If you want much more control over your light sources, you can use the
    auxiliary lighting macros, included into "lightsys.inc", to create custom 
    light_source objects, with all the additional statements of your choice.

    Also, instead of using precalculated colors, you can use the CIE macros 
    to create colors from the spectrums databases (espd*.inc).

    Additionally, you can use the public conversion macros available on CIE.inc 
    to create your own custom light colors, or to change the color system or
    the white balance (by default, CIE.inc uses the sRGB system with the D65
    white point).

    For actual examples of code, please look at the /demos and /tests folders.


  * TIPS & TRICKS:

    + Works best for assumed_gamma 1.0. For accurate color rendition, your
      monitor gamma must be properly calibrated, and the Display_Gamma INI 
      option must be set accordingly.

    + All colors for self luminous objects associated to light sources, as 
      media or ambient objects, could be declared using lightsys/CIE colors, so 
      they can also follow the changes implied by the global controls.

    + Usually, you will obtain more realistic results by adjusting the white 
      point of the color system to the temperature of the dominant light on the
      scene. However, more photorealistic results can be achieved by using well 
      known film temperatures and CC filters. 

    + When looking fo more photographic results, it is recommended to turn off
      the chromatic adaption (CIE_ChromaticAdaption()).


  * NOTES FOR USERS OF PREVIOUS VERSIONS:

    The few and rare users of the previous version will see big differences,
    specially on naming conventions, but the concept remains almost intact. 

    As a guide to convert old scenes, please note the following points:

    + The global variable WHITE_POINT has been removed, as now Lightsys relies
      on CIE.inc for white-balancing purpouses, which is fast enough to avoid
      quick linear hacks. So you must use instead the CIE color system macros, 
      which allow you to change the white point, the color system primaries
      and much more.

    + Global variables BRIGHTNESS and COLOR_FILTER have been renamed to 
      Lightsys_Brightness and Lightsys_Filter respectively.

    + Added fading control, introduced with the switch Lightsys_ExposureFake.
      This is NOT based on real world physics, it is just a cheap trick to 
      simulate an exposure feature on input level.
    
    + Removed the tool to save colors, as the CIE macros are now fast enough
      to calculate the colors on the fly. 

    + Moved the spectrums from lightsys_contants.inc to espd_lightsys.inc, as
      they are converted to the new spline format for spectral data, but you
      don't need to include the file as this is done automatically within the
      file lightsys_constants.inc. Also the precalculation of colors has been
      moved to a separate file, to be manually included after the constants 
      file, and so the Precalculate_Colors switch has disapeared.

    + Note that altough main macros are not dependant of the color macros used, 
      the color constants on lightsys_constants.inc DO need the CIE includes by 
      Ive, as his XYZ color model is the recommended color model for use with 
      Lightsys (not only for being the only known implementation, but mainly 
      because the accuracy of the implementation).



=============
3 - REFERENCE
=============

  The lightsys application consists on three files:


  lightsys.inc
  ------------

    It contains the main lighting macros, independent of the color model, and 
    the defaults for the global variables that control the general behavior of 
    these macros.

    * Public macros:

      + Light(Color,Lumens,AreaAxis1,AreaAxis2,AreaSize1,AreaSize2,CosFalloff)

        Returns a simple light_source statement, with optional area light and 
        cosine falloff spot. 

          - Color: rgb for the light color, usually not given directly, but 
            with the help of the predefined constants or the color macros.

          - Lumens: real intensity value for the light, used as multiplier for
            the light color.

          - AreaAxis & AreaSize: size of the area light, as in the light_source
            statement. Will use always "adaptive 1" and "jitter".

          - CosFallof: Boolean to turn cosine falloff trick on/off. This is a
            technique created by Kari Kivisalo to simulate light patches.

      + Light_Color(Color,Lumens)

        Returns the final rgb for the light_source, balancing and correcting
        the result for the current global controls.

          - Color: rgb for the light color, usually not given directly, but 
            with the help of the predefined constants or the color macros.

          - Lumens: real intensity value for the light, used as multiplier for
            the light color.

      + Light_Color_Filtered(Color,Lumens)

        Similar to Light_Color, but filtering the light color to simulate the
        interaction with a colored cover (like in a LED).

          - Color: rgb for the light color, usually not given directly, but 
            with the help of the predefined constants or the color macros.

          - Lumens: real intensity value for the light, used as multiplier for
            the light color.

          - Filter color: rgb for the filter "covering" the light source.

      + Light_Spot_Cos_Falloff(Point_At)

        Returns a spotlight statement using the cosine falloff trick, based on
        the techinque suggested by Kari Kivisalo at povray newsgroups.

          - Point_At: target point for the spotlight.

      + Light_Fading()

        Returns the attenuation statements for the light source, using the
        square law to set fade_power and fade_distance at fixed values.

    * Global Variables:

      + Lightsys_Brightness

        Light multiplier to increase/decrease the apparent brightness of all
        lights at once. The default of 1 uses the lumen value as it is, relying
        on an arbitrary fade_distance chosen for a basic scene with 1 light of 
        aprox. 1000 lumen, and a scale of 1 unit corresponding to 1 cm. For each
        scene you will need to raise or lower this control to get the desired 
        brightness.

      + Lightsys_Filter

        Color correction filter. This color will be "filtered" from all the 
        lights on the scene, by scaling down the color components filtered. 

        The default of <1,1,1> gives no color correction. 

        Note this has nothing to do with the CIE macros. It's only a quick
        hack to simulate camera filters, implemented on the ligthing macros.
        It can be done externally with transparent planes in front of the
        camera, but I feel it would be slower to render.

        The predefined values on "lightsys_constants.inc" behave like classic 
        CC filters. Look at the predefined/saved colors include file for more
        details.

      + Lightsys_ExposureFake

        This is NOT based on real world physics, it is just a cheap trick to 
        simulate an exposure feature on input level. In fact, any *real* 
        exposure control has to be done AFTER the rendering process, like the 
        feature that is included into MLPov and MegaPOV.
 
        But anyway, in some cases it can be used to produce better looking 
        images and this should be the most important point.
     
        A value for Lightsys_ExposureFake:

          - greater than 1.0, forces overexposed.
          - of 1.0, makes no difference.
          - smaller than 1.0, avoids overexposure.
                    
        For extreme values (smaller than 0.4 or greater than 1.5 you should
        also use lightsys_Brightness to compensate the change in lightness.  
	
      + Lightsys_Scene_Scale
      
	Added on version 4b to allow control of the fade distance respect to
	the scene scale. By default it is 1, so it doesn't affect previous
	behavior with assumed 1=1cm scale. Adjust to match your scene scale
	or for artistic effects.
  
  

  lightsys_constants.inc
  ----------------------

    Predefined lumens, filters and temperatures and spectrums, for use with the 
    lighting and color macros. 

    The lumens data where gathered from the principal manufacturers, looking
    at data sheets with lumens ratios for diferent bulb types. These are
    intended to be used with the Light() and Light_Color() macros to specify
    typical values.

    The predefined spectrums are no longer on this file, as they are now a 
    separate "espd database" for CIE.inc, but they are included from this file 
    for compatibility and ease of use. These spectrums where found on the net, 
    from diferent sources, as graphs (image files), which where "sampled" by 
    hand with the help of The Gimp and typed as POV code. They are used to
    obtain the light color for well known illuminants.

    The constants for the most typical Kelvin temperatures should be used to
    feed the CIE color macros, which accept kelvin temperatures as input, to
    change the white point or obtain the color for a blackbody illuminant. The
    contants where obtained again from several sources on the net and from
    photography manuals.

    The values for CC correction filters cover Red, Green, Blue, Cyan, Magenta
    and Yellow, from 05 to 50, as the typical CC filters on photography. Note 
    these are substractive filters: they scale down all the lights colors.
 
    See the actual file for the names of the predefined variables to use on 
    your scenes.


  lightsys_colors.inc
  -------------------

    Precalculated light colors for direct usage into scenes, avoinding the
    use of CIE macros. These colors are calculated from the predefined spectrums
    and temperatures defined by lightsys_constants.inc, so you need to include 
    it first, along with CIE.inc.

    See the actual file for a list of the predefined color names.


==========================
4 - SOURCES OF INFORMATION
==========================

  Here are a few links in no particular order, only to start:

    + light Measurement Handbook.

      -> http://www.intl-light.com/handbook


    + Spectral Data, collected by Brian Smits.

      -> http://www.cs.utah.edu/~bes/graphics/spectra/


    + Buying & selling gems: Best light for colored stone grading.

      -> http://www.palagems.com/gem_lighting2.htm


    + The Plant Photobiology Notes: Lamps

      -> http://cc.joensuu.fi/~aphalo/lamps_plain.html


    + Google Search 
 
      -> http://www.google.com/



--
Please report any error, comment or suggestion to <jaimevives@ignorancia.org>
=============================================================================
