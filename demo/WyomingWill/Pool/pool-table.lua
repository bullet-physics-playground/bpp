--
-- POOL TABLE -- one-player "clear the table" on a 9-foot pool table, for
-- the Bullet Physics Playground. Bullet does the balls, cushions and
-- pockets; you work the cue from the keyboard.
--
-- THE GAME: fifteen balls are racked at the foot spot. Break from the
-- kitchen (behind the head string, the line across the table through the
-- white head spot), then pocket every ball in as few shots as you can. Any
-- ball in any pocket counts, in any order. Pocketing the cue ball (a
-- scratch) costs one extra shot and gives you ball in hand in the kitchen.
-- From there you can't shoot straight at a ball that's also in the
-- kitchen (the shot is refused); if the cue ball hits one before it has
-- crossed the head string (off a cushion, say) it's a foul: one extra
-- shot, the balls it pocketed are spotted, and ball in hand again. Your
-- best (lowest) score is kept.
--
-- KEYS (click the 3D view first so it has keyboard focus; the Shortcuts
-- pane shows them too, with the aim, force and spin):
--   Left / Right     aim: a tap turns 0.25 degrees; hold to swing
--   ,  /  .          fine aim: a tap turns 0.02 degrees
--   Up / Down        force (1% a tap; hold to slide)
--   W / S            hit the cue ball higher (follow) or lower (draw)
--   A / D            hit it left or right of centre (side spin, "english")
--   C                back to a centre hit (every shot starts from one,
--                    with the cue level)
--   E / Q            raise / lower the back of the cue. Hitting down on the
--                    cue ball off centre curves it (a masse); a little
--                    raised, a side-spin shot swerves gently. Steep and
--                    firm, it jumps (about 45-60 degrees, force 50-70%).
--                    A ball that leaves the table, or comes to rest on a
--                    rail, is a foul: one penalty shot, the ball is spotted
--                    (the cue ball goes back in hand in the kitchen).
--   Space / Return   shoot
--   G                aiming guide (ghost ball and lines) on or off
--   V                back to the starting view, along the table (also undoes
--                    any turning or zooming with the mouse)
--   B                camera behind the cue (it follows your aim)
--   T                camera overhead
--   N or R           re-rack and start again
--   P                auto-play: the computer plays the rack for you (it
--                    picks the easiest pot, places the cue ball when it
--                    has ball in hand, and breaks). P again to take over.
-- With ball in hand the arrows move the cue ball around the kitchen (Up is
-- away from you) and Space or Return puts it down.
--
-- UNITS: centimetres, seconds, kilograms. The table's long axis is X (the
-- head end, where you break from, at -X), across it is Z, up is Y. The
-- playing surface is 254 x 127 cm, measured between the cushion noses.
--
-- FILES
--   pool-table.lua          this table
--   pool-table-meshes/      the cue and the ball markings (spots, stripes)
--   pool-table-sounds/      sound effects; missing ones are skipped
--
-- Needs bpp with the v:onKey() keyboard hook added alongside this table.
-- Two more additions are used when present: v:playSound(id, volume), so
-- soft hits click softly, and the objects' `collides` property, which
-- keeps the purely visual parts (cue, markings, guide) out of collision
-- detection -- without it the table still plays, but runs much slower.
--

local common = require "common"

local SOUND_DIR = "pool-table-sounds/"
local MESH_DIR = "pool-table-meshes/"
local PREFS_PREFIX = "pool-table/"

-- ---------------------------------------------------------------------
-- dimensions and physics
-- ---------------------------------------------------------------------

