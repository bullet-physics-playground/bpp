// *********************************************************
// Persistence Of Vision Ray Tracer Scene Description File
// File name  : i_citroen_gs.inc
// Version    : 3.6.1
// Description: Citroen GS : main include to join the pieces
// Date       : Jul-Oct. 2005
// Author     : Jaime Vives Piqueres
// *********************************************************

// *** required textures ***
#include "i_citroen_gs-textures.inc"

// *** car assembly macro ***
#macro jvp_citroen_gs(t_paint,wheels_angle)

// debug controls
#local use_tyres    =1;
#local use_plates   =1;
#local use_chassis  =1;
#local use_bumpers  =1;
#local use_doors    =1;
#local use_hood     =1;
#local use_grille   =1;
#local use_lights   =1;
#local use_glasses  =1;
#local use_wwipers  =1;
#local use_antenna  =1;
#local use_mirror   =1;
#local use_wchromed =1;
#local use_raing    =1;
#local use_interior =1;

#local chh=.85; // chassis height over terrain

union{

 // tyres csg and wings3d wheels
 #if (use_tyres)
 #include "i_citroen_gs-tyre.inc"
 #local gs_tyre=object{wheel(1,0)}
 // rear
// object{gs_tyre scale <.6,1,1>*.012 translate <-.745,.35,-1.06>}
// object{gs_tyre scale <.6,1,1>*.012 rotate 180*y translate <.745,.35,-1.06>}
 // front 
// object{gs_tyre scale <.6,1,1>*.012 rotate wheels_angle*y translate <-.745,.35,1.56>}
// object{gs_tyre scale <.6,1,1>*.012 rotate 180*y rotate wheels_angle*y translate <.745,.35,1.56>}
 #end

 // plates hf's
 #if (use_plates)
 #include "i_citroen_gs-plate.inc"
 object{carplate rotate 180*y translate <0,.46,2.36>}
 object{carplate rotate -8*x translate <0,.753,-1.656>}
 #end

 // bare chassis
 #if (use_chassis)
 #include "i_citroen_gs-bare-chassis.inc" 
 object{citroen_gs_chassis scale <-1,1,1> translate chh*y}
 #end
 
 // lower chassis
 #if (use_chassis)
 #include "i_citroen_gs-lower.inc" 
 object{citroen_gs_lower scale <-1,1,1> translate chh*y}
 #end

 // chassis front sides
 #if (use_chassis)
 #include "i_citroen_gs-fender.inc" 
 object{citroen_gs_fender scale <-1,1,1> translate chh*y}
 object{citroen_gs_fender translate chh*y}
 #end

 // bumpers
 #if (use_bumpers)
 #include "i_citroen_gs-bumpers.inc" 
 object{citroen_gs_bumpers scale <-1,1,1> translate chh*y}
 #end

 #if (use_doors)
 // front doors
 #include "i_citroen_gs-front-door.inc" 
 object{citroen_gs_front_door scale <-1,1,1> translate chh*y}
 object{citroen_gs_front_door translate chh*y}
 // rear doors
 #include "i_citroen_gs-rear-door.inc" 
 object{citroen_gs_rear_door scale <-1,1,1> translate chh*y}
 object{citroen_gs_rear_door translate chh*y}
 // doors handles
 #include "i_citroen_gs-door-handles.inc" 
 object{citroen_gs_door_handles scale <-1,1,1> translate chh*y}
 // back door
 #include "i_citroen_gs-back-door.inc" 
 object{citroen_gs_back_door scale <-1,1,1> translate chh*y}
 difference{
  cylinder{<0,0,0>,<0,0,-.02>,.02}
  box{-.5,.5 scale <.005,.02,.1>}
  texture{t_exterior_chrome}
  translate <0,.61,-1.656>}
 cylinder{
  <0,0,0>,<0,0,-.01>,.03
  texture{t_rubber}
  translate <0,.61,-1.656>}
 #end

 #if (use_grille)
 // front grille
 #include "i_citroen_gs-front-grille.inc" 
 object{citroen_gs_front_grille scale <-1,1,1> translate chh*y}
 // logos
 #include "i_citroen_gs-logo.inc" 
 object{citroen_logo scale <-1,1,1> scale 1.02 translate chh*y translate -.05*z}
 #end

 #if (use_lights)
 // front lights
 #include "i_citroen_gs-front-light.inc" 
 object{citroen_gs_front_light scale <-1,1,1> translate chh*y}
 object{citroen_gs_front_light translate chh*y}
 // rear lights
 #include "i_citroen_gs-rear-light.inc" 
 object{citroen_gs_rear_light scale <.99,1.02,1> scale <-1,1,1> translate <0,chh-.0025,.01>}
 object{citroen_gs_rear_light scale <.99,1.02,1> translate <0,chh-.0025,.01>}
 // frontal anti-fog lights
 #include "i_citroen_gs-foglight.inc" 
 object{car_foglight scale <-1,1,1> translate chh*y}
 object{car_foglight translate chh*y}
 #end

 // glasses
 #if (use_glasses)
 #include "i_citroen_gs-glass.inc" 
 object{citroen_gs_glasses scale <-1,1,1> translate chh*y}
 #end

 // hood
 #if (use_hood)
 #include "i_citroen_gs-hood.inc" 
 object{citroen_gs_hood scale <-1,1,1> translate chh*y}
 #end

 // radio atenna
 #if (use_antenna)
 #include "i_citroen_gs-antenna.inc" 
 object{car_antenna translate (chh-.01)*y}
 #end

 // lateral mirror
 #if (use_mirror)
 #include "i_citroen_gs-mirror.inc" 
 object{car_mirror scale <-1,1,1> translate chh*y}
 object{car_mirror translate chh*y}
 #end

 // window chromed frames
 #if (use_wchromed)
 #include "i_citroen_gs-wchromed.inc" 
 object{citroen_gs_window_chromed scale <-1,1,1> translate chh*y}
 #end

 // external rain guide
 #if (use_raing)
 #include "i_citroen_gs-rainguide.inc" 
 object{citroen_gs_rainguide scale <-1,1,1> translate chh*y}
 object{citroen_gs_rainguide translate chh*y}
 #end

 // front windshiled wippers
 #if (use_wwipers)
 #include "i_citroen_gs-wwiper.inc" 
 object{citroen_gs_wwiper scale <-1,1,1> translate chh*y}
 #end

 #if (use_interior)
 // fake interior decoration (retro mirror, direction wheel)
 #include "i_citroen_gs-interior.inc" 
 object{citroen_gs_interior scale <-1,1,1> translate chh*y}
 // generic seats modeled with wings3d
 #include "i_car-seat-front.inc"
 #include "i_car-seat-back.inc"
 object{front_seat scale .9 translate <.35,.35,.15>}
 object{front_seat scale .9 translate <-.35,.35,.15>}
 object{back_seat scale .9 translate <0,.35,-.7>}
 #end

}

#end
