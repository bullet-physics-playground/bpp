--[==[

 A red sphere drops on a plane

 * You can run this LUA script from the command-line:
   $ bpp -n 200 -f demo/basic/01-hello-cmdline.lua

 * Or plot the result with gnuplot:
   $ bpp -n 200 -f demo/basic/01-hello-cmdline.lua | gnuplot -e "set terminal dumb; plot for[col=3:3] '/dev/stdin' using 1:col title columnheader(col) with lines"

 10 +---------------------------------------------------------------------+
    | **   +      +      +      +      +      +      +      +      +      |
  9 |-+**                                                       Y *******-|
    |   **                                                                |
  8 |-+  **                                                             +-|
    |     *                                                               |
  7 |-+   **           *****                                            +-|
    |      *          **   ***                                            |
  6 |-+    **        **      **                                         +-|
    |       *       *         *                                           |
  5 |-+     *      **          *         *****                          +-|
    |        *     *           **      **     *                           |
  4 |-+      *    *             *      *       *                        +-|
    |         *   *              *    *         *                         |
  3 |-+       *  *               *   **         **                      +-|
    |          * *                *  *           **                       |
  2 |-+        ***                * *             *  *****    **        +-|
    |          **                 * *              ***    * *** **        |
  1 |-+         *                  *               *       **     ********|
    |      +      +      +      +      +      +      +      +      +      |
  0 +---------------------------------------------------------------------+
    0      20     40     60     80    100    120    140    160    180    200

This demo shows a bouncing ball with position tracking.
It outputs frame number and X/Y/Z positions that can be plotted with gnuplot.

Usage: bpp -n 200 -f demo/basic/01-hello-cmdline.lua

]==]

--
-- SCENE SETUP
--

-- POV-Ray pre-SDL (scene setup before objects)
v.pre_sdl = [==[
#include "colors.inc"
#include "textures.inc"

// Ground 

#declare RasterScale = 1.0 ;
#declare RasterHalfLine  = 0.05;
#declare RasterHalfLineZ = 0.05;

#macro Raster(RScale, HLine)
   pigment{ gradient x scale RScale
            color_map{[0.000   color rgbt<1,1,1,1>*0.6]
                      [0+HLine color rgbt<1,1,1,1>*0.6]
                      [0+HLine color rgbt<1,1,1,1>]
                      [1-HLine color rgbt<1,1,1,1>]
                      [1-HLine color rgbt<1,1,1,1>*0.6]
                      [1.000   color rgbt<1,1,1,1>*0.6]} }
   finish { ambient 0.15 diffuse 0.85}
#end

]==]

-- Create a large ground plane (100x100 units) at y=0
p = Plane(0,1,0,0,100)
p.restitution = 0.9  -- bounciness (0-1)
p.friction = 0.5       -- friction coefficient

p.col = "gray"
-- Add custom POV-Ray texture with checker pattern
p.sdl = [[
  texture { pigment{color rgbt<1,1,1,0.7>*1.1}
            finish {ambient 0.45 diffuse 0.85}}
  texture { Raster(RasterScale,RasterHalfLine ) rotate<0,0,0> }
  texture { Raster(RasterScale,RasterHalfLineZ) rotate<0,90,0>}
  rotate<0,0,0>
]]
v:add(p)

-- a sphere with diameter 2 (radius 1) and mass 10
s = Sphere(1,10)
s.pos = btVector3( 0,10, 0) -- start position (0, 10, 0)
s.vel = btVector3( 5, 0, 0) -- initial velocity: (5, 0, 0)
s.col = "red"
s.restitution = 0.9
s.friction = 0.5
s.sdl = [[ texture { pigment { color rgb <1, 0, 0> } } ]]
v:add(s)

-- Function to set up camera with focal blur focused on the sphere
function setcam()
  v.cam:setFieldOfView(0.15)
  v.cam:setUpVector(btVector3(0,1,0), true)
  v.cam.pos  = btVector3(100, 10, 100)
  v.cam.look = btVector3(20,5,0)

  v.cam.focal_blur     = 1
  v.cam.focal_aperture = 5
  v.cam.focal_point    = s.pos
end

setcam()

-- preSim: Called before each simulation step
v:preSim(function(N)
  if (N == 0) then print("N X Y Z") end
end)

-- postSim: Called after each simulation step
v:postSim(function(N)
  v:clearDebugText()
  setcam()
  print(N.." "..s.pos.x.." "..s.pos.y.." "..s.pos.z)
end)

-- EOF
