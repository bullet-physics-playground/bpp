--
-- Screenshot scene for tests/harness.py screens: the Params pane
-- (v:addParam, v:showParams, v:onParamChanged). One parameter of each kind
-- -- a slider, a text cell, a check box, a push button and a row of
-- buttons -- and one that showParams("ui_") hides. Then the harness works
-- the pane as a user would:
--
--   the push button   turns the ball red
--   the slider        dragged right, onParamChanged moves the box right
--   the check box     unticked, onParamChanged turns the box blue
--
-- xdotool: mousemove --window WIN 1212 582 click 1
-- xdotool: mousemove --window WIN 1160 645 mousedown 1
-- xdotool: mousemove --window WIN 1195 645
-- xdotool: mousemove --window WIN 1230 645 mouseup 1
-- xdotool: mousemove --window WIN 1194 546 click 1
--
v.gravity = btVector3(0, 0, 0)

local plane = Plane(0, 1, 0, 0, 20)
plane.col = "#9aa5b1"
v:add(plane)

local ball = Sphere(2, 0)
ball.col = "#7f7f7f"
ball.pos = btVector3(-4, 2, 0)
v:add(ball)

local box = Cube(2, 2, 2, 0)
box.col = "#7f7f7f"
box.pos = btVector3(2, 1, 0)
v:add(box)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(0, 6, 16)
v.cam.look = btVector3(0, 2, 0)

v:onParamChanged(function(N, name, value)
  if name == "ui_speed" then
    box.pos = btVector3(2 + value * 6, 1, 0)
  elseif name == "ui_enabled" and value == false then
    box.col = "#1f77b4"
  end
end)

v:addParam("ui_speed", 0.25, 0, 1, 0.05, "a slider")
v:addParam("ui_title", "hello", "a text cell")
v:addParam("ui_enabled", true, "a check box")
v:addParam("ui_paint", function() ball.col = "#d62728" end, "a push button")
v:addParam("ui_row", { a = function() end, b = function() end }, "a row of buttons")
v:addParam("hidden", 3, "not shown: showParams below shows ui_ only")
v:showParams("ui_")
