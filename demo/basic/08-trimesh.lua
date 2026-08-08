--
-- btTriangleMesh pyramids
--
-- Demonstrates low-level triangle mesh creation using btTriangleMesh.
-- Shows how to manually define custom mesh geometry.
--
-- Usage: bpp -f demo/basic/08-trimesh.lua

local color  = require "color"
local common = require "common"

v.pre_sdl = common.povRaster(1, 0.045, 0.045)

p = Plane(0,1,0,0,100)
p.pos = btVector3(0,-2,0)
p.col = "#101010"
p.sdl = [[
  texture { pigment{color rgbt<1,1,1,0.7>*1.1}
            finish {ambient 0.45 diffuse 0.85}}
  texture { Raster(RasterScale,RasterHalfLine ) rotate<0,0,0> }
  texture { Raster(RasterScale,RasterHalfLineZ) rotate<0,90,0>}
  rotate<0,0,0>
  // no_shadow
]]
v:add(p)

function mesh()
   m = btTriangleMesh()

  local l = 5

  local a = btVector3(0, l*2,0)
  local b = btVector3(-0, 2, l*2)
  local c = btVector3(-l, 0,-l)
  local d = btVector3( l*2, 0, 0)

  m:addTriangle(a, b, c, true)
  m:addTriangle(b, c, d, true)
  m:addTriangle(c, d, a, true)
  m:addTriangle(d, a, b, true)

ms = btDefaultMotionState(common.transform(0.0, 20, 0.0, 0, 2, 0))

shape = btGImpactMeshShape(m)

shape:updateBound()

mass = 1

inertia = btVector3()
shape:calculateLocalInertia(mass, inertia)
body = btRigidBody(mass, ms, shape, inertia)

mm = Mesh()
mm.col   = color.random_chrome()
mm.shape = shape
mm.body  = body
mm.mass     = 1
mm.inertia  = 0.9
mm.damp_lin = 0.0
mm.damp_ang = 0.0
v:add(mm)
return mm
end

--v:add(mesh())
--v:add(mesh())

function tst()
  for i = 0,600 do
    m = mesh()
  end
end

tst()
