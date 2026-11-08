--
-- Screenshot scene for tests/harness.py screens: culling (v.culling) must
-- not change the picture. Boxes stand across the edges of the view, half
-- in it, and must be drawn; a tall pillar stands out of view, and its long
-- shadow, under a low light, falls across the floor in view, so it must
-- still be drawn into the shadow map. Nothing moves. The shadow record
-- is off: with it, fixed objects come from recorded lists whatever culling
-- says (see tests/screens/merge.lua for the record).
--

v.gravity = btVector3(0, 0, 0)
v.shadowCache = false
v.glLight0 = btVector4(1, 0.35, 0.15, 0)   -- low, from the right

local plane = Plane(0, 1, 0, 0, 60)
plane.col = "#9aa5b1"
v:add(plane)

local function box(x, y, z, sx, sy, sz, col)
  local o = Cube(sx, sy, sz, 0)
  o.col = col
  o.pos = btVector3(x, y, z)
  v:add(o)
  return o
end

-- out of view to the right: only its shadow is seen
box(14, 4, -1, 1, 8, 1, "#444444")

-- across the edges of the view, a quarter or so of each in it
box(-6.85, 0.5, 0, 1, 1, 1, "#d62728")      -- left
box(6.85, 0.5, 0, 1, 1, 1, "#2ca02c")       -- right
box(0, 0.5, -15.8, 1, 1, 1, "#1f77b4")     -- far (top)
box(0, 0.5, 4.5, 1, 1, 1, "#ff7f0e")       -- near (bottom)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(0, 6, 8)
v.cam.look = btVector3(0, 0.5, 0)
