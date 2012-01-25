io.write("Hello world, from ",_VERSION,"!\n")

-- io.write("Viewer: ",tostring(v),"!\n");

-- col = QColor(255, 0, 0)
-- print(col)

function balls(n)
  n = n or 10
  for i = 0, n do
    io.write("shpere ",tostring(i), "\n");
    s = Sphere(0.5, 100)
    s.pos = btVector3(-n / 2 + i, 0.5, 10)
    s.color = QColor(0,0,255)
    s.vel = btVector3(0, 0, -10)
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


function demo(n)
  n = n or 10
  tower(n)
  balls(n)
end

demo(10)