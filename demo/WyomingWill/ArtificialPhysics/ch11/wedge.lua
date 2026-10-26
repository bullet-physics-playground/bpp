--
-- ch11/wedge.lua -- where Maxim's robot gets stuck on a wall (FINDINGS F81)
--
--   lua5.4 ch11/wedge.lua ENV SIZE STEPS          (from ArtificialPhysics/)
--   e.g. lua5.4 ch11/wedge.lua 4cell.roll 10 7000000
--
-- Runs ch11/maxim.lua (the C, exactly) for up to STEPS steps and stops at
-- the first step that needs more than 1000 headings before the way is
-- clear (a robot in the open needs a handful). That happens only once the
-- robot stands ON a wall: then every sensor line touches that wall, except
-- lines along it, so the robot can at best creep along the wall, on the
-- rare heading within ~10^-5 rad of it, and the run all but stops. It
-- prints the step that put the robot there: the sensor's end point
-- stopped short of the wall, but the move, rounded differently, landed on
-- it.
--
-- DEFINITIONS:
--   sensor  the C's end point of the sensor line, (float)(cos(h) * 1 + x):
--           rounded to a float once
--   move    the C's new position, x + (float)cos(h), stored as a float:
--           cos(h) rounded to a float, then the sum
--
package.path = "./?.lua;" .. package.path
local X = require "ch11.maxim"
local name, size, steps = arg[1], tonumber(arg[2]), tonumber(arg[3])
local env = X.readEnvironment(string.format("ch11/maxim/%s.environment/environment_%d.ini", name, size))
local m = X.new({ env = env, f = 0.6 })
local rnd0, draws = m.rnd, 0
m.rnd = function()
  draws = draws + 1
  if draws > 1000 then error("stuck", 0) end
  return rnd0()
end
local f32, cos, sin = X.f32, math.cos, math.sin
local last
while m.steps < steps do
  local x, y, h = m.x, m.y, m.heading
  draws = 0
  local ok = pcall(X.run, m, 1)
  if not ok then
    print(string.format("%s size %d: stuck at step %d, at %.9g %.9g", name, size, m.steps + 1, x, y))
    print(string.format("  put there by step %d: from %.9g %.9g, heading %.9g", last.step, last.x, last.y, last.h))
    print(string.format("  sensor end %.9g %.9g; move to %.9g %.9g", f32(cos(last.h) + last.x), f32(sin(last.h) + last.y),
      f32(last.x + f32(cos(last.h))), f32(last.y + f32(sin(last.h)))))
    print(string.format("  KL of the visits before it: %.5f over %d steps", X.kl(m.counts), m.steps))
    return
  end
  last = { step = m.steps, x = x, y = y, h = m.heading }
end
print(string.format("%s size %d: not stuck in %d steps", name, size, m.steps))
