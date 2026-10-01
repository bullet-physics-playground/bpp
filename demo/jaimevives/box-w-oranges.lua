--
-- A Box of Oranges
--

-- http://www.ignorancia.org/index.php?page=a-box-of-oranges
--

local common = require "common"

common.setTiming(1/5, 10, 1/20)

-- POV-Ray: the scene (lights, grass, crate, oranges) is set up in
-- includes/box-w-oranges-settings.inc, not in the generic settings.inc
v.pov_settings = "box-w-oranges-settings.inc"

-- ORANGES BOX 

plane = Plane(0,1,0,0,100)
plane.col = "green"
plane.tex = "grassy_bank_7160794.jpg" -- the grass of includes/grassy_bank.inc
v:add(plane)

-- BOX MADE OUT OF CUBES: the boards of the crate POV-Ray draws
-- (includes/cajon_POV_geom.inc, raised 9.05 by fruits_woodbox.inc)

-- invisible in POV-Ray
c_post = [[
  no_shadow
  no_reflection
  no_image
  no_radiosity
}
]]

col = "burlywood"
tex = "flat_wood_4022164.JPG" -- the wood of includes/fruits_woodbox.inc

-- a board from corner (x1,y1,z1) to (x2,y2,z2), in the crate's coordinates
function board(x1,y1,z1, x2,y2,z2)
  local c = Cube(x2-x1, y2-y1, z2-z1, 0)
  c.pos = btVector3((x1+x2)/2, (y1+y2)/2 + 9.05, (z1+z2)/2)
  c.col = col
  c.tex = tex
  c.post_sdl = c_post
  v:add(c)
end

-- three runners underneath, across the crate
for _, z in ipairs({ {-25.40,-23.22}, {-1.09,1.09}, {23.22,25.40} }) do
  board(-15.71,-9.03,z[1], 15.71,-8.06,z[2])
end

-- five slats along the bottom
for _, x in ipairs({ {-15.73,-11.41}, {-8.97,-4.65}, {-2.16,2.16}, {4.62,8.94}, {11.35,15.67} }) do
  board(x[1],-8.03,-25.65, x[2],-7.55,25.65)
end

-- four posts in the corners
for _, x in ipairs({ {-15.07,-13.11}, {13.01,14.97} }) do
  for _, z in ipairs({ {-24.96,-23.00}, {23.00,24.96} }) do
    board(x[1],-7.56,z[1], x[2],9.06,z[2])
  end
end

-- three rings of slats round the sides and ends
for _, y in ipairs({ {-7.50,-3.51}, {-1.99,1.99}, {3.51,7.50} }) do
  board(-15.71,y[1],-25.71, -15.04,y[2],25.71)
  board( 15.04,y[1],-25.71,  15.71,y[2],25.71)
  board(-15.04,y[1],-25.71,  15.04,y[2],-24.98)
  board(-15.04,y[1], 24.98,  15.04,y[2], 25.71)
end

-- A ROW OF ORANGES ALONG X
function oranges_row(N,H)
  for i = 0,N do
    scale = 3.5+math.random(0,10)*.05
    d     = Sphere(scale)
    d.pos = btVector3(-5+math.random(0,10),H,-15+30*i/N)    
    d.col = "Orange"
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

common.setCamera(btVector3(101, 71, 40), btVector3(0, 2, 2), .5,
                 { focal_blur = 5, focal_aperture = 1.33,
                   focal_point = btVector3(0,2,2) })
