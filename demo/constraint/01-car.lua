--
-- Basic car demo
--

-- keyboard shortcuts:
-- * F1 - prev car
-- * F2 - next car

require "module/trans"

v.timeStep      = 1/2.5
v.maxSubSteps   = 6
v.fixedTimeStep = 1/60

--v.gravity = btVector3(0,-9.81*.15,0)
--v.gravity = btVector3(0,0,0)

use_obstacles = 2 -- 1 planes , 2 terrain

col_sand  = "#ffff99"
col_base  = "#2f2f2f"
col_wheel = "#0f5f1f"

if(use_obstacles==2) then
  local f = 2000  -- friction

  terrain = Mesh("demo/mesh/terrain.3ds",0)
  terrain.pos =btVector3(0,-1,0)
  terrain.col=col_sand
  terrain.friction=f
  terrain.restitution=0
  terrain.sdl = "texture { t_sand }"
  v:add(terrain)
end

if(use_obstacles==1) then
  local a = 0.2 -- ange
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

math.randomseed(os.time())

function rnd(min, max)
  return min + math.random() * (max - min)
end

car = function(r,x,y,z)
  local wheel_col = col_wheel
  local base_col  = col_base
  local d   = rnd(2.5,3)
  local d1  = rnd(.4,0.4)
  local cd1 = rnd(0.5,0.6)
  local cd2 = rnd(0.5,0.9)
  local d2  = rnd(0.3,0.5)
  local d3  = rnd(0.2,0.3)
  local r   = rnd(0.75,.75)
  local m1  = rnd(12,15)
  local m2  = rnd(12,15)
  local s1  = rnd(100,200)
  local s2  = rnd(100,200)
  local len = rnd(1.5,2)
  local speed = rnd(3,10)
  local f = 200

  cube = Cube(d1,len*2,d,100) 
  cube.col = base_col
  trans.move(cube, btVector3(x,y,z))
  v:add(cube)

  c0 = Cylinder(cd1,.4,m1)
  c0.pos = btVector3(0, -len, d/2+.4/2)
  c0.friction = f
  c0.col = wheel_col
  trans.move(c0, btVector3(x,y,z))
  v:add(c0)

  c1 = Cylinder(cd1,.4,m1)
  c1.pos = btVector3(0, -len, -d/2-.4/2)
  c1.friction = f
  c1.col = wheel_col
  trans.move(c1, btVector3(x,y,z))
  v:add(c1)

  c2 = Cylinder(cd2,.4,m1)
  c2.pos = btVector3(0, len, d/2+.4/2)
  c2.friction = f
  c2.col = wheel_col
  trans.move(c2, btVector3(x,y,z))
  v:add(c2)

  c3 = Cylinder(cd2,.4,m1)
  c3.pos = btVector3(0, len, -d/2-.4/2)
  c3.friction = f
  c3.col = wheel_col
  trans.move(c3, btVector3(x,y,z))
  v:add(c3)

  pivot0 = btVector3(0,-len,0)
  axis0  = btVector3(0,0,1)

  pivot1 = btVector3(0,0,-d/2-.4/2)
  axis1  = btVector3(0,0,1)

  pivot2 = btVector3(0,0,d/2+.4/2)
  axis2  = btVector3(0,0,1)

  pivot3 = btVector3(0,len,0)
  axis3  = btVector3(0,0,1)

  pivot4 = btVector3(0,0,-d/2-.4/2)
  axis4  = btVector3(0,0,1)

  pivot5 = btVector3(0,0,d/2+.4/2)
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

for i = -3,3 do
  for j = -3,3 do
    d = 7
    tmp = car(0,i*d,10,j*d)
    if (i == 0 and j == 0) then c = tmp end
    cs [i+j*3] = tmp
  end
end

function setcam()
  d = 30

  v.cam.up   = btVector3(0,1,0)
  v.cam:setHorizontalFieldOfView(1.2)

  v.cam.pos  = c.car.pos
     + btVector3(d*-.1,d*0.1,d*0.4)

  v.cam.look = c.car.pos
  --print(c.car.vel)
end

setcam()

v:postSim(function(n)
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
  pigment{ color rgb<0.9,0.78,0.6>}
  normal { bumps 0.5 scale 0.015 }
  finish { diffuse 0.9 phong 0 }
}
]]

-- EOF