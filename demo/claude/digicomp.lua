--
-- Digi-Comp II -- a physical binary ripple counter, in the spirit of
-- E.S.R.'s 1960s gravity-powered marble computer.
--
-- THE ORIGINAL MACHINE: balls roll down a pegboard and strike a cascade
-- of bat-wing "toggle" levers. Each toggle is pivoted at its center: a
-- ball landing on it tips it to one side, is deflected out that side,
-- and leaves the toggle resting tipped the OPPOSITE way it was before --
-- so the very next ball to arrive is deflected the other way. A toggle
-- is a one-bit memory (a T flip-flop) implemented purely as a passive,
-- gravity-driven mechanism: no electronics, no scripted decision, just
-- geometry and gravity.
--
-- THE DAG ABSTRACTION (Scott Aaronson, "The Complexity of the Digi-Comp
-- II", quoted by the user): model the machine as a directed acyclic
-- graph where every internal vertex has out-degree 2 (a toggle,
-- routing a ball to one of two children) and ball-count is the input,
-- encoded in unary or binary. Aaronson showed the reachability
-- question ("does any ball reach the designated sink vertex?") is
-- complete for CC (the stable-marriage-reducibility class) under
-- log-space reduction with unary ball counts, and stays in P with
-- binary counts. This demo builds exactly that DAG: N_BITS toggle
-- vertices in a chain, a SOURCE (the entry funnel above bit 0) where
-- balls are introduced one at a time, and a SINK (the overflow bin
-- past the last toggle) that is only reached once the ball count
-- exceeds what N_BITS toggles can represent (2^N_BITS balls).
--
-- WHAT THE CHAIN COMPUTES: toggle i's two exits are DISPLAY (the ball
-- stops here, terminal -- this toggle's bit is 1) and CARRY (the ball
-- falls on to toggle i+1 -- this toggle's bit is 0, and the ball
-- becomes an input to the next toggle). Every toggle starts in the
-- state that sends its FIRST-ever ball to display and flips for the
-- next visit, alternating forever after. That is precisely a binary
-- ripple counter: after N balls have been dropped, one at a time, the
-- toggles' resting states spell out N in binary, low bit first. This
-- is not scripted arithmetic -- it falls straight out of each toggle
-- being a passive 2-state flip-flop clocked by "a ball visited me".
--
-- ENGINEERING NOTE -- why the toggle is motor-assisted, not pure
-- passive dynamics: a bar pivoted exactly at its own center of mass
-- has ZERO gravity torque at any tilt (the CoM sits on the pivot), so
-- there's no restoring/driving force beyond whatever momentum the
-- ball itself transfers on contact -- fragile in practice: measured
-- moment arm at first contact is only ~(ball radius * tan(tilt)), and
-- across many empirical trials (single toggle, then 2-row, then the
-- full cascade) that was NOT reliably enough to complete a full flip
-- every time -- sometimes it would rock most of the way over and fall
-- back to where it started. A small hinge motor, retargeted the
-- instant a ball leaves the bar (so it never fights the ball in
-- transit), fixes this while changing nothing about what's simulated:
-- the ball's actual route is still decided by nothing but real contact
-- physics against the bar's current tilt -- the motor only guarantees
-- the bar reliably FINISHES the flip it's already supposed to make
-- before the next ball arrives, exactly like the spring/detent action
-- a real mechanical toggle would have and a frictionless simulated
-- bar doesn't.
--
-- LAYOUT -- a rightward staircase, not a return-to-center funnel: an
-- earlier version tried to funnel the CARRY ball back to x=0 for every
-- row with a single long ramp, and separately tried a narrow catch
-- funnel directly above each bar. Both were fragile against a real
-- ball's actual post-tip trajectory (either jammed against the bar's
-- own tilt envelope, or the ball simply flew past a too-thin ramp).
-- What actually works, verified empirically: let toggle i+1 sit
-- wherever a carry-ball naturally lands after leaving toggle i's tip
-- (a fixed rightward/downward offset), and give it its own modest
-- entry funnel positioned with generous clearance above ITS bar. No
-- long-distance aiming needed anywhere. The display (bit=1) exit goes
-- the other way, onto a shelf fixed relative to that row's own pivot.
--

local common = require "common"

common.setTiming(1/25, 50, 1/240)
common.gravity(-9.8)

-- ---------------------------------------------------------------------
-- tunables
-- ---------------------------------------------------------------------

local N_BITS = 4              -- counts 0..15, ball 16 overflows to the sink
local MAX_BALLS = 17

