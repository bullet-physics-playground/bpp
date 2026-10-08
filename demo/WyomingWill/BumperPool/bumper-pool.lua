--
-- BUMPER POOL -- the game of bumper pool for the Bullet Physics Playground:
-- you (red) against the computer (white), or two players taking turns.
-- Bullet does the balls, the cushions and the bumpers; you work the cue
-- from the keyboard.
--
-- THE GAME: each side has five balls, one of them marked with a spot of
-- the other colour. Red's balls start around the white cup and are played
-- into the red cup at the far end; white's the other way round. There is
-- no cue ball: you shoot your own balls directly, any one you like, but
-- your marked ball must go in first. Sink one of yours in your cup and you
-- shoot again; otherwise it's the other side's turn. The first to sink all
-- five wins.
--
-- THE OPENING: both marked balls are shot at the same moment. Each must
-- bank off a side cushion first. Whoever sinks his, or finishes nearer his
-- cup, has the first turn.
--
-- FOULS give the other side two of its own balls, dropped straight into
-- its cup: sinking another of your balls before your marked ball, sinking
-- one of yours in the other cup (it is spotted back; if it was your last
-- ball, you lose the game), jumping a ball over a bumper or ball, or
-- knocking a ball off the table (the other side places it: yours back
-- where you started, theirs in front of their cup).
--
-- KEYS (click the 3D view first so it has keyboard focus; the Shortcuts
-- pane shows them too, with the score):
--   Tab / X  Z       choose the next / previous of your balls
--   Left / Right     aim: a tap turns 0.25 degrees; hold to swing
--   ,  /  .          fine aim: a tap turns 0.02 degrees
--   Up / Down        force (1% a tap; hold to slide)
--   W / S            hit the ball higher (follow) or lower (draw)
--   A / D            hit it left or right of centre (side spin)
--   C                back to a centre hit
--   E / Q            raise / lower the back of the cue
--   Space / Return   shoot
--   G                aiming guide: to the first cushion or bumper, the
--                    whole path, or off
--   V / B / T        cameras: your end of the table, behind the cue,
--                    overhead
--   N or R           new game
--   O                white: the computer, or a second player
--   L                the computer's level: 1 easy, 2 medium, 3 hard
--   P                the computer plays red too (P again to take over)
--
-- UNITS: centimetres, seconds, kilograms. The table's long axis is X (the
-- white cup, where red starts, at -X), across it is Z, up is Y. The
-- playing surface is 121.9 x 81.3 cm (48 x 32 inches) between the cushion
-- noses; balls are 57.15 mm.
--
-- FILES
--   bumper-pool.lua        this table
--   bumper-pool-meshes/    the cue and the marked balls' spots
--   bumper-pool-sounds/    sound effects; missing ones are skipped
--
-- Needs bpp with the v:onKey() keyboard hook; v:playSound(id, volume) and
-- the objects' `collides` property are used when present (see the Pool
-- Table's README).
--

local common = require "common"

local SOUND_DIR = "bumper-pool-sounds/"
local MESH_DIR = "bumper-pool-meshes/"
local PREFS_PREFIX = "bumper-pool/"

-- ---------------------------------------------------------------------
-- dimensions and physics
-- ---------------------------------------------------------------------

local K = {
  R = 2.8575,            -- ball radius (2 1/4 inch balls)
  MASS = 0.17,
  HL = 60.96, HW = 40.64, -- half the playing surface (cushion nose to nose)
  G = 981,
  FRAME = 1 / 60,
  CUSHION_T = 4.0,       -- nose to rail
  RAIL_W = 10,           -- the wooden rail's width
  RAIL_H = 5.0,          -- its top
  VMAX = 600,            -- ball speed at full force (a short table, a short cue)
  ROLL_DECEL = 10,       -- rolling resistance of the cloth, cm/s^2 (about 1% of g)
  SPIN_DECEL = 10,       -- side spin dies away at this many rad/s^2
  STOP_V = 0.8,          -- slower than this (cm/s) and not spinning: stopped
  MAX_TIP = 0.5,         -- furthest the tip may be off centre, x ball radius
  STROKE_FRAMES = 5,     -- the cue's forward stroke
  JUMP_MIN = 260,        -- a stroke driving the ball down faster than this
                         -- (cm/s) makes it jump off the cloth...
  JUMP_E = 0.70,         -- ...rising at this fraction of the excess
  LAND_E = 0.5,          -- a falling ball bounces off the cloth at this
  LAND_MIN = 40,         -- fraction of its speed, if it lands faster than this
  CUP_IN = 6.0,          -- a cup's centre, from the end cushion's nose
  CUP_R = 4.3,           -- the hole's radius
  RB = 3.0,              -- a bumper's rubber ring (radius)
  BUMPER_H = 7.0,        -- and its height
  JUMP_FOUL = 1.2,       -- a ball rising this far off the cloth has jumped
}
K.D = 2 * K.R
K.NOSE_H = 0.635 * K.D                      -- cushion nose height
K.NOSE_TILT = math.asin((K.NOSE_H - K.R) / K.R)   -- its contact angle
K.RAIL_IN_X = K.HL + K.CUSHION_T            -- rail's inner edge
K.RAIL_IN_Z = K.HW + K.CUSHION_T
K.OUT_X = K.RAIL_IN_X + K.RAIL_W            -- table's outer edge
K.OUT_Z = K.RAIL_IN_Z + K.RAIL_W
-- A ball over a cup falls in if it would drop this far below the cloth
-- before reaching the far edge of the hole (then the far edge meets it
-- too low down for it to ride back up); faster, it skips over.
K.CUP_DROP = 0.3 * K.R

v.timeStep = K.FRAME
v.fixedTimeStep = 1 / 900
v.maxSubSteps = 30
v.gravity = btVector3(0, -K.G, 0)
if v.setSolverIterations then v:setSolverIterations(24) end
if v.animationPeriod then v.animationPeriod = 16 end
-- Add something that is only for show: it takes no part in collisions
-- (with bpp's `collides` property it isn't even tested; without, it's
-- tested but nothing bounces off it).
local CF_NO_CONTACT_RESPONSE = 4
local function addVisual(obj)
  local ok = pcall(function() obj.collides = false end)
  v:add(obj)
  if not ok then
    obj.body:setCollisionFlags(obj.body:getCollisionFlags() + CF_NO_CONTACT_RESPONSE)
  end
  return obj
end
local yAxis = btVector3(0, 1, 0)
local UPRIGHT = btQuaternion(btVector3(1, 0, 0), math.pi / 2)   -- cylinder axis up

-- ---------------------------------------------------------------------
-- the table
-- ---------------------------------------------------------------------

local COL = {
  cloth = "#1d5c9e", cushion = "#174d86", rail = "#5a2d12", apron = "#33190a",
  cup = "#050505", rim = "#b9bcc0", ring = "#e9e5da", cap = "#9ea3a8", line = "#dfe8f2",
}

-- A static box, `yaw` radians about Y.
local function box(x, y, z, sx, sy, sz, col, yaw)
  local c = Cube(sx, sy, sz, 0)
  c.trans = btTransform(btQuaternion(yAxis, yaw or 0), btVector3(x, y, z))
  c.col = col
  v:add(c)
  return c
end

-- A flat disc lying on a surface at height y (no collision response).
local function disc(x, y, z, r, col)
  local c = Cylinder(r, 0.1, 0)
  c.trans = btTransform(UPRIGHT, btVector3(x, y + 0.05, z))
  c.col = col
  addVisual(c)
  return c
end

-- A cushion: a rubber nose along (x1,z1)-(x2,z2), on the side away from
-- the point (awayX, awayZ). As on a real table the nose is a little above
-- the middle of the ball, so a ball driven into it is pressed down onto
-- the cloth instead of climbing the rubber.
local xAxis = btVector3(1, 0, 0)
local cushionLines = {}     -- every cushion's nose and bumper, for cushionBounce()
local function cushion(x1, z1, x2, z2, thick, awayX, awayZ)
  local dx, dz = x2 - x1, z2 - z1
  local len = math.sqrt(dx * dx + dz * dz)
  local nx, nz = -dz / len, dx / len
  local mx, mz = (x1 + x2) / 2, (z1 + z2) / 2
  if (awayX - mx) * nx + (awayZ - mz) * nz > 0 then nx, nz = -nx, -nz end
  local yaw = -math.atan2(dz, dx)
  if math.sin(yaw) * nx + math.cos(yaw) * nz < 0 then yaw = yaw + math.pi end
  local a = K.NOSE_TILT
  local H, noseY = 5.0, 1.7          -- box height; nose's height in the box
  local q = btQuaternion(yAxis, yaw) * btQuaternion(xAxis, -a)
  local offY = noseY * math.cos(a) - (thick / 2) * math.sin(a)
  local offU = -noseY * math.sin(a) - (thick / 2) * math.cos(a)
  local c = Cube(len, H, thick, 0)
  c.trans = btTransform(q, btVector3(mx - offU * nx, K.NOSE_H - offY, mz - offU * nz))
  c.col = COL.cushion
  c.friction = 0.8
  c.restitution = 0.86
  v:add(c)
  cushionLines[#cushionLines + 1] = { x1 = x1, z1 = z1, x2 = x2, z2 = z2, r = 0,
                                      kind = (x1 == x2) and "end" or "side" }
  return c
end

