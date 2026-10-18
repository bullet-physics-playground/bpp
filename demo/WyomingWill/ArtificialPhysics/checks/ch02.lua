--
-- checks/ch02.lua -- Ch. 2's results (book/ch02.md) on ch02/models.lua
--
-- spring1D (2.1), spring2D (2.2) and solar_system (2.3), with the book's
-- slider values. Each line says what the book reports and what we get.
--
-- DEFINITIONS (printed values): separation = distance between the two
-- bodies; |P| total linear momentum; L angular momentum about the centre of
-- mass; E total energy. "drift" = (mean E over the last tenth of the run -
-- mean E over the first tenth) / |E at the start|: whether energy is
-- conserved. "swing" = (max E - min E) / |E at the start|: how much it
-- moves within each cycle, which the book's integrator always does (about
-- dt x omega). "farthest" = largest distance from the sun; "advances N deg
-- per orbit" = turn of the farthest point between successive orbits.
--
-- Run from the ArtificialPhysics folder (about half a minute):
--   lua5.1 checks/ch02.lua
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local ch = require "ch02.models"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-58s %s", ok and "ok  " or "FAIL", name, detail or ""))
end
local abs, max, min = math.abs, math.max, math.min
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end -- Lua 5.3+ dropped atan2

-- Run a model for `time` units; returns first and last measurements and
-- the extremes of a few monitors.
local function run(m, time, every)
  local n = math.floor(time / m.dt + 0.5)
  local first = ch.measure(m)
  local w = math.max(1, math.floor(n / 10))   -- first and last tenth, for drift
  local ext = { sepMin = math.huge, sepMax = 0, eMin = math.huge, eMax = -math.huge,
                pMax = 0, lMin = math.huge, lMax = -math.huge, speedMax = 0, sepSum = 0, n = 0,
                eHead = 0, nHead = 0, eTail = 0, nTail = 0 }
  for i = 1, n do
    ch.step(m)
    if not every or i % every == 0 or i == n then
      local r = ch.measure(m)
      ext.sepMin, ext.sepMax = min(ext.sepMin, r.sep), max(ext.sepMax, r.sep)
      ext.eMin, ext.eMax = min(ext.eMin, r.e), max(ext.eMax, r.e)
      ext.pMax = max(ext.pMax, r.p)
      ext.lMin, ext.lMax = min(ext.lMin, r.lz), max(ext.lMax, r.lz)
      ext.speedMax = max(ext.speedMax, r.speed2)
      ext.sepSum, ext.n = ext.sepSum + r.sep, ext.n + 1
      if i <= w then ext.eHead, ext.nHead = ext.eHead + r.e, ext.nHead + 1 end
      if i > n - w then ext.eTail, ext.nTail = ext.eTail + r.e, ext.nTail + 1 end
    end
  end
  ext.sepMean = ext.sepSum / ext.n
  -- drift: mean energy over the last tenth against the first, relative to E
  ext.drift = (ext.eTail / ext.nTail - ext.eHead / ext.nHead) / abs(first.e)
  ext.swing = (ext.eMax - ext.eMin) / abs(first.e)
  return first, ch.measure(m), ext
end
local function rel(a, b) return abs(a - b) / max(abs(b), 1e-300) end

print("Ch. 2 checks (" .. _VERSION .. ")")

