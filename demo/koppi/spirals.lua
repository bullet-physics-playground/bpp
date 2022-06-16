--
-- Parametric OpenSCAD spirals
--

color = require "module/color"
marble = require "module/marble"

v.timeStep      = 1/6
v.maxSubSteps   = 200
v.fixedTimeStep = 1/100

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

// texture macro for plane
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

p = Plane(0,1,0,0,1000)
p.pos = btVector3(0,-0.5,0)
p.col = "#000000"
p.sdl = [[
  texture { pigment{color rgbt<1,1,1,0.7>*1.1}
            finish {ambient 0.45 diffuse 0.85}}
  texture { Raster(RasterScale,RasterHalfLine ) rotate<0,0,0> }
  texture { Raster(RasterScale,RasterHalfLineZ) rotate<0,90,0>}
  rotate<0,0,0>
  no_shadow
]]
v:add(p)

function spiral1(height, twist, fn, mass)
  return OpenSCAD([[
  linear_extrude(
    center = true,
    height = ]]..tostring(height)..[[, 
    convexity = 10,
    twist  = ]]..tostring(twist) ..[[,
    $fn    = ]]..tostring(fn)    ..[[)
  translate([1, 0, 0])
  circle(r = 1);
]], mass)
end

function spirals() 
  for i = 0,5 do
    s = spiral1(10,100+i*500, 50, .1)
    s.pos = btVector3(-10+i*5,2,0)
    s.col = color.gray
    v:add(s)
  end
end

--spirals()

function spiral2()
  return OpenSCAD(
[==[
translate([0,1,0])
rotate(-90,[1,0,0])
union() {
r=1; 
thickness=1; 
loops=3; 
linear_extrude(height=1.5)
polygon(points= concat( 
    [for(t = [90:360*loops]) 
        [(r-thickness+t/90)*sin(t),(r-thickness+t/90)*cos(t)]], 
    [for(t = [360*loops:-1:90]) 
        [(r+t/90)*sin(t),(r+t/90)*cos(t)]] 
        ));
  translate([0,-0.5,0])
  cylinder(h=0.75, r=r*14);
};
]==],0)
end

sp = spiral2()
sp.col = color.gray
v:add(sp)

v:postSim(function(N)
  tr = sp.trans
  q = btQuaternion()
  q:setEuler(-N/5,0,0)
  tr:setRotation(q)
  sp.trans = tr
end)

function run()
  s = marble.new({})

  s.pos = btVector3(1,10,0)
  s.col = color.random_pastel()
  v:add(s)
end

run()

v:preSim(function(N)
  if (N % 10 == 0 and N < 1000) then
    run()
  end

end)

v:onCommand(function(N, cmd)
  print(cmd)
  local f = assert(loadstring(cmd))
  f(v)
end)

v.cam.focal_blur      = 0
v.cam.focal_aperture  = 5
--v.cam.focal_point = XXX.pos
v.cam:setUpVector(btVector3(0,1,0), true)
v.cam:setHorizontalFieldOfView(1.1)
v.cam.pos  = btVector3(0,30,-20)
v.cam.look = btVector3(0,0,0) 
