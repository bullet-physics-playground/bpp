--[[
  hover-example.lua  --  demo of v:onHover() mouse-over tooltips

  Rest the mouse pointer on any object for half a second: a tooltip shows
  what it is, where the pointer hit it, and its live position and speed.
  The tooltip follows moving objects and updates ten times per second.

  bpp's normal mouse controls are untouched: holding any button hides the
  tooltip, and left/middle/right drag and the wheel move the camera as usual.

  API (needs a bpp built with the hover patch):
    v:onHover(function(frame, obj, x, y, z) ... return "text" end)
        called for the object under the resting pointer; (x,y,z) is the
        point hit. Return a string to show it, or nil to show nothing.
        v:onHover(nil) turns hovering off.
    objectKey(obj)
        a stable key for an object, usable as a Lua table index.

  Only built-in shapes are used, so this script needs no other files.
]]

local common = require "common"

v.gravity = btVector3(0, -9.81, 0)

local floor = Plane(0, 1, 0, 0, 100)
floor.col = "#808080"
v:add(floor)

local cube = Cube(4, 4, 4, 2)
cube.pos = btVector3(-9, 2, 0)
cube.col = "#d04040"
v:add(cube)

local ball = Sphere(2, 1)
ball.pos = btVector3(0, 15, 0)       -- dropped, so its speed changes at the start
ball.col = "#4070d0"
v:add(ball)

local can = Cylinder(1.5, 5, 1)
can.pos = btVector3(9, 3, 0)
can.col = "#40a040"
v:add(can)

common.setCamera(btVector3(0, 18, 34), btVector3(0, 2, 0))

local NAME = {
  [objectKey(cube)]  = "the red cube",
  [objectKey(ball)]  = "the blue ball",
  [objectKey(can)]   = "the green cylinder",
  [objectKey(floor)] = "the floor",
}

v:onHover(function(N, obj, x, y, z)
  local key = objectKey(obj)
  local name = NAME[key] or "something else"
  if key == objectKey(floor) then
    return string.format("%s\npointer at (%.1f, %.1f, %.1f)", name, x, y, z)
  end
  local p, vel = obj.pos, obj.vel
  return string.format(
    "%s\nmass   %.1f kg\npos    (%.1f, %.1f, %.1f)\nspeed  %.2f m/s\nhit at (%.1f, %.1f, %.1f)",
    name, obj.mass, p.x, p.y, p.z, vel:length(), x, y, z)
end)

print("Rest the mouse on an object to see its tooltip.")
