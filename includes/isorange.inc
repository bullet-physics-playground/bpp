#include "functions.inc" // f_sphere, f_ph, f_th, f_bumps, f_granite

#declare orange=
union{
  isosurface{
    function{
      f_sphere(x,y,z,1)*f_ph(x,y,z)
      -cos(f_th(x,y,z)*4)*.02
      +f_bumps(x*2,y*2,z*2)*.1+f_granite(x,y,z)*.0125-f_bumps(x*20,y*20,z*20)*.02
    }
    max_gradient 3
    contained_by{sphere{0,1}}
    #if(pass=1)
      texture{
        pigment{Orange*.4+OrangeRed*.5}
        finish{
          specular albedo 0.05 roughness 0.02
          conserve_energy
        }
      }
    #end
    #if(pass=2)
      texture{
        pigment{White}
        finish{subsurface{translucency 1}}
      }
    #end
    #if(pass=3)
      texture{
        pigment{Orange*.25+OrangeRed*.25}
        finish{
          specular albedo 0.05 roughness 0.02
          conserve_energy
        }
      }
    #end
  }
  cylinder{<0,0,0>,<0,.9,0>,.02 pigment{DarkGreen*.5}}
}
