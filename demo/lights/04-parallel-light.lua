--
-- ParallelLight: light from one direction everywhere, as the sun's: from
-- pos toward point_at, however far either is.
--
-- A low sun over a row of posts; the slider moves it across the sky, and
-- the shadows all keep the same direction as each other. With no fade_*
-- set it is as bright everywhere.
--
-- Centimetres, as LightSys's rooms (LIGHTS.md).
--
-- Usage: bpp -f demo/lights/04-parallel-light.lua
--

v.glAmbient = 0.08          -- (dim: the scene's own light shows)
v.glModelAmbient = 0.08

local ground = Cube(600, 2, 600, 0)
ground.col = "#c8c0a8"
ground.pos = btVector3(0, -1, 0)
v:add(ground)

for i = -3, 3 do
  local post = Cube(10, 80, 10, 0)
  post.col = "#5a4a3a"
  post.pos = btVector3(i * 60, 40, -40)
  v:add(post)
end
local ball = Sphere(25, 0)
ball.col = "#aa3333"
ball.pos = btVector3(0, 25, 80)
v:add(ball)

local sun = ParallelLight(btVector3(0, 300, 300), btVector3(0, 0, 0))
sun.col = "#fff0d8"
v:add(sun)

v:addParam("sun_angle", 30, -80, 80, 1, "where the sun is, from left to right (degrees)")
v:addParam("sun_height", 35, 5, 90, 1, "how high the sun is (degrees above the horizon)")

v:preDraw(function(N)
  local a, h = math.rad(v:getParam("sun_angle")), math.rad(v:getParam("sun_height"))
  sun.pos = btVector3(300 * math.sin(a) * math.cos(h), 300 * math.sin(h), 300 * math.cos(a) * math.cos(h))
end)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(0, 220, 450)
v.cam.look = btVector3(0, 30, 0)
