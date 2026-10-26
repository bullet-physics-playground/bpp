--
-- checks/ch04_perfect.lua -- Ch. 4.1's perfect formations (book/ch04.md,
-- PDF 124-130) on ch04/perfect.lua, formation_perfect.nlogo's own step
--
-- The (m, n) attributes; the square and the triangle forming perfectly
-- from the model's start; linear momentum conserved by both, angular
-- momentum by the square only (the triangle's special cases break Newton's
-- third law); Toggle Formation rebuilding the other lattice (perfect, but
-- turned 10-15 degrees from the compass axes); One is Born's clone finding
-- its slot; the formation following a new D; the author's open question
-- (a), a triangle that keeps the third law; and the one failure seen in
-- 10 starts, a particle left beyond sensing range. ch04/README.md has the
-- full measurements (10 seeds, three toggles each).
--
-- DEFINITIONS (printed values):
--   slot     a particle's place in the ideal lattice its (m, n) describe,
--            the lattice fitted to the particles (moved, turned, scaled)
--   RMS, worst   the particles' distances from their slots, in D
--   formed   every particle within 0.25 D of its slot (checked every 10
--            ticks); "ticks" is the time to get there
--   angle    the fitted lattice's turn from the compass axes, degrees
--   spacing  the fitted lattice spacing, in D
--   |L|max, |P|max   the largest total angular and linear momentum on the
--            way (about the centre of mass; NetLogo units)
--
-- Run from the ArtificialPhysics folder (about 40 s):
--   lua5.1 checks/ch04_perfect.lua
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local P = require "ch04.perfect"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-58s %s", ok and "ok  " or "FAIL", name, detail or ""))
end
local t0 = os.clock()
print("ch04_perfect: " .. _VERSION)

-- run until formed (or cap); returns ticks (or nil), |L|max, |P|max
local function form(m, cap)
  local Lmax, Pmax, start = 0, 0, m.ticks
  while m.ticks - start < cap do
    P.step(m)
    Lmax = math.max(Lmax, math.abs(m.L)); Pmax = math.max(Pmax, math.sqrt(m.lmx * m.lmx + m.lmy * m.lmy))
    if (m.ticks - start) % 10 == 0 then local _, w = P.fit(m); if w < 0.25 then return m.ticks - start, Lmax, Pmax end end
  end
  return nil, Lmax, Pmax
end
local function state(m)
  local e, w, ang, k = P.fit(m)
  return e, w, ang, k, string.format("RMS %.3f, worst %.3f, angle %.1f, spacing %.4f", e, w, ang, k)
end

-- 1. the attributes (init-m-n)
do
  local sq, hx, dupS, dupH, parity, checker = {}, {}, 0, 0, 0, 0
  for w = 0, 127 do
    local a = P.attributes(w)
    local ks, kh = a.squarem .. "," .. a.squaren, a.hexm .. "," .. a.hexn
    if w < 100 then
      if sq[ks] then dupS = dupS + 1 end
      sq[ks] = true
      if (a.squarem + a.squaren) % 2 ~= w % 2 then checker = checker + 1 end
    end
    if w < 127 then
      if hx[kh] then dupH = dupH + 1 end
      if (a.hexm - a.hexn) % 2 ~= 0 then parity = parity + 1 end
    end
    if w == 127 then dupH = dupH + (hx[kh] and 100 or 0) end
    hx[kh] = true
  end
  check("init-m-n: 100 distinct square slots, a checkerboard by parity", dupS == 0 and checker == 0,
    string.format("%d repeated, %d off the checkerboard", dupS, checker))
  check("init-m-n: 127 distinct triangle slots; the 128th repeats one", dupH == 100 and parity == 0,
    "\"good up to 126 particles\" (who 0-126)")
end

