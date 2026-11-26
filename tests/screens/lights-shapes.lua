--
-- Screenshot scene for tests/harness.py screens: the rest of the lights in
-- the view (LIGHTS.md, step 4), with their markers (v.showLights):
--
-- - a cylinder light throwing a round, soft-edged beam on the floor;
-- - a round area lamp whose looks_like is a glowing bulb (no shadow of its
--   own, written inside the light in the export);
-- - a shadowless spot, which as in POV-Ray lights all round, as a point
--   light, and makes no highlight (shadowless, written last, replaces
--   spotlight);
-- - a spot that is an area light too, casting the shadow.
--
-- Centimetres, as the LightSys rooms. Nothing moves.
--

v.gravity = btVector3(0, 0, 0)
v.shadows = true
v.glAmbient = 0.03
v.glModelAmbient = 0.03

local floor = Cube(400, 2, 400, 0)
floor.col = "#d8d8d8"
floor.pos = btVector3(0, -1, 0)
v:add(floor)

local wall = Cube(400, 250, 2, 0)
wall.col = "#c8c8c8"
wall.pos = btVector3(0, 125, -150)
v:add(wall)

local post = Cylinder(8, 120, 0)
post.col = "#555555"
post.trans = btTransform(btQuaternion(btVector3(1, 0, 0), -math.pi / 2), btVector3(-60, 60, -40))
v:add(post)

local ball = Sphere(20, 0)
ball.col = "#3366aa"
ball.pos = btVector3(70, 20, 30)
v:add(ball)

local beam = CylinderLight(btVector3(-110, 260, 60), btVector3(-110, 0, 60))
beam.col = "#e0f0ff"
beam.power = 0.9
beam.radius, beam.falloff, beam.tightness = 20, 35, 0
v:add(beam)

local bulb = Sphere(6, 0)
bulb.col = "#fff0c0"
bulb.emission = "#fff0c0"
bulb.pos = btVector3(110, 110, -80)
v:add(bulb)

local lamp = AreaLight(btVector3(110, 110, -80))
lamp.col = "#ffd8a0"
lamp.power = 1.4
lamp.fade_distance, lamp.fade_power = 70, 2
lamp.axis1, lamp.axis2 = btVector3(12, 0, 0), btVector3(0, 0, 12)
lamp.circular, lamp.orient = true, true
lamp.looks_like = bulb
v:add(lamp)

local fill = SpotLight(btVector3(0, 200, 250), btVector3(0, 0, 0))
fill.col = "#6080c0"
fill.power = 0.25
fill.shadowless = true
v:add(fill)

local key = SpotLight(btVector3(40, 230, 120), btVector3(20, 0, 20))
key.col = "#fff6e8"
key.power = 1.1
key.radius, key.falloff, key.tightness = 18, 28, 0
key.axis1, key.axis2, key.n1, key.n2 = btVector3(20, 0, 0), btVector3(0, 0, 20), 3, 3
key.adaptive, key.jitter = 1, true
v:add(key)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(0, 190, 420)
v.cam.look = btVector3(0, 60, 0)
