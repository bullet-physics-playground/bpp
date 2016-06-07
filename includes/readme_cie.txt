CIE XYZ Color Model for PoV-Ray - Version 1.7
=============================================

  Ive, Mai-2003  email: ive@lilysoft.com

  This started as a simple replacement for the spectrum sample calculation
  for Jaimes' lightsys but meanwhile it's a kind of multi purpose CIE color
  transformation system.

  See http://www.ignorancia.org/t_cie.php for details.


MAIN FEATURES
=============

  CIE observer
    CIE 1931 2°observer, CIE 1964 10°observer, CIE 1978 Judd/Vos

  CIE reference white
    Illuminant A, B, C, D50, D55, D65, D75, E and all F-types are supported.

  CIE color system and default illuminant
    with 13 predifined color systems together with the illuminant and the
    possibility to select also 'custom-made' systems.

  CIE color system with custum illuminant
    use any non-default illuminant for the predefined color system
    already 20 CIE standard illuminants are defined and in addition you
    can convert temperatures to whitepoints.

  CIE color order systems and conversion utilities between
    RGB, XYZ, xyY, Lab, Lch

  Wavelength, blackbody, daylight(D illuminant), reflective and emissive
  spectrum color conversion tools

  Gamut mapping with different functions (for xyz->RGB conversion)

  Chromatic adaption with different functions
    (used for Lab,Lch <-> xyz and reflectance spectrum -> xyz conversion)


