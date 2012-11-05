--
-- COINS PILES DEMO 1 - JVP
--

plane = Plane(0,1,0)
plane.pos = btVector3(0, 0, 0)
plane.col = "#111111"
plane.friction=.7

v:add(plane)

function coins_pile(coin_width,coin_height,N,xp,zp)

  for i = 0,N do
    q = btQuaternion(1,0,0,1)
    o = btVector3(xp-.5+math.random(0,10)*.1,.6+i*coin_height,zp-.5+math.random(0,10)*.1) 
    d = Cylinder(coin_width,coin_width,coin_height,1)
    d.mass=coin_width*coin_height*.1
    d.col = "#00ff00"
    d.trans=btTransform(q,o)
    d.friction=.4
    d.restitution=.1
    v:add(d)
  end
end

coins_pile(6.0,1.0,45,0,15)
coins_pile(5.0,0.9,41,0,-15)
coins_pile(7.0,1.1,43,15,0)
coins_pile(4.0,0.8,48,-15,0)
coins_pile(3.5,.75,46,0,0)
coins_pile(6.0,1.0,45,15,15)
coins_pile(5.0,0.9,41,15,-15)
coins_pile(7.0,1.1,43,-15,15)
coins_pile(4.0,0.8,48,-15,-15)

-- EOF