// *********************************************************
// Persistence Of Vision Ray Tracer Scene Description File
// File name  : i_citroen_gs-textures.inc
// Version    : 3.6.1
// Description: Required textures for the Citroen GS
// Date       : Jul-Aug. 2005
// Author     : Jaime Vives Piqueres
// Note       : Does not include the user-configurable paint 
//              texture: use the generic i_car-textures.inc
//              or pass your own to the car macro.
// *********************************************************

// car glass
#if (use_final_text)
#declare t_glass=
texture{
 T_Glass1 
}
#else
#declare t_glass=
texture{
 pigment{rgbt 1}
}
#end

// car mirror
#if (use_final_text)
#declare t_mirror=
texture{Mirror}
#else
#declare t_mirror=
texture{pigment{White}}
#end

// car lights
#declare n_optic=
normal{
 pigment_pattern{cells scale .1}
 normal_map{
  [0 quilted scale <.1,1,.1>*.1]
  [1 quilted scale <.1,.1,1>*.1]
 }
}
#if (use_final_text)
#declare t_lights_glass=
texture{
 T_Glass2
 normal{n_optic}
// finish{reflection{.1,.9} caustics .9}
}
#else
#declare t_lights_glass=
texture{pigment{rgb 1}}
#end

// car stop lights
#if (use_final_text)
#declare t_stop=
texture{
 pigment{Firebrick filter .9}
 normal{n_optic}
 finish{F_Glass4}
}
#else
#declare t_stop=
texture{pigment{Firebrick}}
#end

// car iterm. light
#if (use_final_text)
#declare t_interm=
texture{
 pigment{Orange filter .9}
 normal{n_optic}
 finish{F_Glass4}
}
#else
#declare t_interm=
texture{pigment{Orange}}
#end

// car fog light
#if (use_final_text)
#declare t_fog_glass=
texture{
 pigment{Yellow filter .67}
 normal{quilted scale <.2,.1,.1>*.2}
 finish{F_Glass3}
}
#else
#declare t_fog_glass=
texture{pigment{Yellow}}
#end

// lower parts
#declare t_lower=
texture{
 pigment{Gray10}
}

// chromed details
#if (use_final_text)
#declare t_chrome=
texture{T_Chrome_2C
 finish{ambient 0}
}
#else
#declare t_chrome=
texture{pigment{Gray}}
#end


// black plastic
#declare t_grill=
texture{
 pigment{brick color Gray10 color rgbt 1 mortar 2  scale .005 rotate 90*z} 
 #if (use_final_text)
 finish{Shiny}
 #end
}

// seats
#declare t_seat=
texture{
 pigment{Gray30}
}

// wheel cover metal
#if (use_final_text)
#declare t_wheel_chrome=
texture{T_Chrome_3C
 finish{ambient 0}
}
#declare t_brushed_chrome=
texture{T_Chrome_3A finish{ambient 0}}
#else
#declare t_wheel_chrome=
texture{pigment{Gray}}
#declare t_brushed_chrome=
texture{pigment{Gray}}
#end

// car plate
#if (use_final_text)
#declare t_gs_plate=
texture{
 pigment{image_map{png "im_gs-plate"}} 
 finish{ambient .5}
 translate -.5
}
#else
#declare t_gs_plate=
texture{pigment{Gray}}
#end


#declare t_lights_chrome=t_chrome
#declare t_grille=t_lower
#declare t_rubber=t_lower
#declare t_interior_plastic=t_lower
#declare t_exterior_chrome=t_chrome

