--
-- tests/screens/lights.lua with shadows off: a copy, as a script opened in
-- the GUI can't load the file next to it. A script's v.shadows doesn't
-- override View > Shadows (the user's setting, on here), so the scene
-- unticks it: View, then Shadows, its third item. (Clicked: with no window
-- manager the window has no focus, and keys sent to it are ignored.)
--
-- xdotool: mousemove --window WIN 100 10 click 1
-- xdotool: sleep 0.7
-- xdotool: mousemove --window WIN 125 84 click 1
-- xdotool: sleep 0.5
-- xdotool: mousemove --window WIN 1200 760
--
-- Screenshot scene for tests/harness.py screens: the script's own lights in
-- the view (LIGHTS.md, step 3), one of each kind the view shows: a warm
-- point light that fades, a LightSys spot (lumens) throwing a pool on the
-- floor, and a dim blue parallel light. The box's shadow is the spot's (the
-- strongest at the camera that isn't shadowless). Centimetres, as the
-- LightSys rooms. Nothing moves.
--
-- tests/screens/lights-noshadow.lua is a copy with shadows off (keep the
-- two the same otherwise): outside the box's shadow they must look the
-- same, as the shadow map's shader lights as the fixed-function pipeline.
--

v.gravity = btVector3(0, 0, 0)
v.shadows = true
v.glAmbient = 0.03                -- (low: the pools show)
v.glModelAmbient = 0.03

local floor = Cube(400, 2, 400, 0)
floor.col = "#d8d8d8"
floor.pos = btVector3(0, -1, 0)
v:add(floor)

local wall = Cube(400, 250, 2, 0)
wall.col = "#c8c8c8"
wall.pos = btVector3(0, 125, -150)
v:add(wall)

local box = Cube(40, 60, 40, 0)
box.col = "#8a5a2e"
box.pos = btVector3(-20, 30, -20)
v:add(box)

local ball = Sphere(20, 0)
ball.col = "#3366aa"
ball.pos = btVector3(80, 20, 20)
v:add(ball)

local lamp = PointLight(btVector3(110, 80, -60))
lamp.col = "#ffcc88"
lamp.power = 1.5
lamp.fade_distance = 60
lamp.fade_power = 2
v:add(lamp)

local spot = SpotLight(btVector3(-40, 240, 40), btVector3(-40, 0, 20))
spot.col = "#fff2e0"
spot.lumens = 1000
spot.radius, spot.falloff, spot.tightness = 15, 30, 0
v:add(spot)

local sky = ParallelLight(btVector3(-300, 400, 300), btVector3(0, 0, 0))
sky.col = "#4060a0"
sky.power = 0.3
v:add(sky)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(0, 190, 420)
v.cam.look = btVector3(0, 60, 0)
