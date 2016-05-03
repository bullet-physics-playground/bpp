t = require "transform"

--v.gravity = btVector3(0,-9.81*.15,0)
--v.gravity = btVector3(0,0,0)

a=0.15

plane = Plane(a,1,a,0,200)
plane.col = "#111111"
v:add(plane)
plane = Plane(a,1,-a,0,200)
plane.col = "#111111"
v:add(plane)
plane = Plane(-a,1,a,0,200)
plane.col = "#111111"
v:add(plane)

car = function(r,x,y,z)

local d  = math.random(1,3)
      d1 = math.random(.5,1)
      d2 = math.random(0.25,0.7)
      d3 = math.random(0.25,0.7)
      r  = math.random(0.75,.75)
      m1 = math.random(2,15)
      m2 = math.random(2,15)
      s1 = math.random(1,2)
      s2 = math.random(1,2)

cube = Cube(d1,4,d,100) 
cube.pos = btVector3(x, z, y);
cube.col = "#ff0000"
--t.move(cube, btVector3(10,10,0))
v:add(cube)

c0 = Cylinder(1,1,.4,m1)
c0.pos = btVector3(x, z, 2.5)
--c0.col = "#ffff00"
v:add(c0)

c1 = Cylinder(1,1,.4,m1)
c1.pos = btVector3(x, z, -2.5)
--c1.col = "#0000ff"
v:add(c1)

c2 = Cylinder(1,1,.4,m1)
c2.pos = btVector3(x, z, 2.5)
--c2.col = "#00ff00"
v:add(c2)

c3 = Cylinder(1,1,.4,m1)
c3.pos = btVector3(x, z, -2.5)
--c3.col = "#ff00ff"
v:add(c3)

len = 1.5

pivot0 = btVector3(0,-len,0)
axis0  = btVector3(0,0,1)

pivot1 = btVector3(0,0,-d/2-.125)
axis1  = btVector3(0,0,1)

pivot2 = btVector3(0,0,d/2+.125)
axis2  = btVector3(0,0,1)

pivot3 = btVector3(0,len,0)
axis3  = btVector3(0,0,1)

pivot4 = btVector3(0,0,-d/2-.125)
axis4  = btVector3(0,0,1)

pivot5 = btVector3(0,0,d/2+.125)
axis6  = btVector3(0,0,1)

con0 = btHingeConstraint(
  cube.body, c0.body,
  pivot0, pivot1, axis0, axis1)

speed = 1000

con0:enableAngularMotor(true, speed, s1)

v:addConstraint(con0)

con1 = btHingeConstraint(
  cube.body, c1.body,
  pivot0, pivot2, axis0, axis2)

con1:enableAngularMotor(true, -speed, s2)

v:addConstraint(con1)

con2 = btHingeConstraint(
  cube.body, c2.body,
  pivot3, pivot4, axis3, axis4)

con2:enableAngularMotor(true, speed, s1)

v:addConstraint(con2)

con3 = btHingeConstraint(
  cube.body, c3.body,
  pivot3, pivot5, axis3, axis6)

con3:enableAngularMotor(true, -speed, s2)

v:addConstraint(con3)

end

for i = 1,50 do
  car(1,0,0,i)
end

--v:postSim(function(n)
--if (n % 100 == 0) then
--  car(1,0,0,30)
--  car(1,5,1,20)
--end
--end)