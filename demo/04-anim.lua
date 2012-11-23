-- preDraw callback demo: move cam

cube = Cube() 
cube.pos = btVector3(0, 0.5, 0);
cube.col = "#ff0000"
v:add(cube)

p = Plane(0,1,0) p.col = "#111111" 
v:add(p)

v:preDraw(function(n)
  -- print(n)

  i = n / 100 * math.pi * 2 r = 8 z = 8

  cam = Cam()
  cam.pos = btVector3(
  r*math.sin(i), z, r*math.cos(i))

  cam.look = btVector3(0,1,0)

  v:cam(cam)
end)

-- More callback functions:

-- v:postDraw(function)
-- v:preSim(function)
-- v:postSim(function)