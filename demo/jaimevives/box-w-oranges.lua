--
-- A Box of Oranges
--

-- ignorancia.org/en/index.php?page=a-box-of-oranges
--

v.timeStep      = 1/5
v.maxSubSteps   = 10
v.fixedTimeStep = 1/20

-- ORANGES BOX 

plane = Plane(0,1,0,0,100)
plane.col = "#00b000"
v:add(plane)

-- BOX MADE OUT OF CUBES

-- invisible in POV-Ray
c_post = [[
  no_shadow
  no_reflection
  no_image
  no_radiosity
}
]]

c1     = Cube(1,17,50,0)
c1.pos = btVector3(-15.5,7.5,0)
c1.col = "#f0ff00"
c1.post_sdl = c_post
v:add(c1)

c2     = Cube(1,17,50,0)
c2.pos = btVector3(15.5,7.5,0)
c2.col = "#f0ff00"
c2.post_sdl = c_post
v:add(c2)

c3     = Cube(30,17,1,0)
c3.pos = btVector3(0,7.5,25.5)
c3.col = "#f0ff00"
c3.post_sdl = c_post
v:add(c3)

c4     = Cube(30,17,1,0)
c4.pos = btVector3(0,7.5,-25.5)
c4.col = "#f0ff00"
c4.post_sdl = c_post
v:add(c4)

c5     = Cube(30,2,50,0)
c5.pos = btVector3(0,0,0)
c5.col = "#f0ff00"
c5.post_sdl = c_post
v:add(c5)

-- A ROW OF ORANGES ALONG X
function oranges_row(N,H)
  for i = 0,N do
    scale = 3.5+math.random(0,10)*.05
    d     = Sphere(scale)
    d.pos = btVector3(-5+math.random(0,10),H,-15+30*i/N)    
    d.col = "#f05000"
    d.friction = 4;
    d.pre_sdl = "object{orange scale " .. tostring(scale)
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
