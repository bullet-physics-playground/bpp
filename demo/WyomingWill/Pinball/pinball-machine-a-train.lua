--
-- Trains the computer player without the display, many times faster than
-- real time. From this folder:
--
--   bpp -f pinball-machine-a-train.lua -n 2000000
--
-- (-n is the number of frames to run; 60 frames = 1 second of play, and
-- bpp runs them as fast as it can.) It prints progress every 10 games and
-- saves what it has learned to pinball-machine-a-brain.lua, which the
-- table loads the next time you press P.
--
package.path = "../../module/?.lua;" .. package.path
dofile("pinball-machine-a.lua")
TF.clock = function() return TF.frame() / 60 end   -- the plunger times itself by this
local ai = TF.ai
math.randomseed(tonumber(os.getenv("SEED") or tostring(os.time())))
local startGames = ai.brain.games
local lastReport = ai.brain.games
local base = TF.ai.tick
local t0 = os.time()
ai.toggle()
local tick = ai.tick
ai.tick = function(N)
  -- explore a lot at first, less as it gets better
  local played = ai.brain.games - startGames
  ai.epsilon = math.max(0.03, 0.2 * (0.97 ^ played))
  tick(N)
  if ai.brain.games >= lastReport + 10 then
    lastReport = ai.brain.games
    print(string.format("TRAIN %s  (exploring %.0f%% of choices, %d s so far)",
                        ai.statusText():gsub("^COMPUTER PLAYER %(P%): PLAYING | ", ""), 100 * ai.epsilon, os.time() - t0))
    ai.save()
  end
end
