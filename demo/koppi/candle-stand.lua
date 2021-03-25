require "module/trans"
require "module/color"
require "module/metal"

v.glAmbient = 0.2
v.glDiffuse = 0.5
v.glLight0 = btVector4(100,100,100,0)
v.glLight1 = btVector4(100,100,100,100)
v.glSpecular = 0.1
v.glModelAmbient = 0.1

v.pre_sdl = [[
#include "colors.inc"
#include "textures.inc"

#declare t_flame=
texture{
 pigment{rgbt 1}
}
#include "i_flame.inc"
#declare ifl=0;
#declare nfl=18;
#declare fire=
union{
#while (ifl<nfl)
 object{mesh_flame hollow
  interior{
   media{
    emission 5
    density{
     planar
     density_map{
      [0 Blue*.75+Green*.25]
      [1 Red]
     }
     scale .5
     translate .1*y
    }
   }
  }
  rotate 5*x
  translate 5*z
  rotate ifl*(360/nfl)*y
 }
 #declare ifl=ifl+1;
#end
}

object{fire scale <1,1,1> translate 54*y }
]]

plane = Plane(0,1,0,0,500)
plane.col = "#111111"
--v:add(plane)

m = Mesh("demo/mesh/candleStand.stl", 0)
--m.col = "#fff"
--q = btQuaternion(-1,0,0,1)
--o = btVector3(0,0,0)
--m.trans=btTransform(q,o)

--trans.move(m, btVector3(0,1,0))
trans.rotate(m, btQuaternion(-1,0,0,1), btVector3(0,0,0))
v:add(m)

m.col = color.random_pastel()
m.post_sdl = "texture { " .. metal.random() .. " } }"

