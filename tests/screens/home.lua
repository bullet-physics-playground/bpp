--
-- Screenshot scene for tests/harness.py screens: Home (the toolbar's house)
-- after a script set the camera. Viewer::parse notices the script moved
-- the camera and makes that view the one Home returns to. The harness
-- turns the wheel in the view, which moves the camera back (a drag would
-- do, but QGLViewer can leave the camera spinning after one), then clicks
-- Home: the picture is the script's view again.
--
-- xdotool: mousemove --window WIN 400 300 click --repeat 6 --delay 50 5
-- xdotool: mousemove --window WIN 422 40 click 1
--
v.gravity = btVector3(0, 0, 0)

local plane = Plane(0, 1, 0, 0, 20)
plane.col = "#9aa5b1"
v:add(plane)

local ball = Sphere(2, 0)
ball.col = "#1f77b4"
ball.pos = btVector3(0, 2, 0)
v:add(ball)

local box = Cube(2, 4, 2, 0)
box.col = "#d62728"
box.pos = btVector3(5, 2, -3)
v:add(box)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(-6, 7, 14)
v.cam.look = btVector3(1, 2, -1)
