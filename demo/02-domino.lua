plane = Plane(0,1,0)
plane.col = "#111111"
v:add(plane)

function line(N,zpos,damp_lin,damp_ang,fri,res)
  s = Sphere(1.2,1)
  s.pos = btVector3(-10, 1, zpos)
  s.col = "#0000ff"
  s.vel = btVector3(5,0,0)
  v:add(s)

  for i = 0,N do
    d = Cube(0.4,3,1.5, 1)
    d.pos = btVector3(i*2, 1.5, zpos)
    d.col = "#ff0000"

    d.friction = fri
    d.restitution = res

    d.damp_lin = damp_lin
    d.damp_ang = damp_ang

    v:add(d)
  end
end

line(5, -3, 0.01, 0.01, 0.4, 0.1)
line(5,  0, 0.1,  0.1,  0.3, 0.0)
line(5,  3, 0.1,  0.1,  0.3, 0.5)
