--
-- IBEX sculpture (WIP)
--

require "module/color"

v.pre_sdl = [[

#version 3.7;
global_settings{

  assumed_gamma 1.0
  max_trace_level 5
  photons {
    spacing 0.025
    autostop 1
    media 60
  }
}  

#default{ finish{ ambient 0 diffuse 1 }} 

#declare use_lightsys = 1;

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

// ground 
plane { <0,1,0>, 0 
  texture{ pigment{ color rgb<0.45,0.85,0.3>*0.72}
    normal { bumps 0.75 scale 0.015}
    finish { phong 0.1}
  } // end of texture
} // end of plane


// lamp inside

light_source{
  <0.00, 55, -5.00> 
   color rgb<1,0.94,0.85>*0.3 // color * intensity
   looks_like{ sphere{ <0,0,0>,0.75 
   texture{ pigment{ color rgb<1,0.98,0.8>*1.3}
   finish { ambient 0.8   
   diffuse 0.2
   phong 1 }
} // end of texture
  } // end of sphere
 } //end of looks_like

  photons {
    refraction on
    reflection on
  }

 } //end of light_source
]]

use_openscad = 1 -- http://www.openscad.org

v.gravity = btVector3(0,-9.81,0)

v.timeStep      = 1/10
v.maxSubSteps   = 10
v.fixedTimeStep = 1/100

p = Plane(0,1,0,0,1000)
p.pos = btVector3(0,-1,0)
v:add(p)

if (use_openscad == 1) then

  sc = OpenSCAD([[
    $fn = 50;
    difference() {
    d = 3;
    h = 10;
    rotate([-90,0,0])
    cylinder(h,d,1.5, center=true);
    rotate([-90,0,0])
    cylinder(h+1,d,1.5, center=true);
    }
]],0)
  sc.col = "#ffffff"
  sc.pos = btVector3(0,57.5,-5)
  v:add(sc)

  sc = OpenSCAD([[
    difference() {
      translate([0,-5,0])
      cube([100,60,100], center=true);
      translate([0,-10,0])
      cube([95,45,95], center=true);
      translate([30,-10.5,50])
      cube([20,40,10], center=true);
      translate([-16,-5.5,50])
      cube([40,30,10], center=true);
    }
  ]], 0)
  sc.col = color.white
  sc.sdl = [[
      texture { pigment{ color rgb<1,1,1>}
                //normal { bumps 0.25 scale 0.02}
                finish { phong 0.1}
              }
    photons {
      target
      refraction off
      reflection off
      collect on
   }

]]
  sc.pos = btVector3(0,50,0)
  v:add(sc)

tex = [[
  texture {
    Silver_Metal
  } 
  finish { 
    reflection {1} 
    ambient .4
    diffuse .2 
    conserve_energy
  }
  photons{
    target
    reflection on
    refraction on
    collect on
  }
]]

end

N=1000
for i = 0,N do
d = 5
c = Cylinder(0.5,0.2,10)
  tr = btTransform(
    btQuaternion(),
    btVector3(
       math.sin(i)*2,
       35+math.sin(i*2.2)*d*2,
       math.cos(i)*4))
  q = btQuaternion()
  q:setEuler(
0,
math.sin(i/N*3.1415*2)*360,
math.cos(i/N*3.1415)*360
)
  tr:setRotation(q)

  c.trans = tr
  c.col = color.red
  c.sdl = tex
  v:add(c) 
end

function camera()
-- pseudo orthogonal view
  v.cam:setUpVector(btVector3(0,1,0), true)
  v.cam:setHorizontalFieldOfView(1.7)
  v.cam.pos  = btVector3(0,30,40)
  v.cam.look = btVector3(0,50,-40) 
end

v:preStart(function(N)
  print("preStart("..tostring(N)..")")
end)

v:preStop(function(N)
  print("preStop("..tostring(N)..")")
end)

v:preSim(function(N)
--  print("preSim("..tostring(N)..")")
end)

camera()

v:postSim(function(N)

  ---- render every 5th frame with POV-Ray
  --if (N % 5 == 0) then povRender(N) end
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
