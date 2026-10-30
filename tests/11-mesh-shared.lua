-- test that replacing one Mesh's triangle mesh leaves the mesh cache's shared
-- one alone: Meshes loaded from the same file share one btTriangleMesh

local pass = 0
local fail = 0

local function assert_eq(name, got, expected)
  if got ~= expected then
    print("FAIL " .. name .. ": got=" .. tostring(got) .. " expected=" .. tostring(expected))
    fail = fail + 1
    return
  end
  print("PASS " .. name)
  pass = pass + 1
end

local a = Mesh("demo/mesh/torus.stl", 0)
local b = Mesh("demo/mesh/torus.stl", 0)
local n = b.mesh.numTriangles

assert_eq("a and b share one triangle mesh", tostring(a.mesh), tostring(b.mesh))

a.mesh = btTriangleMesh()   -- before c407ba2 this freed the shared mesh b still uses

assert_eq("a has its new mesh", a.mesh.numTriangles, 0)
assert_eq("b keeps its triangles", b.mesh.numTriangles, n)

-- a third Mesh of the file reads the same cached mesh; and when the cache's
-- entry is freed at the end, it must not free that mesh a second time
local c = Mesh("demo/mesh/torus.stl", 0)
assert_eq("a third copy still reads the cached mesh", c.mesh.numTriangles, n)

print(string.format("\n%d passed, %d failed", pass, fail))
