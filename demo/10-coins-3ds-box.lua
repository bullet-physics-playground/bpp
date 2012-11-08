plane = Plane(0,1,0)
plane.pos = btVector3(0, 0, 0)
plane.col = "#111111"
v:add(plane)

function coins_pile(num_obj,pos)
 for i=1,num_obj do
  c=Cylinder(7,7,1.1,1)
  q = btQuaternion(1,0,0,1)
  o = btVector3(pos.x,pos.y+i*2,pos.z)
  c.trans=btTransform(q,o)  
  c.col="#00ffff"
  c.friction=.5
  c.resitution=.1
  v:add(c)
 end
end

coins_pile(50,btVector3(0,2,0))
coins_pile(50,btVector3(14.5,2,0))
coins_pile(50,btVector3(0,2,14.5))
coins_pile(50,btVector3(-14.5,2,0))
coins_pile(50,btVector3(0,2,-14.5))

b=Mesh3DS("demo/box.3ds",0)
b.pos=btVector3(0,20.15,0)
b.col="#ff0000"
v:add(b)