local K = {
  R = 2.8575,            -- ball radius (2 1/4 in ball)
  MASS = 0.17,
  HL = 127, HW = 63.5,   -- half the playing surface (cushion nose to nose)
  G = 981,
  FRAME = 1 / 60,
  CORNER_CUT = 8.0,      -- cushions stop this far from each corner (11.3 cm mouth)
  SIDE_HALF = 6.5,       -- half the side pocket mouth (13 cm)
  CUSHION_H = 4.0,       -- cushion top
  CUSHION_T = 5.0,       -- nose to rail
  RAIL_W = 12,           -- the wooden rail's width
  RAIL_H = 5.0,          -- its top
  VMAX = 1150,           -- cue ball speed at full force (about 26 mph)
  ROLL_DECEL = 10,       -- rolling resistance of the cloth, cm/s^2 (about 1% of g)
  SPIN_DECEL = 10,       -- side spin dies away at this many rad/s^2
  STOP_V = 0.8,          -- slower than this (cm/s) and not spinning: stopped
  MAX_TIP = 0.5,         -- furthest the tip may be off centre, x ball radius
  STROKE_FRAMES = 5,     -- the cue's forward stroke
  JUMP_MIN = 260,        -- a stroke driving the ball down faster than this
                         -- (cm/s) makes it jump off the cloth...
  JUMP_E = 0.70,         -- ...rising at this fraction of the excess (so only
                         -- a steep, firm stroke really leaves the cloth)
  LAND_E = 0.5,          -- a falling ball bounces off the cloth at this
  LAND_MIN = 40,         -- fraction of its speed, if it lands faster than this
}
K.D = 2 * K.R
K.NOSE_H = 0.635 * K.D                      -- cushion nose height (3.63 cm)
K.NOSE_TILT = math.asin((K.NOSE_H - K.R) / K.R)   -- its contact angle
K.RAIL_IN_X = K.HL + K.CUSHION_T            -- rail's inner edge
K.RAIL_IN_Z = K.HW + K.CUSHION_T
K.OUT_X = K.RAIL_IN_X + K.RAIL_W            -- table's outer edge
K.OUT_Z = K.RAIL_IN_Z + K.RAIL_W

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
  cloth = "#0b6e3c", cushion = "#095c32", rail = "#5a2e14", apron = "#3d1f0e",
  diamond = "#efe6cf", pocket = "#050505", spot = "#d9e8dc",
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
do
  local HL, HW, C = K.HL, K.HW, K.CORNER_CUT
  local r2 = math.sqrt(0.5)

  -- the cloth (the pockets are painted on it) and the table below
  -- (the cloth is a thick slab so a ball driven down hard into it by a
  -- steep cue can't pass through it)
  local cloth = box(0, -5, 0, 2 * K.RAIL_IN_X, 10, 2 * K.RAIL_IN_Z, COL.cloth)
  cloth.friction = 1.0
  cloth.restitution = 0.0
  box(0, -12, 0, 2 * K.OUT_X, 20, 2 * K.OUT_Z, COL.apron)
  for _, sx in ipairs({ -1, 1 }) do
    for _, sz in ipairs({ -1, 1 }) do
      box(sx * (K.OUT_X - 14), -52, sz * (K.OUT_Z - 14), 14, 60, 14, COL.apron)   -- legs
    end
  end

  -- long cushions (two on each side, split by the side pocket) and short ones
  for _, sz in ipairs({ -1, 1 }) do
    cushion(-HL + C, sz * HW, -K.SIDE_HALF, sz * HW, K.CUSHION_T, 0, 0)
    cushion(K.SIDE_HALF, sz * HW, HL - C, sz * HW, K.CUSHION_T, 0, 0)
  end
  for _, sx in ipairs({ -1, 1 }) do
    cushion(sx * HL, -HW + C, sx * HL, HW - C, K.CUSHION_T, 0, 0)
  end

  -- corner pockets: the jaws point out along the diagonal, closing in 7
  -- degrees so the pocket narrows as the ball goes in
  local JAW = 9
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
        -- the jaw's box goes on the side away from the middle of the pocket
        jaw(j[1], j[2], fx / fl, fz / fl, mx + nx * 4, mz + nz * 4)
      end
      pockets[#pockets + 1] = { mx = mx, mz = mz, nx = nx, nz = nz, half = C * r2,
                                depth = 2.0, corner = true }
      pocketHole(sx * HL + nx * 1.5, sz * HW + nz * 1.5, 6.5)
    end
  end

  -- side pockets: the jaws flare 14 degrees, wider at the mouth
  for _, sz in ipairs({ -1, 1 }) do
    local t = math.tan(math.rad(14))
    for _, sx in ipairs({ -1, 1 }) do
      local fx, fz = -sx * t, sz
      local fl = math.sqrt(fx * fx + fz * fz)
      jaw(sx * K.SIDE_HALF, sz * HW, fx / fl, fz / fl, 0, sz * (HW + 4))
    end
    pockets[#pockets + 1] = { mx = 0, mz = sz * HW, nx = 0, nz = sz, half = K.SIDE_HALF,
                              depth = 1.6, corner = false }
    pocketHole(0, sz * (HW + 6.6), 6.4)
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

  -- diamonds (sights) on the rails, and the head and foot spots
  for k = 1, 7 do
    if k ~= 4 then
      for _, sz in ipairs({ -1, 1 }) do
        disc(-HL + k * 2 * HL / 8, K.RAIL_H, sz * (K.RAIL_IN_Z + K.RAIL_W / 2), 0.6, COL.diamond)
      end
    end
  end
  for k = 1, 3 do
    for _, sx in ipairs({ -1, 1 }) do
      disc(sx * (K.RAIL_IN_X + K.RAIL_W / 2), K.RAIL_H, -HW + k * 2 * HW / 4, 0.6, COL.diamond)
    end
  end
  disc(-HL / 2, 0, 0, 0.5, COL.spot)
  disc(HL / 2, 0, 0, 0.5, COL.spot)

  -- the ball tray along the far side, where pocketed balls are lined up
  local TZ = K.OUT_Z + 7
  box(0, -4, TZ, 110, 2, 8, COL.apron)
  box(0, -1, TZ + 4.5, 110, 8, 1, COL.apron)
  box(0, -3.5, TZ - 4.5, 110, 3, 1, COL.apron)
  box(-55.5, -1, TZ, 1, 8, 10, COL.apron)
  box(55.5, -1, TZ, 1, 8, 10, COL.apron)
  K.TRAY_Z, K.TRAY_Y = TZ, -3 + K.R
end

-- ---------------------------------------------------------------------
-- the balls
-- ---------------------------------------------------------------------

-- (the colours of includes/ball1..8.jpeg and ball0.jpeg, so the POV-Ray
-- render looks like the 3D view)
local BALL_COLS = { "#feec02", "#182983", "#e53118", "#93117f", "#ef7f01", "#00914e", "#871421",
                    "#000000" }
local WHITE = "#f7f2d4"

-- A mesh that follows a ball around (its number spots, stripe or dots).
local function marking(file, col)
  local ok, m = pcall(function() return Mesh(MESH_DIR .. file, 0, false) end)
  if not ok or not m then return nil end
  m.col = col
  m.pov_export = false
  addVisual(m)
  return m
end

-- POV-Ray export: the balls wear Jaime Vives Piqueres' ivory textures
-- (http://ignorancia.org/index.php?page=pool-balls), t_ivory0..15, which
-- map includes/ball0..15.jpeg onto them -- so the markings aren't exported.
v.pre_sdl = [[
#declare use_media = 0;
#include "poolballs_textures.inc"
]]

local balls = {}          -- [0] the cue ball, [1..15] the object balls
for n = 0, 15 do
  local stripe = n >= 9
  local col = n == 0 and WHITE or (stripe and WHITE or BALL_COLS[n])
  local s = Sphere(K.R, K.MASS)
  s.col = col
  s.sdl = "texture { t_ivory" .. n .. " }"
  s.friction = 0.2
  s.restitution = 0.97
  s.damp_lin = 0
  s.damp_ang = 0
  v:add(s)
  s.body:setActivationState(4)          -- never goes to sleep
  s.body:setCcdMotionThreshold(tonumber(os.getenv("CCDT") or "") or K.R * 0.5)
  s.body:setCcdSweptSphereRadius(K.R * (tonumber(os.getenv("CCDR") or "") or 0.9))
  local mark
  if n == 0 then mark = marking("cue-dots.obj", "#c62828")
  elseif stripe then mark = marking("ball-stripe.obj", BALL_COLS[n - 8])
  else mark = marking("ball-spots.obj", WHITE) end
  balls[n] = { n = n, obj = s, mark = mark, onTable = true, vx = 0, vz = 0 }
end

local function syncMark(b)
  if b.mark then b.mark.trans = b.obj.trans end
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

local function ballXZ(b)
  local p = b.obj.pos
  return p.x, p.z
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
  rack = "rack.wav",            -- the balls are racked
  cleared = "table_cleared.wav",
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
-- the scoreboard: seven-segment digits on a panel past the foot of the
-- table, facing the player
-- ---------------------------------------------------------------------

local board = {}
local CHARS = {
  ["0"] = 63, ["1"] = 6, ["2"] = 91, ["3"] = 79, ["4"] = 102, ["5"] = 109,
  ["6"] = 125, ["7"] = 7, ["8"] = 127, ["9"] = 111,
  A = 119, B = 124, C = 57, D = 94, E = 121, F = 113, G = 61, H = 118, I = 48,
  J = 30, L = 56, N = 84, O = 63, P = 115, R = 80, S = 109, T = 120, U = 62,
  Y = 110, ["-"] = 64, [" "] = 0,
}
do
  local PX = K.OUT_X + 40            -- the panel's face
  local panel = Cube(1, 50, 124, 0)
  panel.pos = btVector3(PX + 0.5, 48, 0)
  panel.col = "#101418"
  v:add(panel)
  local post1 = Cube(3, 30, 3, 0); post1.pos = btVector3(PX + 1.5, 9, -50); post1.col = "#202428"
  local post2 = Cube(3, 30, 3, 0); post2.pos = btVector3(PX + 1.5, 9, 50); post2.col = "#202428"
  v:add(post1); v:add(post2)
  local BITS = { 1, 2, 4, 8, 16, 32, 64 }

  -- A row of digits starting at z0 (left, as the player sees it).
  local function digits(z0, y, count, scale, onCol, offCol, showOff)
    local W, H, T = 1.9 * scale, 3.2 * scale, 0.32 * scale
    local pitch = 3.0 * scale
    local segs = {   -- a..g: {dz, dy, width, height}
      { 0, H / 2, W - T, T }, { W / 2, H / 4, T, H / 2 - T }, { W / 2, -H / 4, T, H / 2 - T },
      { 0, -H / 2, W - T, T }, { -W / 2, -H / 4, T, H / 2 - T }, { -W / 2, H / 4, T, H / 2 - T },
      { 0, 0, W - T, T },
    }
    local d = { digits = {} }
    for k = 1, count do
      local z = z0 + (k - 1) * pitch
      local cubes = {}
      for s, g in ipairs(segs) do
        local c = Cube(0.3, g[4], g[3], 0)
        c.pos = btVector3(PX - 0.2, y + g[2], z + g[1])
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
  digits(-57, 66, 5, 1.1, LABEL, LABEL_OFF, false).set("SHOTS")
  board.shots = digits(-38, 65.5, 3, 2.2, LED, LED_OFF, true)
  digits(-5, 66, 4, 1.1, LABEL, LABEL_OFF, false).set("LEFT")
  board.left = digits(10, 65.5, 2, 2.2, LED, LED_OFF, true)
  digits(29, 66, 4, 1.1, LABEL, LABEL_OFF, false).set("BEST")
  board.best = digits(44, 65.5, 3, 2.2, LED, LED_OFF, true)
  board.message = digits(-54, 49, 12, 1.6, "#7cfc00", "#16240a", true)

  -- force: a bar of 20 lamps; spin: where the tip will strike the cue ball
  digits(-57, 33, 5, 1.1, LABEL, LABEL_OFF, false).set("FORCE")
  board.force = {}
  for i = 1, 20 do
    local c = Cube(0.3, 3.2, 2.0, 0)
    c.pos = btVector3(PX - 0.2, 33, -38 + (i - 1) * 2.6)
    c.col = "#1a1a1a"
    v:add(c)
    local on = i <= 12 and "#39d353" or (i <= 17 and "#ffd400" or "#ff3b30")
    board.force[i] = { obj = c, on = on, lit = false }
  end
  local face = Cylinder(6, 0.3, 0)
  face.trans = btTransform(btQuaternion(yAxis, math.pi / 2), btVector3(PX - 0.2, 36, 42))
  face.col = WHITE
  v:add(face)
  local dot = Cylinder(1.0, 0.3, 0)
  dot.col = "#c62828"
  v:add(dot)
  board.spinDot = function(sx, sy)
    -- the ball is 6 cm across on the panel; the dot shows the tip's offset
    dot.trans = btTransform(btQuaternion(yAxis, math.pi / 2),
                            btVector3(PX - 0.5, 36 + sy * 6 * K.MAX_TIP, 42 + sx * 6 * K.MAX_TIP))
  end
  board.spinDot(0, 0)
  board.setForce = function(p)
    local n = math.floor(p * 20 + 0.5)
    for i, s in ipairs(board.force) do
      local lit = i <= n
      if lit ~= s.lit then s.obj.col = lit and s.on or "#1a1a1a"; s.lit = lit end
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
  for n = 1, 15 do
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
  breakShot = true,     -- the next shot is the break
  kitchen = false,      -- the cue ball is in hand after a scratch or foul:
                        -- it mustn't be shot straight at a ball in the kitchen
  kitchenShot = false,  -- this shot is one of those
  kitchenBalls = {},    -- (object balls in the kitchen when it was taken)
  crossed = false,      -- the cue ball has crossed the head string this shot
  firstHit = nil,       -- the first object ball the cue ball touched
  foul = false,
  shotPotted = {},      -- object balls pocketed this shot
  jumpedOff = {},       -- object balls that left the table this shot
  aim = 0,              -- radians; 0 = toward the foot (+X)
  power = 0.30,         -- 0..1
  spinX = 0, spinY = 0, -- tip offset, -1..1 (right, up)
  elev = 0,             -- how far the player has raised the cue (radians);
                        -- it goes higher by itself if it must clear something
  shots = 0,
  best = nil,
  potted = {},          -- balls in pocket order
  message = "",
  view = "table",       -- table, cue, top
  scratched = false,
  stillFrames = 0,
  rollFrames = 0,
  strokeFrame = 0,
  dirty = true,         -- guide, cue, camera and help need redrawing
  frame = 0,
}
do
  local saved = v.loadPrefs and v:loadPrefs(PREFS_PREFIX .. "bestShots", "") or ""
  S.best = tonumber(saved)
end

local function now()
  if TF and TF.clock then return TF.clock() end
  return v.getTime and v:getTime() or S.frame * K.FRAME
end

local function aimDir()
  return math.cos(S.aim), math.sin(S.aim)
end

local function leftOnTable()
  local n = 0
  for i = 1, 15 do if balls[i].onTable then n = n + 1 end end
  return n
end

-- The kitchen: the end of the table behind the head string, the line
-- across the table through the head spot (the white dot at the end you
-- break from). A ball on the line counts as in the kitchen.
local HEAD_STRING = -K.HL / 2
local function inKitchen(x) return x <= HEAD_STRING + 0.01 end

-- Can the cue ball sit at (x, z)? Ball in hand always goes in the kitchen.
local function cueSpotFree(x, z)
  if math.abs(x) > K.HL - K.R - 0.05 or math.abs(z) > K.HW - K.R - 0.05 then return false end
  if not inKitchen(x) then return false end
  for n = 1, 15 do
    local b = balls[n]
    if b.onTable then
      local bx, bz = ballXZ(b)
      if (bx - x) ^ 2 + (bz - z) ^ 2 < (K.D + 0.05) ^ 2 then return false end
    end
  end
  return true
end

-- Ball in hand: the cue ball goes to the head spot, or the nearest free spot.
local function cueToHand()
  local cb = balls[0]
  cb.onTable = true
  local x0, z0 = -K.HL / 2, 0
  for r = 0, 60, 1 do
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

local function rack()
  -- the 1 at the apex on the foot spot, the 8 in the middle, a solid and a
  -- stripe in the back corners, the rest at random
  local order = {}
  local rest = {}
  for n = 2, 15 do if n ~= 8 then rest[#rest + 1] = n end end
  for i = #rest, 2, -1 do
    local j = math.random(i)
    rest[i], rest[j] = rest[j], rest[i]
  end
  -- back corners (positions 11 and 15): one solid, one stripe
  local solid, stripe
  for i, n in ipairs(rest) do
    if not solid and n < 8 then solid = table.remove(rest, i); break end
  end
  for i, n in ipairs(rest) do
    if not stripe and n > 8 then stripe = table.remove(rest, i); break end
  end
  if math.random() < 0.5 then solid, stripe = stripe, solid end
  local pos = 0
  local ri = 0
  local gap = 0.02            -- a hair between the balls
  local dx = (K.D + gap) * math.cos(math.rad(30))
  for row = 0, 4 do
    for k = 0, row do
      pos = pos + 1
      local n
      if pos == 1 then n = 1
      elseif pos == 5 then n = 8
      elseif pos == 11 then n = solid
      elseif pos == 15 then n = stripe
      else ri = ri + 1; n = rest[ri] end
      local b = balls[n]
      b.onTable = true
      placeBall(b, K.HL / 2 + row * dx, (k - row / 2) * (K.D + gap), K.R, randomRot())
    end
  end
  S.potted = {}
  S.shots = 0
  S.breakShot = true
  S.kitchen = false
  S.kitchenShot = false
  S.foul = false
  S.scratched = false
  S.state = "inhand"
  S.aim = 0
  S.spinX, S.spinY = 0, 0
  S.elev = 0
  S.power = 0.30
  S.message = "IN HAND"
  balls[0].onTable = true
  placeBall(balls[0], -K.HL / 2 - 10, 0, K.R, randomRot())
  S.dirty = true
  playSound("rack")
end

-- A ball has dropped: object balls go to the tray, the cue ball waits
-- there too until it's back in hand.
local function potBall(b)
  b.onTable = false
  local slot
  if b.n == 0 then
    S.scratched = true
    slot = -8.5
    playSound("scratch")
  else
    S.potted[#S.potted + 1] = b.n
    S.shotPotted[#S.shotPotted + 1] = b.n
    slot = #S.potted - 8
    playSound("pocket")
  end
  placeBall(b, slot * (K.D + 0.3), K.TRAY_Z, K.TRAY_Y)
end

-- A ball has left the table (jumped over the rail, or come to rest on
-- it): a foul. It waits beside the tray: the cue ball until it's back in
-- hand, an object ball until it's spotted.
local function offTable(b)
  b.onTable = false
  b.railFrames = 0
  S.foul = true
  S.offTable = true
  if b.n ~= 0 then S.jumpedOff[#S.jumpedOff + 1] = b.n end
  placeBall(b, (b.n == 0 and -8.5 or (9.5 + #S.jumpedOff)) * (K.D + 0.3), K.TRAY_Z, K.TRAY_Y)
  playSound("scratch")
end

-- Balls pocketed on a foul come back out: each goes on the foot spot, or
-- if that's taken, as near behind it (toward the foot rail) as it fits,
-- or failing that in front of it.
local function spotBall(b)
  local function free(x)
    for n = 0, 15 do
      local o = balls[n]
      if o.onTable and o ~= b then
        local ox, oz = ballXZ(o)
        if (ox - x) ^ 2 + oz ^ 2 < (K.D + 0.05) ^ 2 then return false end
      end
    end
    return true
  end
  local x = K.HL / 2
  while not free(x) and x < K.HL - K.R - 0.1 do x = x + 0.5 end
  if not free(x) then
    x = K.HL / 2
    while not free(x) and x > -K.HL + K.R do x = x - 0.5 end
  end
  b.onTable = true
  placeBall(b, x, 0, K.R, randomRot())
end

local function respotShotBalls()
  for _, n in ipairs(S.jumpedOff) do S.shotPotted[#S.shotPotted + 1] = n end
  S.jumpedOff = {}
  table.sort(S.shotPotted)               -- lowest number first
  for _, n in ipairs(S.shotPotted) do
    for i, m in ipairs(S.potted) do
      if m == n then table.remove(S.potted, i); break end
    end
    spotBall(balls[n])
  end
  -- close up the gaps in the tray
  for i, n in ipairs(S.potted) do
    placeBall(balls[n], (i - 8) * (K.D + 0.3), K.TRAY_Z, K.TRAY_Y)
  end
  S.shotPotted = {}
end

-- ---------------------------------------------------------------------
-- the view
-- ---------------------------------------------------------------------

local function setView()
  if S.view == "top" then
    common.setCamera(btVector3(0, 360, 0.01), btVector3(0, 0, 0), 0.8, { up = btVector3(0, 0, -1) })
  elseif S.view == "cue" then
    local cx, cz = ballXZ(balls[0])
    local dx, dz = aimDir()
    common.setCamera(btVector3(cx - dx * 95, 38, cz - dz * 95),
                     btVector3(cx + dx * 70, 0, cz + dz * 70), 0.8, { up = yAxis })
  else
    common.setCamera(btVector3(-250, 185, 0), btVector3(20, -15, 0), 0.8, { up = yAxis })
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
  for n = 1, 15 do
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

-- Is the cue ball, as aimed, going straight at a ball it may not hit?
local function aimedIntoKitchen()
  if not S.kitchen then return false end
  local cx, cz = ballXZ(balls[0])
  local dx, dz = aimDir()
  local _, hit = castCueBall(cx, cz, dx, dz)
  return hit ~= nil and inKitchen((ballXZ(hit)))
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
  for _ = 1, 240 * 8 do
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
    for n = 1, 15 do
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
      return path, px, pz, hit, ux, uz
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
  -- while the cue ball is in (or must shoot out of) the kitchen, show the
  -- head string
  if st == "inhand" or S.kitchen then
    guide.line(HEAD_STRING, -K.HW, HEAD_STRING, K.HW, "#cfe8d5")
  end
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
  local barred = S.kitchen and hit and inKitchen((ballXZ(hit)))
  guide.path(path, barred and "#ff5a4f" or "#ffffff")
  guide.ghost.pos = btVector3(gx, K.R, gz)
  local gcol = barred and "#ff3b30" or "#ffffff"
  if guide.ghost.col ~= gcol then guide.ghost.col = gcol end
  if hit and not barred then
    local bx, bz = ballXZ(hit)
    local ux, uz = throwX or (bx - gx) / K.D, throwZ or (bz - gz) / K.D
    guide.line(bx, bz, bx + ux * 30, bz + uz * 30, "#ffe066")
    -- the cue ball glances off at right angles (for a hit without spin)
    local dot = dx * ux + dz * uz
    local tx, tz = dx - dot * ux, dz - dot * uz
    local tl = math.sqrt(tx * tx + tz * tz)
    if tl > 0.05 then
      guide.line(gx, gz, gx + tx / tl * 18, gz + tz / tl * 18, "#8ecae6")
    end
  end
end

-- auto-play (P): the computer plays the rack; filled in further down
local auto = { on = false }

-- ---------------------------------------------------------------------
-- the shortcuts pane
-- ---------------------------------------------------------------------

local function helpText()
  local lines = {}
  local function add(s) lines[#lines + 1] = s end
  add("POOL -- clear the table" .. (auto.on and "      AUTO-PLAY: the computer is playing (P to take over)" or ""))
  add("")
  local st = S.state
  if st == "inhand" then
    add(S.breakShot and "Ball in hand in the kitchen (behind the head string): place the cue ball for the break."
                     or "Ball in hand in the kitchen (behind the head string): place the cue ball.")
  elseif st == "aim" and S.kitchen then
    add("Your shot, from the kitchen: you can't shoot straight at a ball behind the head string.")
    add("(A red ghost ball means you're aimed at one. The cue ball must cross the line before it hits one.)")
  elseif st == "aim" then add("Your shot.")
  elseif st == "stroke" or st == "rolling" then add("Balls rolling...")
  elseif st == "cleared" then add("Table cleared in " .. S.shots .. " shots! Press N for a new rack.")
  end
  add(string.format("Shots %d   Balls left %d   Best %s", S.shots, leftOnTable(),
                    S.best and tostring(S.best) or "-"))
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
  add("")
  if st == "inhand" then
    add("Arrows      move the cue ball (Up = away from you)")
    add("Space/Enter put it down")
  else
    add("Left/Right  aim (tap for a quarter degree, hold to swing)")
    add(",  .        fine aim")
    add("Up/Down     force")
    add("W/S         hit higher (follow) / lower (draw)")
    add("A/D         hit left / right (side spin)")
    add("C           centre hit")
    add("E/Q         raise / lower the cue: steep + off centre curves (masse),")
    add("            steep + firm jumps (about 45-60 deg, force 50-70%)")
    add("Space/Enter shoot")
  end
  add("G           aiming guide " .. (guide.on and "(on)" or "(off)"))
  add("V           back to the starting view" .. (S.view == "table" and " (now)" or ""))
  add("B           camera behind the cue" .. (S.view == "cue" and " (now)" or ""))
  add("T           camera overhead" .. (S.view == "top" and " (now)" or ""))
  add("N or R      re-rack")
  add("P           auto-play: the computer plays the rack " .. (auto.on and "(on)" or "(off)"))
  add("")
  add("Scratch (cue ball in a pocket): one penalty shot and ball in hand in the kitchen.")
  add("Foul (after ball in hand, hitting a kitchen ball before the cue ball leaves the kitchen):")
  add("one penalty shot, balls pocketed on the shot are spotted, and ball in hand in the kitchen.")
  return table.concat(lines, "\n")
end

-- ---------------------------------------------------------------------
-- shooting
-- ---------------------------------------------------------------------

-- The shot: an impulse on the cue ball at the point the tip meets it,
-- along the cue. With the cue raised it drives the ball down into the
-- cloth; the cloth's friction during that hit, and the spin the ball
-- gets about a tilted axis, are what curve it (a masse, or a gentle swerve
-- when the cue is only a little raised and the ball is hit off centre).
-- Hitting left or right of centre also pushes the ball a little the other
-- way off the line of the cue (squirt), as a real cue does.
local function strike()
  local cb = balls[0]
  -- the direction of the stroke (down the cue, turned by the squirt), the
  -- point the tip meets, and the speed
  local fx, fy, fz, rx, ry, rz, speed = strokeNow()
  local J = K.MASS * speed
  -- The part of the stroke driving the ball down into the cloth: its
  -- turning effect (the masse spin) is kept, but the cloth takes the push
  -- itself, so it's left out. (Handed to Bullet, the bounce off the cloth
  -- with its friction threw the ball sideways at once, instead of the ball
  -- setting off along the cue and then curving.)
  local body = cb.obj.body
  body:applyImpulse(btVector3(fx * J, 0, fz * J), btVector3(rx, ry, rz))
  local vy = fy * J                                   -- (r x (0, vy, 0))
  body:applyTorqueImpulse(btVector3(-rz * vy, 0, rx * vy))
  -- a hard stroke down into the cloth makes the ball jump: the slate
  -- throws it back up (much of the blow is lost in the cloth and the cue)
  local down = -fy * speed
  if down > K.JUMP_MIN then
    local v = body:getLinearVelocity()
    local up = K.JUMP_E * (down - K.JUMP_MIN)
    -- the cloth's grip during that bounce also takes off some of its speed
    -- along the table
    local h = math.sqrt(v.x * v.x + v.z * v.z)
    local keep = h > 0 and math.max(0.5, 1 - 0.2 * (down + up) / h) or 1
    body:setLinearVelocity(btVector3(v.x * keep, up, v.z * keep))
  end
  cb.vx, cb.vz = fx * speed, fz * speed     -- (not a collision)
  playSound("cue", math.min(1, 0.25 + S.power))
end

local function shoot()
  if S.state ~= "aim" then return false end
  if aimedIntoKitchen() then
    S.message = "BEHInd LInE"        -- not allowed: aim somewhere else
    S.dirty = true
    return false
  end
  S.state = "stroke"
  S.strokeFrame = 0
  S.shots = S.shots + 1
  S.scratched = false
  S.foul = false
  S.message = ""
  S.breakShot = false
  S.kitchenShot = S.kitchen
  S.kitchen = false
  S.crossed = false
  S.firstHit = nil
  S.shotPotted = {}
  S.jumpedOff = {}
  S.offTable = false
  S.kitchenBalls = {}
  for n = 1, 15 do
    if balls[n].onTable and inKitchen((ballXZ(balls[n]))) then S.kitchenBalls[n] = true end
  end
  guide.clear()
  S.dirty = true
  return true
end

-- when every ball has stopped: what happened?
local function shotOver()
  -- each shot starts from a centre hit with the cue level (the aim and
  -- force are kept)
  S.spinX, S.spinY, S.elev = 0, 0, 0
  if S.foul then
    S.shots = S.shots + 1                 -- the penalty (one, even with a scratch too)
    S.message = S.offTable and "OFF TABLE" or "FOUL"
    respotShotBalls()
  elseif S.scratched then
    S.shots = S.shots + 1                 -- the penalty
    S.message = "SCRATCH"
  end
  local inHand = S.scratched or S.foul
  if leftOnTable() == 0 then
    S.state = "cleared"
    S.message = "CLEARED"
    if not S.best or S.shots < S.best then
      S.best = S.shots
      if v.savePrefs then pcall(function() v:savePrefs(PREFS_PREFIX .. "bestShots", tostring(S.best)) end) end
    end
    playSound("cleared")
  elseif inHand then
    S.state = "inhand"
    S.kitchen = true
    cueToHand()                           -- (picked up, if it's still on the table)
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
      if S.message == "BEHInd LInE" then S.message = "" end
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

local function refresh()
  -- scoreboard
  local want = {
    shots = tostring(S.shots),
    left = tostring(leftOnTable()),
    best = S.best and tostring(S.best) or "",
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
  -- cue, guide and camera
  if S.state == "aim" or S.state == "inhand" then
    if S.state == "aim" then placeCue(1.0 + 16 * S.power) else cue.hide() end
    drawGuide()
    if S.view == "cue" then setView() end
  end
  local text = helpText()
  if text ~= lastHelp then
    lastHelp = text
    if v.setHelpText then v:setHelpText(text) end
  end
end


-- ---------------------------------------------------------------------
-- auto-play: the computer plays. It looks at every ball and pocket for
-- the easiest pot it can make (a clear path for both balls, a modest cut,
-- short distances), works out how hard to hit it, turns the cue to it and
-- shoots. With ball in hand it puts the cue ball where the best shot is.
-- It never uses spin except a little draw on straight shots (so the cue
-- ball doesn't follow the object ball into the pocket), and when there's
-- nothing to pot it plays a firm shot at the easiest ball to hit (from
-- the kitchen with every ball behind the line, a bank off the foot
-- cushion).
-- ---------------------------------------------------------------------

auto.phase = "idle"
local AUTO_TURN = math.rad(120)   -- how fast it swings the cue (per second)
local AUTO_PAUSE = 0.6            -- a moment to settle before shooting

-- Is the segment (x1,z1)-(x2,z2) clear of balls (other than `skip1`,
-- `skip2`) by `width` (distance from its line to a ball's centre)?
local function laneClear(x1, z1, x2, z2, width, skip1, skip2)
  local dx, dz = x2 - x1, z2 - z1
  local L2 = dx * dx + dz * dz
  for n = 0, 15 do
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

-- Would a cue ball leaving (gx, gz) along (tx, tz) run into a pocket soon?
local function scratchRisk(gx, gz, tx, tz, reach)
  for _, pk in ipairs(pockets) do
    local px, pz = pk.mx, pk.mz
    local a = (px - gx) * tx + (pz - gz) * tz
    if a > 0 and a < reach then
      local qx, qz = gx + tx * a - px, gz + tz * a - pz
      if qx * qx + qz * qz < 7 * 7 then return true end
    end
  end
  return false
end

-- The best pot from a cue ball at (cx, cz): { aim, power, spinY, score, n }
-- or nil. Higher scores are easier.
function auto.bestShot(cx, cz)
  local best
  local cb = balls[0]
  for n = 1, 15 do
    local b = balls[n]
    if b.onTable then
      local bx, bz = ballXZ(b)
      if not (S.kitchen and inKitchen(bx)) then
        for _, pk in ipairs(pockets) do
          -- aim the object ball just inside the pocket's mouth
          local tx, tz = pk.mx + pk.nx * 1.5, pk.mz + pk.nz * 1.5
          local ux, uz = tx - bx, tz - bz
          local ul = math.sqrt(ux * ux + uz * uz)
          ux, uz = ux / ul, uz / ul
          local facing = ux * pk.nx + uz * pk.nz        -- 1: straight into the pocket
          if facing > (pk.corner and 0.45 or 0.8) then
            local gx, gz = bx - ux * K.D, bz - uz * K.D  -- the ghost ball
            if math.abs(gx) < K.HL - K.R and math.abs(gz) < K.HW - K.R then
              local ax, az = gx - cx, gz - cz
              local al = math.sqrt(ax * ax + az * az)
              if al > 1 then
                local cutcos = (ax * ux + az * uz) / al
                if cutcos > math.cos(math.rad(72))
                   and laneClear(cx, cz, gx, gz, K.D - 0.05, cb, b)
                   and laneClear(bx, bz, tx, tz, K.D - 0.05, cb, b) then
                  local aim = math.atan2(az, ax)
                  local _, hit = castCueBall(cx, cz, ax / al, az / al)
                  if hit == b then
                    -- easier: a fuller hit, shorter distances, a pocket faced squarely
                    local score = cutcos * cutcos * (pk.corner and facing or facing * 0.8)
                                  / ((al + 20) * (ul + 20)) * 1e4
                    -- how hard: the object ball must reach the pocket with a
                    -- little pace left; the cue ball must reach the ghost with
                    -- enough to give it that (the cut sends only cos of it)
                    local vo = math.sqrt(70 * 70 + 2 * K.ROLL_DECEL * 1.6 * ul)
                    local vc = vo / (0.95 * math.max(cutcos, 0.3))
                    local v0 = math.sqrt(vc * vc + 2 * 40 * al)
                    local power = math.max(0.06, math.min(0.9, 1.1 * v0 / K.VMAX))
                    -- straight shots: a little draw, so the cue ball stops
                    -- short of the pocket instead of following
                    local spinY = cutcos > math.cos(math.rad(12)) and -0.35 or 0
                    -- a stun cut sends the cue ball off at right angles:
                    -- avoid shots that send it into a pocket
                    local qx, qz = ax / al - (ax / al * ux + az / al * uz) * ux,
                                   az / al - (ax / al * ux + az / al * uz) * uz
                    local ql = math.sqrt(qx * qx + qz * qz)
                    if ql > 0.2 and scratchRisk(gx, gz, qx / ql, qz / ql, 80) then score = score * 0.25 end
                    if spinY == 0 and ql <= 0.2 and scratchRisk(gx, gz, ux, uz, ul + 10) then score = score * 0.3 end
                    if not best or score > best.score then
                      best = { aim = aim, power = power, spinY = spinY, score = score, n = n }
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  return best
end

-- Nothing to pot: a firm shot at the easiest ball to hit, or from the
-- kitchen with every ball behind the line, a bank off the foot cushion.
function auto.fallback(cx, cz)
  local best, bestD
  for n = 1, 15 do
    local b = balls[n]
    if b.onTable then
      local bx, bz = ballXZ(b)
      local dx, dz = bx - cx, bz - cz
      local d = math.sqrt(dx * dx + dz * dz)
      if not (S.kitchen and inKitchen(bx)) then
        local _, hit = castCueBall(cx, cz, dx / d, dz / d)
        if hit == b and (not bestD or d < bestD) then best, bestD = { aim = math.atan2(dz, dx), power = 0.45, spinY = 0 }, d end
      end
    end
  end
  if best then return best end
  -- bank: aim at the ball's mirror image beyond the foot cushion
  for n = 1, 15 do
    local b = balls[n]
    if b.onTable then
      local bx, bz = ballXZ(b)
      local mx = 2 * (K.HL - K.R) - bx
      return { aim = math.atan2(bz - cz, mx - cx), power = 0.6, spinY = 0 }
    end
  end
  return { aim = 0, power = 0.3, spinY = 0 }
end

-- Where to put the cue ball in the kitchen: the spot with the best shot.
function auto.bestSpot()
  if S.breakShot then return HEAD_STRING - 1, (math.random() - 0.5) * 20, nil end
  local bestX, bestZ, bestScore = nil, nil, -1
  for x = -K.HL + K.R + 1, HEAD_STRING, 6 do
    for z = -K.HW + K.R + 1, K.HW - K.R - 1, 6 do
      if cueSpotFree(x, z) then
        local shot = auto.bestShot(x, z)
        local score = shot and shot.score or 0
        if score > bestScore then bestX, bestZ, bestScore = x, z, score end
      end
    end
  end
  return bestX, bestZ
end

function auto.toggle()
  auto.on = not auto.on
  auto.phase = "idle"
  if S.message == "AUTO" then S.message = "" end
  if auto.on and S.state == "cleared" then rack() end
  S.dirty = true
end

-- One step of auto-play, from the draw loop.
function auto.tick()
  if not auto.on then return end
  local t = now()
  local st = S.state
  if st == "cleared" then
    auto.on = false                      -- the rack is done: stop and show the score
    S.dirty = true
    return
  end
  if auto.phase == "idle" then
    if st == "inhand" then
      local x, z = auto.bestSpot()
      if not x then x, z = ballXZ(balls[0]) end
      auto.spot = { x = x, z = z }
      auto.phase, auto.t = "place", t
    elseif st == "aim" then
      local cx, cz = ballXZ(balls[0])
      if S.breakShot then
        auto.shot = { aim = math.atan2(-cz, K.HL / 2 - cx), power = 0.95, spinY = -0.1 }
      else
        auto.shot = auto.bestShot(cx, cz) or auto.fallback(cx, cz)
      end
      S.spinX, S.spinY, S.elev = 0, auto.shot.spinY, 0
      auto.phase, auto.t = "turn", t
    end
  elseif auto.phase == "place" then
    -- slide the cue ball to its spot, then put it down
    local cx, cz = ballXZ(balls[0])
    local dx, dz = auto.spot.x - cx, auto.spot.z - cz
    local d = math.sqrt(dx * dx + dz * dz)
    local step = 80 * math.min(0.1, t - (auto.last or t))
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
      if not shoot() then
        -- (refused: straight at a ball in the kitchen) try the fallback,
        -- and failing that, straight up the table
        auto.refused = (auto.refused or 0) + 1
        local cx, cz = ballXZ(balls[0])
        auto.shot = auto.refused < 2 and auto.fallback(cx, cz)
                    or { aim = (math.random() - 0.5) * 0.6, power = 0.5, spinY = 0 }
        auto.phase = "turn"
      else
        auto.refused = 0
        auto.phase = "idle"
      end
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
  for n = 0, 15 do
    local b = balls[n]
    if b.onTable and b.obj.pos.y < K.R + 0.2 then   -- (not in the air)
      local body = b.obj.body
      local vel = body:getLinearVelocity()
      local w = body:getAngularVelocity()
      local sp = math.sqrt(vel.x * vel.x + vel.z * vel.z)
      local wr = math.sqrt(w.x * w.x + w.z * w.z) * K.R
      if sp < K.STOP_V and wr < 1.5 * K.STOP_V and math.abs(w.y) < 0.5 then
        if sp > 0 or wr > 0 or w.y ~= 0 then
          body:setLinearVelocity(btVector3(0, vel.y, 0))
          body:setAngularVelocity(btVector3(0, 0, 0))
        end
      else
        local f = sp > 0 and math.max(0, sp - K.ROLL_DECEL * K.FRAME) / sp or 1
        local wy = w.y
        local dwy = K.SPIN_DECEL * K.FRAME
        wy = (math.abs(wy) <= dwy) and 0 or (wy - dwy * (wy > 0 and 1 or -1))
        body:setLinearVelocity(btVector3(vel.x * f, vel.y, vel.z * f))
        body:setAngularVelocity(btVector3(w.x * f, wy, w.z * f))
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
  local vel = b.obj.vel
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
  local before = -(b.vx * nx + b.vz * nz)       -- speed into the cushion last frame
  local now = -(vel.x * nx + vel.z * nz)        -- and now (negative: coming off it)
  -- a hit: it was heading in, it's touching (or a partial bounce has
  -- carried it up to a frame's travel away), and it has lost speed.
  -- (Bullet's braking can begin just before the frame ends, so any real
  -- loss counts, not only a dead stop.)
  if not (before > 0.5 and gap < 0.5 + math.max(0, -now) * K.FRAME
          and now < 0.9 * before - 0.3) then
    return
  end
  local body = b.obj.body
  -- straight off the cushion at e x the speed it came in with (unless
  -- Bullet already bounced it that hard)
  local off = math.max(e * before, -now)
  body:setLinearVelocity(btVector3(vel.x + (off + now) * nx, vel.y, vel.z + (off + now) * nz))
  -- the roll into the cushion (spin about the axis a = up x (-n)) is
  -- taken away by the nose, and the ball leaves rolling off the cushion
  -- at ROLL_AFTER of its natural roll
  local ax, az = -nz, nx                         -- up x (-n) = (-nz, 0, nx)
  local w = body:getAngularVelocity()
  local rollBefore = (b.wx or 0) * ax + (b.wz or 0) * az
  local rollNow = w.x * ax + w.z * az
  local target = -ROLL_AFTER * off / K.R          -- (negative along a: rolling away)
  if rollBefore < 0 then target = math.min(rollNow, target) end   -- (draw into it: keep the draw)
  body:setAngularVelocity(btVector3(w.x + (target - rollNow) * ax, w.y, w.z + (target - rollNow) * az))
end

v:postSim(function(N)
  S.frame = N
  gcTick()
  -- a shot from the kitchen: did the cue ball leave it before it hit
  -- anything? The first object ball to move is the one it hit first.
  if S.state == "rolling" and S.kitchenShot and not S.firstHit then
    if balls[0].onTable and not inKitchen(balls[0].obj.pos.x) then S.crossed = true end
    for n = 1, 15 do
      local b = balls[n]
      if b.onTable then
        local vel = b.obj.vel
        if vel.x * vel.x + vel.z * vel.z > 1 then
          S.firstHit = n
          if S.kitchenBalls[n] and not S.crossed then S.foul = true end
          break
        end
      end
    end
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
  for n = 0, 15 do
    local b = balls[n]
    if b.onTable then
      local p = b.obj.pos
      local x, z = p.x, p.z
      -- dropped into a pocket? (only a ball down at the cloth: one in the
      -- air may be flying over it)
      local dropped = false
      local low = p.y < K.RAIL_H
      if low then
        for _, pk in ipairs(pockets) do
          local rx, rz = x - pk.mx, z - pk.mz
          local depth = rx * pk.nx + rz * pk.nz
          local lat = math.abs(rx * pk.nz - rz * pk.nx)
          if depth > pk.depth and lat < pk.half + 2 then dropped = true; break end
        end
        if not dropped and (math.abs(x) > K.HL + 2.5 or math.abs(z) > K.HW + 2.5) then
          dropped = true
        end
      end
      -- off the table: past the rails, fallen, or come to rest on a rail
      local off = math.abs(x) > K.OUT_X or math.abs(z) > K.OUT_Z or p.y < -5
      if not off and not low and (math.abs(x) > K.HL or math.abs(z) > K.HW) then
        local v = b.obj.vel
        if v.x * v.x + v.y * v.y + v.z * v.z < 9 then
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
        local vy = b.obj.vel.y
        if (b.vy or 0) < -K.LAND_MIN and vy > -5 and p.y < K.R + 0.3 then
          local land = -(b.vy or 0) + K.G * K.FRAME
          local v = b.obj.vel
          b.obj.body:setLinearVelocity(btVector3(v.x, K.LAND_E * land, v.z))
          playSound("cushion", math.min(1, land / 400))
        end
        b.vy = b.obj.vel.y
        if p.y < K.R + 0.5 then cushionBounce(b, x, z) end   -- (not a ball flying over)
        local vel = b.obj.vel
        -- a sudden change of velocity is a collision: click
        local dvx, dvz = vel.x - b.vx, vel.z - b.vz
        local dv = math.sqrt(dvx * dvx + dvz * dvz)
        if dv > 20 and sounds < MAX_SOUNDS_PER_FRAME then
          local kind = "cushion"
          for m = 0, 15 do
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
        b.vx, b.vz = vel.x, vel.z
        local wv = b.obj.body:getAngularVelocity()
        b.wx, b.wz = wv.x, wv.z
        local w = b.obj.body:getAngularVelocity()
        if vel.x * vel.x + vel.z * vel.z + vel.y * vel.y > 0.25 or p.y > K.R + 0.3
           or (w.x * w.x + w.y * w.y + w.z * w.z) > 0.05 then
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
  S = S, K = K, balls = balls, pockets = pockets, guide = guide,
  onKey = function(key, down) return onKey(S.frame, key, down) end,
  shoot = function(aimDeg, power, spinX, spinY)
    if S.state == "inhand" then S.state = "aim" end
    S.aim = math.rad(aimDeg)
    S.power = power
    S.spinX, S.spinY = spinX or 0, spinY or 0
    return shoot()
  end,
  placeCue = function(x, z) placeBall(balls[0], x, z) end,
  place = function(n, x, z) balls[n].onTable = true; placeBall(balls[n], x, z) end,
  rack = rack, auto = auto, predict = predictCueBall, cast = castCueBall, placeCueAt = placeCue, cue = cue, cueGeometry = cueGeometry, inKitchen = inKitchen, pot = potBall, shotOver = shotOver, helpText = helpText, refresh = refresh,
  setView = function(view) S.view = view; setView() end,
}

-- ---------------------------------------------------------------------
-- start
-- ---------------------------------------------------------------------

math.randomseed(os.time())
rack()
setView()
refresh()
