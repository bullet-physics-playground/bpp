--
-- The Suanpan -- Babbage's Hall
--
-- The Chinese abacus. Seven rods; on each, two heaven beads above the beam
-- (the reckoning bar) and five earth beads below it. A bead counts when it
-- is at the beam: a heaven bead 5, an earth bead 1. So a rod shows a digit
-- from 0 to 9, the units rod on the right, and the abacus a number.
--
-- Adding is done rod by rod from the left, by rules every pupil learned by
-- heart (plan.lua has them):
--   direct           room on the rod: beads to the beam
--   five-complement  no room among the earth beads: the heaven bead down,
--                    and take away the difference (+3 = 5 - 2)
--   ten-complement   the rod would pass 9: take away what is left of 10,
--                    and carry 1 to the rod on the left (+8 = 10 - 2)
-- Taking away is the same rules backward (-3 = -5 + 2; -8 = -10 + 2,
-- borrowing 1 from the rod on the left). Multiplying is Kojima's way: the
-- multiplier on the rods at the left, the multiplicand to its right, and
-- each digit of one times each of the other, from the times table, added
-- as two digits on the rods to the right of the multiplicand's digit.
-- The slate beside it shows the number on the abacus, the one being added
-- (taken away, multiplied), the rod the hand is at, and the rule.
--
-- THREE WAYS (SU_WAY; in the hall, Tab steps through them)
--   add        (the default)
--   subtract   Return takes the number away; A adds it instead
--   multiply   type 36, X, 4: Return works 36 x 4 (up to 99 x 99, or 9999 x 9)
--
-- KEYS
--   0 - 9      a number (shown on the slate)           Return   add it (or ...)
--   Backspace  its last digit off                      C        clear the abacus
--   T          the tour: each step using a rule of its own
--   H          the manual (MANUAL.pdf) in the PDF viewer
--
-- PHYSICS: each bead is a body that slides on its rod (a slider; a motor at
-- no speed and little force is the rod's friction, holding it where it is
-- left). The operator's finger is the script's: it takes hold of one bead
-- and moves it, and that bead pushes the others ahead of it by contact, as
-- a finger does. The slate and the finger are the script's (said so); the
-- beads' value is read from where they are. 600 steps a second.
--
-- EVERY PART CAN BE PRINTED but the steel rods: parts/suanpan.scad, README.md.
--
-- Units: centimetres, kilograms, seconds.
-- Headless: SU_WAY (add, subtract, multiply), SU_TOUR=0 (no tour), SU_ADD=n (add n at the start), SU_LOG=1
-- (print each move), SU_FRICTION (the beads on their rods, kg cm/s^2),
-- SU_FINGER (the finger's speed, cm/s), SU_HZ (steps a second).
--

local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end

-- ---------------------------------------------------------------------
-- this exhibit's folder; the parts file by its full path (for OpenSCAD)
-- ---------------------------------------------------------------------
local DIR
for _, d in ipairs({ "", "demo/WyomingWill/BabbagesHall/exhibits/Suanpan/" }) do
  local f = io.open(d .. "parts/suanpan.scad", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "The Suanpan: can't find its folder")
local plan = dofile(DIR .. "plan.lua")
local RULES = dofile(DIR .. "slate/rules.lua")
local WAY = os.getenv("SU_WAY") or "add"
if WAY ~= "subtract" and WAY ~= "multiply" then WAY = "add" end
local READY = WAY == "add" and "rule-ready" or ("rule-ready-" .. WAY)
local SCAD
do
  local path = DIR .. "parts/suanpan.scad"
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
-- (a slate picture, by the path bpp opens it from)
local function slatePic(name)
  local p = DIR .. "slate/" .. name .. ".png"
  if hallPath then p = hallPath(p) end
  return p
end

-- the abacus's sizes (cm), as in suanpan.scad
local ROD_N, PITCH = 7, 2.4
local BEAD_D, BEAD_T = 2.0, 1.2
local BAR_W, BAR_H, BEAM_W = 1.2, 2.4, 0.8
local HEAVEN_L, EARTH_L = 2 * BEAD_T + 1.4, 5 * BEAD_T + 1.4
local ROD_Y = BAR_H / 2
local LEN = 2 * BAR_W + HEAVEN_L + BEAM_W + EARTH_L
local Y0 = -LEN / 2
local BEAM_Y = Y0 + BAR_W + EARTH_L
local function rodX(i) return (i - (ROD_N + 1) / 2) * PITCH end

-- ---------------------------------------------------------------------
-- sliders, timing, the pause at every start
-- ---------------------------------------------------------------------
v:addParam("friction", envnum("SU_FRICTION", 0.3), 0.05, 2, 0.05, "a bead on its rod: the force that holds it, kg cm/s^2")
v:addParam("finger", envnum("SU_FINGER", 5), 1, 12, 0.5, "how fast the finger moves a bead, cm/s")
v:addParam("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second")
local HZ = envnum("SU_HZ", 600)
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
-- where things are: the abacus on the table (the parts file's frame turned
-- into the hall's: its y, along the rods toward the heaven beads, is away
-- from you, -z; its z is up), the slate behind it
-- ---------------------------------------------------------------------
local ident = btQuaternion(0, 0, 0, 1)
local function qa(ax, ay, az, deg) return btQuaternion(btVector3(ax, ay, az), math.rad(deg)) end
local Q = qa(1, 0, 0, -90)                 -- the parts file's frame to the hall's
local AZ = 3                               -- the abacus's middle, toward you from the table's middle
local SZ = -9                              -- the slate's face
-- (a point given as the parts file has it, x across, s along the rods, h up)
local function W(x, s, h) return btVector3(x, h, AZ - s) end

local TABLE
do
  local path, f = DIR .. "../../exhibit-table.lua"
  if setfenv then f = assert(loadfile(path)); setfenv(f, getfenv(1))
  else f = assert(loadfile(path, "t", _ENV)) end
  TABLE = f()
end
TABLE.build(32, 24, { z = -1.5, floor = 300 })

local function still(call, col, tr)
  local m = part(call)
  m.col = col
  v:add(m)
  m.trans = tr or btTransform(Q, W(0, 0, 0))
  return m
end
local frameObj = still("frame()", "#b98a52")              -- (boxwood: light, so the dark beads show against it)
local rodsObj = still("rods()", "#a9adb3")
local slateTr = btTransform(Q, btVector3(0, 0, SZ))
local slateObj = still("slate()", "#22282a", slateTr)    -- (the pictures' own slate colour)
local slateFrame = still("slateFrame()", "#6b4423", slateTr)

-- ---------------------------------------------------------------------
-- the beads: each slides on its rod, held by friction where it is left
-- ---------------------------------------------------------------------
local anchor = Cube(0.01, 0.01, 0.01, 0)       -- (only for the sliders to hold to)
anchor.collides = false
v:add(anchor)
anchor.trans = btTransform(ident, btVector3(0, 0, 0))
-- a bead's shape, in the parts file's frame (along y): two cones back to back
local beadShape
do
  local h = btConvexHullShape()
  for k = 0, 23 do
    local a = k * 2 * math.pi / 24
    local c, s = math.cos(a), math.sin(a)
    h:addPoint(btVector3(BEAD_D / 2 * c, 0, BEAD_D / 2 * s), false)
    for _, e in ipairs({ -1, 1 }) do h:addPoint(btVector3(0.4 * c, e * BEAD_T / 2, 0.4 * s), false) end
  end
  h:recalcLocalAabb()
  h:setMargin(0.005)
  beadShape = h
end
local BEAD_M = 0.0023                          -- kg (PLA, 1.8 cm^3, solid)
local BEAD_I = 0.4 * BEAD_M * (BEAD_D / 2) ^ 2
local QZ = qa(0, 0, 1, 90)                     -- (a slider's axis is its frame's x: here along the rod, +s)
-- the beads' places along the rods (s): bead k of a deck, 1 the nearest the beam
local EARTH_LO = Y0 + BAR_W                    -- the earth deck: from the near bar ...
local HEAVEN_HI = -Y0 - BAR_W                  -- the heaven deck: ... to the far bar
local function earthUp(k) return BEAM_Y - (k - 0.5) * BEAD_T end
local function earthDown(k) return EARTH_LO + (5 - k + 0.5) * BEAD_T end
local function heavenDown(j) return BEAM_Y + BEAM_W + (j - 0.5) * BEAD_T end
local function heavenUp(j) return HEAVEN_HI - (2 - j + 0.5) * BEAD_T end

local rods = {}          -- rods[i] = { earth = { beads }, heaven = { beads } }
local allBeads, beadKey = {}, {}
local function makeBead(i, s, lo, hi, col, what)
  local obj = part("bead()", true)
  obj.col = col
  local tr = btTransform(Q, W(rodX(i), s, ROD_Y))
  local b = btRigidBody(BEAD_M, btDefaultMotionState(tr), beadShape, btVector3(BEAD_I, BEAD_I, BEAD_I))
  obj.body = b
  v:add(obj)
  obj.trans = tr
  b:setCenterOfMassTransform(tr)
  b:setActivationState(4)
  b:setFriction(0.3)
  b:setRestitution(0)
  local c = btSliderConstraint(anchor.body, b, btTransform(Q * QZ, W(rodX(i), 0, ROD_Y)), btTransform(QZ, btVector3(0, 0, 0)), true)
  c:setLowerLinLimit(lo); c:setUpperLinLimit(hi)
  c:setLowerAngLimit(0); c:setUpperAngLimit(0)
  c:setPoweredLinMotor(true); c:setTargetLinMotorVelocity(0)
  v:addConstraint(c)
  local bead = { obj = obj, body = b, c = c, lo = lo, hi = hi, rod = i }
  allBeads[#allBeads + 1] = bead
  beadKey[objectKey and objectKey(obj) or obj] = what
  return bead
end
for i = 1, ROD_N do
  local r = { earth = {}, heaven = {} }
  for k = 1, 5 do
    r.earth[k] = makeBead(i, earthDown(k), earthDown(k), earthUp(k), "#2b1a12", "an earth bead: 1, when pushed up to the beam")
  end
  for j = 1, 2 do
    r.heaven[j] = makeBead(i, heavenUp(j), heavenDown(j), heavenUp(j), "#2b1a12", "a heaven bead: 5, when pushed down to the beam")
  end
  rods[i] = r
end
pcall(function() v.showConstraints = false end)
local function applyFriction()
  local f = v:getParam("friction")
  for _, b in ipairs(allBeads) do if not b.held then b.c:setMaxLinMotorForce(f) end end
end
applyFriction()

-- reading the abacus: where the beads are
local NEAR = 0.3 * BEAD_T
local function rodDigit(i)
  local r, h, e = rods[i], 0, 0
  for j = 1, 2 do if r.heaven[j].c:getLinearPos() < r.heaven[j].lo + NEAR then h = h + 1 end end
  for k = 1, 5 do if r.earth[k].c:getLinearPos() > r.earth[k].hi - NEAR then e = e + 1 end end
  return 5 * h + e
end
local function reading()
  local n = 0
  for i = 1, ROD_N do n = n * 10 + rodDigit(i) end
  return n
end

-- ---------------------------------------------------------------------
-- the slate: pictures swapped in (make-slate.py made them)
-- ---------------------------------------------------------------------
local function tile(w, h, x, y, pic)
  local c = Cube(w, h, 0.01, 0)
  c.collides = false
  c.tex = slatePic(pic)
  v:add(c)
  c.trans = btTransform(ident, btVector3(x, y, SZ + 0.04))     -- (just in front of the board's face, which is toward you, +z: the board stands a little proud of SZ; thin, or its top edge shows the picture squashed into a strip)
  return c
end
-- (the board's face is the parts file's y = 0, toward -y: in the hall z = SZ,
-- toward you; its slate from 2 to 19 cm up, 28 cm across)
local slate = {}
slate.labelA = tile(7.4, 1.3, -9.8, 16.4, "label-abacus")
slate.labelB = tile(7.4, 1.3, -9.8, 13.1, ({ add = "label-adding", subtract = "label-subtracting",
                                              multiply = "label-multiplying" })[WAY])
slate.a, slate.b = {}, {}
for k = 1, ROD_N do
  slate.a[k] = tile(1.6, 2.1, -4.6 + k * 2.1, 16.4, "digit-0")
  slate.b[k] = tile(1.6, 2.1, -4.6 + k * 2.1, 13.1, "digit-blank")
end
slate.place = tile(25, 1.6, 0, 9.9, "place-none")
slate.rule = tile(25, 4, 0, 6.0, READY)
local shown = {}
local function show(t, pic) if shown[t] ~= pic then shown[t] = pic; t.tex = slatePic(pic) end end
local function showNumber(row, n, blankZero)
  local s = (n and (n > 0 or not blankZero)) and tostring(n) or ""
  for k = 1, ROD_N do
    local i = k - (ROD_N - #s)
    show(row[k], i >= 1 and ("digit-" .. s:sub(i, i)) or "digit-blank")
  end
end
-- (digits and x, as typed for multiplying: 36x4)
local function showText(row, s)
  s = s or ""
  for k = 1, ROD_N do
    local i = k - (ROD_N - #s)
    local c = i >= 1 and s:sub(i, i) or ""
    show(row[k], c == "" and "digit-blank" or c == "x" and "digit-times" or ("digit-" .. c))
  end
end

-- ---------------------------------------------------------------------
-- the finger: takes hold of one bead and moves it to a place; the others
-- move as that bead pushes them. Between beads it lifts and moves over.
-- ---------------------------------------------------------------------
local fingerObj = part("finger()")
fingerObj.col = "#e0b896"
v:add(fingerObj)
local FQ = qa(1, 0, 0, -59)                    -- (pointing down at the bead, the hand up and toward you)
local fingerAt = btVector3(14, 9, AZ + 6)       -- (resting, beside the abacus)
local REST = btVector3(14, 9, AZ + 6)
local function placeFinger(p) fingerAt = p; fingerObj.trans = btTransform(FQ, p) end
placeFinger(REST)

local queue = {}         -- what is left to do: { move = {rod, deck, count} } or { step = s } or { wait = t }
local job                -- the one being done
local LOG = os.getenv("SU_LOG")
local digits = {}        -- what the plan says the rods hold (checked against the beads)
for i = 1, ROD_N do digits[i] = 0 end

-- a move: which bead the finger takes, and to where
local function beadFor(m)
  local r = rods[m[1]]
  local deck, count = m[2], m[3]
  if deck == "earth" then
    local now = 0
    for k = 1, 5 do if r.earth[k].c:getLinearPos() > r.earth[k].hi - NEAR then now = k end end
    if count > now then return r.earth[count], r.earth[count].hi              -- (up: the farthest of those to go)
    elseif count < now then return r.earth[count + 1], r.earth[count + 1].lo  -- (down: the nearest of those to go)
    end
  else
    local down = r.heaven[1].c:getLinearPos() < r.heaven[1].lo + NEAR
    if count == 1 and not down then return r.heaven[1], r.heaven[1].lo
    elseif count == 0 and down then return r.heaven[1], r.heaven[1].hi end
  end
end
-- the finger's tip, against the bead on the side it pushes from
local function tipFor(bead, s, dir)
  return W(rodX(bead.rod), s - dir * (BEAD_T / 2 + 0.3), ROD_Y + 0.55)
end
local function lerp(a, b, t) return a + (b - a) * t end
local function ease(t) return t * t * (3 - 2 * t) end

-- (what the slate shows for a step: its rule's picture, and the rod)
local LETTERS = "ABCDEFG"
local PLACES = { "units", "tens", "hundreds", "thousands", "ten thousands", "hundred thousands", "millions" }
local function ruleKey(s)
  if s.rule == "times" then return "times-" .. s.a .. "-" .. s.b end
  if s.rule == "mset" or s.rule == "aset" or s.rule == "mclear" then return s.rule end
  return s.rule .. "-" .. s.a
end
local function placePic(s)
  if WAY == "multiply" then return "rod-" .. s.rod .. (s.carry and "-carry" or "") end
  return "place-" .. (ROD_N + 1 - s.rod) .. (s.carry and "-carry" or s.borrow and "-borrow" or "")
end
local function placeWords(s)
  if WAY == "multiply" then return "rod " .. LETTERS:sub(s.rod, s.rod) end
  return PLACES[ROD_N + 1 - s.rod] .. " rod"
end
-- (every rod's digit, zeros too: while multiplying, the numbers set on it)
local function showRods(row)
  for k = 1, ROD_N do show(row[k], "digit-" .. rodDigit(k)) end
end

local function startJob()
  local q = table.remove(queue, 1)
  if not q then job = nil; return end
  if q.step then
    local s = q.step
    local key = ruleKey(s)
    show(slate.place, placePic(s))
    show(slate.rule, "rule-" .. key)
    if WAY == "multiply" then showRods(slate.a) else showNumber(slate.a, reading()) end
    local w = RULES[key]
    print(string.format("  %s%s:  %s   (%s)", placeWords(s), s.carry and " (the carry)" or s.borrow and " (the borrow)" or "",
          w[1], w[2]))
    job = { wait = (s.rule == "mset" or s.rule == "aset") and 1.0 or s.rule == "times" and 1.2 or 0.6 }
    return
  end
  if q.wait then job = { wait = q.wait, after = q.after }; return end
  if q.call then job = nil; q.call(); if not job then job = { wait = 0 } end; return end
  local bead, target = beadFor(q.move)
  if not bead then job = { wait = 0 }; return end
  local s0 = bead.c:getLinearPos()
  local dir = target > s0 and 1 or -1
  local tip = tipFor(bead, s0, dir)
  job = { bead = bead, target = target, dir = dir, phase = "over", t = 0,
          from = fingerAt, above = tip + btVector3(0, 2.5, 0), tip = tip }
  if LOG then print(string.format("  move rod %d %s to %d", q.move[1], q.move[2], q.move[3])) end
end
local function release(b)
  b.held = false
  b.c:setTargetLinMotorVelocity(0)
  b.c:setMaxLinMotorForce(v:getParam("friction"))
end
-- each simulation step: the finger's bead steered to its place
local function steer()
  local j = job
  if not (j and j.bead and j.phase == "push") then return end
  local b = j.bead
  local err = j.target - b.c:getLinearPos()
  local vmax = v:getParam("finger")
  b.c:setTargetLinMotorVelocity(math.max(-vmax, math.min(vmax, 10 * err)))
  b.c:setMaxLinMotorForce(20)
  b.held = true
end
-- each frame: the finger's way, and what comes next
local function stepJob(dt)
  local j = job
  if not j then startJob(); return end
  if j.wait then
    j.wait = j.wait - dt
    if j.wait <= 0 then job = nil; startJob() end
    return
  end
  j.t = j.t + dt
  if j.phase == "over" then                    -- (up, over, and down onto the bead)
    local u = math.min(1, j.t / 0.45)
    local p
    if u < 0.75 then
      local w = ease(u / 0.75)
      local lift = j.from + btVector3(0, 2.5, 0)
      p = btVector3(lerp(lift.x, j.above.x, w), lerp(lift.y, j.above.y, w), lerp(lift.z, j.above.z, w))
    else
      local w = ease((u - 0.75) / 0.25)
      p = btVector3(j.above.x, lerp(j.above.y, j.tip.y, w), j.above.z)
    end
    placeFinger(p)
    if u >= 1 then j.phase, j.t, j.held = "push", 0, 0 end
  elseif j.phase == "push" then                -- (the bead moved, the finger with it)
    local s = j.bead.c:getLinearPos()
    placeFinger(tipFor(j.bead, s, j.dir))
    if math.abs(j.target - s) < 0.03 then j.held = j.held + dt else j.held = 0 end
    if j.held > 0.08 or j.t > 4 then
      release(j.bead)
      j.phase, j.t, j.from = "off", 0, fingerAt
    end
  elseif j.phase == "off" then                 -- (lifted off the bead)
    local u = math.min(1, j.t / 0.12)
    placeFinger(j.from + btVector3(0, 1.2 * ease(u), 0))
    if u >= 1 then job = nil; startJob() end
  end
end
local function idle() return job == nil and #queue == 0 end

-- ---------------------------------------------------------------------
-- adding, clearing, the tour
-- ---------------------------------------------------------------------
local entry = ""          -- the number being typed
local fails = 0
local function queueSteps(steps)
  for _, s in ipairs(steps) do
    queue[#queue + 1] = { step = s }
    for _, m in ipairs(s.moves) do queue[#queue + 1] = { move = m } end
  end
end
-- (the beads read, and checked against what was meant; the finger home)
local function queueCheck(expect)
  queue[#queue + 1] = { wait = 0.3 }
  queue[#queue + 1] = { call = function()
    local r = reading()
    showNumber(slate.a, r)
    show(slate.place, "place-none")
    local want = expect
    local ok = r == want
    if not ok then fails = fails + 1 end
    print(string.format("  the beads read %d%s", r, ok and "" or ("  -- WRONG, " .. want .. " was meant")))
  end }
  -- (the finger back to its rest)
  queue[#queue + 1] = { call = function() job = { bead = nil, phase = "home", t = 0, from = fingerAt } end }
end
local function addNumber(n, expect)
  local total = plan.value(digits)
  if total + n > 10 ^ ROD_N - 1 then print("  (too big for seven rods)"); return false end
  showNumber(slate.b, n)
  show(slate.rule, "rule-none")
  print(string.format("ADD %d to %d", n, total))
  queueSteps(plan.number(digits, n))
  queueCheck(expect or plan.value(digits))
  return true
end
local function subNumber(n, expect)
  local total = plan.value(digits)
  if n > total then print(string.format("  (%d is more than the %d on the abacus)", n, total)); return false end
  showNumber(slate.b, n)
  show(slate.rule, "rule-none")
  print(string.format("TAKE %d from %d", n, total))
  queueSteps(plan.subNumber(digits, n))
  queueCheck(expect or plan.value(digits))
  return true
end
local function clearAll(keepB)
  show(slate.rule, "rule-clear")
  show(slate.place, "place-none")
  for i = 1, ROD_N do
    digits[i] = 0
    queue[#queue + 1] = { move = { i, "heaven", 0 } }
    queue[#queue + 1] = { move = { i, "earth", 0 } }
  end
  queue[#queue + 1] = { wait = 0.2 }
  queue[#queue + 1] = { call = function()
    showNumber(slate.a, reading())
    if not keepB then showNumber(slate.b, nil); show(slate.rule, READY) end
  end }
end
local function multiply(a, b, expect)
  if not plan.layout(ROD_N, a, b) then
    if plan.layout(ROD_N, b, a) then
      print(string.format("  (set as %d x %d: the longer number the multiplicand, so that it fits)", b, a))
      a, b = b, a
    else
      print(string.format("  (%d x %d is too long for seven rods: up to 99 x 99, or 9999 x 9)", a, b))
      return false
    end
  end
  showText(slate.b, a .. "x" .. b)
  show(slate.rule, "rule-none")
  print(string.format("MULTIPLY %d by %d", a, b))
  local clear = reading() == 0
  for i = 1, ROD_N do if digits[i] ~= 0 then clear = false end end
  if not clear then clearAll(true) end
  queueSteps(plan.multiply(digits, a, b))
  queueCheck(expect or a * b)
  return true
end

-- (each: what to do, the number or numbers, and what the beads should read)
local TOURS = {
  add = { { "add", 3, 3 }, { "add", 4, 7 }, { "add", 8, 15 }, { "add", 6, 21 }, { "add", 79, 100 },
          { "add", 1234, 1334 } },
  -- (2000 - 1 borrows through three rods; then each rule in turn)
  subtract = { { "add", 2000, 2000 }, { "sub", 1, 1999 }, { "sub", 4, 1995 }, { "sub", 3, 1992 },
               { "sub", 7, 1985 }, { "sub", 8, 1977 }, { "sub", 5, 1972 } },
  multiply = { { "mul", 36, 4, 144 }, { "mul", 23, 45, 1035 }, { "mul", 99, 99, 9801 } },
}
local TOUR_SAYS = {
  add = "3, 4, 8, 6, 79 and 1234 added, each using a rule of its own",
  subtract = "2000 set, then 1, 4, 3, 7, 8 and 5 taken away, each using a rule of its own",
  multiply = "36 x 4, 23 x 45 and 99 x 99",
}
local TOUR = TOURS[WAY]
-- (SU_RANDOM=n: n random numbers added (taken away, multiplied) instead, and checked)
local RANDOM_N = envnum("SU_RANDOM", 0)
if RANDOM_N > 0 then
  math.randomseed(envnum("SU_SEED", 1))
  TOUR = {}
  local total = 0
  if WAY == "subtract" then
    total = math.random(1000000, 9999999)
    TOUR[1] = { "add", total, total }
  end
  for k = 1, RANDOM_N do
    if WAY == "add" then
      local x = math.random(1, 99999)
      if total + x > 9999999 then break end
      total = total + x
      TOUR[#TOUR + 1] = { "add", x, total }
    elseif WAY == "subtract" then
      if total < 1 then break end
      local x = math.random(1, math.min(total, 99999))
      total = total - x
      TOUR[#TOUR + 1] = { "sub", x, total }
    else
      local a, b
      if k % 2 == 0 then a, b = math.random(1, 9999), math.random(1, 9) else a, b = math.random(1, 99), math.random(1, 99) end
      TOUR[#TOUR + 1] = { "mul", a, b, a * b }
    end
  end
end
local touring = nil
local function tourStart()
  touring, fails = 1, 0
  print("\nTHE SUANPAN -- the tour: " .. TOUR_SAYS[WAY])
  if reading() ~= 0 and WAY ~= "multiply" then clearAll() end
end
local function tourNext()
  if not touring or not idle() then return end
  if touring > #TOUR then
    touring = nil
    local last = TOUR[#TOUR]
    print("RESULT suanpan " .. (WAY == "add" and "" or (WAY .. " ")) .. "tour: " ..
          (fails == 0 and reading() == last[#last] and "PASS" or "FAIL"))
    show(slate.rule, READY)
    return
  end
  local t = TOUR[touring]
  touring = touring + 1
  queue[#queue + 1] = { wait = touring == 2 and 0.3 or 1.2 }
  if t[1] == "add" then addNumber(t[2], t[3])
  elseif t[1] == "sub" then subNumber(t[2], t[3])
  else multiply(t[2], t[3], t[4]) end
end

-- ---------------------------------------------------------------------
-- stepping, and resting when nothing moves
-- ---------------------------------------------------------------------
local REST_S, REST_V = 0.5, 0.05
local REST_ON = os.getenv("SU_REST") ~= "0"
local restFor, resting = 0, false
local function moving()
  for _, b in ipairs(allBeads) do if b.body:getLinearVelocity():length() > REST_V then return true end end
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
  if holdNow then return end
  if not started then
    started = true
    local n = envnum("SU_ADD", 0)
    if n > 0 then addNumber(n) end
    if (os.getenv("SU_TOUR") or "1") ~= "0" then tourStart() end
  end
  -- (the finger home: a job of its own)
  if job and job.phase == "home" then
    job.t = job.t + FRAME_DT
    local u = math.min(1, job.t / 0.4)
    local w = ease(u)
    local a = job.from
    placeFinger(btVector3(lerp(a.x, REST.x, w), lerp(a.y, REST.y, w) + 1.5 * math.sin(math.pi * u), lerp(a.z, REST.z, w)))
    if u >= 1 then job = nil end
  else
    stepJob(FRAME_DT)
  end
  tourNext()
  restPost()
end)

-- ---------------------------------------------------------------------
-- keys, help, hover
-- ---------------------------------------------------------------------
local function showEntry()
  if WAY == "multiply" then showText(slate.b, entry) else showNumber(slate.b, tonumber(entry), true) end
end
local function typed(d)
  touring = nil
  if #entry < ROD_N then
    if entry == "0" then entry = "" elseif entry:sub(-2) == "x0" then entry = entry:sub(1, -2) end
    entry = entry .. d
  end
  showEntry()
  show(slate.rule, READY)
end
for d = 0, 9 do v:addShortcut(tostring(d), function() typed(tostring(d)) end) end
local function enter()
  touring = nil
  local s = entry
  entry = ""
  if WAY == "multiply" then
    local a, b = s:match("^(%d+)x(%d+)$")
    a, b = tonumber(a), tonumber(b)
    if a and b and a > 0 and b > 0 then multiply(a, b)
    else print("  (type a number, X, and another: 36 X 4, then Return)"); showEntry() end
    return
  end
  local n = tonumber(s)
  if n and n > 0 then if WAY == "subtract" then subNumber(n) else addNumber(n) end end
end
v:addShortcut("Return", enter)
v:addShortcut("Enter", enter)
v:addShortcut("Backspace", function()
  entry = entry:sub(1, -2)
  showEntry()
end)
if WAY == "multiply" then
  local function times()
    if entry ~= "" and not entry:find("x") and #entry < ROD_N - 1 then entry = entry .. "x"; showEntry() end
  end
  v:addShortcut("X", times)
  v:addShortcut("*", times)
end
if WAY == "subtract" then
  local function addInstead()
    touring = nil
    local n = tonumber(entry)
    entry = ""
    if n and n > 0 then addNumber(n) end
  end
  v:addShortcut("A", addInstead)
  v:addShortcut("+", addInstead)
end
v:addShortcut("C", function() touring = nil; entry = ""; clearAll() end)
v:addShortcut("T", function() tourStart() end)
-- H (or F1): this exhibit's manual (MANUAL.pdf) in the PDF viewer; in the
-- hall, the hall's own H and F1 do it
if not hallPath then
  local MANUAL = dofile(DIR .. "../../open-manual.lua")
  for _, k in ipairs({ "H", "F1" }) do v:addShortcut(k, function() MANUAL.open(DIR, "the suanpan's manual") end) end
end
v:onParamChanged(function(N, name, value)
  if name == "speed" then applyTiming()
  elseif name == "friction" then applyFriction() end
end)
local HELP = {
  add = {
    "THE SUANPAN  (Babbage's Hall)",
    "",
    "KEYS",
    "  0 - 9  a number to add          Return  add it          Backspace  a digit off",
    "  C      clear the abacus         T       the tour",
    "",
    "The Chinese abacus. A bead counts when it is at the beam: a heaven bead",
    "(above) 5, an earth bead (below) 1. Each rod shows a digit, the units on the",
    "right. The slate shows the number on it, the one being added, the rod the",
    "hand is at, and the rule:",
    "  direct           room on the rod: beads to the beam",
    "  five-complement  no room among the earth beads: +3 = 5 - 2",
    "  ten-complement   the rod would pass 9: +8 = 10 - 2, and carry 1 left",
  },
  subtract = {
    "THE SUANPAN: SUBTRACTION  (Babbage's Hall)",
    "",
    "KEYS",
    "  0 - 9  a number                 Return  take it away    Backspace  a digit off",
    "  A      add it instead           C       clear           T          the tour",
    "",
    "Taking away is adding's rules backward, rod by rod from the left:",
    "  direct           enough on the rod: beads away from the beam",
    "  five-complement  not enough earth beads: -3 = -5 + 2, the heaven bead",
    "                   up and two earth beads up",
    "  ten-complement   not enough on the rod: -8 = -10 + 2, two earth beads up",
    "                   and borrow 1 from the rod on the left",
    "Taking 1 from 2000 borrows through three rods, to 1999.",
  },
  multiply = {
    "THE SUANPAN: MULTIPLICATION  (Babbage's Hall)",
    "",
    "KEYS",
    "  0 - 9  the numbers              X       times           Return  multiply",
    "  Backspace  a digit off          C       clear           T       the tour",
    "  (36 X 4 Return: up to 99 x 99, or 9999 x 9, on seven rods)",
    "",
    "Kojima's way. The multiplier goes on the rods at the left, the multiplicand",
    "to its right. Take the multiplicand's last digit times each digit of the",
    "multiplier, from its left: each product, from the times table, is two digits",
    "(3 x 2 is 06), added with its tens one rod to the right of the digit (two",
    "rods for the multiplier's second digit) and its units on the next. Then",
    "clear that digit and do the same with the one to its left. The product",
    "builds up on the rods at the right. The rods are A to G from the left.",
  },
}
pcall(function()
  local h = HELP[WAY]
  h[#h + 1] = ""
  h[#h + 1] = "The beads slide on their rods and push one another; friction holds them."
  h[#h + 1] = "The finger, the slate and the reading of the beads are the script's."
  h[#h + 1] = ""
  h[#h + 1] = "H: the manual (MANUAL.pdf, in your PDF viewer): reading the abacus, every rule"
  h[#h + 1] = "with pictures, multiplying, and making one."
  v:setHelpText(table.concat(h, "\n"))
end)
if v.onHover then
  local KEY = {}
  if objectKey then
    KEY[objectKey(frameObj)] = "the frame; across it the beam, the reckoning bar: a bead counts when it is at the beam"
    KEY[objectKey(rodsObj)] = "the rods, steel"
    KEY[objectKey(slateObj)] = "the slate: the number on the abacus, the one being added, and the rule the hand is using (the script's)"
    KEY[objectKey(fingerObj)] = "the operator's finger (the script's): it moves one bead, which pushes the others"
  end
  v:onHover(function(N, obj, x, y, z)
    local k = objectKey and objectKey(obj)
    local s = k and (KEY[k] or beadKey[k])
    if not s then return nil end
    return s .. string.format("\nThe abacus reads %d.", reading())
  end)
end

common.setCamera(btVector3(0, 28, AZ + 26), btVector3(0, 6.5, -3))
showNumber(slate.a, 0)
holdStart()
