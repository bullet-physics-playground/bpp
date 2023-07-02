/*
  Persistence of Vision Ray Tracer Scene Description File

  LightSysIV : predefined constants.
  
  These are for easy use the system using standard values for common illuminants and 
  tipical films or white points. Automatically includes the spectrum database files
  espd_cie_standard.inc and espd_lightsys.inc 

  Jaime Vives Piqueres, Apr-2003.

*/

// Lumens for common wattages of generic bulb types
// source: http://www.efi.org/articles/bulbs.html
#declare Lm_Incandescent_15w = 122;
#declare Lm_Incandescent_25w = 210;
#declare Lm_Incandescent_40w = 460;
#declare Lm_Incandescent_60w = 890;
#declare Lm_Incandescent_75w =1180;
#declare Lm_Incandescent_100w=1750;
#declare Lm_Incandescent_150w=2780;
#declare Lm_Fluorescent_15w  = 900;
#declare Lm_Fluorescent_30w  =1900;
#declare Lm_Fluorescent_38w  =2550;
#declare Lm_Halogen_42w      = 665;
#declare Lm_Halogen_52w      = 885;
#declare Lm_Halogen_72w      =1300;
#declare Lm_Compact_40w      = 400;
#declare Lm_Compact_60w      = 600;
#declare Lm_Compact_75w      = 900;
#declare Lm_Compact_75w      =1200;

// Lumens for GE bulbs (www.gelighting.com)
// classic incandescents
#declare Lm_GE_Inc_15w=90;
#declare Lm_GE_Inc_25w=190;
#declare Lm_GE_Inc_40w=410;
#declare Lm_GE_Inc_60w=700;
#declare Lm_GE_Inc_75w=865;
#declare Lm_GE_Inc_100w=1330;
#declare Lm_GE_Inc_150w=1800;
#declare Lm_GE_Inc_200w=2990;
#declare Lm_GE_Inc_300w=4850;
// std halophosphate fluorescents
#declare Lm_GE_T5_8w=385;
#declare Lm_GE_T8_15w=850;
#declare Lm_GE_T8_18w=1150;
#declare Lm_GE_T8_30w=2300;
#declare Lm_GE_T8_36w=2850;
#declare Lm_GE_T8_58w=4600;
#declare Lm_GE_T8_70w=5550;
#declare Lm_GE_T12_20w=1150;
#declare Lm_GE_T12_40w=2950;
#declare Lm_GE_T12_65w=4750;
// cylindrical halogens
#declare Lm_GE_LinearR7S_100w=1600;
#declare Lm_GE_LinearR7S_150w=2600;
#declare Lm_GE_LinearR7S_200w=3400;
#declare Lm_GE_LinearR7S_250w=4000;
#declare Lm_GE_LinearR7S_300w=5100;
#declare Lm_GE_LinearR7S_500w=9500;
// compact fluorescents
#declare Lm_GE_BiaxD2_w10=600;
#declare Lm_GE_BiaxD2_w13=900;
#declare Lm_GE_BiaxD2_w18=1200;
#declare Lm_GE_BiaxD2_w26=1710;

// Common film temperatures on photography
#declare Kt_TungstenA_Film  =3400;   
#declare Kt_TungstenB_Film  =3200;   
#declare Kt_Indoor_Film     =Kt_TungstenB_Film;   
#declare Kt_Daylight_Film   =5500;
#declare Kt_Fluorescent_Film=4100;

// Kelvin temperatures for CIE Standard Iluminants
#declare Kt_SI_A  =2856;    // blackbody
#declare Kt_SI_B  =4882;    // noon sunlight
#declare Kt_SI_C  =6769;    // daylight
#declare Kt_SI_D50=5002.78; // daylight
#declare Kt_SI_D55=5503.06; // daylight
#declare Kt_SI_D65=6503.62; // daylight
#declare Kt_SI_D75=7504.17; // daylight

// Other useful blackbody kelvin temperatures
#declare Kt_Candle_Flame=1800;
#declare Kt_Sunrise     =2000;
#declare Kt_Moonlight   =4000;
#declare Kt_Hazy_Sky    =8000;
#declare Kt_Overcast_Sky=10000;
#declare Kt_Sunless_Sky =11000;

// Color correction filters:
// - Red -
#declare CC05R=<1,.95,.95>;
#declare CC10R=<1,.9,.9>;
#declare CC20R=<1,.8,.8>;
#declare CC30R=<1,.7,.7>;
#declare CC40R=<1,.6,.6>;
#declare CC50R=<1,.5,.5>;
// - Green -
#declare CC05G=<.95,1,.95>;
#declare CC10G=<.9,1,.9>;
#declare CC20G=<.8,1,.8>;
#declare CC30G=<.7,1,.7>;
#declare CC40G=<.6,1,.6>;
#declare CC50G=<.5,1,.5>;
// - Blue -
#declare CC05B=<.95,.95,1>;
#declare CC10B=<.9,.9,1>;
#declare CC20B=<.8,.8,1>;
#declare CC30B=<.7,.7,1>;
#declare CC40B=<.6,.6,1>;
#declare CC50B=<.5,.5,1>;
// - Cyan -
#declare CC05C=<.95,1,1>;
#declare CC10C=<.9,1,1>;
#declare CC20C=<.8,1,1>;
#declare CC30C=<.7,1,1>;
#declare CC40C=<.6,1,1>;
#declare CC50C=<.5,1,1>;
// - Magenta -
#declare CC05M=<1,.95,1>;
#declare CC10M=<1,.9,1>;
#declare CC20M=<1,.8,1>;
#declare CC30M=<1,.7,1>;
#declare CC40M=<1,.6,1>;
#declare CC50M=<1,.5,1>;
// - Yellow -
#declare CC05Y=<1,1,.95>;
#declare CC10Y=<1,1,.9>;
#declare CC20Y=<1,1,.8>;
#declare CC30Y=<1,1,.7>;
#declare CC40Y=<1,1,.6>;
#declare CC50Y=<1,1,.5>;

// Predefined spectral power distributions (needs CIE.inc!!!)
#include "espd_cie_standard.inc"  // standard illuminants
#include "espd_lightsys.inc" // real iluminants 

// *** generic spectrum Alias (easy to rememeber) ***
#declare ES_Incandescent_60w=spline{ES_GE_SW_Incandescent_60w}
#declare ES_Xenon_Flash=spline{ES_Nikon_SB16_XenonFlash}
#declare ES_Warm_White_Fluor=spline{ES_GTE_341_Warm}
#declare ES_Cool_White_Fluor=spline{ES_GTE_341_Cool}
#declare ES_Compact_White_Fluor=spline{ES_Phillips_PLS_11w}
#declare ES_Halogen=spline{ES_Solux_Halog4700K}

