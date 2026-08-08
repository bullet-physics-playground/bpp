--
-- A room with random objects (WIP)
--

local color       = require "color"
local path_extrude = require "scad/path_extrude"
local common      = require "common"

v.pre_sdl = [[

#version 3.7;

#include "colors.inc"
#include "textures.inc"
#include "glass.inc"
#include "metals.inc"
#include "golds.inc"
#include "stones.inc"
#include "woods.inc"
#include "shapes.inc"
#include "shapes2.inc"
#include "functions.inc"
#include "math.inc"
#include "transforms.inc"

#default{ finish{ ambient 0 diffuse 1 }} 

#declare use_lightsys = 1;
#declare use_contrast = 1.6;
#declare use_photons  = on;

global_settings {
 
  assumed_gamma 1.0

  max_trace_level 5
  #if (use_photons)
    photons {
      spacing 0.02                 // specify the density of photons
      //count 100000               // alternatively use a total number of photons

      //gather min, max            // amount of photons gathered during render [20, 100]
      //media max_steps [,factor]  // media photons
      //jitter 1.0                 // jitter phor photon rays
      //max_trace_level 5          // optional separate max_trace_level
      //adc_bailout 1/255          // see global adc_bailout
      //save_file "filename"       // save photons to file
      //load_file "filename"       // load photons from file
      //autostop 0                 // photon autostop option
      //radius 10                  // manually specified search radius
      // (---Adaptive Search Radius---)
      //steps 1
      //expand_thresholds 0.2, 40
    }

  #end
}

// ground 
plane { <0,1,0>, 0 
    texture{ pigment{ color ReferenceRGB(<0.45,0.85,0.3>) * 0.42 }
    normal { bumps 0.75 scale 0.015}
    finish { phong 0.1}
  }
}

#declare Lightsys_Scene_Scale = 0.1;

// lamp
object {
  Light(
    EmissiveSpectrum(ES_GTE_341_Cool),
    Lm_Incandescent_100w,
    x*0.45, z*0.45, 4, 4, off
  )
  translate <0, 55, 0>
}

light_source{ <0,55,0> 
  color ReferenceRGB(<1,0.94,0.5>) * 0.005
  looks_like {
    sphere{ <0,0,0>, 0.75 
      texture{
        pigment{ color ReferenceRGB(<1,0.98,0.8>) * 1.6 }
        finish {
          ambient 0.8   
          diffuse 0.7
          phong 1
        }
      }
    }
  }
}
]]

common.setTiming(1/25)

p = Plane(0,1,0,0,100)
p.pos = btVector3(0,13,0)
p.col = "green"
v:add(p)

cu = Cube(15,1,15,0)
cu.col = "#ef3010"
cu.pos = btVector3(0, 20.5, 10);
cu.sdl = [[
  texture {
    pigment { color ReferenceRGB(<0.9,0.9,0.5>) * use_contrast }
    finish {
      diffuse .6
      phong 2
    }
  }
]]
v:add(cu)

for i = 1,6 do
cy = Cylinder(0.5,40,10)
cy.friction = 7
cy.col = "#707f00"
cy.pos = btVector3(-5, 40, 45)
cy.sdl = [[
  texture {
    pigment { color ReferenceRGB(Yellow) * use_contrast }
    finish  { specular 0.6 roughness 0.01 }
  }
]]
v:add(cy)
end

for i = 1,5 do
sp = Sphere(1,1)
sp.col = "#ffff00"
sp.pos = btVector3(4.5-i*1.99, 30, 11)
sp.sdl = [[
  texture {
    pigment {
      radial
      frequency 2
      color_map {
        [0.00 color ReferenceRGB(Red)   * use_contrast]  [0.25 color ReferenceRGB(Red)   * use_contrast]
        [0.25 color ReferenceRGB(Green) * use_contrast]  [0.50 color ReferenceRGB(Green) * use_contrast]
        [0.50 color ReferenceRGB(Blue)  * use_contrast]  [0.75 color ReferenceRGB(Blue)  * use_contrast]
        [0.75 color ReferenceRGB(Yellow) * use_contrast] [1.00 color ReferenceRGB(Yellow) * use_contrast]
      }
    }
    finish { specular 0.6 roughness 0.01 }
  }
]]
v:add(sp)
end

  sc = OpenSCAD([[
    difference() {
      translate([0,-12,0])
      cube([100,50,100], center=true);
      translate([0,-12.25,0])
      cube([95,45,95], center=true);
      translate([30,-14, 50])
      cube([25,40,10], center=true);
      translate([-16,-9, 50])
      cube([42,30,10], center=true);
    }
  ]], 0, false)
  sc.col = "#7f7f30"
  sc.sdl = [[
texture {
  pigment{ color ReferenceRGB(<1,1,1>) * use_contrast * 0.9}
  normal { bumps 0.1 scale 0.01 }
  finish { phong 0.4 roughness 0.06 }
}
]]
  sc.pos = btVector3(0,50,0)
  v:add(sc)

path = OpenSCAD(path_extrude.sdl .. [[

o = 1.5;
i = 1.25;
i2 = 1.5;

pts = [ [-o,.25], [o,.25], [o,-i2], [i,-i2], [i,0],
        [-i,0], [-i, -i2], [-o, -i2] ];
    
p = [ for(t = [0:2.5:200]) 
    [2.5*cos(t),-10*sin(t), 0.5*cos(t*3)+t*.045] ];

translate([.5,5.75,5.5])
rotate([270,-90,0])
path_extrude(points=pts, path=p, merge=false);

]], 0, false)
path.col = "#00007f";
path.sdl = [[
  pigment { color ReferenceRGB(<0.9,0.9,0.5>) * use_contrast }
  finish {
    diffuse .6
    phong 2
  }
]]
path.pos = btVector3(0,15,8)

v:add(path)

path = OpenSCAD(path_extrude.sdl .. [[

o = 1.5;
i = 1.25;
i2 = 1.5;

pts = [ [-o,.25], [o,.25], [o,-i2], [i,-i2], [i,0],
        [-i,0], [-i, -i2], [-o, -i2] ];
    
p = [ for (t = [0:5:10]) [t,0, 0] ];

rotate([0,90,0])
rotate([270,0,20])
path_extrude(points=pts, path=p, merge=false);

]], 0, false)
path.col = "#00007f";
path.sdl = [[
  pigment { color ReferenceRGB(<0.9,0.9,0.5>) * use_contrast }
  finish {
    diffuse .6
    phong 2
  }
]]
path.pos = btVector3(10,17,20)
v:add(path)

v:preStart(function(N)
  printf("preStart(%i)", N)
end)

v:preStop(function(N)
  printf("preStop(%i)", N)
end)

v:preSim(function(N)
  --printf("preSim(%i)", N)
end)

v:postSim(function(N)
  --printf("postSim(%i)", N)
end)

v:preDraw(function(N)
  --printf("preDraw(%i)", N)
end)

v:postDraw(function(N)
  --printf("postDraw(%i)", N)
end)

v:onCommand(function(N, cmd)
  printf("onCommand(%i)")
  local f = assert(loadstring(cmd))
  f(v)
end)

function setcam()
  common.setCamera(btVector3(-40,40,40), btVector3(40,20,-20), 1,
                   { horizontal = true })
end

setcam()

-- EOF