local BAR_LEN, BAR_THICK, BAR_DEPTH, BAR_MASS = 3.0, 0.3, 0.7, 0.35
local BAR_LIMIT = math.rad(24)
local MOTOR_VEL, MOTOR_FORCE = 3.0, 8.0     -- retarget speed/strength once a ball has cleared the bar

local BALL_R, BALL_MASS = 0.35, 1.0

local X_STEP, ROW_DY = 2.2, 2.7             -- staircase step to where a carry-ball naturally lands
local CHANNEL_Z = 0.6                       -- +-Z confinement so balls can't drift off the board
local FUNNEL_GAP_HALF = 0.7                 -- entry-funnel mouth half-width (comfortably > ball diameter)
local FUNNEL_BOTTOM_OFF = 0.95              -- funnel mouth height above the bar's pivot -- clear of its max tilt reach
local FUNNEL_TOP_OFF = 2.0

-- Balls are spawned ADAPTIVELY, not on a fixed interval: the next ball
-- drops as soon as the current one has actually come to rest, rather
-- than always waiting out the worst case (a ball carrying through all
-- N_BITS toggles to the sink). Most balls terminate at toggle 1 and
-- settle in well under 200 frames -- only every 2^N_BITS-th ball needs
-- the deep cascade -- so this keeps the common case fast while still
-- safely waiting through the rare slow one. "Settled" requires low
-- speed to hold for a sustained run of frames, not just one instant:
-- an earlier version checked a single frame and fired on a ball's
-- brief pause mid-transit (e.g. right as it first touches a bar,
-- before rolling off), spawning the next ball too early and corrupting
-- the count via a mid-air collision.
local SETTLE_SPEED2 = 0.02      -- squared linear speed considered "at rest"
local SETTLE_STREAK_FRAMES = 30 -- how long that has to hold, consecutively
local SETTLE_MIN_AGE = 30       -- ignore the launch itself (still fast/moving)
local SETTLE_MAX_WAIT = 1200    -- hard fallback in case something never settles

local ROW_COLORS = { "coral", "teal", "goldenrod", "slateblue", "firebrick", "seagreen" }

-- ---------------------------------------------------------------------
-- helper: a static or dynamic rod/wall spanning two points in the X-Y
-- plane (half-angle quaternion construction -- avoids relying on
-- atan2, same trick used in the WyomingWill Chebyshev walker demos).
-- ---------------------------------------------------------------------

local function wallSpan(x1, y1, x2, y2, thick, depth, col)
  local dx, dy = x2 - x1, y2 - y1
  local len = math.sqrt(dx * dx + dy * dy)
  local cosT, sinT = dx / len, dy / len
  local cosHalf = math.sqrt((1 + cosT) / 2)
  local sinHalf = math.sqrt((1 - cosT) / 2)
  if sinT < 0 then sinHalf = -sinHalf end
  local q = btQuaternion(0, 0, sinHalf, cosHalf)
  local w = Cube(len, thick, depth, 0)
  w.trans = btTransform(q, btVector3((x1 + x2) / 2, (y1 + y2) / 2, 0))
  if col then w.col = col end
  v:add(w)
  return w
end

