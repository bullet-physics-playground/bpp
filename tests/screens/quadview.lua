--
-- Screenshot scene for tests/harness.py screens: the quad view (Tab). The
-- harness runs the xdotool lines below: a click in the view (no drag, so
-- the camera stays) gives it the keyboard, Tab splits it into four panes,
-- eight wheel clicks zoom the front pane (bottom left) in, and a drag pans
-- the top pane (top right). The right pane (bottom right) is left as it
-- was framed, to compare with.
--
-- xdotool: mousemove --window WIN 500 400 click 1
-- xdotool: key Tab
-- xdotool: mousemove --window WIN 255 525 click --repeat 8 --delay 50 4
-- xdotool: mousemove --window WIN 765 215 mousedown 1
-- xdotool: mousemove --window WIN 715 240
-- xdotool: mousemove --window WIN 665 265 mouseup 1
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
v.cam.pos = btVector3(10, 8, 14)
v.cam.look = btVector3(1, 1, -1)
