plane = Plane(0,1,0)
plane.col = "#111111"
v:add(plane)

function chain(N,pos)

  velomax=4
  velox=math.random(-velomax*2,velomax*2)
  veloz=math.random(-velomax*2,velomax*2)

  for i = 1,N do
    if(i%2==0) then
    q = btQuaternion(0,0,1,1)
    else
    q = btQuaternion(1,1,1,1)
    end
    this_mass=1
--    if(i==N) then 
--      this_mass=0 
--    end
    o = btVector3(pos.x,pos.y+i*9.5,pos.z)
    d=Mesh3DS("demo/chain-link.3ds",this_mass)
    d.trans = btTransform(q,o)    
    d.col = "#ff0000"
    d.friction = .3
    d.restitution = .1
    d.vel=btVector3(velox*(1-i/N),0,veloz*(1-i/N))
    v:add(d)
  end
    
end

chain(40,btVector3(0,60,0))