-- the cups: [1] red's, at +X (red shoots toward it from the -X end);
-- [2] white's, at -X
local CUPS = {
  { x = K.HL - K.CUP_IN, z = 0 },
  { x = -(K.HL - K.CUP_IN), z = 0 },
}
-- the bumpers: a cross of eight in the middle, two arms of two along
-- each axis, and two guarding each cup
local BUMPERS = {
  { 8, 0 }, { 18, 0 }, { -8, 0 }, { -18, 0 }, { 0, 8 }, { 0, 18 }, { 0, -8 }, { 0, -18 },
}
for _, c in ipairs(CUPS) do
  local s = c.x > 0 and 1 or -1
  BUMPERS[#BUMPERS + 1] = { c.x - s * 10, 10 }
  BUMPERS[#BUMPERS + 1] = { c.x - s * 10, -10 }
end

-- where each side's balls start: [1] the marked ball, in front of the
-- other side's cup; the other four either side of that cup
local MARKS = {}
for side = 1, 2 do
  local s = (side == 1) and -1 or 1          -- red starts at the -X end
  MARKS[side] = {
    { s * (K.HL - K.CUP_IN - 19), 0 },
    { s * (K.HL - 9), 17 }, { s * (K.HL - 9), -17 },
    { s * (K.HL - 9), 27 }, { s * (K.HL - 9), -27 },
  }
end

do
  local HL, HW = K.HL, K.HW
  -- the cloth (a thick slab, so a ball driven down hard can't pass
  -- through it) and the table below
  local cloth = box(0, -5, 0, 2 * K.RAIL_IN_X, 10, 2 * K.RAIL_IN_Z, COL.cloth)
  cloth.friction = 1.0
  cloth.restitution = 0.0
  box(0, -12, 0, 2 * K.OUT_X, 20, 2 * K.OUT_Z, COL.apron)
  for _, sx in ipairs({ -1, 1 }) do
    for _, sz in ipairs({ -1, 1 }) do
      box(sx * (K.OUT_X - 12), -52, sz * (K.OUT_Z - 12), 14, 60, 14, COL.apron)   -- legs
    end
  end
  -- the cushions, one on each side, meeting at the corners
  for _, sz in ipairs({ -1, 1 }) do
    cushion(-HL - K.CUSHION_T, sz * HW, HL + K.CUSHION_T, sz * HW, K.CUSHION_T, 0, 0)
  end
  for _, sx in ipairs({ -1, 1 }) do
    cushion(sx * HL, -HW, sx * HL, HW, K.CUSHION_T, 0, 0)
  end
  -- the wooden rails around it all
  for _, sz in ipairs({ -1, 1 }) do
    local r = box(0, K.RAIL_H / 2, sz * (K.RAIL_IN_Z + K.RAIL_W / 2), 2 * K.OUT_X, K.RAIL_H,
                  K.RAIL_W, COL.rail)
    r.restitution = 0.3
  end
  for _, sx in ipairs({ -1, 1 }) do
    local r = box(sx * (K.RAIL_IN_X + K.RAIL_W / 2), K.RAIL_H / 2, 0, K.RAIL_W, K.RAIL_H,
                  2 * K.RAIL_IN_Z, COL.rail)
    r.restitution = 0.3
  end
  -- the cups: a hole in the cloth with a metal rim
  for _, c in ipairs(CUPS) do
    disc(c.x, 0, c.z, K.CUP_R + 0.5, COL.rim)
    disc(c.x, 0.02, c.z, K.CUP_R, COL.cup)
  end
  -- the bumpers: a post with a rubber ring, and a cap
  for _, bp in ipairs(BUMPERS) do
    local c = Cylinder(K.RB, K.BUMPER_H, 0)
    c.trans = btTransform(UPRIGHT, btVector3(bp[1], K.BUMPER_H / 2, bp[2]))
    c.col = COL.ring
    c.friction = 0.4
    c.restitution = 0.8
    v:add(c)
    local cap = Cylinder(K.RB * 0.6, 1.4, 0)
    cap.trans = btTransform(UPRIGHT, btVector3(bp[1], K.BUMPER_H + 0.6, bp[2]))
    cap.col = COL.cap
    addVisual(cap)
    cushionLines[#cushionLines + 1] = { x1 = bp[1], z1 = bp[2], x2 = bp[1], z2 = bp[2],
                                        r = K.RB, kind = "bumper" }
  end
  -- the spots where the balls start
  for side = 1, 2 do
    for _, m in ipairs(MARKS[side]) do disc(m[1], 0, m[2], 0.5, COL.line) end
  end

  -- the ball trays along the far side, where sunk balls are shown: red's
  -- on the left, white's on the right
  local TZ = K.OUT_Z + 7
  local TL = 80
  box(0, -4, TZ, TL, 2, 8, COL.apron)
  box(0, -1, TZ + 4.5, TL, 8, 1, COL.apron)
  box(0, -3.5, TZ - 4.5, TL, 3, 1, COL.apron)
  box(-TL / 2 - 0.5, -1, TZ, 1, 8, 10, COL.apron)
  box(TL / 2 + 0.5, -1, TZ, 1, 8, 10, COL.apron)
  box(0, -1, TZ, 1, 8, 8, COL.apron)
  K.TRAY_Z, K.TRAY_Y = TZ, -3 + K.R
end

-- ---------------------------------------------------------------------
-- the balls: [1..5] red, [6..10] white; 1 and 6 are the marked balls
-- ---------------------------------------------------------------------

local NB = 10
local MARKED = { 1, 6 }
local SIDE_COL = { "#c8102e", "#f2efe6" }
local SIDE_NAME = { "red", "white" }

-- A mesh that follows a ball around (the marked balls' spots), or a cue part.
local function marking(file, col)
  local ok, m = pcall(function() return Mesh(MESH_DIR .. file, 0, false) end)
  if not ok or not m then return nil end
  m.col = col
  m.pov_export = false
  addVisual(m)
  return m
end

local balls = {}
for n = 1, NB do
  local side = (n <= 5) and 1 or 2
  local s = Sphere(K.R, K.MASS)
  s.col = SIDE_COL[side]
  s.friction = 0.2
  s.restitution = 0.97
  s.damp_lin = 0
  s.damp_ang = 0
  v:add(s)
  s.body:setActivationState(4)          -- never goes to sleep
  s.body:setCcdMotionThreshold(K.R * 0.5)
  s.body:setCcdSweptSphereRadius(K.R * 0.9)
  local marked = (n == MARKED[side])
  local mark = marked and marking("ball-spots.obj", SIDE_COL[3 - side]) or nil
  balls[n] = { n = n, obj = s, mark = mark, onTable = true, vx = 0, vz = 0, side = side,
               marked = marked, home = (n - 1) % 5 + 1 }
end
-- A ball's position, velocity and spin as plain numbers. A bpp with
-- getPosXYZ and the rest reads and sets them without making a new vector
-- each time: read for every ball at every step, those vectors were
-- thousands a second of garbage, and sweeping them up held everything up
-- now and then. (An older bpp: through the vectors, as before.)
local posXYZ = getPosXYZ or function(o) local p = o.pos; return p.x, p.y, p.z end
local velXYZ = getVelXYZ or function(o) local p = o.vel; return p.x, p.y, p.z end
local spinXYZ = getAngVelXYZ or function(o) local w = o.body:getAngularVelocity(); return w.x, w.y, w.z end
local setVel = setVelXYZ or function(o, x, y, z) o.body:setLinearVelocity(btVector3(x, y, z)) end
local setSpin = setAngVelXYZ or function(o, x, y, z) o.body:setAngularVelocity(btVector3(x, y, z)) end
local copyTransTo = copyTrans or function(a, b) a.trans = b.trans end

local function syncMark(b)
  if b.mark then copyTransTo(b.mark, b.obj) end
end

-- a random orientation, so the spots don't all line up
local function randomRot()
  local u1, u2, u3 = math.random(), math.random(), math.random()
  local a, c = math.sqrt(1 - u1), math.sqrt(u1)
  return btQuaternion(a * math.sin(2 * math.pi * u2), a * math.cos(2 * math.pi * u2),
                      c * math.sin(2 * math.pi * u3), c * math.cos(2 * math.pi * u3))
end

-- Put a ball at (x, z) on the cloth (or at height y), at rest.
local function placeBall(b, x, z, y, rot)
  b.obj.trans = btTransform(rot or b.obj.trans:getRotation(), btVector3(x, y or K.R, z))
  b.obj.body:setLinearVelocity(btVector3(0, 0, 0))
  b.obj.body:setAngularVelocity(btVector3(0, 0, 0))
  b.vx, b.vz, b.vy, b.railFrames, b.holeT = 0, 0, 0, 0, 0
  syncMark(b)
end

-- (while the computer is thinking, the balls are still and their positions
-- are read once, into frozenXZ: see "thinking a little at a time")
local frozenXZ = nil
local function ballXZ(b)
  local f = frozenXZ and frozenXZ[b]
  if f then return f[1], f[2] end
  local x, _, z = posXYZ(b.obj)
  return x, z
end
local function ballXYZ(b)
  local f = frozenXZ and frozenXZ[b]
  if f then return f[1], f[3], f[2] end
  return posXYZ(b.obj)
end

-- the look of a ball dropping into a cup: a copy of it that sinks into
-- the hole (the real ball goes straight to the tray)
local sinkers = {}
for c = 1, 2 do
  local g = Sphere(K.R, 0)
  g.pos = btVector3(0, -150, 0)
  g.pov_export = false
  addVisual(g)
  sinkers[c] = { obj = g, frames = -1 }
end

-- the ring under the ball you're about to play
local selector = disc(0, -150, 0, K.R + 1.0, "#ffd400")
local function showSelector(b)
  if b then
    local x, z = ballXZ(b)
    selector.trans = btTransform(UPRIGHT, btVector3(x, 0.07, z))
  else
    selector.pos = btVector3(0, -150, 0)
  end
end

-- ---------------------------------------------------------------------
-- sounds: optional files in SOUND_DIR; missing ones are skipped
-- ---------------------------------------------------------------------

local SOUNDS = {
  cue = "cue_hit.wav",          -- the tip strikes a ball
  ball = "ball_hit.wav",        -- two balls click (played softer for gentle hits)
  cushion = "cushion.wav",      -- a ball hits a cushion
  bumper = "bumper.wav",        -- a ball hits a bumper
  pocket = "pocket.wav",        -- a ball drops into a cup
  foul = "scratch.wav",         -- a foul
  rack = "rack.wav",            -- the balls are set up
  win = "table_cleared.wav",    -- the game is won
}
local soundIds = {}
do
  local found, missing = 0, {}
  for event, file in pairs(SOUNDS) do
    local f = io.open(SOUND_DIR .. file, "rb")
    if f then
      f:close()
      local id = v.loadSound and v:loadSound(SOUND_DIR .. file) or -1
      if id >= 0 then soundIds[event] = id; found = found + 1 end
    else
      missing[#missing + 1] = file
    end
  end
  table.sort(missing)
  if #missing > 0 then
    print(string.format("Sounds: %d loaded; not found in %s: %s", found, SOUND_DIR,
                        table.concat(missing, ", ")))
  end
end

local function playSound(event, volume)
  if TF and TF.soundLog then TF.soundLog[#TF.soundLog + 1] = { event, volume or 1 } end
  local id = soundIds[event]
  if not id then return end
  if volume then
    local ok = pcall(function() v:playSound(id, volume) end)
    if ok then return end
  end
  v:playSound(id)
end

-- ---------------------------------------------------------------------
-- the scoreboard: seven-segment digits on a panel past the red cup,
-- facing red's end of the table
-- ---------------------------------------------------------------------

local board = {}
local CHARS = {
  ["0"] = 63, ["1"] = 6, ["2"] = 91, ["3"] = 79, ["4"] = 102, ["5"] = 109,
  ["6"] = 125, ["7"] = 7, ["8"] = 127, ["9"] = 111,
  A = 119, B = 124, C = 57, D = 94, E = 121, F = 113, G = 61, H = 118, I = 48,
  J = 30, L = 56, N = 84, O = 63, P = 115, R = 80, S = 109, T = 120, U = 62,
  V = 62, Y = 110, ["-"] = 64, [" "] = 0,
}
do
  local SC = 0.8                     -- everything on the panel, smaller than the pool table's
  local PX = K.OUT_X + 36            -- the panel's face
  local Y0 = 10 - 14 * SC
  local function Y(y) return Y0 + y * SC end
  local panel = Cube(1, 59 * SC, 124 * SC, 0)
  panel.pos = btVector3(PX + 0.5, Y(43.5), 0)
  panel.col = "#101418"
  v:add(panel)
  local postH = Y(14) + 30
  local post1 = Cube(3, postH, 3, 0); post1.pos = btVector3(PX + 1.5, Y(14) - postH / 2, -45); post1.col = "#202428"
  local post2 = Cube(3, postH, 3, 0); post2.pos = btVector3(PX + 1.5, Y(14) - postH / 2, 45); post2.col = "#202428"
  v:add(post1); v:add(post2)
  local BITS = { 1, 2, 4, 8, 16, 32, 64 }

  -- A row of digits starting at z0 (left, as the player sees it).
  local function digits(z0, y, count, scale, onCol, offCol, showOff)
    scale = scale * SC
    local W, H, T = 1.9 * scale, 3.2 * scale, 0.32 * scale
    local pitch = 3.0 * scale
    local segs = {   -- a..g: {dz, dy, width, height}
      { 0, H / 2, W - T, T }, { W / 2, H / 4, T, H / 2 - T }, { W / 2, -H / 4, T, H / 2 - T },
      { 0, -H / 2, W - T, T }, { -W / 2, -H / 4, T, H / 2 - T }, { -W / 2, H / 4, T, H / 2 - T },
      { 0, 0, W - T, T },
    }
    local d = { digits = {} }
    for k = 1, count do
      local z = z0 * SC + (k - 1) * pitch
      local cubes = {}
      for s, g in ipairs(segs) do
        local c = Cube(0.3, g[4], g[3], 0)
        c.pos = btVector3(PX - 0.2, Y(y) + g[2], z + g[1])
        c.col = offCol
        c.pov_export = false
        if showOff then v:add(c) end
        cubes[s] = { obj = c, added = showOff, on = false }
      end
      d.digits[k] = cubes
    end
    d.set = function(text, right)
      text = tostring(text):upper()
      if #text > count then text = text:sub(-count) end
      if right then text = string.rep(" ", count - #text) .. text end
      for k = 1, count do
        local bits = CHARS[text:sub(k, k)] or 0
        for s, seg in ipairs(d.digits[k]) do
          local on = bits % (2 * BITS[s]) >= BITS[s]
          if on ~= seg.on then
            if not showOff and on and not seg.added then v:add(seg.obj); seg.added = true end
            seg.obj.col = on and onCol or offCol
            seg.on = on
          end
        end
      end
    end
    return d
  end

  local LABEL, LABEL_OFF, LED, LED_OFF = "#d9d9d9", "#101418", "#ff6a00", "#2a1408"
  -- each side: a lamp (lit on its turn) and the balls it has still to sink
  board.lamps = {}
  local LAMP = { { on = "#ff2a2a", off = "#3a0d0d" }, { on = "#ffffff", off = "#3a3a3a" } }
  for side = 1, 2 do
    local c = Cylinder(3.4 * SC, 0.3, 0)
    c.trans = btTransform(btQuaternion(yAxis, math.pi / 2),
                          btVector3(PX - 0.2, Y(65.5), (side == 1 and -52 or -24) * SC))
    c.col = LAMP[side].off
    v:add(c)
    board.lamps[side] = { obj = c, on = LAMP[side].on, off = LAMP[side].off, lit = false }
  end
  board.left1 = digits(-44, 65.5, 1, 2.2, LED, LED_OFF, true)
  board.left2 = digits(-16, 65.5, 1, 2.2, LED, LED_OFF, true)
  digits(-4, 66, 5, 1.1, LABEL, LABEL_OFF, false).set("SCORE")
  board.wins = digits(16, 65.5, 5, 2.2, LED, LED_OFF, true)
  board.message = digits(-54, 49, 12, 1.6, "#7cfc00", "#16240a", true)
  board.setLamps = function(which)
    for side, l in ipairs(board.lamps) do
      local lit = (which == side)
      if lit ~= l.lit then l.obj.col = lit and l.on or l.off; l.lit = lit end
    end
  end

  -- force: a bar of 20 lamps; spin: where the tip will strike the ball
  digits(-57, 33, 5, 1.1, LABEL, LABEL_OFF, false).set("FORCE")
  board.force = {}
  for i = 1, 20 do
    local c = Cube(0.3, 3.2 * SC, 2.0 * SC, 0)
    c.pos = btVector3(PX - 0.2, Y(33), (-38 + (i - 1) * 2.6) * SC)
    c.col = "#1a1a1a"
    v:add(c)
    local on = i <= 12 and "#39d353" or (i <= 17 and "#ffd400" or "#ff3b30")
    board.force[i] = { obj = c, on = on, lit = false }
  end
  local face = Cylinder(6 * SC, 0.3, 0)
  face.trans = btTransform(btQuaternion(yAxis, math.pi / 2), btVector3(PX - 0.2, Y(36), 42 * SC))
  face.col = "#f2efe6"
  v:add(face)
  local dot = Cylinder(1.0 * SC, 0.3, 0)
  dot.col = "#1d5c9e"
  v:add(dot)
  board.spinDot = function(sx, sy)
    dot.trans = btTransform(btQuaternion(yAxis, math.pi / 2),
                            btVector3(PX - 0.5, Y(36) + sy * 6 * SC * K.MAX_TIP, (42 + sx * 6 * K.MAX_TIP) * SC))
  end
  board.spinDot(0, 0)
  board.setForce = function(p)
    local n = math.floor(p * 20 + 0.5)
    for i, s in ipairs(board.force) do
      local lit = i <= n
      if lit ~= s.lit then s.obj.col = lit and s.on or "#1a1a1a"; s.lit = lit end
    end
  end
  -- the computer's level
  digits(-57, 19, 5, 1.1, LABEL, LABEL_OFF, false).set("LEVEL")
  board.level = digits(-38, 19, 1, 1.6, LED, LED_OFF, true)
end

-- ---------------------------------------------------------------------
-- the cue stick (for show: it has no collision; the shot itself is an
-- impulse on the ball where the tip meets it)
-- ---------------------------------------------------------------------

local cue = { parts = {} }
do
  local PARTS = {
    { "cue-tip.obj", "#2f6db5" }, { "cue-ferrule.obj", "#f3efe4" },
    { "cue-shaft.obj", "#e8cf9a" }, { "cue-joint.obj", "#d9d9d9" },
    { "cue-butt.obj", "#6b3518" }, { "cue-wrap.obj", "#1c1c1c" },
    { "cue-butt-end.obj", "#6b3518" }, { "cue-bumper.obj", "#111111" },
  }
  for _, p in ipairs(PARTS) do
    local m = marking(p[1], p[2])
    if m then cue.parts[#cue.parts + 1] = m end
  end
end

-- Quaternion taking +Z to the unit vector (bx, by, bz).
local function quatFromZ(bx, by, bz)
  if bz < -0.9999 then return btQuaternion(yAxis, math.pi) end
  local w = 1 + bz
  local x, y = -by, bx
  local l = math.sqrt(x * x + y * y + w * w)
  return btQuaternion(x / l, y / l, 0, w / l)
end

-- Put the cue with its tip at (tx, ty, tz), running back along (bx, by, bz).
function cue.place(tx, ty, tz, bx, by, bz)
  local t = btTransform(quatFromZ(bx, by, bz), btVector3(tx, ty, tz))
  for _, m in ipairs(cue.parts) do m.trans = t end
end
function cue.hide()
  local t = btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, -200, 0))
  for _, m in ipairs(cue.parts) do m.trans = t end
end

-- ---------------------------------------------------------------------
-- aiming guide: dashes along the ball's path, and a ghost ball where it
-- meets something
-- ---------------------------------------------------------------------

local guide = { mode = 1, dashes = {}, used = 0 }   -- mode 0 off, 1 first contact, 2 whole path
do
  for i = 1, 260 do
    local c = Cylinder(0.14, 1.6, 0)
    c.col = "#ffffff"
    c.pov_export = false
    c.pos = btVector3(0, -150, 0)
    addVisual(c)
    guide.dashes[i] = c
  end
  guide.ghost = Sphere(K.R, 0)
  guide.ghost.col = "#ffffff"
  guide.ghost.transparency = 0.6
  guide.ghost.pov_export = false
  guide.ghost.pos = btVector3(0, -150, 0)
  addVisual(guide.ghost)
end

-- Dashes from (x1,z1) to (x2,z2), in colour col.
function guide.line(x1, z1, x2, z2, col)
  local dx, dz = x2 - x1, z2 - z1
  local len = math.sqrt(dx * dx + dz * dz)
  if len < 0.5 then return end
  local ux, uz = dx / len, dz / len
  local q = btQuaternion(yAxis, math.atan2(ux, uz))
  local s = math.min(1.2, len / 2)
  while s < len and guide.used < #guide.dashes do
    guide.used = guide.used + 1
    local c = guide.dashes[guide.used]
    local m = math.min(s + 0.8, len)
    c.trans = btTransform(q, btVector3(x1 + ux * m, 0.35, z1 + uz * m))
    if c.col ~= col then c.col = col end
    s = s + 3.2
  end
end

function guide.clear()
  for i = 1, guide.used do guide.dashes[i].pos = btVector3(0, -150, 0) end
  guide.used = 0
  guide.ghost.pos = btVector3(0, -150, 0)
end

-- A dashed line along a path of points.
function guide.path(path, col)
  for i = 1, #path - 1 do
    guide.line(path[i][1], path[i][2], path[i + 1][1], path[i + 1][2], col)
  end
end

-- ---------------------------------------------------------------------
-- game state
-- ---------------------------------------------------------------------

local S = {
  state = "aim",        -- aim, stroke, rolling, over
  opening = true,       -- the opening: both marked balls are shot together
  openShots = {},       -- (the shot each side has chosen for it)
  turn = 1,             -- 1 red, 2 white
  sel = 1,              -- the ball about to be played
  ctrl = { "human", "computer" },
  level = 2,            -- the computer's level, 1..3
  wins = { 0, 0 },      -- games won (kept between runs)
  winner = nil,
  sunk = {},            -- this shot: { n, cup } for each ball that dropped
  jumpedOff = {},       -- balls that left the table this shot
  jumped = false,       -- a ball jumped this shot
  tray = {},            -- balls in the trays, in order
  aim = 0,              -- radians; 0 = toward +X
  power = 0.25,         -- 0..1
  spinX = 0, spinY = 0, -- tip offset, -1..1 (right, up)
  elev = 0,             -- how far the player has raised the cue (radians)
  message = "",
  view = "table",       -- table, cue, top
  stillFrames = 0,
  rollFrames = 0,
  strokeFrame = 0,
  dirty = true,
  frame = 0,
}
do
  for side = 1, 2 do
    local saved = v.loadPrefs and v:loadPrefs(PREFS_PREFIX .. "wins" .. side, "") or ""
    S.wins[side] = tonumber(saved) or 0
  end
  local lv = v.loadPrefs and v:loadPrefs(PREFS_PREFIX .. "level", "") or ""
  S.level = tonumber(lv) or 2
end
local function savePref(key, value)
  if v.savePrefs then pcall(function() v:savePrefs(PREFS_PREFIX .. key, tostring(value)) end) end
end

local function now()
  if TF and TF.clock then return TF.clock() end
  return v.getTime and v:getTime() or S.frame * K.FRAME
end

-- Thinking a little at a time. Choosing a shot follows each ball it may
-- play in every direction, a degree apart, at eight speeds -- thousands of
-- paths, each reading every ball's position. Done all at once that held
-- everything up (the picture, and in the rec room every other game) for up
-- to a third of a second. So the computer thinks in a coroutine:
-- PLAN_BUDGET seconds a frame, then the frame carries on and it picks up
-- where it left off on the next. The balls are still while it thinks, so
-- their positions are read once, into frozenXZ (reading one from Bullet
-- makes a vector for the garbage collector: tens of thousands a shot). If
-- anything has moved by the time it has decided, it thinks again. It tries
-- its shots by setting the cue's ball, aim, force and spin; between steps
-- those go back to what's on the screen.
PLAN_BUDGET = PLAN_BUDGET or 0.003
local planUntil = nil
local unpack = unpack or table.unpack
-- (os.clock: the processor time used, finer than bpp's millisecond
-- stopwatch; it counts every thread, so if anything it runs fast, and a
-- step comes out shorter, never longer)
local clockNow = os.clock
local PLAN_STATE = { { S, "sel" }, { S, "aim" }, { S, "power" }, { S, "spinX" }, { S, "spinY" },
                     { S, "elev" }, { cue, "elev" } }
local planShown = {}      -- (what the screen shows, while the computer borrows them)
local function planPace()
  if planUntil and clockNow() >= planUntil then
    local mine = {}
    for i, k in ipairs(PLAN_STATE) do mine[i] = k[1][k[2]]; k[1][k[2]] = planShown[i] end
    coroutine.yield()
    for i, k in ipairs(PLAN_STATE) do planShown[i] = k[1][k[2]]; k[1][k[2]] = mine[i] end
  end
end
local function freezeXZ()
  local f = {}
  for _, b in pairs(balls) do
    local x, y, z = posXYZ(b.obj)
    f[b] = { x, z, y }
  end
  return f
end
local function stillFrozen(f)
  for b, xz in pairs(f) do
    local x, y, z = posXYZ(b.obj)
    if math.abs(x - xz[1]) > 0.05 or math.abs(z - xz[2]) > 0.05 or math.abs(y - xz[3]) > 0.05 then return false end
  end
  return true
end
-- start thinking: fn runs in a coroutine of its own
local function planStart(fn)
  return { co = coroutine.create(fn), xz = freezeXZ(), cpu = 0 }
end
-- think for up to PLAN_BUDGET seconds; true and fn's result when it's done
local function planStep(p)
  for i, k in ipairs(PLAN_STATE) do planShown[i] = k[1][k[2]] end
  local c0 = clockNow()
  frozenXZ, planUntil = p.xz, c0 + PLAN_BUDGET
  local res = { coroutine.resume(p.co) }
  frozenXZ, planUntil = nil, nil
  -- (the screen gets back what it showed, however the step ended)
  for i, k in ipairs(PLAN_STATE) do k[1][k[2]] = planShown[i] end
  p.cpu = p.cpu + (clockNow() - c0)
  if not res[1] then error(res[2], 0) end
  if coroutine.status(p.co) ~= "dead" then return false end
  return true, unpack(res, 2)
end

local function aimDir()
  return math.cos(S.aim), math.sin(S.aim)
end

local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end

-- balls of a side still on the table / sunk in its own cup
local function ballsLeft(side)
  local n = 0
  for i = 1, NB do if balls[i].side == side and balls[i].onTable then n = n + 1 end end
  return n
end
local function ballsSunk(side)
  local n = 0
  for i = 1, NB do if balls[i].side == side and balls[i].inCup == side then n = n + 1 end end
  return n
end
local function markedUp(side) return balls[MARKED[side]].onTable end

local function cupDist(b, side)
  local x, z = ballXZ(b)
  local c = CUPS[side or b.side]
  return math.sqrt((x - c.x) ^ 2 + (z - c.z) ^ 2)
end

-- the balls a side may play now, nearest its cup first
local function playable(side)
  local list = {}
  if markedUp(side) and S.opening then return { balls[MARKED[side]] } end
  for n = 1, NB do
    local b = balls[n]
    if b.side == side and b.onTable then list[#list + 1] = b end
  end
  table.sort(list, function(a, b)
    if a.marked ~= b.marked then return a.marked end
    return cupDist(a) < cupDist(b)
  end)
  return list
end

-- Could a ball sit at (x, z): on the cloth, clear of balls, bumpers and cups?
local function spotFree(x, z, skip)
  if math.abs(x) > K.HL - K.R or math.abs(z) > K.HW - K.R then return false end
  for n = 1, NB do
    local o = balls[n]
    if o.onTable and o ~= skip then
      local ox, oz = ballXZ(o)
      if (ox - x) ^ 2 + (oz - z) ^ 2 < (K.D + 0.05) ^ 2 then return false end
    end
  end
  for _, bp in ipairs(BUMPERS) do
    if (bp[1] - x) ^ 2 + (bp[2] - z) ^ 2 < (K.R + K.RB + 0.1) ^ 2 then return false end
  end
  for _, c in ipairs(CUPS) do
    if (c.x - x) ^ 2 + (c.z - z) ^ 2 < (K.CUP_R + 0.3) ^ 2 then return false end
  end
  return true
end

-- Put a ball on the table at (x, z), or the nearest free place to it.
local function placeNear(b, x, z)
  b.onTable = true
  b.inCup = nil
  for r = 0, 60, 0.5 do
    local steps = math.max(1, math.floor(2 * math.pi * r / 1.5))
    for k = 0, steps - 1 do
      local a = 2 * math.pi * k / steps
      local px, pz = x + r * math.cos(a), z + r * math.sin(a)
      if spotFree(px, pz, b) then
        placeBall(b, px, pz, K.R, randomRot())
        return
      end
    end
  end
  placeBall(b, x, z, K.R, randomRot())
end

-- Back where it started: its own mark, or the first of its side's free.
local function respotHome(b)
  local marks = MARKS[b.side]
  local order = { b.home }
  for i = 1, 5 do if i ~= b.home then order[#order + 1] = i end end
  b.onTable = false
  for _, i in ipairs(order) do
    local m = marks[i]
    if spotFree(m[1], m[2], b) then
      b.onTable = true
      b.inCup = nil
      placeBall(b, m[1], m[2], K.R, randomRot())
      return
    end
  end
  placeNear(b, marks[b.home][1], marks[b.home][2])
end

-- In front of a side's own cup, between its guard bumpers: where that
-- side would put a ball knocked off the table by the other side.
local function placeForCup(b, side)
  local c = CUPS[side]
  local s = c.x > 0 and 1 or -1
  placeNear(b, c.x - s * 12, c.z)
end

-- the sunk balls in the trays: red's on the left, white's on the right
local function arrangeTray()
  local count = { 0, 0 }
  for _, n in ipairs(S.tray) do
    local b = balls[n]
    local side = b.side
    count[side] = count[side] + 1
    local x = (side == 1) and (-39 + count[side] * (K.D + 0.3) - K.R)
                          or (1 + count[side] * (K.D + 0.3) - K.R)
    placeBall(b, x, K.TRAY_Z, K.TRAY_Y)
  end
end
local function removeFromTray(n)
  for i, m in ipairs(S.tray) do
    if m == n then table.remove(S.tray, i); break end
  end
end
local function toTray(b)
  removeFromTray(b.n)
  S.tray[#S.tray + 1] = b.n
  arrangeTray()
end

-- A ball has dropped into cup c.
local function sinkBall(b, c)
  local p = b.obj.pos
  local vel = b.obj.vel
  local sk = sinkers[c]
  sk.obj.col = b.obj.col
  sk.x, sk.y, sk.z, sk.vy, sk.frames = p.x, p.y, p.z, 0, 0
  sk.obj.pos = btVector3(p.x, p.y, p.z)
  b.onTable = false
  b.inCup = c
  b.holeT = 0
  S.sunk[#S.sunk + 1] = { n = b.n, cup = c }
  toTray(b)
  playSound("pocket", math.min(1, 0.5 + math.sqrt(vel.x * vel.x + vel.z * vel.z) / 300))
end

-- A ball has left the table (jumped over the rail, or come to rest on it).
local function offTable(b)
  b.onTable = false
  b.railFrames = 0
  S.jumpedOff[#S.jumpedOff + 1] = b.n
  toTray(b)
  playSound("foul")
end

-- ---------------------------------------------------------------------
-- the view
-- ---------------------------------------------------------------------

-- The end of the table the cameras look from: that of the player on
-- turn if a person is playing it, else the person's.
local function viewSide()
  if S.ctrl[S.turn] == "human" then return S.turn end
  if S.ctrl[1] == "human" then return 1 end
  if S.ctrl[2] == "human" then return 2 end
  return 1
end

local function setView()
  local s = (viewSide() == 1) and -1 or 1          -- red plays from the -X end
  if S.view == "top" then
    common.setCamera(btVector3(0, 230, 0.01), btVector3(0, 0, 0), 0.8, { up = btVector3(0, 0, s) })
  elseif S.view == "cue" then
    local cx, cz = ballXZ(balls[S.sel])
    local dx, dz = aimDir()
    common.setCamera(btVector3(cx - dx * 60, 30, cz - dz * 60),
                     btVector3(cx + dx * 45, 0, cz + dz * 45), 0.8, { up = yAxis })
  else
    common.setCamera(btVector3(s * 165, 120, 0), btVector3(-s * 14, -6, 0), 0.8, { up = yAxis })
  end
end

-- Place the cue behind the ball, drawn back `gap` cm from it. The cue is
-- kept as low as it can go (4 degrees) but raised as far as it must be to
-- clear the rail, the bumpers and any ball behind -- it never passes
-- through them. Raised, it still points at the same spot on the ball, so
-- the tip meets the ball higher up its back.
local CUE_LEN = 147
local function cueRadius(s) return 0.64 + 0.81 * math.max(0, s) / CUE_LEN end

-- The tip and the unit vector back along the cue, for elevation e.
local function cueGeometry(e, gap)
  local cx, cz = ballXZ(balls[S.sel])
  local dx, dz = aimDir()
  local rx, rz = -dz, dx                               -- to the right of the aim
  local ox, oy = S.spinX * K.MAX_TIP * K.R, S.spinY * K.MAX_TIP * K.R
  local ce, se = math.cos(e), math.sin(e)
  local bx, by, bz = -dx * ce, se, -dz * ce            -- back along the cue
  local ux, uy, uz = dx * se, ce, dz * se              -- "up", square to the cue
  local k = math.sqrt(math.max(0, K.R * K.R - ox * ox - oy * oy)) + gap
  return cx + rx * ox + ux * oy + bx * k, K.R + uy * oy + by * k,
         cz + rz * ox + uz * oy + bz * k, bx, by, bz
end

-- Does the cue at elevation e clear the rail, the bumpers and every ball?
local function cueClears(e, gap)
  local px, py, pz, bx, by, bz = cueGeometry(e, gap)
  -- the rail: where the cue passes over the cushion nose it must be above
  -- the rail's top
  local sExit = math.huge
  local ox0, oz0 = px - bx * gap, pz - bz * gap
  if bx > 1e-6 then sExit = math.min(sExit, (K.HL - ox0) / bx) elseif bx < -1e-6 then sExit = math.min(sExit, (-K.HL - ox0) / bx) end
  if bz > 1e-6 then sExit = math.min(sExit, (K.HW - oz0) / bz) elseif bz < -1e-6 then sExit = math.min(sExit, (-K.HW - oz0) / bz) end
  sExit = math.max(-gap, sExit - gap)
  if sExit < CUE_LEN and py + by * sExit - cueRadius(sExit) < K.RAIL_H + 0.3 then return false end
  -- the bumpers: where the cue passes over one, above its cap
  local a = bx * bx + bz * bz
  if a > 1e-9 then
    for _, bp in ipairs(BUMPERS) do
      local qx, qz = px - bp[1], pz - bp[2]
      local rr = K.RB + 1.0
      local bq = 2 * (qx * bx + qz * bz)
      local cq = qx * qx + qz * qz - rr * rr
      local disc = bq * bq - 4 * a * cq
      if disc > 0 then
        local s1 = (-bq - math.sqrt(disc)) / (2 * a)
        local s2 = (-bq + math.sqrt(disc)) / (2 * a)
        if s2 > -gap and s1 < CUE_LEN then
          local s = math.max(s1, -gap)
          if py + by * s - cueRadius(s) < K.BUMPER_H + 1.5 then return false end
        end
      end
    end
  end
  -- the balls
  for n = 1, NB do
    local b = balls[n]
    if b.onTable and n ~= S.sel then
      local bx_, by_, bz_ = ballXYZ(b)
      local vx, vy, vz = bx_ - px, by_ - py, bz_ - pz
      local sB = math.max(-gap, math.min(CUE_LEN, vx * bx + vy * by + vz * bz))
      local qx, qy, qz = vx - bx * sB, vy - by * sB, vz - bz * sB
      if qx * qx + qy * qy + qz * qz < (K.R + cueRadius(sB) + 0.15) ^ 2 then return false end
    end
  end
  return true
end

local MIN_ELEV, MAX_ELEV = math.rad(4), math.rad(80)
local function cueElevation(gap)
  local e = math.max(MIN_ELEV, S.elev)
  while e < MAX_ELEV and not cueClears(e, gap) do e = e + math.rad(1) end
  return e
end
local function placeCue(gap)
  local e = cueElevation(gap)
  cue.elev = e
  local px, py, pz, bx, by, bz = cueGeometry(e, gap)
  cue.place(px, py, pz, bx, by, bz)
end

-- Hitting left or right of centre pushes the ball a little the other way
-- off the line of the cue (squirt), as a real cue does.
local SQUIRT = math.rad(1.5)

-- The stroke for the current aim, cue angle, force and spin: the unit
-- direction it drives the ball (squirt included), the point on the ball
-- the tip meets (relative to its centre) and the speed.
local function strokeNow()
  local e = cue.elev or MIN_ELEV
  local cx, cz = ballXZ(balls[S.sel])
  local tx, ty, tz, bx, by, bz = cueGeometry(e, 0)        -- tip on the ball
  local fx, fy, fz = -bx, -by, -bz
  local sq = -SQUIRT * S.spinX
  local c, s = math.cos(sq), math.sin(sq)
  fx, fz = fx * c - fz * s, fx * s + fz * c
  return fx, fy, fz, tx - cx, ty - K.R, tz - cz, K.VMAX * math.max(0.01, S.power)
end

-- ---------------------------------------------------------------------
-- predicting a ball's path
-- ---------------------------------------------------------------------

local MU_G = 0.2 * K.G          -- the cloth's sliding friction (ball 0.2 x cloth 1.0)
local E_CUSHION, E_BUMPER = 0.85, 0.80
local ROLL_AFTER = 0.6          -- (see cushionBounce)
local LIM_X, LIM_Z = K.HL - K.R, K.HW - K.R
local GRIP = 0.88               -- the speed along a cushion or bumper kept through a bounce (measured)

-- Would a ball over cup (cx, cz) -- (rx, rz) from its centre, moving at
-- (vx, vz), already `t` seconds over the hole -- fall in?
local function fallsIn(rx, rz, vx, vz, t)
  local sp = math.sqrt(vx * vx + vz * vz)
  local tRem = math.huge
  if sp > 1e-3 then
    local ux, uz = vx / sp, vz / sp
    local bq = rx * ux + rz * uz
    local s = -bq + math.sqrt(math.max(0, bq * bq - (rx * rx + rz * rz - K.CUP_R * K.CUP_R)))
    tRem = s / sp
  end
  local tt = t + tRem
  return 0.5 * K.G * tt * tt > K.CUP_DROP
end

-- The ball about to be played, stroked as set up now: step its motion on
-- the cloth (sliding until it rolls, then rolling resistance; side spin's
-- swerve and a masse's curve included), off cushions and bumpers (as
-- cushionBounce() does), over the cups, until it meets a ball, drops,
-- stops, or makes more than maxBounces bounces.
-- Returns the path, where it ends, and what ended it: "ball" (with the
-- ball and the direction the ball will take), "cushion"/"bumper" (with
-- the direction it comes off), "cup" (with the cup) or "stop".
local function predictShot(maxBounces)
  local fx, fy, fz, rx, ry, rz, speed = strokeNow()
  local sb = balls[S.sel]
  local px, pz = ballXZ(sb)
  local vx, vz = fx * speed, fz * speed
  local Jx, Jy, Jz = fx * speed, fy * speed, fz * speed
  local k = 5 / (2 * K.R * K.R)
  local wx = (ry * Jz - rz * Jy) * k
  local wy = (rz * Jx - rx * Jz) * k
  local wz = (rx * Jy - ry * Jx) * k
  local path = { { px, pz } }
  local lastX, lastZ = px, pz
  local dt = 1 / 200
  local bounces = 0
  local holeT = 0
  -- a bounce off a surface whose normal (into the table) is (nx, nz)
  local function bounce(nx, nz, e)
    local before = -(vx * nx + vz * nz)
    if before <= 0 then return end
    local off = e * before
    local tx, tz = vx + before * nx, vz + before * nz      -- along it: friction takes some
    vx, vz = GRIP * tx + off * nx, GRIP * tz + off * nz
    local ax, az = -nz, nx
    local rollNow = wx * ax + wz * az
    local target = -ROLL_AFTER * off / K.R
    if rollNow < 0 then target = math.min(rollNow, target) end
    wx, wz = wx + (target - rollNow) * ax, wz + (target - rollNow) * az
  end
  for step = 1, 200 * 12 do
    if step % 40 == 0 then planPace() end
    local sx, sz = vx + K.R * wz, vz - K.R * wx
    local slip = math.sqrt(sx * sx + sz * sz)
    local dv = MU_G * dt
    if slip > 3.5 * dv then
      local ax, az = -MU_G * sx / slip, -MU_G * sz / slip
      vx, vz = vx + ax * dt, vz + az * dt
      wx, wz = wx - 2.5 / K.R * az * dt, wz + 2.5 / K.R * ax * dt
    else
      wx, wz = vz / K.R, -vx / K.R                -- rolling
    end
    local sp = math.sqrt(vx * vx + vz * vz)
    if sp < K.STOP_V then break end
    local f = math.max(0, sp - K.ROLL_DECEL * dt) / sp
    vx, vz, wx, wz = vx * f, vz * f, wx * f, wz * f
    local dwy = K.SPIN_DECEL * dt
    wy = math.abs(wy) <= dwy and 0 or wy - dwy * (wy > 0 and 1 or -1)
    local nx, nz = px + vx * dt, pz + vz * dt
    local mx, mz = nx - px, nz - pz
    local ml2 = mx * mx + mz * mz
    -- a ball in the way during this step?
    local bestT, hit = nil, nil
    for n = 1, NB do
      local b = balls[n]
      if b.onTable and b ~= sb then
        local bx, bz = ballXZ(b)
        local ox, oz = px - bx, pz - bz
        local bq = ox * mx + oz * mz
        local cq = ox * ox + oz * oz - K.D * K.D
        local disc = bq * bq - ml2 * cq
        if disc >= 0 and ml2 > 0 then
          local t = (-bq - math.sqrt(disc)) / ml2
          if t >= -1e-6 and t <= 1 and (not bestT or t < bestT) then bestT, hit = math.max(0, t), b end
        end
      end
    end
    if hit then
      px, pz = px + mx * bestT, pz + mz * bestT
      path[#path + 1] = { px, pz }
      -- throw: friction between the balls drags the object ball a little
      -- off the line of centres
      local bx, bz = ballXZ(hit)
      local cx, cz = (bx - px) / K.D, (bz - pz) / K.D
      local vn = vx * cx + vz * cz
      local ux, uz = cx, cz
      if vn > 1 then
        local tsx = vx + K.R * wy * cz
        local tsz = vz - K.R * wy * cx
        local tsy = K.R * (wz * cx - wx * cz)
        local tn = tsx * cx + tsz * cz
        local thx, thz = tsx - tn * cx, tsz - tn * cz
        local st = math.sqrt(thx * thx + thz * thz + tsy * tsy)
        if st > 1e-6 then
          local vt = math.min(0.04 * vn, st / 7)
          ux, uz = cx + thx / st * vt / vn, cz + thz / st * vt / vn
          local ul = math.sqrt(ux * ux + uz * uz)
          ux, uz = ux / ul, uz / ul
        end
      end
      return path, px, pz, "ball", hit, ux, uz
    end
    -- a cushion?
    local kind, bnx, bnz, e = nil, 0, 0, 0
    if math.abs(nx) >= LIM_X or math.abs(nz) >= LIM_Z then
      local t = 1
      if math.abs(nx) >= LIM_X and mx ~= 0 then t = math.min(t, ((nx > 0 and LIM_X or -LIM_X) - px) / mx) end
      if math.abs(nz) >= LIM_Z and mz ~= 0 then t = math.min(t, ((nz > 0 and LIM_Z or -LIM_Z) - pz) / mz) end
      nx, nz = px + mx * t, pz + mz * t
      if math.abs(nx) >= LIM_X - 1e-6 then bnx = nx > 0 and -1 or 1 end
      if math.abs(nz) >= LIM_Z - 1e-6 then bnz = nz > 0 and -1 or 1 end
      local l = math.sqrt(bnx * bnx + bnz * bnz)
      bnx, bnz = bnx / l, bnz / l
      kind, e = "cushion", E_CUSHION
    else
      -- a bumper?
      local rr = K.R + K.RB
      for _, bp in ipairs(BUMPERS) do
        local ox, oz = px - bp[1], pz - bp[2]
        local bq = ox * mx + oz * mz
        local cq = ox * ox + oz * oz - rr * rr
        local disc = bq * bq - ml2 * cq
        if bq < 0 and disc >= 0 and ml2 > 0 then
          local t = (-bq - math.sqrt(disc)) / ml2
          if t >= -1e-6 and t <= 1 then
            nx, nz = px + mx * math.max(0, t), pz + mz * math.max(0, t)
            bnx, bnz = (nx - bp[1]) / rr, (nz - bp[2]) / rr
            kind, e = "bumper", E_BUMPER
            break
          end
        end
      end
    end
    if kind then
      px, pz = nx, nz
      path[#path + 1] = { px, pz }
      lastX, lastZ = px, pz
      bounce(bnx, bnz, e)
      bounces = bounces + 1
      if bounces > maxBounces then
        local l = math.sqrt(vx * vx + vz * vz)
        return path, px, pz, kind, nil, vx / math.max(l, 1e-6), vz / math.max(l, 1e-6)
      end
    else
      px, pz = nx, nz
      -- over a cup?
      local over = false
      for c, cup in ipairs(CUPS) do
        local qx, qz = px - cup.x, pz - cup.z
        if qx * qx + qz * qz < K.CUP_R * K.CUP_R then
          over = true
          holeT = holeT + dt
          if fallsIn(qx, qz, vx, vz, holeT) then
            path[#path + 1] = { px, pz }
            return path, px, pz, "cup", nil, nil, nil, c
          end
        end
      end
      if not over then holeT = 0 end
      if (px - lastX) ^ 2 + (pz - lastZ) ^ 2 > 3.2 * 3.2 then
        path[#path + 1] = { px, pz }
        lastX, lastZ = px, pz
      end
    end
  end
  path[#path + 1] = { px, pz }
  return path, px, pz, "stop"
end

-- The same, quickly, for the computer's planning: a ball sent from (x, z)
-- along the unit (dx, dz) at speed v0 with a centre-ball hit (it slides,
-- then rolls). It moves in straight lines between events, worked out
-- exactly rather than stepped; a bounce keeps the speed along the cushion
-- and sends it off at E times the speed into it (less a little lost
-- getting back to a roll). Returns a table: kind ("cup", "ball", "stop"),
-- cup, x, z, hit (a ball), first (what it touched first: "side", "end",
-- "bumper" or "ball"), bounces.
local REROLL = (5 + 2 * ROLL_AFTER) / 7
-- the speed squared, from v2 with `slide` still to slide, after going s
-- further (out here, not made afresh for each of the planner's thousands
-- of traces)
local function traceAfter(s, v2, slide)
  local a1 = math.min(s, slide)
  return v2 - 2 * MU_G * a1 - 2 * K.ROLL_DECEL * math.max(0, s - slide)
end
local function trace(x, z, dx, dz, v0, skip)
  local v2 = v0 * v0
  local slide = 12 / 49 * v0 * v0 / MU_G        -- sliding still to do
  local first, bounces, skipped = nil, 0, nil
  local rrB, D2 = K.R + K.RB, K.D * K.D
  local H2 = K.CUP_R * K.CUP_R
  for _ = 1, 40 do
    local sl = math.min(slide, v2 / (2 * MU_G))
    local best = sl + math.max(0, v2 - 2 * MU_G * sl) / (2 * K.ROLL_DECEL)
    local kind, obj, nx, nz = "stop", nil, 0, 0
    local t
    if dx > 1e-9 then t = (LIM_X - x) / dx; if t < best then best, kind, nx, nz = t, "end", -1, 0 end
    elseif dx < -1e-9 then t = (-LIM_X - x) / dx; if t < best then best, kind, nx, nz = t, "end", 1, 0 end end
    if dz > 1e-9 then t = (LIM_Z - z) / dz; if t < best then best, kind, nx, nz = t, "side", 0, -1 end
    elseif dz < -1e-9 then t = (-LIM_Z - z) / dz; if t < best then best, kind, nx, nz = t, "side", 0, 1 end end
    for _, bp in ipairs(BUMPERS) do
      local ox, oz = x - bp[1], z - bp[2]
      local bq = ox * dx + oz * dz
      if bq < 0 then
        local disc = bq * bq - (ox * ox + oz * oz - rrB * rrB)
        if disc > 0 then
          t = -bq - math.sqrt(disc)
          if t > -1e-6 and t < best then best, kind, obj = math.max(0, t), "bumper", bp end
        end
      end
    end
    for n = 1, NB do
      local b = balls[n]
      if b.onTable and n ~= skip then
        local bx, bz = ballXZ(b)
        local ox, oz = x - bx, z - bz
        local bq = ox * dx + oz * dz
        if bq < 0 then
          local disc = bq * bq - (ox * ox + oz * oz - D2)
          if disc > 0 then
            t = -bq - math.sqrt(disc)
            if t > -1e-6 and t < best then best, kind, obj = math.max(0, t), "ball", b end
          end
        end
      end
    end
    for c, cup in ipairs(CUPS) do
      local ox, oz = x - cup.x, z - cup.z
      local bq = ox * dx + oz * dz
      if bq < 0 then
        local disc = bq * bq - (ox * ox + oz * oz - H2)
        if disc > 0 then
          t = -bq - math.sqrt(disc)
          if t > -1e-6 and t < best then best, kind, obj = math.max(0, t), "cup", c end
        end
      end
    end
    -- go there
    x, z = x + dx * best, z + dz * best
    local nv2 = math.max(0, traceAfter(best, v2, slide))
    slide = math.max(0, slide - best)
    v2 = nv2
    if kind == "stop" then
      return { kind = "stop", x = x, z = z, first = first, bounces = bounces, skipped = skipped }
    elseif kind == "ball" then
      return { kind = "ball", x = x, z = z, hit = obj, first = first or "ball", bounces = bounces, skipped = skipped }
    elseif kind == "cup" then
      -- across the hole: does it fall before the far edge?
      local cup = CUPS[obj]
      local ox, oz = x - cup.x, z - cup.z
      local bq = ox * dx + oz * dz
      local L = -bq + math.sqrt(math.max(0, bq * bq - (ox * ox + oz * oz - H2)))
      local vIn = math.sqrt(v2)
      local vOut2 = traceAfter(L, v2, slide)
      local falls = vOut2 <= 0
      if not falls then
        local tt = L / ((vIn + math.sqrt(vOut2)) / 2)
        falls = 0.5 * K.G * tt * tt > K.CUP_DROP
      end
      if falls then
        return { kind = "cup", cup = obj, x = cup.x, z = cup.z, first = first, bounces = bounces }
      end
      x, z = x + dx * (L + 0.01), z + dz * (L + 0.01)
      skipped = skipped or {}
      skipped[obj] = true
      v2 = math.max(0, vOut2)
      slide = math.max(0, slide - L)
    else
      if kind == "bumper" then
        nx, nz = (x - obj[1]) / rrB, (z - obj[2]) / rrB
      end
      first = first or kind
      bounces = bounces + 1
      local v = math.sqrt(v2)
      local vx, vz = dx * v, dz * v
      local vn = vx * nx + vz * nz                    -- (negative: into it)
      local e = (kind == "bumper") and E_BUMPER or E_CUSHION
      if vn < 0 then
        local tx, tz = vx - vn * nx, vz - vn * nz          -- along the cushion: friction takes some
        vx, vz = GRIP * tx - e * REROLL * vn * nx, GRIP * tz - e * REROLL * vn * nz
      end
      v2 = vx * vx + vz * vz
      local l = math.sqrt(v2)
      if l < 1e-6 then return { kind = "stop", x = x, z = z, first = first, bounces = bounces, skipped = skipped } end
      dx, dz = vx / l, vz / l
      slide = 0
    end
  end
  return { kind = "stop", x = x, z = z, first = first, bounces = bounces, skipped = skipped }
end

local function drawGuide()
  guide.clear()
  if S.state ~= "aim" or guide.mode == 0 then return end
  local path, gx, gz, kind, hit, ux, uz, cup = predictShot(guide.mode == 1 and 0 or 12)
  local col = "#ffffff"
  if kind == "cup" then col = (cup == S.turn) and "#7cfc00" or "#ff5a4f" end
  guide.path(path, col)
  if kind == "cup" then
    guide.ghost.pos = btVector3(CUPS[cup].x, K.R, CUPS[cup].z)
  else
    guide.ghost.pos = btVector3(gx, K.R, gz)
  end
  if guide.ghost.col ~= col then guide.ghost.col = col end
  if kind == "ball" then
    local bx, bz = ballXZ(hit)
    guide.line(bx, bz, bx + ux * 22, bz + uz * 22, "#ffe066")
    -- the shot ball glances off at right angles (for a hit without spin)
    local p1, p2 = path[math.max(1, #path - 1)], path[#path]
    local ex, ez = p2[1] - p1[1], p2[2] - p1[2]
    local el = math.sqrt(ex * ex + ez * ez)
    if el > 1e-6 then
      ex, ez = ex / el, ez / el
      local dot = ex * ux + ez * uz
      local tx, tz = ex - dot * ux, ez - dot * uz
      local tl = math.sqrt(tx * tx + tz * tz)
      if tl > 0.05 then guide.line(gx, gz, gx + tx / tl * 14, gz + tz / tl * 14, "#8ecae6") end
    end
  elseif (kind == "cushion" or kind == "bumper") and ux then
    guide.line(gx, gz, gx + ux * 16, gz + uz * 16, "#8ecae6")
  end
end

-- auto-play: the computer's turns; filled in further down
local auto = { phase = "idle" }

-- ---------------------------------------------------------------------
-- the shortcuts pane
-- ---------------------------------------------------------------------

local function who(side)
  local name = (side == 1) and "Red" or "White"
  if S.ctrl[side] == "computer" then return name .. " (computer)" end
  if S.ctrl[1] == "human" and S.ctrl[2] == "human" then return name .. " (player " .. side .. ")" end
  return name .. " (you)"
end

local function helpText()
  local lines = {}
  local function add(s) lines[#lines + 1] = s end
  add(string.format("BUMPER POOL -- %s v %s      computer level %d", who(1), who(2), S.level))
  add("")
  local st = S.state
  if st == "over" then
    add(string.format("%s wins. Press N for a new game.", who(S.winner)))
  elseif st == "stroke" or st == "rolling" then
    add(S.opening and "The opening: both marked balls rolling..." or "Balls rolling...")
  elseif S.opening then
    if S.ctrl[S.turn] == "computer" then add(who(S.turn) .. " is choosing its opening shot...")
    else
      add(string.format("THE OPENING -- %s: set up your marked ball's shot. It must bank off a side cushion first.", who(S.turn)))
      add(S.openShots[3 - S.turn] and "Both balls go together when you shoot."
          or "Then the other side sets up theirs, and both balls go together.")
    end
  elseif st == "aim" then
    if S.ctrl[S.turn] == "computer" then add(who(S.turn) .. " to play...")
    else
      add(string.format("%s to play%s.", who(S.turn),
                        markedUp(S.turn) and " -- your marked ball must go in first" or ""))
    end
  end
  add(string.format("Still to sink: red %d, white %d      Games won: red %d, white %d",
                    5 - ballsSunk(1), 5 - ballsSunk(2), S.wins[1], S.wins[2]))
  add(string.format("Aim %.2f deg   Force %d%%   Spin: %s", (math.deg(S.aim) + 360) % 360,
                    math.floor(S.power * 100 + 0.5),
                    (S.spinX == 0 and S.spinY == 0) and "centre ball"
                    or string.format("%s %.0f%%, %s %.0f%%",
                                     S.spinY >= 0 and "follow" or "draw", math.abs(S.spinY) * 100,
                                     S.spinX >= 0 and "right" or "left", math.abs(S.spinX) * 100)))
  local ce = math.deg(cue.elev or MIN_ELEV)
  local notes = {}
  if ce > math.deg(math.max(MIN_ELEV, S.elev)) + 0.5 then notes[#notes + 1] = "raised to clear a bumper, ball or the rail" end
  if K.VMAX * S.power * math.sin(math.rad(ce)) > K.JUMP_MIN + 60 then
    notes[#notes + 1] = "hit this firmly it will jump (a foul)"
  end
  if ce >= 30 and S.spinX ~= 0 then notes[#notes + 1] = "off centre, it will curve (masse)" end
  add(string.format("Cue raised %.0f deg%s", ce, #notes > 0 and " -- " .. table.concat(notes, "; ") or ""))
  add("")
  add("Tab or X / Z  next / previous of your balls (the ring shows which)")
  add("Left/Right  aim (tap for a quarter degree, hold to swing)    ,  .  fine aim")
  add("Up/Down     force")
  add("W/S  A/D    hit higher (follow) / lower (draw); left / right (side)    C  centre hit")
  add("E/Q         raise / lower the cue (masse)")
  add("Space/Enter shoot")
  add("G           aiming guide: " .. ({ [0] = "off", "to the first cushion, bumper or ball", "the whole path (green: it drops)" })[guide.mode])
  add("V B T       camera: your end" .. (S.view == "table" and " (now)" or "") .. ", behind the cue"
      .. (S.view == "cue" and " (now)" or "") .. ", overhead" .. (S.view == "top" and " (now)" or ""))
  add("N or R      new game")
  add("O           white: " .. (S.ctrl[2] == "computer" and "the computer (O: a second player)" or "a second player (O: the computer)"))
  add("L           the computer's level: " .. S.level .. " (1 easy, 2 medium, 3 hard)")
  add("P           the computer plays red too " .. (S.ctrl[1] == "computer" and "(on)" or "(off)"))
  add("")
  add("Sink your five in your own cup (red's is at the far end from where red starts), marked ball first.")
  add("Sink one and you go again. Fouls -- another ball before the marked one, yours in the other cup,")
  add("a jump, a ball off the table -- let the other side drop two of theirs in its cup.")
  return table.concat(lines, "\n")
end

-- ---------------------------------------------------------------------
-- shooting and the rules
-- ---------------------------------------------------------------------

-- aim ball n straight at its own cup
local function aimAtCup(n)
  local b = balls[n]
  local x, z = ballXZ(b)
  local c = CUPS[b.side]
  S.aim = math.atan2(c.z - z, c.x - x)
end

-- It's `side`'s turn (with its first ball chosen and aimed).
local function startTurn(side)
  S.turn = side
  local list = playable(side)
  S.sel = list[1] and list[1].n or MARKED[side]
  aimAtCup(S.sel)
  S.spinX, S.spinY, S.elev = 0, 0, 0
  S.state = "aim"
  auto.phase = "idle"
  setView()
  S.dirty = true
end

local function newGame()
  for side = 1, 2 do
    for i = 1, 5 do
      local b = balls[(side - 1) * 5 + i]
      b.onTable = true
      b.inCup = nil
      placeBall(b, MARKS[side][i][1], MARKS[side][i][2], K.R, randomRot())
    end
  end
  S.tray = {}
  S.opening = true
  S.openShots = {}
  S.winner = nil
  S.message = "OPENING"
  S.power = 0.25
  playSound("rack")
  startTurn(1)
end

-- The shot: an impulse on ball n at the point the tip meets it, along the
-- cue (see the Pool Table for how spin, masse and jumps come from it).
local function strikeBall(n, aim, power, spinX, spinY, elev)
  local saved = { S.sel, S.aim, S.power, S.spinX, S.spinY, cue.elev }
  S.sel, S.aim, S.power, S.spinX, S.spinY, cue.elev = n, aim, power, spinX, spinY, elev
  local b = balls[n]
  local fx, fy, fz, rx, ry, rz, speed = strokeNow()
  local J = K.MASS * speed
  local body = b.obj.body
  body:applyImpulse(btVector3(fx * J, 0, fz * J), btVector3(rx, ry, rz))
  local vy = fy * J
  body:applyTorqueImpulse(btVector3(-rz * vy, 0, rx * vy))
  local down = -fy * speed
  if down > K.JUMP_MIN then
    local vel = body:getLinearVelocity()
    local up = K.JUMP_E * (down - K.JUMP_MIN)
    local h = math.sqrt(vel.x * vel.x + vel.z * vel.z)
    local keep = h > 0 and math.max(0.5, 1 - 0.2 * (down + up) / h) or 1
    body:setLinearVelocity(btVector3(vel.x * keep, up, vel.z * keep))
  end
  b.vx, b.vz = fx * speed, fz * speed     -- (not a collision)
  S.sel, S.aim, S.power, S.spinX, S.spinY, cue.elev = saved[1], saved[2], saved[3], saved[4], saved[5], saved[6]
end

local function strike()
  strikeBall(S.sel, S.aim, S.power, S.spinX, S.spinY, cue.elev or MIN_ELEV)
  local o = S.opening and S.openShots[3 - S.turn]
  if o then strikeBall(o.n, o.aim, o.power, o.spinX, o.spinY, o.elev) end
  playSound("cue", math.min(1, 0.25 + S.power))
end

local function shoot()
  if S.state ~= "aim" then return false end
  if S.opening and not S.openShots[3 - S.turn] then
    -- the first side's opening shot is set: now the other side's
    S.openShots[S.turn] = { n = S.sel, aim = S.aim, power = S.power, spinX = S.spinX,
                            spinY = S.spinY, elev = cue.elev or MIN_ELEV }
    startTurn(3 - S.turn)
    return true
  end
  S.state = "stroke"
  S.strokeFrame = 0
  S.message = ""
  S.markedUpAtShot = markedUp(S.turn)
  S.sunk, S.jumpedOff, S.jumped = {}, {}, false
  for n = 1, NB do balls[n].jumped, balls[n].firstContact = false, nil end
  guide.clear()
  showSelector(nil)
  S.dirty = true
  return true
end

-- Two of `side`'s balls drop straight into its cup (the penalty for the
-- other side's foul): its marked ball if it's still up, then the balls
-- furthest from the cup.
local function penaltyDrop(side, count)
  for _ = 1, count do
    local pick
    if markedUp(side) then pick = balls[MARKED[side]]
    else
      local far
      for n = 1, NB do
        local b = balls[n]
        if b.side == side and b.onTable then
          local d = cupDist(b)
          if not far or d > far then pick, far = b, d end
        end
      end
    end
    if not pick then return end
    pick.onTable = false
    pick.inCup = side
    toTray(pick)
  end
  playSound("pocket", 0.8)
end

local function gameOver(side)
  S.winner = side
  S.state = "over"
  S.wins[side] = S.wins[side] + 1
  savePref("wins" .. side, S.wins[side])
  S.message = "FINISHED"
  auto.overAt = now()
  playSound("win")
  setView()
  S.dirty = true
end

-- The opening is over: who shoots first? Whoever sank his marked ball,
-- or else finished nearer his cup. A marked ball that didn't bank off a
-- side cushion first, jumped, or left the table loses the opening.
local function openingOver()
  local score = {}
  for side = 1, 2 do
    local m = balls[MARKED[side]]
    local d
    if m.inCup == side then d = -1
    elseif not m.onTable then d = 1e9
    else
      d = cupDist(m)
      if m.firstContact ~= "side" or m.jumped then d = d + 1e6 end
    end
    score[side] = d
  end
  -- anything in the wrong cup or off the table goes back
  local back = {}
  for _, e in ipairs(S.sunk) do
    if e.cup ~= balls[e.n].side then back[#back + 1] = balls[e.n] end
  end
  for _, n in ipairs(S.jumpedOff) do back[#back + 1] = balls[n] end
  for _, b in ipairs(back) do removeFromTray(b.n); respotHome(b) end
  arrangeTray()
  S.opening = false
  S.openShots = {}
  S.message = "FIRST SHOT"
  startTurn(score[1] <= score[2] and 1 or 2)
end

-- When every ball has stopped: fouls, penalties, whose turn, a winner?
local function shotOver()
  S.spinX, S.spinY, S.elev = 0, 0, 0
  if S.opening then return openingOver() end
  local p, o = S.turn, 3 - S.turn
  local foul, why = false, nil
  local function fault(reason)
    if not foul then foul, why = true, reason end
  end
  local potted, lose = 0, false
  local markedIn = false
  for _, e in ipairs(S.sunk) do
    local b = balls[e.n]
    if b.side == p and b.marked and e.cup == p then markedIn = true end
  end
  local back = {}                  -- balls to spot back where they started
  for _, e in ipairs(S.sunk) do
    local b = balls[e.n]
    if e.cup == b.side then
      if b.side == p then
        if S.markedUpAtShot and not markedIn then fault("SPOT 1ST")   -- stays down, all the same
        else potted = potted + 1 end
      end
    elseif b.side == p then
      fault("OTHER CUP")
      back[#back + 1] = b
    else
      back[#back + 1] = b          -- the other side's ball in your cup: it goes back
    end
  end
  -- your last ball in the other cup loses the game
  if #back > 0 then
    local lastBall = ballsLeft(p) == 0
    for _, b in ipairs(back) do
      if b.side == p and lastBall then lose = true end
    end
  end
  if S.jumped then fault("FOUL JUMP") end
  for _, n in ipairs(S.jumpedOff) do
    fault("OFF TABLE")
    local b = balls[n]
    removeFromTray(n)
    if b.side == o then placeForCup(b, o) else respotHome(b) end
  end
  if not lose then
    for _, b in ipairs(back) do removeFromTray(b.n); respotHome(b) end
  end
  arrangeTray()

  if lose then
    S.message = "OTHER CUP"
    playSound("foul")
    gameOver(o)
    return
  end
  if foul then
    S.message = why
    playSound("foul")
    penaltyDrop(o, 2)
  end
  if ballsSunk(p) == 5 and not foul then gameOver(p); return end
  if ballsSunk(o) == 5 then gameOver(o); return end
  if ballsSunk(p) == 5 then gameOver(p); return end
  if not foul then
    if potted > 0 then
      S.message = (5 - ballsSunk(p)) .. " TO GO"
    else
      S.message = "NO POT"
    end
  end
  startTurn((potted > 0 and not foul) and p or o)
end

-- ---------------------------------------------------------------------
-- keyboard: taps step, holds slide (faster the longer they're held)
-- ---------------------------------------------------------------------

local HOLD_DELAY = 0.25     -- a key held this long starts sliding
local REPEAT_GAP = 0.04     -- a release and press this close are one hold
local SLIDES = {
  aim = { math.rad(0.25), math.rad(8), math.rad(45) },
  fine = { math.rad(0.02), math.rad(0.4), math.rad(2) },
  power = { 0.01, 0.25, 0.6 },
  spin = { 0.05, 0.6, 1.2 },
  elev = { math.rad(1), math.rad(10), math.rad(30) },
}
local held = {}
local released = {}

-- What a key does (amount is in the key's units), or nil if nothing.
local function keyAction(key)
  if S.state ~= "aim" then return nil end
  local function adj(field, sign, lo, hi, slide)
    return slide, function(a)
      S[field] = lo and clamp(S[field] + sign * a, lo, hi) or (S[field] + sign * a)
      if field == "spinX" or field == "spinY" then
        local r = math.sqrt(S.spinX ^ 2 + S.spinY ^ 2)
        if r > 1 then S.spinX, S.spinY = S.spinX / r, S.spinY / r end
      end
      S.dirty = true
    end
  end
  if key == "Left" then return adj("aim", -1, nil, nil, "aim") end
  if key == "Right" then return adj("aim", 1, nil, nil, "aim") end
  if key == "," or key == "<" then return adj("aim", -1, nil, nil, "fine") end
  if key == "." or key == ">" then return adj("aim", 1, nil, nil, "fine") end
  if key == "Up" then return adj("power", 1, 0.01, 1, "power") end
  if key == "Down" then return adj("power", -1, 0.01, 1, "power") end
  if key == "W" then return adj("spinY", 1, -1, 1, "spin") end
  if key == "S" then return adj("spinY", -1, -1, 1, "spin") end
  if key == "A" then return adj("spinX", -1, -1, 1, "spin") end
  if key == "D" then return adj("spinX", 1, -1, 1, "spin") end
  if key == "E" then return adj("elev", 1, 0, MAX_ELEV, "elev") end
  if key == "Q" then return adj("elev", -1, 0, MAX_ELEV, "elev") end
  return nil
end

local OUR_KEYS = {}
for _, k in ipairs({ "Left", "Right", "Up", "Down", ",", ".", "<", ">", "W", "S", "A", "D",
                     "C", "E", "Q", "G", "V", "B", "T", "N", "R", "P", "O", "L", "X", "Z", "Tab",
                     "Space", "Return", "Enter" }) do
  OUR_KEYS[k] = true
end
-- keys that play the shot (ignored on the computer's turn)
local PLAY_KEYS = { Left = 1, Right = 1, Up = 1, Down = 1, [","] = 1, ["."] = 1, ["<"] = 1, [">"] = 1,
                    W = 1, S = 1, A = 1, D = 1, C = 1, E = 1, Q = 1, Space = 1, Return = 1, Enter = 1,
                    X = 1, Z = 1, Tab = 1 }

-- choose the next (step 1) or previous (-1) of your balls
local function cycleBall(step)
  local list = playable(S.turn)
  if #list == 0 then return end
  local at = 1
  for i, b in ipairs(list) do if b.n == S.sel then at = i end end
  S.sel = list[(at - 1 + step) % #list + 1].n
  aimAtCup(S.sel)
  S.spinX, S.spinY, S.elev = 0, 0, 0
  S.dirty = true
end

local function onKey(N, key, down)
  local t = now()
  if key == "P" or key == "O" then
    if down then
      local side = (key == "P") and 1 or 2
      S.ctrl[side] = (S.ctrl[side] == "computer") and "human" or "computer"
      auto.phase = "idle"
      if S.state == "over" and S.ctrl[1] == "computer" and S.ctrl[2] == "computer" then newGame() end
      setView()
      S.dirty = true
    end
    return true
  end
  if key == "L" then
    if down then
      S.level = S.level % 3 + 1
      savePref("level", S.level)
      S.dirty = true
    end
    return true
  end
  if S.ctrl[S.turn] == "computer" and PLAY_KEYS[key] then return true end
  local slide, act = keyAction(key)
  if slide then
    if down then
      local r = released[key]
      if r and t - r.at < REPEAT_GAP then
        held[key] = { since = r.since, last = t }
      else
        held[key] = { since = t, last = t }
        act(SLIDES[slide][1])
      end
      released[key] = nil
    elseif held[key] then
      released[key] = { at = t, since = held[key].since }
      held[key] = nil
    end
    return true
  end
  if not down then
    held[key] = nil
    return OUR_KEYS[key] or false
  end
  if key == "Space" or key == "Return" or key == "Enter" then
    shoot()
    return true
  end
  if key == "Tab" or key == "X" or key == "Z" then
    if S.state == "aim" then cycleBall(key == "Z" and -1 or 1) end
    return true
  end
  if key == "C" then
    S.spinX, S.spinY = 0, 0
    S.dirty = true
    return true
  end
  if key == "G" then
    guide.mode = (guide.mode + 1) % 3
    S.dirty = true
    return true
  end
  local VIEW_KEYS = { V = "table", B = "cue", T = "top" }
  if VIEW_KEYS[key] then
    S.view = VIEW_KEYS[key]
    setView()
    S.dirty = true
    return true
  end
  if key == "N" or key == "R" then
    newGame()
    return true
  end
  return OUR_KEYS[key] or false
end
if v.onKey then v:onKey(onKey) end

-- held keys slide
local function keyTick()
  local t = now()
  for key, h in pairs(held) do
    local slide, act = keyAction(key)
    if not slide then
      held[key] = nil
    else
      local def = SLIDES[slide]
      local dt = t - h.last
      h.last = t
      local age = t - h.since
      if age > HOLD_DELAY and dt > 0 then
        local rate = math.min(def[3], def[2] + (def[3] - def[2]) * (age - HOLD_DELAY) / 1.5)
        act(rate * math.min(dt, 0.1))
      end
    end
  end
  for key, r in pairs(released) do
    if t - r.at > REPEAT_GAP then released[key] = nil end
  end
end

-- ---------------------------------------------------------------------
-- per frame
-- ---------------------------------------------------------------------

local shown = {}
local lastHelp = nil

local function refreshNow()
  local want = {
    left1 = tostring(5 - ballsSunk(1)),
    left2 = tostring(5 - ballsSunk(2)),
    wins = string.format("%d-%d", S.wins[1] % 100, S.wins[2] % 100),
    message = S.message,
    level = tostring(S.level),
  }
  for k, text in pairs(want) do
    if shown[k] ~= text then
      shown[k] = text
      board[k].set(text, k ~= "message")
    end
  end
  board.setForce(S.power)
  board.spinDot(S.spinX, S.spinY)
  board.setLamps(S.state == "over" and S.winner or S.turn)
  if S.state == "aim" then
    placeCue(1.0 + 12 * S.power)
    showSelector(balls[S.sel])
    drawGuide()
    if S.view == "cue" then setView() end
  elseif S.state == "over" then
    cue.hide()
    showSelector(nil)
    guide.clear()
  end
  local text = helpText()
  if text ~= lastHelp then
    lastHelp = text
    if v.setHelpText then v:setHelpText(text) end
  end
end
-- (nothing moves while the picture is brought up to date, and the aiming
-- guide alone reads each ball's position tens of thousands of times: read
-- them once, here)
local function refresh()
  if frozenXZ then return refreshNow() end
  frozenXZ = freezeXZ()
  local ok, err = pcall(refreshNow)
  frozenXZ = nil
  if not ok then error(err, 0) end
end

-- ---------------------------------------------------------------------
-- the computer player. For each ball it may play, it sends the ball off
-- in every direction (a degree apart) at eight speeds, and follows it --
-- off the cushions and bumpers, over the cups -- with trace(). Of the
-- shots that drop into its cup it takes the one that still drops with
-- the aim or force a little off (the safest), aimed at the middle of the
-- range of angles that work. With no pot worth trying it plays for
-- position: the ball nearest its cup with a clear run to it. Its level
-- sets how far its aim and force stray.
-- ---------------------------------------------------------------------

local AUTO_TURN = math.rad(120)   -- how fast it swings the cue (per second)
local AUTO_PAUSE = 0.6            -- a moment to settle before shooting
local LEVELS = {                  -- how far its aim (degrees) and force stray
  { aim = 3.0, power = 0.15 }, { aim = 0.8, power = 0.05 }, { aim = 0.1, power = 0.01 },
}
local SPEEDS = { 40, 58, 80, 108, 145, 195, 260, 350 }

local function gauss()
  local u1, u2 = math.max(1e-9, math.random()), math.random()
  return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
end

-- A clear straight run from (x, z) to a side's cup?
local function laneToCup(x, z, side, skip)
  local c = CUPS[side]
  local dx, dz = c.x - x, c.z - z
  local L2 = dx * dx + dz * dz
  local function blocked(px, pz, r)
    local t = L2 > 0 and clamp(((px - x) * dx + (pz - z) * dz) / L2, 0, 1) or 0
    local qx, qz = x + dx * t - px, z + dz * t - pz
    return qx * qx + qz * qz < r * r
  end
  for _, bp in ipairs(BUMPERS) do
    if blocked(bp[1], bp[2], K.R + K.RB) then return false end
  end
  for n = 1, NB do
    local b = balls[n]
    if b.onTable and n ~= skip then
      local bx, bz = ballXZ(b)
      if blocked(bx, bz, K.D) then return false end
    end
  end
  return true
end

function auto.plan(side)
  local cands = markedUp(side) and { balls[MARKED[side]] } or playable(side)
  if #cands == 0 then return { n = S.sel, aim = S.aim, power = S.power } end
  local saved = { S.sel, S.aim, S.spinX, S.spinY, S.elev, cue.elev, S.power }
  S.spinX, S.spinY, S.elev = 0, 0, 0
  local function ok(r)
    return (not S.opening) or r.first == "side"
  end
  local pots, bestPos, bestPosScore = {}, nil, nil
  local cup = CUPS[side]
  for _, b in ipairs(cands) do
    local bx, bz = ballXZ(b)
    S.sel = b.n
    for deg = 0, 359 do
      planPace()
      local a = math.rad(deg)
      -- (a direction it can't be played in without raising the cue a lot
      -- over a bumper or a ball -- the shot would curve -- is left out)
      S.aim = a
      if cueElevation(3.5) <= math.rad(12) then
        local dx, dz = math.cos(a), math.sin(a)
        for _, v0 in ipairs(SPEEDS) do
          local r = trace(bx, bz, dx, dz, v0, b.n)
          if ok(r) then
            if r.kind == "cup" then
              if r.cup == side then pots[#pots + 1] = { b = b, a = a, v0 = v0, bounces = r.bounces } end
            else
              local d = math.sqrt((r.x - cup.x) ^ 2 + (r.z - cup.z) ^ 2)
              local sc = d + (S.opening and 0 or ((laneToCup(r.x, r.z, side, b.n) and 0 or 25)
                                                 + (r.kind == "ball" and 30 or 0)))
              -- (and not near the other cup, where a nudge could drop it)
              local oc = CUPS[3 - side]
              if (r.x - oc.x) ^ 2 + (r.z - oc.z) ^ 2 < 15 * 15 then sc = sc + 40 end
              -- (and simple: every bounce, and speed, makes it less sure; a
              -- ball that runs over the other cup might drop)
              sc = sc + 4 * r.bounces + v0 / 20
              if r.skipped and r.skipped[3 - side] then sc = sc + 60 end
              if not bestPosScore or sc < bestPosScore then
                bestPos, bestPosScore = { b = b, a = a, v0 = v0 }, sc
              end
            end
          end
        end
      end
    end
  end
  local wrong = false     -- (set by drops(): that shot ended in the other cup)
  local function drops(b, a, v0)
    local bx, bz = ballXZ(b)
    local r = trace(bx, bz, math.cos(a), math.sin(a), v0, b.n)
    wrong = r.kind == "cup" and r.cup ~= side
    return r.kind == "cup" and r.cup == side and ok(r)
  end
  -- the safest pots: those that still drop with the aim or force a little off
  for _, p in ipairs(pots) do
    planPace()
    local sc = 0
    for _, da in ipairs({ -0.8, -0.4, 0.4, 0.8 }) do
      if drops(p.b, p.a + math.rad(da), p.v0) then sc = sc + 1 elseif wrong then sc = sc - 3 end
    end
    for _, f in ipairs({ 0.9, 1.1 }) do
      if drops(p.b, p.a, p.v0 * f) then sc = sc + 1 elseif wrong then sc = sc - 3 end
    end
    p.score = sc - 0.1 * p.bounces - p.v0 / 5000
  end
  table.sort(pots, function(a, b) return a.score > b.score end)
  if S.level == 1 then
    -- (at level 1 it doesn't look for the safest: any pot it sees will do)
    for i = #pots, 2, -1 do
      local j = math.random(i)
      pots[i], pots[j] = pots[j], pots[i]
    end
  end
  -- the best few, aimed at the middle of the range of angles that drop,
  -- checked with the aiming guide's fuller model of the ball's motion
  local best, bestHits
  for i = 1, math.min(S.level == 1 and 2 or 10, #pots) do
    local p = pots[i]
    local lo, hi = 0, 0
    for k = 1, 20 do
      planPace()
      if drops(p.b, p.a - math.rad(0.1 * k), p.v0) then lo = k else break end
    end
    for k = 1, 20 do
      planPace()
      if drops(p.b, p.a + math.rad(0.1 * k), p.v0) then hi = k else break end
    end
    p.a = p.a + math.rad(0.1 * (hi - lo) / 2)
    local hits = 0
    S.sel, S.power = p.b.n, p.v0 / K.VMAX
    for _, da in ipairs({ 0, -0.3, 0.3 }) do
      planPace()
      S.aim = p.a + math.rad(da)
      cue.elev = cueElevation(1.0 + 12 * S.power)
      local _, _, _, kind, _, _, _, c = predictShot(12)
      if kind == "cup" and c == side then hits = hits + 1 end
    end
    if not bestHits or hits > bestHits then best, bestHits = p, hits end
    if hits == 3 then break end
  end
  local shot
  if best and bestHits > 0 and (best.score >= 1.5 or bestHits == 3 or not bestPos or bestPosScore > 35) then
    shot = { n = best.b.n, aim = best.a, v0 = best.v0, pot = true }
  elseif bestPos then
    shot = { n = bestPos.b.n, aim = bestPos.a, v0 = bestPos.v0 }
  else
    local b = cands[1]
    local bx, bz = ballXZ(b)
    shot = { n = b.n, aim = math.atan2(cup.z - bz, cup.x - bx), v0 = 80 }
  end
  S.sel, S.aim, S.spinX, S.spinY, S.elev, cue.elev, S.power = saved[1], saved[2], saved[3], saved[4], saved[5], saved[6], saved[7]
  -- how far its hand strays
  local lv = LEVELS[S.level] or LEVELS[2]
  shot.aim = shot.aim + math.rad(lv.aim) * gauss()
  shot.power = clamp(shot.v0 / K.VMAX * (1 + lv.power * gauss()), 0.02, 1)
  return shot
end

-- One step of the computer's play, from the draw loop.
function auto.tick()
  local t = now()
  if S.state == "over" then
    -- computer against computer: the next game after a few seconds
    if S.ctrl[1] == "computer" and S.ctrl[2] == "computer" and t - (auto.overAt or t) > 4 then newGame() end
    auto.last = t
    return
  end
  if S.state ~= "aim" or S.ctrl[S.turn] ~= "computer" then
    auto.phase = "idle"
    auto.last = t
    return
  end
  if auto.phase == "idle" then
    -- start thinking (see "thinking a little at a time"); it carries on
    -- below, this frame and the next few
    local side = S.turn
    auto.planning = planStart(function() return auto.plan(side) end)
    auto.planFor, auto.phase = side, "plan"
  end
  if auto.phase == "plan" then
    if S.turn ~= auto.planFor then
      auto.planning, auto.phase = nil, "idle"        -- (the table changed: start again)
    else
      local done, shot = planStep(auto.planning)
      if done then
        local still = stillFrozen(auto.planning.xz)
        auto.planTime = auto.planning.cpu
        auto.planning, auto.phase = nil, "idle"
        if still then
          auto.shot = shot
          S.sel = auto.shot.n
          S.spinX, S.spinY, S.elev = 0, 0, 0
          auto.phase, auto.t = "turn", t
          if S.view == "cue" then setView() end
          S.dirty = true
        end
      end
    end
  elseif auto.phase == "turn" then
    local dt = math.min(0.1, t - (auto.last or t))
    local diff = (auto.shot.aim - S.aim + math.pi) % (2 * math.pi) - math.pi
    local turn = AUTO_TURN * dt
    local done = math.abs(diff) <= turn
    S.aim = done and auto.shot.aim or S.aim + (diff > 0 and turn or -turn)
    local dp = auto.shot.power - S.power
    local pstep = 0.8 * dt
    if math.abs(dp) <= pstep then S.power = auto.shot.power else S.power = S.power + (dp > 0 and pstep or -pstep); done = false end
    S.dirty = true
    if done then auto.phase, auto.t = "settle", t end
  elseif auto.phase == "settle" then
    if t - auto.t >= AUTO_PAUSE then
      auto.phase = "idle"
      shoot()
    end
  end
  auto.last = t
end

-- Memory. bpp stops Lua's garbage collector (so it can never free a
-- Bullet object C++ still points to), so every temporary vector this
-- script makes would be kept forever. Everything this script creates that
-- C++ holds on to is either added to the world or kept in the script's
-- own tables, so a collection here frees only garbage. Every 120 calls it
-- collects, then stops the collector again as bpp wants it.
local gcCalls = 0
local function gcTick()
  -- (a bpp that collects garbage itself, BPP_GC_AUTO, needs none of this)
  if BPP_GC_AUTO then return end
  gcCalls = gcCalls + 1
  if gcCalls >= 120 then
    gcCalls = 0
    collectgarbage("collect")
    collectgarbage("stop")
  end
end

-- the draw loop runs whether or not the simulation is: keys and the view
v:preDraw(function(N)
  gcTick()
  keyTick()
  auto.tick()
  if S.dirty then
    S.dirty = false
    refresh()
  end
end)

v:preSim(function(N)
  -- the stroke: the cue drives forward and strikes
  if S.state == "stroke" then
    S.strokeFrame = S.strokeFrame + 1
    local gap0 = 1.0 + 12 * S.power
    local f = S.strokeFrame / K.STROKE_FRAMES
    if f < 1 then
      placeCue(gap0 * (1 - f * f))
    else
      placeCue(0)
      strike()
      S.state = "rolling"
      S.rollFrames = 0
      S.stillFrames = 0
      S.followFrom = { cueGeometry(cue.elev or MIN_ELEV, 0) }
    end
    return
  end

  -- the cloth: rolling resistance, and side spin wearing off
  for n = 1, NB do
    local b = balls[n]
    local o = b.obj
    if b.onTable and select(2, posXYZ(o)) < K.R + 0.2 then   -- (not in the air)
      local vx, vy, vz = velXYZ(o)
      local wx, wy, wz = spinXYZ(o)
      local sp = math.sqrt(vx * vx + vz * vz)
      local wr = math.sqrt(wx * wx + wz * wz) * K.R
      if sp < K.STOP_V and wr < 1.5 * K.STOP_V and math.abs(wy) < 0.5 then
        if sp > 0 or wr > 0 or wy ~= 0 then
          setVel(o, 0, vy, 0)
          setSpin(o, 0, 0, 0)
        end
      else
        local f = sp > 0 and math.max(0, sp - K.ROLL_DECEL * K.FRAME) / sp or 1
        local dwy = K.SPIN_DECEL * K.FRAME
        wy = (math.abs(wy) <= dwy) and 0 or (wy - dwy * (wy > 0 and 1 or -1))
        setVel(o, vx * f, vy, vz * f)
        setSpin(o, wx * f, wy, wz * f)
      end
    end
  end
end)

local MAX_SOUNDS_PER_FRAME = 6

-- The cushions and bumpers. Bullet on its own makes them feel dead: its
-- solver starts braking a ball a step before it touches, which swallows a
-- slow ball's bounce, and a rolling ball keeps its forward spin through
-- the bounce, so the cloth drags it back. So whenever a ball hits one,
-- the script sets the rebound: E of the speed it arrived with, straight
-- off, and its roll into the cushion replaced by a roll away from it (a
-- cushion's nose, above the middle of the ball, grips it and takes that
-- spin away; a bumper's ring does much the same). Returns what it hit.
local function cushionBounce(b, x, z)
  local nx, nz, gap, e, kind
  for _, l in ipairs(cushionLines) do
    local lx, lz = l.x2 - l.x1, l.z2 - l.z1
    local L2 = lx * lx + lz * lz
    local t = L2 > 0 and clamp(((x - l.x1) * lx + (z - l.z1) * lz) / L2, 0, 1) or 0
    local qx, qz = x - (l.x1 + lx * t), z - (l.z1 + lz * t)
    local d = math.sqrt(qx * qx + qz * qz)
    local g = d - K.R - l.r
    if d > 1e-6 and (not gap or g < gap) then
      nx, nz, gap, kind = qx / d, qz / d, g, l.kind
      e = (l.kind == "bumper") and E_BUMPER or E_CUSHION
    end
  end
  if not gap or gap > 6 then return nil end
  local o = b.obj
  local vx, vy, vz = velXYZ(o)
  local before = -(b.vx * nx + b.vz * nz)
  local now_ = -(vx * nx + vz * nz)
  if not (before > 0.5 and gap < 0.5 + math.max(0, -now_) * K.FRAME
          and now_ < 0.9 * before - 0.3) then
    return nil
  end
  local off = math.max(e * before, -now_)
  setVel(o, vx + (off + now_) * nx, vy, vz + (off + now_) * nz)
  local ax, az = -nz, nx
  local wx, wy, wz = spinXYZ(o)
  local rollBefore = (b.wx or 0) * ax + (b.wz or 0) * az
  local rollNow = wx * ax + wz * az
  local target = -ROLL_AFTER * off / K.R
  if rollBefore < 0 then target = math.min(rollNow, target) end
  setSpin(o, wx + (target - rollNow) * ax, wy, wz + (target - rollNow) * az)
  b.firstContact = b.firstContact or kind
  return kind
end

-- what a ball at (x, z) is touching, if anything: "ball", "bumper", or a
-- cushion ("side" or "end")
local function touching(n, x, z)
  for m = 1, NB do
    local o = balls[m]
    if m ~= n and o.onTable then
      local ox, oz = ballXZ(o)
      if (ox - x) ^ 2 + (oz - z) ^ 2 < (K.D + 1.0) ^ 2 then return "ball", m end
    end
  end
  for _, bp in ipairs(BUMPERS) do
    if (bp[1] - x) ^ 2 + (bp[2] - z) ^ 2 < (K.R + K.RB + 1.0) ^ 2 then return "bumper" end
  end
  if math.abs(z) > LIM_Z - 1.0 then return "side" end
  if math.abs(x) > LIM_X - 1.0 then return "end" end
  return nil
end

v:postSim(function(N)
  S.frame = N
  gcTick()
  -- follow-through: the cue carries on a little after the hit
  if S.state == "rolling" and S.rollFrames == 45 then
    cue.hide()
  elseif S.state == "rolling" and S.rollFrames < 6 and S.followFrom then
    local f = S.followFrom
    local d = (S.rollFrames + 1) * 1.0
    cue.place(f[1] - f[4] * d, f[2] - f[5] * d, f[3] - f[6] * d, f[4], f[5], f[6])
  end
  -- balls dropping into the cups (for show)
  for c, sk in ipairs(sinkers) do
    if sk.frames >= 0 then
      sk.frames = sk.frames + 1
      local cup = CUPS[c]
      sk.x, sk.z = sk.x + (cup.x - sk.x) * 0.35, sk.z + (cup.z - sk.z) * 0.35
      sk.vy = sk.vy - K.G * K.FRAME
      sk.y = sk.y + sk.vy * K.FRAME
      if sk.frames > 14 then
        sk.frames = -1
        sk.obj.pos = btVector3(0, -150, 0)
      else
        sk.obj.pos = btVector3(sk.x, sk.y, sk.z)
      end
    end
  end

  local moving = false
  local sounds = 0
  local rolling = (S.state == "rolling")
  for n = 1, NB do
    local b = balls[n]
    if b.onTable then
      local o = b.obj
      local x, y, z = posXYZ(o)
      local vx, vy, vz = velXYZ(o)
      -- over a cup: does it fall in? (only a ball down on the cloth)
      local dropped = nil
      local inside = false
      if y < K.R + 0.5 then
        for c, cup in ipairs(CUPS) do
          local rx, rz = x - cup.x, z - cup.z
          if rx * rx + rz * rz < K.CUP_R * K.CUP_R then
            inside = true
            b.holeT = (b.holeT or 0) + K.FRAME
            if fallsIn(rx, rz, vx, vz, b.holeT) then dropped = c end
          end
        end
      end
      if not inside then b.holeT = 0 end
      -- jumping (a foul)
      if rolling and y > K.R + K.JUMP_FOUL then
        b.jumped = true
        S.jumped = true
      end
      -- off the table: past the rails, fallen, or come to rest on a rail
      local off = math.abs(x) > K.OUT_X or math.abs(z) > K.OUT_Z or y < -5
      if not off and y > K.RAIL_H and (math.abs(x) > K.HL or math.abs(z) > K.HW) then
        if vx * vx + vy * vy + vz * vz < 9 then
          b.railFrames = (b.railFrames or 0) + 1
          off = b.railFrames > 30
        else
          b.railFrames = 0
        end
      end
      if dropped then
        sinkBall(b, dropped)
        S.dirty = true
      elseif off then
        offTable(b)
        S.dirty = true
      else
        -- landing from a jump: the cloth bounces it back up
        if (b.vy or 0) < -K.LAND_MIN and vy > -5 and y < K.R + 0.3 then
          local land = -(b.vy or 0) + K.G * K.FRAME
          vy = K.LAND_E * land
          setVel(o, vx, vy, vz)
          playSound("cushion", math.min(1, land / 400))
        end
        b.vy = vy
        if y < K.R + 0.5 and cushionBounce(b, x, z) then   -- (its velocity changed)
          vx, vy, vz = velXYZ(o)
        end
        -- a sudden change of velocity is a collision: click (and note what
        -- it touched first)
        local dvx, dvz = vx - b.vx, vz - b.vz
        local dv = math.sqrt(dvx * dvx + dvz * dvz)
        if dv > 20 then
          local kind, m = touching(n, x, z)
          if rolling and kind then b.firstContact = b.firstContact or kind end
          if kind == "ball" and m < n then kind = nil end        -- (the other ball clicks)
          if kind and sounds < MAX_SOUNDS_PER_FRAME then
            local snd = (kind == "side" or kind == "end") and "cushion" or kind
            playSound(snd, math.min(1, (dv / (snd == "ball" and 500 or 400)) ^ 0.7))
            sounds = sounds + 1
          end
        end
        b.vx, b.vz = vx, vz
        local wx, wy, wz = spinXYZ(o)
        b.wx, b.wz = wx, wz
        if vx * vx + vz * vz + vy * vy > 0.25 or y > K.R + 0.3
           or (wx * wx + wy * wy + wz * wz) > 0.05 then
          moving = true
        end
        syncMark(b)
      end
    end
  end

  if rolling then
    S.rollFrames = S.rollFrames + 1
    if moving and S.rollFrames < 60 * 40 then
      S.stillFrames = 0
    else
      S.stillFrames = S.stillFrames + 1
      if S.stillFrames >= 8 then shotOver() end
    end
    if N % 10 == 0 then S.dirty = true end
  end
  if TF and TF.onFrame then TF.onFrame(N) end
end)

-- exposed for scripted testing (bpp -f runs have no keyboard)
TF = {
  S = S, K = K, balls = balls, CUPS = CUPS, BUMPERS = BUMPERS, MARKS = MARKS, NB = NB, guide = guide,
  onKey = function(key, down) return onKey(S.frame, key, down) end,
  shoot = function(aimDeg, power, spinX, spinY, n)
    if n then S.sel = n end
    S.aim = math.rad(aimDeg)
    S.power = power
    S.spinX, S.spinY = spinX or 0, spinY or 0
    S.elev = 0
    cue.elev = cueElevation(1.0 + 12 * power)
    return shoot()
  end,
  place = function(n, x, z) balls[n].onTable = true; balls[n].inCup = nil; placeBall(balls[n], x, z) end,
  newGame = newGame, auto = auto, planStart = planStart, planStep = planStep, trace = trace, predict = predictShot, shotOver = shotOver,
  helpText = helpText, refresh = refresh, startTurn = startTurn, sink = sinkBall,
  ballsSunk = ballsSunk, removeFromTray = removeFromTray, arrangeTray = arrangeTray,
  setView = function(view) S.view = view; setView() end,
}

-- ---------------------------------------------------------------------
-- start
-- ---------------------------------------------------------------------

math.randomseed(os.time())
newGame()
setView()
refresh()