-------------------------------------------------------------------- 2.1
print("-- 2.1 spring1D (k 10, D 50, dt 0.001)")
do
  local m = ch.spring1D({ seed = 1 })
  local f, l, e = run(m, 20)
  check("momentum stays exactly 0", e.pMax == 0, string.format("max |P| %g", e.pMax))
  check("oscillates symmetrically about D", rel(e.sepMax - 50, 50 - e.sepMin) < 0.01,
        string.format("separation %.3f to %.3f", e.sepMin, e.sepMax))
  check("total energy constant (friction 0, dt 0.001): no drift", abs(e.drift) < 1e-4 and e.swing < 0.01,
        string.format("E %.1f, drift %.1g, swing within a cycle %.2g", f.e, e.drift, e.swing))

  local function period(k)
    local mm = ch.spring1D({ seed = 1, k = k })
    local ups, prev = {}, ch.measure(mm).sep - 50
    for i = 1, 40000 do
      ch.step(mm)
      local cur = ch.measure(mm).sep - 50
      if prev < 0 and cur >= 0 then ups[#ups + 1] = i * mm.dt end
      prev = cur
    end
    return (ups[#ups] - ups[1]) / (#ups - 1)
  end
  local t10, t1 = period(10), period(1)
  check("lower k: slower oscillation (period x sqrt 10)", rel(t1 / t10, math.sqrt(10)) < 0.01,
        string.format("period %.3f at k 10, %.3f at k 1", t10, t1))

  local h = ch.spring1D({ seed = 1, massRatio = 10 })
  local x2a = h.ps[2].x
  local _, l2, e2 = run(h, 10)
  check("mass ratio 10: COM near the heavy mass", abs(l2.cx - h.ps[2].x) < 0.1 * l2.sep,
        string.format("COM %.2f, heavy mass %.2f (moved %.2f), light %.2f", l2.cx, h.ps[2].x, x2a - h.ps[2].x, h.ps[1].x))

  local fm = ch.spring1D({ seed = 1 })
  run(fm, 5)
  fm.law.friction = 0.001
  local f3, l3, e3 = run(fm, 10)
  local _, l4, e4 = run(fm, 2)
  check("friction 0.001 drains energy to 0, separation to D", l4.e < 1e-3 * f3.e and abs(e4.sepMax - 50) < 0.25,
        string.format("E %.3f -> %.2g; separation within %.3f of D", f3.e, l4.e, max(e4.sepMax - 50, 50 - e4.sepMin)))

  local function spread(dt)
    local mm = ch.spring1D({ seed = 1, dt = dt })
    local ff, _, ee = run(mm, 20)
    return (ee.eMax - ee.eMin) / ff.e, ee
  end
  local s1, s2 = spread(0.001), spread(0.01)
  check("larger dt: bigger but small energy fluctuations", s2 > 5 * s1 and s2 < 0.05,
        string.format("swing %.2g at dt 0.001, %.2g at dt 0.01", s1, s2))

  local cm = ch.spring1D({ seed = 1 })
  local fa, la = run(cm, 5)
  ch.setSpring(cm, nil, 60)                  -- D changed mid-run: the system is opened
  local fb, lb, eb = run(cm, 5)
  check("changing D mid-run steps E to a new constant level", rel(fb.e, la.e) > 0.1 and abs(eb.drift) < 1e-4,
        string.format("E %.1f before, %.1f after (drift %.1g)", la.e, fb.e, eb.drift))
end

-------------------------------------------------------------------- 2.2
print("-- 2.2 spring2D (AM 200, mass ratio 10, k 10, D 50, dt 0.001)")
do
  local exceed, detail = 0, {}
  for seed = 1, 5 do
    local m = ch.spring2D({ seed = seed })
    local f, l, e = run(m, 20, 10)
    if seed == 1 then
      check("linear momentum stays 0", e.pMax < 1e-9, string.format("max |P| %.1g", e.pMax))
      check("angular momentum constant", (e.lMax - e.lMin) / abs(f.lz) < 1e-10,
            string.format("L %.1f, spread %.1g", f.lz, (e.lMax - e.lMin) / abs(f.lz)))
      check("mean separation greater than D (centrifugal)", e.sepMean > 50,
            string.format("mean %.1f", e.sepMean))
    end
    if e.sepMax > 100 then exceed = exceed + 1 end
    detail[#detail + 1] = string.format("%.0f", e.sepMax)
  end
  check("separation can exceed 2D = 100", exceed > 0,
        string.format("max separation by seed: %s", table.concat(detail, ", ")))
end

-- spring3D (ours): spring2D with a third axis. Two bodies on a spring move
-- in the fixed plane perpendicular to L, so L must keep its direction too.
-- DEFINITIONS: tilt = largest angle between L and its starting direction;
-- offPlane = largest distance of the light mass from the plane through the
-- centre of mass perpendicular to the starting L.
print("-- spring3D (ours: AM 200, AMz 0 and 120, mass ratio 10, k 10, D 50, dt 0.001)")
do
  local worst = { p = 0, l = 0, tilt = 0, off = 0, drift = 0 }
  local means = {}
  for seed = 1, 5 do
    for _, amz in ipairs({ 0, 120 }) do
      local m = ch.spring3D({ seed = seed, angularMotionZ = amz })
      local f = ch.measure(m)
      local n = math.floor(20 / m.dt + 0.5)
      local sepSum, ns, eHead, eTail = 0, 0, 0, 0
      for i = 1, n do
        ch.step(m)
        if i % 10 == 0 then
          local r = ch.measure(m)
          worst.p = max(worst.p, r.p)
          worst.l = max(worst.l, rel(r.l, f.l))
          local cx = r.ly * f.lz - r.lz * f.ly                -- L x L0 and L . L0
          local cy = r.lz * f.lx - r.lx * f.lz
          local cz = r.lx * f.ly - r.ly * f.lx
          local dot = r.lx * f.lx + r.ly * f.ly + r.lz * f.lz
          worst.tilt = max(worst.tilt, math.deg(atan2(math.sqrt(cx * cx + cy * cy + cz * cz), dot)))
          local q = m.ps[1]
          local off = abs(((q.x - r.cx) * f.lx + (q.y - r.cy) * f.ly + ((q.z or 0) - r.cz) * f.lz) / f.l)
          worst.off = max(worst.off, off)
          sepSum, ns = sepSum + r.sep, ns + 1
          if i <= n / 10 then eHead = eHead + r.e end
          if i > n - n / 10 then eTail = eTail + r.e end
        end
      end
      worst.drift = max(worst.drift, abs(eTail - eHead) / (n / 100) / abs(f.e))
      means[#means + 1] = string.format("%.0f", sepSum / ns)
    end
  end
  check("spring3D: linear momentum stays 0", worst.p < 1e-9, string.format("max |P| %.1g", worst.p))
  check("spring3D: |L| constant and L keeps its direction", worst.l < 1e-10 and worst.tilt < 1e-6,
        string.format("|L| spread %.1g, tilt %.1g degrees", worst.l, worst.tilt))
  check("spring3D: the motion stays in one plane", worst.off < 1e-8,
        string.format("light mass at most %.1g from the plane", worst.off))
  check("spring3D: energy does not drift", worst.drift < 1e-3,
        string.format("largest drift %.1g of E", worst.drift))
  check("spring3D: mean separation greater than D", (function()
    for _, x in ipairs(means) do if tonumber(x) <= 50 then return false end end
    return true end)(), "means by run: " .. table.concat(means, ", "))
end

-------------------------------------------------------------------- 2.3
print("-- 2.3 solar_system (sun 100 at the origin, planet at 15, G 20)")
do
  -- a. Delta-t 0.1: AM 15 / 10 x sun 100 / 95
  local reach = {}
  for _, am in ipairs({ 15, 10 }) do
    for _, ms in ipairs({ 100, 95 }) do
      local m = ch.solar({ angularMotion = am, sunMass = ms, dt = 0.1 })
      local f, l, e = run(m, 400)
      reach[am .. "/" .. ms] = { e.sepMax, e.swing, e.pMax, (e.lMax - e.lMin) / abs(f.lz), e.drift }
    end
  end
  local r = reach
  check("a: AM 15 gives a larger orbit than AM 10", r["15/100"][1] > r["10/100"][1],
        string.format("farthest %.1f vs %.1f", r["15/100"][1], r["10/100"][1]))
  check("a: a lighter sun gives a larger orbit, more so for AM 15",
        r["15/95"][1] > r["15/100"][1] and r["10/95"][1] > r["10/100"][1]
        and r["15/95"][1] - r["15/100"][1] > r["10/95"][1] - r["10/100"][1],
        string.format("AM 15: %.1f -> %.1f; AM 10: %.1f -> %.1f", r["15/100"][1], r["15/95"][1], r["10/100"][1], r["10/95"][1]))
  check("a: momentum 0; L and E steady (no drift)", r["15/100"][3] < 1e-9 and r["15/100"][4] < 1e-10 and abs(r["15/100"][5]) < 0.01,
        string.format("E drift %.1g (swings %.0f%% at closest approach), L spread %.1g",
                      r["15/100"][5], 100 * r["15/100"][2], r["15/100"][4]))

  -- b. Delta-t 0.1: AM 5 escapes; AM 0 is nonsense
  local m5 = ch.solar({ angularMotion = 5, dt = 0.1 })
  local f5, l5 = run(m5, 400)
  check("b: dt 0.1, AM 5: the planet escapes (discretisation error)", l5.sep > 200 and l5.e > 0,
        string.format("E %.1f -> %.1f, distance %.0f", f5.e, l5.e, l5.sep))
  local m0 = ch.solar({ angularMotion = 0, dt = 0.1 })
  local f0, l0 = run(m0, 400)
  check("b: dt 0.1, AM 0: total energy changes radically", rel(l0.e, f0.e) > 1,
        string.format("E %.1f -> %.1f", f0.e, l0.e))

  -- c. Delta-t 0.001: AM 5 fine; AM 0 still wrong (keeps moving left)
  local c5 = ch.solar({ angularMotion = 5, dt = 0.001 })
  local fc5, lc5, ec5 = run(c5, 100, 10)
  check("c: dt 0.001, AM 5: a reasonable orbit, E and L conserved",
        ec5.sepMax < 16 and abs(ec5.drift) < 0.01 and (ec5.lMax - ec5.lMin) / abs(fc5.lz) < 1e-9,
        string.format("distance %.2f to %.2f, E drift %.1g (swings %.0f%% at closest approach)",
                      ec5.sepMin, ec5.sepMax, ec5.drift, 100 * ec5.swing))
  local c0 = ch.solar({ angularMotion = 0, dt = 0.001 })
  local fc0, lc0 = run(c0, 100, 10)
  check("c: dt 0.001, AM 0: still wrong, the planet keeps moving left", c0.ps[2].x < -100,
        string.format("planet at x = %.0f (should stay within 15 of the sun)", c0.ps[2].x))

  -- d. Velocity cap at Delta-t 0.1 (uncapped peak speed about 15)
  local function vcap(am, vmax, perAxis)
    local m = ch.solar({ angularMotion = am, speedMax = vmax, dt = 0.1, speedCapPerAxis = perAxis })
    local f, l, e = run(m, 400)
    return f, l, e
  end
  local fd, ld, ed = run(ch.solar({ dt = 0.1 }), 60)
  local f12, l12, e12 = vcap(15, 12)
  check("d: Vmax 12, AM 15: runs well, slight momentum change", e12.pMax > 1e-6 and e12.pMax < 10 and l12.sep < 3 * ed.sepMax and e12.sepMin > 5,
        string.format("uncapped peak speed %.1f; capped: max |P| %.1f, distance %.0f to %.0f",
                      ed.speedMax, e12.pMax, e12.sepMin, e12.sepMax))
  -- F15: the orbit shrinks to nearly circular, whichever way the cap clips
  local _, _, ea = vcap(15, 12, true)
  local _, l9a, e9a = vcap(15, 9, true)
  check("d: Vmax 12 shrinks the orbit, clipping speed or each component",
        e12.sepMax < 25 and ea.sepMax < 25 and ed.sepMax > 80,
        string.format("uncapped %.0f to %.0f; speed %.1f to %.1f; components %.1f to %.1f (|P| %.1f); Vmax 9 by components ends %.2f away",
                      ed.sepMin, ed.sepMax, e12.sepMin, e12.sepMax, ea.sepMin, ea.sepMax, ea.pMax, l9a.sep))
  local f9, l9, e9 = vcap(15, 9)
  check("d: Vmax 9, AM 15: plunges into the sun and stays", l9.sep < 3 and e9.pMax > 1,
        string.format("ends %.2f from the sun; max |P| %.1f; E %.1f -> %.1f", l9.sep, e9.pMax, f9.e, l9.e))
  local worst = 0
  for _, vm in ipairs({ 12, 9, 1 }) do
    local f, l, e = vcap(0, vm)
    worst = max(worst, e.pMax)
  end
  check("d: AM 0 with any velocity cap: large momentum changes", worst > 1,
        string.format("max |P| %.1f", worst))

  -- e. Force cap Fmax = 1: bound, precessing orbits; AM 0 oscillates 0..15
  local peaks = {}
  for _, am in ipairs({ 9, 4, 1, 0 }) do
    local m = ch.solar({ angularMotion = am, forceMax = 1, dt = 0.1 })
    local f, l, e = run(m, 400)
    peaks[am] = { e.speedMax, e.sepMin, e.sepMax, e.swing, e.pMax, e.drift }
  end
  local allBound, cons = true, true
  for _, am in ipairs({ 9, 4, 1, 0 }) do
    if peaks[am][3] > 120 then allBound = false end
    if abs(peaks[am][6]) > 0.01 or peaks[am][5] > 1e-9 then cons = false end
  end
  check("e: Fmax 1: every orbit stays bound", allBound,
        string.format("farthest: %.0f, %.0f, %.0f, %.0f (AM 9, 4, 1, 0)", peaks[9][3], peaks[4][3], peaks[1][3], peaks[0][3]))
  check("e: energy and momentum conserved well", cons,
        string.format("E spread up to %.2g", max(peaks[9][4], peaks[4][4], peaks[1][4], peaks[0][4])))
  check("e: AM 0: separation oscillates 0 to 15", peaks[0][2] < 0.5 and abs(peaks[0][3] - 15) < 1,
        string.format("%.2f to %.2f", peaks[0][2], peaks[0][3]))
  -- precession: the angle of successive farthest points moves
  local m = ch.solar({ angularMotion = 4, forceMax = 1, dt = 0.1 })
  local angles, prevR, rising = {}, 0, true
  for i = 1, 4000 do
    ch.step(m)
    local p, s = m.ps[2], m.ps[1]
    local rr = math.sqrt((p.x - s.x) ^ 2 + (p.y - s.y) ^ 2)
    if rising and rr < prevR then angles[#angles + 1] = math.deg(atan2(p.y - s.y, p.x - s.x)) end
    rising = rr > prevR
    prevR = rr
  end
  local adv = #angles >= 2 and ((angles[2] - angles[1]) % 360) or 0
  check("e: Fmax 1, AM 4: the orbit precesses (rosette)", #angles >= 2 and adv > 5 and adv < 355,
        string.format("farthest point advances %.0f deg per orbit", adv))
  local bookPeaks = { [0] = 5.6, [1] = 5, [4] = 4, [9] = 9 }
  local okPeaks = true
  for am, bp in pairs(bookPeaks) do if abs(peaks[am][1] - bp) > 0.15 then okPeaks = false end end
  check("e: peak planet speeds as printed (5.6, 5, 4, 9 for AM 0, 1, 4, 9)", okPeaks,
        string.format("%.2f, %.2f, %.2f, %.2f", peaks[0][1], peaks[1][1], peaks[4][1], peaks[9][1]))
end

if fails == 0 then print(string.format("PASS ch02: %d tests", count))
else print(string.format("FAIL ch02: %d of %d tests failed", fails, count)) end
if not rawget(_G, "v") then os.exit(fails == 0 and 0 or 1) end
