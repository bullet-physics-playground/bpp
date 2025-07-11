--
-- Basic car demo
--

-- keyboard shortcuts:
-- * F1 - prev car
-- * F2 - next car

trans = require "module/trans"

v.timeStep      = 1/5
v.maxSubSteps   = 6
v.fixedTimeStep = 1/80

--v.gravity = btVector3(0,-9.81*.15,0)
--v.gravity = btVector3(0,0,0)

use_obstacles = 2 -- 1 planes , 2 terrain

col_sand  = "#404005"
col_wheel  = "#1f1f1f"
col_base = "#0f0f0f"

if(use_obstacles==2) then
  local f = 2000  -- friction

  terrain = Mesh("demo/mesh/terrain.3ds",0)
  terrain.pos =btVector3(0,-1,0)
  terrain.col=col_sand
  terrain.friction=f
  terrain.restitution=0
  terrain.sdl = "texture { t_sand }"
 terrain.trans = btTransform(btQuaternion(0,0,0,1), btVector3(240,-10,175))
-- terrain.trans = btTransform(btQuaternion(-1,0,0,1), btVector3(-60,-10,100))
  v:add(terrain)
end

if(use_obstacles==1) then
  local a = 0.1 -- angle
  local dim = 100
  local f = 200  -- friction

  plane = Plane(a,1,a,0,dim)
  plane.col = col_sand
  plane.friction = f
  plane.sdl = "texture { t_sand }"
  v:add(plane)
  plane = Plane(a,1,-a,0,dim)
  plane.col = col_sand
  plane.friction = f
  plane.sdl = "texture { t_sand }"
  v:add(plane)
  plane = Plane(-a,1,a,0,dim)
  plane.col = col_sand
  plane.friction = f
  plane.sdl = "texture { t_sand }"
  v:add(plane)
end

math.randomseed(2342)

function rnd(min, max)
  return min + math.random() * (max - min)
end

car = function(r,x,y,z)
  local wheel_col = col_wheel
  local base_col  = col_base
  local d   = rnd(10,10)
  local d1  = rnd(5,5)
  local cd1 = rnd(5,5)
  local cd2 = rnd(5,5)
  local cdd = rnd(5,5)  -- wheel width
  local d2  = rnd(1.3,1.5)
  local d3  = rnd(1.2,1.3)
  local r   = rnd(1.75,1.75)
  local m1  = rnd(1,1)
  local m2  = rnd(1,1)
  local s1  = rnd(100,200)
  local s2  = rnd(100,200)
  local len = rnd(10,10)
  local speed = rnd(0.5,1)
  local f = 2000

  cube = Cube(d1,len*2,d,1) 
  cube.col = base_col
  cube.sdl = "texture { t_body }"
  trans.move(cube, btVector3(x,y,z))
  v:add(cube)

  c0 = Cylinder(cd1,cdd,m1)
  c0.pos = btVector3(0, -len, d/2+cdd/2)
  c0.friction = f
  c0.col = wheel_col
  c0.sdl = "texture { t_wheel }"
  trans.move(c0, btVector3(x,y,z))
  v:add(c0)

  c1 = Cylinder(cd1,cdd,m1)
  c1.pos = btVector3(0, -len, -d/2-cdd/2)
  c1.friction = f
  c1.col = wheel_col
  c1.sdl = "texture { t_wheel }"
  trans.move(c1, btVector3(x,y,z))
  v:add(c1)

  c2 = Cylinder(cd2,cdd,m1)
  c2.pos = btVector3(0, len, d/2+cdd/2)
  c2.friction = f
  c2.col = wheel_col
  c2.sdl = "texture { t_wheel }"
  trans.move(c2, btVector3(x,y,z))
  v:add(c2)

  c3 = Cylinder(cd2,cdd,m1)
  c3.pos = btVector3(0, len, -d/2-cdd/2)
  c3.friction = f
  c3.col = wheel_col
  c3.sdl = "texture { t_wheel }"
  trans.move(c3, btVector3(x,y,z))
  v:add(c3)

  pivot0 = btVector3(0,-len,0)
  axis0  = btVector3(0,0,1)

  pivot1 = btVector3(0,0,-d/2-cdd/2)
  axis1  = btVector3(0,0,1)

  pivot2 = btVector3(0,0,d/2+cdd/2)
  axis2  = btVector3(0,0,1)

  pivot3 = btVector3(0,len,0)
  axis3  = btVector3(0,0,1)

  pivot4 = btVector3(0,0,-d/2-cdd/2)
  axis4  = btVector3(0,0,1)

  pivot5 = btVector3(0,0,d/2+cdd/2)
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

c = nil

local cs = {}

NX = 2
NY = 2

for i = -NX,NX do
  for j = -NY,NY do
    d = 50
    tmp = car(0,i*d,10,j*d)
    if (i == 0 and j == 0) then c = tmp end
    cs [i+j*3] = tmp
  end
end

function setcam()
  d = 5000 -- camera distance to object

  v.cam.up   = btVector3(0,1,0)
  v.cam:setHorizontalFieldOfView(0.4)

  v.cam.pos  = c.car.pos
     + btVector3(d*-.1,d*0.1,d*0.2)

  v.cam.look = c.car.pos
     + btVector3(0,-6,0)
  --print(c.car.vel)
end

setcam()

v:preSim(function(N)
  -- reset cars to center if y < -10
  -- XXX does not work yet
  for i = 0, #cs do
    tmp = cs[i]
    if (tmp.car.pos.y < -10) then
      print(tmp.car.pos.y)
      tmp.car.pos.x = 0
      tmp.car.pos.y = 20
      tmp.car.pos.z = 0
      cs[i] = tmp
    end
  end
end)


v:preDraw(function(n)
  setcam()
end)

-- ******************
-- KEYBOARD SHORTCUTS
-- ******************

cn = 1 -- car number for camers focus

-- switch to previous car
v:addShortcut("F1", function(N)
  cn = cn - 1; if (cn <= 0) then cn = #cs end
  print("cn = "..cn) -- print(cs[cn])
  c = cs[cn]
end)

-- switch to next car
v:addShortcut("F2", function(N)
  cn = cn + 1; if (cn >= #cs) then cn = 1 end
  print("cn = "..cn) -- print(cs[cn])
  c = cs[cn]
end)

-- **************
-- POV-Ray export
-- **************

v.pre_sdl = [[
#declare t_sand = texture {
  pigment{ color rgb<0.4,0.28,0.06>}
  normal { bumps 0.5 scale 0.015 }
  finish { diffuse 0.9 phong 0 }
}

#declare t_wheel = texture{
    pigment { Gray50 }
    finish {
      ambient .2
      diffuse .6
      phong .75
      phong_size 25
    }
}
#declare t_body  = texture{
    pigment { Gray10 }
    finish {
      ambient .2
      diffuse .6
      phong .75
      phong_size 25
    }
}
]]

-- EOF