PUBLIC MACROS
=============
  
  Global Switches
  ---------------
  
  CIE_MultiObserver
    use #declare CIE_MultiObserver=true; *before* you do '#include cie.inc"
    if you want to use the CIE_Observer macro.

  System Settings
  ---------------

  CIE_Observer(S)
    Selects the active CIE standard observer.
    Optional, CIE_1931 is used by default.
    Input:
      CIE_1931  ( 2° observer)
      CIE_1964  (10° observer)
      CIE_1978  (the 2° observer modified 1950 by Judd and 1978 by Vos)
    Note: This macro does only exist if CIE_MultiObserver is set true

  CIE_ColorSystem(CS)
    Selects the active color system.
    Optional, the sRGB color system is used by default.
    Input:
      sRGB_ColSys   (EBU)
      CIE_ColSys    (with wide gamut)
      ITU_ColSys    (Pal Secam european tv)
      NTSC_ColSys   (american tv)
      SMPTE_ColSys
      Adobe_ColSys
      Match_ColSys  (color match also used by Adobe)
      Apple_ColSys  (apple crt monitors)
      Beta_ColSys   (defined by Bruce Lindbloom)
      Dell_ColSys   (dell crt monitors)
      ShortPersistence_ColSys
      LongPersistence_ColSys
      HOT_ColSys    (Hydrogen, Oxygen, Thermal color space)
      (or any user defined color system)

  CIE_ColorSystemWhitepoint(CS,WP)
    Selects the active color system but with any non default illuminant
    (whitepoint) for the given color system.
    Optional, sRGB with D65 is used by default
    Input (CS):
      see color systems above
    Input (WP):
      Illuminant_A    (blackbody 2856K)
      Illuminant_B    (incandescent 4874K)
      Illuminant_C    (incandescent 6774K)
      Illuminant_D50  (daylight 5000K)
      Illuminant_D55  (daylight 5502K)
      Illuminant_D65  (daylight 6500K)
      Illuminant_D75  (daylight 7500K)
      Illuminant_E    (theoretical equal-energy 5469K )
      Illuminant_F1   (fluorescent 6430K)
      Illuminant_F2   (fluorescent 4200K)
      Illuminant_F3   (fluorescent 3450K)
      Illuminant_F4   (fluorescent 2940K)
      Illuminant_F5   (fluorescent 6350K)
      Illuminant_F6   (fluorescent 4150K)
      Illuminant_F7   (broad band fluorescent 6500K)
      Illuminant_F8   (broad band fluorescent 5000K)
      Illuminant_F9   (broad band fluorescent 6150K)
      Illuminant_F10  (narrow band fluorescent 5000K)
      Illuminant_F11  (narrow band fluorescent 4000K)
      Illuminant_F12  (narrow band fluorescent 3000K)
      (or any user defined whitepoint converted from kelvin temperatures by
      using Blackbody2Whitepoint or Daylight2Whitepoint)

  CIE_ChromaticAdaption(M)
    Select the internal function for chroma mapping (used for xyz<->Lab/Lch and
    reflectance spectrum -> xyz conversion)
    Optional, Bradford_Match is used by default
    Possible settings:
      0/off/false          - no mapping is performed
      Scaling_ChromaMatch  - not invertable (an inferior chromatic adaptation)
      VonKries_ChromaMatch - invertable
      Bradford_ChromaMatch - invertable (used by Photoshop)

  CIE_ReferenceWhite(RW)
    Changes the illuminant for the reference whitepoint
    Do not confuse this reference whitepoint with the color system whitepoint,
    they can be different - and this is why the chromatic adaption is needed!
    Optional, D50 is used by default
    Possible settings:
      Illuminant_A
      Illuminant_B
      Illuminant_C
      Illuminant_D50
      Illuminant_D55
      Illuminant_D65
      Illuminant_D75
      Illuminant_E
      Illuminant_F*

  CIE_GamutMapping(GM)
    Selects the internal function for gamut mapping (for xzy->rgb conversion)
    Optional, type 1 is used by default
    Possible settings:
      0/off/false  - no mapping is performed
      1            - just clip negative RGB values
      2            - triangle intersection
      3            - desaturate RGB values


  Color Conversion
  ----------------

  + with gamut mapping (all except the Reflective macros do also normalization):

  ReflectiveSpectrum(RS)
    Converts a given reflective spectral data sample (RS) into a gamut mapped
    RGB value.

  EmissiveSpectrum(ES)
    Converts a given emissive spectral data sample (ES) into a gamut mapped RGB
    value.

  LineSpectrum(LS,Ion)
    Converts a given line spectral data sample (LS) into a gamut mapped RGB
    value by taking the ionization of the element into account.

  Blackbody(K)
    Converts a given Kelvin blackbody temperature into a gamut mapped RGB value
    (e.g glowing iron or stars colors)

  Daylight(K)
    Converts a given Kelvin D illuminant temperature into a gamut mapped RGB
    value.

  Wavelength(W)
    Converts a given wavelength into a gamut mapped RGB value (maybe useful to
    determine the color of some a high energy laser where usually the wavelength
    or the frequence is known, as the wavelength can easily calculated from a
    given frequence)

  xyz2RGBgamut(XYZ)
    Converts xyz to RGB

  xyY2RGBgamut(XYZ)
    Converts xy+Lumens to RGB


  + without gamut mapping:

  Reflective2RGB(RS)
  Emissive2RGB(ES)
  LineSpectrum2RGB(LS,Ion)
  Blackbody2RGB(K)
  Daylight2RGB(K)
  Wavelength2RGB(W)
  
  Relective2xyz(RS)
  Emissive2xyz(ES)
  LineSpectrum2xyz(LS,Ion)
  Blackbody2xyz(K)
  Daylight2xyz(K)
  Wavelength2xyz(W)

  Relective2Lab(S)
  Emissive2Lab(S)
  LineSpectrum2Lab(LS,Ion)
  Blackbody2Lab(K)
  Daylight2Lab(K)
  Wavelength2Lab(W)

  Reflective2Lch(S)
  Emissive2Lch(S)
  LineSpectrum2Lch(LS,Ion)
  Blackbody2Lch(K)
  Daylight2Lch(K)
  Wavelength2Lch(W)

  xyz2RGB(XYZ)
  xyY2RGB(xyY)
  Lab2RGB(Lab)
  Lch2RGB(Lch)

  RGB2xyz(RGB)
  Lab2xyz(Lab)
  Lch2xyz(Lch)
  xyY2xyz(xyY)

  xyz2xyY(XYZ)
  xyz2Lab(XYZ)

  Blackbody2Whitepoint(K)
    Converts a given Kelvin temperature to x/y whitepoint by using the
    blackbody radiation. Use it to create custom color systems with
    CIE_ColorSystemWhitepoint().
    Note: the CIE D illuminants (e.g. D50) are different to the blackbody.
          To create corresponding D illuminants use the next macro.

  Daylight2Whitepoint(K)
    Converts a given Kelvin temperature to a x/y whitepoint by using the
    daylight illumination formula. The input is restricted to the range of
    4000°-25000° kelvin.
    Note (due to the Boltzmann constant revision):
      D50 = 5002.78 K
      D55 = 5503.06 K
      D65 = 6503.62 K
      D75 = 7504.17 K


  Color Utilities
  ---------------

  ReflectanceMix(S1,S2,F1,F2)
    mix 2 reflectance spectra S1 and S2 by the factor F1/F2 and returns the
    resulting gamut mapped rgb value.

  ReflectanceMix2RGB(S1,S2,F1,F2)
  ReflectanceMix2Lab(S1,S2,F1,F2)
  ReflectanceMix2Lch(S1,S2,F1,F2)
    reflectance mixer without gamut mapping

  LineSpectrumMix(LS,LF)
    where LS is a one-dimensional array that contains the line spectra
    LF is a two-dimensional array at corresponding size
      1st column: factor to mix the line spectra
      2nd column: ionization of the element

  LineSpectrumMix2RGB(LS,LF)
  LineSpectrumMix2Lab(LS,LF)
  LineSpectrumMix2Lch(LS,LF)
    spectrum mixer without gamut mapping

  Text Output
  -----------

  CIE_Observer_String(S)
  CIE_ColorSystem_String(S)
  CIE_Whitepoint_String(S)
  CIE_ReferenceWhite_String(S)
  CIE_ChromaticAdaption_String(S)
    all of them take any string as input and return it concatenated with
    the requested system setting.


