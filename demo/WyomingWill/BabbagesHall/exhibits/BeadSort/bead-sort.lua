--
-- The Bead Sort -- Babbage's Hall
--
-- Nine steel rods in a frame. A number from 0 to 9 is a row of beads, laid
-- from the left: 3 is a bead on each of rods 1, 2 and 3. Up to eight
-- numbers, one row each, the first at the bottom. Laid flat, the beads stay
-- where they are put. Turned upright, they slide down their rods, each as
-- far as the beads below let it: rod k keeps as many beads as there are
-- numbers of k or more, all at the bottom. So the bottom row then reaches
-- as far as the largest number, the next row the next largest: the rows,
-- read from the bottom, are the numbers sorted. (Arulanandham, Calude and
-- Dinneen called it "bead sort", or "gravity sort", in 2002.)
--
-- The beads keep the colour of the number they were laid in: after the sort
-- the rows are mixed colours. The beads moved; the numbers didn't. A bead
-- sort sorts values only.
--
-- KEYS
--   0 - 9      a number, laid as the next row (up to eight)
--   Backspace  the last number off             Return   sort: turn the frame upright
--   R          eight numbers at random         C        lay the frame down, the beads off
--   T          the tour                        H        the manual (MANUAL.pdf)
--
-- PHYSICS: each bead is a body on a slider along its rod, tied to the frame
-- (a motor at no speed and little force is the rod's friction). The frame
-- is a body on a hinge; the operator's hand turns it, by a motor on the
-- hinge, from flat to upright. The beads fall under gravity and stop on
-- one another. The hand also threads the beads on and takes them off (the
-- script's: they appear on their row, and go). The slate, the digits by the
-- rows and the reading of the rows (counted from where the beads are) are
-- the script's. 600 steps a second.
--
-- EVERY PART CAN BE PRINTED but the steel rods and the hinge's pin:
-- parts/bead-sort.scad, README.md.
--
-- Units: centimetres, kilograms, seconds.
-- Headless: BS_TOUR=0 (no tour), BS_NUMS="3 7 1" (sort these at the start), BS_LOG=1,
-- BS_FRICTION (a bead on its rod, kg cm/s^2), BS_HAND (the frame's turning, degrees a second),
-- BS_HZ (steps a second), BS_RANDOM=n and BS_SEED (n more lists at random in the tour).
--
local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end

-- ---------------------------------------------------------------------
-- this exhibit's folder; the parts file by its full path (for OpenSCAD)
-- ---------------------------------------------------------------------
local DIR
for _, d in ipairs({ "", "demo/WyomingWill/BabbagesHall/exhibits/BeadSort/" }) do
  local f = io.open(d .. "parts/bead-sort.scad", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "The Bead Sort: can't find its folder")
local SCAD
do
  local path = DIR .. "parts/bead-sort.scad"
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
local function part(call, solid)
  local m = OpenSCAD("// " .. SCAD_SUM .. "\ninclude <" .. SCAD .. ">\nscale(0.1) " .. call .. ";\n", 0, false)
  if not solid then m.collides = false end
  return m
end
local function slatePic(name)
  local p = DIR .. "slate/" .. name .. ".png"
  if hallPath then p = hallPath(p) end
  return p
end

-- the frame's sizes (cm), as in bead-sort.scad
local NROD, PITCH, NROW = 9, 2.6, 8
local BEAD_D, BEAD_T = 2.0, 1.2
local BAR_W, BAR_H = 1.2, 2.2
local ROD_H = BAR_H / 2
local INNER = NROW * BEAD_T + 0.4
local LEN = INNER + 2 * BAR_W
local WID = NROD * PITCH + 2 * BAR_W
local S0 = BAR_W
local HINGE_H, PIN_Z = -0.6, 1.4
local function rodX(i) return (i - (NROD + 1) / 2) * PITCH end
local function rowS(r) return S0 + (r - 0.5) * BEAD_T end

-- ---------------------------------------------------------------------
-- sliders, timing, the pause at every start
-- ---------------------------------------------------------------------
v:addParam("hand", envnum("BS_HAND", 30), 5, 90, 5, "how fast the hand turns the frame upright, degrees a second")
v:addParam("friction", envnum("BS_FRICTION", 0.3), 0, 3, 0.05, "a bead on its rod: the force that holds it, kg cm/s^2 (its weight is 4.4)")
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

-- ---------------------------------------------------------------------
-- where things are. The hinge's pin runs across, PIN_Z above the table at
-- z = ZH; the frame lies flat away from you (its rods along -z) and turns
-- upright toward you (its rods up). The parts file's frame (x, s, h) with
-- the frame turned up by th degrees, flat 0, upright 90:
-- ---------------------------------------------------------------------
local ident = btQuaternion(0, 0, 0, 1)
local function qa(ax, ay, az, deg) return btQuaternion(btVector3(ax, ay, az), math.rad(deg)) end
local ZH = 5                                    -- the pin, toward you from the table's middle
local SZ = -11                                  -- the slate's face
local QFLAT = qa(1, 0, 0, -90)                  -- the parts file's frame to the hall's, the frame flat
local function frameQ(th) return qa(1, 0, 0, th) * QFLAT end
-- (a point of the frame, x across, s along the rods, h out of its face)
local function F(th, x, s, h)
  local hp = h - HINGE_H
  local c, sn = math.cos(math.rad(th)), math.sin(math.rad(th))
  return btVector3(x, PIN_Z + hp * c + s * sn, ZH + hp * sn - s * c)
end

local TABLE
do
  local path, f = DIR .. "../../exhibit-table.lua"
  if setfenv then f = assert(loadfile(path)); setfenv(f, getfenv(1))
  else f = assert(loadfile(path, "t", _ENV)) end
  TABLE = f()
end
TABLE.build(30, 26, { z = -3, floor = 300 })

local function still(call, col, tr)
  local m = part(call)
  m.col = col
  v:add(m)
  m.trans = tr
  return m
end
local footTr = btTransform(qa(1, 0, 0, -90), btVector3(0, PIN_Z, ZH))   -- (the foot's frame: its y away from you, its z up)
local footObj = still("foot()", "#7a5a3a", footTr)
local restObj = still("rest()", "#7a5a3a", footTr)
local pinObj = still("pin()", "#a9adb3", footTr)
local slateTr = btTransform(qa(1, 0, 0, -90), btVector3(0, 0, SZ))
local slateObj = still("slate()", "#22282a", slateTr)
local slateFrame = still("slateFrame()", "#6b4423", slateTr)

-- ---------------------------------------------------------------------
-- the frame: a body on a hinge (it touches nothing: the beads ride their
-- sliders, and the hinge's limits are its rest and its stop)
-- ---------------------------------------------------------------------
local FRAME_M = 0.15
local frameObj = part("frame()")
frameObj.col = "#b98a52"
local frameShape = btBoxShape(btVector3(WID / 2, LEN / 2, BAR_H / 2))
local frameTr0 = btTransform(frameQ(0), F(0, 0, 0, 0))
local frameBody = btRigidBody(FRAME_M, btDefaultMotionState(frameTr0), frameShape,
  btVector3(FRAME_M / 12 * (LEN ^ 2 + BAR_H ^ 2), FRAME_M / 12 * (WID ^ 2 + BAR_H ^ 2), FRAME_M / 12 * (WID ^ 2 + LEN ^ 2)))
frameObj.body = frameBody
v:add(frameObj)
frameObj.trans = frameTr0
frameBody:setCenterOfMassTransform(frameTr0)
frameBody:setActivationState(4)
local rodsObj = part("rods()"); rodsObj.col = "#a9adb3"; v:add(rodsObj)
local knobObj = part("knob()"); knobObj.col = "#6b4423"; v:add(knobObj)
local riders = { rodsObj, knobObj }             -- (drawn with the frame)
local anchor = Cube(0.01, 0.01, 0.01, 0)
anchor.collides = false
v:add(anchor)
anchor.trans = btTransform(ident, btVector3(0, 0, 0))
local QH = qa(0, 1, 0, 90)                       -- (a hinge's axis is its frame's z: here x)
local hinge = btHingeConstraint(anchor.body, frameBody, btTransform(QH, btVector3(0, PIN_Z, ZH)),
  btTransform(QFLAT:inverse() * QH, btVector3(0, 0, HINGE_H)))
hinge:setLimit(-math.rad(90), 0, 0.9, 0.3, 1.0)  -- (flat to upright: the rest and the stop)
v:addConstraint(hinge)
pcall(function() v.showConstraints = false end)   -- (bpp would draw the hinge and every slider)
local function frameAngle() return -math.deg(hinge:getHingeAngle()) end
local HOLD_TORQUE = 2e5                          -- (the hand's strength, kg cm^2/s^2: far more than the frame needs)
local handTarget = 0                             -- (where the hand is taking the frame: 0 flat, 90 upright)

-- ---------------------------------------------------------------------
-- the beads: threaded on (by the script) as a number is laid, taken off at
-- the end. Each slides on its rod, tied to the frame, held by friction
-- ---------------------------------------------------------------------
local BEAD_M = 0.0045                            -- kg (PLA, 3.6 cm^3)
local BI = 0.4 * BEAD_M * (BEAD_D / 2) ^ 2
local beadShape = btConvexHullShape()            -- (a short cylinder along s)
for k = 0, 23 do
  local a = k * 2 * math.pi / 24
  for _, e in ipairs({ -1, 1 }) do beadShape:addPoint(btVector3(BEAD_D / 2 * math.cos(a), e * BEAD_T / 2, BEAD_D / 2 * math.sin(a)), false) end
end
beadShape:recalcLocalAabb()
beadShape:setMargin(0.005)
local QZ = qa(0, 0, 1, 90)                       -- (a slider's axis is its frame's x: here the rod, s)
local COLOURS = { "#c0392b", "#e67e22", "#f1c40f", "#27ae60", "#16a085", "#2980b9", "#8e44ad", "#e8e2d0" }
local CNAMES = { "red", "orange", "yellow", "green", "teal", "blue", "purple", "white" }
local beads, beadKey = {}, {}
local numbers = {}                               -- the numbers laid, the first at the bottom
local function applyFriction()
  local f = v:getParam("friction")
  for _, b in ipairs(beads) do b.c:setMaxLinMotorForce(f) end
end
local function threadBead(rod, row, k)
  local th = frameAngle()
  local s = rowS(row)
  local obj = part("bead()", true)
  obj.col = COLOURS[k]
  local tr = btTransform(frameQ(th), F(th, rodX(rod), s, ROD_H))
  local b = btRigidBody(BEAD_M, btDefaultMotionState(tr), beadShape, btVector3(BI, BI, BI))
  obj.body = b
  v:add(obj)
  obj.trans = tr
  b:setCenterOfMassTransform(tr)
  b:setActivationState(4)
  b:setFriction(0.3)
  b:setRestitution(0)
  local c = btSliderConstraint(frameBody, b, btTransform(QZ, btVector3(rodX(rod), 0, ROD_H)), btTransform(QZ, btVector3(0, 0, 0)), true)
  c:setLowerLinLimit(S0 + BEAD_T / 2); c:setUpperLinLimit(LEN - BAR_W - BEAD_T / 2)
  c:setLowerAngLimit(0); c:setUpperAngLimit(0)
  c:setPoweredLinMotor(true); c:setTargetLinMotorVelocity(0); c:setMaxLinMotorForce(v:getParam("friction"))
  v:addConstraint(c)
  local bead = { obj = obj, body = b, c = c, rod = rod, laid = row, number = numbers[k], k = k }
  beads[#beads + 1] = bead
  if objectKey then beadKey[objectKey(obj)] = bead end
  return bead
end
local function takeOffAll()
  for _, b in ipairs(beads) do
    v:removeConstraint(b.c)
    v:remove(b.obj)
  end
  beads, beadKey = {}, {}
end

-- reading the frame: the row each bead is in, from where it is on its rod
local function beadRow(b) return math.max(1, math.min(NROW, math.floor((b.c:getLinearPos() - S0) / BEAD_T) + 1)) end
-- (a rod counts once in a row: while beads fall, two on one rod can
-- briefly be in the same row's band)
local function rowCounts()
  local n, seen = {}, {}
  for r = 1, NROW do n[r] = 0 end
  for _, b in ipairs(beads) do
    local r = beadRow(b)
    if not seen[r * 100 + b.rod] then seen[r * 100 + b.rod] = true; n[r] = n[r] + 1 end
  end
  return n
end
-- (and whether a row is a run from the left: rods 1 to n, no gaps)
local function rowsPacked()
  local on = {}
  for _, b in ipairs(beads) do on[beadRow(b) * 100 + b.rod] = true end
  local counts = rowCounts()
  for r = 1, NROW do
    for i = 1, counts[r] do if not on[r * 100 + i] then return false end end
  end
  return true
end

-- ---------------------------------------------------------------------
-- the slate, and the digits beside the rows (pictures: make-slate.py)
-- ---------------------------------------------------------------------
local function tile(w, h, x, y, pic)
  local c = Cube(w, h, 0.01, 0)
  c.collides = false
  c.tex = slatePic(pic)
  v:add(c)
  c.trans = btTransform(ident, btVector3(x, y, SZ + 0.04))
  return c
end
local slate = {}
-- (its board from 16 to 33 cm up, 30 across: above the upright frame)
slate.say = tile(28, 2.4, 0, 31.2, "say-ready")
slate.labelA = tile(23.4, 1.25, -2.5, 28.5, "label-laid")
slate.labelB = tile(23.4, 1.25, -2.5, 22.6, "label-rows")
slate.a, slate.b = {}, {}
for k = 1, NROW do
  slate.a[k] = tile(1.6, 2.1, -10.4 + (k - 1) * 2.4, 26.2, "digit-blank")
  slate.b[k] = tile(1.6, 2.1, -10.4 + (k - 1) * 2.4, 20.3, "digit-blank")
end
local shown = {}
local function show(t, pic) if shown[t] ~= pic then shown[t] = pic; t.tex = slatePic(pic) end end
-- (the digits beside the rows: on the frame's left bar, turned with it)
local rowTiles = {}
for r = 1, NROW do
  local c = Cube(0.9, 1.15, 0.01, 0)
  c.collides = false
  c.tex = slatePic("digit-blank")
  v:add(c)
  rowTiles[r] = c
end
local ROWTILE_X = -WID / 2 - 0.7
local function placeRiders()
  local tr = frameObj.trans
  for _, m in ipairs(riders) do m.trans = tr end
  local th = frameAngle()
  local q = qa(1, 0, 0, th - 90)
  for r = 1, NROW do rowTiles[r].trans = btTransform(q, F(th, ROWTILE_X, rowS(r), BAR_H + 0.05)) end
end
local lastCounts = ""
local sortedKey = nil      -- the counts as read when sorted: green while they last
local function showRows()
  local n = rowCounts()
  local key = table.concat(n, ",")
  if key == lastCounts then return end
  lastCounts = key
  local any = #beads > 0
  for r = 1, NROW do
    local pic = (any and r <= #numbers) and ("digit-" .. n[r]) or "digit-blank"
    show(rowTiles[r], pic)
    show(slate.b[r], (pic ~= "digit-blank" and key == sortedKey) and (pic .. "-green") or pic)
  end
end
local function showLaid()
  for k = 1, NROW do show(slate.a[k], numbers[k] and ("digit-" .. numbers[k]) or "digit-blank") end
end

-- ---------------------------------------------------------------------
-- the hand: a finger that threads the beads on (the script's) and lifts
-- the frame by its knob
-- ---------------------------------------------------------------------
local fingerObj = part("finger()")
fingerObj.col = "#e0b896"
v:add(fingerObj)
local REST = btVector3(WID / 2 + 4, 6, ZH + 2)
local fingerAt = REST
local function placeFinger(p, q) fingerAt = p; fingerObj.trans = btTransform(q or qa(1, 0, 0, -30), p) end
placeFinger(REST)
local function lerp(a, b, t) return a + (b - a) * t end
local function ease(t) return t * t * (3 - 2 * t) end
local function knobAt(th) return F(th, 0, LEN - BAR_W / 2, BAR_H + 2.2) end

-- ---------------------------------------------------------------------
-- what the hand does: a queue of steps, one at a time
-- ---------------------------------------------------------------------
local LOG = os.getenv("BS_LOG")
local queue, job = {}, nil
local say = "ready"
local result                                     -- (the last sort's reading: true right, false wrong)
local function idle() return job == nil and #queue == 0 end
local function startJob(q)
  job = { q = q, t = 0 }
  if q.say then say = q.say; show(slate.say, "say-" .. q.say) end
  if q.lay then job.k, job.i = 1, 0 end
  if q.turn then handTarget = q.turn end
end
local function fingerTo(p, u) placeFinger(btVector3(lerp(fingerAt.x, p.x, u), lerp(fingerAt.y, p.y, u), lerp(fingerAt.z, p.z, u))) end
local function stepJob(dt)
  if not job then
    if #queue == 0 then return end
    startJob(table.remove(queue, 1))
  end
  local q = job.q
  job.t = job.t + dt
  if q.wait then
    if job.t >= q.wait then job = nil end
  elseif q.lay then
    -- a bead every 0.06 s, row by row; the finger at the row's right end
    local k = job.k
    if k > #numbers then
      if job.t > 0.2 then job = nil end
      return
    end
    local n = numbers[k]
    local th = frameAngle()
    fingerTo(F(th, rodX(math.max(1, n)) + 1.5, rowS(k), BAR_H + 2.5), math.min(1, dt * 12))
    if job.t >= 0.06 then
      job.t = 0
      if job.i < n then
        job.i = job.i + 1
        threadBead(job.i, k, k)
      else
        if LOG then print(string.format("  row %d: %d laid", k, n)) end
        job.k, job.i = k + 1, 0
      end
    end
  elseif q.turn then
    -- the finger on the knob; the motor on the hinge takes the frame there
    local th = frameAngle()
    if q.turn > 0 and not job.slid then          -- (the angle at which the first bead slides)
      for _, b in ipairs(beads) do
        if rowS(b.laid) - b.c:getLinearPos() > 0.3 then        -- (a quarter of a bead toward the hinge)
          job.slid = th
          print(string.format("  the first bead slides at %.1f degrees (rod %d, row %d)", th, b.rod, b.laid))
          break
        end
      end
    end
    fingerTo(knobAt(th), math.min(1, dt * 15))
    if math.abs(th - q.turn) < 0.3 and job.t > 0.3 then
      if LOG then print(string.format("  the frame at %.1f degrees after %.2f s", th, job.t)) end
      job = nil
    end
  elseif q.settle then
    -- until no bead moves on its rod for a quarter of a second (or 3 s):
    -- its place along the rod, frame to frame (the frame's own shaking,
    -- against its stop, doesn't count)
    local moving, vmax = false, 0
    for _, b in ipairs(beads) do
      local sp = b.c:getLinearPos()
      local vv = b.lastS and math.abs(sp - b.lastS) / dt or 1e9
      b.lastS = sp
      vmax = math.max(vmax, vv)
      if vv > 0.2 then moving = true end
    end
    job.still = moving and 0 or (job.still or 0) + dt
    if job.still >= 0.25 or job.t > 3 then
      if LOG then print(string.format("  settled after %.2f s (the fastest bead on its rod %.3f cm/s)", job.t, vmax)) end
      for _, b in ipairs(beads) do b.lastS = nil end
      job = nil
    end
  elseif q.read then
    local n = rowCounts()
    local want = {}
    for k, x in ipairs(numbers) do want[k] = x end
    table.sort(want, function(a, b) return a > b end)
    local ok = rowsPacked()
    for r = 1, #numbers do ok = ok and n[r] == want[r] end
    for r = #numbers + 1, NROW do ok = ok and n[r] == 0 end
    result = ok
    local got = {}
    for r = 1, #numbers do got[r] = n[r] end
    print(string.format("  laid %s; the rows, from the bottom: %s (%s)", table.concat(numbers, " "),
                        table.concat(got, " "), ok and "sorted" or "NOT sorted"))
    sortedKey = ok and table.concat(n, ",") or nil
    lastCounts = ""
    say = ok and "sorted" or "wrong"
    show(slate.say, "say-" .. say)
    job = nil
  elseif q.off then
    takeOffAll()
    lastCounts = ""
    job = nil
  elseif q.home then
    fingerTo(REST, math.min(1, dt * 8))
    if job.t > 0.4 then placeFinger(REST); job = nil end
  elseif q.call then
    q.call()
    job = nil
  else
    job = nil
  end
end

-- the steps: lay the numbers, turn the frame up, let the beads settle, read
local function clearFrame()
  if #beads == 0 and frameAngle() < 1 then return end
  queue[#queue + 1] = { say = "clearing", turn = 0 }
  queue[#queue + 1] = { off = true }
  queue[#queue + 1] = { home = true }
end
local function sortNumbers(list)
  clearFrame()
  queue[#queue + 1] = { call = function()
    numbers = {}
    for k, x in ipairs(list) do if k <= NROW then numbers[k] = x end end
    showLaid()
    result = nil
  end }
  queue[#queue + 1] = { say = "laying", lay = true }
  queue[#queue + 1] = { wait = 0.5 }
  queue[#queue + 1] = { say = "tipping", turn = 90 }
  queue[#queue + 1] = { settle = true }
  queue[#queue + 1] = { say = "settled", wait = 0.8 }
  queue[#queue + 1] = { read = true }
  queue[#queue + 1] = { home = true }
end

-- ---------------------------------------------------------------------
-- the tour
-- ---------------------------------------------------------------------
local TOUR = {
  { 3, 7, 1, 9, 4, 2, 6, 5 },        -- eight different numbers
  { 5, 0, 5, 2, 8, 2 },              -- a nought, and numbers twice over
  { 1, 2, 3, 4, 5, 6, 7, 8 },        -- the wrong way up: every bead above the first row falls
}
-- (BS_RANDOM=n: n more lists at random, BS_SEED the seed: for sweeps)
do
  local n = envnum("BS_RANDOM", 0)
  if n > 0 then
    math.randomseed(envnum("BS_SEED", 1))
    for j = 1, n do
      local list = {}
      for k = 1, math.random(1, NROW) do list[k] = math.random(0, 9) end
      TOUR[#TOUR + 1] = list
    end
  end
end
local touring, fails = nil, 0
local function tourStart()
  touring, fails = 1, 0
  print(string.format("\nTHE BEAD SORT -- the tour: %d lists, each laid, turned upright, and read", #TOUR))
end
local function tourNext()
  if not touring or not idle() then return end
  if touring > 1 and result ~= true then fails = fails + 1 end
  if touring > #TOUR then
    touring = nil
    print("RESULT bead sort tour: " .. (fails == 0 and "PASS" or "FAIL") .. string.format("  (%d lists, %d wrong)", #TOUR, fails))
    return
  end
  local t = TOUR[touring]
  touring = touring + 1
  queue[#queue + 1] = { wait = touring == 2 and 0.3 or 1.5 }
  sortNumbers(t)
end

-- ---------------------------------------------------------------------
-- stepping: the hand's motor each step; resting when nothing moves
-- ---------------------------------------------------------------------
local function steer()
  local th = frameAngle()
  local speed = v:getParam("hand")
  local err = handTarget - th
  local w = math.max(-speed, math.min(speed, err * 8))       -- (slowing over the last few degrees)
  hinge:enableAngularMotor(true, -math.rad(w), HOLD_TORQUE * STEP)
end
local REST_S, REST_V = 0.5, 0.05
local REST_ON = os.getenv("BS_REST") ~= "0"
local restFor, resting = 0, false
local function moving()
  if math.abs(frameBody:getAngularVelocity():length()) > 0.01 then return true end
  for _, b in ipairs(beads) do if b.body:getLinearVelocity():length() > REST_V then return true end end
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
  for k = 1, NSTEPS - 1 do v:stepSimulation(STEP, 0, STEP); steer() end
end)
local started = false
v:postSim(function(N)
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
  showRows()
  tourNext()
  restPost()
end)

-- ---------------------------------------------------------------------
-- keys, help, hover
-- ---------------------------------------------------------------------
local entry = {}                                 -- (the numbers typed, not yet sorted)
local function showEntry()
  for k = 1, NROW do show(slate.a[k], entry[k] and ("digit-" .. entry[k]) or "digit-blank") end
  show(slate.say, "say-ready")
end
local function typed(d)
  touring = nil
  if #entry == 0 and (#beads > 0 or frameAngle() > 1) then clearFrame() end
  if #entry < NROW then entry[#entry + 1] = d end
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
  for k = 1, NROW do list[k] = math.random(0, 9) end
  sortNumbers(list)
end)
v:addShortcut("C", function()
  touring = nil
  entry = {}
  clearFrame()
  queue[#queue + 1] = { call = function() numbers = {}; showLaid(); show(slate.say, "say-ready") end }
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
    "THE BEAD SORT  (Babbage's Hall)",
    "",
    "KEYS",
    "  0 - 9  a number, laid as the next row (up to eight)",
    "  Return  sort them               Backspace  the last number off",
    "  R       eight at random         C          lay the frame down, the beads off",
    "  T       the tour",
    "",
    "Each number is a row of beads, laid from the left: 3 is a bead on each of",
    "rods 1, 2 and 3. The first number is the bottom row. Turned upright, the",
    "beads slide down their rods, each until it rests on the bead below. Rod k",
    "then keeps as many beads as there are numbers of k or more, all at the",
    "bottom: the bottom row reaches as far as the largest number, the next row",
    "the next largest. Read from the bottom, the rows are the numbers, sorted.",
    "The digits beside the rows count each row's beads as they fall.",
    "",
    "The beads keep their number's colour: after the sort the rows are mixed.",
    "The beads moved; the numbers didn't. A bead sort sorts values only.",
    "",
    "The beads fall and stop by physics; the hand (threading the beads on and",
    "turning the frame), the slate and the counting of the rows are the script's.",
    "",
    "H: the manual (MANUAL.pdf, in your PDF viewer).",
  }, "\n"))
end)
if v.onHover then
  local KEY = {}
  if objectKey then
    KEY[objectKey(frameObj)] = "the frame, hinged at its lower edge: laid flat to lay the numbers, turned upright to sort them"
    KEY[objectKey(rodsObj)] = "the rods, steel: rod 1 at the left, rod 9 at the right"
    KEY[objectKey(footObj)] = "the foot: the hinge, and the stop the frame leans on upright"
    KEY[objectKey(slateObj)] = "the slate: the numbers as laid, the rows as they are now, and what the hand is doing (the script's)"
    KEY[objectKey(fingerObj)] = "the operator's hand (the script's): it threads the beads on and turns the frame"
    KEY[objectKey(knobObj)] = "the knob the hand lifts the frame by"
  end
  v:onHover(function(N, obj, x, y, z)
    local k = objectKey and objectKey(obj)
    if not k then return nil end
    local b = beadKey[k]
    if b then
      return string.format("a bead on rod %d, %s: laid in row %d as part of the number %d; now in row %d",
                           b.rod, CNAMES[b.k], b.laid, b.number, beadRow(b))
    end
    for r, t in ipairs(rowTiles) do
      if objectKey(t) == k then return string.format("row %d: its beads, counted (the script's)", r) end
    end
    return KEY[k]
  end)
end

common.setCamera(btVector3(0, 34, ZH + 50), btVector3(0, 15, -6))
showLaid()
holdStart()
