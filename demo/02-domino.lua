--
-- Domino for Jaime - 20120828 - Koppi
--

plane = Plane(0,1,0)
plane.pos = btVector3(0, 0, 0)
plane.col = "#111111"

sphere = Sphere(0.75,10)
sphere.pos = btVector3(-10, 1, 0)
sphere.col = "#0000ff"
sphere.vel = btVector3(10,0,0)

function domino_line(N)
  for i = 0,N do
    domino = Cube(0.2,3,1.5, 1)
    domino.pos = btVector3(-N/2 + i*2,1.5,0)
    domino.col = "#ff0000"
    v:add(domino)
  end
end

v:add(plane)
v:add(sphere)

domino_line(5)

-- EOF