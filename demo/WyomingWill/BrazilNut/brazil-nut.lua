--
-- The Brazil-Nut Effect, in real glass -- Euler's Cabinet of Curiosities
--
-- Shake a jar of mixed nuts and the Brazil nuts come up to the top: the
-- biggest rise, though they're the heaviest. Here, two glass-fronted boxes
-- of real glass beads (a layer one bead thick, 280 beads, 20 cm deep) are
-- shaken up and down five times a second, a big glass bead at the bottom of
-- each. They differ only in their side walls:
--
--   left    lined with glass beads glued to them, as laboratories roughen
--           their walls: the bed turns over in two rolls, up the middle and
--           down the walls, and the big bead comes up within seconds and
--           stays up
--   right   smooth glass: the rolls turn the other way, up the walls and
--           down the middle, and the big bead stays down
--
-- They are shaken gently first (peak acceleration 0.8 g: nothing happens,
-- the bed never leaves the floor), then hard (3 g). A red bead in each box
-- shows which way the beads go round.
--
-- Why: shaken hard, the bed leaves the floor for part of each shake and
-- lands again. Rough walls hold back the beads beside them, so beads go down
-- along the walls and come up in the middle, and carry the big bead up with
-- them; at the top it's too big to follow the small beads down the narrow
-- stream by the walls. Smooth glass walls don't hold the beads back, and
-- the bed turns the other way. (J. B. Knight, H. M. Jaeger and S. R. Nagel,
-- Phys. Rev. Lett. 70, 3728 (1993): the big bead rises with the convection,
-- which the walls drive.)
--
-- THE BEADS: soda-lime glass, 0.95 to 1.05 cm across, bounce 0.95 and
-- friction 0.1 (between beads, and with the walls and the glued beads), the
-- big one 3 cm across and solid glass too. The boxes are 15 cm wide inside.
-- Shaken at 5 Hz: 8.0 mm for 0.8 g, 29.8 mm for 3 g.
--
-- PHYSICS: not Bullet. Bullet can't run beads this bouncy (in a packed bed
-- its restitution pumps energy in: see reconstruction/GLASS-DESIGN.md), so
-- each box is simulated by bpp's DemBed: soft spheres in contact by Hertz's
-- law with Mindlin's tangential spring and Coulomb friction, stepped in
-- microseconds, one thread per box -- the reference model of
-- reconstruction/, number for number. Bullet only draws them.
--
-- Keys
--   R   pour them again
--   Z   slow motion (1/4, the default) <-> real time
--
-- Units: centimetres, kilograms, seconds.
-- Needs bpp from 17 October 2026 or later (DemBed).
-- Headless testing: BN_SPEED, BN_SEED, BN_HARD, BN_GENTLE (g), BN_F (Hz),
-- BN_YM (Pa), BN_NS (steps per contact), BN_TIMING=1 (frame times).
--

local common = require "common"

