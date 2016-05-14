v.pre_sdl = [[

#version 3.7;

#include "rad_def.inc"

global_settings {
  assumed_gamma 1.0
  max_trace_level 256

  radiosity {
    count 100 
    recursion_limit 2
            low_error_factor .5 
            gray_threshold 0.0  
            minimum_reuse 0.015 
            brightness 1
            adc_bailout 0.01/2
            brightness 0.5
            normal on
//            media on
  }
}  

#default{ finish{ ambient 0 diffuse 1 }} 

//----------------------------------------

#declare Photons=off;

global_settings {
 
  max_trace_level 5
  #if (Photons)          // global photon block
    photons {
      spacing 0.0025                 // specify the density of photons
      //count 100000               // alternatively use a total number of photons

      //gather min, max            // amount of photons gathered during render [20, 100]
      //media max_steps [,factor]  // media photons
      //jitter 1.0                 // jitter phor photon rays
      //max_trace_level 5          // optional separate max_trace_level
      //adc_bailout 1/255          // see global adc_bailout
      //save_file "filename"       // save photons to file
      //load_file "filename"       // load photons from file
      autostop 1                 // photon autostop option
      //radius 10                  // manually specified search radius
      // (---Adaptive Search Radius---)
      //steps 1
      //expand_thresholds 0.2, 40
    }

  #end
}

#include "textures.inc"

#if (use_lightsys)

#declare Lightsys_Scene_Scale=0.07;

  object {
    Light(EmissiveSpectrum(ES_Osram_CoolFluor_36w), Lm_Incandescent_15w, x*0.015, z*0.015, on*4, on*4, on)
    translate <0.6,3.425,3.4>

  photons {
    reflection on
    refraction on
  }
}

#else

light_source {
  <0.6,3.425,3.4>       // light's position
  color rgb 0.3       // light's color
  photons {           // photon block for a light source
    refraction on
    reflection on
  }
}

#end

declare daytime = 4;

   #switch (int(daytime))
   #case (0)    // morning
      light_source {<6000, 500, -1000> rgb <.8, .7, .6>}
      fog {fog_type 2 rgb <.6, .6, .5> distance 50000 fog_alt 500}
      sky_sphere {pigment {gradient y pigment_map {
         [0 rgb 1]
         [.1 wrinkles color_map {[.5 rgb 1] [.7 rgb <.4, .5, .6>]} scale .1]
         [.15 wrinkles color_map {[.1 rgb 1] [.4 rgb <.4, .5, .6>]} scale .1]
         [.2 rgb <.4, .5, .6>]}}}
      #break

   #case (1)    // daytime
      light_source {<3000, 6000, -7000> rgb 1}
      fog {fog_type 2 rgb <.6, .75, .9> distance 50000 fog_alt 1000}
      sky_sphere {pigment {granite color_map {
         [.4 rgb <.3, .5, .8>] [.7 rgb .9]}
         scale <1, .7, 1>}}
      #break

   #case (2)    // sunset
      light_source {<-5000, 1000, -2000> rgb <.8, .6, .3>}
      fog {fog_type 2 rgb <.9, .8, .5> distance 50000 fog_alt 500}
      sky_sphere {pigment {wrinkles color_map {
         [.4 rgb <.7, .2, .4>] [.8 rgb <.9, .5, .4>]}
         scale <.4, .04, .4>}}
      #break

   #case (3)    // night
      light_source {<-6000, 500, -3000> rgb <.2, .25, .3>}
      fog {fog_type 2 rgb <.1, .15, .2> distance 50000 fog_alt 500}

     #break

   #case (4)   // sunset oyonale
//---------------------------------------
// Sun and sky
//---------------------------------------

#macro GammaColor(Color,Gamma)
    rgb <pow(Color.red,Gamma),pow(Color.green,Gamma),pow(Color.blue,Gamma)>
#end

#declare Pos_Camera=y*1000;


#declare C_Sun=<204,162,124>/255;
#declare C_SkyTop=rgb <36,57,86>/255;
#declare C_SkyBottom=rgb <138,31,24>/255;
#declare C_Cloud=rgb <92,82,80>/255;

#declare C_Sky1=rgb <194,101,80>/255;
#declare C_Sky2=rgb <204,162,124>/255;
#declare C_Sky3=rgb <254,234,26>/255;
#declare C_Fog=C_Sky1*1.2;
#declare C_Sand=rgb <105,126,112>/255;
#declare C_Sand2=rgb <70,79,61>/255;

#declare T_Clear=texture{pigment{Clear}finish{ambient 0 diffuse 0}}


// This is sun for the clouds
// The terrain has its own light group with the sun slightly higher above the horizon
#declare SunAngleX=4;
#declare SunAngleX_Terrain=12;
#declare SunAngleY=200;
#declare Transform_Sun=transform{
    rotate x*SunAngleX
    rotate y*SunAngleY
}
#declare Pos_Sun=(vaxis_rotate(vaxis_rotate(vaxis_rotate(z,x,-SunAngleX),y,SunAngleY-180)*<1,1,2>,x,-0.5)-z)*100000000;
light_source {
    -z*100000
    color GammaColor(C_Sun,2)
    transform{Transform_Sun}
}


#declare P_SkySun=pigment {
        pigment_pattern{
            cylindrical
            poly_wave 3
            rotate x*90     
            scale 0.4
            rotate x*-SunAngleX
            rotate y*(SunAngleY-180)
        }
        pigment_map{
            [ 0 function {min(1,max(0,y))} 
                poly_wave 0.6
                color_map {
                    [0.0 C_Sky1]
                    [0.3 C_Sky3]
                    [1.0 C_Sky2]
                }
                scale 0.32
            ]
            [ 0.8 color C_Sky3*5]
            [ 0.86 color White*10]
            [ 1 color White*20] // the sun has to come through the fog
        }
    
    }

