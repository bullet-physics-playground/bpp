-- tests/harness.py render: a quick render (v:quickRender) on frame 2, with
-- extra options. The harness puts a stand-in povray first on PATH and checks
-- how bpp called it.
v.gravity = btVector3(0, 0, 0)

local ball = Sphere(2, 0)
ball.col = "#1f77b4"
ball.pos = btVector3(0, 2, 0)
v:add(ball)

v:postSim(function(N)
  if N == 2 then v:quickRender("+W160 +H120") end
end)