local G = 981
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("hard", envnum("BN_HARD", 3.0), 1.5, 4, 0.1, "the peak acceleration after the opening, in g (from the next pour: R)")
param("speed", envnum("BN_SPEED", 0.25), 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")

local FRAME_DT = 0.25 / 60
local function applyTiming()
  FRAME_DT = v:getParam("speed") / 60
  v.animationPeriod = 16
  common.setTiming(FRAME_DT, 0, FRAME_DT)
end

-- ---------------------------------------------------------------------
-- a pause at every start: one frame to put everything in place, then it
-- all stands still for HOLD_S seconds (half a second), so you see how it
-- begins -- the beads' clock stopped too -- and then it carries on from
-- there, exactly as if there had been no pause
-- ---------------------------------------------------------------------
local HOLD_FRAMES = math.floor(envnum("HOLD_S", 0.5) * 60 + 0.5)
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

local Q0 = btQuaternion(0, 0, 0, 1)
local function block(sx, sy, sz, x, y, z, col)
  local c = Cube(sx, sy, sz, 0)
  c.trans = btTransform(Q0, btVector3(x, y, z))
  c.col = col
  c.collides = false
  v:add(c)
  return c
end
local function ball(r, x, y, col)
  local s = Sphere(r, 0)
  s.trans = btTransform(Q0, btVector3(x, y, 0))
  s.col = col
  s.collides = false
  v:add(s)
  return s
end

-- ---------------------------------------------------------------------
-- the shaker table and the boxes
-- ---------------------------------------------------------------------
local TABLE_Y = 0
block(100, 3, 40, 0, TABLE_Y - 1.5, 0, "#7a4a24")
for _, x in ipairs({ -45, 45 }) do
  for _, z in ipairs({ -16, 16 }) do block(3, 72, 3, x, TABLE_Y - 3 - 36, z, "#4e2e15") end
end
local floor = Plane(0, 1, 0, TABLE_Y - 75, 300)
floor.col = "#3b3f45"
v:add(floor)

local F_HZ = envnum("BN_F", 5)
local OMEGA = 2 * math.pi * F_HZ
local GENTLE = envnum("BN_GENTLE", 0.8)
local T_GENTLE, T_RAMP = 2, 1               -- gently for 2 s, then up to hard over 1 s
local T_HARD = T_GENTLE + T_RAMP
local W_IN, H_IN, WALL = 15, 44, 1.0        -- inside the box; its walls (the bed is 20 cm deep at rest; shaken hard, its top beads fly well above that)
local R_B = 1.5
local N_S = 280
local BASE_Y = TABLE_Y + 8                  -- the boxes' floors, at rest
local POUR_S = 50                           -- each pour runs 50 s
local BOXES = {
  { name = "Left, walls lined with glued glass beads", short = "Left", x = -19, rough = true },
  { name = "Right, smooth glass walls", short = "Right", x = 19, rough = false },
}

-- what each box is: the reference model's keys (reconstruction/bead-bed.c)
local function settings(bx, hard)
  return {
    MODEL = 1, YM = envnum("BN_YM", 6.3e8), NS = envnum("BN_NS", 40),   -- Hertz-Mindlin; the stiffness (see README)
    E = 0.95, MUB = 0.1, MUW = 0.1, MUG = 0.1,                          -- glass
    N = N_S, W = W_IN, H = H_IN, BOX = 1, RB = R_B,
    ROUGH = bx.rough and 1 or 0, RG = 0.5, SG = 1.0,                     -- 1-cm glass beads glued, touching, half-embedded
    F = F_HZ, GAMMA = hard, GAMMA0 = GENTLE, TG = T_GENTLE, TR = T_RAMP,
    SEED = envnum("BN_SEED", 7),
    GW1 = 3, GW2 = 10,                       -- the gentle push: shakes 4 to 10 (0.6 to 2 s)
    WATCH1 = 25, WATCH2 = 75,                -- the hard push: shakes 26 to 75 (5 to 15 s)
    CONVSTART = 8, CONVEND = 45,             -- the rolls: 8 to 45 s
    LATE0 = 25, LATE1 = 45,                  -- the big bead's height: 25 to 45 s
    RISE1 = 10, RISE2 = 12, RISEW = 2,       -- its rise: when its middle, averaged over 2 s, passes 10 and 12 cm
  }
end

-- the reference: these boxes run headless, four pours (BN_SEED 1, 2, 7, 8;
-- reconstruction/dembed-check, the same code): the lowest and highest of
-- each number (see README)
local REF = {
  Left = { push = { 0.18, 0.19 }, off = { 38, 40 }, landed = { 44, 46 }, rise = { 7.6, 10.6 },
           mid = { 5.9, 7.5 }, wall = { -13.8, -11.7 }, late = { 15.7, 16.3 }, up = { 81, 88 } },
  Right = { push = { 0.19, 0.19 }, off = { 40, 42 }, landed = { 44, 46 },
            mid = { -0.7, 0.4 }, wall = { 3.1, 4.0 }, late = { 7.9, 9.2 }, up = { 0, 0 } },
}

local GLASS, FRAME_COL = "#26343a", "#5a3418"     -- (the glass at the back drawn dark; the front pane left out)
local BEAD_COLS = { "#c4d8d2", "#b6cdc6", "#d0e2dc" }   -- clear glass, a little green
local GLUED_COL, BIG_COL, TRACER_COL = "#8fa9a2", "#2b5d8c", "#c0392b"

if not DemBed then
  -- an older bpp: the boxes stand empty, and the console says why
  for _, bx in ipairs(BOXES) do
    block(W_IN + 2 * WALL, WALL, 3, bx.x, BASE_Y - WALL / 2, 0, FRAME_COL)
    for _, s in ipairs({ -1, 1 }) do block(WALL, H_IN, 3, bx.x + s * (W_IN / 2 + WALL / 2), BASE_Y + H_IN / 2, 0, FRAME_COL) end
    block(W_IN, H_IN, 0.1, bx.x, BASE_Y + H_IN / 2, -1.3, GLASS)
  end
  local msg = "The Brazil-nut effect needs bpp from 17 October 2026 or later: its beads are\n" ..
              "simulated by bpp's DemBed, which this bpp hasn't got. Rebuild bpp to see it."
  print(msg)
  v:setHelpText(msg)
  common.setCamera(btVector3(0, 30, 88), btVector3(0, 24, 0))
  return
end

-- the boxes, drawn: a floor, two walls and the glass at the back, moved
-- with the shaker
for _, bx in ipairs(BOXES) do
  bx.parts = {
    { block(W_IN + 2 * WALL, WALL, 3, 0, 0, 0, FRAME_COL), 0, -WALL / 2, 0 },
    { block(WALL, H_IN, 3, 0, 0, 0, FRAME_COL), -(W_IN / 2 + WALL / 2), H_IN / 2, 0 },
    { block(WALL, H_IN, 3, 0, 0, 0, FRAME_COL), W_IN / 2 + WALL / 2, H_IN / 2, 0 },
    { block(W_IN, H_IN, 0.1, 0, 0, 0, GLASS), 0, H_IN / 2, -1.3 },
  }
  bx.post = block(3, BASE_Y - WALL - TABLE_Y, 3, bx.x, 0, 0, "#3a3f46")
end

-- ---------------------------------------------------------------------
-- pouring: a DemBed per box (the beads simulated in C++), its beads and
-- glued beads drawn by display-only spheres
-- ---------------------------------------------------------------------
local t = 0
local ahead = nil      -- the time the boxes are stepping on to, in their threads, while the last frame is drawn
local said
local function amplitude(g) return g * G / (OMEGA * OMEGA) end

local function pour()
  holdStart()
  local hard = v:getParam("hard")
  print(string.format("\n--- poured: %d glass beads a box, shaken at %d Hz: gently (%.1f g, %.1f mm) for %d s, then hard (%.1f g, %.1f mm) from %d s ---",
                      N_S, F_HZ, GENTLE, amplitude(GENTLE) * 10, T_GENTLE, hard, amplitude(hard) * 10, T_HARD))
  print(string.format("  Gamma %.1f: below 1 -- the bed should never leave the floor; Gamma %.1f: it should leave it %.1f degrees into each upswing (arcsin 1/Gamma), if it has landed by then",
                      GENTLE, hard, math.deg(math.asin(1 / hard))))
  for _, bx in ipairs(BOXES) do
    local bed = DemBed()
    for k, val in pairs(settings(bx, hard)) do bed:set(k, val) end
    bed:init()
    -- the tracer: the small bead nearest the top of the bed, 6 cm to the
    -- left of the middle (by the left wall, 1.5 cm in from it)
    local top = 0
    for i = 0, N_S - 1 do top = math.max(top, bed:y(i)) end
    local best, bi = 1e9, 0
    for i = 0, N_S - 1 do
      local d = (bed:x(i) + 6) ^ 2 + (bed:y(i) - top) ^ 2
      if d < best then best, bi = d, i end
    end
    bed:set("TRACER", bi)
    bx.bed, bx.tracer = bed, bi
    -- its beads: the display spheres made once, then handed to each new bed
    if not bx.shown then
      bx.shown = {}
      for i = 0, N_S do
        local r = bed:r(i)
        local col = i == N_S and BIG_COL or BEAD_COLS[i % 3 + 1]
        bx.shown[i] = ball(r, bx.x, BASE_Y + r, col)
      end
      bx.glued = {}
      for wall = 0, 2 do
        for k = 0, bed:gluedCount(wall) - 1 do
          bx.glued[#bx.glued + 1] = { wall, k, ball(0.5, bx.x, BASE_Y, GLUED_COL) }
        end
      end
    end
    for i = 0, N_S do
      bx.shown[i].col = i == N_S and BIG_COL or (i == bi and TRACER_COL or BEAD_COLS[i % 3 + 1])
      bed:attach(i, bx.shown[i])
    end
    for _, gl in ipairs(bx.glued) do bed:attachGlued(gl[1], gl[2], gl[3]) end
  end
  t = -0.5
  ahead = nil
  said = {}
end

-- the box's height: what the bed says (it moves the box itself)
local function drawBoxes()
  for _, bx in ipairs(BOXES) do
    local by = BASE_Y + bx.bed:boxY()
    for _, p in ipairs(bx.parts) do
      p[1].trans = btTransform(Q0, btVector3(bx.x + p[2], by + p[3], p[4]))
    end
    bx.post.trans = btTransform(Q0, btVector3(bx.x, (by - WALL + TABLE_Y) / 2, 0))
    bx.bed:sync(bx.x, BASE_Y, 0)
  end
end

local TIMING = os.getenv("BN_TIMING")
local wallSum, stepSum, nTimed, wallLast = 0, 0, 0, nil
-- both boxes at once, a thread each, on to the frame's end. The threads
-- are started as soon as a frame has been reported (in postSim), so they
-- step while bpp draws it; here they're waited for. (The same steps either
-- way: only when they're worked out changes.)
local function startBoxes()
  ahead = t + FRAME_DT
  for _, bx in ipairs(BOXES) do bx.bed:start(ahead) end
end
v:preSim(function(N_)
  if holdPre() then return end
  if not ahead then startBoxes() end
  if TIMING then stepSum = stepSum - demWallClock() end
  for _, bx in ipairs(BOXES) do bx.bed:finish() end
  if TIMING then stepSum = stepSum + demWallClock() end
end)

-- ---------------------------------------------------------------------
-- after every frame: draw, and report
-- ---------------------------------------------------------------------
local function range(r, fmt) return string.format(fmt .. " to " .. fmt, r[1], r[2]) end
local function once(key) if said[key] then return false end said[key] = true return true end

local function report()
  for _, bx in ipairs(BOXES) do
    local b, nm = bx.bed, bx.short
    -- gently: the floor's push, against a rigid bed's (1 - Gamma)
    if b:get("gphase") == 1 and once(nm .. "g") then
      local least, off = b:get("gleast"), b:get("goff")
      if off < 0 then
        print(string.format("  %-5s Gamma %.1f: the bed never left the floor (the floor's push never less than %.2f of its weight; a rigid bed's: %.2f; the reference: %s)",
                            nm, GENTLE, least, 1 - GENTLE, range(REF[nm].push, "%.2f")))
      else
        print(string.format("  %-5s Gamma %.1f: the bed left the floor %d degrees into the upswing (the floor's push least %.2f of its weight)", nm, GENTLE, off, least))
      end
    end
    -- the big bead coming up
    if b:get("rise2") > 0 and once(nm .. "r") then
      local r = b:get("rise2")
      local ref = REF[nm].rise
      print(string.format("  %-5s the big bead is up: its middle 12 cm above the floor (over 2 s) at %.1f s, %.1f s into the hard shaking%s",
                          nm, r, r - T_HARD, ref and string.format(" (the reference, 4 pours: %s s)", range(ref, "%.1f")) or ""))
    end
    -- hard: where the bed leaves the floor, and where it has landed
    if b:get("phase") == 1 and once(nm .. "p") then
      local hard = b:get("GAMMA")
      local off, landed, vdown = b:get("off"), b:get("landed"), b:get("vdown")
      local b19 = math.floor(math.deg(math.asin(math.min(1, 1 / hard))) / 2)
      local second
      if landed >= 0 and landed <= b19 * 2 then
        second = string.format("it had landed (its middle stopped coming down) by %d to %d", landed, landed + 2)
      else
        second = string.format("it can't till it has landed: at %d to %d degrees its middle is still coming down (%.0f cm/s); landed at %s",
                               b19 * 2, b19 * 2 + 2, vdown, landed >= 0 and string.format("%d to %d", landed, landed + 2) or "90 or later")
      end
      print(string.format("  %-5s Gamma %.1f: the bed leaves the floor %s into the upswing (a rigid bed: arcsin 1/Gamma = %.1f; the reference: %d to %d);\n        %s (the reference: landed at %d to %d)",
                          nm, hard, off >= 0 and string.format("%d to %d degrees", off, off + 2) or "never", math.deg(math.asin(1 / hard)),
                          REF[nm].off[1], REF[nm].off[2] + 2, second, REF[nm].landed[1], REF[nm].landed[2] + 2))
    end
    -- the rolls, and where the big bead has been since
    if b:get("late") == 1 and b:get("conv") == 1 and once(nm .. "c") then
      local mid, wall = b:get("mid"), b:get("wall")
      local ref = REF[nm]
      print(string.format("  %-5s from 8 s to 45 s: beads in the middle %s %.1f mm/s on average, beside the walls %s %.1f mm/s (the reference: %s / %s)",
                          nm, mid >= 0 and "rising" or "falling", math.abs(mid), wall >= 0 and "rising" or "falling", math.abs(wall),
                          range(ref.mid, "%+.1f"), range(ref.wall, "%+.1f")))
      print(string.format("  %-5s the big bead from 25 s to 45 s: its middle %.1f cm above the floor on average, never below %.1f; in the bed's upper half %.0f%% of the time (the reference: %s cm, %s%%)",
                          nm, b:get("lateMean"), b:get("lateMin"), b:get("up20") * 100, range(ref.late, "%.1f"), range(ref.up, "%.0f")))
      print(string.format("  %-5s the red bead, poured at the top by the left wall: lowest %.1f cm above the floor, at %.1f s, %.1f cm from the left wall",
                          nm, b:get("tracerMin"), b:get("tracerMinT"), b:get("tracerMinX") + W_IN / 2))
    end
  end
  local L, R = BOXES[1].bed, BOXES[2].bed
  if not said.lesson and L:get("late") == 1 and R:get("late") == 1 and L:get("conv") == 1 and R:get("conv") == 1 then
    said.lesson = true
    local lw, rw = L:get("wall"), R:get("wall")
    local function way(w) return w < 0 and "down beside the walls and up the middle" or "up beside the walls" end
    local function where(b) return b:get("rise2") > 0 and "comes up" or "stays down" end
    print(string.format("  The walls decide: with rough walls the beads go %s (%+.1f mm/s by the walls) and the big bead %s (%.1f cm);\n" ..
                        "  with smooth glass walls they go %s (%+.1f mm/s) and it %s (%.1f cm).",
                        way(lw), lw, where(L), L:get("lateMean"), way(rw), rw, where(R), R:get("lateMean")))
  end
end

v:postSim(function(N_)
  if holdNow then return end
  t, ahead = ahead or t, nil
  drawBoxes()
  report()
  if TIMING then
    local now = demWallClock()
    if wallLast then wallSum = wallSum + now - wallLast; nTimed = nTimed + 1 end
    wallLast = now
    if nTimed == 300 then
      print(string.format("TIMING: %.1f ms a frame, %.1f of it waiting for the beads (300 frames, speed %.2f)", wallSum / nTimed * 1000, stepSum / (nTimed + 1) * 1000, v:getParam("speed")))
      wallSum, stepSum, nTimed = 0, 0, 0
    end
  end
  -- every pour runs 50 s
  if t > POUR_S then pour() end
  startBoxes()
end)

-- ---------------------------------------------------------------------
-- keys, sliders, help
-- ---------------------------------------------------------------------
common.setCamera(btVector3(0, 30, 88), btVector3(0, 24, 0))
v:addShortcut("R", function(N_) pour() end)
v:addShortcut("Z", function(N_)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N_, name, value)
  if name == "speed" then applyTiming() end
end)
v:setHelpText(table.concat({
  "The Brazil-nut effect, in real glass (Euler's Cabinet of Curiosities)",
  "",
  "Two boxes of glass beads shaken up and down five times a second,",
  "gently (0.8 g) for 2 s, then hard (3 g). A big glass bead at the",
  "bottom of each; a red bead to show which way the beads go round.",
  "Left:   walls lined with glued glass beads -- the beads go up the",
  "        middle and down the walls, and the big bead comes up",
  "Right:  smooth glass walls -- the beads go round the other way,",
  "        and the big bead stays down",
  "",
  "R   pour them again",
  "Z   slow motion (1/4, the default) <-> real time",
  "",
  "Sliders: hard (peak acceleration, g, from the next pour), speed.",
}, "\n"))
if v.onHover then
  v:onHover(function(N_, obj, x, y, z)
    for _, bx in ipairs(BOXES) do
      if bx.shown and objectKey(obj) == objectKey(bx.shown[N_S]) then
        return string.format("%s\nthe big bead: its middle %.1f cm above the floor; the bed %.1f cm deep at its top",
                             bx.name, bx.bed:get("special"), bx.bed:get("top"))
      end
    end
    return nil
  end)
end

pour()
