--
-- LUA math functions example.
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
plane.pos = btVector3(0, 0, 0)
plane.col = "#111111"

--
-- Circle of spheres.
--
function circle(d,r,N)
  for i = 1,N do
    x = math.sin(i / N * math.pi * 2) * r
    y = math.cos(i / N * math.pi * 2) * r

    s = Sphere(d, 1)
    s.pos = btVector3(x, d / 2 + 0.1,y)
    s.col = "#0000ff"
    v:add(s)
  end
end

circle(0.5,  0.0,  1)
circle(0.25, 0.7,  3)
circle(0.2,  1.2,  8)

v:add(plane)
