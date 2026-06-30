--
-- OpenSCAD template
--
-- Demonstrates using OpenSCAD to generate 3D geometry.
-- The script embeds OpenSCAD code to create 3D letters.
--
-- Usage: bpp -f demo/basic/07-scad.lua

v.gravity = btVector3(0,-9.81,0)

v.timeStep      = 1/10
v.maxSubSteps   = 10
v.fixedTimeStep = 1/100

local p = Plane(0,1,0,0,100)
p.col = "#7f7f7f"
v:add(p)

local N=1

for i = 1,N do
  for j = 1,N do
    o = OpenSCAD([===[

// Written in 2015 by Marius Kintel <marius@kintel.net>
//
// To the extent possible under law, the author(s) have dedicated all
// copyright and related and neighboring rights to this software to the
// public domain worldwide. This software is distributed without any
// warranty.
//
// You should have received a copy of the CC0 Public Domain
// Dedication along with this software.
// If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

font = "Liberation Sans";
// Nicer, but not generally installed:
// font = "Bank Gothic";

module G() offset(0.3) text("G", size=20, halign="center", valign="center", font = font);
module E() offset(0.3) text("E", size=20, halign="center", valign="center", font = font);
module B() offset(0.5) text("B", size=20, halign="center", valign="center", font = font);

$fn=34;

module GEB() {
intersection() {
    linear_extrude(height = 20, convexity = 3, center=true) B();
    
    rotate([90, 0, 0])
      linear_extrude(height = 20, convexity = 3, center=true) E();
    
    rotate([90, 0, 90])
      linear_extrude(height = 20, convexity = 3, center=true) G();
  }
}

color("Ivory") GEB();

color("MediumOrchid") 
  translate([0,0,-20])
    linear_extrude(1) 
      difference() {
        square(40, center=true);
        projection() GEB();
      }

color("DarkMagenta")
  rotate([90,0,0]) 
    translate([0,0,-20])
      linear_extrude(1) 
        difference() {
          translate([0,0.5]) square([40,39], center=true);
          projection() rotate([-90,0,0]) GEB();
        }

color("MediumSlateBlue")
  rotate([90,0,90]) 
    translate([0,0,-20])
      linear_extrude(1)
        difference() {
          translate([-0.5,0.5]) square([39,39], center=true);
          projection() rotate([0,-90,-90]) GEB();
        }

]===], 1, false)

    o.col = "#7f7f7f"

    dim = 9
    o.pos = btVector3(i*dim-N/2*dim,20,j*dim-N/2*dim)

    o.sdl = [[
texture {
 pigment { color rgb <1,0,0> }
 normal { bumps 0.095 scale 0.008 }
 finish { ambient 0 diffuse 0.9 phong 0.0 } }
]]

    v:add(o)
  end
end

v.cam:setUpVector(btVector3(-0.0780239, 0.962312, -0.260514), true)
v.cam.up   = btVector3(-0.0780239, 0.962312, -0.260514)
v.cam.pos  = btVector3(600.407, 610.439, 1996.8)
v.cam.look = btVector3(-275495, -271337, -919858)

--v.cam.focal_blur     = 10
v.cam.focal_aperture = 5
v.cam.focal_point    = btVector3(1,10,0)

v.sdl = [[
light_source { <100, 200, 100> color rgb <1, 0.95, 0.8>
  spotlight
  point_at <0, 0, 0>
  radius 30
  falloff 35
}

light_source { <-100, 180, -80> color rgb <0.8, 0.85, 1>
  spotlight
  point_at <0, 0, 0>
  radius 25
  falloff 30
}
]]