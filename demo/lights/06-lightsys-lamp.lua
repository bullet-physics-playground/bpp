--
-- A LightSys lamp: a light given in lumens, with a lamp's own colour, as
-- the LightSys IV rooms are lit (includes/bpp_lightsys.inc, by Jaime Vives
-- Piqueres). Any kind of light can be one: set lumens (above 0) and,
-- for the render, lightsys -- a LightSys colour, written into the export
-- as it is. POV-Ray then gets LightSys's Light_Color() and Light_Fading():
-- the lamp falls off with the square of the distance, as a real one.
--
-- The view can't read a LightSys colour, so it takes the lamp's hue from
-- col; pick one close to it. LightSys's own settings for the whole scene
-- (Lightsys_Brightness and the like) go in v.pre_sdl.
--
-- Two desk lamps, a warm incandescent one and a cool fluorescent one; the
-- sliders set their lumens. Centimetres, as LightSys's rooms (LIGHTS.md).
--
-- Usage: bpp -f demo/lights/06-lightsys-lamp.lua
--

v.glAmbient = 0.05          -- (dim: the scene's own light shows)
v.glModelAmbient = 0.05

-- (the whole scene's LightSys brightness, for the render)
v.pre_sdl = "#declare Lightsys_Brightness = 1.0;\n"

-- the room
local floor = Cube(400, 2, 400, 0)
floor.col = "#d8d8d8"
floor.pos = btVector3(0, -1, 0)
v:add(floor)
local wall = Cube(400, 250, 2, 0)
wall.col = "#c8c8c8"
wall.pos = btVector3(0, 125, -150)
v:add(wall)
local desk = Cube(260, 4, 80, 0)
desk.col = "#9a6a3e"
desk.pos = btVector3(0, 72, -80)
v:add(desk)

local lamps = {}
for i, l in ipairs({
  { x = -70, col = "#ffc890", lightsys = "Cl_Incandescent_60w", lumens = 600 },
  { x = 70, col = "#e8f0ff", lightsys = "Cl_Cool_White_Fluor", lumens = 900 },
}) do
  local shade = Cone(18, 20, 0)
  shade.col = "#404040"
  shade.trans = btTransform(btQuaternion(btVector3(1, 0, 0), math.pi / 2), btVector3(l.x, 130, -90))
  v:add(shade)
  local lamp = SpotLight(btVector3(l.x, 118, -90), btVector3(l.x, 0, -90))
  lamp.col = l.col
  lamp.lightsys = l.lightsys
  lamp.lumens = l.lumens
  lamp.radius, lamp.falloff, lamp.tightness = 40, 70, 2
  v:add(lamp)
  lamps[i] = lamp
end

v:addParam("incandescent_lumens", 600, 50, 2000, 50, "the warm lamp's light (lumens: a 60 W bulb gives about 700)")
v:addParam("fluorescent_lumens", 900, 50, 2000, 50, "the cool lamp's light (lumens)")

v:preDraw(function(N)
  lamps[1].lumens = v:getParam("incandescent_lumens")
  lamps[2].lumens = v:getParam("fluorescent_lumens")
end)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(0, 180, 300)
v.cam.look = btVector3(0, 80, -60)
