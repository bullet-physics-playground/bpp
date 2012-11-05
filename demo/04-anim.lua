--
-- camera movement and pre callback function demo
--
-- Known bug: the camera animation keeps running 
-- after loading another script
--

cube = Cube() 
cube.pos = btVector3(0, 0.5, 0);
cube.col = "#ff0000"

plane = Plane(0,1,0)
plane.pos = btVector3(0, 0, 0)
plane.col = "#111111"

v:add(cube)
v:add(plane)

v:pre(function(n)
  print(n)

  i = n / 100 * math.pi * 2 r = 8 z = 8

  cam = Cam()
  cam.pos = btVector3(
  r*math.sin(i), z, r*math.cos(i))

  cam.look = btVector3(0,1,0)

  v:cam(cam)
end)

-- A v:post(function(n) end) callback function not used here.

-- EOF