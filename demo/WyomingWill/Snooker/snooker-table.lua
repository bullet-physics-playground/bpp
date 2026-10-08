--
-- SNOOKER TABLE -- one-player snooker on a full-size 12-foot table, for
-- the Bullet Physics Playground: practise break building, or press P and
-- the computer plays. Bullet does the balls, cushions and pockets; you
-- work the cue from the keyboard.
--
-- THE GAME: a full frame's balls -- 15 reds and the six colours on their
-- spots. Break off from the D. Pot a red (1 point), then a colour of your
-- choice (yellow 2, green 3, brown 4, blue 5, pink 6, black 7), which comes
-- back onto its spot; then a red again, and so on. When the reds are gone,
-- pot the colours in order, yellow to black. Every point you score without
-- a miss is your break; a miss or a foul ends it, and you carry on from
-- where the balls lie with a new break (the ball "on" goes back to a red,
-- or the lowest colour once the reds are gone). The highest break is kept.
-- 147 is the maximum.
--
-- FOULS end the break and are counted with the points they would give an
-- opponent (the value of the ball on or the ball concerned, at least 4):
-- the cue ball in a pocket (in-off, then ball in hand in the D), hitting
-- nothing, hitting a ball that isn't on first, potting a ball that isn't
-- on, or a ball leaving the table. Colours potted on a foul are respotted;
-- reds stay down. After a red, the colour you hit first is the one you
-- chose.
--
-- KEYS (click the 3D view first so it has keyboard focus; the Shortcuts
-- pane shows them too, with the ball on, the aim, force and spin):
--   Left / Right     aim: a tap turns 0.25 degrees; hold to swing
--   ,  /  .          fine aim: a tap turns 0.02 degrees
--   Up / Down        force (1% a tap; hold to slide)
--   W / S            hit the cue ball higher (follow) or lower (draw)
--   A / D            hit it left or right of centre (side spin)
--   C                back to a centre hit (every shot starts from one,
--                    with the cue level)
--   E / Q            raise / lower the back of the cue (masse; a jump
--                    shot is possible but, as in the rules, the table
--                    doesn't stop you: a ball leaving the table is a foul)
--   Space / Return   shoot
--   G                aiming guide on or off (the ghost ball turns red when
--                    the first ball the cue ball will hit isn't on)
--   V                back to the starting view (also undoes mouse turning)
--   B                camera behind the cue (it follows your aim)
--   T                camera overhead
--   N or R           re-rack: a new frame
--   P                the computer plays (it pots, plans its position for
--                    the next ball, and breaks off). P again to take over.
-- With ball in hand the arrows move the cue ball around the D (Up is away
-- from you) and Space or Return puts it down.
--
-- UNITS: centimetres, seconds, kilograms. The table's long axis is X (the
-- baulk end, where you break from, at -X), across it is Z, up is Y. The
-- playing surface is 356.9 x 177.8 cm between the cushion noses; balls are
-- 52.5 mm.
--
-- FILES
--   snooker-table.lua        this table
--   snooker-table-meshes/    the cue and the cue ball's dots
--   snooker-table-sounds/    sound effects; missing ones are skipped
-- The balls' pictures, snooker-*.jpeg, are in bpp's own includes directory,
-- where POV-Ray looks too.
--
-- Needs bpp with the v:onKey() keyboard hook; v:playSound(id, volume) and
-- the objects' `collides` property are used when present (see the Pool
-- Table's README).
--

local common = require "common"

local SOUND_DIR = "snooker-table-sounds/"
local MESH_DIR = "snooker-table-meshes/"
local PREFS_PREFIX = "snooker-table/"

-- ---------------------------------------------------------------------
-- dimensions and physics
-- ---------------------------------------------------------------------

local K = {
  R = 2.625,             -- ball radius (52.5 mm balls)
  MASS = 0.142,
  HL = 178.45, HW = 88.9, -- half the playing surface (cushion nose to nose)
  G = 981,
  FRAME = 1 / 60,
  CORNER_CUT = 6.3,      -- cushions stop this far from each corner (8.9 cm mouth)
  SIDE_HALF = 5.05,      -- half the middle pocket mouth (10.1 cm)
  CUSHION_H = 4.0,       -- cushion top
  CUSHION_T = 5.0,       -- nose to rail
  RAIL_W = 12,           -- the wooden rail's width
  RAIL_H = 5.0,          -- its top
  VMAX = 1150,           -- cue ball speed at full force
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
  BAULK = 73.7,          -- baulk line, from the baulk cushion
  D_R = 29.2,            -- radius of the D
  BLACK_FROM_TOP = 32.4, -- black spot, from the top cushion
}
K.D = 2 * K.R
K.NOSE_H = 0.635 * K.D                      -- cushion nose height
K.NOSE_TILT = math.asin((K.NOSE_H - K.R) / K.R)   -- its contact angle
K.RAIL_IN_X = K.HL + K.CUSHION_T            -- rail's inner edge
K.RAIL_IN_Z = K.HW + K.CUSHION_T
K.OUT_X = K.RAIL_IN_X + K.RAIL_W            -- table's outer edge
K.OUT_Z = K.RAIL_IN_Z + K.RAIL_W
K.BAULK_X = -K.HL + K.BAULK                 -- the baulk line's x

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
  cloth = "#0e6b34", cushion = "#0b5a2c", rail = "#4a2410", apron = "#2f170a",
  pocket = "#050505", line = "#e6eee4",
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

-- A cushion or jaw: a rubber nose along (x1,z1)-(x2,z2), on the side away
-- from the point (awayX, awayZ) -- the side the balls come from. As on a
-- real table the nose is a little above the middle of the ball
-- (K.NOSE_H), so its face leans over the cloth: a ball driven into it is
-- pressed down onto the cloth instead of climbing the rubber.
local xAxis = btVector3(1, 0, 0)
local cushionLines = {}     -- every cushion's and jaw's nose, for cushionBounce()
local function cushion(x1, z1, x2, z2, thick, awayX, awayZ, col, rest)
  local dx, dz = x2 - x1, z2 - z1
  local len = math.sqrt(dx * dx + dz * dz)
  local nx, nz = -dz / len, dx / len
  local mx, mz = (x1 + x2) / 2, (z1 + z2) / 2
  if (awayX - mx) * nx + (awayZ - mz) * nz > 0 then nx, nz = -nx, -nz end
  -- (nx, nz) now points into the cushion. The box's local X runs along
  -- the nose, local Z into the cushion; turn it so local Z matches (nx, nz).
  local yaw = -math.atan2(dz, dx)
  if math.sin(yaw) * nx + math.cos(yaw) * nz < 0 then yaw = yaw + math.pi end
  local a = K.NOSE_TILT
  local H, noseY = 5.0, 1.7          -- box height; nose's height in the box
  local q = btQuaternion(yAxis, yaw) * btQuaternion(xAxis, -a)
  -- where the box's centre goes so the nose lands on the line at NOSE_H
  local offY = noseY * math.cos(a) - (thick / 2) * math.sin(a)
  local offU = -noseY * math.sin(a) - (thick / 2) * math.cos(a)
  local c = Cube(len, H, thick, 0)
  c.trans = btTransform(q, btVector3(mx - offU * nx, K.NOSE_H - offY, mz - offU * nz))
  c.col = col or COL.cushion
  c.friction = 0.8
  c.restitution = rest or 0.86
  v:add(c)
  cushionLines[#cushionLines + 1] = { x1 = x1, z1 = z1, x2 = x2, z2 = z2, jaw = thick < 2 }
  return c
end

-- A pocket, as seen: a black well from the cloth up to the rail top,
-- behind the mouth. Balls that drop are hidden in it for a moment.
local function pocketHole(x, z, r)
  local c = Cylinder(r, K.RAIL_H + 0.3, 0)
  c.trans = btTransform(UPRIGHT, btVector3(x, (K.RAIL_H + 0.3) / 2, z))
  c.col = COL.pocket
  addVisual(c)
end

-- pockets: mouth midpoint (mx, mz), outward direction (nx, nz), half the
-- mouth, and how far past the mouth the ball's centre must go to drop
local pockets = {}
-- the spots the colours sit on
local SPOTS = {
  [2] = { K.BAULK_X, K.D_R },               -- yellow: right-hand corner of the D
  [3] = { K.BAULK_X, -K.D_R },              -- green: left-hand corner
  [4] = { K.BAULK_X, 0 },                   -- brown: middle of the baulk line
  [5] = { 0, 0 },                           -- blue: the centre spot
  [6] = { K.HL / 2, 0 },                    -- pink: the pyramid spot
  [7] = { K.HL - K.BLACK_FROM_TOP, 0 },     -- black
}
do
  local HL, HW, C = K.HL, K.HW, K.CORNER_CUT
  local r2 = math.sqrt(0.5)

  -- the cloth (a thick slab, so a ball driven down hard can't pass through
  -- it) and the table below
  local cloth = box(0, -5, 0, 2 * K.RAIL_IN_X, 10, 2 * K.RAIL_IN_Z, COL.cloth)
  cloth.friction = 1.0
  cloth.restitution = 0.0
  box(0, -12, 0, 2 * K.OUT_X, 20, 2 * K.OUT_Z, COL.apron)
  for _, sx in ipairs({ -1, 0, 1 }) do
    for _, sz in ipairs({ -1, 1 }) do
      box(sx * (K.OUT_X - 16), -52, sz * (K.OUT_Z - 16), 16, 60, 16, COL.apron)   -- legs
    end
  end

  -- long cushions (two on each side, split by the middle pocket) and short ones
  for _, sz in ipairs({ -1, 1 }) do
    cushion(-HL + C, sz * HW, -K.SIDE_HALF, sz * HW, K.CUSHION_T, 0, 0)
    cushion(K.SIDE_HALF, sz * HW, HL - C, sz * HW, K.CUSHION_T, 0, 0)
  end
  for _, sx in ipairs({ -1, 1 }) do
    cushion(sx * HL, -HW + C, sx * HL, HW - C, K.CUSHION_T, 0, 0)
  end

  -- corner pockets: the jaws point out along the diagonal, closing in 7
  -- degrees so the pocket narrows as the ball goes in
  local JAW = 8
  local function jaw(ax, az, dirx, dirz, towardX, towardZ)
    cushion(ax, az, ax + dirx * JAW, az + dirz * JAW, 1.5, towardX, towardZ, COL.cushion, 0.6)
  end
  for _, sx in ipairs({ -1, 1 }) do
    for _, sz in ipairs({ -1, 1 }) do
      local Ax, Az = sx * (HL - C), sz * HW            -- jaw on the long cushion
      local Bx, Bz = sx * HL, sz * (HW - C)            -- jaw on the short cushion
      local mx, mz = (Ax + Bx) / 2, (Az + Bz) / 2
      local nx, nz = sx * r2, sz * r2
      local t = math.tan(math.rad(7))
      for _, j in ipairs({ { Ax, Az }, { Bx, Bz } }) do
        local ix, iz = mx - j[1], mz - j[2]            -- toward the pocket's middle
        local il = math.sqrt(ix * ix + iz * iz)
        local fx, fz = nx + t * ix / il, nz + t * iz / il
        local fl = math.sqrt(fx * fx + fz * fz)
        jaw(j[1], j[2], fx / fl, fz / fl, mx + nx * 4, mz + nz * 4)
      end
      pockets[#pockets + 1] = { mx = mx, mz = mz, nx = nx, nz = nz, half = C * r2,
                                depth = 1.8, corner = true }
      pocketHole(sx * HL + nx * 1.2, sz * HW + nz * 1.2, 5.2)
    end
  end

  -- middle pockets: the jaws flare 14 degrees, wider at the mouth
  for _, sz in ipairs({ -1, 1 }) do
    local t = math.tan(math.rad(14))
    for _, sx in ipairs({ -1, 1 }) do
      local fx, fz = -sx * t, sz
      local fl = math.sqrt(fx * fx + fz * fz)
      jaw(sx * K.SIDE_HALF, sz * HW, fx / fl, fz / fl, 0, sz * (HW + 4))
    end
    pockets[#pockets + 1] = { mx = 0, mz = sz * HW, nx = 0, nz = sz, half = K.SIDE_HALF,
                              depth = 1.5, corner = false }
    pocketHole(0, sz * (HW + 5.4), 5.1)
  end

  -- the wooden rails around it all (they close off the back of the pockets)
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

  -- the markings: the baulk line, the D, and the spots
  local function mark(x, z, len, yaw)
    local c = Cube(len, 0.02, 0.12, 0)
    c.trans = btTransform(btQuaternion(yAxis, yaw), btVector3(x, 0.01, z))
    c.col = COL.line
    c.pov_export = false
    addVisual(c)
  end
  mark(K.BAULK_X, 0, 2 * HW, math.pi / 2)
  local N = 40
  for i = 0, N - 1 do
    local a1 = math.pi / 2 + math.pi * i / N
    local a2 = math.pi / 2 + math.pi * (i + 1) / N
    local x1, z1 = K.BAULK_X + K.D_R * math.cos(a1), K.D_R * math.sin(a1)
    local x2, z2 = K.BAULK_X + K.D_R * math.cos(a2), K.D_R * math.sin(a2)
    mark((x1 + x2) / 2, (z1 + z2) / 2, math.sqrt((x2 - x1) ^ 2 + (z2 - z1) ^ 2) + 0.05,
         -math.atan2(z2 - z1, x2 - x1))
  end
  for _, s in pairs(SPOTS) do disc(s[1], 0, s[2], 0.45, COL.line) end

  -- the ball tray along the far side, where potted balls are lined up
  local TZ = K.OUT_Z + 7
  local TL = 130
  box(0, -4, TZ, TL, 2, 8, COL.apron)
  box(0, -1, TZ + 4.5, TL, 8, 1, COL.apron)
  box(0, -3.5, TZ - 4.5, TL, 3, 1, COL.apron)
  box(-TL / 2 - 0.5, -1, TZ, 1, 8, 10, COL.apron)
  box(TL / 2 + 0.5, -1, TZ, 1, 8, 10, COL.apron)
  K.TRAY_Z, K.TRAY_Y = TZ, -3 + K.R
end

-- ---------------------------------------------------------------------
-- the balls: [0] the cue ball, [1..15] the reds, [16..21] the colours
-- ---------------------------------------------------------------------

local NB = 21
local WHITE = "#f4f1e8"
local COLOUR_COLS = { [2] = "#f2c400", [3] = "#0e7a3b", [4] = "#6b3a1e", [5] = "#1d55c4",
                      [6] = "#ff8fb3", [7] = "#111111" }
local RED_COL = "#c1121f"
local COLOUR_NAMES = { [2] = "yellow", [3] = "green", [4] = "brown", [5] = "blue", [6] = "pink",
                       [7] = "black" }
local COLOUR_BALL = {}        -- value -> ball index

-- Snooker balls carry no numbers, so they can't wear the pool table's
-- includes/ball0..15.jpeg. These are pictures of bare phenolic resin instead:
-- each is its ball's colour above with a little mottling in it. `tex` draws
-- them in the view and exports them as an image_map, so a render shows the
-- same balls.
local function ballTex(value)
  local name = (value == 0) and "cue" or (value == 1) and "red" or COLOUR_NAMES[value]
  return "snooker-" .. name .. ".jpeg"
end

-- A mesh that follows a ball around (the cue ball's dots), or a cue part.
local function marking(file, col)
  local ok, m = pcall(function() return Mesh(MESH_DIR .. file, 0, false) end)
  if not ok or not m then return nil end
  m.col = col
  m.pov_export = false
  addVisual(m)
  return m
end

local balls = {}
for n = 0, NB do
  local value = (n == 0) and 0 or (n <= 15 and 1 or n - 14)
  local col = n == 0 and WHITE or (n <= 15 and RED_COL or COLOUR_COLS[value])
  local s = Sphere(K.R, K.MASS)
  s.col = col
  pcall(function() s.tex = ballTex(value) end)    -- without it, the colour stands in
  s.friction = 0.2
  s.restitution = 0.97
  s.damp_lin = 0
  s.damp_ang = 0
  v:add(s)
  s.body:setActivationState(4)          -- never goes to sleep
  s.body:setCcdMotionThreshold(K.R * 0.5)
  s.body:setCcdSweptSphereRadius(K.R * 0.9)
  local mark = (n == 0) and marking("cue-dots.obj", "#c62828") or nil
  balls[n] = { n = n, obj = s, mark = mark, onTable = true, vx = 0, vz = 0, value = value,
               red = (n >= 1 and n <= 15), colour = (n >= 16) }
  if n >= 16 then COLOUR_BALL[value] = n end
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

-- a random orientation, so the spots and stripes don't all line up
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
  b.vx, b.vz, b.vy, b.railFrames = 0, 0, 0, 0
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
-- ---------------------------------------------------------------------
-- sounds: optional files in SOUND_DIR; missing ones are skipped
-- ---------------------------------------------------------------------

local SOUNDS = {
  cue = "cue_hit.wav",          -- the tip strikes the cue ball
  ball = "ball_hit.wav",        -- two balls click (played softer for gentle hits)
  cushion = "cushion.wav",      -- a ball hits a cushion
  pocket = "pocket.wav",        -- a ball drops
  scratch = "scratch.wav",      -- the cue ball drops
  rack = "rack.wav",            -- the balls are set up
  cleared = "table_cleared.wav", -- the frame is cleared
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
-- the scoreboard: seven-segment digits on a panel past the top of the
-- table, facing the player
-- ---------------------------------------------------------------------

local board = {}
local CHARS = {
  ["0"] = 63, ["1"] = 6, ["2"] = 91, ["3"] = 79, ["4"] = 102, ["5"] = 109,
  ["6"] = 125, ["7"] = 7, ["8"] = 127, ["9"] = 111,
  A = 119, B = 124, C = 57, D = 94, E = 121, F = 113, G = 61, H = 118, I = 48,
  J = 30, L = 56, N = 84, O = 63, P = 115, R = 80, S = 109, T = 120, U = 62,
  Y = 110, K = 117, ["-"] = 64, [" "] = 0,
}
do
  local SC = 1.3                     -- everything on the panel, bigger than the pool table's
  local PX = K.OUT_X + 50            -- the panel's face
  local Y0 = 25 - 14 * SC             -- (the pool board's heights, scaled; its bottom at 25 cm)
  local function Y(y) return Y0 + y * SC end
  local panel = Cube(1, 59 * SC, 124 * SC, 0)
  panel.pos = btVector3(PX + 0.5, Y(43.5), 0)
  panel.col = "#101418"
  v:add(panel)
  local post1 = Cube(3, 36, 3, 0); post1.pos = btVector3(PX + 1.5, 10, -64); post1.col = "#202428"
  local post2 = Cube(3, 36, 3, 0); post2.pos = btVector3(PX + 1.5, 10, 64); post2.col = "#202428"
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
  digits(-57, 66, 5, 1.1, LABEL, LABEL_OFF, false).set("BREAK")
  board.breakPts = digits(-38, 65.5, 3, 2.2, LED, LED_OFF, true)
  digits(-7, 66, 4, 1.1, LABEL, LABEL_OFF, false).set("HIGH")
  board.high = digits(8, 65.5, 3, 2.2, LED, LED_OFF, true)
  digits(30, 66, 3, 1.1, LABEL, LABEL_OFF, false).set("PTS")
  board.points = digits(42, 65.5, 3, 2.2, LED, LED_OFF, true)
  board.message = digits(-54, 49, 12, 1.6, "#7cfc00", "#16240a", true)

  -- force: a bar of 20 lamps; spin: where the tip will strike the cue ball
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
  face.col = WHITE
  v:add(face)
  local dot = Cylinder(1.0 * SC, 0.3, 0)
  dot.col = "#c62828"
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

  -- the ball on: seven lamps, red and the six colours, lit for the balls
  -- you may play now
  digits(-57, 20, 2, 1.1, LABEL, LABEL_OFF, false).set("ON")
  board.onLamps = {}
  local lampCols = { [1] = RED_COL }
  for val = 2, 7 do lampCols[val] = COLOUR_COLS[val] end
  for val = 1, 7 do
    local c = Cylinder(2.2 * SC, 0.3, 0)
    c.trans = btTransform(btQuaternion(yAxis, math.pi / 2), btVector3(PX - 0.2, Y(20), (-40 + (val - 1) * 7) * SC))
    c.col = "#202020"
    v:add(c)
    board.onLamps[val] = { obj = c, col = lampCols[val], lit = false }
  end
  -- `on` is "red", "colour" (any) or a colour's value
  board.setOn = function(on)
    for val, l in ipairs(board.onLamps) do
      local lit = (on == "red" and val == 1) or (on == "colour" and val >= 2) or on == val
      if lit ~= l.lit then l.obj.col = lit and l.col or "#202020"; l.lit = lit end
    end
  end
end
-- ---------------------------------------------------------------------
-- the cue stick (for show: it has no collision; the shot itself is an
-- impulse on the cue ball where the tip meets it)
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
-- aiming guide: a dashed line to a ghost ball where the cue ball would
-- meet the first ball, and the paths the two balls take from there
-- ---------------------------------------------------------------------

local guide = { on = true, dashes = {}, used = 0 }
do
  for i = 1, 200 do
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

-- Where the cue ball, sent from (cx, cz) along (dx, dz), first meets a ball
-- (returns distance, ball) or a cushion (distance, nil).
local function castCueBall(cx, cz, dx, dz)
  local best, hit = math.huge, nil
  for n = 1, NB do
    local b = balls[n]
    if b.onTable then
      local bx, bz = ballXZ(b)
      local ox, oz = bx - cx, bz - cz
      local along = ox * dx + oz * dz
      if along > 0 then
        local perp2 = ox * ox + oz * oz - along * along
        local r2 = K.D * K.D
        if perp2 < r2 then
          local t = along - math.sqrt(r2 - perp2)
          if t < best then best, hit = t, b end
        end
      end
    end
  end
  -- the cushions, as the box the ball's centre can reach
  local limX, limZ = K.HL - K.R, K.HW - K.R
  local t
  if dx > 1e-9 then t = (limX - cx) / dx elseif dx < -1e-9 then t = (-limX - cx) / dx end
  if t and t < best then best, hit = t, nil end
  t = nil
  if dz > 1e-9 then t = (limZ - cz) / dz elseif dz < -1e-9 then t = (-limZ - cz) / dz end
  if t and t < best then best, hit = t, nil end
  return math.max(0, best), hit
end
-- ---------------------------------------------------------------------
-- game state
-- ---------------------------------------------------------------------

local S = {
  state = "inhand",     -- inhand, aim, stroke, rolling, cleared
  breakOff = true,      -- the next shot is the break-off
  on = "red",           -- the ball on: "red", "colour" (any) or a colour's value
  onAtShot = "red",     -- (the ball on when this shot was taken)
  breakPts = 0,         -- the break in progress
  lastBreak = 0,        -- the last break that ended
  highBreak = 0,        -- the highest break (kept between runs)
  framePts = 0,         -- points scored this frame
  visits = 0,           -- breaks (visits to the table) this frame
  fouls = 0,            -- fouls this frame...
  foulPts = 0,          -- ...and the points they'd give an opponent
  firstHit = nil,       -- the first object ball the cue ball touched
  shotPotted = {},      -- object balls potted this shot
  jumpedOff = {},       -- object balls that left the table this shot
  offTable = false,
  scratched = false,    -- the cue ball went in (an in-off)
  tray = {},            -- balls in the tray, in order
  aim = 0,              -- radians; 0 = toward the top cushion (+X)
  power = 0.30,         -- 0..1
  spinX = 0, spinY = 0, -- tip offset, -1..1 (right, up)
  elev = 0,             -- how far the player has raised the cue (radians);
                        -- it goes higher by itself if it must clear something
  message = "",
  view = "table",       -- table, cue, top
  stillFrames = 0,
  rollFrames = 0,
  strokeFrame = 0,
  dirty = true,         -- guide, cue, camera and help need redrawing
  frame = 0,
}
do
  local saved = v.loadPrefs and v:loadPrefs(PREFS_PREFIX .. "highBreak", "") or ""
  S.highBreak = tonumber(saved) or 0
end

local function now()
  if TF and TF.clock then return TF.clock() end
  return v.getTime and v:getTime() or S.frame * K.FRAME
end

-- Thinking a little at a time. Choosing a shot follows the cue ball for
-- each likely pot at nine strokes (three spins, three paces), and where it
-- comes to rest, what's on next -- reading every ball's position hundreds
-- of thousands of times. Done all at once that held everything up (the
-- picture, and in the rec room every other game) for up to a second and a
-- half. So the computer thinks in a coroutine: PLAN_BUDGET seconds a
-- frame, then the frame carries on and it picks up where it left off on
-- the next. The balls are still while it thinks, so their positions are
-- read once, into frozenXZ (reading one from Bullet makes a vector for the
-- garbage collector: millions a shot). If anything has moved by the time
-- it has decided, it thinks again. It tries its strokes by setting the
-- cue's aim, force and spin; between steps those go back to what's on the
-- screen.
PLAN_BUDGET = PLAN_BUDGET or 0.003
local planUntil = nil
local unpack = unpack or table.unpack
-- (os.clock: the processor time used, finer than bpp's millisecond
-- stopwatch; it counts every thread, so if anything it runs fast, and a
-- step comes out shorter, never longer)
local clockNow = os.clock
local PLAN_STATE = { { S, "aim" }, { S, "power" }, { S, "spinX" }, { S, "spinY" }, { cue, "elev" } }
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
    local x, _, z = posXYZ(b.obj)
    f[b] = { x, z }
  end
  return f
end
local function stillFrozen(f)
  for b, xz in pairs(f) do
    local x, _, z = posXYZ(b.obj)
    if math.abs(x - xz[1]) > 0.05 or math.abs(z - xz[2]) > 0.05 then return false end
  end
  return true
end
-- start thinking: fn runs in a coroutine of its own
local function planStart(fn)
  return { co = coroutine.create(fn), xz = freezeXZ() }
end
-- think for up to PLAN_BUDGET seconds; true and fn's result when it's done
local function planStep(p)
  for i, k in ipairs(PLAN_STATE) do planShown[i] = k[1][k[2]] end
  frozenXZ, planUntil = p.xz, clockNow() + PLAN_BUDGET
  local res = { coroutine.resume(p.co) }
  frozenXZ, planUntil = nil, nil
  -- (the screen gets back what it showed, however the step ended)
  for i, k in ipairs(PLAN_STATE) do k[1][k[2]] = planShown[i] end
  if not res[1] then error(res[2], 0) end
  if coroutine.status(p.co) ~= "dead" then return false end
  return true, unpack(res, 2)
end

local function aimDir()
  return math.cos(S.aim), math.sin(S.aim)
end

local function redsLeft()
  local n = 0
  for i = 1, 15 do if balls[i].onTable then n = n + 1 end end
  return n
end

local function ballsLeft()
  local n = 0
  for i = 1, NB do if balls[i].onTable then n = n + 1 end end
  return n
end

-- the lowest-value colour still on the table
local function lowestColour()
  for val = 2, 7 do
    if balls[COLOUR_BALL[val]].onTable then return val end
  end
  return nil
end

-- May ball b be played at now (is it "on")?
local function isOn(b, on)
  on = on or S.on
  if on == "red" then return b.red end
  if on == "colour" then return b.colour end
  return b.colour and b.value == on
end

-- Could a ball sit at (x, z) without touching another (other than `skip`)?
local function spotFree(x, z, skip)
  for n = 0, NB do
    local o = balls[n]
    if o.onTable and o ~= skip then
      local ox, oz = ballXZ(o)
      if (ox - x) ^ 2 + (oz - z) ^ 2 < (K.D + 0.05) ^ 2 then return false end
    end
  end
  return true
end

-- The D: behind the baulk line, within its radius of the brown spot.
local function inD(x, z)
  return x <= K.BAULK_X + 0.01 and (x - K.BAULK_X) ^ 2 + z * z <= K.D_R * K.D_R + 0.01
end

-- Can the cue ball sit at (x, z)? Ball in hand always goes in the D.
local function cueSpotFree(x, z)
  if not inD(x, z) then return false end
  for n = 1, NB do
    local b = balls[n]
    if b.onTable then
      local bx, bz = ballXZ(b)
      if (bx - x) ^ 2 + (bz - z) ^ 2 < (K.D + 0.05) ^ 2 then return false end
    end
  end
  return true
end

-- Ball in hand: the cue ball goes into the D, a little to the yellow side
-- of the brown, or the nearest free spot.
local function cueToHand()
  local cb = balls[0]
  cb.onTable = true
  local x0, z0 = K.BAULK_X - 2, 10
  for r = 0, 40, 1 do
    for k = 0, math.max(0, 8 * r - 1) do
      local a = (r == 0) and 0 or (2 * math.pi * k / (8 * r))
      local x, z = x0 + r * math.cos(a), z0 + r * math.sin(a)
      if cueSpotFree(x, z) then
        placeBall(cb, x, z)
        return
      end
    end
  end
  placeBall(cb, x0, z0)
end

-- Put a colour back on the table: on its own spot; if that's taken, the
-- highest-value spot free; if none is, as near its own spot as it fits on
-- the line toward the top cushion (or failing that, toward the baulk end).
local function respotColour(b)
  b.onTable = false                       -- (so it doesn't block itself)
  local x, z
  local own = SPOTS[b.value]
  if spotFree(own[1], own[2], b) then
    x, z = own[1], own[2]
  else
    for val = 7, 2, -1 do
      local s = SPOTS[val]
      if spotFree(s[1], s[2], b) then x, z = s[1], s[2]; break end
    end
  end
  if not x then
    local px = own[1]
    while px < K.HL - K.R and not spotFree(px, own[2], b) do px = px + 0.25 end
    if px >= K.HL - K.R then
      px = own[1]
      while px > -K.HL + K.R and not spotFree(px, own[2], b) do px = px - 0.25 end
    end
    x, z = px, own[2]
  end
  b.onTable = true
  placeBall(b, x, z, K.R, randomRot())
end

-- the balls in the tray, lined up in the order they went in
local function arrangeTray()
  for i, n in ipairs(S.tray) do
    placeBall(balls[n], (i - 11) * (K.D + 0.3), K.TRAY_Z, K.TRAY_Y)
  end
end
local function removeFromTray(n)
  for i, m in ipairs(S.tray) do
    if m == n then table.remove(S.tray, i); break end
  end
end

local function rack()
  -- the reds in a triangle behind the pink: its apex as near the pink as
  -- it can be without touching; the colours on their spots
  local gap = 0.02            -- a hair between the balls
  local dx = (K.D + gap) * math.cos(math.rad(30))
  local apex = K.HL / 2 + K.D + 0.15
  local n = 0
  for row = 0, 4 do
    for k = 0, row do
      n = n + 1
      local b = balls[n]
      b.onTable = true
      placeBall(b, apex + row * dx, (k - row / 2) * (K.D + gap), K.R, randomRot())
    end
  end
  for val = 2, 7 do
    local b = balls[COLOUR_BALL[val]]
    b.onTable = true
    placeBall(b, SPOTS[val][1], SPOTS[val][2], K.R, randomRot())
  end
  S.tray = {}
  S.breakOff = true
  S.on, S.onAtShot = "red", "red"
  S.breakPts, S.lastBreak, S.framePts, S.visits, S.fouls, S.foulPts = 0, 0, 0, 0, 0, 0
  S.scratched, S.offTable = false, false
  S.state = "inhand"
  S.aim = 0
  S.spinX, S.spinY = 0, 0
  S.elev = 0
  S.power = 0.30
  S.message = "IN HAND"
  balls[0].onTable = true
  placeBall(balls[0], K.BAULK_X - 2, 12, K.R, randomRot())
  S.dirty = true
  playSound("rack")
end

-- A ball has dropped. Everything waits in the tray: reds for good, colours
-- until they're respotted, the cue ball until it's back in hand.
local function potBall(b)
  b.onTable = false
  if b.n == 0 then
    S.scratched = true
    placeBall(b, 11.5 * (K.D + 0.3), K.TRAY_Z, K.TRAY_Y)
    playSound("scratch")
  else
    S.shotPotted[#S.shotPotted + 1] = b.n
    S.tray[#S.tray + 1] = b.n
    arrangeTray()
    playSound("pocket")
  end
end

-- A ball has left the table (jumped over the rail, or come to rest on it).
local function offTable(b)
  b.onTable = false
  b.railFrames = 0
  S.offTable = true
  if b.n == 0 then
    S.scratched = true
    placeBall(b, 11.5 * (K.D + 0.3), K.TRAY_Z, K.TRAY_Y)
  else
    S.jumpedOff[#S.jumpedOff + 1] = b.n
    S.tray[#S.tray + 1] = b.n
    arrangeTray()
  end
  playSound("scratch")
end
-- ---------------------------------------------------------------------
-- the view
-- ---------------------------------------------------------------------

local function setView()
  if S.view == "top" then
    common.setCamera(btVector3(0, 480, 0.01), btVector3(0, 0, 0), 0.8, { up = btVector3(0, 0, -1) })
  elseif S.view == "cue" then
    local cx, cz = ballXZ(balls[0])
    local dx, dz = aimDir()
    common.setCamera(btVector3(cx - dx * 95, 38, cz - dz * 95),
                     btVector3(cx + dx * 70, 0, cz + dz * 70), 0.8, { up = yAxis })
  else
    common.setCamera(btVector3(-330, 240, 0), btVector3(30, -20, 0), 0.8, { up = yAxis })
  end
end
-- Place the cue behind the cue ball, drawn back `gap` cm from it. The cue
-- is kept as low as it can go (4 degrees) but raised as far as it must be
-- to clear the rail and any ball behind the cue ball -- it never passes
-- through either. Raised, it still points at the same spot on the cue
-- ball, so the tip meets the ball higher up its back.
local CUE_LEN = 147
local function cueRadius(s) return 0.64 + 0.81 * math.max(0, s) / CUE_LEN end

-- The tip and the unit vector back along the cue, for elevation e.
local function cueGeometry(e, gap)
  local cx, cz = ballXZ(balls[0])
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

-- Does the cue at elevation e clear the rail and every ball?
local function cueClears(e, gap)
  local px, py, pz, bx, by, bz = cueGeometry(e, gap)
  -- the rail: where the cue (or the path of its stroke) passes over the
  -- cushion nose it must be above the rail's top (it only climbs from there)
  local hx, hz = bx, bz
  local sExit = math.huge
  local ox0, oz0 = px - bx * gap, pz - bz * gap       -- where the stroke meets the ball
  if hx > 1e-6 then sExit = math.min(sExit, (K.HL - ox0) / hx) elseif hx < -1e-6 then sExit = math.min(sExit, (-K.HL - ox0) / hx) end
  if hz > 1e-6 then sExit = math.min(sExit, (K.HW - oz0) / hz) elseif hz < -1e-6 then sExit = math.min(sExit, (-K.HW - oz0) / hz) end
  sExit = sExit - gap                                 -- (measured from the tip)
  sExit = math.max(-gap, sExit)       -- (drawn right back, the tip itself may be over the rail)
  if sExit < CUE_LEN and py + by * sExit - cueRadius(sExit) < K.RAIL_H + 0.3 then return false end
  -- the balls
  for n = 1, NB do
    local b = balls[n]
    if b.onTable then
      local p = b.obj.pos
      local vx, vy, vz = p.x - px, p.y - py, p.z - pz
      -- (from where the tip meets the cue ball, so the stroke clears too)
      local sB = math.max(-gap, math.min(CUE_LEN, vx * bx + vy * by + vz * bz))
      local qx, qy, qz = vx - bx * sB, vy - by * sB, vz - bz * sB
      if qx * qx + qy * qy + qz * qz < (K.R + cueRadius(sB) + 0.15) ^ 2 then return false end
    end
  end
  return true
end

local MIN_ELEV, MAX_ELEV = math.rad(4), math.rad(80)
local function placeCue(gap)
  local e = math.max(MIN_ELEV, S.elev)
  while e < MAX_ELEV and not cueClears(e, gap) do e = e + math.rad(1) end
  cue.elev = e
  local px, py, pz, bx, by, bz = cueGeometry(e, gap)
  cue.place(px, py, pz, bx, by, bz)
end

-- Hitting left or right of centre pushes the cue ball a little the other
-- way off the line of the cue (squirt), as a real cue does.
local SQUIRT = math.rad(1.5)     -- at the furthest a tip may be off centre

-- The stroke for the current aim, cue angle, force and spin: the unit
-- direction it drives the cue ball (squirt included), the point on the
-- ball the tip meets (relative to its centre) and the speed.
local function strokeNow()
  local e = cue.elev or MIN_ELEV
  local cx, cz = ballXZ(balls[0])
  local tx, ty, tz, bx, by, bz = cueGeometry(e, 0)        -- tip on the ball
  local fx, fy, fz = -bx, -by, -bz
  local sq = -SQUIRT * S.spinX
  local c, s = math.cos(sq), math.sin(sq)
  fx, fz = fx * c - fz * s, fx * s + fz * c
  return fx, fy, fz, tx - cx, ty - K.R, tz - cz, K.VMAX * math.max(0.01, S.power)
end

-- Where the cue ball will really go: from the velocity and spin the
-- stroke gives it, step its motion on the cloth (sliding with friction
-- until it rolls, then rolling resistance -- the same as the simulation)
-- until it meets a ball, reaches a cushion or stops. So side spin's squirt
-- and swerve, and a masse's curve, show in the guide.
-- Returns the path (a list of {x, z}), where it ends, and the ball it hits.
local MU_G = 0.2 * K.G          -- the cloth's sliding friction (ball 0.2 x cloth 1.0)
local function predictCueBall()
  local fx, fy, fz, rx, ry, rz, speed = strokeNow()
  local px, pz = ballXZ(balls[0])
  local vx, vz = fx * speed, fz * speed
  -- spin from the blow: w = (r x J) / I, per unit mass, I = 2/5 R^2
  local Jx, Jy, Jz = fx * speed, fy * speed, fz * speed
  local k = 5 / (2 * K.R * K.R)
  local wx = (ry * Jz - rz * Jy) * k
  local wy = (rz * Jx - rx * Jz) * k
  local wz = (rx * Jy - ry * Jx) * k
  local path = { { px, pz } }
  local lastX, lastZ = px, pz
  local dt = 1 / 240
  local limX, limZ = K.HL - K.R, K.HW - K.R
  for step = 1, 240 * 8 do
    if step % 40 == 0 then planPace() end
    -- the cloth: slip at the contact point, and friction against it
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
    -- rolling resistance (as the script applies it)
    local sp = math.sqrt(vx * vx + vz * vz)
    if sp < K.STOP_V then break end
    local f = math.max(0, sp - K.ROLL_DECEL * dt) / sp
    vx, vz, wx, wz = vx * f, vz * f, wx * f, wz * f
    local dwy = K.SPIN_DECEL * dt
    wy = math.abs(wy) <= dwy and 0 or wy - dwy * (wy > 0 and 1 or -1)
    local nx, nz = px + vx * dt, pz + vz * dt
    -- a ball in the way during this step?
    local mx, mz = nx - px, nz - pz
    local ml2 = mx * mx + mz * mz
    local bestT, hit = nil, nil
    for n = 1, NB do
      local b = balls[n]
      if b.onTable then
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
      -- along the way the cue ball's surface is sliding across it (side
      -- spin, or a cut), so it leaves slightly off the line of centres.
      local bx, bz = ballXZ(hit)
      local nx, nz = (bx - px) / K.D, (bz - pz) / K.D
      local vn = vx * nx + vz * nz
      local ux, uz = nx, nz
      if vn > 1 then
        -- the cue ball's surface velocity where it touches (w x R n)
        local sx = vx + K.R * wy * nz
        local sz = vz - K.R * wy * nx
        local sy = K.R * (wz * nx - wx * nz)
        local tn = sx * nx + sz * nz
        local thx, thz = sx - tn * nx, sz - tn * nz        -- sideways slip
        local st = math.sqrt(thx * thx + thz * thz + sy * sy)
        if st > 1e-6 then
          local vt = math.min(0.04 * vn, st / 7)            -- ball-on-ball friction 0.04
          ux, uz = nx + thx / st * vt / vn, nz + thz / st * vt / vn
          local ul = math.sqrt(ux * ux + uz * uz)
          ux, uz = ux / ul, uz / ul
        end
      end
      return path, px, pz, hit, ux, uz, vx, vz, wx, wy, wz
    end
    -- a cushion?
    if math.abs(nx) >= limX or math.abs(nz) >= limZ then
      local t = 1
      if math.abs(nx) >= limX and mx ~= 0 then t = math.min(t, ((nx > 0 and limX or -limX) - px) / mx) end
      if math.abs(nz) >= limZ and mz ~= 0 then t = math.min(t, ((nz > 0 and limZ or -limZ) - pz) / mz) end
      px, pz = px + mx * t, pz + mz * t
      path[#path + 1] = { px, pz }
      return path, px, pz, nil
    end
    px, pz = nx, nz
    if (px - lastX) ^ 2 + (pz - lastZ) ^ 2 > 3.2 * 3.2 then
      path[#path + 1] = { px, pz }
      lastX, lastZ = px, pz
    end
  end
  path[#path + 1] = { px, pz }
  return path, px, pz, nil
end

-- A dashed line along a path of points.
function guide.path(path, col)
  for i = 1, #path - 1 do
    guide.line(path[i][1], path[i][2], path[i + 1][1], path[i + 1][2], col)
  end
end
local function drawGuide()
  guide.clear()
  local st = S.state
  if st ~= "aim" and st ~= "inhand" then return end
  if not guide.on then return end
  local cx, cz = ballXZ(balls[0])
  -- the cue ball's real path (it curves with side spin or a raised cue)
  local path, gx, gz, hit, throwX, throwZ = predictCueBall()
  local dx, dz = gx - cx, gz - cz                     -- (its overall heading)
  local dl = math.sqrt(dx * dx + dz * dz)
  if dl > 1e-6 then dx, dz = dx / dl, dz / dl else dx, dz = aimDir() end
  if #path >= 2 then
    local p1, p2 = path[#path - 1], path[#path]      -- its heading as it arrives
    local ex, ez = p2[1] - p1[1], p2[2] - p1[2]
    local el = math.sqrt(ex * ex + ez * ez)
    if el > 1e-6 then dx, dz = ex / el, ez / el end
  end
  -- red: the first ball it would hit isn't on (a foul)
  local wrong = hit and not isOn(hit)
  guide.path(path, wrong and "#ff5a4f" or "#ffffff")
  guide.ghost.pos = btVector3(gx, K.R, gz)
  local gcol = wrong and "#ff3b30" or "#ffffff"
  if guide.ghost.col ~= gcol then guide.ghost.col = gcol end
  if hit then
    local bx, bz = ballXZ(hit)
    local ux, uz = throwX or (bx - gx) / K.D, throwZ or (bz - gz) / K.D
    guide.line(bx, bz, bx + ux * 30, bz + uz * 30, wrong and "#ff9a8f" or "#ffe066")
    -- the cue ball glances off at right angles (for a hit without spin)
    local dot = dx * ux + dz * uz
    local tx, tz = dx - dot * ux, dz - dot * uz
    local tl = math.sqrt(tx * tx + tz * tz)
    if tl > 0.05 then
      guide.line(gx, gz, gx + tx / tl * 18, gz + tz / tl * 18, "#8ecae6")
    end
  end
end

-- auto-play (P): the computer plays; filled in further down
local auto = { on = false }

-- the ball on, in words
local function onText(on)
  on = on or S.on
  if on == "red" then return "a red" end
  if on == "colour" then return "any colour (the one you hit first is the one you've chosen)" end
  return string.format("the %s (%d)", COLOUR_NAMES[on], on)
end

-- ---------------------------------------------------------------------
-- the shortcuts pane
-- ---------------------------------------------------------------------

local function helpText()
  local lines = {}
  local function add(s) lines[#lines + 1] = s end
  add("SNOOKER -- break building" .. (auto.on and "      COMPUTER PLAYING (P to take over)" or ""))
  add("")
  local s0 = #lines + 1          -- (from here: what's going on, for the console)
  local st = S.state
  if st == "inhand" then
    add(S.breakOff and "Ball in hand in the D: place the cue ball and break off."
                    or "Ball in hand in the D: place the cue ball.")
  elseif st == "aim" then add("Ball on: " .. onText() .. ".")
  elseif st == "stroke" or st == "rolling" then add("Balls rolling...")
  elseif st == "cleared" then
    add(string.format("Frame cleared: %d points in %d break%s. Press N for a new frame.",
                      S.framePts, S.visits, S.visits == 1 and "" or "s"))
  end
  add(string.format("Break %d   Last break %d   Highest break %d   Points this frame %d   Reds left %d",
                    S.breakPts, S.lastBreak, S.highBreak, S.framePts, redsLeft()))
  add(string.format("Fouls %d (%d points to an opponent)", S.fouls, S.foulPts))
  local s1 = #lines
  add(string.format("Aim %.2f deg   Force %d%%   Spin: %s", (math.deg(S.aim) + 360) % 360,
                    math.floor(S.power * 100 + 0.5),
                    (S.spinX == 0 and S.spinY == 0) and "centre ball"
                    or string.format("%s %.0f%%, %s %.0f%%",
                                     S.spinY >= 0 and "follow" or "draw", math.abs(S.spinY) * 100,
                                     S.spinX >= 0 and "right" or "left", math.abs(S.spinX) * 100)))
  local ce = math.deg(cue.elev or MIN_ELEV)
  local notes = {}
  if ce > math.deg(math.max(MIN_ELEV, S.elev)) + 0.5 then notes[#notes + 1] = "raised to clear a ball or the rail" end
  if K.VMAX * S.power * math.sin(math.rad(ce)) > K.JUMP_MIN + 60 then
    notes[#notes + 1] = "hit this firmly it will jump"
  end
  if ce >= 30 and S.spinX ~= 0 then notes[#notes + 1] = "off centre, it will curve (masse)" end
  add(string.format("Cue raised %.0f deg%s", ce, #notes > 0 and " -- " .. table.concat(notes, "; ") or ""))
  local a1 = #lines               -- (to here: the shot's settings; then the keys)
  add("")
  if st == "inhand" then
    add("Arrows      move the cue ball around the D (Up = away from you)")
    add("Space/Enter put it down")
  else
    add("Left/Right  aim (tap for a quarter degree, hold to swing)")
    add(",  .        fine aim")
    add("Up/Down     force")
    add("W/S         hit higher (follow) / lower (draw)")
    add("A/D         hit left / right (side spin)")
    add("C           centre hit")
    add("E/Q         raise / lower the cue (masse)")
    add("Space/Enter shoot")
  end
  add("G           aiming guide " .. (guide.on and "(on; a red ghost ball: that ball isn't on)" or "(off)"))
  add("V           back to the starting view" .. (S.view == "table" and " (now)" or ""))
  add("B           camera behind the cue" .. (S.view == "cue" and " (now)" or ""))
  add("T           camera overhead" .. (S.view == "top" and " (now)" or ""))
  add("N or R      new frame")
  add("P           the computer plays " .. (auto.on and "(on)" or "(off)"))
  add("")
  add("Red 1, yellow 2, green 3, brown 4, blue 5, pink 6, black 7. Red, colour, red...; then the")
  add("colours in order. A miss or a foul ends the break. Fouls: in-off, no ball hit, the wrong")
  add("ball first or potted, a ball off the table. Colours potted on a foul are respotted.")
  -- the keys (with the title) for the Shortcuts pane; what's going on, and
  -- the shot as it's set up, for the console
  local keys = { lines[1] }
  for n = a1 + 1, #lines do keys[#keys + 1] = lines[n] end
  return table.concat(keys, "\n"), table.concat(lines, "\n", s0, s1), table.concat(lines, "   ", s1 + 1, a1)
end

-- What's going on goes to the console, not the Shortcuts pane (written there
-- whenever it changed, it kept the pane from being scrolled to the keys): a
-- line when it changes, and the settings of each shot as it's played. In the
-- rec room, v:setStatusText passes it on from the game you're at only.
local function say(text, once)
  if v.setStatusText then v:setStatusText(text, once) else print(text) end
end
local lastStatus = nil
local function showStatus(text)
  if S.state == "stroke" or S.state == "rolling" or text == lastStatus then return end
  lastStatus = text
  say("SNOOKER: " .. text:gsub("\n", "\n         "))
end

-- ---------------------------------------------------------------------
-- shooting
-- ---------------------------------------------------------------------

-- The shot: an impulse on the cue ball at the point the tip meets it,
-- along the cue (see the Pool Table for how spin, masse and jumps come
-- from it).
local function strike()
  local cb = balls[0]
  local fx, fy, fz, rx, ry, rz, speed = strokeNow()
  local J = K.MASS * speed
  local body = cb.obj.body
  body:applyImpulse(btVector3(fx * J, 0, fz * J), btVector3(rx, ry, rz))
  local vy = fy * J                                   -- (r x (0, vy, 0))
  body:applyTorqueImpulse(btVector3(-rz * vy, 0, rx * vy))
  local down = -fy * speed
  if down > K.JUMP_MIN then
    local v = body:getLinearVelocity()
    local up = K.JUMP_E * (down - K.JUMP_MIN)
    local h = math.sqrt(v.x * v.x + v.z * v.z)
    local keep = h > 0 and math.max(0.5, 1 - 0.2 * (down + up) / h) or 1
    body:setLinearVelocity(btVector3(v.x * keep, up, v.z * keep))
  end
  cb.vx, cb.vz = fx * speed, fz * speed     -- (not a collision)
  playSound("cue", math.min(1, 0.25 + S.power))
end

local function shoot()
  if S.state ~= "aim" then return false end
  S.state = "stroke"
  say("SNOOKER: shot -- " .. select(3, helpText()), true)
  S.strokeFrame = 0
  S.scratched = false
  S.offTable = false
  S.message = ""
  S.breakOff = false
  S.onAtShot = S.on
  S.firstHit = nil
  S.shotPotted = {}
  S.jumpedOff = {}
  guide.clear()
  S.dirty = true
  return true
end

-- The break is over (a miss or a foul): remember it if it's the highest.
local function endBreak()
  S.visits = S.visits + 1
  S.lastBreak = S.breakPts
  if S.breakPts > S.highBreak then
    S.highBreak = S.breakPts
    if v.savePrefs then pcall(function() v:savePrefs(PREFS_PREFIX .. "highBreak", tostring(S.highBreak)) end) end
  end
  S.breakPts = 0
end

-- The ball on for a new break: a red, or once they're gone the lowest colour.
local function newBreakOn()
  if redsLeft() > 0 then return "red" end
  return lowestColour()
end

-- When every ball has stopped: was it a foul, what did it score, what's on?
local function shotOver()
  S.spinX, S.spinY, S.elev = 0, 0, 0
  local on = S.onAtShot
  local first = S.firstHit and balls[S.firstHit]
  local potted = {}
  for _, n in ipairs(S.shotPotted) do potted[#potted + 1] = balls[n] end
  -- what the shot would cost: the value of the ball on, or of the ball
  -- wrongly hit or potted, whichever is higher -- at least 4
  local onValue = (on == "red") and 1 or (on == "colour" and 7 or on)
  local penalty = math.max(4, on == "colour" and 4 or onValue)
  local foul, why = false, nil
  local function fault(reason, value)
    if not foul then foul, why = true, reason end
    penalty = math.max(penalty, value or 4)
  end
  if S.scratched then fault("IN OFF") end
  if S.offTable and not S.scratched then fault("OFF TABLE", 4) end
  if not first then
    fault("NO HIT")
  elseif not isOn(first, on) then
    fault("FOUL", first.value)
  end
  -- the colour chosen after a red is the colour hit first
  local chosen = (on == "colour" and first and first.colour) and first.value or nil
  local points = 0
  for _, b in ipairs(potted) do
    local legal
    if on == "red" then legal = b.red
    elseif on == "colour" then legal = b.colour and b.value == chosen and #potted == 1
    else legal = b.colour and b.value == on and #potted == 1 end
    if legal then points = points + b.value else fault("FOUL", b.value) end
  end
  for _, n in ipairs(S.jumpedOff) do fault("OFF TABLE", balls[n].value) end

  -- colours potted, or knocked off the table, go back on their spots --
  -- except in the colours-in-order stage, where a legally potted one stays down
  local respot = {}
  for _, n in ipairs(S.shotPotted) do
    local b = balls[n]
    if b.colour then
      local staysDown = (not foul) and type(on) == "number" and b.value == on
      if not staysDown then respot[#respot + 1] = b end
    end
  end
  for _, n in ipairs(S.jumpedOff) do
    if balls[n].colour then respot[#respot + 1] = balls[n] end
  end
  table.sort(respot, function(a, b) return a.value > b.value end)   -- highest first
  for _, b in ipairs(respot) do
    removeFromTray(b.n)
    respotColour(b)
  end
  arrangeTray()

  if foul then
    S.fouls = S.fouls + 1
    S.foulPts = S.foulPts + penalty
    S.message = why .. " " .. penalty
    endBreak()
    S.on = newBreakOn()
  elseif points > 0 then
    S.breakPts = S.breakPts + points
    S.framePts = S.framePts + points
    S.message = "BREAK " .. S.breakPts
    if on == "red" then
      S.on = "colour"
    elseif on == "colour" then
      S.on = (redsLeft() > 0) and "red" or 2
    else
      S.on = lowestColour()                 -- nil once the black is down
    end
  else
    S.message = (S.breakPts > 0) and ("BREAK " .. S.breakPts .. " END") or "NO POT"
    if #S.message > 12 then S.message = "BREAK " .. S.breakPts end
    endBreak()
    -- (a miss on the colour after the last red: the colours start from yellow)
    S.on = newBreakOn()
  end

  if ballsLeft() == 0 or not S.on then
    endBreak()
    S.state = "cleared"
    S.message = "CLEARED " .. S.framePts
    playSound("cleared")
  elseif S.scratched then
    S.state = "inhand"
    cueToHand()
  else
    S.state = "aim"
  end
  S.dirty = true
end
-- ---------------------------------------------------------------------
-- keyboard: taps step, holds slide (faster the longer they're held)
-- ---------------------------------------------------------------------

local HOLD_DELAY = 0.25     -- a key held this long starts sliding
local REPEAT_GAP = 0.04     -- a release and press this close are one hold
-- key -> { tap, slide rate, max rate } (units per tap / per second)
local SLIDES = {
  aim = { math.rad(0.25), math.rad(8), math.rad(45) },
  fine = { math.rad(0.02), math.rad(0.4), math.rad(2) },
  power = { 0.01, 0.25, 0.6 },
  spin = { 0.05, 0.6, 1.2 },
  elev = { math.rad(1), math.rad(10), math.rad(30) },
  move = { 0.5, 12, 60 },
}
local held = {}             -- key -> { since = time, last = time }
local released = {}         -- key -> { at = time, since = press time }

local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end

-- Move the cue ball in hand by (ax, az) in the view's frame (a = away, r = right).
local function moveInHand(away, right)
  local fx, fz, rx, rz = 1, 0, 0, 1
  if S.view == "cue" then
    fx, fz = aimDir()
    rx, rz = -fz, fx
  end
  local mx, mz = fx * away + rx * right, fz * away + rz * right
  local cx, cz = ballXZ(balls[0])
  local tries = { { mx, mz }, { mx, 0 }, { 0, mz } }
  for _, t in ipairs(tries) do
    if (t[1] ~= 0 or t[2] ~= 0) and cueSpotFree(cx + t[1], cz + t[2]) then
      placeBall(balls[0], cx + t[1], cz + t[2])
      S.dirty = true
      return true
    end
  end
  return false
end

-- What a key does (amount is in the key's units), or nil if nothing.
local function keyAction(key)
  local st = S.state
  if st == "inhand" then
    if key == "Up" then return "move", function(a) moveInHand(a, 0) end end
    if key == "Down" then return "move", function(a) moveInHand(-a, 0) end end
    if key == "Left" then return "move", function(a) moveInHand(0, -a) end end
    if key == "Right" then return "move", function(a) moveInHand(0, a) end end
  elseif st ~= "aim" then
    return nil
  end
  local function adj(field, sign, lo, hi, slide)
    return slide, function(a)
      S[field] = lo and clamp(S[field] + sign * a, lo, hi) or (S[field] + sign * a)
      if field == "spinX" or field == "spinY" then
        -- keep the tip on the ball
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

-- every key the table uses (so bpp's own shortcuts don't fire on them)
local OUR_KEYS = {}
for _, k in ipairs({ "Left", "Right", "Up", "Down", ",", ".", "<", ">", "W", "S", "A", "D",
                     "C", "E", "Q", "G", "V", "B", "T", "N", "R", "P", "Space", "Return", "Enter" }) do
  OUR_KEYS[k] = true
end

-- keys that play the shot (ignored while the computer is playing)
local PLAY_KEYS = { Left = 1, Right = 1, Up = 1, Down = 1, [","] = 1, ["."] = 1, ["<"] = 1, [">"] = 1,
                    W = 1, S = 1, A = 1, D = 1, C = 1, E = 1, Q = 1, Space = 1, Return = 1, Enter = 1 }

local function onKey(N, key, down)
  local t = now()
  if key == "P" then
    if down then auto.toggle() end
    return true
  end
  if auto.on and PLAY_KEYS[key] then return true end
  local slide, act = keyAction(key)
  if slide then
    if down then
      local r = released[key]
      if r and t - r.at < REPEAT_GAP then
        held[key] = { since = r.since, last = t }       -- the same hold, continued
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
    if S.state == "inhand" then
      S.state = "aim"
      S.message = ""
      S.dirty = true
    elseif S.state == "aim" then
      shoot()
    end
    return true
  end
  if key == "C" then
    S.spinX, S.spinY = 0, 0
    S.dirty = true
    return true
  end
  if key == "G" then
    guide.on = not guide.on
    S.dirty = true
    return true
  end
  -- cameras: V back to the starting view (also undoing any turning or
  -- zooming done with the mouse), B behind the cue, T overhead
  local VIEW_KEYS = { V = "table", B = "cue", T = "top" }
  if VIEW_KEYS[key] then
    S.view = VIEW_KEYS[key]
    setView()
    S.dirty = true
    return true
  end
  if key == "N" or key == "R" then
    rack()
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
  -- scoreboard
  local want = {
    breakPts = tostring(S.breakPts),
    high = tostring(S.highBreak),
    points = tostring(S.framePts),
    message = (S.message ~= "" and S.message) or (auto.on and "AUTO" or ""),
  }
  for k, text in pairs(want) do
    if shown[k] ~= text then
      shown[k] = text
      board[k].set(text, k ~= "message")
    end
  end
  board.setForce(S.power)
  board.spinDot(S.spinX, S.spinY)
  board.setOn(S.state ~= "cleared" and S.on or nil)
  -- cue, guide and camera
  if S.state == "aim" or S.state == "inhand" then
    if S.state == "aim" then placeCue(1.0 + 16 * S.power) else cue.hide() end
    drawGuide()
    if S.view == "cue" then setView() end
  end
  local text, status = helpText()
  if text ~= lastHelp then
    lastHelp = text
    if v.setHelpText then v:setHelpText(text) end
  end
  showStatus(status)
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
-- the computer player. For every ball on and every pocket it works out
-- the pot (ghost ball, cut, a clear path for both balls) and how likely it
-- is to go in; then for the likelier ones it tries draw, stun and follow at
-- three speeds, follows the cue ball after the hit (with the same cloth
-- physics as the aiming guide, off the cushions, watching for pockets)
-- and scores where it would end up by the best pot available there on the
-- next ball on. It plays the shot with the best expected value: points
-- now plus position for the next one. With nothing on it plays safe: a
-- soft contact on a ball on (off a cushion if it must). It breaks off
-- thin off the end red, as the professionals do.
-- ---------------------------------------------------------------------

auto.phase = "idle"
local AUTO_TURN = math.rad(120)   -- how fast it swings the cue (per second)
local AUTO_PAUSE = 0.6            -- a moment to settle before shooting

-- Is the segment (x1,z1)-(x2,z2) clear of balls (other than `skip1`,
-- `skip2`) by `width` (distance from its line to a ball's centre)?
local function laneClear(x1, z1, x2, z2, width, skip1, skip2)
  local dx, dz = x2 - x1, z2 - z1
  local L2 = dx * dx + dz * dz
  for n = 0, NB do
    local b = balls[n]
    if b.onTable and b ~= skip1 and b ~= skip2 then
      local bx, bz = ballXZ(b)
      local t = L2 > 0 and math.max(0, math.min(1, ((bx - x1) * dx + (bz - z1) * dz) / L2)) or 0
      local qx, qz = x1 + dx * t - bx, z1 + dz * t - bz
      if qx * qx + qz * qz < width * width then return false end
    end
  end
  return true
end

-- The value of potting b when `on` is the ball on (a red is worth its
-- point plus the colour it leads to).
local function potValue(b)
  if b.red then return 3 end
  return b.value
end

-- Every pot available from (cx, cz) for balls on under `on`: a list of
-- { b, aim, al, ul, cutcos, prob, basePower, ux, uz }.
local function pots(cx, cz, on, exclude)
  local list = {}
  local cb = balls[0]
  for n = 1, NB do
    planPace()
    local b = balls[n]
    if b.onTable and b ~= exclude and isOn(b, on) then
      local bx, bz = ballXZ(b)
      for _, pk in ipairs(pockets) do
        local tx, tz = pk.mx + pk.nx * 1.2, pk.mz + pk.nz * 1.2
        local ux, uz = tx - bx, tz - bz
        local ul = math.sqrt(ux * ux + uz * uz)
        ux, uz = ux / ul, uz / ul
        local facing = ux * pk.nx + uz * pk.nz
        if facing > (pk.corner and 0.5 or 0.82) then
          local gx, gz = bx - ux * K.D, bz - uz * K.D
          if math.abs(gx) < K.HL - K.R and math.abs(gz) < K.HW - K.R then
            local ax, az = gx - cx, gz - cz
            local al = math.sqrt(ax * ax + az * az)
            if al > 1 then
              local cutcos = (ax * ux + az * uz) / al
              if cutcos > math.cos(math.rad(70))
                 and laneClear(cx, cz, gx, gz, K.D - 0.05, cb, b)
                 and laneClear(bx, bz, tx, tz, K.D - 0.05, cb, b) then
                local _, hit = castCueBall(cx, cz, ax / al, az / al)
                if hit == b then
                  local score = cutcos * cutcos * (pk.corner and facing or facing * 0.8)
                                / ((al + 20) * (ul + 20)) * 1e4 * 0.8
                  local vo = math.sqrt(60 * 60 + 2 * K.ROLL_DECEL * 1.6 * ul)
                  local vc = vo / (0.95 * math.max(cutcos, 0.3))
                  local v0 = math.sqrt(vc * vc + 2 * 40 * al)
                  list[#list + 1] = { b = b, aim = math.atan2(az, ax), al = al, ul = ul,
                                      cutcos = cutcos, prob = 1 - math.exp(-score),
                                      basePower = 1.1 * v0 / K.VMAX, ux = ux, uz = uz }
                end
              end
            end
          end
        end
      end
    end
  end
  return list
end

-- The best expected value of the next pot from (x, z).
local function nextValue(x, z, on, exclude)
  if not on then return 0 end
  local best = 0
  for _, p in ipairs(pots(x, z, on, exclude)) do
    local ev = p.prob * potValue(p.b)
    if ev > best then best = ev end
  end
  return best
end

-- Where the cue ball goes after the hit: from its velocity and spin at the
-- contact, minus the part along the line of centres the object ball takes,
-- stepped on the cloth until it stops -- off cushions, into pockets.
-- Returns x, z and "pocket", "ball" (it runs into another ball: the
-- position is uncertain) or nil.
local function rollOut(px, pz, vx, vz, wx, wy, wz, nx, nz, skip)
  local vn = vx * nx + vz * nz
  vx, vz = vx - 0.97 * vn * nx, vz - 0.97 * vn * nz
  local dt = 1 / 120
  local limX, limZ = K.HL - K.R, K.HW - K.R
  for step = 1, 120 * 10 do
    if step % 40 == 0 then planPace() end
    local sx, sz = vx + K.R * wz, vz - K.R * wx
    local slip = math.sqrt(sx * sx + sz * sz)
    if slip > 3.5 * MU_G * dt then
      local ax, az = -MU_G * sx / slip, -MU_G * sz / slip
      vx, vz = vx + ax * dt, vz + az * dt
      wx, wz = wx - 2.5 / K.R * az * dt, wz + 2.5 / K.R * ax * dt
    else
      wx, wz = vz / K.R, -vx / K.R
    end
    local sp = math.sqrt(vx * vx + vz * vz)
    if sp < 1 then return px, pz end
    local f = math.max(0, sp - K.ROLL_DECEL * dt) / sp
    vx, vz, wx, wz = vx * f, vz * f, wx * f, wz * f
    px, pz = px + vx * dt, pz + vz * dt
    -- a pocket?
    for _, pk in ipairs(pockets) do
      local rx, rz = px - pk.mx, pz - pk.mz
      if rx * pk.nx + rz * pk.nz > -1 and math.abs(rx * pk.nz - rz * pk.nx) < pk.half then
        return px, pz, "pocket"
      end
    end
    -- a cushion: bounce (0.85, leaving with a natural-ish roll)
    local bounced = false
    if math.abs(px) > limX then px = (px > 0) and limX or -limX; vx = -0.85 * vx; bounced = true end
    if math.abs(pz) > limZ then pz = (pz > 0) and limZ or -limZ; vz = -0.85 * vz; bounced = true end
    if bounced then wx, wz = 0.6 * vz / K.R, -0.6 * vx / K.R end
    -- another ball?
    for n = 1, NB do
      local b = balls[n]
      if b.onTable and b ~= skip then
        local bx, bz = ballXZ(b)
        if (bx - px) ^ 2 + (bz - pz) ^ 2 < K.D * K.D then return px, pz, "ball" end
      end
    end
  end
  return px, pz
end

-- The ball on after potting b now (for planning).
local function onAfter(on, b)
  if on == "red" then return "colour" end
  if on == "colour" then return (redsLeft() > 0) and "red" or 2 end
  if on == 7 then return nil end
  return on + 1
end

-- The best shot from the cue ball's position: { aim, power, spinY, ev }.
function auto.bestShot(cx, cz)
  local on = S.on
  local list = pots(cx, cz, on)
  table.sort(list, function(a, b) return a.prob * potValue(a.b) > b.prob * potValue(b.b) end)
  local best
  local saved = { S.aim, S.power, S.spinX, S.spinY, cue.elev }
  for i = 1, math.min(8, #list) do
    local p = list[i]
    local after = onAfter(on, p.b)
    for _, spinY in ipairs({ -0.6, 0, 0.5 }) do
      for _, speed in ipairs({ 1.0, 1.5, 2.2 }) do
        planPace()
        local power = math.min(0.95, math.max(0.06, p.basePower * speed))
        S.aim, S.power, S.spinX, S.spinY, cue.elev = p.aim, power, 0, spinY, MIN_ELEV
        local _, gx, gz, hit, _, _, vx, vz, wx, wy, wz = predictCueBall()
        if hit == p.b then
          local bx, bz = ballXZ(p.b)
          local nx, nz = (bx - gx) / K.D, (bz - gz) / K.D
          local ex, ez, what = rollOut(gx, gz, vx, vz, wx, wy, wz, nx, nz, p.b)
          local nextEv = 0
          if what == "pocket" then nextEv = -6
          else
            -- (a red potted leaves the others; a colour after a red comes back to its spot)
            nextEv = nextValue(ex, ez, after, (p.b.red or type(on) == "number") and p.b or nil)
            if what == "ball" then nextEv = nextEv * 0.5 end
          end
          local ev = p.prob * (potValue(p.b) + 0.9 * nextEv)
          if not best or ev > best.ev then
            best = { aim = p.aim, power = power, spinY = spinY, ev = ev, n = p.b.n }
          end
        end
      end
    end
  end
  S.aim, S.power, S.spinX, S.spinY, cue.elev = saved[1], saved[2], saved[3], saved[4], saved[5]
  return best
end

-- Nothing to pot: touch a ball on softly (a legal shot), straight if it
-- can see one, or off a cushion.
function auto.safety(cx, cz)
  local best, bestD
  for n = 1, NB do
    local b = balls[n]
    if b.onTable and isOn(b) then
      local bx, bz = ballXZ(b)
      local dx, dz = bx - cx, bz - cz
      local d = math.sqrt(dx * dx + dz * dz)
      local _, hit = castCueBall(cx, cz, dx / d, dz / d)
      if hit == b and (not bestD or d < bestD) then
        best, bestD = { aim = math.atan2(dz, dx), power = math.min(0.5, 0.12 + d / 900), spinY = 0 }, d
      end
    end
  end
  if best then return best end
  -- off one cushion: aim at the ball's mirror image in it
  for n = 1, NB do
    local b = balls[n]
    if b.onTable and isOn(b) then
      local bx, bz = ballXZ(b)
      local limX, limZ = K.HL - K.R, K.HW - K.R
      for _, m in ipairs({ { 2 * limX - bx, bz }, { -2 * limX - bx, bz }, { bx, 2 * limZ - bz }, { bx, -2 * limZ - bz } }) do
        local dx, dz = m[1] - cx, m[2] - cz
        local d = math.sqrt(dx * dx + dz * dz)
        local _, hit = castCueBall(cx, cz, dx / d, dz / d)
        if not hit then
          return { aim = math.atan2(dz, dx), power = math.min(0.7, 0.2 + d / 700), spinY = 0 }
        end
      end
    end
  end
  return { aim = 0, power = 0.3, spinY = 0 }
end

-- The break-off: from the yellow side of the D, thin off the end red of
-- the back row, so the cue ball runs off the top and side cushions back
-- toward baulk.
function auto.breakOffShot(cx, cz)
  local target, tx, tz
  for n = 1, 15 do
    local b = balls[n]
    if b.onTable then
      local bx, bz = ballXZ(b)
      if not target or bz > tz + 0.1 or (math.abs(bz - tz) <= 0.1 and bx > tx) then target, tx, tz = b, bx, bz end
    end
  end
  if not target then return auto.safety(cx, cz) end
  -- a thin contact on its outside
  local gx, gz = tx - 0.35 * K.D, tz + 0.94 * K.D
  return { aim = math.atan2(gz - cz, gx - cx), power = 0.5, spinY = 0 }
end

-- Where to put the cue ball in the D: the spot with the best pot.
function auto.bestSpot()
  if S.breakOff then return K.BAULK_X - 1, K.D_R * 0.5 end
  local bestX, bestZ, bestScore = nil, nil, -1
  for x = K.BAULK_X - K.D_R, K.BAULK_X, 4 do
    for z = -K.D_R, K.D_R, 4 do
      planPace()
      if cueSpotFree(x, z) then
        local score = 0
        for _, p in ipairs(pots(x, z, S.on)) do score = math.max(score, p.prob * potValue(p.b)) end
        if score > bestScore then bestX, bestZ, bestScore = x, z, score end
      end
    end
  end
  return bestX, bestZ
end

function auto.toggle()
  auto.on = not auto.on
  auto.phase = "idle"
  if auto.on and S.state == "cleared" then rack() end
  S.dirty = true
end

-- One step of auto-play, from the draw loop.
function auto.tick()
  if not auto.on then return end
  local t = now()
  local st = S.state
  if st == "cleared" then
    auto.on = false                      -- the frame is done: stop and show the score
    S.dirty = true
    return
  end
  if auto.phase == "idle" then
    -- start thinking (see "thinking a little at a time"); it carries on
    -- below, this frame and the next few
    if st == "inhand" then
      auto.plan = planStart(function()
        local x, z = auto.bestSpot()
        return { x = x, z = z }
      end)
      auto.planFor, auto.phase = st, "plan"
    elseif st == "aim" then
      local cx, cz = ballXZ(balls[0])
      auto.plan = planStart(function()
        if S.breakOff then return auto.breakOffShot(cx, cz) end
        return auto.bestShot(cx, cz) or auto.safety(cx, cz)
      end)
      auto.planFor, auto.phase = st, "plan"
    end
  end
  if auto.phase == "plan" then
    if st ~= auto.planFor then
      auto.plan, auto.phase = nil, "idle"            -- (the table changed: start again)
    else
      local done, r = planStep(auto.plan)
      if done then
        local still = stillFrozen(auto.plan.xz)
        auto.plan, auto.phase = nil, "idle"
        if still and st == "inhand" then
          local x, z = r.x, r.z
          if not x then x, z = ballXZ(balls[0]) end
          auto.spot = { x = x, z = z }
          auto.phase, auto.t = "place", t
        elseif still then
          auto.shot = r
          S.spinX, S.spinY, S.elev = 0, auto.shot.spinY, 0
          auto.phase, auto.t = "turn", t
        end
      end
    end
  elseif auto.phase == "place" then
    -- slide the cue ball to its spot, then put it down
    local cx, cz = ballXZ(balls[0])
    local dx, dz = auto.spot.x - cx, auto.spot.z - cz
    local d = math.sqrt(dx * dx + dz * dz)
    local step = 60 * math.min(0.1, t - (auto.last or t))
    if d <= step or d < 0.1 then
      if cueSpotFree(auto.spot.x, auto.spot.z) then placeBall(balls[0], auto.spot.x, auto.spot.z) end
      S.state = "aim"
      S.message = ""
      auto.phase = "idle"
    else
      local nx, nz = cx + dx / d * step, cz + dz / d * step
      if cueSpotFree(nx, nz) then placeBall(balls[0], nx, nz)
      elseif cueSpotFree(auto.spot.x, auto.spot.z) then placeBall(balls[0], auto.spot.x, auto.spot.z) end
    end
    S.dirty = true
  elseif auto.phase == "turn" then
    if st ~= "aim" then auto.phase = "idle"; return end
    -- swing the cue round, and set the force, then pause and shoot
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
    if st ~= "aim" then auto.phase = "idle"; return end
    if t - auto.t >= AUTO_PAUSE then
      shoot()
      auto.phase = "idle"
    end
  end
  auto.last = t
end
-- Memory. bpp stops Lua's garbage collector (so it can never free a
-- Bullet object C++ still points to), which means every temporary vector
-- this script makes -- dozens every frame -- was kept forever: memory grew
-- by about 50 KB a frame. Everything this script creates that C++ holds
-- on to is either added to the world (bpp then owns it) or kept in the
-- script's own tables, so a collection here frees only garbage. Every 120
-- calls (about two seconds) it collects, then stops the collector again
-- as bpp wants it.
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
    local gap0 = 1.0 + 16 * S.power
    local f = S.strokeFrame / K.STROKE_FRAMES
    if f < 1 then
      placeCue(gap0 * (1 - f * f))
    else
      placeCue(0)
      strike()
      S.state = "rolling"
      S.rollFrames = 0
      S.stillFrames = 0
      S.followFrom = { cueGeometry(cue.elev or math.rad(4), 0) }
    end
    return
  end

  -- the cloth: rolling resistance, and side spin wearing off
  for n = 0, NB do
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

-- The cushions. Two things Bullet gets wrong here, both of which make the
-- cushions feel dead:
--  * Its solver starts braking a ball a step before it actually touches a
--    box, and at small time steps that swallows the whole bounce of a slow
--    ball (under about 1 m/s it stopped dead, or, arriving at an angle,
--    lost its speed off the cushion and rolled along it).
--  * A rolling ball keeps all its forward spin through the bounce, and the
--    cloth then drags it back toward the cushion: it came off at only a
--    third of the speed it arrived with. A real cushion's nose, above the
--    middle of the ball, grips it and takes that spin away.
-- So whenever a ball hits a cushion (or a pocket's jaw), the script sets
-- the rebound: E of the speed it arrived with, straight off the cushion,
-- and its forward roll into the cushion replaced by a roll away from it.
local E_CUSHION, E_JAW = 0.85, 0.60
local ROLL_AFTER = 0.6       -- it leaves rolling at this fraction of natural
                             -- roll for its new speed, so it checks up only a little
local function cushionBounce(b, x, z)
  -- the nearest cushion or jaw: the outward normal (nx, nz) from its nose
  -- to the ball's centre (at a jaw's point, straight out from the point)
  -- and the ball's gap to it
  local nx, nz, gap, e
  for _, l in ipairs(cushionLines) do
    local lx, lz = l.x2 - l.x1, l.z2 - l.z1
    local t = ((x - l.x1) * lx + (z - l.z1) * lz) / (lx * lx + lz * lz)
    t = math.max(0, math.min(1, t))
    local qx, qz = x - (l.x1 + lx * t), z - (l.z1 + lz * t)
    local d = math.sqrt(qx * qx + qz * qz)
    if d > 1e-6 and (not gap or d - K.R < gap) then
      nx, nz, gap, e = qx / d, qz / d, d - K.R, l.jaw and E_JAW or E_CUSHION
    end
  end
  if not gap or gap > 6 then return end
  local o = b.obj
  local vx, vy, vz = velXYZ(o)
  local before = -(b.vx * nx + b.vz * nz)       -- speed into the cushion last frame
  local now = -(vx * nx + vz * nz)              -- and now (negative: coming off it)
  -- a hit: it was heading in, it's touching (or a partial bounce has
  -- carried it up to a frame's travel away), and it has lost speed.
  -- (Bullet's braking can begin just before the frame ends, so any real
  -- loss counts, not only a dead stop.)
  if not (before > 0.5 and gap < 0.5 + math.max(0, -now) * K.FRAME
          and now < 0.9 * before - 0.3) then
    return
  end
  -- straight off the cushion at e x the speed it came in with (unless
  -- Bullet already bounced it that hard)
  local off = math.max(e * before, -now)
  setVel(o, vx + (off + now) * nx, vy, vz + (off + now) * nz)
  -- the roll into the cushion (spin about the axis a = up x (-n)) is
  -- taken away by the nose, and the ball leaves rolling off the cushion
  -- at ROLL_AFTER of its natural roll
  local ax, az = -nz, nx                         -- up x (-n) = (-nz, 0, nx)
  local wx, wy, wz = spinXYZ(o)
  local rollBefore = (b.wx or 0) * ax + (b.wz or 0) * az
  local rollNow = wx * ax + wz * az
  local target = -ROLL_AFTER * off / K.R          -- (negative along a: rolling away)
  if rollBefore < 0 then target = math.min(rollNow, target) end   -- (draw into it: keep the draw)
  setSpin(o, wx + (target - rollNow) * ax, wy, wz + (target - rollNow) * az)
  return true                                    -- (its velocity has changed)
end

v:postSim(function(N)
  S.frame = N
  gcTick()
  -- the first object ball the cue ball hits: the first to move (if two
  -- start in the same frame, the one nearer the cue ball)
  if S.state == "rolling" and not S.firstHit then
    local cx, cz = ballXZ(balls[0])
    local bestD
    for n = 1, NB do
      local b = balls[n]
      local vx, _, vz = velXYZ(b.obj)
      if b.onTable and vx * vx + vz * vz > 1 then
        local bx, bz = ballXZ(b)
        local d = (bx - cx) ^ 2 + (bz - cz) ^ 2
        if not bestD or d < bestD then S.firstHit, bestD = n, d end
      end
    end
    -- (a ball potted in the same frame it was hit)
    if not S.firstHit and #S.shotPotted > 0 then S.firstHit = S.shotPotted[1] end
  end
  -- follow-through: the cue carries on a little after the hit
  if S.state == "rolling" and S.rollFrames == 45 then
    cue.hide()                -- the player steps back from the table
  elseif S.state == "rolling" and S.rollFrames < 6 and S.followFrom then
    -- (along the cue, at the angle it was struck at)
    local f = S.followFrom
    local d = (S.rollFrames + 1) * 1.0
    cue.place(f[1] - f[4] * d, f[2] - f[5] * d, f[3] - f[6] * d, f[4], f[5], f[6])
  end

  local moving = false
  local sounds = 0
  for n = 0, NB do
    local b = balls[n]
    if b.onTable then
      local o = b.obj
      local x, y, z = posXYZ(o)
      local vx, vy, vz = velXYZ(o)
      -- dropped into a pocket? (only a ball down at the cloth: one in the
      -- air may be flying over it)
      local dropped = false
      local low = y < K.RAIL_H
      if low then
        -- (a fast ball can cross the mouth and hit the back of the pocket
        -- within one frame, so one heading in fast enough to be past the
        -- drop point by the next frame drops now)
        for _, pk in ipairs(pockets) do
          local rx, rz = x - pk.mx, z - pk.mz
          local depth = rx * pk.nx + rz * pk.nz
          local lat = math.abs(rx * pk.nz - rz * pk.nx)
          local out = vx * pk.nx + vz * pk.nz
          if (depth > pk.depth or (depth > -0.5 and depth + out * K.FRAME > pk.depth))
             and lat < pk.half + 2 then
            dropped = true
            break
          end
        end
        if not dropped and (math.abs(x) > K.HL + 2.5 or math.abs(z) > K.HW + 2.5) then
          dropped = true
        end
      end
      -- off the table: past the rails, fallen, or come to rest on a rail
      local off = math.abs(x) > K.OUT_X or math.abs(z) > K.OUT_Z or y < -5
      if not off and not low and (math.abs(x) > K.HL or math.abs(z) > K.HW) then
        if vx * vx + vy * vy + vz * vz < 9 then
          b.railFrames = (b.railFrames or 0) + 1
          off = b.railFrames > 30
        else
          b.railFrames = 0
        end
      end
      if dropped then
        potBall(b)
        S.dirty = true
      elseif off then
        offTable(b)
        S.dirty = true
      else
        -- landing from a jump: the cloth bounces it back up (Bullet's cloth
        -- doesn't bounce, which keeps balls rolling smoothly on it)
        if (b.vy or 0) < -K.LAND_MIN and vy > -5 and y < K.R + 0.3 then
          local land = -(b.vy or 0) + K.G * K.FRAME
          vy = K.LAND_E * land
          setVel(o, vx, vy, vz)
          playSound("cushion", math.min(1, land / 400))
        end
        b.vy = vy
        if y < K.R + 0.5 and cushionBounce(b, x, z) then   -- (not a ball flying over)
          vx, vy, vz = velXYZ(o)
        end
        -- a sudden change of velocity is a collision: click
        local dvx, dvz = vx - b.vx, vz - b.vz
        local dv = math.sqrt(dvx * dvx + dvz * dvz)
        if dv > 20 and sounds < MAX_SOUNDS_PER_FRAME then
          local kind = "cushion"
          for m = 0, NB do
            local o = balls[m]
            if m ~= n and o.onTable then
              local ox, oz = ballXZ(o)
              if (ox - x) ^ 2 + (oz - z) ^ 2 < (K.D + 1.0) ^ 2 then
                kind = (m < n) and "skip" or "ball"
                break
              end
            end
          end
          if kind ~= "skip" then
            playSound(kind, math.min(1, (dv / (kind == "ball" and 500 or 400)) ^ 0.7))
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

  if S.state == "rolling" then
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
  S = S, K = K, balls = balls, pockets = pockets, guide = guide, SPOTS = SPOTS, NB = NB,
  COLOUR_BALL = COLOUR_BALL,
  onKey = function(key, down) return onKey(S.frame, key, down) end,
  shoot = function(aimDeg, power, spinX, spinY)
    if S.state == "inhand" then S.state = "aim" end
    S.aim = math.rad(aimDeg)
    S.power = power
    S.spinX, S.spinY = spinX or 0, spinY or 0
    return shoot()
  end,
  placeCue = function(x, z) balls[0].onTable = true; placeBall(balls[0], x, z) end,
  place = function(n, x, z) balls[n].onTable = true; placeBall(balls[n], x, z) end,
  pot = potBall, rack = rack, auto = auto, planStart = planStart, planStep = planStep, predict = predictCueBall, cast = castCueBall,
  isOn = isOn, inD = inD, shotOver = shotOver, helpText = helpText, refresh = refresh,
  respotColour = respotColour, redsLeft = redsLeft,
  setView = function(view) S.view = view; setView() end,
}

-- ---------------------------------------------------------------------
-- start
-- ---------------------------------------------------------------------

math.randomseed(os.time())
rack()
setView()
refresh()
