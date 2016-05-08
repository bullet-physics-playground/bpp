--
-- Marble run with OpenSCAD
--

require "color"

v.gravity = btVector3(0,-98.1*2,0)

-- POV-Ray scene settings
v.pre_sdl = [==[

#include "textures.inc"
#declare seee = seed(5);

#declare PlankNormal =
  normal
  { gradient x 2 slope_map { [0 <0,1>][.05 <1,0>][.95 <1,0>][1 <0,-1>] }
    scale 2
  };

]==]

p = Plane(0,1,0,0,10)
p.pos = btVector3(0,-0.5,0)
p.col = "#303030"
p.post_sdl = [[
	
texture { PinkAlabaster scale 2 }
}]]
v:add(p)

function wheel(rad, px, py, pz)
  w = OpenSCAD([[
module wheel(rad) {
  $fn = 170;

  n = 12;
  c = -0.25;

  difference() {
    cylinder(r = rad-c, h=2, center=true);
    for (i = [0 : n - 1]) {
      rotate(i * 360 / n, [0, 0, 1])
      translate([0, rad-1.5, -1.5])
      rotate(10, [cos(n/360), sin(n/360), 0])
      cylinder(r1=1.275, r2=1.1, h = 3);
    }
    cylinder(r = .6, h=2, center=true);
    translate([0,0,1.5])
    cylinder(r = rad-2-c, h=2, center=true);
  }
}
wheel(]]..tostring(rad)..[[);]], 20);
  w.pos = btVector3(px, py, pz)
  w.col = color.gray
  return w
end

function tower(width, height, depth, px, py, pz)
  t = OpenSCAD([[
module tower(width, height, depth) {
  $fn = 26;
  c = .5;
  union() {
    cube([width-c,height,depth], center=true);
    translate([0,-height/2-0.5,0])
    cube([width,1,5], center=true);
    translate([0,height/2,0])
    cylinder(r = .6, h=8, center=true);
    translate([0,height/2,0])
    cylinder(r = width/2-c/2, h = depth, center=true);
  }
}
tower(]]..tostring(width)..[[,]]..tostring(height)..[[,]]..tostring(depth)..[[);]], 0);
  t.pos = btVector3(px, py, pz)
  t.col = color.red
  return t
end

function box(c, width, height, depth, px, py, pz)
  t = OpenSCAD([[
module box(c, width, height, depth) {
  $fn = 70;

  difference() {
    rotate(-17,[1,0,0])
    rotate(10,[0,0,1])
    difference() {
      cube([width,height,depth], center=true);
      translate([0,c,0])
      cube([width-c,height+c,depth-c], center=true);
      translate([0,c,-c])
      cube([width-c,height+c,depth-c], center=true);
    }
    translate([0,-1,-5.5])
    cube([width+c,height*2,2], center=true);
  }
}
box(]]..tostring(c)..[[,]]..tostring(width)..[[,]]..tostring(height)..[[,]]..tostring(depth)..[[);]], 0);
  t.pos = btVector3(px, py, pz)
  t.col = color.green
  return t
end

b = box(1, 5,1.4,10, 0,3.5,5.6)
b.sdl = [[
pigment { Gray20 }
    finish {
      ambient .2
      diffuse .6
      phong .75
      phong_size 25
    }
]]
v:add(b)

w = wheel(9, 0,10,0)
w.sdl = [[
pigment { Gray50 }
    finish {
      ambient .2
      diffuse .6
      phong .75
      phong_size 25
    }
]]
v:add(w)

t = tower(15,10,2, 0,5,-2)
t.sdl = [[
pigment { Gray20 }
    finish {
      ambient .2
      diffuse .6
      phong .75
      phong_size 25
    }
]]
v:add(t)

pivot0 = btVector3(0,0,-2)
axis0  = btVector3(0,0,1)

pivot1 = btVector3(0,5,0)
axis1  = btVector3(0,0,1)

con0 = btHingeConstraint(
  w.body, t.body,
  pivot0, pivot1, axis0, axis1)

speed = 1.0
s1 = 9e99

con0:enableAngularMotor(true, speed, s1)

v:addConstraint(con0)

v.cam:setHorizontalFieldOfView(0.15)

function run()
  s = Sphere(1,2)
  s.pos = btVector3(1,10,7)
  s.col = color.random_pastel()

  s.pre_sdl = [==[

// from alzinger.de/cms5/robert/raytracing/marble-machine-in-povray.html

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
        pigment{ color ]==]..(math.random() >= 0.5 and "Blue" or "Red")..[==[ }
        finish { diffuse 0.9 phong 0.8 }
      }
    }
    blob {
      threshold  0.1
      #for (i,-0.9,0.9,0.01)
        sphere {0,1, 0.2 scale <sin(((i+1)*pi/2))*0.8,0.1,0.08> 
        translate y*(i) rotate <0,90+i*150,0>}
      #end
        texture { pigment{ color ]==]..(math.random() >= 0.5 and "Yellow" or "Green")..[==[ }
        finish {diffuse 0.9 phong 0.8}
      }
    }
  }
  texture { Glass }
  interior {
    ior 1.5 caustics 0.25
  }
}
]==]

  v:add(s)
end

run()

v:onCommand(function(cmd)
  print(cmd)
  local f = assert(loadstring(cmd))
  f(v)
end)
