-- tests/harness.py render: an export (bpp -e) of a scene with lights of
-- its own (LIGHTS.md). The harness checks that the .pov declares
-- BPP_Lights before settings.inc and pulls in LightSys after it, and that
-- each frame's .inc holds the lights where they are on that frame -- the
-- lamp moves -- and not the one taken out, and the halogen's bulb only
-- inside it (looks_like).
v.gravity = btVector3(0, 0, 0)

local ball = Sphere(2, 0)
ball.pos = btVector3(0, 2, 0)
v:add(ball)

local lamp = PointLight(btVector3(0, 100, 0))
v:add(lamp)

local halogen = SpotLight(btVector3(-130, 249.9, -175), btVector3(-130, -0.1, -175))
halogen.lumens = 1000
v:add(halogen)

-- (a bulb, written inside the lamp below, not on its own)
local bulb = Sphere(3, 0)
bulb.pos = btVector3(-130, 250, -175)
v:add(bulb)
halogen.looks_like = bulb

local gone = PointLight(btVector3(777, 0, 0))
v:add(gone)
v:remove(gone)

v:preDraw(function(N)
  lamp.pos = btVector3(10 * N, 100, 0)
end)