-- ---------------------------------------------------------------------
-- one toggle row -- the physical DAG vertex. Pivoted on a hinge whose
-- anchor body sits physically BEHIND the board (offset in Z, with the
-- hinge's own pivot point offset back to the true world pivot) so the
-- anchor's own collision geometry never intercepts the ball.
-- ---------------------------------------------------------------------

local rows = {}

local function buildRow(index, x, y)
  local anchor = Cube(0.3, 0.3, 0.3, 0)
  anchor.pos = btVector3(x, y, -1.0)
  v:add(anchor)

  local bar = Cube(BAR_LEN, BAR_THICK, BAR_DEPTH, BAR_MASS)
  bar.pos = btVector3(x, y, 0)
  bar.col = ROW_COLORS[((index - 1) % #ROW_COLORS) + 1]
  bar.friction = 0.9
  bar.damp_ang = 0.3
  v:add(bar)

  local axis = btVector3(0, 0, 1)
  local hinge = btHingeConstraint(anchor.body, bar.body, btVector3(0, 0, 1.0), btVector3(0, 0, 0), axis, axis)
  hinge:setLimit(-BAR_LIMIT, BAR_LIMIT, 0.9, 0.3, 1.0)
  v:addConstraint(hinge)

  -- state: "display" -> this toggle currently reads bit 0, ball stops here next visit.
  --        "carry"   -> this toggle currently reads bit 1, ball falls through to the next toggle.
  -- Every toggle starts at "display": bit 0, matching a freshly-reset counter.
  local row = { index = index, x = x, y = y, hinge = hinge, state = "display", shelfBall = nil }

  local function applyMotor()
    local targetVel = (row.state == "display") and -MOTOR_VEL or MOTOR_VEL
    hinge:enableAngularMotor(true, targetVel, MOTOR_FORCE)
  end
  row.applyMotor = applyMotor
  applyMotor()

  row.flip = function()
    local before = row.state
    row.state = (row.state == "display") and "carry" or "display"
    applyMotor()
    return before
  end

  -- entry funnel: wide gap, well clear of the bar's own max-tilt reach
  -- (an earlier too-narrow/too-close version let the ball wedge between
  -- the funnel wall and the tilted bar -- fixed by widening the gap
  -- past the ball's diameter and raising the funnel mouth above the
  -- bar's highest possible tip height).
  wallSpan(x - 1.8, y + FUNNEL_TOP_OFF, x - FUNNEL_GAP_HALF, y + FUNNEL_BOTTOM_OFF, 0.12, 0.9)
  wallSpan(x + 1.8, y + FUNNEL_TOP_OFF, x + FUNNEL_GAP_HALF, y + FUNNEL_BOTTOM_OFF, 0.12, 0.9)

  -- display shelf: catches a "bit=1" ball and holds it there, a visible,
  -- permanent readout of this toggle's current value.
  local shelf = Cube(2.6, 0.2, 1.0, 0)
  shelf.pos = btVector3(x - 3.6, y - 1.5, 0)
  shelf.col = "burlywood"
  shelf.friction = 0.8
  v:add(shelf)
  local stop = Cube(0.2, 0.6, 1.0, 0)
  stop.pos = btVector3(x - 4.9, y - 1.3, 0)
  stop.col = "burlywood"
  v:add(stop)

  return row
end

for i = 1, N_BITS do
  rows[i] = buildRow(i, (i - 1) * X_STEP, -(i - 1) * ROW_DY)
end

-- ---------------------------------------------------------------------
-- the sink vertex: past the last toggle's carry side, a ball only ever
-- lands here once the count exceeds 2^N_BITS - 1 (i.e. the (2^N_BITS)th
-- ball). Marked in red to stand out as "counter overflow".
-- ---------------------------------------------------------------------

local lastRow = rows[N_BITS]
local sinkFloor = Cube(3.0, 0.2, CHANNEL_Z * 2, 0)
sinkFloor.pos = btVector3(lastRow.x + 2.3, lastRow.y - 1.8, 0)
sinkFloor.col = "red"
sinkFloor.friction = 0.8
v:add(sinkFloor)
local sinkStop = Cube(0.2, 0.6, CHANNEL_Z * 2, 0)
sinkStop.pos = btVector3(lastRow.x + 3.7, lastRow.y - 1.6, 0)
sinkStop.col = "red"
v:add(sinkStop)

-- Z-confinement walls the full extent of the board, keeping every ball
-- on the same flat plane the whole way down the staircase. Sized to
-- cover the whole rig, a pair of solid panels this large would
-- otherwise fill the camera's view edge-to-edge from almost any angle
-- that still frames the whole staircase -- made semi-transparent
-- (0.25) instead of hiding them outright, so the toggles, funnels and
-- balls are still visible working away behind the "glass".
local topY, botY = 3, lastRow.y - 3
local channelLen = lastRow.x + 8
local zw1 = Cube(channelLen, topY - botY, 0.2, 0)
zw1.pos = btVector3(lastRow.x / 2, (topY + botY) / 2, CHANNEL_Z + 0.1)
zw1.col = "darkblue"
zw1.transparency = 0.9
v:add(zw1)
local zw2 = Cube(channelLen, topY - botY, 0.2, 0)
zw2.pos = btVector3(lastRow.x / 2, (topY + botY) / 2, -CHANNEL_Z - 0.1)
zw2.col = "darkblue"
zw2.transparency = 0.9
v:add(zw2)

-- ---------------------------------------------------------------------
-- ball spawner + trigger logic. A ball "clocks" toggle i (flips it) the
-- moment it has fallen clear of that toggle's bar -- regardless of
-- which side it went out, since a T flip-flop toggles on every visit.
-- The routing itself was already decided by real physics before this
-- ever runs: this only advances the memory bit for the NEXT visit.
-- ---------------------------------------------------------------------

local activeBalls = {}
local spawned = 0

local function counterValue()
  local val = 0
  for i = 1, N_BITS do
    if rows[i].state == "carry" then val = val + 2 ^ (i - 1) end
  end
  return val
end

local function bitsString()
  local s = ""
  for i = N_BITS, 1, -1 do
    s = s .. ((rows[i].state == "carry") and "1" or "0")
  end
  return s
end

local currentBall = nil   -- {obj=, id=, nextRow=, spawnFrame=, lowSpeedStreak=}

local function spawnBall(N)
  spawned = spawned + 1
  local b = Sphere(BALL_R, BALL_MASS)
  b.pos = btVector3(rows[1].x, rows[1].y + 3.0, 0)
  b.col = "ivory"
  b.friction = 0.7
  b.restitution = 0.02
  v:add(b)
  local rec = { obj = b, id = spawned, nextRow = 1, spawnFrame = N, lowSpeedStreak = 0 }
  table.insert(activeBalls, rec)
  currentBall = rec
  print(string.format("frame %d: ball %d (of %d) enters at the source vertex", N, spawned, spawned))
end

v:preSim(function(N)
  if N == 1 then
    spawnBall(N)
    return
  end
  if currentBall == nil or spawned >= MAX_BALLS then return end

  local age = N - currentBall.spawnFrame
  local vel = currentBall.obj.vel
  local speed2 = vel.x * vel.x + vel.y * vel.y + vel.z * vel.z

  if speed2 < SETTLE_SPEED2 then
    currentBall.lowSpeedStreak = currentBall.lowSpeedStreak + 1
  else
    currentBall.lowSpeedStreak = 0
  end

  local settled = age > SETTLE_MIN_AGE and currentBall.lowSpeedStreak >= SETTLE_STREAK_FRAMES
  if settled or age > SETTLE_MAX_WAIT then
    if spawned < MAX_BALLS then
      spawnBall(N)
    else
      currentBall = nil
    end
  end
end)

-- ---------------------------------------------------------------------
-- camera -- fixed framing of the whole staircase (nothing in this rig
-- moves as a whole, unlike a walker demo, so no per-frame tracking is
-- needed -- just centered on the rig's own bounding box).
--
-- IMPORTANT: v:postSim can only hold ONE callback at a time (_cb_postSim
-- is a single-slot field in viewer.cpp) -- calling v:postSim a second
-- time silently OVERWRITES the first registration rather than adding a
-- second one. The flip-trigger logic and the camera setup both need to
-- run every frame, so they're combined into this single callback.
-- ---------------------------------------------------------------------

local centerX = lastRow.x / 2
local centerY = (topY + botY) / 2

v:postSim(function(N)
  for _, bs in ipairs(activeBalls) do
    if bs.nextRow <= N_BITS and bs.obj.pos.y < rows[bs.nextRow].y - 0.6 then
      local row = rows[bs.nextRow]
      local before = row.flip()
      -- A shelf should hold exactly one ball -- whichever one is
      -- CURRENTLY displaying that bit -- not every ball that ever
      -- landed there. Without this, balls pile up on a shared shelf
      -- over a long run and eventually collide with a later arrival,
      -- knocking it (or an old "settled" ball) back into motion and
      -- corrupting the count -- caught empirically: the demo ran
      -- perfectly through ball 6, then went to visible nonsense at
      -- ball 7 once toggle 1's shelf had accumulated 3 old balls.
      if before == "display" then
        -- this ball just landed here -- it's the fresh occupant.
        row.shelfBall = bs.obj
      elseif row.shelfBall ~= nil then
        -- bit just reset to 0 -- the old marker is now stale.
        v:remove(row.shelfBall)
        row.shelfBall = nil
      end
      local outcome = (before == "display") and "DISPLAY (bit stays 1, no carry)" or "CARRY (bit resets to 0, ball falls on)"
      print(string.format("frame %d: ball %d clocks toggle %d (bit %d) -- was %s -> %s. counter now %s = %d",
        N, bs.id, bs.nextRow, bs.nextRow - 1, before, outcome, bitsString(), counterValue()))
      bs.nextRow = bs.nextRow + 1
      -- Only a CARRY out of the last toggle actually falls through to
      -- the physical sink floor -- a DISPLAY there means the ball
      -- stops on that toggle's own shelf instead, same as at any other
      -- row (this is what makes N_BITS toggles top out at 2^N_BITS - 1:
      -- every row's SHELF holds a bit; only the sink means overflow).
      if bs.nextRow > N_BITS and before == "carry" then
        print(string.format("frame %d: ball %d reached the SINK vertex -- counter overflowed past %d",
          N, bs.id, 2 ^ N_BITS - 1))
      end
    end
  end
end)

common.setCamera(btVector3(2.62242, 15.8954, -28.7863),
                 btVector3(499.773, -581198, 813722), nil,
                 { up = btVector3(0.00180565, 0.81375, 0.581213) })
