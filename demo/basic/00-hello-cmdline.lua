--
-- 00-hello-cmdline.lua - A Sphere drops on a Plane
--

-- You can run this Lua script from the command-line:
--
--   $ bpp -n 200 -f /usr/share/bpp/demo/basic/00-hello-cmdline.lua
--
-- Or plot the result with gnuplot:
--
--   $ bpp -n 200 -f /usr/share/bpp/demo/basic/00-hello-cmdline.lua | \
--     gnuplot -e "set terminal dumb; plot for[col=3:3] '/dev/stdin' using 1:col title columnheader(col) with lines"

-- a fixed plane in the x-z dimension
p = Plane(0,1,0,0,100)
p.col = "white"
p.restitution = 1
p.friction = 1
v:add(p)

-- a sphere with diameter 2 and mass 10
s = Sphere(1,10)
s.pos = btVector3( 0,10, 0) -- position
s.vel = btVector3( 4, 0, 0) -- velocity
s.col = "red"
s.restitution =.9
s.friction = 1
s.sdl = [[
  texture {
    pigment {
      radial
      frequency 2
      color_map {
        [0.00 color ReferenceRGB(Red)]    [0.25 color ReferenceRGB(Red)]
        [0.25 color ReferenceRGB(Green)]  [0.50 color ReferenceRGB(Green)]
        [0.50 color ReferenceRGB(Blue)]   [0.75 color ReferenceRGB(Blue)]
        [0.75 color ReferenceRGB(Yellow)] [1.00 color ReferenceRGB(Yellow)]
      }
    }
    finish { specular 0.6 }
  }
]]
v:add(s)

function setcam()
  v.cam:setFieldOfView(0.0095)
  v.cam:setUpVector(btVector3(0,1,0), true)
  v.cam.pos  = btVector3(600, 1, 2000)
  v.cam.look = btVector3(13.5,4,0)

  v.cam.focal_blur     = 1
  v.cam.focal_aperture = 5
  v.cam.focal_point    = s.pos
end

setcam()

v:preSim(function(N)
  if (N == 0) then print("N X Y Z") end
end)

v:postSim(function(N)
  print(N.." "..s.pos.x.." "..s.pos.y.." "..s.pos.z)
--  print(v:toPOV())
  setcam()
end)

-- EOF
