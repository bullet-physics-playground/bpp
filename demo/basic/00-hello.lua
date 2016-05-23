--
-- Demo of basic BPP objects and functions
--

require "module/color"

v.gravity = btVector3(0,-9.81,0)

v.timeStep      = 1/10
v.maxSubSteps   = 10
v.fixedTimeStep = 1/100

use_openscad = 1 -- requires www.openscad.org

v.pre_sdl = [[

#version 3.7;

global_settings {
  assumed_gamma 1.0
  max_trace_level 20

/*
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
*/
  irid_wavelength rgb <0.70,0.52,0.48>
}  

#default{ finish{ ambient 0 diffuse 1 }} 

/*
object {
  Light(
    EmissiveSpectrum(ES_GE_SW_Incandescent_100w),
    Lm_Incandescent_100w,
    x*25, z*25, 4, 4, on
  )
  translate <-100, 290, -100>
}*/

#include "textures.inc"

declare daytime = 0;

   #switch (int(daytime))
   #case (0)    // morning
      light_source {<6000, 500, 1000> rgb <.8, .7, .6>}
      fog {fog_type 2 rgb <.6, .6, .5> distance 50000 fog_alt 500}
      sky_sphere {pigment {gradient y pigment_map {
         [0 rgb 1]
         [.1 wrinkles color_map {[.5 rgb 1] [.7 rgb <.4, .5, .6>]} scale .1]
         [.15 wrinkles color_map {[.1 rgb 1] [.4 rgb <.4, .5, .6>]} scale .1]
         [.2 rgb <.4, .5, .6>]}}}
      #break

   #case (1)    // daytime
      light_source {<3000, 6000, 7000> rgb 1}
      fog {fog_type 2 rgb <.6, .75, .9> distance 50000 fog_alt 1000}
      sky_sphere {pigment {granite color_map {
         [.4 rgb <.3, .5, .8>] [.7 rgb .9]}
         scale <1, .7, 1>}}
      #break

   #case (2)    // sunset
      light_source {<-5000, 1000, 2000> rgb <.8, .6, .3>}
      fog {fog_type 2 rgb <.9, .8, .5> distance 50000 fog_alt 500}
      sky_sphere {pigment {wrinkles color_map {
         [.4 rgb <.7, .2, .4>] [.8 rgb <.9, .5, .4>]}
         scale <.4, .04, .4>}}
      #break

   #case (3)    // night
      light_source {<-6000, 500, 3000> rgb <.2, .25, .3>}
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

#declare M_Glass= // Glass material
material {
  texture {
    pigment { color ReferenceRGB(<0.5,0.9,0.5>) transmit 0.5}
    //pigment { color rgbt <0.5,0.9,0.5,0.5> }

/*
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
*/
  }
/*
  interior {
    ior 1.5
    fade_power 1001
    fade_distance 0.9
    fade_color <0.5,0.8,0.6>
  }
*/
}
]]

p = Plane(0,1,0,0,10)
p.sdl = [[
#if (use_lightsys)
  pigment {
      rgb ReferenceRGB(Gray90)
  }
#else
  texture {
    pigment {
        rgb White * 0.9
      }
    }
#end
  finish {
    Glossy
    ambient 0.2
    specular 0.6 // shiny

/*      irid { 0.25
        thickness 0.2 // of the layer
        turbulence 0.7 }
*/
  }
]]
v:add(p)

cu = Cube(1,1,1,4)
cu.col = "#ef3010"
cu.pos = btVector3(0, 0.5, 0);
cu.sdl = [[
  texture {
    pigment { rgb ReferenceRGB(Red) }
    finish { phong 1}
  }
]]
v:add(cu)

cy = Cylinder(0.5,1,1)
cy.col = "#007f00"
cy.pos = btVector3(1, 0.5, 0)
cy.sdl = [[
  texture {
    pigment { rgb ReferenceRGB(Green) }
    finish { phong 1}
  }
]]
v:add(cy)

