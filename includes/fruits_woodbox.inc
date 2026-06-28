#if(pass=2)

  #declare m_madera_cajon=
  material{
    texture{
      pigment{Black}
      finish{brilliance 0 diffuse 0}
    }
  }
  #declare m_cajon_clavos=m_madera_cajon

#else

  #declare m_madera_cajon=
  material{
    texture{
      pigment{
        image_map{jpeg "flat_wood_4022164.JPG" interpolate 2}
      }
      normal{
        bump_map{jpeg "flat_wood_4022164.JPG" bump_size 1}
      }
      rotate 90*z
      scale .5
    }
    texture{
      pigment{
        image_map{png "logo" interpolate 2}
      }
    }
  }
  #declare m_cajon_clavos=
  material{
    texture{
      pigment{
        image_map{jpeg "copper" interpolate 2}
        turbulence 1
      }
      finish{specular 1 metallic}
    }
  }
  
#end

#include "cajon_POV_geom.inc"
object{cajon 
  translate 9.05*y
}
