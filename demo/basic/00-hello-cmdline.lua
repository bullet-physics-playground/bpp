--
-- 00-hello-cmdline.lua
--

-- You can run this Lua script from the command-line:
--
--   $ bpp -n 60 -l 00-hello-cmdline.lua
--
-- Or plot the result with gnuplot:
--
--   $ bpp -n 60 -l 00-hello-cmdline.lua | \
--     gnuplot -e "set terminal dumb; plot for[col=3:3] '/dev/stdin' using 1:col title columnheader(col) with lines"

-- A Sphere drops on a Plane

p = Plane(0,1,0,0) -- a fixed plane in the x-z dimension
v:add(p)

s = Sphere(1,10)          -- 1 radius, 10 mass
s.pos = btVector3(0,10,0) -- position of sphere
s.vel = btVector3(10,0,0) -- velocity vector
v:add(s)

v:preSim(function(N)
  if (N == 0) then print("N X Y") end
end)

v:postSim(function(N)
  print(N.." "..s.pos.x.." "..s.pos.y)
end)

-- EOF
