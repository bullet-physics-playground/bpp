--
-- CylinderLight: a round beam of parallel light, full strength within
-- radius (in units, not degrees) of its axis and gone by falloff.
--
-- A beam shines down from the ceiling onto a table; however far it goes,
-- its disc stays the same size, unlike a spot's. The sliders change its
-- width. Its marker shows the beam at its true width.
--
-- Centimetres, as LightSys's rooms (LIGHTS.md).
--
-- Usage: bpp -f demo/lights/03-cylinder-light.lua
--

v.glAmbient = 0.05          -- (dim: the scene's own light shows)
v.glModelAmbient = 0.05

-- the room
local floor = Cube(400, 2, 400, 0)
floor.col = "#d8d8d8"
floor.pos = btVector3(0, -1, 0)
v:add(floor)
local wall = Cube(400, 250, 2, 0)
wall.col = "#c8c8c8"
wall.pos = btVector3(0, 125, -150)
v:add(wall)

-- a table, half in the beam: the beam's disc on its top and on the floor
-- beside it is the same size
local top = Cube(100, 4, 60, 0)
top.col = "#9a6a3e"
top.pos = btVector3(30, 70, 0)
v:add(top)
for _, x in ipairs({-15, 75}) do
  for _, z in ipairs({-25, 25}) do
    local leg = Cube(5, 68, 5, 0)
    leg.col = "#6a4a2e"
    leg.pos = btVector3(x, 34, z)
    v:add(leg)
  end
end

local beam = CylinderLight(btVector3(-10, 260, 0), btVector3(-10, 0, 0))
beam.col = "#e0f0ff"
beam.power = 1.5
v:add(beam)

v:addParam("radius", 20, 0, 80, 1, "full strength within this distance of the axis (cm)")
v:addParam("falloff", 35, 1, 120, 1, "no light beyond this distance of the axis (cm)")

v:preDraw(function(N)
  beam.radius = v:getParam("radius")
  beam.falloff = v:getParam("falloff")
end)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(-20, 210, 280)
v.cam.look = btVector3(10, 40, 0)
