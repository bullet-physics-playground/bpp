--
-- Parametric Involute Bevel and Spur Gears
--
-- http://www.thingiverse.com/thing:3575

require "koppi/gearsv50"
require "color"

v.gravity = btVector3(0,-980.1, 0)

plane = Plane(0,1,0,0,10000)
plane.col = "#555555"
v:add(plane)

function gear1(pitch, mass)
  g = gearsv50.new({fun=[[
  gear(
    circular_pitch=]]..tostring(pitch)..[[,
    gear_thickness = 12,
    rim_thickness = 15,
    hub_thickness = 17,
    circles=8
);]], mass = mass})
  return g
end

function gears1() 
  for i = 0,20 do
    g = gear1(500+i*100, 1)
    g.pos = btVector3(0,12,0)
    g.col = color.random_pastel()
    v:add(g)
  end
end

gears1()

function gear2(pitch, teeth, mass)
  g = gearsv50.new({fun=[[
  gear(
    circular_pitch=]]..tostring(pitch)..[[,
    number_of_teeth=]]..tostring(teeth)..[[,
    hub_diameter=0,
rim_width=65
);]], mass = mass})
  return g
end

function gears2() 
  for i = 0,20 do
    g = gear2(500, 6+i*2, 1)
    g.pos = btVector3(0,12,0)
    g.col = color.random_pastel()
    v:add(g)
  end
end

--gears2()