--
-- Lua transform module demo (WIP)
--

require "module/trans"

v.timeStep      = 1/5
v.maxSubSteps   = 10
v.fixedTimeStep = 1/5

plane = Plane(0,1,0,0,500)
plane.col = "#111111"
v:add(plane)

d = 200

for i = 1,3 do
  m = Mesh("demo/mesh/box.3ds", 100)
  m.col="#ff0000"
  m.pos=btVector3(
    math.random()*d-d/2,
    45-i*2,
    math.random()*d-d/2)
--  t.rotate(m, btQuaternion(0,1,0,1), btVector3(0,0,0))
  v:add(m)
end
 
d = 100

local p1 = nil

for i = 1,20 do
  m = Mesh("demo/mesh/torus.stl", 1)
  m.col="#7f007f"
  m.pos=btVector3(math.random(-d,d),200-i*2,math.random(-d,d))
--  t.rotate(m, btQuaternion(0,1,0,1), btVector3(0,0,0))

  if (i == 10) then p1 = m end

  v:add(m)
end

-- cam pseudo orthogonal
v.cam:setHorizontalFieldOfView(0.2)

-- cam up vector
v.cam:setUpVector(
  btVector3(0,1,0), false)

r = 1000 z = 2000
v.cam.pos = btVector3(r, z, r)
v.cam.look = btVector3(0,p1.pos.y-150,0)

-- cam focal blur
v.cam.focal_blur      = 10
v.cam.focal_aperture  = 5
-- set blur point to mesh shape position
v.cam.focal_point = p1.pos
