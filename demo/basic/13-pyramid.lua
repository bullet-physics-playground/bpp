--
-- Random pyramids demo
--
-- Creates tetrahedra and square-based pyramids as compound
-- rigid bodies with mass, using btTriangleMesh and Mesh for
-- visual rendering with checker texture.
--
-- Usage: bpp -f demo/basic/13-pyramid.lua

local color  = require "color"
local common = require "common"

common.gravity(-9.81)
common.setTiming(1/50, 7, 1/120)

local dim = 20 -- scene dimension

v.pre_sdl = [[

#include "textures.inc"

object {                                                                        
  Light(                                                                        
    EmissiveSpectrum(ES_GE_SW_Incandescent_100w),                               
    Lm_Incandescent_100w,                                                       
    x*50, z*50, 4, 4, on                                                        
  )                                                                             
  translate <0, 290, 150>                                                   
}
]]

v.pre_sdl = v.pre_sdl..[==[
#declare CheckerScale = 0.5;
#declare CheckerPigment = pigment {
  checker
  color rgb <1, 1, 1>
  color rgb <0.1, 0.1, 0.1>
  scale CheckerScale
}
]==]

-- ground plane
p = Plane(0, 1, 0, 0, 50)
p.col = color.HuntersGreen
p.sdl = [[
  pigment { HuntersGreen }
  normal  { quilted scale 0.5 }
]]
v:add(p)

-- helper: build a rigid body pyramid from a triangle mesh
function make_pyramid(triangles, px, py, pz, mass, col)
  local meshData = btTriangleMesh()

  for _, tri in ipairs(triangles) do
    meshData:addTriangle(tri[1], tri[2], tri[3], true)
  end

  local shape = btGImpactMeshShape(meshData)
  shape:updateBound()

  local ms = btDefaultMotionState(common.transform(0, 0, 0, px, py, pz))

  local inertia = btVector3()
  if mass > 0 then
    shape:calculateLocalInertia(mass, inertia)
  end
  local body = btRigidBody(mass, ms, shape, inertia)

  local obj = Mesh()
  obj.mesh  = meshData  -- transfer ownership to prevent GC
  obj.shape = shape
  obj.body  = body
  obj.mass  = mass
  obj.inertia = inertia:length()
  obj.damp_lin = 0.0
  obj.damp_ang = 0.0
  obj.pos  = btVector3(px, py, pz)
  obj.col  = col or color.random_google()
  v:add(obj)
  return obj
end

-- helper: tetrahedron face indices
local tet_faces = {
  {1, 2, 3},
  {1, 2, 4},
  {2, 3, 4},
  {3, 1, 4},
}

-- helper: build a tetrahedron (3-sided pyramid)
function tetrahedron(cx, cy, cz, size, mass, col)
  local s = size * 0.5
  local h = size
  local v = {
    btVector3(-s, 0, -s),
    btVector3( s, 0, -s),
    btVector3( 0, 0,  s),
    btVector3( 0, h,  0),
  }
  local tris = {}
  for _, f in ipairs(tet_faces) do
    table.insert(tris, { v[f[1]], v[f[2]], v[f[3]] })
  end
  return make_pyramid(tris, cx, cy, cz, mass, col)
end

-- helper: square-based pyramid face indices
local pyr_faces = {
  {1, 2, 3}, -- base tri 1
  {1, 3, 4}, -- base tri 2
  {1, 2, 5}, -- side 1
  {2, 3, 5}, -- side 2
  {3, 4, 5}, -- side 3
  {4, 1, 5}, -- side 4
}

-- helper: build a square-based pyramid
function pyramid(cx, cy, cz, base, height, mass, col)
  local s = base * 0.5
  local h = height
  local v = {
    btVector3(-s, 0, -s), -- 1: b0
    btVector3( s, 0, -s), -- 2: b1
    btVector3( s, 0,  s), -- 3: b2
    btVector3(-s, 0,  s), -- 4: b3
    btVector3( 0, h,  0), -- 5: apex
  }
  local tris = {}
  for _, f in ipairs(pyr_faces) do
    table.insert(tris, { v[f[1]], v[f[2]], v[f[3]] })
  end
  return make_pyramid(tris, cx, cy, cz, mass, col)
end

-- random tetrahedra
for i = 1, 50 do
  local x  = math.random(-dim, dim)
  local z  = math.random(-dim, dim)
  local sz = 0.5 + math.random() * 1.2
  local y  = sz + 1
  tetrahedron(x, y, z, sz, 1, color.random_chrome())
end

-- random square-based pyramids
for i = 1, 50 do
  local x  = math.random(-dim, dim)
  local z  = math.random(-dim, dim)
  local b  = 1.5 + math.random() * 1.2
  local h  = 1.8 + math.random() * 1.5
  local y  = h + 0.5
  pyramid(x, y, z, b, h, 1, color.random_chrome())
end

-- dynamic cubes to knock into the pyramids
for i = 1, 50 do
  local x = math.random(-dim, dim)
  local y = 2 + math.random() * 5
  local z = math.random(-dim, dim)
  local s = 1.8 + math.random() * 0.4
  local c = Cube(s, s, s, 1)
  c.pos = btVector3(x, y, z)
  c.col = color.random_google()
  v:add(c)
end

-- some spheres too
for i = 1, 50 do
  local r = 0.9 + math.random() * 0.3
  local s = Sphere(r, 1)
  s.pos = btVector3(math.random(-dim, dim), 3 + math.random() * 4, math.random(-dim, dim))
  s.col = color.random_chrome()
  v:add(s)
end

-- EOF