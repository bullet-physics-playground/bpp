--
-- Parametric OpenSCAD spirals
--
require "color"
require "transform"

v.gravity = btVector3(0,-9.81*10, 0)

p = Plane(0,1,0,0,100)
p.col = "#555555"
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
    s.col = color.random_pastel()
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
sp.col = color.green
v:add(sp)

v:postSim(function(N)
  tr = btTransform()
  q = btQuaternion()
  q:setEuler(N/5,0,0)
  tr:setRotation(q)
  sp.trans = tr
end)

function run()
  s = Sphere(1.25,5)
  s.pos = btVector3(1,10,0)
  s.col = color.random_pastel()
  v:add(s)
end

run()

v:onCommand(function(cmd)
  print(cmd)
  local f = assert(loadstring(cmd))
  f(v)
end)

