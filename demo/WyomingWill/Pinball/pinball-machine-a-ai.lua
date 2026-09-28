--
-- The computer player for Pinball Machine A (press P at the table).
--
-- It plays through the same keys you do -- the plunger and the two
-- flippers -- and learns as it plays:
--
-- FLIPPERS: reinforcement learning (Q-learning). Every frame the ball is
-- near a flipper, the player looks at where the ball is relative to that
-- flipper and how it's moving, and chooses: flip now, or wait. When the
-- ball goes back up the table that's a reward (+1); when it drains
-- between the flippers, a penalty (-1). Q-learning passes that back to
-- the choices that led there, so over many balls the table of "how good
-- is flipping here" fills in and the timing sharpens. The left and right
-- flippers share what they learn (the right side is the mirror image).
--
-- PLUNGER: it tries different plunger strengths and keeps a running
-- average of how many points each one led to (a "multi-armed bandit"),
-- choosing the best one most of the time and the others now and then.
--
-- What it has learned is saved in pinball-machine-a-brain.lua next to the
-- table (every 50 balls, and when you press P to stop), so it carries on
-- where it left off. Delete that file to start it from scratch. To train
-- it quickly without the display, run pinball-machine-a-train.lua (see the
-- README).
--

return function(TF)
  local ai = { on = false }
  local BRAIN_FILE = "pinball-machine-a-brain.lua"

  -- learning settings
  local ALPHA = 0.15          -- how far each lesson moves an estimate
  local GAMMA = 0.98          -- how much a later outcome counts, per frame back
  ai.epsilon = 0.03           -- how often it tries a random choice while playing
  local HOLD = 12             -- frames a flip holds the flipper up (0.2 s)

  -- the state: the ball's place and motion relative to the flipper nearest
  -- it, in bins
  local DU0, DU_STEP, NDU = -3, 1.5, 12      -- across, from the pivot toward the middle
  local DW0, DW_STEP, NDW = -8, 1.5, 15      -- up the table from the pivot
  local VW_EDGES = { -220, -120, -60, -20, 15 }  -- speed down/up the table (cm/s)
  local VU_EDGES = { -40, 40 }                   -- speed across (toward the middle +)
  local NVW, NVU = #VW_EDGES + 1, #VU_EDGES + 1

  local function binOf(x, edges)
    for i, e in ipairs(edges) do if x < e then return i - 1 end end
    return #edges
  end

  -- ---------------------------------------------------------------------
  -- the brain: the Q table, the plunger's averages and some history
  -- ---------------------------------------------------------------------
  local brain
  do
    local ok, b = pcall(dofile, BRAIN_FILE)
    if ok and type(b) == "table" and b.q then brain = b end
  end
  brain = brain or { q = {}, episodes = 0, balls = 0, games = 0, scores = {}, recent = {},
                     plunge = { n = {}, sum = {} } }
  brain.recent = brain.recent or {}
  brain.scores = brain.scores or {}
  local q = brain.q

  function ai.save()
    local f = io.open(BRAIN_FILE, "w")
    if not f then return false end
    f:write("-- What the computer player of Pinball Machine A has learned.\n")
    f:write("-- Written by pinball-machine-a-ai.lua; delete it to start over.\n")
    f:write(string.format("return { episodes = %d, balls = %d, games = %d,\n",
                          brain.episodes, brain.balls, brain.games))
    local keys = {}
    for k in pairs(q) do keys[#keys + 1] = k end
    table.sort(keys)
    f:write("  q = {\n")
    for i, k in ipairs(keys) do
      f:write(string.format("[%d]=%.4f,", k, q[k]))
      if i % 8 == 0 then f:write("\n") end
    end
    f:write("\n  },\n  plunge = { n = {")
    for i = 1, 8 do f:write(string.format("%d,", brain.plunge.n[i] or 0)) end
    f:write("}, sum = {")
    for i = 1, 8 do f:write(string.format("%.1f,", brain.plunge.sum[i] or 0)) end
    f:write("} },\n  scores = {")
    for i = math.max(1, #brain.scores - 49), #brain.scores do f:write(string.format("%d,", brain.scores[i])) end
    f:write("},\n  recent = {")
    for i = math.max(1, #brain.recent - 199), #brain.recent do f:write(string.format("%d,", brain.recent[i])) end
    f:write("},\n}\n")
    f:close()
    return true
  end

  local function Q(s, a) return q[s * 2 + a] or 0 end
  local function setQ(s, a, x) q[s * 2 + a] = x end

  -- ---------------------------------------------------------------------
  -- seeing the ball
  -- ---------------------------------------------------------------------
  local fl = TF.flippers

  -- Which flipper the ball is nearest, and the state index (nil when the
  -- ball isn't near the flippers).
  local function observe(u, w, vu, vw)
    local mid = (fl[-1].pu + fl[1].pu) / 2
    local side = (u < mid) and -1 or 1
    local f = fl[side]
    -- mirror the right side onto the left: "across" is from the pivot
    -- toward the middle
    local du = (u - f.pu) * -side
    local dw = w - f.pw
    local mvu = vu * -side
    if du < DU0 or du >= DU0 + NDU * DU_STEP or dw < DW0 or dw >= DW0 + NDW * DW_STEP then
      return side, nil, du, dw
    end
    local iu = math.floor((du - DU0) / DU_STEP)
    local iw = math.floor((dw - DW0) / DW_STEP)
    local s = ((iu * NDW + iw) * NVW + binOf(vw, VW_EDGES)) * NVU + binOf(mvu, VU_EDGES)
    return side, s, du, dw
  end

  -- ---------------------------------------------------------------------
  -- playing
  -- ---------------------------------------------------------------------
  local FLIP_KEY = { [-1] = "LShift", [1] = "RShift" }
  local hold = { [-1] = 0, [1] = 0 }
  local episode = nil           -- { s, a, frames } while the ball is near the flippers
  local pull = nil              -- { at, strength, arm } while drawing the plunger
  local ballPlay = nil          -- { arm, score } for the ball in play
  local stats = { saves = 0, drains = 0 }
  local lastGameActive = false
  local game = TF.game

  local function recent(outcome)
    brain.recent[#brain.recent + 1] = outcome
    if #brain.recent > 400 then table.remove(brain.recent, 1) end
  end

  -- the end of a visit to the flippers: +1 the ball went back up, -1 it drained
  local function finish(reward)
    if episode then
      local s, a = episode.s, episode.a
      setQ(s, a, Q(s, a) + ALPHA * (reward - Q(s, a)))
      brain.episodes = brain.episodes + 1
      if reward > 0 then stats.saves = stats.saves + 1; recent(1)
      elseif reward < 0 then stats.drains = stats.drains + 1; recent(0) end
    end
    episode = nil
  end

  local function press(side, down)
    if (fl[side].pressed and true or false) ~= down then TF.onKey(FLIP_KEY[side], down) end
  end

  -- the plunger: 8 strengths from 30% to 100%
  local function plungeStrength(arm) return 0.3 + 0.1 * (arm - 1) end
  local function chooseArm()
    local p = brain.plunge
    local best, bestV = 1, -math.huge
    for i = 1, 8 do
      local n = p.n[i] or 0
      if n == 0 then return i end                   -- try each at least once
      local v = (p.sum[i] or 0) / n
      if v > bestV then best, bestV = i, v end
    end
    if math.random() < 0.15 then return math.random(8) end
    return best
  end

  local function ballOver()
    -- the plunger strength used for this ball: how many points it led to
    if ballPlay then
      local p = brain.plunge
      local arm = ballPlay.arm
      p.n[arm] = (p.n[arm] or 0) + 1
      p.sum[arm] = (p.sum[arm] or 0) + (game.score - ballPlay.score) / 1000
      ballPlay = nil
      brain.balls = brain.balls + 1
      if brain.balls % 50 == 0 then ai.save() end
    end
  end

  function ai.tick(N)
    if not ai.on then return end
    local t = TF.now()
    -- finish the layout editor, start games
    if TF.isEditing() then
      TF.onKey("E", true); TF.onKey("E", false)
      return
    end
    if lastGameActive and not game.active then
      brain.games = brain.games + 1
      brain.scores[#brain.scores + 1] = game.score
      if #brain.scores > 200 then table.remove(brain.scores, 1) end
    end
    lastGameActive = game.active
    if not game.active and not game.serveAt then
      finish(0)
      TF.onKey("1", true); TF.onKey("1", false)
      return
    end
    if game.serveAt then                       -- drained: waiting for the next ball
      finish(-1)
      ballOver()
      press(-1, false); press(1, false); hold[-1], hold[1] = 0, 0
      return
    end

    local u, w = TF.ballUW()
    local vu, vw = TF.ballVelUW()

    -- the plunger: ball resting in the shooter lane
    if u > TF.laneIn and w < 10 then
      if not pull and math.abs(vw) < 2 and math.abs(vu) < 2 then
        local arm = chooseArm()
        pull = { at = t, strength = plungeStrength(arm), arm = arm }
        TF.onKey("Return", true)
      elseif pull and t - pull.at >= pull.strength * 1.0 then
        TF.onKey("Return", false)
        ballPlay = ballPlay or { arm = pull.arm, score = game.score }
        pull = nil
      end
      return
    end
    if pull then TF.onKey("Return", false); pull = nil end

    -- the flippers
    for side = -1, 1, 2 do
      if hold[side] > 0 then
        hold[side] = hold[side] - 1
        if hold[side] == 0 then press(side, false) end
      end
    end
    local side, s, du, dw = observe(u, w, vu, vw)
    if episode then
      episode.frames = episode.frames + 1
      if dw > DW0 + NDW * DW_STEP and vw > 0 then finish(1)          -- back up the table
      elseif TF.inOuthole(u, w) or dw < DW0 - 2 then finish(-1)       -- gone
      elseif episode.frames > 600 then finish(0) end                  -- stuck
    end
    if s and hold[side] == 0 then
      -- learn from the last choice: what it led to is the best this state offers
      if episode then
        local ps, pa = episode.s, episode.a
        local target = GAMMA * math.max(Q(s, 0), Q(s, 1))
        setQ(ps, pa, Q(ps, pa) + ALPHA * (target - Q(ps, pa)))
      end
      -- choose: flip (1) or wait (0)
      local a
      if math.random() < ai.epsilon then a = math.random(0, 1)
      else
        local q0, q1 = Q(s, 0), Q(s, 1)
        a = (q1 > q0 or (q1 == q0 and math.random() < 0.5)) and 1 or 0
      end
      episode = { s = s, a = a, frames = episode and episode.frames or 0 }
      if a == 1 then
        press(side, true)
        hold[side] = HOLD
      end
    end
  end

  function ai.toggle()
    ai.on = not ai.on
    if not ai.on then
      press(-1, false); press(1, false); hold[-1], hold[1] = 0, 0
      if pull then TF.onKey("Return", false); pull = nil end
      episode = nil
      ai.save()
    end
  end

  function ai.statusText()
    local sc = brain.scores
    local n = math.min(10, #sc)
    local sum, best = 0, 0
    for i = #sc - n + 1, #sc do sum = sum + sc[i] end
    for _, x in ipairs(sc) do best = math.max(best, x) end
    local r = brain.recent
    local m = math.min(200, #r)
    local saved = 0
    for i = #r - m + 1, #r do saved = saved + r[i] end
    local entries = 0
    for _ in pairs(q) do entries = entries + 1 end
    return string.format("COMPUTER PLAYER (P): %s | %d games learned from, average of the last %d: %s, best %s | "
                         .. "saves at the flippers: %s of the last %d | %d flipper visits, %d table entries",
                         ai.on and "PLAYING" or "off", brain.games, n, n > 0 and tostring(math.floor(sum / n)) or "-",
                         tostring(best), m > 0 and string.format("%.0f%%", 100 * saved / m) or "-", m,
                         brain.episodes, entries)
  end

  ai.brain = brain
  ai.Q = Q
  return ai
end
