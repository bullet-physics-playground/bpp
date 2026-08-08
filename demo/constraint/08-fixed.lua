--
-- btFixedConstraint demo
-- Welds a chain of independent rigid bodies into one rigid compound: each
-- link keeps its own physics body (its own mass, its own collision shape),
-- but zero relative motion is allowed between neighbors, so the whole
-- chain falls, tumbles and bounces off the ground as if it were a single
-- rigid object -- unlike btPoint2PointConstraint (locks position only, so
-- a chain of those sags and swings) or btHingeConstraint (locks position
-- but still allows rotation about the hinge axis).
--

plane = Plane(0,1,0,0,20)
plane.col = "#222222"
v:add(plane)

local LINKS = 5
local LEN   = 1.5
local links = {}

for i = 1, LINKS do
  local link = Cube(LEN * 0.5, 0.4, 0.4, 1)
  link.pos = btVector3((i - 1) * LEN, 10, 0)
  link.col = (i % 2 == 0) and "#ff6600" or "#4488ff"
  v:add(link)
  links[i] = link

  if i > 1 then
    local frameInA = btTransform()
    frameInA:setIdentity()
    frameInA:setOrigin(btVector3(LEN * 0.5, 0, 0))

    local frameInB = btTransform()
    frameInB:setIdentity()
    frameInB:setOrigin(btVector3(-LEN * 0.5, 0, 0))

    local con = btFixedConstraint(links[i - 1].body, link.body, frameInA, frameInB)
    v:addConstraint(con)
  end
end

-- Spin just the first link -- the fixed joints immediately drag the rest
-- of the chain along with it, since none of them are allowed to move
-- relative to their neighbor. Watch it tumble onto the ground as one
-- rigid rod, never flexing at any of its 4 welded joints.
links[1].body:setAngularVelocity(btVector3(0, 0, 2))

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos  = btVector3(3, 9, 17)
v.cam.look = btVector3(3, 2, 0)

-- EOF
