--
-- 20 randomly colored polyhedra on a green plane
-- Objects are placed on an ordered 5x4 grid
-- Sizes are normalized so that all AABBs are equal
--

local color = require "color"
local polyhedra = require "polyhedra"

math.randomseed(os.time())

plane = Plane(0,1,0,0,200)
plane.col = color.gray
plane.friction = 1
v:add(plane)

solids = {
  "tetrahedron", "octahedron", "cube", "icosahedron", "dodecahedron",
  "small_stellated_dodecahedron", "great_stellated_dodecahedron",
  "great_dodecahedron", "great_icosahedron",
  "tetrahemihexahedron", "cubohemioctahedron", "octahemioctahedron",
  "small_dodecahemidodecahedron", "great_dodecahemidodecahedron",
  "small_dodecahemicosahedron", "great_dodecahemicosahedron",
  "small_icosihemidodecahedron", "great_icosihemidodecahedron",
}

-- extent of each solid = half of the AABB side at size = 1 (max |vertex coordinate|)
-- sizes are normalized so that every object has the same AABB
extents = {
  tetrahedron                    = 0.3536,
  octahedron                     = 0.7071,
  cube                           = 0.5000,
  icosahedron                    = 0.8090,
  dodecahedron                   = 1.3090,
  small_stellated_dodecahedron   = 0.5000,
  great_stellated_dodecahedron   = 0.5000,
  great_dodecahedron             = 0.8090,
  great_icosahedron              = 0.5000,
  tetrahemihexahedron            = 0.7071,
  cubohemioctahedron             = 0.7071,
  octahemioctahedron             = 0.7071,
  small_dodecahemidodecahedron   = 1.6180,
  great_dodecahemidodecahedron   = 0.6180,
  small_dodecahemicosahedron     = 1.0,
  great_dodecahemicosahedron     = 1.0,
  small_icosihemidodecahedron    = 1.6180,
  great_icosihemidodecahedron    = 0.6180,
}

-- target half AABB side; every object gets an AABB of side 2*target
target = 5

-- grid spacing must be >= AABB side + margin to avoid intersection
spacing = 2*target + 2

cols = 5
rows = 4

for i = 1,20 do
  col = (i-1) % cols
  row = math.floor((i-1) / cols)

  x = (col - (cols-1)/2) * spacing
  z = (row - (rows-1)/2) * spacing

  name = solids[math.random(#solids)]
  size = target / extents[name]

  obj = polyhedra[name]({ size = size, mass = 1 })
  obj.col = color.random_google()
  obj.friction = 0.5
  obj.restitution = 0.3

  obj.pos = btVector3(x, size*extents[name], z)

  v:add(obj)
end

v.cam:setUpVector(btVector3(0,1,0), false)
v.cam:setHorizontalFieldOfView(0.02)
v.cam.pos  = btVector3(0, 120, 200)
v.cam.look = btVector3(0, 0, 0)
