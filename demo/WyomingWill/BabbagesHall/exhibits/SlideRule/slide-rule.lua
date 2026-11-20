--
-- The Slide Rule -- Babbage's Hall
--
-- Multiplying by adding lengths. On D, the number v stands log v of the
-- way along (25 cm for one decade); C, on the slide, is the same scale. Put
-- C's 1 over a on D and every number b on C stands over a x b on D: the
-- slide has added the two lengths, log a + log b = log ab. Edmund Gunter
-- drew the scale (1620) and added lengths with dividers; William Oughtred
-- slid two of them along each other (about 1622). This is a Mannheim rule,
-- as most were for a century: A, B for squares, CI (C backward) for
-- reciprocals, K for cubes, L for the logarithms themselves.
--
-- TWO WAYS (SR_WAY; in the hall, Tab steps through them)
--   multiply   (the default) type 2.5 X 3.2, or 7.5 / 2.5, and Return
--   powers     type a number, then S its square, R its square root, K its
--              cube, I its reciprocal, L its logarithm
--
-- KEYS
--   0 - 9 .    a number (shown on the slate)        Backspace  a figure off
--   C          close the rule (the slide home, the cursor to the left)
--   M          the camera close to the hairline, following it; again: back
--   T          the tour
--   H          the manual (MANUAL.pdf) in the PDF viewer
--
-- Each part is set against the other as it stands (C's 1 under the
-- hairline wherever the hairline is; the cursor to a mark on the slide
-- wherever the slide is), so an error in setting one is carried on.
--
-- PHYSICS: the slide and the cursor are bodies, each on a slider (the
-- slide's dovetail, the cursor's tongues in the stock's edges), held where
-- they are left by friction (a motor at no speed and a little force). The
-- operator's finger is the script's: it takes hold of one and moves it
-- until it stands where it should, as near as a steady hand can. Every
-- reading is taken from where the slide and the cursor are, as a person
-- reads it (three figures, four from 1 to 2 on C and D); the decimal point
-- is placed by an estimate, as a person does. The slate and the finger
-- are the script's (said so). 600 steps a second.
--
-- EVERY PART CAN BE PRINTED but the cursor's window (2 mm acrylic): the
-- scales are printed on paper (scales.pdf) and glued on. README.md.
--
-- Units: centimetres, kilograms, seconds.
-- Headless: SR_WAY (multiply, powers), SR_TOUR=0 (no tour), SR_LOG=1 (print
-- each move), SR_FRICTION (the slide in its groove, kg cm/s^2; the cursor
-- has 0.6 of it), SR_FINGER (the finger's speed, cm/s), SR_TOL (how near the
-- finger sets a part, cm), SR_HZ (steps a second), SR_RANDOM=n (n random
-- problems instead of the tour), SR_SEED.
--

local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end

-- ---------------------------------------------------------------------
-- this exhibit's folder; the parts file by its full path (for OpenSCAD)
-- ---------------------------------------------------------------------
local DIR
for _, d in ipairs({ "", "demo/WyomingWill/BabbagesHall/exhibits/SlideRule/" }) do
  local f = io.open(d .. "parts/slide-rule.scad", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "The Slide Rule: can't find its folder")
local R = dofile(DIR .. "rule.lua")
local SAYS = dofile(DIR .. "slate/says.lua")
local WAY = os.getenv("SR_WAY") or "multiply"
if WAY ~= "powers" then WAY = "multiply" end
local SCAD
do
  local path = DIR .. "parts/slide-rule.scad"
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
-- (a picture, by the path bpp opens it from)
local function pic(name)
  local p = DIR .. name .. ".png"
  if hallPath then p = hallPath(p) end
  return p
end

-- the rule's sizes (cm), as in slide-rule.scad
local L = R.L                                  -- 25: one decade of C and D
local X0, X1 = -2, 27                          -- the stock's and the slide's ends
local YA, YS, YB = 1.9, 0.9, -2.7              -- the faces' edges across: upper stator, slide, lower stator
local ZB, ZC, CLR = -0.8, -0.45, 0.02
local CZ0, CZ1, CW = 0.06, 0.36, 1.5           -- the cursor's front plate; its half width
local TILT = 25                                -- the face, from level
local H0 = 0.8 + 2.7 * math.sin(math.rad(TILT)) + 0.8 * math.cos(math.rad(TILT))
local Y0 = -3.0                                -- (the table's frame: y away from you, z up)
local SLATE_Y = 6.0
local OX = -12.5                               -- the rule's 0, left of the table's middle: the scales centred
local FOOT_X = { 1.6, 23.4 }

-- ---------------------------------------------------------------------
-- sliders, timing, the pause at every start
-- ---------------------------------------------------------------------
v:addParam("friction", envnum("SR_FRICTION", 50), 5, 200, 5, "the slide in its groove: the force it takes to move it, kg cm/s^2 (100 is 1 N); the cursor 0.6 of it")
v:addParam("finger", envnum("SR_FINGER", 6), 1, 15, 0.5, "how fast the finger moves the slide or the cursor, cm/s")
v:addParam("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second")
local TOL = envnum("SR_TOL", 0.002)            -- cm: how near the finger sets a part (0.02 mm)
local HZ = envnum("SR_HZ", 600)
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
-- where things are. The parts file's table frame (x along the rule, y
-- away from you, z up) is the hall's (x, z, -y); the rule's own frame (x
-- along it, y across its face, z out of it) is tilted TILT toward you.
-- ---------------------------------------------------------------------
local ident = btQuaternion(0, 0, 0, 1)
local function qa(ax, ay, az, deg) return btQuaternion(btVector3(ax, ay, az), math.rad(deg)) end
local Q = qa(1, 0, 0, -90)                     -- the table frame to the hall's
local RQ = Q * qa(1, 0, 0, TILT)               -- the rule's frame to the hall's
local cT, sT = math.cos(math.rad(TILT)), math.sin(math.rad(TILT))
-- (a point in the rule's frame, in the hall's)
local function RW(x, y, z)
  local ty, tz = Y0 + y * cT - z * sT, H0 + y * sT + z * cT
  return btVector3(OX + x, tz, -ty)
end
local NORMAL = btVector3(0, cT, sT)            -- the face's normal, in the hall
local SZ = -SLATE_Y                            -- the slate's face

local TABLE
do
  local path, f = DIR .. "../../exhibit-table.lua"
  if setfenv then f = assert(loadfile(path)); setfenv(f, getfenv(1))
  else f = assert(loadfile(path, "t", _ENV)) end
  TABLE = f()
end
TABLE.build(40, 16, { z = -1, floor = 300 })   -- (the rule and the slate; the slide runs out past them)

local function still(call, col, tr)
  local m = part(call)
  m.col = col
  v:add(m)
  m.trans = tr or btTransform(Q, btVector3(0, 0, 0))
  return m
end
local ruleTr = btTransform(RQ, RW(0, 0, 0))
local stockObj = still("stock()", "#c9a46c", ruleTr)            -- (boxwood)
local feet = {}
for k, x in ipairs(FOOT_X) do
  feet[k] = still(string.format("translate([%g, 0, 0]) foot(%g)", OX * 10, x * 10), "#6b4423")
end
local slateTr = btTransform(Q, btVector3(0, 0, SZ))
local slateObj = still("slate()", "#22282a", slateTr)
local slateFrame = still("slateFrame()", "#6b4423", slateTr)
-- (the stock's faces: the scales, on paper, as pictures)
local function face(name, y0, y1, follow)
  local c = Cube(X1 - X0, y1 - y0, 0.01, 0)
  c.collides = false
  c.tex = pic("scales/face-" .. name)
  v:add(c)
  local off = btVector3((X0 + X1) / 2, (y0 + y1) / 2, 0.006)
  c.trans = btTransform(RQ, RW(off.x, off.y, off.z))
  return c, off
end
local upperFace = face("upper", YS, YA)
local lowerFace = face("lower", YB, -YS)

-- ---------------------------------------------------------------------
-- the slide and the cursor: each a body on a slider, held by friction
-- ---------------------------------------------------------------------
local anchor = Cube(0.01, 0.01, 0.01, 0)       -- (only for the sliders to hold to)
anchor.collides = false
v:add(anchor)
anchor.trans = btTransform(ident, btVector3(0, 0, 0))
local QZ = ident                               -- (a slider's axis is its frame's x: along the rule already)
local function mover(call, col, mass, half, com, lo, hi)
  local obj = part(string.format("translate([%g, %g, %g]) %s", -com[1] * 10, -com[2] * 10, -com[3] * 10, call))
  obj.col = col
  local tr = btTransform(RQ, RW(com[1], com[2], com[3]))
  local shape = btBoxShape(btVector3(half[1], half[2], half[3]))
  local inertia = btVector3(mass * (half[2] ^ 2 + half[3] ^ 2) / 3, mass * (half[1] ^ 2 + half[3] ^ 2) / 3,
                            mass * (half[1] ^ 2 + half[2] ^ 2) / 3)
  local b = btRigidBody(mass, btDefaultMotionState(tr), shape, inertia)
  obj.body = b
  v:add(obj)
  obj.trans = tr
  b:setCenterOfMassTransform(tr)
  b:setActivationState(4)
  local c = btSliderConstraint(anchor.body, b, btTransform(RQ, RW(com[1], com[2], com[3])), btTransform(QZ, btVector3(0, 0, 0)), true)
  c:setLowerLinLimit(lo); c:setUpperLinLimit(hi)
  c:setLowerAngLimit(0); c:setUpperAngLimit(0)
  c:setPoweredLinMotor(true); c:setTargetLinMotorVelocity(0)
  v:addConstraint(c)
  return { obj = obj, body = b, c = c, com = com, mass = mass }
end
-- the slide: PLA, 23.1 cm^3, 29 g; its middle; out a scale's length either way
local slide = mover("slide()", "#f2ecd8", 0.029, { (X1 - X0) / 2, 0.95, 0.21 }, { (X0 + X1) / 2, 0, -0.21 }, -L - 0.2, L + 0.2)
-- the cursor: its frame (2.2 cm^3 of PLA) and its acrylic window (2.4 cm^3), 5.5 g; the hairline at its x = 0
local cursor = mover("cursorFrame()", "#8a9096", 0.0055, { CW, 2.5, 0.35 }, { 0, -0.4, 0.1 }, -0.5, L + 0.5)
slide.name, cursor.name = "slide", "cursor"
-- (drawn with them, moved to where they are each frame: the slide's scales,
-- the cursor's window and its hairline)
local slideFace = Cube(X1 - X0, 2 * YS - 2 * CLR, 0.01, 0)
slideFace.collides = false
slideFace.tex = pic("scales/face-slide")
v:add(slideFace)
local windowObj = part("cursorWindow()")
windowObj.col = "#d8eef0"
windowObj.transparency = 0.8
v:add(windowObj)
local hairObj = part("hairline()")
hairObj.col = "#c0161a"
v:add(hairObj)
pcall(function() v.showConstraints = false end)
local function applyFriction()
  local f = v:getParam("friction")
  if not slide.held then slide.c:setMaxLinMotorForce(f) end
  if not cursor.held then cursor.c:setMaxLinMotorForce(0.6 * f) end
end
applyFriction()
-- where they are: the slide's left index right of D's; the hairline from D's 1
local function slideAt() return slide.c:getLinearPos() end
local function cursorAt() return cursor.c:getLinearPos() end
local function follow()
  local s, c = slideAt(), cursorAt()
  slideFace.trans = btTransform(RQ, RW(s + (X0 + X1) / 2, 0, 0.006))
  local tr = btTransform(RQ, RW(c, 0, 0))
  windowObj.trans = tr
  hairObj.trans = tr
end
follow()

-- ---------------------------------------------------------------------
-- the slate: pictures swapped in (make-slate.py made them)
-- ---------------------------------------------------------------------
local HIDE = btVector3(0, 10, SZ - 3)          -- (behind the slate: a glyph not in use)
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
-- a row of glyphs: each place has a wide tile and a narrow one (the point,
-- the small 2 and 3), the one not used put away behind the slate
local GLYPH = { ["."] = "point", x = "times", d = "div", ["="] = "eq", ["~"] = "approx", q = "sq", c = "cube",
                r = "root", s = "slash", l = "log", ["-"] = "minus" }
local NARROW = { ["."] = true, q = true, c = true }
local GW, GN, GH = 1.0, 0.6, 1.3
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
      x = x + width + 0.04
    end
  end
end
-- (the slate's board: 34 cm across, from 2 to 14 cm up)
local slate = {}
slate.op = tile(7.4, 1.3, -12.6, 12.6, "label-" .. (WAY == "multiply" and "multiply" or "square"))
slate.problem = glyphRow(12, -8.4, 12.6)
slate.say = tile(32, 3.2, 0, 9.8, "say-ready-" .. WAY)
slate.readsL = tile(7.4, 1.3, -12.6, 6.5, "label-reads")
slate.reads = glyphRow(8, -8.4, 6.5)
slate.aboutL = tile(3.2, 1.3, 2.0, 6.5, "label-about-none")
slate.about = glyphRow(12, 3.9, 6.5)
slate.answerL = tile(7.4, 1.3, -12.6, 4.0, "label-answer")
slate.answer = glyphRow(10, -8.4, 4.0)
local function clearResult()
  showGlyphs(slate.reads, ""); showGlyphs(slate.about, ""); showGlyphs(slate.answer, "")
  show(slate.aboutL, "label-about-none")
end

-- ---------------------------------------------------------------------
-- the finger: takes hold of the slide or the cursor and moves it, until
-- it stands where it should; between, it lifts and moves over
-- ---------------------------------------------------------------------
local fingerObj = part("finger()")
fingerObj.col = "#e0b896"
v:add(fingerObj)
local FQ = RQ * qa(0, 0, 1, -35) * qa(0, 1, 0, 60)   -- (pressing on the face, the hand low, to the right and toward you)
local REST = RW(29.5, -0.5, 2.5)
local fingerAt = REST
local function placeFinger(p) fingerAt = p; fingerObj.trans = btTransform(FQ, p) end
placeFinger(REST)
-- where it presses: on the cursor's frame above the window; on the slide
-- near whichever end is farther from the hairline
local function tipOn(m, x)
  if m == cursor then return RW(x, 2.0, CZ1 + 0.7) end
  local c = cursorAt()
  local lx = (math.abs(x + X1 - 1.5 - c) > math.abs(x + X0 + 1.5 - c)) and (X1 - 1.5) or (X0 + 1.5)
  return RW(x + lx, 0, 0.7)
end
local function lerp(a, b, t) return a + (b - a) * t end
local function ease(t) return t * t * (3 - 2 * t) end
local function vlerp(a, b, t) return btVector3(lerp(a.x, b.x, t), lerp(a.y, b.y, t), lerp(a.z, b.z, t)) end

local queue = {}           -- what is left: { say = key } { move = part, st = a plan's step } { wait = s } { call = fn }
local job                  -- the one being done
local LOG = os.getenv("SR_LOG")
local planned = { slide = 0, cursor = 0 }      -- (where the parts will be when the queue is done)
local target = { slide = 0, cursor = 0 }       -- (where the last move of each was meant to put it)
local function startJob()
  local q = table.remove(queue, 1)
  if not q then job = nil; return end
  if q.say then
    show(slate.say, "say-" .. q.say)
    local w = SAYS[q.say]
    if w then print(string.format("  %s   (%s)", w[1], w[2])) end
    job = { wait = q.waitS or 1.1 }
    return
  end
  if q.wait then job = { wait = q.wait }; return end
  if q.call then job = nil; q.call(); if not job then job = { wait = 0 } end; return end
  -- (where to: against where the other part stands now, as a person sets it)
  local m = q.move
  local x0 = m.c:getLinearPos()
  local to = R.target(q.st, slideAt(), cursorAt())
  target[m.name] = to
  if math.abs(to - x0) < TOL then job = { wait = 0 }; return end
  local tip = tipOn(m, x0)
  job = { m = m, target = to, phase = "over", t = 0, from = fingerAt, tip = tip,
          above = tip + NORMAL * 2.5, tmax = math.abs(to - x0) / v:getParam("finger") + 4 }
  if LOG then print(string.format("  move the %s from %.4f to %.4f cm", m.name, x0, to)) end
end
local function release(m)
  m.held = false
  m.c:setTargetLinMotorVelocity(0)
  m.c:setMaxLinMotorForce(m == slide and v:getParam("friction") or 0.6 * v:getParam("friction"))
end
-- each simulation step: the held part steered to its place, faster the
-- farther it has to go, at most the finger's speed
local GAIN = 10
local function steer()
  local j = job
  if not (j and j.m and j.phase == "push") then return end
  local m = j.m
  local err = j.target - m.c:getLinearPos()
  local vmax = v:getParam("finger")
  m.c:setTargetLinMotorVelocity(math.max(-vmax, math.min(vmax, GAIN * err)))
  m.c:setMaxLinMotorForce(400)
  m.held = true
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
  if j.phase == "over" then                    -- (up, over, and down onto the part)
    local u = math.min(1, j.t / 0.5)
    local lift = j.from + NORMAL * 2.5
    if u < 0.75 then placeFinger(vlerp(lift, j.above, ease(u / 0.75)))
    else placeFinger(vlerp(j.above, j.tip, ease((u - 0.75) / 0.25))) end
    if u >= 1 then j.phase, j.t, j.held = "push", 0, 0 end
  elseif j.phase == "push" then                -- (the part moved, the finger with it)
    local x = j.m.c:getLinearPos()
    placeFinger(j.tip + btVector3(x - (j.x0 or x), 0, 0))
    j.x0 = j.x0 or x
    if j.m == cursor then placeFinger(tipOn(cursor, x)) end
    if math.abs(j.target - x) < TOL then j.held = j.held + dt else j.held = 0 end
    if j.held > 0.08 or j.t > j.tmax then
      if j.t > j.tmax then print(string.format("  (the %s stopped %.3f mm short)", j.m.name, 10 * (j.target - x))) end
      release(j.m)
      j.phase, j.t, j.from = "off", 0, fingerAt
    end
  elseif j.phase == "off" then                 -- (lifted off, and back beside the rule, out of the way)
    local u = math.min(1, j.t / 0.15)
    placeFinger(j.from + NORMAL * (1.2 * ease(u)))
    if u >= 1 then j.phase, j.t, j.from = "home", 0, fingerAt end
  elseif j.phase == "home" then
    local u = math.min(1, j.t / 0.5)
    placeFinger(vlerp(j.from, REST, ease(u)) + btVector3(0, 1.5 * math.sin(math.pi * u), 0))
    if u >= 1 then job = nil; startJob() end
  end
end
local function idle() return job == nil and #queue == 0 end

-- ---------------------------------------------------------------------
-- working a problem: the moves, then the reading, checked
-- ---------------------------------------------------------------------
local fails, worked = 0, 0
local OPLABEL = { x = "multiply", d = "divide", q = "square", r = "root", c = "cube", i = "recip", l = "log" }
local function push(q) queue[#queue + 1] = q end
local function pushSteps(steps)
  for _, st in ipairs(steps) do
    if st.say then push({ say = st.say }) end
    if st.part then
      push({ move = st.part == "slide" and slide or cursor, st = st })
      planned[st.part] = R.target(st, planned.slide, planned.cursor)
    end
  end
end
-- (the reading: from where the parts are; the slate and the console)
local function readIt(p)
  local s, c = slideAt(), cursorAt()
  local r = R.check(p, c, s)
  worked = worked + 1
  if not r.ok then fails = fails + 1 end
  showGlyphs(slate.reads, R.text(r.seen, r.figs, r.decs))
  local est = R.estimateText(p)
  show(slate.aboutL, est ~= "" and "label-about" or "label-about-none")
  showGlyphs(slate.about, est)
  showGlyphs(slate.answer, r.text)
  show(slate.say, r.ok and "say-right" or "say-wrong")
  -- (how far each part stands from where its last move meant to put it)
  local ds, dc = 10 * (s - target.slide), 10 * (c - target.cursor)
  print(string.format("  %s reads %s, so %s   (true: %.6g%s; the slide %.3f mm, the hairline %.3f mm from their places)",
        p.read, R.text(r.seen, r.figs, r.decs), r.text, p.exact, r.ok and "" or "  -- WRONG", ds, dc))
end
local function work(p, label)
  push({ call = function()
    show(slate.op, "label-" .. (label or OPLABEL[p.what]))
    showGlyphs(slate.problem, R.problem(p))
    clearResult()
    print(string.format("%s", (R.problem(p):gsub("x", " x "):gsub("d", " / "):gsub("q", " squared")
      :gsub("^r", "square root of "):gsub("^1s", "1 / "):gsub("c$", " cubed"):gsub("^l", "log "))))
  end })
  pushSteps(p.steps)
  push({ call = function() readIt(p) end })
  push({ wait = 2.0 })
end
local function workTable(t)
  push({ call = function()
    show(slate.op, "label-table")
    showGlyphs(slate.problem, string.format("%gx", t.a))
    clearResult()
    print(string.format("A TABLE: %g times %s, at one setting", t.a, table.concat(t.bs, ", ")))
  end })
  pushSteps(t.steps)
  for _, it in ipairs(t.items) do
    push({ call = function() showGlyphs(slate.problem, R.problem(it)); clearResult() end })
    pushSteps(it.steps)
    push({ call = function() readIt(it) end })
    push({ wait = 2.0 })
  end
end
local function close()
  push({ say = "close", waitS = 0.6 })
  push({ move = slide, st = { x = 0 } }); planned.slide = 0
  push({ move = cursor, st = { x = 0 } }); planned.cursor = 0
end
local function home()
  push({ call = function() job = { phase = "home", t = 0, from = fingerAt } end })
end

-- the tours: each step using a scale or a way of its own
local TOURS = {
  multiply = {
    { "x", 2, 3 }, { "x", 1.5, 4.5 }, { "x", 3, 4 }, { "d", 7.5, 2.5 }, { "d", 2, 8 }, { "x", 0.25, 36 },
    { "t", 1.609, { 2, 3, 5 } },
  },
  powers = { { "q", 3 }, { "r", 2 }, { "r", 20 }, { "c", 2 }, { "i", 4 }, { "l", 2 } },
}
local TOUR_SAYS = {
  multiply = "2 x 3, 1.5 x 4.5, 3 x 4 (by C's right index), 7.5 / 2.5, 2 / 8, 0.25 x 36, and a table: 1.609 x 2, 3 and 5 at one setting",
  powers = "3 squared, the square roots of 2 and 20, 2 cubed, 1 / 4 and log 2",
}
local TOUR = TOURS[WAY]
local RANDOM_N = envnum("SR_RANDOM", 0)
if RANDOM_N > 0 then
  math.randomseed(envnum("SR_SEED", 1))
  TOUR = {}
  local function rnd() return math.random(100, 999) / 100 * 10 ^ math.random(-1, 1) end
  for k = 1, RANDOM_N do
    if WAY == "multiply" then TOUR[k] = { k % 2 == 0 and "d" or "x", rnd(), rnd() }
    else TOUR[k] = { ({ "q", "r", "c", "i", "l" })[math.random(1, 5)], rnd() } end
  end
end
local function plan(t)
  if t[1] == "x" then return R.multiply(t[2], t[3])
  elseif t[1] == "d" then return R.divide(t[2], t[3])
  elseif t[1] == "q" then return R.square(t[2], planned.slide)
  elseif t[1] == "r" then return R.root(t[2], planned.slide)
  elseif t[1] == "c" then return R.cube(t[2], planned.slide)
  elseif t[1] == "i" then return R.reciprocal(t[2], planned.slide)
  elseif t[1] == "l" then return R.logarithm(t[2], planned.slide) end
end
local function workOne(t)
  if t[1] == "t" then
    local tb = R.table(t[2], t[3])
    if tb then workTable(tb) else print("  (not all on the rule at one setting)") end
  else
    local p = plan(t)
    if p.steps[1].say == "close" then planned.slide = 0 end
    work(p)
  end
end
local touring = nil
local function tourStart()
  touring, fails, worked = 1, 0, 0
  print("\nTHE SLIDE RULE -- the tour: " .. (RANDOM_N > 0 and (RANDOM_N .. " random problems") or TOUR_SAYS[WAY]))
  queue, job = {}, nil
  for _, m in ipairs({ slide, cursor }) do if m.held then release(m) end end
  planned.slide, planned.cursor = slideAt(), cursorAt()
end
local frame = 0
local function tourNext()
  if not touring or not idle() then return end
  if touring > #TOUR then
    touring = nil
    print(string.format("RESULT slide rule %stour: %s  (%d readings, %d wrong; frame %d)", WAY == "multiply" and "" or "powers ",
          (fails == 0 and worked > 0) and "PASS" or "FAIL", worked, fails, frame))
    home()
    return
  end
  local t = TOUR[touring]
  touring = touring + 1
  push({ wait = touring == 2 and 0.3 or 0.8 })
  workOne(t)
end

-- ---------------------------------------------------------------------
-- stepping, and resting when nothing moves
-- ---------------------------------------------------------------------
local REST_S, REST_V = 0.5, 0.01
local REST_ON = os.getenv("SR_REST") ~= "0"
local restFor, resting = 0, false
local function moving()
  return slide.body:getLinearVelocity():length() > REST_V or cursor.body:getLinearVelocity():length() > REST_V
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

-- the camera close to the hairline (M), following it. It stands 30 cm off
-- with a narrow view (in the hall, a 42 m scene, bpp clips anything nearer
-- than about 21 cm); upright, which down onto the tilted face puts the
-- scales the right way up, here and in a bay turned any way. bpp leaves
-- the field of view at QGLViewer's pi/4: put back on M again, or on leaving.
local MAG_D, MAG_FOV, FOV = 30, 0.36, math.pi / 4
local magnify = nil
local function magnifyView()
  local look = RW(cursorAt(), -0.9, 0)
  local cam = v.cam
  cam:setUpVector(btVector3(0, 1, 0), true)
  cam.pos = look + NORMAL * MAG_D
  cam.look = look
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
  if magnify then magnifyView() end
  if holdNow then return end
  if not started then
    started = true
    if (os.getenv("SR_TOUR") or "1") ~= "0" then tourStart() end
  end
  stepJob(FRAME_DT)
  tourNext()
  restPost()
end)

-- ---------------------------------------------------------------------
-- keys, help, hover
-- ---------------------------------------------------------------------
local entry = ""            -- what is being typed: numbers, x or / between
local function showEntry()
  showGlyphs(slate.problem, (entry:gsub("/", "d")))
end
local function stopTour() touring = nil end
local function typed(ch)
  stopTour()
  if #entry < 12 then entry = entry .. ch end
  showEntry()
  show(slate.say, "say-ready-" .. WAY)
  clearResult()
end
for d = 0, 9 do v:addShortcut(tostring(d), function() typed(tostring(d)) end) end
v:addShortcut(".", function() typed(".") end)
v:addShortcut("Backspace", function() entry = entry:sub(1, -2); showEntry() end)
if WAY == "multiply" then
  local function op(ch) if entry ~= "" and not entry:find("[x/]") then typed(ch) end end
  v:addShortcut("X", function() op("x") end)
  v:addShortcut("*", function() op("x") end)
  v:addShortcut("/", function() op("/") end)
  local function enter()
    stopTour()
    local a, o, b = entry:match("^([%d%.]+)([x/])([%d%.]+)$")
    a, b = tonumber(a), tonumber(b)
    entry = ""
    if a and b and a > 0 and b > 0 then
      planned.slide, planned.cursor = slideAt(), cursorAt()
      workOne({ o == "x" and "x" or "d", a, b })
    else print("  (type a number, X or /, and another: 2.5 X 3.2, then Return)"); showEntry() end
  end
  v:addShortcut("Return", enter)
  v:addShortcut("Enter", enter)
else
  local function op(what)
    stopTour()
    local a = tonumber(entry)
    entry = ""
    if a and a > 0 then
      planned.slide, planned.cursor = slideAt(), cursorAt()
      workOne({ what, a })
    else print("  (type a number first, then S, R, K, I or L)"); showEntry() end
  end
  v:addShortcut("S", function() op("q") end)
  v:addShortcut("R", function() op("r") end)
  v:addShortcut("K", function() op("c") end)
  v:addShortcut("I", function() op("i") end)
  v:addShortcut("L", function() op("l") end)
end
v:addShortcut("C", function() stopTour(); entry = ""; close(); home() end)
v:addShortcut("T", function() tourStart() end)
-- H: this exhibit's manual (MANUAL.pdf) in the PDF viewer; in the hall,
-- the hall's own H does it
if not hallPath then
  local MANUAL = dofile(DIR .. "../../open-manual.lua")
  v:addShortcut("H", function() MANUAL.open(DIR, "the slide rule's manual") end)
end
local camBack = nil
local function magnifyOff(putBack)
  if not magnify then return end
  magnify = nil
  local cam = v.cam
  pcall(function() cam:setFieldOfView(FOV) end)
  cam:setUpVector(btVector3(0, 1, 0), true)
  if putBack and camBack then cam.pos = camBack.pos; cam.look = camBack.look end
  camBack = nil
end
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
-- (in the hall: walking away puts the field of view back)
pcall(function() v:onLeave(function() magnifyOff(false) end) end)
v:onParamChanged(function(N, name, value)
  if name == "speed" then applyTiming()
  elseif name == "friction" then applyFriction() end
end)
local HELP = {
  multiply = {
    "THE SLIDE RULE  (Babbage's Hall)",
    "",
    "KEYS",
    "  0 - 9 .  a number      X  times      /  divided by      Return  work it",
    "  Backspace  a figure off      C  close the rule      T  the tour",
    "  M  the camera close to the hairline, following it; again: back",
    "  H  the manual (MANUAL.pdf, in your PDF viewer)",
    "",
    "On D the number v stands log v of the way along; C on the slide is the",
    "same. C's 1 over a puts every b on C over a x b on D: the slide adds",
    "the lengths, log a + log b = log ab. If b would run off the end, C's",
    "10 goes over a instead. To divide, b on C over a, and a / b is on D",
    "under C's index. The rule gives three figures; an estimate places the",
    "point (2.5 x 3.2: about 3 x 3 = 9, so 8.00, not 0.800 or 80.0).",
  },
  powers = {
    "THE SLIDE RULE: SQUARES, ROOTS, CUBES, LOGARITHMS  (Babbage's Hall)",
    "",
    "KEYS",
    "  0 - 9 .  a number, then  S its square   R its square root   K its cube",
    "                           I its reciprocal   L its logarithm",
    "  Backspace  a figure off      C  close the rule      T  the tour",
    "  M  the camera close to the hairline, following it; again: back",
    "  H  the manual (MANUAL.pdf, in your PDF viewer)",
    "",
    "The hairline reads every scale at once. A is D squared (two decades in",
    "the length of one), K is D cubed (three), CI is C backward (1 / x), L",
    "is even (the logarithm itself). A square root: x on A, its left half if",
    "x has an odd number of figures before the point, else the right; the",
    "root on D.",
  },
}
pcall(function()
  local h = HELP[WAY]
  h[#h + 1] = ""
  h[#h + 1] = "The slide and the cursor are bodies on sliders (the sliders are the grooves:"
  h[#h + 1] = "the parts don't touch), held by friction; the finger moves one at a time,"
  h[#h + 1] = "each against the other as it stands. The finger, the slate, the reading and"
  h[#h + 1] = "the estimate that places the point are the script's."
  v:setHelpText(table.concat(h, "\n"))
end)
if v.onHover then
  local KEY = {}
  if objectKey then
    KEY[objectKey(stockObj)] = "the stock: A above the slide; D, K and L below it (paper scales on printed boxwood)"
    KEY[objectKey(upperFace)] = "A: squares, two decades in a scale's length (1 to 100)"
    KEY[objectKey(lowerFace)] = "D: the number v at log v of the way along; K below it: cubes; L: logarithms"
    KEY[objectKey(slide.obj)] = "the slide: B (squares), CI (C backward, in red: reciprocals) and C"
    KEY[objectKey(slideFace)] = "the slide: B (squares), CI (C backward, in red: reciprocals) and C"
    KEY[objectKey(cursor.obj)] = "the cursor: its hairline reads every scale at once"
    KEY[objectKey(windowObj)] = "the cursor's window, acrylic, its hairline scribed in red"
    KEY[objectKey(slateObj)] = "the slate (the script's): the problem, the step, what the rule reads, the estimate that places the point"
    KEY[objectKey(fingerObj)] = "the operator's finger (the script's): it moves the slide or the cursor"
    for _, f in ipairs(feet) do KEY[objectKey(f)] = "a foot: the rule lies on two, tilted 25 degrees toward you" end
  end
  v:onHover(function(N, obj, x, y, z)
    local k = objectKey and objectKey(obj)
    local s = k and KEY[k]
    if not s then return nil end
    local sAt, cAt = slideAt(), cursorAt()
    local function r(sc) local val = R.read[sc](cAt, sAt); local f, d = R.figures(sc, val); return R.text(R.round(val, f, d), f, d) end
    return s .. string.format("\nUnder the hairline: D %s, C %s, A %s, K %s, L %s. The slide stands %.1f mm %s.",
      r("D"), (cAt - sAt >= 0 and cAt - sAt <= L) and r("C") or "-", r("A"), r("K"), r("L"),
      math.abs(10 * sAt), sAt >= 0 and "right" or "left")
  end)
end

common.setCamera(btVector3(0, 19, 31), btVector3(0, 5, -1.5))
holdStart()
