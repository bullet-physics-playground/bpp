--
-- Lua math functions demo
--
-- see: http://lua-users.org/wiki/MathLibraryTutorial
--
-- math.abs   math.acos  math.asin  math.atan math.atan2 math.ceil
-- math.cos   math.cosh  math.deg   math.exp  math.floor math.fmod
-- math.frexp math.huge  math.ldexp math.log  math.log10 math.max
-- math.min   math.modf  math.pi    math.pow  math.rad   math.random
-- math.randomseed       math.sin   math.sinh math.sqrt  math.tanh
-- math.tan

plane = Plane(0,1,0)
plane.col = "white"
v:add(plane)

--
-- Circle of spheres.
--
function circle(d,r,N)
  for i = 1,N do
    x = math.sin(i / N * math.pi * 2) * r
    y = math.cos(i / N * math.pi * 2) * r

    s = Sphere(d, 1/d)
    s.pos = btVector3(x, d / 2 + 0.1,y)
    s.col = "blue"
    v:add(s)
  end
end

circle(0.5,  0.0,  1)
circle(0.25, 0.7,  5)
circle(0.2,  1.2,  8)
