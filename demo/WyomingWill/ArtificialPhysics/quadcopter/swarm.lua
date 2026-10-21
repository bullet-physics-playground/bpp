--
-- quadcopter/swarm.lua -- the harness moved to lib/swarm.lua in milestone
-- M2, when it began to serve every kind of vehicle (BOOK.md G18). This
-- file stays so that scripts and probes that require "quadcopter.swarm"
-- keep working.
--
if select("#", ...) == 0 then
  local msg = "quadcopter/swarm.lua is the shared harness, not a scene: open "
           .. "Formations-Newtonian-Quadcopter.lua or Formations-Lennard-Jones-Quadcopter.lua "
           .. "in the ArtificialPhysics folder"
  print(msg)
  if rawget(_G, "v") then pcall(function() v.statusText = msg end) end
  return
end
return require "lib.swarm"
