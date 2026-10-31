--
-- probes/worldgen_time.lua -- times the world generator: World.preset for
-- the five realistic presets, seed 1, generation only (no drawing), and
-- prints one line each and the total (CPU seconds, os.clock). Inside BPP
-- (which also has its compiled helpers, geo) or any Lua; from the
-- ArtificialPhysics folder:
--   bpp -f probes/worldgen_time.lua -n 1      or      luajit probes/worldgen_time.lua
--
local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]probes[/\\][^/\\]*$")) or "."
package.path = here .. "/?.lua;" .. package.path
local World = require "lib.world"
local total = 0
for _, name in ipairs({ "rural", "suburban", "city-centre", "industrial-port", "harbour-town" }) do
  local t = os.clock()
  World.preset(name, { seed = 1 })
  local dt = os.clock() - t
  total = total + dt
  print(string.format("WORLDGEN %-16s %.2f s", name, dt))
end
print(string.format("WORLDGEN total %.2f s (%s, geo %s)", total,
                    rawget(_G, "jit") and jit.version or _VERSION, tostring(rawget(_G, "geo") ~= nil)))
