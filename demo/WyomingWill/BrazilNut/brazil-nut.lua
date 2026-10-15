--
-- The Brazil-Nut Effect -- Euler's Cabinet of Curiosities
--
-- Shake a jar of mixed nuts and the Brazil nuts come up to the top: the
-- biggest rise, though they're the heaviest. Here, three glass-fronted
-- boxes of beads (a layer one bead thick) are shaken up and down, seven
-- times a second, on a shaker table:
--
--   left    a big bead at the bottom, shaken gently (peak acceleration 0.8
--           g): the beads never leave the floor, and nothing happens
--   middle  the same, shaken hard (3 g): the big bead comes up within
--           seconds, and stays up -- three quarters of the time in the
--           bed's upper half
--   right   no big bead -- a coloured small one at the bottom, in the
--           middle -- shaken the same: it comes up too, but then goes down
--           again beside a wall, and round and round
--
-- Why: shaken hard, the bed leaves the floor for part of each shake and
-- lands again. Rubbing on the walls holds the beads beside them back, so
-- the beads go down along the walls and come up in the middle: the bed
-- turns over slowly, in two rolls. Anything in the middle comes up with it.
-- At the top, the small beads go down again in the narrow layer along the
-- walls; the big one is too big to follow them, so it stays up. (Knight,
-- Jaeger and Nagel, 1993: the big bead rises with the convection.)
--
-- Theory, checked as it goes: the box's floor accelerates downward at up
-- to Gamma g (Gamma = A w^2 / g, A the amplitude, w the shaking in radians
-- a second). Below Gamma = 1 the floor never drops away faster than the
-- beads fall, and the bed rides on it: the floor's push on it never less
-- than (1 - Gamma) of its weight. Above, a rigid bed would leave the floor
-- each shake when the floor's downward acceleration passes g, at a phase
-- of arcsin(1 / Gamma) into the upswing; the real bed is springy and
-- presses on longer. The console gives both (the push from how much the
-- heavy box is slowed), and the convection: how fast the beads in the
-- middle rise and those beside the walls fall.
--
-- THE BEADS: glass, 0.95 to 1.05 cm across (140 a box), the big one 3 cm
-- across; the boxes 15 cm wide inside. Shaken at 7 Hz: 4.1 mm (0.8 g),
-- 15.2 mm (3 g).
--
-- PHYSICS: Bullet: the beads spheres held to the plane of the box (a layer
-- one bead thick, between glass), friction 0.8 (the walls 1.0), little
-- bounce (0.1); each box a heavy body moved exactly as the shaker moves it.
-- 2400 physics steps a second.
--
-- Keys
--   R   pour them again (the big bead at the bottom)
--   Z   slow motion (1/4) <-> real time
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: BN_SPEED, BN_STEPS, BN_SEED, BN_HARD, BN_GENTLE (g),
-- BN_F (Hz), BN_POLY (the beads' spread in size), BN_MUB, BN_MUW, BN_E,
-- BN_LOG=file.csv.
--

local common = require "common"

local G = 981
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("hard", envnum("BN_HARD", 3.0), 1, 5, 0.1, "the middle and right boxes' peak acceleration, in g")
param("gentle", envnum("BN_GENTLE", 0.8), 0.2, 1.5, 0.1, "the left box's peak acceleration, in g")
param("speed", envnum("BN_SPEED", 1), 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
param("steps", envnum("BN_STEPS", 2400), 1200, 4800, 600, "physics steps per simulated second")

local STEP, NSTEPS, FRAME_DT = 1 / 2400, 40, 1 / 60
local function applyTiming()
  local speed = v:getParam("speed")
  NSTEPS = math.max(1, math.floor(v:getParam("steps") * speed / 60 + 0.5))
  FRAME_DT = speed / 60
  STEP = FRAME_DT / NSTEPS
  v.animationPeriod = 16
  common.setTiming(STEP, 0, STEP)
end

-- ---------------------------------------------------------------------
-- a pause at every start: one frame to put everything in place, then it
-- all stands still for HOLD_S seconds (2), so you see how it begins --
-- bpp's own physics step stopped too (a zero time step) -- and then it
-- carries on from there, exactly as if there had been no pause
-- ---------------------------------------------------------------------
local HOLD_FRAMES = math.floor(envnum("HOLD_S", 2) * 60 + 0.5)
local holdArm, holdLeft, holdNow = false, 0, false
local function holdStart() holdArm, holdLeft = true, 0 end
local function holdPre()            -- first thing before each step: true while it stands still
  if holdLeft > 0 then
    holdLeft = holdLeft - 1
    holdNow = true
    v.timeStep = 0
    return true
  end
  if holdNow then holdNow = false; applyTiming() end
  if holdArm then holdArm, holdLeft = false, HOLD_FRAMES end
  return false
end
applyTiming()
v.gravity = btVector3(0, -G, 0)
v:setSolverIterations(20)

local Q0 = btQuaternion(0, 0, 0, 1)
local function block(sx, sy, sz, x, y, z, col)
  local c = Cube(sx, sy, sz, 0)
  c.trans = btTransform(Q0, btVector3(x, y, z))
  c.col = col
  c.collides = false
  v:add(c)
  return c
end

-- ---------------------------------------------------------------------
-- the shaker table and the boxes
-- ---------------------------------------------------------------------
local TABLE_Y = 0
block(120, 3, 40, 0, TABLE_Y - 1.5, 0, "#7a4a24")
for _, x in ipairs({ -55, 55 }) do
  for _, z in ipairs({ -16, 16 }) do block(3, 72, 3, x, TABLE_Y - 3 - 36, z, "#4e2e15") end
end
local floor = Plane(0, 1, 0, TABLE_Y - 75, 300)
floor.col = "#3b3f45"
v:add(floor)

local F_HZ = envnum("BN_F", 7)
local MU_B, MU_W, REST = envnum("BN_MUB", 0.8), envnum("BN_MUW", 1.0), envnum("BN_E", 0.1)
local OMEGA = 2 * math.pi * F_HZ
local W_IN, H_IN = 15, 24                  -- inside the box
local WALL = 1.0
local R_S, R_B = 0.5, 1.5                  -- small and big beads' radii
local RHO_GLASS = 0.0025                   -- kg/cm^3
local M_S = RHO_GLASS * 4 / 3 * math.pi * R_S ^ 3
-- (the small beads vary a little, 0.85 to 1.15 of R_S across: all the same,
-- in a flat layer they'd stack like a honeycomb and lock)
local POLY = envnum("BN_POLY", 0.1)
local function smallR(i) return R_S * (1 - POLY / 2 + POLY * ((i * 37) % 100) / 99) end
local R_MAX = (1 + POLY / 2) * R_S
local M_B = RHO_GLASS * 4 / 3 * math.pi * R_B ^ 3
local N_S = 140
local BASE_Y = TABLE_Y + 8                 -- the boxes' floors, at rest
local BOXES = {
  { name = "Left, a big bead, shaken gently", short = "Left", x = -38, big = true, accel = "gentle" },
  { name = "Middle, a big bead, shaken hard", short = "Middle", x = 0, big = true, accel = "hard" },
  { name = "Right, no big bead: a coloured small one, shaken hard", short = "Right", x = 38, big = false, accel = "hard" },
}

local GLASS, FRAME_COL = "#26343a", "#5a3418"     -- (the glass at the back drawn dark; the front pane left out)
local function boxShape()
  local s = btCompoundShape(true)
  s:addChildShape(btTransform(Q0, btVector3(0, -WALL / 2, 0)), btBoxShape(btVector3(W_IN / 2 + WALL, WALL / 2, 2)))
  for _, side in ipairs({ -1, 1 }) do
    s:addChildShape(btTransform(Q0, btVector3(side * (W_IN / 2 + WALL / 2), H_IN / 2, 0)),
                    btBoxShape(btVector3(WALL / 2, H_IN / 2, 2)))
  end
  return s
end
local BIGM = 1e4
for _, bx in ipairs(BOXES) do
  -- (the box: drawn as its parts, which follow the body)
  local body = btRigidBody(BIGM, btDefaultMotionState(btTransform(Q0, btVector3(bx.x, BASE_Y, 0))), boxShape(),
                           btVector3(1e6, 1e6, 1e6))
  local holder = Sphere(0.05, 0)
  holder.body = body
  holder.col = FRAME_COL
  v:add(holder)
  body:setActivationState(4)
  body:setFlags(1)
  body:setGravity(btVector3(0, 0, 0))
  body:setLinearFactor(btVector3(0, 1, 0))
  body:setAngularFactor(btVector3(0, 0, 0))
  body:setFriction(MU_W)
  body:setRestitution(REST)
  bx.body, bx.holder = body, holder
  bx.parts = {
    { block(W_IN + 2 * WALL, WALL, 3, 0, 0, 0, FRAME_COL), 0, -WALL / 2, 0 },
    { block(WALL, H_IN, 3, 0, 0, 0, FRAME_COL), -(W_IN / 2 + WALL / 2), H_IN / 2, 0 },
    { block(WALL, H_IN, 3, 0, 0, 0, FRAME_COL), W_IN / 2 + WALL / 2, H_IN / 2, 0 },
    { block(W_IN, H_IN, 0.1, 0, 0, 0, GLASS), 0, H_IN / 2, -1.3 },
  }
  bx.parts[4][1].col = GLASS
  -- the shaker's post under it
  bx.post = block(3, BASE_Y - WALL - TABLE_Y, 3, bx.x, 0, 0, "#3a3f46")
end

-- the beads
local BEAD_COLS = { "#d8cfae", "#cfc5a0", "#e2dab9" }
for _, bx in ipairs(BOXES) do
  bx.beads = {}
  for i = 1, N_S do
    local r = smallR(i)
    local s = Sphere(r, RHO_GLASS * 4 / 3 * math.pi * r ^ 3)
    s.col = BEAD_COLS[i % 3 + 1]
    v:add(s)
    s.body:setActivationState(4)
    s.body:setFriction(MU_B)
    s.body:setRestitution(REST)
    s.body:setLinearFactor(btVector3(1, 1, 0))
    s.body:setAngularFactor(btVector3(0, 0, 1))
    bx.beads[i] = s
  end
  local s = Sphere(bx.big and R_B or R_S, bx.big and M_B or M_S)
  s.col = bx.big and "#7a4a24" or "#c0392b"
  v:add(s)
  s.body:setActivationState(4)
  s.body:setFriction(MU_B)
  s.body:setRestitution(REST)
  s.body:setLinearFactor(btVector3(1, 1, 0))
  s.body:setAngularFactor(btVector3(0, 0, 1))
  bx.special = s
end

-- ---------------------------------------------------------------------
-- pouring, and shaking
-- ---------------------------------------------------------------------
local t = 0
local reportedPhase, reportedConv = false, false
local seed = envnum("BN_SEED", 7)
local function rnd()
  -- (a little random number generator of its own, so each pour is the same)
  seed = (seed * 1103515245 + 12345) % 2147483648
  return seed / 2147483648
end
local function amplitude(bx) return v:getParam(bx.accel) * G / (OMEGA * OMEGA) end
local function place(o, x, y)
  local tr = btTransform(Q0, btVector3(x, y, 0))
  o.body:setCenterOfMassTransform(tr)
  o.trans = tr
  o.body:setLinearVelocity(btVector3(0, 0, 0))
  o.body:setAngularVelocity(btVector3(0, 0, 0))
end
local function pour()
  holdStart()
  t = 0
  print(string.format("\n--- poured: %d beads a box, shaken at %d Hz; left %.1f g (%.1f mm), middle and right %.1f g (%.1f mm) ---",
                      N_S, F_HZ, v:getParam("gentle"), amplitude(BOXES[1]) * 10, v:getParam("hard"), amplitude(BOXES[2]) * 10))
  for _, bx in ipairs(BOXES) do
    place(bx.holder, bx.x, BASE_Y)
    local x0 = bx.x
    -- the special bead at the bottom in the middle, the rest in loose rows
    -- above and round it
    local rs = bx.big and R_B or R_S
    place(bx.special, x0, BASE_Y + rs + 0.01)
    local k = 0
    local row = 0
    while k < N_S do
      local y = BASE_Y + R_MAX + 0.02 + row * 2.02 * R_MAX
      local nper = math.floor(W_IN / (2.1 * R_MAX))
      for c = 0, nper - 1 do
        if k >= N_S then break end
        local x = x0 - W_IN / 2 + R_MAX + 0.05 + c * 2.1 * R_MAX + (row % 2) * 0.5 * R_MAX + (rnd() - 0.5) * 0.05
        if x < x0 + W_IN / 2 - R_MAX - 0.02 and (math.abs(x - x0) > rs + R_MAX + 0.05 or y > BASE_Y + 2 * rs + R_MAX + 0.05) then
          k = k + 1
          place(bx.beads[k], x, y)
        end
      end
      row = row + 1
    end
    bx.reached, bx.upN, bx.upHalf = nil, 0, 0
    bx.conv = { midSum = 0, midN = 0, wallSum = 0, wallN = 0, upX = 0, upN = 0, downX = 0, downN = 0, trips = 0, zone = "bottom" }
    bx.lastSample = nil
    bx.pushSum, bx.pushN = {}, {}
  end
  for _, bx in ipairs(BOXES) do
    local g = v:getParam(bx.accel)
    print(string.format("  %-6s Gamma %.1f: %s", bx.short, g,
                        g < 1 and "below 1 -- the bed should never leave the floor"
                        or string.format("the bed should leave the floor %.1f degrees into each upswing (arcsin 1/Gamma)",
                                         math.deg(math.asin(1 / g)))))
  end
  -- let them settle a moment before the shaking starts
  t = -0.5
  reportedPhase, reportedConv = false, false
end

-- the box's height: A sin(w t), from t = 0
local function boxY(bx, tt) return BASE_Y + (tt > 0 and amplitude(bx) * math.sin(OMEGA * tt) or 0) end
local function boxV(bx, tt) return tt > 0 and amplitude(bx) * OMEGA * math.cos(OMEGA * tt) or 0 end

-- the bed's bottom: is it off the floor? (the lowest beads all clear of it)
local function bedOff(bx, floorY)
  local lowest = 1e9
  for _, s in ipairs(bx.beads) do
    local _, y = getPosXYZ(s)
    if y < lowest then lowest = y end
  end
  local _, ys = getPosXYZ(bx.special)
  local rs = bx.big and R_B or R_S
  lowest = math.min(lowest, ys - rs + R_S)
  return lowest - R_S - floorY
end

local W_BED = 0
for i = 1, N_S do W_BED = W_BED + RHO_GLASS * 4 / 3 * math.pi * smallR(i) ^ 3 * G end
-- (the bed's weight, above: for the box's push)
v:preSim(function(N_)
  if holdPre() then return end
  for k = 1, NSTEPS do
    local tt = t + (k - 1) * STEP
    for _, bx in ipairs(BOXES) do
      -- the shaker: the box exactly where it should be, at the speed it
      -- should have (for its contacts) -- set before each step
      local tr = btTransform(Q0, btVector3(bx.x, boxY(bx, tt), 0))
      bx.body:setCenterOfMassTransform(tr)
      bx.vset = boxV(bx, tt)
      bx.body:setLinearVelocity(btVector3(0, bx.vset, 0))
    end
    if k < NSTEPS then
      v:stepSimulation(STEP, 0, STEP)
      -- the beads' push on the box over that step, from how much it slowed
      -- the (heavy) box: when it drops to nothing, the bed is off the floor.
      -- Watched in shakes 5 to 12, once it has settled.
      local cyc = math.floor(tt * F_HZ)
      if cyc >= 4 and cyc < 12 then
        for _, bx in ipairs(BOXES) do
          local _, vy = getVelXYZ(bx.holder)
          local push = (bx.vset - vy) * BIGM / STEP
          -- (summed by the phase of the shake, in 2-degree bins)
          local bin = math.floor((tt * F_HZ - cyc) * 180) + 1
          bx.pushSum[bin] = (bx.pushSum[bin] or 0) + push
          bx.pushN[bin] = (bx.pushN[bin] or 0) + 1
        end
      end
    end
  end
end)

-- after every frame: draw the boxes, report
local function surface(bx)
  -- the bed's top: the mean height of its highest tenth
  local ys = {}
  for i, s in ipairs(bx.beads) do
    local _, y = getPosXYZ(s)
    ys[i] = y
  end
  table.sort(ys)
  local sum, n = 0, 0
  for i = math.floor(#ys * 0.9), #ys do sum, n = sum + ys[i], n + 1 end
  return sum / n + R_S
end
local LOGF = os.getenv("BN_LOG") and io.open(os.getenv("BN_LOG"), "w")
if LOGF then LOGF:write("t,box,special_height,surface\n") end
v:postSim(function(N_)
  if holdNow then return end
  t = t + FRAME_DT
  for k, bx in ipairs(BOXES) do
    local by = boxY(bx, t)
    for _, p in ipairs(bx.parts) do
      p[1].trans = btTransform(Q0, btVector3(bx.x + p[2], by + p[3], p[4]))
    end
    bx.post.trans = btTransform(Q0, btVector3(bx.x, (by - WALL + TABLE_Y) / 2, 0))
    local _, ys = getPosXYZ(bx.special)
    local rs = bx.big and R_B or R_S
    local top = surface(bx)
    -- at the top: its top level with the bed's
    if t > 0 and not bx.reached and ys + rs > top - 0.3 then
      bx.reached = t
      print(string.format("  %-6s the %s bead reaches the top at %.1f s (%d shakes), having risen %.1f cm",
                          bx.short, bx.big and "big" or "coloured", t, math.floor(t * F_HZ), ys - (BASE_Y + by - BASE_Y) - rs))
    end
    -- (after reaching the top: how much of the time it's in the bed's upper half)
    if bx.reached and bx.big then
      bx.upN = (bx.upN or 0) + 1
      if ys - by > (top - by) / 2 then bx.upHalf = (bx.upHalf or 0) + 1 end
    end
    -- the convection: every half second, each bead's rise or fall, by where
    -- it is across the box (the middle 6 cm, or within 2.5 cm of a wall),
    -- from 5 s in; and the special bead's trips round
    if t > 5 and (not bx.lastSample or t - bx.lastSample.t >= 0.5) then
      local cur = {}
      for i, s_ in ipairs(bx.beads) do
        local x_, y_ = getPosXYZ(s_)
        cur[i] = { x_, y_ - by }                 -- (its height in the box)
      end
      local C = bx.conv
      if bx.lastSample then
        for i, p0 in ipairs(bx.lastSample.p) do
          local dx_ = math.abs(p0[1] - bx.x)
          local dy = (cur[i][2] - p0[2]) / (t - bx.lastSample.t)
          if dx_ < 3 then C.midSum, C.midN = C.midSum + dy, C.midN + 1
          elseif dx_ > W_IN / 2 - 2.5 then C.wallSum, C.wallN = C.wallSum + dy, C.wallN + 1 end
        end
        if not bx.big then
          local h = ys - by - rs
          local depth = top - by
          local sdx = math.abs(getPosXYZ(bx.special) - bx.x)
          local dyS = ys - bx.lastSample.ys
          if dyS > 0 then C.upX, C.upN = C.upX + sdx, C.upN + 1 else C.downX, C.downN = C.downX + sdx, C.downN + 1 end
          if h > depth * 2 / 3 and C.zone == "bottom" then C.zone = "top" end
          if h < depth / 3 and C.zone == "top" then C.zone, C.trips = "bottom", C.trips + 1 end
        end
      end
      bx.lastSample = { t = t, p = cur, ys = ys }
    end
    if LOGF and N_ % 6 == 0 then
      LOGF:write(string.format("%.3f,%d,%.3f,%.3f\n", t, k, ys - by, top - by))
    end
  end
  if not reportedPhase and t > 1.25 then
    reportedPhase = true
    for _, bx in ipairs(BOXES) do
      -- the floor's push through the shake, averaged over shakes 5 to 12:
      -- the first phase in the upswing where it falls below a tenth of the
      -- bed's weight (a rigid bed's: W (1 - Gamma sin(phase)))
      local g = v:getParam(bx.accel)
      local off, least = nil, 1e9
      for bin = 1, 45 do
        if bx.pushN[bin] then
          local p = bx.pushSum[bin] / bx.pushN[bin] / W_BED
          least = math.min(least, p)
          if not off and p < 0.1 then off = (bin - 1) * 2 end
        end
      end
      if not off then
        print(string.format("  %-6s Gamma %.1f: the bed never left the floor (the floor's push never less than %.2f of its weight; a rigid bed's: %.2f)",
                            bx.short, g, least, 1 - g))
      else
        print(string.format("  %-6s Gamma %.1f: the bed leaves the floor %d to %d degrees into the upswing (a rigid bed: arcsin 1/Gamma = %.1f;" ..
                            "\n         the real one is springy, squeezed by its landing, and presses on a little longer)",
                            bx.short, g, off, off + 2, g > 1 and math.deg(math.asin(1 / g)) or 0))
      end
    end
  end
  -- a minute in: the convection
  if not reportedConv and t > 60 then
    reportedConv = true
    for _, bx in ipairs(BOXES) do
      local C = bx.conv
      if C.midN > 0 and C.wallN > 0 and v:getParam(bx.accel) > 1 then
        print(string.format("  %-6s from 5 s to a minute: beads in the middle rising %.1f mm/s on average, beside the walls %s %.1f mm/s",
                            bx.short, C.midSum / C.midN * 10, C.wallSum < 0 and "falling" or "rising", math.abs(C.wallSum / C.wallN) * 10))
      end
      if bx.big and bx.reached and bx.upN > 0 then
        print(string.format("  %-6s the big bead, since reaching the top, has been in the bed's upper half %.0f%% of the time", bx.short,
                            bx.upHalf / bx.upN * 100))
      elseif not bx.big and C.upN > 0 and C.downN > 0 then
        print(string.format("  %-6s the coloured bead has gone round %d times: going up it was %.1f cm from the middle on average, going down %.1f cm (the walls are %.1f cm out)",
                            bx.short, C.trips, C.upX / C.upN, C.downX / C.downN, W_IN / 2))
      end
    end
  end
  -- every pour runs a minute and a half
  if t > 90 then pour() end
end)

-- ---------------------------------------------------------------------
-- keys, sliders, help
-- ---------------------------------------------------------------------
common.setCamera(btVector3(0, 24, 92), btVector3(0, 18, 0))
v:addShortcut("R", function(N_) pour() end)
v:addShortcut("Z", function(N_)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N_, name, value)
  if name == "speed" or name == "steps" then applyTiming() end
end)
v:setHelpText(table.concat({
  "The Brazil-nut effect (Euler's Cabinet of Curiosities)",
  "",
  "Three boxes of beads shaken up and down seven times a second.",
  "Left:   a big bead, shaken gently (0.8 g) -- nothing happens",
  "Middle: a big bead, shaken hard (3 g) -- it comes up, stays up",
  "Right:  a coloured small bead, shaken hard -- it goes round:",
  "        the bed turns over, up the middle, down by the walls",
  "",
  "R   pour them again",
  "Z   slow motion (1/4) <-> real time",
  "",
  "Sliders: hard, gentle (peak acceleration, g), speed, steps.",
}, "\n"))
local KEYS = {}
if v.onHover then
  for _, bx in ipairs(BOXES) do KEYS[objectKey(bx.special)] = bx end
  v:onHover(function(N_, obj, x, y, z)
    local bx = KEYS[objectKey(obj)]
    if not bx then return nil end
    local _, ys = getPosXYZ(bx.special)
    return string.format("%s\nthe %s bead %.1f cm above the floor; the bed %.1f cm deep", bx.name,
                         bx.big and "big" or "coloured", ys - boxY(bx, t) - (bx.big and R_B or R_S), surface(bx) - boxY(bx, t))
  end)
end

pour()
