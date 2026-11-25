--
-- The Spaghetti Sort -- Babbage's Hall (the bead sort's second way: Tab,
-- or BS_WAY=spaghetti with bead-sort.lua)
--
-- A. K. Dewdney's spaghetti sort (Scientific American, June 1984): cut a
-- strand of spaghetti to the length of each number, gather them in your
-- fist and stand the bundle on the table, so that their lower ends are
-- level. Lower your other hand flat onto them: the first strand it touches
-- is the longest. Take it out and lower the hand on; the next it touches is
-- the next longest, and so on.
--
-- Here the strands are printed rods, a number n cut 3 + 1.2 n cm long (so
-- that 0 has a rod too: longer means larger all the same). The fist is a
-- rack: a base plate the rods stand on, the table that levels their feet,
-- a notch for each foot and a comb whose slots hold them upright. The flat hand is
-- the palm, a board on a post that the operator's hand lowers. Where the
-- bead sort sorts only the values (its beads end up in mixed colours), the
-- spaghetti sort moves the rods themselves: each keeps its colour, and they
-- come out in order, colours and all.
--
-- KEYS
--   0 - 9      a number, a rod cut for it (up to eight)
--   Backspace  the last number off             Return   sort: stand them up, lower the palm
--   R          eight numbers at random         C        the rods away, the palm up
--   T          the tour                        H        the manual (MANUAL.pdf)
--
-- PHYSICS: each rod is a body; it drops into its slot and stands on the
-- base, upright, its foot in a notch and its top half in the comb's slot. The palm is a body on a slider up its post, the
-- operator's hand lowering it by a motor on the slider (its speed the
-- "palm" slider). Which rod the palm touches first is found from the
-- contacts between them: that is the reading. The hand cuts the rods and
-- drops them in (the script's: each appears above its slot), and takes the
-- touched rod out and lays it down (the script's: it is lifted out of the
-- world and carried). The slate and the digits are the script's.
-- 600 steps a second.
--
-- EVERY PART CAN BE PRINTED: parts/spaghetti-sort.scad, README.md.
--
-- Units: centimetres, kilograms, seconds.
-- Headless: BS_TOUR=0 (no tour), BS_NUMS="3 7 1" (sort these at the start), BS_LOG=1,
-- BS_PALM (the palm's speed, cm a second), BS_FRICTION (a rod on the rack and the palm),
-- BS_HZ (steps a second), BS_RANDOM=n and BS_SEED (n more lists at random in the tour),
-- BS_TILT (the palm out of level by so many degrees, its right end down: a test).
--
local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end

-- ---------------------------------------------------------------------
-- this exhibit's folder; the parts files by their full paths (OpenSCAD)
-- ---------------------------------------------------------------------
local DIR
for _, d in ipairs({ "", "demo/WyomingWill/BabbagesHall/exhibits/BeadSort/" }) do
  local f = io.open(d .. "parts/spaghetti-sort.scad", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "The Spaghetti Sort: can't find its folder")
local function fullPath(path)
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
  return path
end
local SCAD = fullPath(DIR .. "parts/spaghetti-sort.scad")
local SCAD_BEAD = fullPath(DIR .. "parts/bead-sort.scad")   -- (the slate and the finger are the bead sort's)
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
local SUM = { [SCAD] = checksum({ SCAD }), [SCAD_BEAD] = checksum({ SCAD_BEAD }) }
local function part(call, solid, file)
  file = file or SCAD
  local m = OpenSCAD("// " .. SUM[file] .. "\ninclude <" .. file .. ">\nscale(0.1) " .. call .. ";\n", 0, false)
  if not solid then m.collides = false end
  return m
end
local function slatePic(name)
  local p = DIR .. "slate/" .. name .. ".png"
  if hallPath then p = hallPath(p) end
  return p
end

-- the sizes (cm), as in spaghetti-sort.scad
local G = {
  NSLOT = 8, PITCH = 2.6, ROD_D = 0.8, ROD_L0 = 3.0, ROD_U = 1.2,
  BASE_T = 0.6, ZC = -1.0, COMB_Y1 = 2.6,
  PALM_W = 25, PALM_T = 0.6, PALM_D = 4.0, POST_X = 14.1,
}
G.PALM_Z = G.ZC - 0.4
G.PALM_LOW, G.PALM_HIGH = 3.0, 15.2          -- the palm's lower face: its lowest (above the comb) and where it waits
local function rodL(n) return G.ROD_L0 + G.ROD_U * n end
local function slotX(k) return (k - (G.NSLOT + 1) / 2) * G.PITCH end
G.ROD_Z = G.ZC + G.ROD_D / 2 + 0.05             -- the rods' axes: a little in front of the comb's slots' back

-- ---------------------------------------------------------------------
-- sliders, timing, the pause at every start
-- ---------------------------------------------------------------------
v:addParam("palm", envnum("BS_PALM", 3), 0.5, 10, 0.5, "how fast the hand lowers the palm, cm a second")
v:addParam("friction", envnum("BS_FRICTION", 0.4), 0, 1.2, 0.05, "a rod on the rack, the comb and the palm (printed PLA)")
v:addParam("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second")
local HZ = envnum("BS_HZ", 600)
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
v.gravity = btVector3(0, -981, 0)
pcall(function() v:setSolverIterations(20) end)

local ident = btQuaternion(0, 0, 0, 1)
local function qa(ax, ay, az, deg) return btQuaternion(btVector3(ax, ay, az), math.rad(deg)) end
local SZ = -11                                  -- the slate's face (as the bead sort's)

local TABLE
do
  local path, f = DIR .. "../../exhibit-table.lua"
  if setfenv then f = assert(loadfile(path)); setfenv(f, getfenv(1))
  else f = assert(loadfile(path, "t", _ENV)) end
  TABLE = f()
end
TABLE.build(30, 26, { z = -3, floor = 300 })

local function still(call, col, file)
  local m = part(call, false, file)
  m.col = col
  v:add(m)
  m.trans = btTransform(ident, btVector3(0, 0, 0))
  return m
end
local baseObj = still("base()", "#7a5a3a")
local combObj = still("comb()", "#b98a52")
local postObj = still("post()", "#7a5a3a")
local slateTr = btTransform(qa(1, 0, 0, -90), btVector3(0, 0, SZ))
local slateObj = still("slate()", "#22282a", SCAD_BEAD); slateObj.trans = slateTr
local slateFrame = still("slateFrame()", "#6b4423", SCAD_BEAD); slateFrame.trans = slateTr

-- the rack's solid parts, as a fixed body: the base plate, the feet's stop,
-- the comb's back bar and its teeth (open toward you)
do
  local c = btCompoundShape(true)
  local function box(x0, x1, y0, y1, z0, z1)
    local s = btBoxShape(btVector3((x1 - x0) / 2, (y1 - y0) / 2, (z1 - z0) / 2))
    c:addChildShape(btTransform(ident, btVector3((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)), s)
  end
  local W = G.NSLOT * G.PITCH
  box(-12.0, 15.2, 0, G.BASE_T, -4.0, 2.0)                                   -- the base
  box(-W / 2 - 0.8, W / 2 + 0.8, 2.0, G.COMB_Y1, G.ZC - 1.2, G.ZC)           -- the comb's back
  local slotW = G.ROD_D + 0.1
  for k = 0, G.NSLOT do                                                       -- its teeth
    local x0 = k == 0 and -W / 2 - 0.8 or slotX(k) + slotW / 2
    local x1 = k == G.NSLOT and W / 2 + 0.8 or slotX(k + 1) - slotW / 2
    box(x0, x1, 2.0, G.COMB_Y1, G.ZC, G.ZC + 1.6)
  end
  G.rackShapes = { c }
  -- the feet's strip: a notch for each foot, open at the back, its front
  -- the stop the foot rests against (a compound of its own: bpp's Lua takes
  -- only a few dozen children to one)
  c = btCompoundShape(true)
  G.rackShapes[2] = c
  local stopZ = G.ROD_Z + G.ROD_D / 2 + 0.03
  local notchW = G.ROD_D + 0.06
  local y0, y1 = G.BASE_T, G.BASE_T + 0.3
  box(-W / 2, W / 2, y0, y1, stopZ, stopZ + 0.4)                             -- its front: the stop
  for k = 0, G.NSLOT do                                                       -- its teeth
    local x0 = k == 0 and -W / 2 or slotX(k) + notchW / 2
    local x1 = k == G.NSLOT and W / 2 or slotX(k + 1) - notchW / 2
    box(x0, x1, y0, y1, stopZ - 1.2, stopZ)
  end
  G.stopZ = stopZ
  G.rackBodies = {}
  for _, shape in ipairs(G.rackShapes) do
    local rack = Cube(0.01, 0.01, 0.01, 0)
    rack.collides = false
    local b = btRigidBody(0, btDefaultMotionState(btTransform(ident, btVector3(0, 0, 0))), shape, btVector3(0, 0, 0))
    b:setFriction(envnum("BS_FRICTION", 0.4))
    rack.body = b
    rack.collides = true
    v:add(rack)
    rack.trans = btTransform(ident, btVector3(0, 0, 0))
    G.rackBodies[#G.rackBodies + 1] = b
  end
end

-- ---------------------------------------------------------------------
-- the palm: a body on a slider up its post, lowered by the hand (a motor
-- on the slider)
-- ---------------------------------------------------------------------
local PALM_M = 0.03
local palmObj = part("translate([0, -PALM_T / 2, -PALM_Z]) palm()")
palmObj.col = "#b98a52"
local palmShape = btBoxShape(btVector3(G.PALM_W / 2, G.PALM_T / 2, G.PALM_D / 2))
-- (the body's middle is the board's; the drawing's origin is its lower face's)
-- (BS_TILT: the palm out of level, degrees, its right end down: a test)
local TILT = envnum("BS_TILT", 0)
local QTILT = qa(0, 0, 1, -TILT)
local function palmTr(y) return btTransform(QTILT, btVector3(0, y + G.PALM_T / 2, G.PALM_Z)) end
local palm = {}
do
  local tr = palmTr(G.PALM_HIGH)
  local b = btRigidBody(PALM_M, btDefaultMotionState(tr), palmShape,
    btVector3(PALM_M / 12 * (G.PALM_T ^ 2 + G.PALM_D ^ 2), PALM_M / 12 * (G.PALM_W ^ 2 + G.PALM_D ^ 2), PALM_M / 12 * (G.PALM_W ^ 2 + G.PALM_T ^ 2)))
  palmObj.body = b
  palmObj.collides = true
  v:add(palmObj)
  palmObj.trans = tr
  b:setCenterOfMassTransform(tr)
  b:setActivationState(4)
  b:setFriction(envnum("BS_FRICTION", 0.4))
  b:setRestitution(0)
  local anchor = Cube(0.01, 0.01, 0.01, 0)
  anchor.collides = false
  v:add(anchor)
  anchor.trans = btTransform(ident, btVector3(0, 0, 0))
  local QY = qa(0, 0, 1, 90)                    -- (a slider's axis is its frame's x: here up)
  local c = btSliderConstraint(anchor.body, b, btTransform(QY, btVector3(0, 0, G.PALM_Z)),
    btTransform(qa(0, 0, 1, TILT) * QY, btVector3(0, -G.PALM_T / 2, 0)), true)
  c:setLowerLinLimit(G.PALM_LOW); c:setUpperLinLimit(G.PALM_HIGH + 0.5)
  c:setLowerAngLimit(0); c:setUpperAngLimit(0)
  c:setPoweredLinMotor(true); c:setTargetLinMotorVelocity(0); c:setMaxLinMotorForce(PALM_M * 981 * 2)
  v:addConstraint(c)
  palm.obj, palm.body, palm.c = palmObj, b, c
end
pcall(function() v.showConstraints = false end)   -- (bpp would draw the slider)
local knobObj = part("translate([0, -PALM_T / 2, -PALM_Z]) knob()"); knobObj.col = "#6b4423"; v:add(knobObj)
local KNOB_X = 11.5                               -- (the knob, near the board's right end, as drawn)
local function palmY() return palm.c:getLinearPos() end
local palmWant = 0                                -- the hand's speed on the palm: 0 holding, - lowering, + raising

-- ---------------------------------------------------------------------
-- the rods: cut and dropped into their slots (by the script), taken out
-- one by one and laid in a row in front
-- ---------------------------------------------------------------------
local RHO = 0.00124                               -- kg a cm^3 (PLA)
local COLOURS = { "#c0392b", "#e67e22", "#f1c40f", "#27ae60", "#16a085", "#2980b9", "#8e44ad", "#e8e2d0" }
local CNAMES = { "red", "orange", "yellow", "green", "teal", "blue", "purple", "white" }
local QROD = qa(1, 0, 0, -90)                     -- (the part's z, its axis, up)
local rods, rodKey = {}, {}
local numbers = {}                                -- the numbers cut, in the order typed (slot 1 first)
local taken = {}                                  -- the rods taken, in order
-- where a rod's middle is, standing in slot k, its foot lifted by lift
local function standAt(k, L, lift)
  return btVector3(slotX(k), G.BASE_T + (lift or 0) + L / 2, G.ROD_Z)
end
local function rodPart(n, solid)
  return part(string.format("translate([0, 0, %g]) rod(%d)", -rodL(n) * 5, n), solid)   -- (mm: half its length down)
end
local function dropRod(k)
  local n = numbers[k]
  local L = rodL(n)
  local obj = rodPart(n, true)
  obj.col = COLOURS[k]
  local tr = btTransform(QROD, standAt(k, L, 0.6))
  local m = RHO * math.pi * (G.ROD_D / 2) ^ 2 * L
  local ix = m * (3 * (G.ROD_D / 2) ^ 2 + L * L) / 12
  local shape = btCylinderShapeZ(btVector3(G.ROD_D / 2, G.ROD_D / 2, L / 2))
  shape:setMargin(0.01)
  local b = btRigidBody(m, btDefaultMotionState(tr), shape, btVector3(ix, ix, m * (G.ROD_D / 2) ^ 2 / 2))
  obj.body = b
  obj.collides = true
  v:add(obj)
  obj.trans = tr
  b:setCenterOfMassTransform(tr)
  b:setActivationState(4)
  b:setFriction(v:getParam("friction"))
  b:setRestitution(0)
  local rod = { obj = obj, body = b, k = k, n = n, L = L }
  rods[#rods + 1] = rod
  if objectKey then rodKey[objectKey(obj)] = rod end
  return rod
end
local function applyFriction()
  local f = v:getParam("friction")
  for _, r in ipairs(rods) do if r.body then r.body:setFriction(f) end end
  palm.body:setFriction(f)
  for _, b in ipairs(G.rackBodies) do b:setFriction(f) end
end
-- (a rod lying in the row in front: the i-th taken, its left end at x0)
local LIE_X0, LIE_Z0, LIE_DZ = -11, 4.4, 1.0
local QLIE = qa(0, 1, 0, 90)                       -- (the part's z along x)
local function lieTr(i, L) return btTransform(QLIE, btVector3(LIE_X0 + L / 2, G.ROD_D / 2, LIE_Z0 + (i - 1) * LIE_DZ)) end
-- (a rod taken out of the world, drawn only, for the hand to carry)
local function lift(rod)
  local tr = rod.obj.trans
  v:remove(rod.obj)
  if objectKey then rodKey[objectKey(rod.obj)] = nil end
  rod.body = nil
  local obj = rodPart(rod.n, false)
  obj.col = COLOURS[rod.k]
  v:add(obj)
  obj.trans = tr
  rod.obj = obj
  if objectKey then rodKey[objectKey(obj)] = rod end
end
local function takeOffAll()
  for _, r in ipairs(rods) do v:remove(r.obj) end
  rods, rodKey, taken = {}, {}, {}
end

-- ---------------------------------------------------------------------
-- the slate, and the digits by the slots and the row (make-slate.py)
-- ---------------------------------------------------------------------
local function tile(w, h, x, y, pic, z, q)
  local c = Cube(w, h, 0.01, 0)
  c.collides = false
  c.tex = slatePic(pic)
  v:add(c)
  c.trans = btTransform(q or ident, btVector3(x, y, z or SZ + 0.04))
  return c
end
local slate = {}
slate.say = tile(28, 2.4, 0, 31.2, "say-sp-ready")
slate.labelA = tile(23.4, 1.25, -2.5, 28.5, "label-cut")
slate.labelB = tile(23.4, 1.25, -2.5, 22.6, "label-taken")
slate.a, slate.b = {}, {}
for k = 1, G.NSLOT do
  slate.a[k] = tile(1.6, 2.1, -10.4 + (k - 1) * 2.4, 26.2, "digit-blank")
  slate.b[k] = tile(1.6, 2.1, -10.4 + (k - 1) * 2.4, 20.3, "digit-blank")
end
local shown = {}
local function show(t, pic) if shown[t] ~= pic then shown[t] = pic; t.tex = slatePic(pic) end end
-- (the digits on the base's front, under each slot; and at the left end of
-- each rod laid in the row)
local slotTiles, rowTiles = {}, {}
local QUP = qa(1, 0, 0, -90)                       -- (a tile lying face up)
for k = 1, G.NSLOT do
  slotTiles[k] = tile(0.9, 1.15, slotX(k), G.BASE_T + 0.01, "digit-blank", 1.35, QUP)
  rowTiles[k] = tile(0.75, 0.95, LIE_X0 - 0.8, 0.01, "digit-blank", LIE_Z0 + (k - 1) * LIE_DZ, QUP)
end
local sortedOk = nil                               -- (the last reading: green while it stands)
local function showSlate()
  for k = 1, G.NSLOT do
    show(slate.a[k], numbers[k] and ("digit-" .. numbers[k]) or "digit-blank")
    local t = taken[k]
    local pic = t and ("digit-" .. t.n) or "digit-blank"
    show(slate.b[k], (t and sortedOk) and (pic .. "-green") or pic)
    show(rowTiles[k], pic)
    local standing = false
    for _, r in ipairs(rods) do if r.k == k and not r.out then standing = true end end
    show(slotTiles[k], (standing and numbers[k]) and ("digit-" .. numbers[k]) or "digit-blank")
  end
end

-- ---------------------------------------------------------------------
-- the hands: one lowers the palm by its knob, the other cuts the rods,
-- drops them in, and takes them out (the script's, drawn)
-- ---------------------------------------------------------------------
local fingerP = part("finger()", false, SCAD_BEAD); fingerP.col = "#e0b896"; v:add(fingerP)
local fingerT = part("finger()", false, SCAD_BEAD); fingerT.col = "#e0b896"; v:add(fingerT)
local REST_P = btVector3(G.POST_X + 3, 8, 6)
local REST_T = btVector3(-19, 6, 0)
local atP, atT = REST_P, REST_T
local QFING = qa(1, 0, 0, -30)
local function placeP(p) atP = p; fingerP.trans = btTransform(QFING, p) end
local function placeT(p) atT = p; fingerT.trans = btTransform(QFING, p) end
placeP(REST_P); placeT(REST_T)
local function lerp(a, b, t) return a + (b - a) * t end
local function vlerp(a, b, t) return btVector3(lerp(a.x, b.x, t), lerp(a.y, b.y, t), lerp(a.z, b.z, t)) end
local function knobAt() return btVector3(KNOB_X, palmY() + G.PALM_T + 2.0, G.PALM_Z) end
local function placeRiders()
  local tr = palmObj.trans
  knobObj.trans = tr
end

-- ---------------------------------------------------------------------
-- which rods the palm touches (the contacts: the reading)
-- ---------------------------------------------------------------------
-- (the palm is known by where it meets a rod: above the comb, where
-- nothing else is; rods never touch one another. Not by its handle: bpp
-- hands eachContact a wrong one for an object added while the hall loads
-- the exhibit, in a coroutine; FINDINGS.md)
local ABOVE = G.COMB_Y1 + 0.3
local function touching()
  local byObj, hit, seen = {}, {}, {}
  for _, r in ipairs(rods) do if r.body then byObj[r.obj] = r end end
  v:eachContact(function(a, b, x, y, z, nx, ny, nz, d, imp)
    local ra, rb = byObj[a], byObj[b]
    local r = ra or rb
    if r and not (ra and rb) and y > ABOVE and d < 0.02 and not seen[r] then seen[r] = true; hit[#hit + 1] = r end
  end)
  table.sort(hit, function(p, q) return p.k < q.k end)
  return hit
end

-- ---------------------------------------------------------------------
-- what the hands do: a queue of steps, one at a time
-- ---------------------------------------------------------------------
local LOG = os.getenv("BS_LOG")
local queue, job = {}, nil
local result                                      -- (the last sort's reading: true right, false wrong)
local function idle() return job == nil and #queue == 0 end
local function sayIt(s) show(slate.say, "say-sp-" .. s) end
local function startJob(q)
  job = { q = q, t = 0 }
  if q.say then sayIt(q.say) end
end
local function stepJob(dt)
  if not job then
    if #queue == 0 then return end
    startJob(table.remove(queue, 1))
  end
  local q = job.q
  job.t = job.t + dt
  if q.wait then
    if job.t >= q.wait then job = nil end
  elseif q.gather then
    -- a rod every 0.4 s: the hand above its slot, the rod dropped in
    job.k = job.k or 1
    local k = job.k
    if k > #numbers then
      placeT(vlerp(atT, REST_T, math.min(1, dt * 8)))
      if job.t > 0.4 then job = nil end
      return
    end
    local L = rodL(numbers[k])
    local top = standAt(k, L, 0.6)
    local want = btVector3(top.x, top.y + L / 2 + 1.2, top.z + 0.3)
    placeT(vlerp(atT, want, math.min(1, dt * 14)))
    if job.t >= 0.25 and not job.dropped then
      job.dropped = true
      dropRod(k)
      if LOG then print(string.format("  slot %d: a rod for %d, %.1f cm", k, numbers[k], L)) end
    end
    if job.t >= 0.4 then job.k, job.t, job.dropped = k + 1, 0, nil end
  elseif q.settle then
    -- until no rod moves for a quarter of a second (or 3 s)
    local vmax = 0
    for _, r in ipairs(rods) do if r.body then vmax = math.max(vmax, r.body:getLinearVelocity():length()) end end
    job.still = vmax > 0.2 and 0 or (job.still or 0) + dt
    if job.still >= 0.25 or job.t > 3 then
      if LOG then
        print(string.format("  settled after %.2f s (the fastest rod %.3f cm/s)", job.t, vmax))
        for _, r in ipairs(rods) do
          local p = r.body:getCenterOfMassPosition()
          print(string.format("    slot %d: rod %d, its top at %.3f cm", r.k, r.n, p.y + r.L / 2))
        end
      end
      job = nil
    end
  elseif q.lower then
    -- the palm down until it touches a rod; that rod taken out; on down
    placeP(knobAt())
    if not job.phase then job.phase = "down"; job.n = 0 end
    if job.phase == "down" then
      palmWant = -v:getParam("palm")
      G.watch = true
      local left = 0
      for _, r in ipairs(rods) do if r.body then left = left + 1 end end
      local hit = left > 0 and touching() or {}
      -- (the palm stopped and nothing touched: it can go no lower, on its
      -- limit or, out of level, on the comb)
      job.stall = (#hit == 0 and math.abs(palm.body:getLinearVelocity().y) < 0.05) and (job.stall or 0) + dt or 0
      if #hit > 0 then
        local r = hit[1]
        palmWant = 0
        G.watch = false
        job.n = job.n + 1
        local y = palmY()
        if LOG or #hit > 1 then
          local also = {}
          for i = 2, #hit do also[#also + 1] = string.format("%d (slot %d)", hit[i].n, hit[i].k) end
          print(string.format("  the palm touches %d (slot %d) at %.3f cm%s", r.n, r.k, y,
                              #also > 0 and (", and " .. table.concat(also, ", ")) or ""))
        end
        taken[#taken + 1] = r
        r.out = true
        job.rod, job.phase, job.pt = r, "reach", 0
        sayIt("taking")
      elseif left == 0 or palmY() <= G.PALM_LOW + 0.05 or job.stall > 0.5 or job.t > 90 then
        palmWant = 0
        if left > 0 then print(string.format("  the palm can go no lower (%.2f cm) and %d rods are left untouched", palmY(), left)) end
        job = nil
      end
    else
      -- the hand takes the touched rod: to its front, half way up; out of
      -- its slot toward you; lifted, turned and laid in the row
      local r = job.rod
      job.pt = job.pt + dt
      local p0 = standAt(r.k, r.L, 0)
      if job.phase == "reach" then
        local want = btVector3(p0.x, p0.y + 1.5, p0.z + 1.6)
        placeT(vlerp(atT, want, math.min(1, dt * 14)))
        if job.pt >= 0.35 then lift(r); job.phase, job.pt = "out", 0 end
      elseif job.phase == "out" then
        -- its foot lifted over the stop, and out of its slot toward you, its
        -- top sliding under the palm
        local u = math.min(1, job.pt / 0.35)
        local start = standAt(r.k, r.L, 0)
        local pos = btVector3(start.x, start.y + 0.45 * math.min(1, u * 3), start.z + 3.4 * math.max(0, (u - 0.3) / 0.7))
        r.obj.trans = btTransform(QROD, pos)
        placeT(btVector3(pos.x, pos.y + 1.5, pos.z + 1.6))
        if u >= 1 then
          job.phase, job.pt = "lay", 0
          job.foot = btVector3(pos.x, pos.y - r.L / 2, pos.z)
        end
      elseif job.phase == "lay" then
        -- lifted by its foot and tipped toward you, turned to lie across,
        -- and lowered into the row: (a stage each, so that it passes over
        -- the rods standing and the rods laid)
        local u = math.min(1, job.pt / 0.9)
        local function sm(t) t = math.max(0, math.min(1, t)); return t * t * (3 - 2 * t) end
        local e1, e2, e3 = sm(u / 0.4), sm((u - 0.35) / 0.35), sm((u - 0.7) / 0.3)
        local dest = btVector3(LIE_X0, G.ROD_D / 2, LIE_Z0 + (#taken - 1) * LIE_DZ)
        local up = 3.0 * (1 - e3)
        local foot = btVector3(lerp(job.foot.x, dest.x, e2), lerp(job.foot.y, dest.y, e3) + up * (e1 > 0 and 1 or 0) * math.min(1, e1 * 3), lerp(job.foot.z, dest.z, e2))
        local q = qa(0, 1, 0, 90 * e2) * qa(1, 0, 0, -90 * (1 - e1))
        -- (the axis, the part's z turned by q)
        local b1 = math.rad(-90 * (1 - e1))
        local g1 = math.rad(90 * e2)
        local dy, dz = -math.sin(b1), math.cos(b1)
        local dir = btVector3(dz * math.sin(g1), dy, dz * math.cos(g1))
        local mid = btVector3(foot.x + dir.x * r.L / 2, foot.y + dir.y * r.L / 2, foot.z + dir.z * r.L / 2)
        r.obj.trans = btTransform(q, mid)
        placeT(btVector3(mid.x, mid.y + 1.2, mid.z + 0.4))
        if u >= 1 then
          r.obj.trans = lieTr(#taken, r.L)
          job.phase = "down"
          G.watch = true
          sayIt("lowering")
        end
      end
    end
  elseif q.raise then
    palmWant = v:getParam("palm") * 2
    placeP(knobAt())
    if palmY() >= G.PALM_HIGH - 0.02 or job.t > 10 then palmWant = 0; job = nil end
  elseif q.read then
    local want = {}
    for k, x in ipairs(numbers) do want[k] = x end
    table.sort(want, function(a, b) return a > b end)
    local got = {}
    for i, r in ipairs(taken) do got[i] = r.n end
    local ok = #got == #want
    for i = 1, #want do ok = ok and got[i] == want[i] end
    result = ok
    sortedOk = ok
    print(string.format("  cut %s; taken, first to last: %s (%s)", table.concat(numbers, " "),
                        table.concat(got, " "), ok and "sorted" or "NOT sorted"))
    sayIt(ok and "sorted" or "wrong")
    job = nil
  elseif q.off then
    takeOffAll()
    sortedOk = nil
    job = nil
  elseif q.home then
    placeT(vlerp(atT, REST_T, math.min(1, dt * 8)))
    placeP(vlerp(atP, REST_P, math.min(1, dt * 8)))
    if job.t > 0.4 then placeT(REST_T); placeP(REST_P); job = nil end
  elseif q.call then
    q.call()
    job = nil
  else
    job = nil
  end
end

-- the steps: cut the rods and drop them in, let them settle, lower the palm,
-- read the order they were taken in
local function clearAll()
  if #rods == 0 and palmY() >= G.PALM_HIGH - 0.05 then return end
  queue[#queue + 1] = { say = "clearing", off = true }
  queue[#queue + 1] = { raise = true }
  queue[#queue + 1] = { home = true }
end
local function sortNumbers(list)
  clearAll()
  queue[#queue + 1] = { call = function()
    numbers = {}
    for k, x in ipairs(list) do if k <= G.NSLOT then numbers[k] = x end end
    result, sortedOk = nil, nil
  end }
  queue[#queue + 1] = { say = "gathering", gather = true }
  queue[#queue + 1] = { settle = true }
  queue[#queue + 1] = { say = "standing", wait = 0.8 }
  queue[#queue + 1] = { say = "lowering", lower = true }
  queue[#queue + 1] = { read = true }
  queue[#queue + 1] = { raise = true }
  queue[#queue + 1] = { home = true }
end

-- ---------------------------------------------------------------------
-- the tour
-- ---------------------------------------------------------------------
local TOUR = {
  { 3, 7, 1, 9, 4, 2, 6, 5 },        -- eight different numbers
  { 5, 0, 5, 2, 8, 2 },              -- a nought, and numbers twice over: two rods touched at once
  { 1, 2, 3, 4, 5, 6, 7, 8 },        -- in order already: the palm takes them from the right
}
do
  local n = envnum("BS_RANDOM", 0)
  if n > 0 then
    math.randomseed(envnum("BS_SEED", 1))
    for j = 1, n do
      local list = {}
      for k = 1, math.random(1, G.NSLOT) do list[k] = math.random(0, 9) end
      TOUR[#TOUR + 1] = list
    end
  end
end
local touring, fails = nil, 0
local function tourStart()
  touring, fails = 1, 0
  print(string.format("\nTHE SPAGHETTI SORT -- the tour: %d lists, each cut, stood up, and taken by the palm", #TOUR))
end
local function tourNext()
  if not touring or not idle() then return end
  if touring > 1 and result ~= true then fails = fails + 1 end
  if touring > #TOUR then
    touring = nil
    print("RESULT spaghetti sort tour: " .. (fails == 0 and "PASS" or "FAIL") .. string.format("  (%d lists, %d wrong; frame %d)", #TOUR, fails, G.frame or 0))
    return
  end
  local t = TOUR[touring]
  touring = touring + 1
  queue[#queue + 1] = { wait = touring == 2 and 0.3 or 1.5 }
  sortNumbers(t)
end

-- ---------------------------------------------------------------------
-- stepping: the hand's motor on the palm each step; resting when nothing moves
-- ---------------------------------------------------------------------
local function steer()
  palm.c:setTargetLinMotorVelocity(palmWant)
end
local REST_S, REST_V = 0.5, 0.05
local REST_ON = os.getenv("BS_REST") ~= "0"
local restFor, resting = 0, false
local function moving()
  if palm.body:getLinearVelocity():length() > REST_V then return true end
  for _, r in ipairs(rods) do if r.body and r.body:getLinearVelocity():length() > REST_V then return true end end
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

v:preSim(function(N)
  if holdPre() then return end
  if restPre() then return end
  steer()
  -- (while the palm is lowered, its touch is looked for after every step,
  -- and the hand stops at once: it presses on the rod no longer than that)
  for k = 1, NSTEPS - 1 do
    v:stepSimulation(STEP, 0, STEP)
    if G.watch and #touching() > 0 then G.watch = false; palmWant = 0; steer() end
  end
end)
local started = false
v:postSim(function(N)
  G.frame = N
  placeRiders()
  if holdNow then return end
  if not started then
    started = true
    local list = {}
    for n in (os.getenv("BS_NUMS") or ""):gmatch("%d") do list[#list + 1] = tonumber(n) end
    if #list > 0 then sortNumbers(list) end
    if (os.getenv("BS_TOUR") or "1") ~= "0" then tourStart() end
  end
  stepJob(FRAME_DT)
  showSlate()
  tourNext()
  restPost()
end)

-- ---------------------------------------------------------------------
-- keys, help, hover
-- ---------------------------------------------------------------------
local entry = {}                                  -- (the numbers typed, not yet sorted)
local function showEntry()
  for k = 1, G.NSLOT do show(slate.a[k], entry[k] and ("digit-" .. entry[k]) or "digit-blank") end
  sayIt("ready")
end
local function typed(d)
  touring = nil
  if #entry == 0 and #rods > 0 then
    clearAll()
    queue[#queue + 1] = { call = function() numbers = {} end }
  end
  if #entry < G.NSLOT then entry[#entry + 1] = d end
  showEntry()
end
for d = 0, 9 do v:addShortcut(tostring(d), function() typed(d) end) end
local function enter()
  touring = nil
  if #entry == 0 then return end
  local list = entry
  entry = {}
  sortNumbers(list)
end
v:addShortcut("Return", enter)
v:addShortcut("Enter", enter)
v:addShortcut("Backspace", function()
  entry[#entry] = nil
  showEntry()
end)
v:addShortcut("R", function()
  touring = nil
  entry = {}
  local list = {}
  for k = 1, G.NSLOT do list[k] = math.random(0, 9) end
  sortNumbers(list)
end)
v:addShortcut("C", function()
  touring = nil
  entry = {}
  clearAll()
  queue[#queue + 1] = { call = function() numbers = {}; sayIt("ready") end }
end)
v:addShortcut("T", function() tourStart() end)
if not hallPath then
  local MANUAL = dofile(DIR .. "../../open-manual.lua")
  for _, k in ipairs({ "H", "F1" }) do v:addShortcut(k, function() MANUAL.open(DIR, "the bead sort's manual") end) end
end
v:onParamChanged(function(N, name, value)
  if name == "speed" then applyTiming()
  elseif name == "friction" then applyFriction() end
end)
pcall(function()
  v:setHelpText(table.concat({
    "THE SPAGHETTI SORT  (Babbage's Hall: the bead sort's second way)",
    "",
    "KEYS",
    "  0 - 9  a number: a rod cut for it (up to eight)",
    "  Return  sort them               Backspace  the last number off",
    "  R       eight at random         C          the rods away, the palm up",
    "  T       the tour",
    "",
    "Each number is a rod, cut 3 + 1.2 n cm long: the larger the number, the",
    "longer the rod. The hand drops them into the rack, where they stand on its",
    "base, their feet level. Then it lowers the palm, a flat board, onto them:",
    "the first rod it touches is the longest. That rod is taken out and laid",
    "down, and the palm goes on down to the next. Laid in the order taken, the",
    "rods are the numbers sorted, largest first (A. K. Dewdney, 1984).",
    "",
    "Each rod keeps its colour: they come out in order, colours and all. The",
    "spaghetti sort moves the rods themselves; the bead sort only the values.",
    "",
    "The rods stand and the palm stops on the tallest by physics; which rod it",
    "touched is read from their contact. The hands (cutting the rods, dropping",
    "them in, taking them out), the slate and the digits are the script's.",
    "",
    "H: the manual (MANUAL.pdf, in your PDF viewer).",
  }, "\n"))
end)
if v.onHover then
  local KEY = {}
  if objectKey then
    KEY[objectKey(palmObj)] = "the palm: a flat board on a slide, lowered onto the rods; the first it touches is the longest"
    KEY[objectKey(baseObj)] = "the rack's base: the rods stand on it, so their feet are level (the table, in Dewdney's sort)"
    KEY[objectKey(combObj)] = "the comb: its slots hold the rods upright, leaning back a little, and let them out toward you"
    KEY[objectKey(postObj)] = "the post the palm slides down"
    KEY[objectKey(slateObj)] = "the slate: the numbers as cut, the rods in the order the palm took them, and what the hands are doing (the script's)"
    KEY[objectKey(fingerT)] = "the operator's hand (the script's): it cuts the rods, drops them in, and takes out each the palm touches"
    KEY[objectKey(fingerP)] = "the operator's other hand (the script's): it lowers the palm by its knob"
    KEY[objectKey(knobObj)] = "the knob the hand lowers the palm by"
  end
  v:onHover(function(N, obj, x, y, z)
    local k = objectKey and objectKey(obj)
    if not k then return nil end
    local r = rodKey[k]
    if r then
      local where = "standing in slot " .. r.k
      for i, t in ipairs(taken) do if t == r then where = "taken " .. ({ "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth" })[i] end end
      return string.format("a rod for %d, %s, %.1f cm long: %s", r.n, CNAMES[r.k], r.L, where)
    end
    for i, t in ipairs(slotTiles) do
      if objectKey(t) == k then return string.format("slot %d: the number its rod was cut for (the script's)", i) end
    end
    return KEY[k]
  end)
end

common.setCamera(btVector3(0, 33, 54), btVector3(0, 13, -3))
showSlate()
holdStart()
