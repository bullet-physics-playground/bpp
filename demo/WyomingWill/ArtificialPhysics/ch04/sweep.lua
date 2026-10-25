--
-- ch04/sweep.lua -- the deviation from uniformity of ch04/coverage.lua
-- (uniform.nlogo, uniform_mfpl.nlogo) over agents and mean free paths
--
--   lua5.4 ch04/sweep.lua AGENTS MFPS [SEED]      (from ArtificialPhysics/)
--   e.g. lua5.4 ch04/sweep.lua 1,10 4,17,none
--
-- STOPPING RULE (the same for every run, since the right length depends
-- on the agents and the mean free path): run in doubling blocks of agent
-- steps (agents x ticks) from 2 x 10^7, and stop when the deviation at the
-- end of a block is within 1% of its value at the block's start, or at
-- 2 x 10^8 agent steps (the book's budget for Fig. 4.19: 1 agent for
-- 2 x 10^8 ticks, 100 for 2 x 10^6). Prints one line per run:
--   agents mfp ticks agentSteps deviation previous change converged
-- (deviation: Eq. 4.1, as ch04/coverage.lua defines it; previous: at
-- half the agent steps; change = |deviation - previous| / deviation).
--
package.path = "./?.lua;" .. package.path
local U = require "ch04.coverage"

local function list(s, f)
  local t = {}
  for v in s:gmatch("[^,]+") do t[#t + 1] = f(v) end
  return t
end
local agents = list(arg[1] or "1", tonumber)
local mfps = list(arg[2] or "17", function(v) return v ~= "none" and tonumber(v) or false end)
local seed = tonumber(arg[3] or "1")
local START, CAP, TOL = 2e7, 2e8, 0.01

for _, n in ipairs(agents) do
  for _, mfp in ipairs(mfps) do
    local m = U.new({ n = n, mfp = mfp or nil, seed = seed })
    local t0 = os.clock()
    local steps = START
    U.run(m, math.ceil(steps / n) - m.ticks)
    local prev, dev, ok = nil, U.deviation(m), false
    while steps < CAP do
      steps = math.min(steps * 2, CAP)
      U.run(m, math.ceil(steps / n) - m.ticks)
      prev, dev = dev, U.deviation(m)
      if math.abs(dev - prev) <= TOL * dev then ok = true; break end
    end
    print(string.format("agents %d mfp %s ticks %d agentSteps %.3g deviation %.5f previous %.5f change %.3f converged %s (%.0f s)",
      n, mfp and tostring(mfp) or "none", m.ticks, m.ticks * n, dev, prev or dev, prev and math.abs(dev - prev) / dev or 0,
      tostring(ok), os.clock() - t0))
    io.stdout:flush()
  end
end
