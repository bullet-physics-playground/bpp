// *********************************************************
// Persistence Of Vision Ray Tracer Scene Description File
// File name  : i_car-textures.inc
// Version    : 3.6.1
// Description: car-like textures (version 2)
// Date       : Jul-Oct. 2005
// Author     : Jaime Vives Piqueres
// Note       : Requires predefined variables clo and cla
//              for the camera location and look_at values
// *********************************************************

// *** Predefinied paints ***

// reflection params
#ifndef(rmin) #declare rmin=.1; #end
#ifndef(rmax) #declare rmax=.33; #end

// camera vector
#declare cv=vnormalize(clo-cla);

// paint finishes
#declare f_matte=
finish{ // metalized mate
 metallic 
 specular .5 
 roughness .05
 diffuse .5
 conserve_energy 
}
#declare f_varnish=
finish{ // normal varnish
 Shiny ambient 0
 diffuse 0
 reflection{rmin,rmax falloff 5} 
 conserve_energy 
}

// paint textures
#declare t_red_paint=
texture{
 pigment{Firebrick*.1+Red*.5}
 finish{f_varnish}
}
#declare t_green_paint=
texture{
 pigment{DarkGreen+Blue*.1}
 finish{f_varnish}
}
#declare t_blue_paint=
texture{
 pigment{NavyBlue+Green*.1}
 finish{f_varnish}
}
#declare t_black_paint=
texture{
 pigment{DarkSlateBlue*.01}
 finish{f_varnish}
}
#declare t_white_paint=
texture{
 pigment{White*.75}
 finish{f_varnish}
}
#declare t_blue_white_bars_paint=
texture{
 pigment{
  function{abs(x)}
  color_map{
   [0.00 DarkSlateBlue*.3+Green*.15+Blue*.15]
   [0.10 DarkSlateBlue*.3+Green*.15+Blue*.15]
   [0.10 White*.5]
   [0.30 White*.5]
   [0.30 DarkSlateBlue*.3+Green*.15+Blue*.15]
   [1.00 DarkSlateBlue*.3+Green*.15+Blue*.15]
  }
 }
 finish{f_varnish}
}

// metallized paint macro (2 layers)
#macro metallized_paint(c1,c2,cv,f_matte,f_varnish)

#local t_metallized_paint=
// basecoat (pigment + metallic flakes)
texture{ 
 pigment{
  slope cv
  color_map{
   [0.0 rgb c1]
   [0.5 rgb c2]
   [1.0 rgb c1]
  }
 }
 normal{bozo 1 turbulence 1 lambda 3 omega 1 scale .01}
 finish{f_matte} 
}
// clearcoat (varnish)
texture{
 pigment{rgbt 1}
 finish{f_varnish}
}
#local dummy=0;

texture{t_metallized_paint}

#end


