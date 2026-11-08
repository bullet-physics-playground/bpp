--
-- Screenshot scene for tests/harness.py screens: decorations (o.decoration,
-- v:attach). A block (mass 0, moved by the script) carries a box and a
-- cylinder that are decorations, the cylinder following the box (a
-- decoration following a decoration). The block slides along, then rests
-- until all four boxes and cylinders are merged into the screen's batches
-- and the shadows of the fixed objects are recorded; then it slides to a
-- new place and rests there. The decorations, and their shadows, must be
-- drawn on the block at its new place, not left where they were merged and
-- recorded. A ball rolls along the front until all that is done, so the
-- picture only settles afterwards; the frame and the counts are printed for
-- the log.
--

v.gravity = btVector3(0, 0, 0)
v.shadows = true

local plane = Plane(0, 1, 0, 0, 20)
plane.col = "#9aa5b1"
v:add(plane)

local block = Cube(1.6, 0.6, 1.6, 0)
block.col = "#1f77b4"
block.pos = btVector3(-3, 0.3, 0)
v:add(block)

local hat = Cube(0.8, 0.8, 0.8, 0)
hat.decoration = true
hat.col = "#d62728"
hat.pos = btVector3(-3, 1, 0)
v:add(hat)
v:attach(hat, block)

local post = Cylinder(0.15, 1.2, 0)
post.decoration = true
post.col = "#ff7f0e"
post.trans = btTransform(btQuaternion(btVector3(1, 0, 0), math.pi / 2), btVector3(-3, 2, 0))
v:add(post)
v:attach(post, hat)

-- a decoration on its own, never moving
local marker = Cube(0.4, 0.4, 0.4, 0)
marker.decoration = true
marker.col = "#2ca02c"
marker.pos = btVector3(3, 0.2, -2)
v:add(marker)

local ball = Sphere(0.3, 0)
ball.col = "#ffffff"
ball.pos = btVector3(-4, 0.3, 2.5)
v:add(ball)

local phase, at = "sliding", 0
v:postDraw(function(N)
  if phase ~= "done" then
    ball.pos = btVector3(-4 + (N % 100) * 0.08, 0.3, 2.5)
  end
  if phase == "sliding" then
    block.pos = btVector3(-3 + math.min(N, 60) * 0.04, 0.3, 0)   -- to x = -0.6
    if N > 60 then phase = "resting" end
  elseif phase == "resting" then
    if v.screenMerged >= 4 and v.shadowCached >= 4 then
      print("merged " .. v.screenMerged .. ", shadows recorded " .. v.shadowCached .. " at frame " .. N)
      phase, at = "moving", N
    end
  elseif phase == "moving" then
    local k = math.min(N - at, 40)
    block.pos = btVector3(-0.6 + k * 0.06, 0.3, -k * 0.03)        -- to (1.8, 0.3, -1.2)
    if N > at + 70 then
      print("after the move: " .. v.screenMerged .. " merged, " .. v.shadowCached .. " recorded at frame " .. N)
      ball.pos = btVector3(4, 0.3, 2.5)
      phase = "done"
    end
  end
end)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(0, 7, 9)
v.cam.look = btVector3(0, 0.5, 0)