#declare P_SkyBack=pigment {
    function {min(1,max(0,y))}
    poly_wave 0.6
    color_map{
        [0 color C_SkyBottom]
        [1 color C_SkyTop]
    }
}
#declare Sky=sky_sphere {
    pigment {
        gradient z
        pigment_map{
            [0.5 P_SkyBack]
            [1 P_SkySun]
        }
        scale <1,1,2>
        rotate x*-0.5
        translate -z
    }
}
#declare SunFlare=disc{0,y,1
    hollow
    no_shadow
    texture{
        pigment{
            cylindrical
            poly_wave 2
            color_map{
                [0.3 Clear]
                [1 rgbt <1,1,1,0.5>]
            }
        } 
        finish{ambient 1}
    }
    rotate x*90
}
object{SunFlare scale 300 translate Pos_Camera+(Pos_Sun-Pos_Camera)*1000/Pos_Sun.z}
// sky_sphere{Sky}
// fog{C_Fog fog_type 2 distance 400000 fog_alt 1000 }

  #end

#declare M_Glass=    // Glass material
material {
  texture {
    pigment {rgbt 1}
    finish {
      ambient 0.0
      diffuse 0.05
      specular 0.6
      roughness 0.005
      reflection {
        0.1, 1.0
        fresnel on
      }
      conserve_energy
    }
  }
  interior {
    ior 1.5
    fade_power 1001
    fade_distance 0.9
    fade_color <0.5,0.8,0.6>
  }
}

/*
sphere {
  <0,1,0>, 1
  translate <1.0,0,-1.3>
  material { M_Glass }

  photons {  // photon block for an object
    target 1.0
    refraction on
    reflection on
  }
}

cylinder {
  <0,0.01,0>, <0,2.5,0>, 1
  translate <-1.2,0,0.8>
  material { M_Glass }

  photons {  // photon block for an object
    target 1.0
    refraction on
    reflection on
  }
}
*/
]]

require "color"

use_openscad = 1 -- http://www.openscad.org

v.gravity = btVector3(0,-9.81,0)

