--
-- Screenshot scene for tests/harness.py screens: the screen's merge
-- (v.screenMerge). Still boxes and cylinders are merged into batches after
-- some 300 frames; then one box is moved (it leaves its batch, its
-- triangles blanked there), one is recoloured (its colour changed in its
-- batch) and one is removed. A ball rolls along the front until all that
-- is done, so the picture only settles afterwards; the frame and the merge
-- counts are printed for the log.
--

v.gravity = btVector3(0, 0, 0)

local plane = Plane(0, 1, 0, 0, 20)
plane.col = "#9aa5b1"
v:add(plane)

local palette = { "#d62728", "#2ca02c", "#1f77b4", "#ff7f0e", "#9467bd", "#8c564b" }
local objs = {}
for i = 0, 11 do
  local x, z = (i % 6) * 1.6 - 4, math.floor(i / 6) * 1.8 - 1.5
  local o
  if i % 2 == 0 then
    o = Cube(1, 1, 1, 0)
  else
    o = Cylinder(0.5, 1, 0)
  end
  o.col = palette[i % 6 + 1]
  o.pos = btVector3(x, 0.5, z)
  v:add(o)
  objs[#objs + 1] = o
end

local ball = Sphere(0.3, 0)
ball.col = "#ffffff"
ball.pos = btVector3(-4, 0.3, 2)
v:add(ball)

local phase, at = "merging", 0
v:postDraw(function(N)
  if phase == "merging" then
    ball.pos = btVector3(-4 + (N % 100) * 0.08, 0.3, 2)
    if v.screenMerged >= 12 then
      print("merged " .. v.screenMerged .. " at frame " .. N)
      objs[3].pos = btVector3(-0.8, 0.5, 3.2) -- moved: leaves its batch
      objs[8].col = "#17becf"                  -- recoloured in its batch
      v:remove(objs[11])                       -- removed
      phase, at = "changed", N
    end
  elseif phase == "changed" then
    ball.pos = btVector3(-4 + (N % 100) * 0.08, 0.3, 2)
    if N > at + 30 then
      print("after the changes: " .. v.screenMerged .. " merged at frame " .. N)
      ball.pos = btVector3(4, 0.3, 2)
      phase = "done"
    end
  end
end)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(0, 7, 9)
v.cam.look = btVector3(0, 0.5, 0)
