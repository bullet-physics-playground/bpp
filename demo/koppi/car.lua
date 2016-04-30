a=0.15

plane = Plane(0,1,a)
plane.col = "#111111"
v:add(plane)
plane = Plane(0,1,-a)
plane.col = "#111111"
v:add(plane)

car = function(r,x,y,z)

local d  = math.random(1,4.75)
      d1 = math.random(0.25,0.7)
      d2 = math.random(0.25,0.7)
      d3 = math.random(0.25,0.7)
      r  = math.random(0.75,1.75)
      m1 = math.random(1,5)
      m2 = math.random(2,15)
      s1 = math.random(1,5)
      s2 = math.random(1,5)

cube = Cube(d1,d1,d,10) 
cube.pos = btVector3(x, z, y);
cube.col = "#ff0000"
v:add(cube)

c0 = Sphere(d2,m1)
c0.pos = btVector3(x, z, 2.5)
c0.col = "#ffff00"
v:add(c0)

c1 = Sphere(d3,m2)
c1.pos = btVector3(x, z, -2.5)
c1.col = "#0000ff"
v:add(c1)

--s=Sphere(d/8,m2)v:add(s)

pivot0 = btVector3(0,0,0)
axis0  = btVector3(0,0,1)

pivot1 = btVector3(0,0,-d/2-.125)
axis1  = btVector3(0,0,1)

pivot2 = btVector3(0,0,d/2+.125)
axis2  = btVector3(0,0,1)

con0 = btHingeConstraint(
  cube.body, c0.body,
  pivot0, pivot1, axis0, axis1)

con0:enableAngularMotor(true, 2, s1)

v:addConstraint(con0)

con1 = btHingeConstraint(
  cube.body, c1.body,
  pivot0, pivot2, axis0, axis2)

con1:enableAngularMotor(true, -2, s2)

v:addConstraint(con1)

end

for i = 1,100 do
  car(1,0,0,i)
end

--v:postSim(function(n)
--if (n % 100 == 0) then
--  car(1,0,0,30)
--  car(1,5,1,20)
--end
--end)