v.timeStep      = 1/10
v.maxSubSteps   = 10
v.fixedTimeStep = 1/100

p = Plane(0,1,0,0,10)
p.col = color.gray
p.sdl = [[
#if (use_lightsys)
  pigment {
    checker
      rgb ReferenceRGB(Gray30)
      rgb ReferenceRGB(Gray60)
  }
#else
  texture {
    pigment {
      checker
        rgb White * 0.3,
        rgb White * 0.6
      }
    }
#end
  finish {
    Glossy
    ambient 0.2
    specular 0.6 // shiny
  }
]]
v:add(p)

cu = Cube(1,1,1,4)
cu.col = "#ef3010"
cu.pos = btVector3(0, 0.5, 0);
cu.sdl = [[
  texture {
    pigment { color Red }
    finish { phong 1}
  }
]]
v:add(cu)

cy = Cylinder(0.5,1,1)
cy.col = "#007f00"
cy.pos = btVector3(1, 0.5, 0)
cy.sdl = [[
  texture {
    pigment { color Green }
    finish { phong 1}
  }
]]
v:add(cy)

sp = Sphere(.5,2)
sp.col = "#ffff00"
sp.pos = btVector3(0.5, 2, 0)

sp.sdl = [[
  texture { uv_mapping
    pigment {
      tiling 6
        color_map {
          [ 0.0 color rgb<1,1,1>]
          [ 1.0 color rgb<0,0,0>]
        }
      scale 0.10/4
      rotate<-90,0,0>
      scale<1/1.6,2,1>
    }
    finish { phong 1}
  }
]]

v:add(sp)

if (use_openscad == 1) then
  sc = OpenSCAD([[
    rotate_extrude(convexity = 10, $fn = 40)
    translate([0.45, 0, 0])
    circle(r = 0.25, $fn = 20);
  ]], 18.75)
  sc.col = "#103070"
  sc.sdl = [[
  material { M_Glass }

  hollow on 
  texture { pigment {rgbt<1,1,1,0.95>} }
  finish {reflection 0.5 ambient .2 diffuse 0 specular 1 roughness .001 }  
  interior { ior 2.42  // diamant
                 // 1.95  // Zircon
  }

  photons {  // photon block for an object
    target 1.0
    refraction on
    reflection on
  }
]]
  sc.pos = btVector3(2.5,3,0.1)
  v:add(sc)
end

pixarlamp = Mesh("demo/koppi/pixarlamp.stl", 0)
pixarlamp.trans = btTransform(btQuaternion(-0.04,-.48,-1.1,1), btVector3(0.8,3.17,3))
pixarlamp.col = "#ffffff"
v:add(pixarlamp)

ls = Sphere(0.25,0)
ls.pos = btVector3(0.6,3.425,3.4)
--v:add(ls)

-- pseudo orthogonal view
v.cam:setFieldOfView(.01)

v:preStart(function(N)
  print("preStart("..tostring(N)..")")
end)

v:preStop(function(N)
  print("preStop("..tostring(N)..")")
end)

v:preSim(function(N)
--  print("preSim("..tostring(N)..")")
end)

v:postSim(function(N)
  --v.cam:setUpVector(btVector3(0,1,0), false)
  --d = 350
  --o = btVector3(-.2,-.2,0)
  --v.cam.pos  = btVector3(-d,d,d) - o
  --v.cam.look = cy.pos - o 

  ---- render every 10th frame with POV-Ray
  -- if (N % 10 == 0) then povRender(N) end
end)

v:preDraw(function(N)
--  print("preDraw("..tostring(N)..")")
end)

v:postDraw(function(N)
--  print("postDraw("..tostring(N)..")")
end)

function povRender(N)
  v:quickRender("-p -d +W320 +H240 +O/tmp/00-hello-"..string.format("%05d", N)..".png")
end

v:onCommand(function(N, cmd)
  --print("at frame "..tostring(N)..": '"..cmd)

  local f = assert(loadstring(cmd))
  f(v)
end)
