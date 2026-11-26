--
-- SpotLight: a cone of light, at full strength within radius degrees of
-- its axis and gone by falloff; tightness makes it fall away inside.
--
-- A spot hangs from the ceiling and slowly sweeps across the floor; the
-- sliders change its cone. The view works POV-Ray's own formula, so the
-- pool looks as a render (F6) shows it, and the spot casts the shadows.
--
-- Centimetres, as LightSys's rooms (LIGHTS.md).
--
-- Usage: bpp -f demo/lights/02-spot-light.lua
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

-- something to light
local box = Cube(40, 60, 40, 0)
box.col = "#8a5a2e"
box.pos = btVector3(-50, 30, -20)
v:add(box)
local ball = Sphere(20, 0)
ball.col = "#3366aa"
ball.pos = btVector3(60, 20, 30)
v:add(ball)

local spot = SpotLight(btVector3(0, 240, 60), btVector3(0, 0, 0))
spot.col = "#fff2e0"
spot.power = 1.2
v:add(spot)

v:addParam("radius", 15, 0, 60, 1, "full strength within this angle of the axis (degrees)")
v:addParam("falloff", 30, 1, 90, 1, "no light beyond this angle (degrees)")
v:addParam("tightness", 0, 0, 50, 1, "how fast the light falls away from the axis, inside the cone too")

v:preDraw(function(N)
  spot.point_at = btVector3(80 * math.sin(N / 90), 0, 20)
  spot.radius = v:getParam("radius")
  spot.falloff = v:getParam("falloff")
  spot.tightness = v:getParam("tightness")
end)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(0, 190, 420)
v.cam.look = btVector3(0, 60, 0)
