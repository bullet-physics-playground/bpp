dofile("runs/speedprobe.lua")
local w = room.walkers[1]
local cT = w.cube.body:getCenterOfMassTransform()
local lo, hi = btVector3(0,0,0), btVector3(0,0,0); w.cube.body:getAabb(lo, hi)
print(string.format("RUN BODY %.2f %.2f", hi.x - lo.x, hi.z - lo.z))
for _, o in ipairs(w.bodies) do
  if o.mass > 0 and not rawequal(o, w.cube) then
    local p = cT:invXform(o.body:getCenterOfMassPosition())
    print(string.format("RUN PART %s %.2f %.2f", w.madeBy[o] or "?", p.x, p.z))
  end
end
for _, t in ipairs(w.ties or {}) do
  local a, b = cT:invXform(t[1].body:getCenterOfMassPosition()), cT:invXform(t[2].body:getCenterOfMassPosition())
  print(string.format("RUN TIE %.2f %.2f %.2f %.2f", a.x, a.z, b.x, b.z))
end
