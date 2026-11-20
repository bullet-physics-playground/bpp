--
-- Napier's Bones -- Babbage's Hall
--
-- The multiplication table, cut into rods. Each face of a rod carries one
-- digit's multiples, x 1 to x 9, each cell split by a diagonal: the tens
-- above it, the units below. Lay the rods for 4138 side by side beside the
-- index, and row 6 holds the multiples of every digit at once; adding along
-- the diagonals, from the right, gives 4138 x 6. John Napier published them
-- in 1617 (Rabdologiae). Genaille's rods (Henri Genaille and Edouard Lucas,
-- about 1891) draw the carries as triangles, so that the product is read
-- with no adding at all.
--
-- TWO WAYS (NB_WAY; in the hall, Tab steps through them)
--   napier     (the default) Napier's bones: the row, then along the
--              diagonals; a multiplier of several digits, a row each, added
--   genaille   Genaille's rods: the row, then follow the triangles
--
-- KEYS
--   0 - 9      a number, then X and the multiplier, then Return
--   Backspace  a figure off        C  clear the board (the rods back in the tray)
--   M          the camera close to the board; again: back
--   T          the tour
--
-- PHYSICS: the ten rods are bodies (boxes, 16 mm square, 176 mm long); the
-- board (its plate, its ledge, the index rod against its rim) and the tray
-- are solid. The operator's hand is the script's: it takes hold of a rod
-- (steering it, its weight held), lifts it, turns it to the face it needs,
-- carries it to the board and sets it down beside the last; then lets go
-- and presses it left and down until it stops against its neighbour and the
-- ledge. The board is tilted 20 degrees; a rod stays where it is by
-- friction and the ledge. Every reading is taken from where the rods lie:
-- which face is up (from each rod's orientation) and which of its cells is
-- level with the index's row. The slate, the hand, the reading strip and the
-- adding are the script's (said so). 600 steps a second.
--
-- EVERY PART CAN BE PRINTED; the faces are printed on paper
-- (napier-faces.pdf, genaille-faces.pdf) and wrapped round the rods.
-- README.md.
--
-- Units: centimetres, kilograms, seconds.
-- Headless: NB_WAY (napier, genaille), NB_TOUR=0, NB_LOG=1 (print each
-- move), NB_FRICTION (the rods' friction coefficient), NB_HAND (the hand's
-- speed, cm/s), NB_PUSH (how hard the hand presses a rod into place, kg
-- cm/s^2), NB_TILT (the board's tilt, degrees; the parts are drawn at 20),
-- NB_HZ, NB_RANDOM=n (n random problems instead of the tour), NB_SEED,
-- NB_CREEP=1 (each rod watched for 10 s after it is pressed into place),
-- NB_SLEEP (how slow a rod still for 2 s must be to sleep, cm/s; 0: never).
--

local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end

-- ---------------------------------------------------------------------
-- this exhibit's folder; the parts file by its full path (for OpenSCAD)
-- ---------------------------------------------------------------------
local DIR
for _, d in ipairs({ "", "demo/WyomingWill/BabbagesHall/exhibits/NapiersBones/" }) do
  local f = io.open(d .. "parts/napiers-bones.scad", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "Napier's bones: can't find its folder")
local B = dofile(DIR .. "bones.lua")
local SAYS = dofile(DIR .. "slate/says.lua")
local WAY = os.getenv("NB_WAY") or "napier"
if WAY ~= "genaille" then WAY = "napier" end
local SCAD
do
  local path = DIR .. "parts/napiers-bones.scad"
  if hallPath then path = hallPath(path) end
  if path:sub(1, 1) ~= "/" and not path:match("^%a:[/\\]") then
    local cwd
    local p = io.popen and io.popen("cd")
    if p then cwd = p:read("*l"); p:close() end
    if not cwd or cwd == "" or not (cwd:sub(1, 1) == "/" or cwd:match("^%a:")) then
      p = io.popen and io.popen("pwd")
      if p then cwd = p:read("*l"); p:close() end
    end
    path = (cwd or os.getenv("PWD") or ".") .. "/" .. path
  end
  SCAD = path
end
local function checksum(paths)
  local sum = 0
  for _, path in ipairs(paths) do
    local f = io.open(path, "rb")
    if f then
      local data = f:read("*a"); f:close()
      for i = 1, #data, 7 do sum = (sum * 31 + data:byte(i)) % 2147483647 end
      sum = (sum + #data) % 2147483647
    end
  end
  return sum
end
local SCAD_SUM = checksum({ SCAD })
local function part(call)
  local m = OpenSCAD("// " .. SCAD_SUM .. "\ninclude <" .. SCAD .. ">\nscale(0.1) " .. call .. ";\n", 0, false)
  m.collides = false
  return m
end
local function pic(name)
  local p = DIR .. name .. ".png"
  if hallPath then p = hallPath(p) end
  return p
end

-- the sizes (cm), as in napiers-bones.scad and make-faces.py
local S, RL = 1.6, 17.6                        -- a rod's side and length
local BX0, BX1, BY0, BY1, BT, LH = -2.2, 12.2, -1.0, 18.2, 0.6, 0.8
local TILT = envnum("NB_TILT", 20)
local DRAWN_TILT = 20
local BOX, BOY = -17.8, -6.0
local H0 = (10 - (-10) * math.sin(math.rad(DRAWN_TILT)) + 6 * math.cos(math.rad(DRAWN_TILT))) / 10
local TX0, TP, TW, TF, TD, TL, TY = 2.0, 1.9, 0.2, 0.2, 0.9, 18.2, 1.0
local SLATE_Y = 15.0
local CELL, BOTTOM = 1.6, 1.0                  -- a face: its cells, the margin below them
local TOP_CELL = BOTTOM + 9 * CELL
local E = 9 * CELL / 44                        -- a Genaille entry
local NROD = 10

-- ---------------------------------------------------------------------
-- sliders, timing, the pause at every start
-- ---------------------------------------------------------------------
v:addParam("friction", envnum("NB_FRICTION", 0.4), 0.1, 1, 0.05, "the rods' friction, on the board and on each other (a coefficient)")
v:addParam("hand", envnum("NB_HAND", 12), 3, 30, 1, "how fast the hand carries a rod, cm/s")
v:addParam("speed", 1, 0.05, 3, 0.05, "simulated seconds per real second")
local PUSH = envnum("NB_PUSH", 30)              -- kg cm/s^2: 0.3 N, pressing a rod into place
local HZ = envnum("NB_HZ", 600)
local STEP, NSTEPS, FRAME_DT = 1 / HZ, 10, 1 / 60
local function applyTiming()
  local speed = v:getParam("speed")
  NSTEPS = math.max(1, math.floor(HZ * speed / 60 + 0.5))
  FRAME_DT = speed / 60
  STEP = FRAME_DT / NSTEPS
  v.animationPeriod = 16
  common.setTiming(STEP, 0, STEP)
end
local HOLD_FRAMES = math.floor(envnum("HOLD_S", 0.5) * 60 + 0.5)
local holdArm, holdLeft, holdNow = false, 0, false
local function holdStart() holdArm, holdLeft = true, 0 end
local function holdPre()
  if holdLeft > 0 then holdLeft = holdLeft - 1; holdNow = true; v.timeStep = 0; return true end
  if holdNow then holdNow = false; applyTiming() end
  if holdArm then holdArm, holdLeft = false, HOLD_FRAMES end
  return false
end
applyTiming()
local G = 981
v.gravity = btVector3(0, -G, 0)
pcall(function() v:setSolverIterations(20) end)

-- ---------------------------------------------------------------------
-- where things are. The parts file's table frame (x right, y away from
-- you, z up) is the hall's (x, z, -y); the board's frame (x along the
-- ledge, y up the board, z out of it) is tilted TILT toward you.
-- ---------------------------------------------------------------------
local ident = btQuaternion(0, 0, 0, 1)
local function qa(ax, ay, az, deg) return btQuaternion(btVector3(ax, ay, az), math.rad(deg)) end
-- (a vector turned by a quaternion: bpp binds no product of the two)
local function qrot(q, v3)
  local x, y, z, w = q:getX(), q:getY(), q:getZ(), q:getW()
  local vx, vy, vz = v3.x, v3.y, v3.z
  local tx, ty, tz = 2 * (y * vz - z * vy), 2 * (z * vx - x * vz), 2 * (x * vy - y * vx)
  return btVector3(vx + w * tx + (y * tz - z * ty), vy + w * ty + (z * tx - x * tz), vz + w * tz + (x * ty - y * tx))
end
local function dot(a, b) return a.x * b.x + a.y * b.y + a.z * b.z end
local Q = qa(1, 0, 0, -90)                      -- the table's frame to the hall's
local function TW3(x, y, z) return btVector3(x, z, -y) end
local cT, sT = math.cos(math.rad(TILT)), math.sin(math.rad(TILT))
local BQ = Q * qa(1, 0, 0, TILT)                -- the board's frame to the hall's
local BORIGIN
do -- (if NB_TILT differs from the drawing, the board turns about its ledge's bottom edge)
  local cD, sD = math.cos(math.rad(DRAWN_TILT)), math.sin(math.rad(DRAWN_TILT))
  local ey, ez = BY0 * cD - (-BT) * sD, BY0 * sD + (-BT) * cD          -- (that edge, drawn)
  local ty, tz = BOY + ey - (BY0 * cT - (-BT) * sT), H0 + ez - (BY0 * sT + (-BT) * cT)
  BORIGIN = TW3(BOX, ty, tz)
end
local EX, EY, EZ = qrot(BQ, btVector3(1, 0, 0)), qrot(BQ, btVector3(0, 1, 0)), qrot(BQ, btVector3(0, 0, 1))
local function BW(x, y, z) return BORIGIN + EX * x + EY * y + EZ * z end
-- (a point of the hall in the board's frame)
local function toBoard(p) local d = p - BORIGIN; return dot(d, EX), dot(d, EY), dot(d, EZ) end
local SZ = -SLATE_Y
local function slotX(k) return TX0 + TW + (k - 0.5) * TP end

local TABLE
do
  local path, f = DIR .. "../../exhibit-table.lua"
  if setfenv then f = assert(loadfile(path)); setfenv(f, getfenv(1))
  else f = assert(loadfile(path, "t", _ENV)) end
  TABLE = f()
end
TABLE.build(44, 26, { z = -4, floor = 300 })

local function still(call, col, tr)
  local m = part(call)
  m.col = col
  v:add(m)
  m.trans = tr or btTransform(Q, btVector3(0, 0, 0))
  return m
end
local boardTr = btTransform(BQ, BORIGIN)
local boardObj = still("board()", "#8a5a32", boardTr)
local feet = {}
for k, x in ipairs({ 8, 96 }) do feet[k] = still(string.format("foot(%d)", x), "#6b4423") end
if TILT ~= DRAWN_TILT then for _, f in ipairs(feet) do v:remove(f) end; feet = {} end   -- (drawn for 20 degrees)
local trayObj = still("tray()", "#8a5a32")
local slateTr = btTransform(Q, btVector3(0, 0, SZ))
local slateObj = still("slate()", "#22282a", slateTr)
local slateFrame = still("slateFrame()", "#6b4423", slateTr)
local indexObj = still("rod()", "#efe6cc", btTransform(BQ, BW(-S / 2, RL / 2, S / 2)))
local function faceTile()
  local c = Cube(S - 0.04, RL - 0.04, 0.01, 0)
  c.collides = false
  v:add(c)
  return c
end
local indexTile = faceTile()
indexTile.tex = pic("faces/" .. WAY .. "-index")
indexTile.trans = btTransform(BQ, BW(-S / 2, RL / 2, S + 0.006))

-- the solids: the board (plate, ledge, rim, the index rod) and the tray,
-- each one static body of boxes (drawn by the parts above)
local MARGIN = 0.02
local function solid(tr, boxes)
  local c = btCompoundShape(true)
  for _, bx in ipairs(boxes) do
    local x0, x1, y0, y1, z0, z1 = bx[1], bx[2], bx[3], bx[4], bx[5], bx[6]
    local sh = btBoxShape(btVector3((x1 - x0) / 2, (y1 - y0) / 2, (z1 - z0) / 2))
    sh:setMargin(MARGIN)
    c:addChildShape(btTransform(ident, btVector3((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)), sh)
  end
  local o = Cube(1, 1, 1, 0)
  o.body = btRigidBody(0, btDefaultMotionState(tr), c, btVector3(0, 0, 0))
  o.collides = true
  v:add(o)
  o.trans = tr
  pcall(function() o.transparency = 1 end)
  return o
end
local boardSolid = solid(boardTr, {
  { BX0, BX1, BY0, BY1, -BT, 0 },               -- the plate
  { BX0, BX1, BY0, 0, 0, LH },                  -- the ledge
  { BX0, -S, 0, BY1, 0, LH },                   -- the rim
  { -S, 0, 0, RL, 0, S },                       -- the index rod
})
local trayBoxes = { { TX0, TX0 + 2 * TW + NROD * TP, TY - TL / 2 - TW, TY + TL / 2 + TW, 0, TF } }
for k = 0, NROD do                              -- (the dividers and the side walls)
  local x = TX0 + TW + k * TP
  local x0, x1 = x - 0.08, x + 0.08
  if k == 0 then x0 = TX0 end
  if k == NROD then x1 = TX0 + 2 * TW + NROD * TP end
  trayBoxes[#trayBoxes + 1] = { x0, x1, TY - TL / 2 - TW, TY + TL / 2 + TW, TF, TF + TD }
end
trayBoxes[#trayBoxes + 1] = { TX0, TX0 + 2 * TW + NROD * TP, TY - TL / 2 - TW, TY - TL / 2, TF, TF + TD }
trayBoxes[#trayBoxes + 1] = { TX0, TX0 + 2 * TW + NROD * TP, TY + TL / 2, TY + TL / 2 + TW, TF, TF + TD }
local traySolid = solid(btTransform(Q, btVector3(0, 0, 0)), trayBoxes)

-- ---------------------------------------------------------------------
-- the rods: bodies, each with its four faces drawn on it
-- ---------------------------------------------------------------------
-- a face f's turn about the rod's long axis (y): face 1 is +z, face 2 +x,
-- face 3 -z, face 4 -x (as the paper strip wraps it)
local FACEQ = {}
for f = 1, 4 do FACEQ[f] = qa(0, 1, 0, (f - 1) * 90) end
local UP = {}                                   -- (the turn that puts face f up)
for f = 1, 4 do UP[f] = qa(0, 1, 0, -(f - 1) * 90) end
local ROD_MASS = 0.035                          -- kg: 45 cm^3 printed at about 60% (PLA)
local SLEEP_V = envnum("NB_SLEEP", 0.05)        -- cm/s and rad/s (0: no sleeping)
local rods = {}
local function applyFriction()
  local mu = v:getParam("friction")
  for _, r in ipairs(rods) do r.body:setFriction(mu) end
  pcall(function() boardSolid.body:setFriction(mu); traySolid.body:setFriction(mu) end)
end
local restPose = {}
for k = 1, NROD do
  restPose[k] = { pos = TW3(slotX(k), TY, TF + S / 2 + 0.005), q = Q }
  local obj = part("rod()")
  obj.col = "#efe6cc"
  local tr = btTransform(Q, restPose[k].pos)
  local shape = btBoxShape(btVector3(S / 2, RL / 2, S / 2))
  shape:setMargin(MARGIN)
  local m = ROD_MASS
  local inertia = btVector3(m * (RL * RL + S * S) / 12, m * (S * S + S * S) / 12, m * (RL * RL + S * S) / 12)
  local b = btRigidBody(m, btDefaultMotionState(tr), shape, inertia)
  obj.body = b
  obj.collides = true
  v:add(obj)
  obj.trans = tr
  b:setCenterOfMassTransform(tr)
  -- (a rod still for 2 s, under 0.05 cm/s, sleeps: Bullet's way with
  -- resting bodies, and here the end of a slow creep, FINDINGS.md; held or
  -- pressed it is kept awake, and a moving rod touching it wakes it)
  -- (bpp adds every body unable to sleep; forceActivationState undoes that,
  -- setActivationState can't)
  b:setSleepingThresholds(SLEEP_V, SLEEP_V)
  b:forceActivationState(SLEEP_V > 0 and 1 or 4)
  b:setRestitution(0)
  pcall(function() b:setDamping(0.05, 0.1) end)
  local r = { k = k, obj = obj, body = b, faces = B.RODS[k], tiles = {}, where = "tray" }
  for f = 1, 4 do
    local t = faceTile()
    t.tex = pic("faces/" .. WAY .. "-" .. B.RODS[k][f])
    r.tiles[f] = t
  end
  rods[k] = r
end
applyFriction()
local OFF = btVector3(0, 0, S / 2 + 0.006)
local function follow()
  for _, r in ipairs(rods) do
    local tr = r.body:getCenterOfMassTransform()
    local q, p = r.body:getOrientation(), r.body:getCenterOfMassPosition()
    for f = 1, 4 do
      local tq = q * FACEQ[f]
      r.tiles[f].trans = btTransform(tq, p + qrot(tq, OFF))
    end
  end
end
follow()

-- where a rod lies on the board: its middle in the board's frame, its
-- bottom end, which face is up and how far it is turned from square
local function onBoard(r)
  local p, q = r.body:getCenterOfMassPosition(), r.body:getOrientation()
  local x, y, z = toBoard(p)
  local best, bd = 1, -2
  for f = 1, 4 do
    local d = dot(qrot(q * FACEQ[f], btVector3(0, 0, 1)), EZ)
    if d > bd then best, bd = f, d end
  end
  local along = dot(qrot(q, btVector3(0, 1, 0)), EY)
  return { x = x, y = y, z = z, bottom = y - RL / 2, face = best,
           roll = math.deg(math.acos(math.min(1, bd))), skew = math.deg(math.acos(math.min(1, math.abs(along)))),
           on = z > 0 and z < S and y > 0 and y < BY1 and x > -0.5 and x < BX1 }
end

-- ---------------------------------------------------------------------
-- the slate: pictures swapped in (make-slate.py made them)
-- ---------------------------------------------------------------------
local HIDE = btVector3(0, 30, SZ - 3)
local function tile(w, h, x, y, name)
  local c = Cube(w, h, 0.01, 0)
  c.collides = false
  c.tex = pic("slate/" .. name)
  v:add(c)
  c.trans = btTransform(ident, btVector3(x, y, SZ + 0.004))
  return c
end
local shown = {}
local function show(t, name) if shown[t] ~= name then shown[t] = name; t.tex = pic("slate/" .. name) end end
local GLYPH = { x = "times", ["+"] = "plus", ["="] = "eq", ["/"] = "slash", [" "] = "blank", ["."] = "point" }
local NARROW = { ["/"] = true, [" "] = true, ["."] = true }
local GW, GN, GH = 0.85, 0.45, 1.3
local function glyphRow(n, x0, y)
  local row = { x0 = x0, y = y, wide = {}, narrow = {} }
  for k = 1, n do
    row.wide[k] = tile(GW, GH, 0, 0, "g-blank")
    row.narrow[k] = tile(GN, GH, 0, 0, "g-blank")
    row.wide[k].trans = btTransform(ident, HIDE)
    row.narrow[k].trans = btTransform(ident, HIDE)
  end
  return row
end
local function showGlyphs(row, text)
  text = text or ""
  local x = row.x0
  for k = 1, #row.wide do
    local ch = text:sub(k, k)
    local w, n = row.wide[k], row.narrow[k]
    if ch == "" then
      w.trans = btTransform(ident, HIDE); n.trans = btTransform(ident, HIDE)
    else
      local use, other, width = w, n, GW
      if NARROW[ch] then use, other, width = n, w, GN end
      show(use, "g-" .. (GLYPH[ch] or ch))
      use.trans = btTransform(ident, btVector3(x + width / 2, row.y, SZ + 0.004))
      other.trans = btTransform(ident, HIDE)
      x = x + width + 0.03
    end
  end
end
-- (the board: 34 cm across, from 9 to 24 cm up)
local slate = {}
slate.op = tile(7.4, 1.3, -12.6, 22.8, "label-" .. WAY)
slate.problem = glyphRow(16, -8.4, 22.8)
slate.say = tile(32, 3.2, 0, 20.0, "say-ready-" .. WAY)
slate.rowL = tile(7.4, 1.3, -12.6, 16.8, "label-none")
slate.row = glyphRow(24, -8.4, 16.8)
slate.diagL = tile(7.4, 1.3, -12.6, 14.7, "label-none")
slate.diag = glyphRow(22, -8.4, 14.7)
slate.givesL = tile(7.4, 1.3, -12.6, 12.6, "label-none")
slate.gives = glyphRow(14, -8.4, 12.6)
slate.totalL = tile(7.4, 1.3, -12.6, 10.5, "label-none")
slate.total = glyphRow(14, -8.4, 10.5)
local function clearRows(keepTotal)
  for _, k in ipairs({ "row", "diag", "gives" }) do showGlyphs(slate[k], ""); show(slate[k .. "L"], "label-none") end
  if not keepTotal then showGlyphs(slate.total, ""); show(slate.totalL, "label-none") end
end

-- the reading strip (the script's): a red band across the row being read;
-- and dots on the numbers a Genaille path passes
local strip = Cube(BX1 + S, CELL * 0.92, 0.01, 0)
strip.collides = false
strip.col = "#d02a20"
pcall(function() strip.transparency = 0.7 end)
v:add(strip)
local function hideStrip() strip.trans = btTransform(ident, HIDE) end
hideStrip()
local dots = {}
for k = 1, 8 do
  local d = Cube(0.32, 0.3, 0.01, 0)
  d.collides = false
  d.col = "#d02a20"
  pcall(function() d.transparency = 0.45 end)
  v:add(d)
  d.trans = btTransform(ident, HIDE)
  dots[k] = d
end
local function hideDots() for _, d in ipairs(dots) do d.trans = btTransform(ident, HIDE) end end

-- ---------------------------------------------------------------------
-- the hand: a thumb and a finger (drawn, the script's). It holds a rod by
-- steering it (velocity toward where it should be, its weight held), then
-- lets it go and presses it into place
-- ---------------------------------------------------------------------
local FQ = Q * qa(1, 0, 0, 30)                  -- (pointing down, the hand up and toward you)
local fingers = {}
for k = 1, 2 do
  local f = part("finger()")
  f.col = "#e0b896"
  v:add(f)
  fingers[k] = f
end
local REST = { TW3(24, -6, 8), TW3(26, -6, 9) }
local fingerAt = { REST[1], REST[2] }
local function placeFingers(a, b)
  fingerAt[1], fingerAt[2] = a, b
  fingers[1].trans = btTransform(FQ, a)
  fingers[2].trans = btTransform(FQ, b)
end
placeFingers(REST[1], REST[2])
-- (where thumb and finger hold a rod: at its sides, half way along)
local function gripPoints(r, apart)
  local q, p = r.body:getOrientation(), r.body:getCenterOfMassPosition()
  local side = qrot(q * FACEQ[r.faceUp or 1], btVector3(1, 0, 0))
  local d = S / 2 + 0.7 + (apart or 0)
  return p - side * d, p + side * d
end
local function lerp(a, b, t) return a + (b - a) * t end
local function ease(t) return t * t * (3 - 2 * t) end
local function vlerp(a, b, t) return btVector3(lerp(a.x, b.x, t), lerp(a.y, b.y, t), lerp(a.z, b.z, t)) end

local held = nil            -- { r, target = btVector3, q = btQuaternion }
local pressing = nil        -- { r, force }
local GAIN, GAIN_R, WMAX = 8, 8, 4
local function steer()
  if held then
    local b = held.r.body
    local p = b:getCenterOfMassPosition()
    local e = held.target - p
    local vmax = v:getParam("hand")
    local vel = e * GAIN
    local len = vel:length()
    if len > vmax then vel = vel * (vmax / len) end
    b:setLinearVelocity(vel)
    local q = b:getOrientation()
    local dq = held.q * q:inverse()
    if dq:getW() < 0 then dq = dq * -1 end
    local ang = dq:getAngle()
    if ang > 1e-5 then b:setAngularVelocity(dq:getAxis() * math.min(WMAX, ang * GAIN_R))
    else b:setAngularVelocity(btVector3(0, 0, 0)) end
  end
  if pressing then pressing.r.body:applyCentralForce(pressing.force) end
end
local function take(r)
  r.body:forceActivationState(4)
  held = { r = r, target = r.body:getCenterOfMassPosition(), q = r.body:getOrientation() }
  r.body:setGravity(btVector3(0, 0, 0))
end
local function letGo()
  if not held then return end
  held.r.body:setGravity(btVector3(0, -G, 0))
  held = nil
end

-- the jobs, one at a time: { say } { wait } { call } { lay = rod, place, face } { back = rod }
local queue, job = {}, nil
local LOG = os.getenv("NB_LOG")
local function push(q) queue[#queue + 1] = q end
-- (from inside a job: these next, before what was already queued)
local function soon(list) for i = #list, 1, -1 do table.insert(queue, 1, list[i]) end end
local function startJob()
  local q = table.remove(queue, 1)
  if not q then job = nil; return end
  if q.say then
    show(slate.say, "say-" .. q.say)
    local w = SAYS[q.say]
    if w then print(string.format("  %s   (%s)", w[1], w[2])) end
    job = { wait = q.waitS or 1.0 }
  elseif q.wait then job = { wait = q.wait }
  elseif q.call then job = nil; q.call(); if not job then job = { wait = 0 } end
  elseif q.lay then
    local r = q.lay
    job = { kind = "lay", r = r, place = q.place, face = q.face, phase = "reach", t = 0, from = { fingerAt[1], fingerAt[2] } }
    if LOG then print(string.format("  rod %d, face %d (%d) to place %d", r.k, q.face, r.faces[q.face], q.place)) end
  elseif q.back then
    job = { kind = "back", r = q.back, phase = "reach", t = 0, from = { fingerAt[1], fingerAt[2] } }
  elseif q.home then
    job = { kind = "home", phase = "home", t = 0, from = { fingerAt[1], fingerAt[2] } }
  end
end
-- (a held rod near where it is steered to?)
local function arrived(tolP, tolA)
  local b = held.r.body
  local e = (held.target - b:getCenterOfMassPosition()):length()
  local dq = held.q * b:getOrientation():inverse()
  if dq:getW() < 0 then dq = dq * -1 end
  return e < tolP and math.deg(dq:getAngle()) < tolA
end
local HIGH = 13                                 -- cm above the table: carrying height
local function stepJob(dt)
  local j = job
  if not j then startJob(); return end
  if j.wait then
    j.wait = j.wait - dt
    if j.wait <= 0 then job = nil; startJob() end
    return
  end
  j.t = j.t + dt
  local r = j.r
  if j.phase == "home" then
    local u = math.min(1, j.t / 0.6)
    placeFingers(vlerp(j.from[1], REST[1], ease(u)), vlerp(j.from[2], REST[2], ease(u)))
    if u >= 1 then job = nil; startJob() end
    return
  end
  if j.phase == "reach" then                    -- (the hand to the rod, open)
    local a, b = gripPoints(r, 0.8)
    local u = math.min(1, j.t / 0.6)
    placeFingers(vlerp(j.from[1], a + btVector3(0, 3 * (1 - u), 0), ease(u)), vlerp(j.from[2], b + btVector3(0, 3 * (1 - u), 0), ease(u)))
    if u >= 1 then
      take(r)
      local p = r.body:getCenterOfMassPosition()
      held.target = p + (j.kind == "lay" and btVector3(0, 4, 0) or EZ * 3)
      j.phase, j.t = "lift", 0
    end
    return
  end
  -- (held: the fingers on its sides)
  if held then local a, b = gripPoints(r); placeFingers(a, b) end
  if j.phase == "lift" then
    if arrived(0.1, 3) or j.t > 3 then
      local dest, q
      if j.kind == "lay" then
        r.faceUp = j.face
        q = BQ * UP[j.face]
        dest = BW((j.place - 0.5) * S + 0.25, RL / 2 + 0.12, S / 2 + 3.5)
      else
        r.faceUp = 1
        q = Q
        dest = restPose[r.k].pos + btVector3(0, 3.5, 0)
      end
      local p = r.body:getCenterOfMassPosition()
      j.dest, j.q = dest, q
      held.target = btVector3((p.x + dest.x) / 2, math.max(HIGH, p.y, dest.y), (p.z + dest.z) / 2)
      held.q = q
      j.phase, j.t = "over", 0
    end
  elseif j.phase == "over" then                 -- (up and over, turned on the way)
    if arrived(1.0, 20) or j.t > 6 then held.target = j.dest; j.phase, j.t = "above", 0 end
  elseif j.phase == "above" then
    if arrived(0.05, 1.5) or j.t > 6 then
      if j.kind == "lay" then held.target = BW((j.place - 0.5) * S + 0.25, RL / 2 + 0.12, S / 2 + 0.04)
      else held.target = restPose[r.k].pos + btVector3(0, 0.05, 0) end
      j.phase, j.t = "down", 0
    end
  elseif j.phase == "down" then                 -- (set down, just clear of its neighbour)
    local slow = held.r.body:getLinearVelocity():length() < 0.05
    if arrived(0.03, 1) or (j.t > 0.5 and slow) or j.t > 5 then
      letGo()
      if j.kind == "lay" then
        -- (then pressed left, against its neighbour, and down onto the ledge)
        pressing = { r = r, force = EX * (-PUSH) + EY * (-0.6 * PUSH) }
        j.phase, j.t, j.still = "press", 0, 0
      else
        j.phase, j.t = "release", 0
      end
    end
  elseif j.phase == "press" then
    local _, b = gripPoints(r)
    local up = r.body:getCenterOfMassPosition() + EZ * 3
    placeFingers(vlerp(fingerAt[1], up, 0.2), b)
    local sp = r.body:getLinearVelocity():length() + r.body:getAngularVelocity():length() * RL / 2
    if r.body:getLinearVelocity():length() < 0.03 and r.body:getAngularVelocity():length() < 0.02 then j.still = j.still + dt else j.still = 0 end
    if (j.t > 0.4 and j.still > 0.25) or j.t > 5 then
      if LOG then
        local w = onBoard(r)
        print(string.format("    pressed %.2f s: its middle at x %.3f (its place %.3f), off the ledge %.3f mm, face %d", j.t, w.x, (j.place - 0.5) * S, 10 * w.bottom, w.face))
      end
      pressing = nil
      if SLEEP_V > 0 then r.body:forceActivationState(1) end
      r.where = "board"
      j.phase, j.t = "settle", 0
    end
  elseif j.phase == "settle" and os.getenv("NB_CREEP") and j.t < 10 then
    -- (an experiment: the rod left alone after its press, watched for 10 s)
    j.next = j.next or 0
    if j.t >= j.next then
      local w = onBoard(r)
      print(string.format("    creep t %.1f s: x %.4f cm, bottom %.4f mm, v %.4f cm/s", j.t, w.x, 10 * w.bottom, r.body:getLinearVelocity():length()))
      j.next = j.next + 1
    end
  elseif j.phase == "release" or j.phase == "settle" then
    local u = math.min(1, j.t / 0.3)
    placeFingers(fingerAt[1] + btVector3(0, 0.06, 0), fingerAt[2] + btVector3(0, 0.06, 0))
    if u >= 1 then
      if j.kind == "back" then r.where = "tray"; if SLEEP_V > 0 then r.body:forceActivationState(1) end end
      job = nil; startJob()
    end
  end
end
local function idle() return job == nil and #queue == 0 end

-- ---------------------------------------------------------------------
-- reading the rods, from where they lie
-- ---------------------------------------------------------------------
-- (the rods on the board, left to right, each as it lies)
local function laid()
  local out = {}
  for _, r in ipairs(rods) do
    local w = onBoard(r)
    if w.on then w.r = r; w.digit = r.faces[w.face]; out[#out + 1] = w end
  end
  table.sort(out, function(a, b) return a.x < b.x end)
  return out
end
-- the index's row m: its middle, up the board (the index rod on the ledge)
local function napierRowY(m) return BOTTOM + (9 - m) * CELL + CELL / 2 end
local function genailleRow(m)                  -- (its bottom and top on a face, up from the rod's bottom)
  local top = TOP_CELL
  for k = 2, m - 1 do top = top - k * E end
  return top - m * E, top
end
-- which Napier cell of a rod is level with the index's row m (or nil)
local function napierCell(w, m)
  local ly = napierRowY(m) - w.bottom
  local k = 9 - math.floor((ly - BOTTOM) / CELL)
  if k < 1 or k > 9 then return nil end
  return k
end
-- a row read the Napier way: each rod's cell beside the index's m; along
-- the diagonals; the row's product. Returns the product (or nil) and what
-- the slate shows
local function readNapier(ws, m)
  local cells, txt = {}, {}
  for i, w in ipairs(ws) do
    local k = napierCell(w, m)
    if not k then return nil, "a rod is a row out" end
    cells[i] = B.cell(w.digit, k)
    txt[i] = cells[i][1] .. "/" .. cells[i][2]
  end
  local sums, _, p = B.diagonals(cells)
  local st = {}
  for i, s in ipairs(sums) do st[i] = tostring(s) end
  return p, table.concat(txt, " "), table.concat(st, " ")
end
-- a row read the Genaille way: the rightmost rod's top number in row m,
-- then each triangle to the number level with its tip on the next rod
-- left, and at last the index rod's carry. All from where the rods lie.
local function readGenaille(ws, m)
  local n = #ws
  if m == 1 then
    local s = ""
    for _, w in ipairs(ws) do s = s .. w.digit end
    return s, "", {}
  end
  -- (the row on the last rod, level with the index's row m)
  local i0, i1 = genailleRow(m)
  local midY = (i0 + i1) / 2                    -- (board y: the index rod's bottom is at 0)
  local digits, path = {}, {}
  local entryY                                  -- (board y of the entry being read)
  local w = ws[n]
  local function rowAt(wr, y)                   -- (which row of a rod is at board y, and its top there)
    local ly = y - wr.bottom
    for r = 2, 9 do
      local a, b = genailleRow(r)
      if ly >= a and ly < b then return r, wr.bottom + b end
    end
  end
  local r, top = rowAt(w, midY)
  if not r then return nil end
  entryY = top - 0.5 * E                        -- (its top entry: carry 0)
  for i = n, 1, -1 do
    w = ws[i]
    r, top = rowAt(w, entryY)
    if not r then return nil end
    local c = math.floor((top - entryY) / E)
    local e = B.entries(w.digit, r)[c + 1]
    if not e then return nil end
    digits[#digits + 1] = e.units
    path[#path + 1] = { x = w.x, y = top - (c + 0.5) * E }
    -- (the triangle's tip: level with the entry its tens select, one rod left)
    entryY = top - (e.tens + 0.5) * E
  end
  -- (the index rod: its row there, the carry read off)
  local ir, itop = rowAt({ bottom = 0 }, entryY)
  if not ir then return nil end
  local c = math.floor((itop - entryY) / E)
  path[#path + 1] = { x = -S / 2, y = itop - (c + 0.5) * E }
  local s = (c > 0 and tostring(c) or "")
  for k = #digits, 1, -1 do s = s .. digits[k] end
  s = s:gsub("^0+(%d)", "%1")
  local shown = {}
  for k = #digits, 1, -1 do shown[#shown + 1] = tostring(digits[k]) end
  if c > 0 then table.insert(shown, 1, tostring(c)) end
  return s, table.concat(shown, " "), path
end

-- ---------------------------------------------------------------------
-- a problem: lay the rods, read a row for each of the multiplier's digits
-- (adding them up), check, clear the board
-- ---------------------------------------------------------------------
local fails, worked = 0, 0
local onBoardNow = {}       -- (the rods laid, in their places)
local function layNumber(s)
  local ch = B.choose(B.digits(s))
  if not ch then return false end
  push({ say = "lay", waitS = 0.6 })
  for i, c in ipairs(ch) do
    push({ lay = rods[c.rod], place = i, face = c.face })
    onBoardNow[i] = rods[c.rod]
  end
  push({ home = true })                         -- (the hand out of the way of the reading)
  push({ wait = 0.2 })
  return true
end
local function clearBoard()
  if #onBoardNow == 0 then
    -- (anything else lying off its slot goes back too)
    for _, r in ipairs(rods) do if r.where ~= "tray" then onBoardNow[#onBoardNow + 1] = r end end
  end
  if #onBoardNow == 0 then return end
  push({ say = "clear", waitS = 0.4 })
  for i = #onBoardNow, 1, -1 do push({ back = onBoardNow[i] }) end
  onBoardNow = {}
end
local function showStrip(m)
  strip.trans = btTransform(BQ, BW((BX1 - S) / 2 - 0.6, napierRowY(m), S + 0.03))
end
local function stripGenaille(m)
  local a, b = genailleRow(m)
  strip.trans = btTransform(BQ, BW((BX1 - S) / 2 - 0.6, (a + b) / 2, S + 0.03))
end
local function work(s, mul)
  local mds = B.digits(mul)
  push({ call = function()
    show(slate.op, "label-" .. WAY)
    showGlyphs(slate.problem, s .. "x" .. mul)
    clearRows(); hideStrip(); hideDots()
    print(string.format("%s x %s", s, mul))
  end })
  if not layNumber(s) then
    push({ say = "cannot", waitS = 2 })
    return
  end
  local total = "0"
  local n = #mds
  local rowsShown = 0
  for k = 1, n do
    local m = mds[k]
    if m > 0 then
      rowsShown = rowsShown + 1
      if rowsShown > 1 then push({ say = "next", waitS = 0.6 }) end
      push({ call = function()
        clearRows(true)
        if WAY == "napier" then showStrip(m) else if m > 1 then stripGenaille(m) else hideStrip() end end
      end })
      if WAY == "napier" then
        push({ say = "row", waitS = 0.9 })
        push({ call = function()
          local ws = laid()
          if LOG then
            local t = {}
            for _, w in ipairs(ws) do t[#t + 1] = string.format("%.3f", w.x) end
            print("    the rods' middles: " .. table.concat(t, " "))
          end
          local p, cells, sums = readNapier(ws, m)
          show(slate.rowL, "label-row" .. m)
          showGlyphs(slate.row, cells or "")
          job = { wait = 0.9 }
          soon({ { say = "diag", waitS = 0.9 }, { call = function()
            show(slate.diagL, "label-diagonals"); showGlyphs(slate.diag, sums or "")
            show(slate.givesL, "label-gives"); showGlyphs(slate.gives, (p or "?") .. string.rep("0", n - k))
            total = B.add(total, (p or "0") .. string.rep("0", n - k))
            print(string.format("  row %d: %s; along the diagonals %s; so %s", m, cells or "?", sums or "?", (p or "?") .. string.rep("0", n - k)))
          end }, { wait = 1.6 } })
        end })
      else
        push({ say = m == 1 and "gone" or "grow", waitS = 0.9 })
        push({ call = function()
          local ws = laid()
          local p, shownTxt, path = readGenaille(ws, m)
          hideDots()
          for i, pt in ipairs(path or {}) do
            if dots[i] then dots[i].trans = btTransform(BQ, BW(pt.x + S * 0.31, pt.y, S + 0.04)) end
          end
          local nxt = {}
          if m > 1 then nxt[#nxt + 1] = { say = "gfollow", waitS = 1.0 } end
          nxt[#nxt + 1] = { call = function()
            show(slate.rowL, "label-row" .. m)
            show(slate.diagL, m > 1 and "label-triangles" or "label-none")
            showGlyphs(slate.diag, m > 1 and (shownTxt or "?") or "")
            show(slate.givesL, "label-gives"); showGlyphs(slate.gives, (p or "?") .. string.rep("0", n - k))
            total = B.add(total, (p or "0") .. string.rep("0", n - k))
            print(string.format("  row %d: the triangles lead to %s; so %s", m, shownTxt or "?", (p or "?") .. string.rep("0", n - k)))
          end }
          nxt[#nxt + 1] = { wait = 1.6 }
          soon(nxt)
        end })
      end
    end
  end
  push({ call = function()
    local want = B.times(s, mul)
    local nxt = {}
    if rowsShown > 1 then nxt[#nxt + 1] = { say = "add", waitS = 0.8 } end
    nxt[#nxt + 1] = { call = function()
      show(slate.totalL, "label-total")
      showGlyphs(slate.total, total)
      worked = worked + 1
      local ok = total == want
      if not ok then fails = fails + 1 end
      show(slate.say, ok and "say-right" or "say-wrong")
      -- (how the rods lie: the worst of them)
      local gap, skew, roll, off = 0, 0, 0, 0
      local ws = laid()
      for i, w in ipairs(ws) do
        if LOG then print(string.format("    rod %d at x %.3f, bottom %.3f mm, face %d", w.r.k, w.x, 10 * w.bottom, w.face)) end
        local left = i == 1 and 0 or (ws[i - 1].x + S / 2)
        gap = math.max(gap, w.x - S / 2 - left)
        skew, roll = math.max(skew, w.skew), math.max(roll, w.roll)
        off = math.max(off, math.abs(w.bottom))
      end
      print(string.format("  = %s   (true: %s%s; the rods: largest gap %.2f mm, off the ledge %.2f mm, skew %.2f, roll %.2f degrees)",
        total, want, ok and "" or "  -- WRONG", 10 * gap, 10 * off, skew, roll))
    end }
    nxt[#nxt + 1] = { wait = 2.2 }
    soon(nxt)
  end })
  push({ call = function() hideStrip(); hideDots() end })
  clearBoard()
end

-- the tours
local TOURS = {
  napier = { { "425", "6" }, { "6785", "8" }, { "2222", "9" }, { "4138", "567" } },
  genaille = { { "52749", "4" }, { "874", "7" }, { "874", "73" } },
}
local TOUR_SAYS = {
  napier = "425 x 6 (no carries), 6785 x 8 (carries), 2222 x 9 (four rods with a 2), 4138 x 567 (three rows added)",
  genaille = "52749 x 4, 874 x 7, and 874 x 73 (two rows added)",
}
local TOUR = TOURS[WAY]
local RANDOM_N = envnum("NB_RANDOM", 0)
if RANDOM_N > 0 then
  math.randomseed(envnum("NB_SEED", 1))
  TOUR = {}
  for k = 1, RANDOM_N do
    local s = tostring(math.random(1, 9))
    for i = 2, math.random(2, 5) do s = s .. math.random(0, 9) end
    TOUR[k] = { s, tostring(math.random(2, k % 3 == 0 and 99 or 9)) }
  end
end
local touring = nil
local function tourStart()
  touring, fails, worked = 1, 0, 0
  print("\nNAPIER'S BONES -- the tour: " .. (RANDOM_N > 0 and (RANDOM_N .. " random problems") or TOUR_SAYS[WAY]))
end
local frame = 0
local function tourNext()
  if not touring or not idle() then return end
  if touring > #TOUR then
    touring = nil
    print(string.format("RESULT napier %stour: %s  (%d products, %d wrong; frame %d)", WAY == "napier" and "" or "genaille ",
          (fails == 0 and worked > 0) and "PASS" or "FAIL", worked, fails, frame))
    push({ home = true })
    return
  end
  local t = TOUR[touring]
  touring = touring + 1
  work(t[1], t[2])
end

-- ---------------------------------------------------------------------
-- stepping, and resting when nothing moves
-- ---------------------------------------------------------------------
local REST_S, REST_V = 0.6, 0.02
local REST_ON = os.getenv("NB_REST") ~= "0"
local restFor, resting = 0, false
local function moving()
  for _, r in ipairs(rods) do
    if r.body:getLinearVelocity():length() > REST_V or r.body:getAngularVelocity():length() > REST_V then return true end
  end
  return false
end
local function restPre()
  if not resting then return false end
  if not idle() or touring then resting, restFor = false, 0; applyTiming(); return false end
  v.timeStep = 0
  return true
end
local function restPost()
  if resting then return end
  if not idle() or touring or moving() then restFor = 0; return end
  restFor = restFor + FRAME_DT
  if REST_ON and restFor >= REST_S then resting = true; v.timeStep = 0 end
end

-- the camera close to the board (M): 34 cm off, a narrower view (in the
-- hall bpp clips nearer than about 21 cm); put back on M again, or on leaving
local MAG_D, MAG_FOV, FOV = 34, 0.62, math.pi / 4
local magnify, camBack = nil, nil
local function magnifyView()
  local look = BW(4.4, RL / 2, S)
  local cam = v.cam
  cam:setUpVector(btVector3(0, 1, 0), true)
  cam.pos = look + EZ * MAG_D
  cam.look = look
end
local function magnifyOff(putBack)
  if not magnify then return end
  magnify = nil
  local cam = v.cam
  pcall(function() cam:setFieldOfView(FOV) end)
  cam:setUpVector(btVector3(0, 1, 0), true)
  if putBack and camBack then cam.pos = camBack.pos; cam.look = camBack.look end
  camBack = nil
end

v:preSim(function(N)
  if holdPre() then return end
  if restPre() then return end
  steer()
  for k = 1, NSTEPS - 1 do v:stepSimulation(STEP, 0, STEP); steer() end
end)
local started = false
v:postSim(function(N)
  frame = frame + 1
  follow()
  if holdNow then return end
  if not started then
    started = true
    if (os.getenv("NB_TOUR") or "1") ~= "0" then tourStart() end
  end
  stepJob(FRAME_DT)
  tourNext()
  restPost()
end)

-- ---------------------------------------------------------------------
-- keys, help, hover
-- ---------------------------------------------------------------------
local entry = ""
local function showEntry() showGlyphs(slate.problem, entry) end
local function typed(ch)
  touring = nil
  if #entry < 12 then entry = entry .. ch end
  showEntry()
  show(slate.say, "say-ready-" .. WAY)
end
for d = 0, 9 do v:addShortcut(tostring(d), function() typed(tostring(d)) end) end
v:addShortcut("Backspace", function() entry = entry:sub(1, -2); showEntry() end)
local function times() if entry:match("^%d+$") then typed("x") end end
v:addShortcut("X", times)
v:addShortcut("*", times)
local function enter()
  touring = nil
  local a, b = entry:match("^(%d+)x(%d+)$")
  entry = ""
  a = a and a:gsub("^0+(%d)", "%1")
  if a and b and #a <= 6 and #b <= 3 and tonumber(b) > 0 then
    if not idle() then print("  (the hand is busy: wait for it, then Return)"); return end
    clearBoard()
    work(a, b)
  else print("  (type a number of up to 6 figures, X, a multiplier of up to 3, then Return)"); showEntry() end
end
v:addShortcut("Return", enter)
v:addShortcut("Enter", enter)
v:addShortcut("C", function()
  touring = nil
  entry = ""
  if idle() then clearBoard(); push({ call = function() clearRows(); hideStrip(); hideDots() end }); push({ home = true }) end
end)
v:addShortcut("T", function()
  if idle() then clearBoard(); tourStart() end
end)
v:addShortcut("M", function()
  if magnify then magnifyOff(true)
  else
    local cam = v.cam
    camBack = { pos = cam.pos, look = cam.look }
    magnify = true
    pcall(function() cam:setFieldOfView(MAG_FOV) end)
    magnifyView()
  end
end)
pcall(function() v:onLeave(function() magnifyOff(false) end) end)
v:onParamChanged(function(N, name, value)
  if name == "speed" then applyTiming()
  elseif name == "friction" then applyFriction() end
end)
local HELP = {
  napier = {
    "NAPIER'S BONES  (Babbage's Hall)",
    "",
    "KEYS",
    "  0 - 9  a number, X, a multiplier, Return      Backspace  a figure off",
    "  C  clear the board      M  the camera close to the board; again: back      T  the tour",
    "",
    "Each face of a rod holds one digit's multiples, x 1 to x 9, the tens above",
    "each diagonal and the units below. The rods for 4138 laid beside the index:",
    "row 6 holds 4 x 6, 1 x 6, 3 x 6 and 8 x 6 side by side, and adding along the",
    "diagonals from the right (a units digit and the next rod's tens, carrying",
    "any ten) gives 4138 x 6. A multiplier of several digits: a row for each,",
    "each a place left of the one after it, added up.",
  },
  genaille = {
    "GENAILLE'S RODS  (Babbage's Hall)",
    "",
    "KEYS",
    "  0 - 9  a number, X, a multiplier, Return      Backspace  a figure off",
    "  C  clear the board      M  the camera close to the board; again: back      T  the tour",
    "",
    "Henri Genaille's rods (with Edouard Lucas, about 1891) draw the carries.",
    "Row m of a rod holds a number for each carry the rod to its right can",
    "send: the units of digit x m + carry; a triangle points to the number on",
    "the next rod that its tens select. From the last rod's top number, follow",
    "the triangles left: the numbers passed are the product. No adding.",
  },
}
pcall(function()
  local h = HELP[WAY]
  h[#h + 1] = ""
  h[#h + 1] = "The rods are bodies, laid by the hand (the script's), pressed against each"
  h[#h + 1] = "other and the ledge, and read from where they lie: which face is up, which"
  h[#h + 1] = "cell is level with the index. The slate, the red strip and the adding are"
  h[#h + 1] = "the script's. The set is Napier's: ten rods, four tables each (Glaisher)."
  v:setHelpText(table.concat(h, "\n"))
end)
if v.onHover and objectKey then
  local KEY = {}
  KEY[objectKey(boardObj)] = "Napier's board: the index rod against its rim, a ledge for the rods to stand on, tilted 20 degrees"
  KEY[objectKey(indexObj)] = "the index rod: the rows' multipliers"
  KEY[objectKey(trayObj)] = "the tray: the ten rods, each in its slot"
  KEY[objectKey(slateObj)] = "the slate (the script's): the problem, the step, the row read, the adding"
  for k, r in ipairs(rods) do
    KEY[objectKey(r.obj)] = string.format("rod %d: the tables of %d, %d, %d and %d (opposite faces make 9)", k, r.faces[1], r.faces[2], r.faces[3], r.faces[4])
  end
  v:onHover(function(N, obj)
    local k = objectKey(obj)
    return k and KEY[k] or nil
  end)
end

common.setCamera(btVector3(-2, 33, 38), btVector3(-2, 9, -3))
holdStart()
