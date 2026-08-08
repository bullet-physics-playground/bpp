--
-- Mesh loading (stl and 3ds)
--
-- Demonstrates loading mesh files in various formats (STL, 3DS).
-- Also shows randomized positioning and multiple meshes.
--
-- Usage: bpp -f demo/basic/06-mesh.lua

local common = require "common"

common.setTiming(1/5, 10, 1/5)

plane = Plane(0,1,0,0,500)
plane.col = "#111111"
v:add(plane)

d = 200

for i = 1,3 do
  m = Mesh("demo/mesh/box.3ds", 10, false)
  m.col="#ff0000"
  m.pos=btVector3(
    math.random()*d-d/2,
    45-i*2,
    math.random()*d-d/2)
  v:add(m)
end
 
d = 100

local p1 = nil

for i = 1,20 do
  m = Mesh("demo/mesh/torus.stl", 1, false)
  m.col="#7f007f"
  m.pos=btVector3(math.random(-d,d),200-i*2,math.random(-d,d))
--  t.rotate(m, btQuaternion(0,1,0,1), btVector3(0,0,0))

  if (i == 10) then p1 = m end

  v:add(m)
end

-- cam pseudo orthogonal, up vector, focal blur on the 10th torus
common.setCamera(btVector3(1000, 2000, 1000), btVector3(0, p1.pos.y - 150, 0),
                 0.2, { horizontal = true, noMove = false,
                        focal_blur = 10, focal_point = p1.pos })
