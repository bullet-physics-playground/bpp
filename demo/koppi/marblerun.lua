--
-- Marble run (WIP)
--

-- Please disable deactivation state

require "module/color"
require "module/marble"
require "module/path_extrude"

v.timeStep      = 1/6
v.maxSubSteps   = 200
v.fixedTimeStep = 1/40

speed = 0.175
s1 = 9e99

-- POV-Ray scene settings
v.pre_sdl = [==[

#include "finish.inc"
#include "textures.inc"

#declare seee = seed(5);
#declare contrast = 1.0;
#declare Lightsys_Scene_Scale = 0.1;

#declare PlankNormal =
  normal
  { gradient x 2 slope_map { [0 <0,1>][.05 <1,0>][.95 <1,0>][1 <0,-1>] }
    scale 2
  };

#declare Photons=off;

global_settings {
  max_trace_level 15
}

// lamp
object {
  Light(
    EmissiveSpectrum(ES_GTE_341_Cool),
    Lm_Incandescent_100w,
    x*2.45, z*2.45, 4, 4, on
  )
  translate <0, 55, 10>
}

// ground 
#declare RasterScale = 1.0 ;
#declare RasterHalfLine  = 0.045;
#declare RasterHalfLineZ = 0.045;

#macro Raster(RScale, HLine)
   pigment{ gradient x scale RScale
            color_map{[0.000   color rgbt<1,1,1,1>*0.6]
                      [0+HLine color rgbt<1,1,1,1>*0.6]
                      [0+HLine color rgbt<1,1,1,1>]
                      [1-HLine color rgbt<1,1,1,1>]
                      [1-HLine color rgbt<1,1,1,1>*0.6]
                      [1.000   color rgbt<1,1,1,1>*0.6]} }
   finish { ambient 0.15 diffuse 0.85}
#end

]==]

p = Plane(0,1,0,0,100)
p.pos = btVector3(0,-0.5,0)
p.col = "#111111"
p.sdl = [[
  texture { pigment{color rgbt<1,1,1,0.7>*1.1}
            finish {ambient 0.45 diffuse 0.85}}
  texture { Raster(RasterScale,RasterHalfLine ) rotate<0,0,0> }
  texture { Raster(RasterScale,RasterHalfLineZ) rotate<0,90,0>}
  rotate<0,0,0>
  no_shadow
]]
v:add(p)

function marblewheel(mwx, mwy, mwz)

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
      cylinder(r1=1.275, r2=1.0, h = 3);
    }
    cylinder(r = .6, h=2, center=true);
    translate([0,0,1.5])
    cylinder(r = rad-0.5-c, h=2, center=true);
  }
}
wheel(]]..tostring(rad)..[[);]], 20);
  w.pos = btVector3(px, py, pz)
  w.col = "#fff"
  w.sdl = [[
  texture {
    pigment {
      color White
    }
    finish {
      Glossy
      specular 0.6 // shiny
    }
  }
]]
  return w
end

function tower(width, height, depth, px, py, pz)
  t = OpenSCAD([[
module tower(width, height, depth) {
  $fn = 126;
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
  t.col = "#fff"
  return t
end

b = box(1, 3,2,10, mwx+1,mwy+3.9,mwz+5.55)
b.sdl = [[
  pigment { color ReferenceRGB(<0.9,0.8,0.3>) }
  finish {
    diffuse .6
    phong .75
    phong_size 25
  }
]]
v:add(b)

w = wheel(9, mwx+0,mwy+10,mwz+0)
v:add(w)

t = tower(15,10,2, mwx+0,mwy+5,mwz-2)
t.sdl = [[
  pigment { color ReferenceRGB(Red) * contrast }
  finish {
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

con0:enableAngularMotor(true, speed, s1)

v:addConstraint(con0)

path = OpenSCAD(path_extrude.sdl .. [[

o = 1.45;
i = 1.35;
i2 = 1.0;

pts = [ [-o,.25], [o,.25], [o,-i2], [i,-i2], [i,0],
        [-i,0], [-i, -i2], [-o, -i2] ];
    
p = [ for(t = [30:1.5:200]) 
    [2.7*cos(t),-10*sin(t), 0.5*cos(t*1.6)+t*.03] ];

translate([.5,7.75,5.5])
rotate([270,-90,0])
path_extrude(points=pts, path=p, merge=false);

]], 0)
--path.col = "#00007f";
path.sdl = [[
  pigment { color ReferenceRGB(White) * contrast }
  finish {
    diffuse .6
    phong .75
    phong_size 25
  }
]]
path.friction = 1
path.col = color.gray
path.pos = btVector3(mwx,mwy,mwz)
v:add(path)

thing = OpenSCAD([==[
rotate([-90,0,0])
  rotate_extrude($fn = 250)
    polygon(
      points=[[1.2,-0.35],[3.5,-0.1],[4.2,0.9],[5.3,1.1]]
  );
]==],0)
thing.pos = btVector3(mwx+1,mwy+7,mwz+6.5)
thing.friction = 1
thing.col = "#fff"
thing.sdl = [[
  pigment { color ReferenceRGB(White) * contrast }
  finish {
    diffuse .6
    phong .75
    phong_size 25
  }
]]
v:add(thing)

end

--marblewheel(10,0,0)
marblewheel(0,0,0)

function addmarble(px,py,pz)
  rcol1 = color.random_google()
  rcol2 = color.white
  col1 = QColor(rcol1)
  col2 = QColor(rcol2)

  s = marble.new({
col1r = col1.r / 255,
col1g = col1.g / 255,
col1b = col1.b / 255,
col2r = col2.r / 255,
col2g = col2.g / 255,
col2b = col2.b / 255})
  s.pos = btVector3(px,py,pz)
  s.friction = 0.12
  s.restitution = 0
  s.mass = .1
  s.col = rcol1

  v:add(s)
end

function run()
  addmarble(0,19,3)
end

v:postSim(function(N)
  if (N % 15 == 0 and N < 150) then
    run()
  end
end)

function setcam()
  v.cam.focal_blur      = 0-- > 0: enable focal blur
  v.cam.focal_aperture  = 5

  -- set blur point to wheel shape position
  v.cam.focal_point = w.pos

  v.cam:setUpVector(btVector3(0,1,0), false)

  -- pseudo orthogonal view
  v.cam:setFieldOfView(.02)

  v.cam.pos = btVector3(250,300,1000)
  v.cam.look = btVector3(0,10,3)
end

setcam()

--run()

v:onCommand(function(N, cmd)
  print(cmd)
  local f = assert(loadstring(cmd))
  f(v)
end)