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
      scale <-1,1,1> translate -.5*x
    }
  }
}
#declare m_cajon_clavos=
material{
  texture{
    pigment{
      image_map{jpeg "flat_uniformly_aged_metal_6080084" interpolate 2}
      turbulence 1
    }
    finish{specular 1 metallic}
  }
}

#include "cajon_POV_geom.inc"
object{cajon 
  translate 9.05*y
}
