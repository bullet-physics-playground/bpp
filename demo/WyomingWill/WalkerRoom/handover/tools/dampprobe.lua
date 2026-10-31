dofile("runs/speedprobe.lua")
local w = room.walkers[1]
local t = {}
for _, o in ipairs(w.bodies) do
  if o.mass > 0 then
    local by = (rawequal(o, w.cube) and "body") or (w.madeBy[o] or "?")
    local k = string.format("%s lin %.2f ang %.2f", by, o.body:getLinearDamping(), o.body:getAngularDamping())
    t[k] = (t[k] or 0) + 1
  end
end
local s = {}
for k, n in pairs(t) do s[#s + 1] = n .. "x " .. k end
table.sort(s)
print("RUN DAMP " .. w.spec.name .. " | " .. table.concat(s, " | "))
