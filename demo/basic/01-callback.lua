--
-- Callback functions demo
--

-- tip: type "run()" in the GUI Command Line

p = Plane(0,1,0,0,100)
p.col = "#111111" 
v:add(p)

function run() -- adds a red cube
  cube = Cube() 
  cube.pos = btVector3(0, 5, 0);
  cube.col = "#ff0000"
  v:add(cube)
  return cube
end

local cube = run()

-- Called before the animation starts
v:preStart(function(N)
  print("preStart("..tostring(N)..")")
end)

-- Called before the animation stops
v:preStop(function(N)
  print("preStop("..tostring(N)..")")
end)

-- Called about 25 times per second
v:preDraw(function(n) -- print(n)
  i = n / 1000 * math.pi * 2

  r = 50 z = 40

  -- cam pseudo orthogonal
  v.cam:setHorizontalFieldOfView(0.4)

  -- cam up vector
  v.cam:setUpVector(
    btVector3(math.sin(i/4)*0.15,1,0), false)

  v.cam.pos = btVector3(
    r*math.sin(i), z, r*math.cos(i))
  v.cam.look = btVector3(0,2 + cube.pos.y,0)

  -- cam focal blur
  v.cam.focal_blur      = 0
  v.cam.focal_aperture  = 5
  -- set blur point to cube shape position
  v.cam.focal_point = cube.pos

end)

-- Called 25 times per second
v:postDraw(function(N)
--  print("postDraw("..tostring(N)..")")
end)

-- Called on command entered from the GUI
v:onCommand(function(N,cmd)
--  print(cmd)
  local f = assert(loadstring(cmd))
  f(v)
end)

-- Called before every simulation step
v:preSim(function(N)
--  print("preSim("..tostring(N)..")")
end)

-- Called after every simulation step
v:postSim(function(N)
--  print("postSim("..tostring(N)..")")

  if (N % 10 == 0 and N <= 1000) then
    run()
  end

end)