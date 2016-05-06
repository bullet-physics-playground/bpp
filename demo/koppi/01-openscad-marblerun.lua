--
-- Marble run with OpenSCAD
--

require "color"

v.gravity = btVector3(0,-98.1*2,0)

p = Plane(0,1,0,0,1)
p.pos = btVector3(0,-1,0)
p.col = "#303030"
v:add(p)

function wheel(rad, px, py, pz)
  w = OpenSCAD([[
module wheel(rad) {
  $fn = 70;

  n = 10;
  c = -0.25;

  module rotate_about(v,a) {
    translate(v) rotate(a) translate(-v) child(0);
  }

  difference() {
    cylinder(r = rad-c, h=2, center=true);
    for (i = [0 : n - 1]) {
      rotate(i * 360 / n, [0, 0, 1])
      translate([0, rad-1.5, -1.5])
      rotate(10, [cos(n/360), sin(n/360), 0])
      cylinder(r1=1.275, r2=1.1, h = 3);
    }
    cylinder(r = .6, h=2, center=true);
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

b = box(1, 5,2.5,10, 0,4.1,5.6)
v:add(b)

w = wheel(9, 0,10,0)
v:add(w)

t = tower(15,10,2, 0,5,-2)
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

function run()
  s = Sphere(1,2)
  s.pos = btVector3(1,10,7)
  s.col = color.random_pastel()
  v:add(s)
end

run()

v:onCommand(function(cmd)
  print(cmd)
  local f = assert(loadstring(cmd))
  f(v)
end)
