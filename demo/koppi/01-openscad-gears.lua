--
-- OpenSCAD experiments
--

require "koppi/gearsv50"

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

g = gear1(700, 1)
g.pos = btVector3(0,12,0)
--v:add(g)

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
  for i = 0,2 do
    g = gear2(500, 6+i*2, 1)
    g.pos = btVector3(0,12,0)
    v:add(g)
  end
end

gears2()