HISTORY
=======

  Changes and bug fixes in version 1.7
  - conversion macros for line spectra added
  - CIE_ReleaseMemory() macro added

  Changes and bug fixes in version 1.6
  - Beta RGB color system added
  - all the missing F-type illuminants added (e.g. KODAK does use F10 and F11
    for reference white).
  - CMF's put together in one lookup table

  Changes and bug fixes in version 1.5
  - stupid error in A and C illuminant calculation corrected
  - renamed the spectra macros to 'EmissiveSpectrum' and 'Emissive2...'
  - renamed the reflectance macros to 'ReflectiveSpectrum' and 'Reflective2...'
  - cleaned the code

  Changes and bug fixes in version 1.4
  - macros to calculate the D illuminants for the reference whitepoint added
  - reference white can now be set to A, C or any standard D illuminant
  - Kelvin macros renamed to Blackbody
  - Daylight (Illuminant D) macros similar to the Blackbody macros added
  - CMF and RefWhiteSP changed to cubic splines for accurate interpolation
  - more macros for text output
  - global switch CIE_MultiObserver added
  - some minor optimisations

  Changes and bug fixes in version 1.3
  - modified CIE 2°observer (1950 Judd, 1978 Vos) added
  - Reflectance spetrum mixer added
  - CIE_Gamma variable removed (the gamma macros are still there but now they do
    use the desired rgb gamma as input)
  - accurate sRGB gamma correction added
  - gamut mapping code tweaked again
  - Illuminant_B added (for some reason I have missed it in earlier versions)
  - Daylight2Whitepoint macro added (it returns the corresponding D illuminant
    for a given kelvin temperature) and - to make the usage more clear -
    Kelvin2Whitepoint renamed to Blackbody2Whitepoint.

  Changes and bug fixes in version 1.2
  - chromatic adaption added (default: Bradford_Match)
  - XYZ reference whitepoint added (default: Illuminant D50)

  Changes and bug fixes in version 1.1
  - a major bug in the gamut mapping code is fixed
  - possibility to select the way gamut mapping is performed added
  - speed improvement: Kelvin, Wavelength and Spectrum calculation about
    20 to 30 times faster!
  - new color systems added
      Adobe and ColorMatch - both used by Adobe (Photoshop etc.)
      Apple - Apple monitor
      HOT - uses primaries found in deep space.
  - some internal names are changes to avoid future confusion
  - macros for text output added

  Changes and bug fixes in version 1.0
  - initial release


  To do (somehow, somewhen, by somebody):
  - implement the function used by the standard B and C illuminant in the
    same way as done for the Blackbody and Daylight macros.
    Call it e.g. Incandescent(K).
  - check if the three different F-type spectra are also based on functions
    and - if so - implement it. This way we could eleminate the 12 emissive
    spectra from espd_cie_standard.inc and also the 12 F-type whitepoints
    in cie.inc.
  - Luv/Lch(uv) implementation
  - CIE 1974 UV color match function


SOURCES
=======

  Most of the work is based on the chapters
    13.2 chromatic colors
    13.3 color models for raster graphics
    in Computer Graphics, Principles And Practice
       Foley, van Damme, Feiner, Hughes
       Addison Wesley 2nd Edition 1996
       [Foley96]

  also
    http://www.cie.co.at/cie

  and a useful pdf document by Gernot Hoffmann at
    http://www.fho-emden.de/~hoffmann/colcie290800.pdf

  the reflectance and chroma match adaption is done with help of the infos
  found at the homepage of Bruce Lindbloom, a color scientist whom I also
  wish to thank for his kind reply to some of my silly color math questions.
    http://www.brucelindbloom.com

  Many thanks to Jaime Vives Piqueres, without his lightsys, enlightenment
  and inspiration I would never have done this.


  Ive, Mai-2003
