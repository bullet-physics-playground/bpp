-- test polyhedra module (Platonic, Kepler-Poinsot, and Versi-Regular solids)

local pass = 0
local fail = 0

local function assert_true(name, got)
  if got then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name)
    fail = fail + 1
  end
end

local polyhedra = require "polyhedra"

assert_true("polyhedra module is table", type(polyhedra) == "table")

local solids = {
  "tetrahedron", "octahedron", "cube", "icosahedron", "dodecahedron",
  "small_stellated_dodecahedron", "great_stellated_dodecahedron",
  "great_dodecahedron", "great_icosahedron",
  "tetrahemihexahedron", "cubohemioctahedron", "octahemioctahedron",
  "small_dodecahemidodecahedron", "great_dodecahemidodecahedron",
  "small_dodecahemicosahedron", "great_dodecahemicosahedron",
  "small_icosihemidodecahedron", "great_icosihemidodecahedron",
}

-- expected number of triangles after fan triangulation of each face
triangles = {
  tetrahedron                  = 4,
  octahedron                   = 8,
  cube                         = 12,
  icosahedron                  = 20,
  dodecahedron                 = 36,
  small_stellated_dodecahedron = 36,
  great_stellated_dodecahedron = 36,
  great_dodecahedron           = 36,
  great_icosahedron            = 20,
  tetrahemihexahedron          = 10,
  cubohemioctahedron           = 28,
  octahemioctahedron           = 24,
  small_dodecahemidodecahedron = 84,
  great_dodecahemidodecahedron = 84,
  small_dodecahemicosahedron   = 76,
  great_dodecahemicosahedron   = 76,
  small_icosihemidodecahedron  = 68,
  great_icosihemidodecahedron  = 68,
}

for _, name in ipairs(solids) do
  local ok, obj = pcall(function() return polyhedra[name]() end)
  assert_true(name .. " builds", ok and obj ~= nil)
  assert_true(name .. " is Mesh", ok and obj ~= nil and string.match(tostring(obj), "Mesh"))
  assert_true(name .. " body", ok and obj ~= nil and obj.body ~= nil)
  assert_true(name .. " mesh triangles", ok and obj ~= nil and obj.mesh ~= nil
    and obj.mesh.numTriangles == triangles[name])
end

print(string.format("\n%d passed, %d failed", pass, fail))
