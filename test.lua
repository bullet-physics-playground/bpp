io.write("Hello world, from ",_VERSION,"!\n")

-- io.write("Viewer: ",tostring(v),"!\n");

function balls(n)
  n = n or 10
  for i = 0, n do
    io.write("shpere ",tostring(i), "\n");
    s = Sphere(0.5)
    s.pos = btVector3(1, 0.5, 10 + i)
    s.color = QColor(0,0,255)
    s.vel = btVector3(10, 0, 0)
    v:add(s)
  end
end

function tower(n)
  n = n or 10
  for i = 0, n do
    io.write("cube ",tostring(i),"\n");
    c = Cube(btVector3(1, 1, 1))
    c.pos = btVector3(0, 0.5 + i, 0)
    c.color = QColor(255, 0, 0)
    v:add(c)
  end
end

tower(10)
balls(10)
