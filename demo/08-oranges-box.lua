-- ORANGES BOX 

plane = Plane(0,1,0)
plane.col = "#111111"
v:add(plane)

-- BOX MADE OUT OF CUBES
c1 = Cube(1,15,50,0)
c1.pos = btVector3(-15.5,7.5,0)
c1.col = "#00ff00"
v:add(c1)
c2 = Cube(1,15,50,0)
c2.pos = btVector3(15.5,7.5,0)
c2.co2 = "#00ff00"
v:add(c2)
c3 = Cube(30,15,1,0)
c3.pos = btVector3(0,7.5,25.5)
c3.col = "#00ff00"
v:add(c3)
c4 = Cube(30,15,1,0)
c4.pos = btVector3(0,7.5,-25.5)
c4.col = "#00ff00"
v:add(c4)

-- A ROW OF ORANGES ALONG X
function oranges_row(N,H)

  for i = 0,N do
    d = Sphere(3.5+math.random(0,10)*.05)
    d.pos = btVector3(-5+math.random(0,10),H,-15+30*i/N)    
    d.col = "#ff0000"
    d.friction = 4;
    v:add(d)
  end
end

-- LETS FALL SOME ORANGES INTO THE BOX
oranges_row(4,5)
oranges_row(4,15)
oranges_row(4,25)
oranges_row(4,35)
oranges_row(4,45)
oranges_row(4,55)
oranges_row(4,65)
oranges_row(4,75)
oranges_row(4,85)
oranges_row(4,95)
