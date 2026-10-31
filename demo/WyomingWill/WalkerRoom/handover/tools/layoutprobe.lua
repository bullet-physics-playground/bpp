dofile("runs/speedprobe.lua")
local w = room.walkers[1]; local look = w.spec.look
local lo, hi = btVector3(0,0,0), btVector3(0,0,0); w.cube.body:getAabb(lo, hi)
local X, Z = hi.x - lo.x - 0.08, hi.z - lo.z - 0.08
local letters, links = look.code:match("^(%S+)%s+(%S+)$"); letters, links = letters or look.code, look.links or links or "4"
print(string.format("RUN LAYOUT %s|%.2f|%.2f|%s|%s|%s|%s|%s|%s|%s", w.spec.name, X, Z, letters, links, tostring(LIFT_PCT[w.spec.name]), tostring(look.diag), tostring(w.unbraced and w.guides and true or false), look.colour, tostring(look.spears)))
