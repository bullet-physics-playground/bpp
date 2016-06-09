--
-- 00-hello-cmdline.lua - A Sphere drops on a Plane
--

-- You can run this Lua script from the command-line:
--
--   $ bpp -n 200 -f 00-hello-cmdline.lua
--
-- Or plot the result with gnuplot:
--
--   $ bpp -n 200 -f 00-hello-cmdline.lua | \
--     gnuplot -e "set terminal dumb; plot for[col=3:3] '/dev/stdin' using 1:col title columnheader(col) with lines"

-- a fixed plane in the x-z dimension
p = Plane(0,1,0,0,100)
p.col = "white"
p.restitution = 1
v:add(p)

-- a sphere with diameter 1 and mass 10
s = Sphere(0.5,10)
s.pos = btVector3( 0,10, 0) -- position
s.vel = btVector3( 2, 0, 0) -- velocity
s.col = "red"
s.restitution =.725
v:add(s)

v:preSim(function(N)
  if (N == 0) then print("N X Y") end
end)

v:postSim(function(N)
  print(N.." "..s.pos.x.." "..s.pos.y)
end)

-- EOF
