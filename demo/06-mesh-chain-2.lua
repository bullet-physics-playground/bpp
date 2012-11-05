plane = Plane(0,1,0)
plane.pos = btVector3(0, 0, 0)
plane.col = "#111111"
v:add(plane)

function chain(N,xp,yp,zp)

  velomax=10
  veloz=-velomax+math.random(1,velomax*2)

  for i = 1,N do
    if(i%2==0) then
    q = btQuaternion(1,0,0,1)
    else
    q = btQuaternion(1,0,0,0)
    end
    this_mass=1
    if(i==1 or i==N) then 
      this_mass=0
    end
    o = btVector3(xp-N*4.5+i*9,yp,zp)
    d=Mesh3DS("demo/chain-link.3ds",this_mass)
    d.trans = btTransform(q,o)    
    d.col = "#ff0000"
    d.friction = .3
    d.restitution = .1
    if(i==math.floor(N/2)) then
    d.vel=btVector3(0,0,veloz*(1-i/N))
    end
    v:add(d)
  end
    
end

chain(30,  0,80,0)

