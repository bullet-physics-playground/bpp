--
-- CSG generated with OpenSCAD
--
-- spur gears
-- http://www.thingiverse.com/thing:6894 
--

require "koppi/hcw"
require "koppi/nutsnbolts"

--print(v.cam.look)
v.cam.look = btVector3(0,60,0)
--v.cam.pos  = btVector3(80,120,260)
--print(v.cam.look)

v.gravity = btVector3(0,-98.1*1, 0)

plane = Plane(0,1,0,0,1000)
plane.col = "#111"
v:add(plane)

c = OpenSCAD([[
union() {
translate([0,-20,0])
cube([30,70,10], center=true);
cube([140,10,10], center=true);
translate([0,-60,0])
cube([100,10,100], center=true);
}
]], 1)

c.pos=btVector3(0,0,0)
c.col = "#530"
v:add(c)

-- small gear

g2 = Mesh("demo/stl/spur-02.stl", .1)
g2.col = "#ff0f00"
g2.pos = btVector3(50,60,6)
v:add(g2)

pivot0 = btVector3(50,0,6)
axis0  = btVector3(0,0,1)

pivot1 = btVector3(0,0,0)
axis1  = btVector3(0,0,1)

con0 = btHingeConstraint(
  c.body, g2.body,
  pivot0, pivot1, axis0, axis1)

speed = 10
s1 = 9e99

con0:enableAngularMotor(true, speed, s1)

v:addConstraint(con0)

-- big center gear

g1 = Mesh("demo/stl/spur-01.stl", .2)
g1.pos = btVector3(0,60,6)
g1.col = "#ff0f00"
v:add(g1)

pivot0 = btVector3(0,0,6)
axis0  = btVector3(0,0,1)

pivot1 = btVector3(0,0,0)
axis1  = btVector3(0,0,1)

con1 = btHingeConstraint(
  c.body, g1.body,
  pivot0, pivot1, axis0, axis1)

v:addConstraint(con1)
 
--g3 = hcw.new({spokeStyle="circlefit", treadStyle="v-grooves", fn=50, mass = 10})

g3 = OpenSCAD([===[
function pi()=3.14159265358979;
function base(x)=exp(x*ln(1.618));

$fn=50;
R=90;
theta=130;
a=2;
n=50;
h=13;
module blade(){
    phi=10;
    linear_extrude(h,center=true,twist = 70.7){
	difference(){
	    polygon([for (i=[0:n])[R*cos(theta*i/(pi()*n))*(1-base(-a*i/n)),R*sin(theta*i/(pi()*n))*(1-base(-a*i/n))]]);
	    polygon([for (i=[0:n])[R*cos(theta*i/(pi()*n)+phi)*(1-base(-a*i/n)),R*sin(theta*i/(pi()*n)+phi)*(1-base(-a*i/n))]]);}}}


// blade();

module propeller(){
    difference(){
	union(){
	    cylinder(h,35/2,35/2,center=true);
	    for(i=[0:3]){
		rotate([0,0,i*360/4]){
		    blade();}}}
	cylinder(20,1.75,1.75,center=true);}}

propeller();
]===], .1)

g3.col = "#707070"
g3.pos = btVector3(0,60,32)
v:add(g3)

pivot3 = btVector3(0,0,26)

con2 = btHingeConstraint(
  g1.body, g3.body,
  pivot3, pivot1, axis0, axis1)

con2:enableAngularMotor(true, 0, 9e99)

v:addConstraint(con2)

function wheels()
  -- treadStyles = { "none", "cross", "o-rings", "v-grooves", "squares", "spheres", "cylindersX" }

  spokeStyles = { "biohazard", "circle", "circlefit", "diamond", "line", "rectangle", "spiral", "fill" }
  i = 0
  for k, s in pairs(spokeStyles) do
   print(s) 
    w = hcw.new({spokeStyle=s, treadStyle="none", fn=50, mass = 1})
    w.col = "#0f0"
    i = i + 1
    w.pos = btVector3(0,180+i*100,60)
    v:add(w)
 end
end

--wheels()

function nuts()
for i = 0,10 do
n = nutsnbolts.new({fun = "grub_bolt (4, 3, 3, 0.2, 32, 1.5, \"metric\", 0.425);"})
n.pos = btVector3(10,100,10+5*i)
v:add(n)
end
end

nuts()

function bolts()
for i = 0,10 do
n = nutsnbolts.new({fun = "conical_allen_bolt (10, 3, 6, 4, 0.2, 32, \"metric\", 1, 2.5, 10, 0.4);"})
n.pos = btVector3(10,100,10+5*i)
v:add(n)
end
end

function hexnuts()
for i = 0,10 do
n = nutsnbolts.new({fun = "hex_nut (1/8, 1/4, 3/8, 1/128, 32, 1, \"imperial\", 28);"})
n.pos = btVector3(10,100,10+5*i)
v:add(n)
end
end

v:onCommand(function(cmd)
  print(cmd)
  local f = assert(loadstring(cmd))
  f(v)
end)