-- Centre-of-mass height above the feet' bottoms, at build, and total mass.
package.path = "/home/claude/bpp/demo/module/?.lua;" .. package.path
dofile("walker-room.lua")
local w = room.walkers[1]
local m, my, low = 0, 0, 1e9
for _, o in ipairs(w.bodies) do
  if o.mass > 0 then
    local _, y = getPosXYZ(o)
    m = m + o.mass; my = my + o.mass * y
    if w.madeBy[o] == "buildFoot" then low = math.min(low, y - 0.25) end
  end
end
local _, by = getPosXYZ(w.cube)
local fh = io.open(os.getenv("COM_OUT"), "a")
fh:write(string.format("%s|%s|mass %.1f|COM height %.2f cm|body centre %.2f cm\n", w.spec.name, LABEL, m, my / m - low, by - low))
fh:close()
