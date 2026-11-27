--
-- Screenshot scene for tests/harness.py screens: v.shadowLight, the
-- script's choice of the light casting the shadow in the view. A bright
-- sun from the left would cast it on its own (the strongest at the
-- camera); the script picks the dim lamp on the right instead, so the
-- box's shadow falls to the left, away from the lamp. Nothing moves.
--

v.gravity = btVector3(0, 0, 0)
v.shadows = true
v.glAmbient = 0.03
v.glModelAmbient = 0.03

local floor = Cube(400, 2, 400, 0)
floor.col = "#d8d8d8"
floor.pos = btVector3(0, -1, 0)
v:add(floor)

local box = Cube(40, 60, 40, 0)
box.col = "#8a5a2e"
box.pos = btVector3(0, 30, 0)
v:add(box)

local sun = ParallelLight(btVector3(-400, 300, 0), btVector3(0, 0, 0))
sun.col = "#fff0d8"
sun.power = 0.8
v:add(sun)

local lamp = PointLight(btVector3(90, 90, 20))
lamp.col = "#ffc080"
lamp.power = 0.6
v:add(lamp)

v.shadowLight = lamp

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(0, 200, 330)
v.cam.look = btVector3(0, 30, 0)
