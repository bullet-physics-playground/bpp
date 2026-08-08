--
-- Mesh cain demo
--

local common = require "common"

common.setTiming(1/5, 100, 1/50)

plane = Plane(0,1,0,0,100)
plane.friction = 10
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
    d=Mesh("demo/mesh/chain-link.3ds", this_mass, false)
    d.trans = btTransform(q,o)    
    d.col = "#ff0000"
    d.friction = 1
    d.restitution = .5
    d.vel=btVector3(velox*(1-i/N),0,veloz*(1-i/N))
    v:add(d)
  end
    
end

chain(40,btVector3(0,60,0))

common.setCamera(btVector3(1.38623, 375.857, 2638.52),
                 btVector3(163.488, -136713, -987920), nil,
                 { up = btVector3(-0.0076577, 0.99053, -0.137086) })
