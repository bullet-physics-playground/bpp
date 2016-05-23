--
-- Basic car demo (WIP)
--

t = require "module/trans"

v.timeStep      = 1/5
v.maxSubSteps   = 200
v.fixedTimeStep = 1/200

--v.gravity = btVector3(0,-9.81*.15,0)
--v.gravity = btVector3(0,0,0)

a = 0.05

f = 10

plane = Plane(a,1,a,0,500)
plane.col = "#111111"
plane.friction = f
v:add(plane)
plane = Plane(a,1,-a,0,500)
plane.col = "#111111"
plane.friction = f
v:add(plane)
plane = Plane(-a,1,a,0,500)
plane.col = "#111111"
plane.friction = f
v:add(plane)

function rnd(min, max)
  return math.random(min,max)
end

car = function(r,x,y,z)
  local d   = rnd(2,2.5)
        d1  = rnd(.5,1)
        cd1 = rnd(0.5,0.75)
        cd2 = rnd(0.6,0.75)
        d2  = rnd(0.6,0.7)
        d3  = rnd(0.6,0.7)
        r   = rnd(0.75,.75)
        m1  = rnd(2,15)
        m2  = rnd(2,15)
        s1  = rnd(1000,2000)
        s2  = rnd(1000,2000)
        len = 1.5
        speed = 1

  cube = Cube(d1,3,d,100) 
  --cube.pos = btVector3(x, y, z);
  cube.col = "#ff0000"
  trans.move(cube, btVector3(x,y,z))
  v:add(cube)

  c0 = Cylinder(cd1,.4,m1)
  c0.pos = btVector3(0, -len, 2.5)
  c0.friction = f
  --c0.col = "#ffff00"
  trans.move(c0, btVector3(x,y,z))
  v:add(c0)

  c1 = Cylinder(cd1,.4,m1)
  c1.pos = btVector3(0, -len, -2.5)
  c1.friction = f
  --c1.col = "#0000ff"
  trans.move(c1, btVector3(x,y,z))
  v:add(c1)

  c2 = Cylinder(cd2,.4,m1)
  c2.pos = btVector3(0, len, 2.5)
  c2.friction = f
  --c2.col = "#00ff00"
  trans.move(c2, btVector3(x,y,z))
  v:add(c2)

  c3 = Cylinder(cd2,.4,m1)
  c3.pos = btVector3(0, len, -2.5)
  c3.friction = f
  --c3.col = "#ff00ff"
  trans.move(c3, btVector3(x,y,z))
  v:add(c3)

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

  con1 = btHingeConstraint(
    cube.body, c1.body,
    pivot0, pivot2, axis0, axis2)

  con2 = btHingeConstraint(
    cube.body, c2.body,
    pivot3, pivot4, axis3, axis4)

  con3 = btHingeConstraint(
    cube.body, c3.body,
    pivot3, pivot5, axis3, axis6)

  con0:enableAngularMotor(true, speed, s1)
  con1:enableAngularMotor(true, speed, s2)
  con2:enableAngularMotor(true, speed, s1)
  con3:enableAngularMotor(true, speed, s2)

  v:addConstraint(con0)
  v:addConstraint(con1)
  v:addConstraint(con2)
  v:addConstraint(con3)

  return {car = cube}
end

local c = nil

for i = -3,3 do
  for j = -3,3 do
    d = 7
    tmp = car(0,i*d,10,j*d)
    if (i == 0 and j == 0) then c = tmp end
  end
end

v:postSim(function(n)
  d = 300
  v.cam:setHorizontalFieldOfView(0.3)
  v.cam.pos  = btVector3(0,d,d)
  v.cam.up   = btVector3(0,1,0)
  v.cam.look = c.car.pos
end)
