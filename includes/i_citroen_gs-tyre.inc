// *********************************************************
// Persistence Of Vision Ray Tracer Scene Description File
// File name  : i_citroen_gs-tyre.inc
// Version    : 3.6.1
// Description: Citroen GS piece: tyre
// Date       : Jul-Oct. 2005
// Author     : Jaime Vives Piqueres
// *********************************************************

#macro wheel(type_rim,wheel_rotation)

// *** measures ***
#local width_wheel=20;
#local radius_wheel=55.3*.5;
#local width_rim=18.5;
#local radius_rim=20;

// tyres texture
#declare t_tyre=
texture{
 pigment{
  cylindrical
  color_map{
   [0.0 Gray20]
   [0.05 Gray10]
   [1.0 Gray10*.1]
  }
  rotate 90*z
  scale radius_wheel
 }
 normal{granite scale .01}
// finish{specular .2 roughness .01}
}


// *** wheels ***
#local tyre=
difference{
 union{
  difference{
   superellipsoid{
   <1,.2>
    rotate 90*y
    scale <width_wheel*.5,radius_wheel,radius_wheel>
   }
   cylinder{
    <-width_wheel*.6,0,0>
    < width_wheel*.6,0,0>
    radius_rim+.1
   }
  }
  torus{
   radius_wheel-5,4.8
   rotate 90*z
   scale <0.8,1,1>
   translate -width_wheel*.45*x
  }
 }
 union{
  torus{radius_wheel,.5 rotate 90*z}
  torus{radius_wheel,.5 rotate 90*z translate -width_wheel*.25*x}
  torus{radius_wheel,.5 rotate 90*z translate  width_wheel*.25*x}
  #local trd=72;
  #local nrd=0;
  #while (nrd<trd)
  cylinder{<-width_wheel*.25,0,0>,<0,0,0>,.4 rotate -15*y translate (radius_wheel)*y rotate (360*nrd/trd)*x}
  cylinder{<width_wheel*.25,0,0>,<0,0,0>,.4 rotate 15*y translate (radius_wheel)*y rotate (360*nrd/trd)*x}
  cylinder{<-width_wheel*.5,0,0>,<0,0,0>,.4 rotate 15*y translate (radius_wheel)*y rotate (360*nrd/trd)*x}
  cylinder{<width_wheel*.5,0,0>,<0,0,0>,.4 rotate -15*y translate (radius_wheel)*y rotate (360*nrd/trd)*x}
  #local nrd=nrd+1;
  #end
 }
 texture{t_tyre}
}

#switch (type_rim)
 #case (1)
  #include "i_citroen_gs-rim.inc"
  #local car_rim=
  object{gs_rim_1 scale .5
   rotate -90*y
   scale <width_rim*2.5,radius_rim*2,radius_rim*2>
   translate width_rim*.25*x
  }
  #break
 #else
  #local car_rim=
  cylinder{<-.5,0,0>,<.5,0,0>,1
   scale <5,radius_rim*2,radius_rim*2>
   texture{t_chrome}
  }
#end

// wheel
union{
 object{tyre}
 object{car_rim translate -width_wheel*.5*x}
 rotate wheel_rotation*x
}

#end // end of macro wheel
