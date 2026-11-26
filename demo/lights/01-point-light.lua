--
-- PointLight: light shining all round from one point.
--
-- A warm lamp circles the room. It fades with distance (fade_distance,
-- fade_power), as POV-Ray's lights do; drag the sliders to change how far
-- it reaches. The cross is its marker (View > Show Lights). F6 renders the
-- frame with POV-Ray: the same light, written into each exported frame, so
-- it moves in an animation too.
--
-- Centimetres, as LightSys's rooms (LIGHTS.md).
--
-- Usage: bpp -f demo/lights/01-point-light.lua
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
for i, x in ipairs({-90, 0, 90}) do
  local column = Cube(30, 40 + 30 * i, 30, 0)
  column.col = "#8a5a2e"
  column.pos = btVector3(x, (40 + 30 * i) / 2, -40)
  v:add(column)
end
local ball = Sphere(25, 0)
ball.col = "#3366aa"
ball.pos = btVector3(0, 25, 60)
v:add(ball)

local lamp = PointLight(btVector3(0, 120, 0))
lamp.col = "#ffcc88"
lamp.power = 1.5
lamp.fade_power = 2
v:add(lamp)

v:addParam("fade_distance", 80, 10, 300, 5, "how far the lamp reaches (cm): full strength at about this distance, then falling away")
v:addParam("power", 1.5, 0.1, 4, 0.1, "the lamp's brightness")

v:preDraw(function(N)
  local a = N / 60
  lamp.pos = btVector3(120 * math.cos(a), 110, 120 * math.sin(a))
  lamp.fade_distance = v:getParam("fade_distance")
  lamp.power = v:getParam("power")
end)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(0, 220, 420)
v.cam.look = btVector3(0, 50, 0)
