--
-- probes/coverage_sweep.lua -- a lib/batch.py probe: Uniform_Coverage.lua's
-- deviation from uniformity, run under ch04/sweep.lua's stopping rule
--
-- DEFINITIONS: deviation as the scene defines it (Eq. 4.1, the 9 cells of
-- its +-40 arena); agentSteps = agents x ticks. The rule: checkpoints at
-- 2 x 10^7 agent steps and then doubling, to 2 x 10^8 at most; the run
-- stops (os.exit) at the first checkpoint whose deviation is within 1% of
-- the one before. Reports one row: ticks, agentSteps, deviation, previous,
-- change, converged. COVER_START and COVER_CAP change the two budgets.
-- Use a large ticksPerFrame (the scene draws once a
-- frame) and enough frames, e.g.:
--   python3 lib/batch.py Uniform_Coverage.lua --probe probes/coverage_sweep.lua \
--     --set numParticles=1 --set meanFreePath=17 --set ticksPerFrame=20000 \
--     --frames 20000 --seeds 1 --out uc.csv
--
local batch = require "lib.batch"
local START = tonumber(os.getenv("COVER_START") or "") or 2e7   -- (shorter for the scene's 100 agents:
local CAP = tonumber(os.getenv("COVER_CAP") or "") or 2e8       --  it checks every pair, so it is slow)
local TOL = 0.01
local nextAt, prev = START, nil
local function report(ticks, n, dev, ok)
  batch.row({ final = 1, ticks = ticks, agentSteps = ticks * n, deviation = string.format("%.6g", dev),
              previous = prev and string.format("%.6g", prev) or "", change = prev and string.format("%.4f", math.abs(dev - prev) / dev) or "",
              converged = ok and 1 or 0 })
  io.stdout:flush()
end
batch.every(1, function()
  local ticks, n, dev = coverageStats()
  if ticks * n < nextAt then return end
  if prev and math.abs(dev - prev) <= TOL * dev then report(ticks, n, dev, true); os.exit(0) end
  if nextAt >= CAP then report(ticks, n, dev, false); os.exit(0) end
  prev = dev
  nextAt = math.min(nextAt * 2, CAP)
end)
batch.atEnd(function()
  local ticks, n, dev = coverageStats()
  report(ticks, n, dev, false)
end)
