t = require "transform"

v.gravity = btVector3(0,-9.81*10,0)

plane = Plane(0,1,0,0,200)
plane.col = "#111111"
v:add(plane)

d = 200

for i = 1,5 do
  m = Mesh("demo/box.3ds", 100)
  m.col="#ff0000"
  m.pos=btVector3(math.random()*d-d/2,45-i*2,math.random()*d-d/2)
--  t.rotate(m, btQuaternion(0,1,0,1), btVector3(0,0,0))
  v:add(m)
end
 
d = 100

for i = 1,40 do
  m = Mesh("demo/stl/torus.stl", 1)
  m.col="#7f007f"
  m.pos=btVector3(math.random(-d,d),200-i*2,math.random(-d,d))
--  t.rotate(m, btQuaternion(0,1,0,1), btVector3(0,0,0))
  v:add(m)
end