-- 2. the square from the model's start
local sqm = P.new({ seed = 1, square = true })
do
  local t, L, Pm = form(sqm, 2000)
  P.run(sqm, 200)
  local e, w, ang, k, s = state(sqm)
  check("square: forms perfectly from the model's start", t and t <= 400 and w < 0.15 and math.abs(ang) < 3 and math.abs(k - 1) < 0.01,
    string.format("%s ticks; %s", tostring(t), s))
  check("square: linear and angular momentum conserved", L < 1e-9 and Pm < 1e-9, string.format("|L|max %.1e, |P|max %.1e", L, Pm))
end

-- 3. the triangle from the model's start
local trm = P.new({ seed = 1, square = false })
do
  local t, L, Pm = form(trm, 2000)
  P.run(trm, 200)
  local e, w, ang, k, s = state(trm)
  check("triangle: forms perfectly from the model's start", t and t <= 400 and w < 0.15 and math.abs(ang) < 3 and math.abs(k - 1) < 0.01,
    string.format("%s ticks; %s", tostring(t), s))
  check("triangle: linear momentum conserved, angular not (PDF 130)", L > 100 and Pm < 1e-9, string.format("|L|max %.0f, |P|max %.1e", L, Pm))
end

-- 4. Toggle Formation, both ways
do
  P.toggle(sqm)
  local t, L = form(sqm, 2000); P.run(sqm, 200)
  local e, w, ang, k, s = state(sqm)
  check("toggle square -> triangle: rebuilt, perfect, turned", t and w < 0.15 and ang > 8 and ang < 16, string.format("%s ticks; %s", tostring(t), s))
  P.toggle(sqm)
  t, L = form(sqm, 2000); P.run(sqm, 200)
  e, w, ang, k, s = state(sqm)
  check("toggle back -> square: rebuilt, perfect, turned the other way", t and w < 0.15 and ang < -8 and ang > -16,
    string.format("%s ticks; %s", tostring(t), s))
end

-- 5. One is Born
do
  local b = P.born(trm)
  local t = form(trm, 2000); P.run(trm, 100)
  local e, w, ang, k, s = state(trm)
  check("One is Born: the clone ripples to its slot", t and t <= 500 and w < 0.15,
    string.format("particle %d: %s ticks; %s", b.who, tostring(t), s))
end

-- 6. a new D
do
  local m = P.new({ seed = 1, square = true }); form(m, 2000); P.run(m, 200)
  m.D = 30
  local t = form(m, 2000); P.run(m, 200)
  local e, w, ang, k, s = state(m)
  check("Desired_Separation 25 -> 30: the formation follows", t and w < 0.15 and math.abs(k - 1) < 0.01,
    string.format("%s ticks; %s, i.e. %.2f", tostring(t), s, k * m.D))
end

-- 7. the author's question (a): a triangle that keeps Newton's third law
do
  local m = P.new({ seed = 2, square = false, thirdLaw = true })
  local t, L = form(m, 5000)
  local m2 = P.new({ seed = 2, square = false })
  local t2 = form(m2, 2000)
  check("question (a): third law kept, the triangle forms, slower", t and t2 and t > 3 * t2 and L < 1e-9,
    string.format("%s ticks against %s; |L|max %.1e", tostring(t), tostring(t2), L))
end

-- 8. the failure seen: a particle left beyond sensing range (seed 7)
do
  local m = P.new({ seed = 7, square = true })
  local t = form(m, 3000)
  local _, w = P.fit(m)
  -- the lost particle's distance to its nearest neighbour, in D
  local far = 0
  for _, a in ipairs(m.ps) do
    local near = math.huge
    for _, b in ipairs(m.ps) do
      if b ~= a then near = math.min(near, math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)) end
    end
    far = math.max(far, near / m.D)
  end
  check("seed 7: one particle stays out of sensing range", not t and far > 1.7,
    string.format("worst %.2f D from its slot, %.2f D from the nearest particle (sensing 1.3-1.7 D)", w, far))
end

print(string.format("ch04_perfect: %d checks, %d failed, %.0f s", count, fails, os.clock() - t0))
print(fails == 0 and "PASS ch04_perfect: " .. count .. " tests" or "FAIL ch04_perfect")
