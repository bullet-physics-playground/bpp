-- Tests 1 and 2 (28 October), over wobprobe.lua (stallprobe under it):
--   T12_GHOST = true: the walker's outside braces touch nothing (they pass through the ground and obstacles)
--   T12_ROLL = k: the body's response to roll (turning about the walk, world x) scaled by k (setAngularFactor):
--     k 0.25 makes it four times as hard to roll, so it rocks less
dofile("/home/claude/work/wobprobe.lua")
local w = room.walkers[1]
if T12_GHOST then
  local n = 0
  for _, o in ipairs(w.bodies) do
    if w.madeBy[o] == "buildOutsideCrossbar" then o.body:setCollisionFlags(o.body:getCollisionFlags() + 4); n = n + 1 end
  end
  print("GHOST " .. n .. " brace pieces")
end
if T12_ROLL then w.cube.body:setAngularFactor(btVector3(T12_ROLL, 1, 1)); print("ROLL factor " .. T12_ROLL) end
