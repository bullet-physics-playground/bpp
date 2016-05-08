p = Plane(0,1,0)
p.col = "#111111" 
v:add(p)

cube = Cube() 
cube.pos = btVector3(0, 0.5, 0);
cube.col = "#ff0000"
v:add(cube)

v:preDraw(function(n)
  -- print(n)

  i = n / 100 * math.pi * 2 r = 8 z = 8

  v.cam.pos = btVector3(
  r*math.sin(i), z, r*math.cos(i))

  v.cam.look = btVector3(0,1,0)
end)

-- All callback functions:
-- * v:preDraw(function) called about 25 times / sec.
-- * v:postDraw(function) called 25 times / sec.
-- * v:preSim(function) called before every simulation step.
-- * v:postSim(function) called after every simulation step.
