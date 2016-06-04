--
-- Mesh cain demo
--

v.timeStep      = 1/4
v.maxSubSteps   = 20
v.fixedTimeStep = 1/100

plane = Plane(0,1,0,0,1000)
plane.col = "#111111"
v:add(plane)

function chain(N,xp,yp,zp)
  velomax=10
  veloz=-velomax+math.random(1,velomax*2)

  for i = 1,N do
    if (i%2==0) then
      q = btQuaternion(1,0,0,1)
    else
      q = btQuaternion(1,0,0,0)
    end
    this_mass=1
    if (i==1 or i==N) then 
      this_mass=0
    end
    o = btVector3(xp-N*5+i*9,yp,zp)
    d=Mesh("demo/mesh/chain-link.3ds",this_mass)
    d.trans = btTransform(q,o)    
    d.col = "#ff0000"
    d.friction = .3
    d.restitution = .1
    if (i==math.floor(N/2)) then
      d.vel=btVector3(0,0,veloz*(1-i/N))
    end
    v:add(d)
  end
    
end

chain(17, 0,40, 0)

-- pseudo orthogonal
v.cam:setFieldOfView(0.1)

-- rotate camera
v.cam.up   = btVector3(0,1,0)
v.cam.pos = btVector3(0,500,1500)
v.cam.look = btVector3(0,25,0)
