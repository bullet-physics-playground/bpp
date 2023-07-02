/*
  Persistence of Vision Ray Tracer Scene Description File

  LightSysIV : precalculated colors.
  
  These are for easy use the system using standard colors for common illuminants.

  Needs CIE.inc, lightsys_constants.inc and espd_lightsys.inc 

  Jaime Vives Piqueres, Apr-2003.

*/



// *** PRECALCULATED COLORS ***
// Colors from predefined temperatures and spectrums. Note these are calculated each 
// time the scene is rendered, allowing changes to the predefined data between renders.

// Correlated Kelvin temperatures for standard illuminants
#declare Cl_SI_A  =Blackbody(Kt_SI_A);  // blackbody 2856 K
#declare Cl_SI_B  =EmissiveSpectrum(ES_Illuminant_B); // noon sunlight
#declare Cl_SI_C  =EmissiveSpectrum(ES_Illuminant_C); // daylight
#declare Cl_SI_D50=Daylight(Kt_SI_D50); // daylight
#declare Cl_SI_D55=Daylight(Kt_SI_D55); // daylight
#declare Cl_SI_D65=Daylight(Kt_SI_D65); // daylight
#declare Cl_SI_D75=Daylight(Kt_SI_D75); // daylight

// Other useful blackbody colors for light colors
#declare Cl_Candle_Flame=Blackbody(Kt_Candle_Flame);
#declare Cl_Sunrise     =Blackbody(Kt_Sunrise);
#declare Cl_Moonlight   =Daylight(Kt_Moonlight);
#declare Cl_Hazy_Sky    =Daylight(Kt_Hazy_Sky);
#declare Cl_Overcast_Sky=Daylight(Kt_Overcast_Sky);
#declare Cl_Sunless_Sky =Daylight(Kt_Sunless_Sky);

// Predefined RGB colors for common spectrums 
#declare Cl_Cornell_Box_Light=EmissiveSpectrum(ES_Cornell_Box_Light);
#declare Cl_Incandescent_60w=EmissiveSpectrum(ES_Incandescent_60w);
#declare Cl_Incandescent_100w=EmissiveSpectrum(ES_GE_SW_Incandescent_100w);
#declare Cl_Xenon_Flash=EmissiveSpectrum(ES_Xenon_Flash);
#declare Cl_Warm_White_Fluor=EmissiveSpectrum(ES_Warm_White_Fluor);
#declare Cl_Cool_White_Fluor=EmissiveSpectrum(ES_Cool_White_Fluor);
#declare Cl_Daylight_Fluor=EmissiveSpectrum(ES_Daylight_Fluor);
#declare Cl_Compact_White_Fluor=EmissiveSpectrum(ES_Compact_White_Fluor);
#declare Cl_Mastercolor_3K=EmissiveSpectrum(ES_Phillips_Mastercolor_3K);
#declare Cl_Sodium=EmissiveSpectrum(ES_Phillips_HPS);
#declare Cl_CoolBeam=EmissiveSpectrum(ES_Osram_CoolBeam_20w);
#declare Cl_Halogen=EmissiveSpectrum(ES_Solux_Halog4700K);
#declare Cl_Sunlight=EmissiveSpectrum(ES_Sunlight);
#declare Cl_Extraterrestrial_Sun=EmissiveSpectrum(ES_Extraterrestrial_Sun);


