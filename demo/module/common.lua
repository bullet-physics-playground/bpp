--
-- common.lua - small helpers shared by many BPP demo scripts
--
-- Load with:  local common = require "common"
--
-- Everything here is optional; demos that need bespoke behavior (orbiting
-- cameras, dynamic gravity, custom pre_sdl) just don't call the helper.
--

local M = {}

-- ---------------------------------------------------------------------------
-- Simulation timing
-- ---------------------------------------------------------------------------

-- Sets the three timing knobs used by nearly every demo.
-- Defaults mirror the engine's own (Viewer.cpp): timeStep = 1/25,
-- maxSubSteps = 7, fixedTimeStep = 1/100.
function M.setTiming(timeStep, maxSubSteps, fixedTimeStep)
  v.timeStep      = timeStep or 1 / 25
  v.maxSubSteps   = maxSubSteps or 7
  v.fixedTimeStep = fixedTimeStep or 1 / 100
end

-- Standard gravity preset (default matches Bullet's -9.81).
function M.gravity(y)
  v.gravity = btVector3(0, y or -9.81, 0)
end

-- ---------------------------------------------------------------------------
-- Camera
-- ---------------------------------------------------------------------------

-- Positions the camera and optionally sets its field of view and focal blur.
--
--   common.setCamera(btVector3(0,30,-20), btVector3(0,0,0))
--   common.setCamera(pos, look, 0.5)                       -- also set FOV
--   common.setCamera(pos, look, 0.075, { horizontal = true, -- duplo/gears style
--                                        up = btVector3(0,1,0),
--                                        noMove = true,
--                                        focal_blur = 1,
--                                        focal_aperture = 5,
--                                        focal_point = somePos })
function M.setCamera(pos, look, fov, opts)
  opts = opts or {}
  v.cam:setUpVector(opts.up or btVector3(0, 1, 0),
                    opts.noMove ~= false)
  if fov then
    if opts.horizontal then
      v.cam:setHorizontalFieldOfView(fov)
    else
      v.cam:setFieldOfView(fov)
    end
  end
  v.cam.pos  = pos
  v.cam.look = look
  v.cam.focal_blur     = opts.focal_blur or 0
  v.cam.focal_aperture = opts.focal_aperture or 5
  v.cam.focal_point    = opts.focal_point or btVector3(0, 0, 0)
end

-- ---------------------------------------------------------------------------
-- Transforms
-- ---------------------------------------------------------------------------

-- btTransform from Euler angles (radians) and an origin, the long-form
-- idiom that demos otherwise write out with btQuaternion()/btTransform()
-- every time.
function M.transform(rx, ry, rz, x, y, z)
  return btTransform(M.quat(rx, ry, rz), btVector3(x or 0, y or 0, z or 0))
end

-- btQuaternion from Euler angles (radians), applied in x/y/z order.
function M.quat(rx, ry, rz)
  local q = btQuaternion()
  q:setEuler(rx or 0, ry or 0, rz or 0)
  return q
end

-- Quaternion that rotates a Cylinder's local +Z axis (its default resting
-- orientation, see Cylinder::renderInLocalFrame) to point from p1 to p2, so
-- a Cylinder(radius, length, 0) placed at their midpoint spans exactly
-- between them. Returns the quaternion, the length, and the midpoint.
function M.orientBetween(p1, p2)
  local dx, dy, dz = p2.x - p1.x, p2.y - p1.y, p2.z - p1.z
  local len = math.sqrt(dx * dx + dy * dy + dz * dz)
  if len < 1e-6 then return btQuaternion(), 0, p1 end
  dx, dy, dz = dx / len, dy / len, dz / len

  local dot = dz -- dot((0,0,1), dir)
  dot = math.max(-1, math.min(1, dot))
  local angle = math.acos(dot)

  local axis
  if angle < 1e-6 or angle > math.pi - 1e-6 then
    axis = btVector3(1, 0, 0) -- dir parallel/antiparallel to Z: any perpendicular axis works
  else
    -- cross((0,0,1), dir)
    axis = btVector3(-dy, dx, 0)
  end

  local mid = btVector3((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5, (p1.z + p2.z) * 0.5)
  return btQuaternion(axis, angle), len, mid
end

-- Places a fixed (mass 0) cylinder spanning p1..p2 and returns it.
function M.placeCylinder(p1, p2, radius, col)
  local rot, len, mid = M.orientBetween(p1, p2)
  if len < 1e-6 then return nil end
  local cy = Cylinder(radius, len, 0)
  cy.col = col
  cy.trans = btTransform(rot, mid)
  v:add(cy)
  return cy
end

-- Re-orients an already-placed cylinder to span p1..p2 (its length is baked
-- into its collision shape at construction, so this only works for rigid
-- rotations that preserve the separation, not sagging bodies).
function M.repositionCylinder(cy, p1, p2)
  if cy == nil then return end
  local rot, _, mid = M.orientBetween(p1, p2)
  cy.trans = btTransform(rot, mid)
end

-- Pushes a point further out, away from the central (vertical) axis, used to
-- place strands/rungs clear of an existing helical geometry.
function M.outwardOffset(pos, extra)
  local len = math.sqrt(pos.x * pos.x + pos.z * pos.z)
  if len < 1e-6 then
    return btVector3(pos.x + extra, pos.y, pos.z)
  end
  return btVector3(pos.x + pos.x / len * extra, pos.y, pos.z + pos.z / len * extra)
end

-- Rotates pos by `angle` radians around the Y (vertical) axis.
function M.rotateY(pos, angle)
  local c, s = math.cos(angle), math.sin(angle)
  return btVector3(pos.x * c - pos.z * s, pos.y, pos.x * s + pos.z * c)
end

-- ---------------------------------------------------------------------------
-- POV-Ray
-- ---------------------------------------------------------------------------

-- Returns a pre_sdl string declaring the Raster ground-grid macro used by
-- several demos. Callers append their own #include lines first, e.g.
--   v.pre_sdl = common.povRaster() -- with default "colors.inc"+"textures.inc"
function M.povRaster(scale, halfLine, halfLineZ)
  scale = scale or 1.0
  halfLine = halfLine or 0.045
  halfLineZ = halfLineZ or 0.045
  return string.format([==[
#include "colors.inc"
#include "textures.inc"

#declare RasterScale = %g;
#declare RasterHalfLine  = %g;
#declare RasterHalfLineZ = %g;

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

]==], scale, halfLine, halfLineZ)
end

return M
