--
-- Stack of Coins demo
--
-- postSim used to insert coins on-the-fly
--

v.timeStep      = 1/5
v.maxSubSteps   = 100
v.fixedTimeStep = 1/50

plane = Plane(0,1,0,0,1000)
plane.col = "#111111"
v:add(plane)

b=Mesh("demo/mesh/box.3ds",0)
b.pos=btVector3(0,20.15,0)
b.col="#ff0000"
v:add(b)

v:postSim(function(N)
  if (N%5==0 and N < 500) then
    c=Cylinder(7,1.1,1)
    q = btQuaternion(1,0,0,1)
    o = btVector3(math.random(-2,2),150,math.random(-2,2))
    c.trans=btTransform(q,o)  
    c.col="#00ffff"
    c.friction=.5
    c.resitution=.1
    v:add(c)
  end
end)
