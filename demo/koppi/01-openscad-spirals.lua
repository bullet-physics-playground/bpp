--
-- Parametric OpenSCAD spirals
--
require "color"

v.gravity = btVector3(0,-980.1, 0)

p = Plane(0,1,0,0,100)
p.col = "#555555"
v:add(p)

function spiral(height, twist, fn, mass)
  return OpenSCAD([[
  linear_extrude(
    center = true,
    height = ]]..tostring(height)..[[, 
    convexity = 10,
    twist  = ]]..tostring(twist) ..[[,
    $fn    = ]]..tostring(fn)    ..[[)
  translate([1, 0, 0])
  circle(r = 1);
]], mass)
end

function spirals() 
  for i = 0,5 do
    s = spiral(10,100+i*500, 50, .1)
    s.pos = btVector3(-10+i*5,2,0)
    s.col = color.random_pastel()
    v:add(s)
  end
end

spirals()