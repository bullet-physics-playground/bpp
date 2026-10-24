-- The body's box in its own frame (x along the walk, y up, z across): AABB at build minus its centre of mass.
dofile("test-track.lua")
local w = room.walkers[1]
local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0)
w.cube.body:getAabb(lo, hi)
local c = w.cube.body:getCenterOfMassPosition()
print(string.format("BOX %s|x %.3f %.3f|y %.3f %.3f|z %.3f %.3f", w.spec.name, lo.x - c.x, hi.x - c.x, lo.y - c.y, hi.y - c.y, lo.z - c.z, hi.z - c.z))
for _, d in ipairs(w.decor or {}) do d.o.body:getAabb(lo, hi); print(string.format("DECO|x %.2f %.2f|y %.2f %.2f|z %.2f %.2f", lo.x - c.x, hi.x - c.x, lo.y - c.y, hi.y - c.y, lo.z - c.z, hi.z - c.z)) end
