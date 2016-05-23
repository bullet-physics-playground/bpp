--
-- http://alzinger.de/cms5/robert/raytracing/marble-machine-in-povray.html
--

module("marble", package.seeall)

function sdl(col1r, col1g, col1b, col2r, col2g, col2b)
   local marble_sdl = [==[

union {
  difference {     
    sphere {0,1}      
    #for (i,1,70)
      sphere {0,1 scale (rand(seee)*0.04+0.01) 
      translate y*(0.3+0.5*rand(seee)) 
      rotate <rand(seee)*360,0,rand(seee)*360>}
    #end
    union {
      blob { threshold  0.1
      #for (i,-0.9,0.9,0.01)
        sphere {0,1, 0.2 scale <sin(((i+1)*pi/2))*0.8,0.1,0.08> 
        translate y*(i) rotate <0,i*150,0>}
      #end
      texture {
        pigment{ color rgb <]==]..tostring(col1r)..[==[, ]==]..tostring(col1g)..[==[, ]==]..tostring(col1b)..[==[> }
        finish { diffuse 0.9 phong 0.8 ambient 1.2}
      }
    }
    blob {
      threshold  0.1
      #for (i,-0.9,0.9,0.01)
        sphere {0,1, 0.2 scale <sin(((i+1)*pi/2))*0.8,0.1,0.08> 
        translate y*(i) rotate <0,90+i*150,0>}
      #end
        texture {
          pigment{ color rgb <]==]..tostring(col2r)..[==[, ]==]..tostring(col2g)..[==[, ]==]..tostring(col2b)..[==[> }
        finish {diffuse 0.9 phong 0.8 ambient 1.2}
      }
    }
  }
  texture { Glass }
  interior {
    ior 1.5 caustics 0.25
  }
  photons {  // photon block for an object
    target 1.0
    refraction on
    reflection on
  }
}
}
]==]
   return marble_sdl
end

function new(params)
   params    = params or {}
   options   = {
      d      =  1,
      mass   =   .1,
      col1r  = 1,
      col1g  = 0,
      col1b  = 0,
      col2r  = 0,
      col2g  = 1,
      col2b  = 0,
   }

   for k,v in pairs(params) do options[k] = v end

   d     = options.d
   col1r = options.col1r
   col1g = options.col1g
   col1b = options.col1b

   col2r = options.col2r
   col2g = options.col2g
   col2b = options.col2b

   mass = options.mass

   s = Sphere(d, mass)
   s.col = "#ff0000"
   s.pre_sdl = "object {" .. sdl(col1r, col1g, col1b, col2r, col2g, col2b)

   return s
end

