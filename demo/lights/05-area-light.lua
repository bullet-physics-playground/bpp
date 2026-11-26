--
-- AreaLight: a light spread over an area (axis1 by axis2, n1 by n2 lights
-- across it), so its shadows are soft. Any kind can be an area light: set
-- axis1, axis2, n1 and n2 on a SpotLight too (LIGHTS.md).
--
-- A round lamp hangs over a ball and a box. The view shows it as a
-- point at its middle, with hard shadows; press F6 to see the soft
-- shadows POV-Ray gives it, wider as the lamp gets bigger. The bulb is
-- its looks_like: drawn here, written inside the light in the export, and
-- casting no shadow of its own.
--
-- Centimetres, as LightSys's rooms (LIGHTS.md).
--
-- Usage: bpp -f demo/lights/05-area-light.lua
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
box.pos = btVector3(-60, 30, 0)
v:add(box)
local ball = Sphere(25, 0)
ball.col = "#3366aa"
ball.pos = btVector3(50, 25, 20)
v:add(ball)

-- the lamp's bulb, where the light is
local bulb = Sphere(8, 0)
bulb.col = "#ffcc66"
bulb.emission = "#ffcc66"
bulb.pos = btVector3(0, 150, 40)
v:add(bulb)

local lamp = AreaLight(btVector3(0, 150, 40))
lamp.col = "#ffe0b0"
lamp.power = 1.6
lamp.fade_distance, lamp.fade_power = 120, 2
lamp.circular, lamp.orient = true, true
lamp.looks_like = bulb
v:add(lamp)

v:addParam("size", 30, 2, 120, 2, "the lamp's width (cm): the wider, the softer POV-Ray's shadows")
v:addParam("lights", 5, 2, 9, 1, "lights across the lamp, each way (more: smoother soft shadows, slower renders)")

v:preDraw(function(N)
  local s, n = v:getParam("size"), math.floor(v:getParam("lights"))
  lamp.axis1 = btVector3(s, 0, 0)
  lamp.axis2 = btVector3(0, 0, s)
  lamp.n1, lamp.n2 = n, n
end)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(0, 190, 420)
v.cam.look = btVector3(0, 60, 0)