sp = Sphere(.5,2)
sp.col = "#ffff00"
sp.pos = btVector3(0, 1.5, 0)
sp.sdl = [[
  texture {
    pigment {
      radial
      frequency 2
      color_map {
        [0.00 color ReferenceRGB(Red)]    [0.25 color ReferenceRGB(Red)]
        [0.25 color ReferenceRGB(Green)]  [0.50 color ReferenceRGB(Green)]
        [0.50 color ReferenceRGB(Blue)]   [0.75 color ReferenceRGB(Blue)]
        [0.75 color ReferenceRGB(Yellow)] [1.00 color ReferenceRGB(Yellow)]
      }
    }
    finish { specular 0.6 }
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
  sc.sdl =
[==[
  material { M_Glass }

/*
  hollow on 
  texture { pigment {rgbt<1,1,1,0.95>} }
  finish {reflection 0.5 ambient .2 diffuse 0 specular 1 roughness .001 }  
  interior { ior 2.42  // diamant
                 // 1.95  // Zircon
    dispersion 1.1
    dispersion_samples 50
  }

  photons {  // photon block for an object
    target 1.0
    refraction on
    reflection on
  }
*/
]==]
  sc.pos = btVector3(1.5,1,0.75)
  v:add(sc)

  gs = OpenSCAD([==[ // http://www.thingiverse.com/thing:1484333
module geodesic_sphere(r=-1, d=-1) {
  // if neither parameter specified, radius is taken to be 1
  rad = r > 0 ? r : d > 0 ? d/2 : 1;  
  
  pentside_pr = 2*sin(36);  // side length compared to radius of a pentagon
  pentheight_pr = sqrt(pentside_pr*pentside_pr - 1);
  // from center of sphere, icosahedron edge subtends this angle
  edge_subtend = 2*atan(pentheight_pr);

  // vertical rotation by 72 degrees
  c72 = cos(72);
  s72 = sin(72);
  function zrot(pt) = [ c72*pt[0]-s72*pt[1], s72*pt[0]+c72*pt[1], pt[2] ];

  // rotation from north to vertex along positive x
  ces = cos(edge_subtend);
  ses = sin(edge_subtend);
  function yrot(pt) = [ ces*pt[0] + ses*pt[2], pt[1], ces*pt[2]-ses*pt[0] ];
  
  // 12 icosahedron vertices generated from north, south, yrot and zrot
  ic1 = [ 0, 0, 1 ];  // north
  ic2 = yrot(ic1);    // north and +x
  ic3 = zrot(ic2);    // north and +x and +y
  ic4 = zrot(ic3);    // north and -x and +y
  ic5 = zrot(ic4);    // north and -x and -y
  ic6 = zrot(ic5);    // north and +x and -y
  ic12 = [ 0, 0, -1]; // south
  ic10 = yrot(ic12);  // south and -x
  ic11 = zrot(ic10);  // south and -x and -y
  ic7 = zrot(ic11);   // south and +x and -y
  ic8 = zrot(ic7);    // south and +x and +y
  ic9 = zrot(ic8);    // south and -x and +y
  
  // start with icosahedron, icos[0] is vertices and icos[1] is faces
  icos = [ [ic1, ic2, ic3, ic4, ic5, ic6, ic7, ic8, ic9, ic10, ic11, ic12 ],
    [ [0, 2, 1], [0, 3, 2], [0, 4, 3], [0, 5, 4], [0, 1, 5],
      [1, 2, 7], [2, 3, 8], [3, 4, 9], [4, 5, 10], [5, 1, 6], 
      [7, 6, 1], [8, 7, 2], [9, 8, 3], [10, 9, 4], [6, 10, 5],
      [6, 7, 11], [7, 8, 11], [8, 9, 11], [9, 10, 11], [10, 6, 11]]];
  
  // now for polyhedron subdivision functions

  // given two 3D points on the unit sphere, find the half-way point on the great circle
  // (euclidean midpoint renormalized to be 1 unit away from origin)
  function midpt(p1, p2) = 
    let (midx = (p1[0] + p2[0])/2, midy = (p1[1] + p2[1])/2, midz = (p1[2] + p2[2])/2)
    let (midlen = sqrt(midx*midx + midy*midy + midz*midz))
    [ midx/midlen, midy/midlen, midz/midlen ];
  
  // given a "struct" where pf[0] is vertices and pf[1] is faces, subdivide all faces into 
  // 4 faces by dividing each edge in half along a great circle (midpt function)
  // and returns a struct of the same format, i.e. pf[0] is a (larger) list of vertices and
  // pf[1] is a larger list of faces.
  function subdivpf(pf) =
    let (p=pf[0], faces=pf[1])
    [ // for each face, barf out six points
      [ for (f=faces) 
          let (p0 = p[f[0]], p1 = p[f[1]], p2=p[f[2]])
            // "identity" for-loop saves having to flatten
            for (outp=[ p0, p1, p2, midpt(p0, p1), midpt(p1, p2), midpt(p0, p2) ]) outp
      ],
      // now, again for each face, spit out four faces that connect those six points
      [ for (i=[0:len(faces)-1])
        let (base = 6*i)  // points generated in multiples of 6
          for (outf =
          [[ base, base+3, base+5], 
          [base+3, base+1, base+4],
          [base+5, base+4, base+2],
          [base+3, base+4, base+5]]) outf  // "identity" for-loop saves having to flatten
      ]
    ];

  // recursive wrapper for subdivpf that subdivides "levels" times
  function multi_subdiv_pf(pf, levels) =
    levels == 0 ? pf :
    multi_subdiv_pf(subdivpf(pf), levels-1);

  // subdivision level based on $fa:
  // level 0 has edge angle of edge_subtend so subdivision factor should be edge_subtend/$fa
  // must round up to next power of 2.  
  // Take log base 2 of angle ratio and round up to next integer
  ang_levels = ceil(log(edge_subtend/$fa)/log(2));
    
  // subdivision level based on $fs:
  // icosahedron edge length is rad*2*tan(edge_subtend/2)
  // actually a chord and not circumference but let's say it's close enough
  // subdivision factor should be rad*2*tan(edge_subtend/2)/$fs
  side_levels = ceil(log(rad*2*tan(edge_subtend/2)/$fs)/log(2));
  
  // subdivision level based on $fn: (fragments around circumference, not total facets)
  // icosahedron circumference around equator is about 5 (level 1 is exactly 10)
  // ratio of requested to equatorial segments is $fn/5
  // level of subdivison is log base 2 of $fn/5
  // round up to the next whole level so we get at least $fn
  facet_levels = ceil(log($fn/5)/log(2));
  
  // $fn takes precedence, otherwise facet_levels is NaN (-inf) but it's ok 
  // because it falls back to $fa or $fs, whichever translates to fewer levels
  levels = $fn ? facet_levels : min(ang_levels, side_levels);

  // subdivide icosahedron by these levels
  subdiv_icos = multi_subdiv_pf(icos, levels);
  
  scale(rad)
  polyhedron(points=subdiv_icos[0], faces=subdiv_icos[1]);
}
geodesic_sphere(r = 0.5, $fn=6);
]==], 1)
  gs.col = "#103070"
  gs.sdl =
[[
  material { M_Glass }

/*
  hollow on 
  texture { pigment {rgbt<1,1,1,0.95>} }
  finish {reflection 0.5 ambient .2 diffuse 0 specular 1 roughness .001 }  
  interior { ior 2.42  // diamant
                 // 1.95  // Zircon
    dispersion 1.1
    dispersion_samples 50
  }

  photons {  // photon block for an object
    target 1.0
    refraction on
    reflection on
  }
*/
]]
  gs.pos = btVector3(0,1.5,1.5)

  v:add(gs);

 rb = OpenSCAD([==[

// Library: rounder.scad
// Version: 1.0
// Author: Zach Hoeken
// Copyright: 2010
// License: GPLv3

// EXAMPLE USAGE:
// pill(5, 30);
// roundedBox(20, 30, 40, 5);

module pill(radius, length)
{
	cylinderHeight = length-radius*2;
	translate([0,0,-cylinderHeight/2])
	{
		union()
		{
			cylinder(h=cylinderHeight, r=radius);
			translate([0,0,0])
				sphere(r=radius);
			translate([0,0,cylinderHeight])
				sphere(r=radius);
		}
	}
}

module roundedBox(x, y, z, r)
{
	union()
	{
		translate([x/2-r,-y/2+r, 0])
			pill(r, z);
		translate([x/2-r,y/2-r,0])
			pill(r, z);
		translate([-x/2+r,-y/2+r, 0])
			pill(r, z);
		translate([-x/2+r,y/2-r,0])
			pill(r, z);

		translate([x/2-r, 0, z/2-r])
			rotate([90, 0, 0])
				pill(r, y);
		translate([-x/2+r, 0, z/2-r])
			rotate([90, 0, 0])
				pill(r, y);
		translate([x/2-r, 0, -z/2+r])
			rotate([90, 0, 0])
				pill(r, y);
		translate([-x/2+r, 0, -z/2+r])
			rotate([90, 0, 0])
				pill(r, y);

		translate([0, y/2-r, z/2-r])
			rotate([0, 90, 0])
				pill(r, x);
		translate([0, -y/2+r, z/2-r])
			rotate([0, 90, 0])
				pill(r, x);
		translate([0, y/2-r, -z/2+r])
			rotate([0, 90, 0])
				pill(r, x);
		translate([0, -y/2+r, -z/2+r])
			rotate([0, 90, 0])
				pill(r, x);
	
		cube([x, y-r*2, z-r*2], center=true);
		cube([x-r*2, y, z-r*2], center=true);
		cube([x-r*2, y-r*2, z], center=true);
	}
}
$fn=15;
roundedBox(1, 1, 1, .05);
]==],10)
  rb.pos = btVector3(0,.5,1.5)
  rb.col = "#ffff00"
  v:add(rb)

end

pixarlamp = Mesh("demo/stl/pixarlamp.stl", 0)
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

v.cam:setUpVector(btVector3(0,1,0), false)
d = 350
o = btVector3(0,-.2,0)
v.cam.pos  = btVector3(d,d,d) - o
v.cam.look = cy.pos - o

v:postSim(function(N)
  v.cam.focal_blur      = 0
  v.cam.focal_aperture  = 5
  -- set blur point to sphere shape position
  v.cam.focal_point = sp.pos

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
