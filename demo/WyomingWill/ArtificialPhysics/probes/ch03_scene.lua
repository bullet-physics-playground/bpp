--
-- probes/ch03_scene.lua -- a lib/batch.py probe: Formations-Newtonian.lua
-- (the BPP scene) at the book's Ch. 3 settings, against Eq. 3.4
--
-- Switches the scene to 2D, sets the book's sliders (G from the run's
-- --set or 400, power 2, forceMax from --set or 1, rad 30, range 1.5,
-- friction 0.5, timeStep 1), starts 50 particles and reports at the end
-- (every frame runs ticksPerFrame = 10 of the scene's ticks):
--   ticks   the scene's steps run
--   nodes   lattice nodes occupied: particles closer than rad / 3 are one
--           node (as checks/ch03.lua counts them)
--   shared  share of the particles sharing a node with another
--   Gt      Eq. 3.4's G_t for these sliders; GoverGt = G / Gt
--
--   python3 lib/batch.py Formations-Newtonian.lua --probe probes/ch03_scene.lua \
--     --set G=233.8,311.8,400 --seeds 1-3 --frames 100 --out scene.csv
--
local batch = require "lib.batch"
setDimension(false)
local want = {}
for _, kv in ipairs(batch.settings()) do want[kv[1]] = kv[2] end
local book = { G = want.G or 400, power = 2, forceMax = want.forceMax or 1, rad = 30, range = 1.5,
               friction = 0.5, timeStep = 1, ticksPerFrame = 10 }
for k, val in pairs(book) do batch.set(k, val) end
setup(50)
batch.atEnd(function(frame)
  local ps = apParticles()
  local eps = 10
  local parent = {}
  for i = 1, #ps do parent[i] = i end
  local function find(i) while parent[i] ~= i do i = parent[i] end return i end
  for i = 1, #ps do for j = i + 1, #ps do
    local a, b = ps[i], ps[j]
    if (a.x - b.x) ^ 2 + (a.z - b.z) ^ 2 < eps * eps then parent[find(i)] = find(j) end
  end end
  local size = {}
  for i = 1, #ps do local r = find(i); size[r] = (size[r] or 0) + 1 end
  local nodes, shared = 0, 0
  for _, c in pairs(size) do nodes = nodes + 1; if c > 1 then shared = shared + c end end
  local Gt = book.forceMax * 30 ^ 2 / (2 * math.sqrt(3))
  batch.row({ final = 1, ticks = frame * 10, nodes = nodes, shared = shared / #ps, Gt = Gt, GoverGt = book.G / Gt })
end)
