--
-- lock-test.lua -- the combination lock's model against every combination
-- (Babbage's Hall). From its folder: lua lock-test.lua  (Lua 5.1 or 5.2).
--
-- No physics: lock.lua's wheels, pins and gates, turned as the dialling
-- rules say. For each of the 1,000,000 combinations, set as that lock's own
-- combination and dialled by the rules from a scrambled start, it checks
--   * that every gate ends under the fence (the rules set the lock);
--   * the forbidden zone: turning right to open, the cam must draw the bolt
--     before its pin comes round to wheel 3's and carries it off;
--   * that the lock doesn't open early: turning right while setting the
--     second number, every time the cam's notch passes under the fence, are
--     all three gates there by chance?
-- Then, for one lock, which of the million dialled combinations open it
-- (the fence's fall from the pieces, as the exhibit's bodies have them), and
-- the tolerance: how far off a number may be and still open.
--
if v and v.addParam then             -- (opened in bpp, as the Demos menu and the CI's smoke run do: it is a tool)
  print("lock-test.lua is a plain Lua tool: run it with lua, from its folder")
  return
end
local DIR = (arg and arg[0] or ""):match("^(.*[/\\])") or ""
local L = dofile(DIR .. "lock.lua")
local N, DELTA = L.N, L.DELTA

-- the tolerance: how far a gate may be from the fence and the fence still fall
-- far enough to be hooked by the cam's notch (its centre below the cam's rim)
local wp0 = L.wheelPieces(90)
local TOL = 0
for e = 0, 3, 0.01 do
  if L.fall(wp0, e * L.DEG, 8) >= L.HOOK_DROP then TOL = e else break end
end
local tolDown = 0
for e = 0, -3, -0.01 do
  if L.fall(wp0, e * L.DEG, 8) >= L.HOOK_DROP then tolDown = e else break end
end
print(string.format("A gate within %.2f numbers of the fence (%.2f the other way) lets it fall %.1f mm or more,", TOL, tolDown, L.HOOK_DROP))
print(string.format("  its centre down to the top of the notch's steep wall, which hooks it (a full fall, onto the"))
print(string.format("  notch's floor, is %.1f mm; onto the wheels' rims, %.1f).", L.G.ROD_Y - L.G.NOTCH_R - L.G.ROD_D / 2, L.G.R_C - L.G.R_W))
local falls = {}
for e = 0.9, 1.31, 0.05 do falls[#falls + 1] = string.format("%.2f: %.2f", e, L.fall(wp0, e * L.DEG, 8)) end
print("  The fence's fall (mm) against one wheel, its gate so many numbers off: " .. table.concat(falls, ", "))
print(string.format("Two pins touching are %.3f numbers apart; the pull, from the notch arriving, %.2f numbers.", DELTA, L.PULL))

local function dial(s, a, b, c, gates, early)
  local m = L.plan(s.D, a, b, c)
  L.turn(s, m[1].to - s.D)
  -- turning right to b, a notch pass at each D = OPEN_AT (mod N) on the way
  if early then
    local D, to = s.D, m[2].to
    local nxt = D - L.wrap(D - L.OPEN_AT)
    if nxt == D then nxt = D - N end
    while nxt > to do
      L.turn(s, nxt - s.D)
      local e = L.gateOffsets(s, gates)
      if math.abs(e[1]) <= TOL and math.abs(e[2]) <= TOL and math.abs(e[3]) <= TOL then early.hit = true end
      nxt = nxt - N
    end
  end
  L.turn(s, m[2].to - s.D)
  L.turn(s, m[3].to - s.D)
  return s
end

local START = { 13, 58, 91 }     -- (the wheels scrambled)
local notSet, forbidden, early = 0, 0, 0
local forbiddenC, earlyEx, notSetEx = {}, {}, {}
local badAB, badBC = {}, {}          -- (b - a and c - b, mod 100, wherever the first or the second wheel was moved)
local t0 = os.clock()
for a = 0, N - 1 do
  for b = 0, N - 1 do
    for c = 0, N - 1 do
      local gates = L.gates(a, b, c)
      local s = L.new(0, START)
      local e = { hit = false }
      dial(s, a, b, c, gates, e)
      local off = L.gateOffsets(s, gates)
      if math.abs(off[1]) > 1e-6 or math.abs(off[2]) > 1e-6 or math.abs(off[3]) > 1e-6 then
        notSet = notSet + 1
        if math.abs(off[1]) > 1e-6 then badAB[L.wrap(b - a)] = true end
        if math.abs(off[2]) > 1e-6 then badBC[L.wrap(b - c)] = true end
        if #notSetEx < 6 then notSetEx[#notSetEx + 1] = string.format("%s (%.1f %.1f %.1f)", L.text(a, b, c), off[1], off[2], off[3]) end
      end
      -- turning right to open: to the notch, then the pull
      local moved = L.turn(s, L.toOpen(s.D) - s.D - L.PULL)
      if moved[3] ~= 0 then forbidden = forbidden + 1; forbiddenC[c] = true end
      if e.hit and moved[3] == 0 and math.abs(off[1]) + math.abs(off[2]) + math.abs(off[3]) < 1e-6 then
        early = early + 1
        if #earlyEx < 6 then earlyEx[#earlyEx + 1] = L.text(a, b, c) end
      end
    end
  end
end
print(string.format("\nEvery combination, set and dialled (%.1f s):", os.clock() - t0))
print(string.format("  not set by the rules: %d%s", notSet, #notSetEx > 0 and ("  e.g. " .. table.concat(notSetEx, ", ")) or ""))
local function list(t)
  local o = {}
  for k = 0, N - 1 do if t[k] then o[#o + 1] = k end end
  return table.concat(o, " ")
end
print("    wheel 1 carried off by wheel 2 (setting the second number) whenever the second number is")
print("      this many above the first: " .. list(badAB))
print("    wheel 2 carried off by wheel 3 (setting the third) whenever the third is this many below the second: " .. list(badBC))
local fz = {}
for c = 0, N - 1 do if forbiddenC[c] then fz[#fz + 1] = c end end
print(string.format("  the forbidden zone: %d combinations, every one with its last number in {%s}", forbidden, table.concat(fz, " ")))
print(string.format("  of the rest, could open early (all three gates under the fence as the notch passes, turning right to the second number): %d%s",
  early, #earlyEx > 0 and ("  e.g. " .. table.concat(earlyEx, ", ")) or ""))

-- one lock: which dialled combinations open it? (the rod's fall, from the
-- pieces, with the notch under the rod)
local function opens(lock, a, b, c)
  local gates = L.gates(lock[1], lock[2], lock[3])
  local s = dial(L.new(0, START), a, b, c, gates)
  L.turn(s, L.toOpen(s.D) - s.D)
  local e = L.gateOffsets(s, gates)
  for i = 1, 3 do if math.abs(e[i]) > TOL + 0.5 then return false end end      -- (far off: no need to look)
  local wps = {}
  for i = 1, 3 do wps[i] = L.wheelPieces(gates[i] * L.DEG, i) end
  return L.rodFall(s, gates, wps, L.camPieces()) >= L.HOOK_DROP
end
local LOCK = { 31, 72, 46 }
local count, list = 0, {}
for a = 0, N - 1 do
  if math.abs(L.centred(a - LOCK[1])) <= 3 then
    for b = 0, N - 1 do
      if math.abs(L.centred(b - LOCK[2])) <= 3 then
        for c = 0, N - 1 do
          if math.abs(L.centred(c - LOCK[3])) <= 3 and opens(LOCK, a, b, c) then
            count = count + 1
            list[#list + 1] = L.text(a, b, c)
          end
        end
      end
    end
  end
end
print(string.format("\nThe lock set to %s opens to %d of the million combinations (those within 3 of it tried;", L.text(LOCK[1], LOCK[2], LOCK[3]), count))
print("  none further can open it): " .. table.concat(list, " "))
if count > 0 then print(string.format("  So a thief has about %d really different combinations to try, not 1,000,000.", math.floor(N ^ 3 / count + 0.5))) end

-- ---------------------------------------------------------------------
-- the safecracker's way, in the model: the exhibit's method (graph the gap
-- between the contact points with all three wheels parked together, then
-- with wheel 1 left on what that found and wheels 2 and 3 parked together;
-- each graph every 2.5 numbers until just past the narrowing, then its
-- edges every half number) on random locks. Every lock has its first number from 10 to
-- 88 and its second one the exhibit's hand can graph (7.5 to 95.4, and not
-- 0 to 12 above the first).
-- ---------------------------------------------------------------------
local cp = L.camPieces()
local DIP = 0.08
local readings = 0                 -- (contact-point pairs felt, all locks)
local function median(gaps, n)
  local g = {}
  for k = 1, n do g[#g + 1] = gaps[k] end
  table.sort(g)
  return g[math.floor((#g + 1) / 2)]
end
local function crack(lock)
  local gates = L.gates(lock[1], lock[2], lock[3])
  local wps = {}
  for i = 1, 3 do wps[i] = L.wheelPieces(gates[i] * L.DEG, i) end
  local s
  local function feel() readings = readings + 1; local _, _, w = L.contacts(s, wps, cp); return w end
  -- (each graph to the first point back up after the narrowing, once four
  -- points give a baseline; then its two edges, half a number at a time,
  -- on the way the dial turns: as the exhibit)
  local function graphToDip(xs, park)
    local gaps = {}
    for k, x in ipairs(xs) do
      park(k, x); gaps[k] = feel()
      local m = k >= 4 and median(gaps, k)
      if m and gaps[k] >= m - DIP then
        for j = 1, k - 1 do if gaps[j] < m - DIP then return gaps, k, m end end
      end
    end
    return gaps, #xs, median(gaps, #xs)
  end
  local function closerLook(xs, gaps, n, m, park, dir, ok, width)
    local first, last
    for k = 1, n do if gaps[k] < m - DIP then first = first or k; last = k end end
    if not first then return nil end
    local k = 0
    local function narrow(x) k = k + 1; park(k, x); return feel() < m - DIP end
    local out, inside = first > 1 and xs[first - 1] or xs[first] - dir * 2.5, xs[first]
  local felt = first > 1                       -- (out: a point felt, not supposed)
    local from = out
    for i = 1, 4 do
      local x = from + dir * 0.5 * i
      if (x - inside) * dir > -0.01 then break end
      if ok(x) then if narrow(x) then inside = x; break end; out, felt = x, true end
    end
    local near = (felt and math.abs(out - inside) < 0.51) and (out + inside) / 2   -- (an edge found to half a number)
  local nearB = (out + inside) / 2
    inside, out = xs[last], last < n and xs[last + 1] or xs[last] + dir * 2.5
  felt = last < n
    from = inside
    for i = 1, 4 do
      local x = from + dir * 0.5 * i
      if (x - out) * dir > -0.01 then break end
      if ok(x) then if not narrow(x) then out, felt = x, true; break end; inside = x end
    end
    local far = (felt and math.abs(out - inside) < 0.51) and (inside + out) / 2
    if near and far then return L.wrap((near + far) / 2), math.abs(far - near) end
    if near and width then return L.wrap(near + dir * width / 2) end
    if far and width then return L.wrap(far - dir * width / 2) end
    return L.wrap((nearB + (inside + out) / 2) / 2)
  end
  s = L.new(0, START)
  local parkAll = function(k, x) L.turn(s, L.goTo(s.D, 1, x, k == 1 and 4 or 1) - s.D) end
  local xs = {}
  for x = 7.5, 90.01, 2.5 do xs[#xs + 1] = x end
  local g1, n1, m1 = graphToDip(xs, parkAll)
  local c1, w1 = closerLook(xs, g1, n1, m1, parkAll, 1, function(x) return x >= 7.5 and x <= 90 end)
  if not c1 then return nil end
  local a = math.floor(c1 + 0.5) % N
  local ys, y = {}, a - 1.5
  while L.wrap(y - a) >= 12 or L.wrap(y - a) < 0.5 do
    local r = L.wrap(y)
    if r >= 7.5 and r <= N - L.FEEL_FROM - 0.1 then ys[#ys + 1] = y end
    y = y - 2.5
  end
  local prev
  local parkTwo = function(k, y)
    if k == 1 then
      L.turn(s, L.goTo(s.D, 1, a, 4) - s.D)
      L.turn(s, L.goTo(s.D, -1, y, 3) - s.D)
    else L.turn(s, -(L.wrap(s.D - prev) + L.wrap(prev - y))) end
    prev = y
  end
  local g2, n2, m2 = graphToDip(ys, parkTwo)
  local c2 = closerLook(ys, g2, n2, m2, parkTwo, -1, function(y)
    local r = L.wrap(y)
    return r >= 7.5 and r <= N - L.FEEL_FROM - 0.1 and (L.wrap(y - a) >= 12 or L.wrap(y - a) < 0.5)
  end, w1)
  if not c2 then return a end
  local b = math.floor(c2 + 0.5) % N
  -- the last wheel: from just above b round to just below it, every second
  -- number but the forbidden zone, carrying wheel 3 on 2 each time, and
  -- turning right to open (as far as the exhibit's hand does)
  L.turn(s, L.goTo(s.D, 1, a, 4) - s.D); L.turn(s, L.goTo(s.D, -1, b, 3) - s.D)
  local lastD, lastZ, c, tries = nil, nil, nil, 0
  for k = 1, N / 2 - 1 do
    local z = (b + 2 * k) % N
    if L.wrap(b - z) <= 7 then break end
    if z < N - 10 then
      L.turn(s, (lastD and lastD + L.wrap(z - lastZ) or L.goTo(s.D, 1, z, 2)) - s.D)
      lastD, lastZ, tries = s.D, z, tries + 1
      local t = L.copy(s)
      L.turn(t, L.toOpen(t.D) - t.D)
      if L.rodFall(t, gates, wps, cp) >= L.HOOK_DROP then c = z; break end
      L.turn(s, L.toOpen(s.D) - L.PULL - 4 - s.D)
    end
  end
  return a, b, m1, m2, c, tries
end
local t1 = os.clock()
local _, _, gapOn1 = crack({ 31, 72, 46 })
math.randomseed(7)
local tried, right, near, misses, opened, triesAll = 0, 0, 0, {}, 0, 0
while tried < 40 do
  local a, b, c = math.random(10, 88), math.random(0, 99), math.random(0, 89)
  local rb = L.wrap(b)
  if L.wrap(b - a) > 12 and L.wrap(b - c) > 7 and rb >= 7.5 and rb <= 95.4 then
    tried = tried + 1
    local fa, fb, _, _, fc, nt = crack({ a, b, c })
    if fc then opened = opened + 1; triesAll = triesAll + nt end
    if fa == a and fb == b then right = right + 1
    elseif fa and fb and math.abs(L.centred(fa - a)) <= 1 and math.abs(L.centred(fb - b)) <= 1 then near = near + 1
    else misses[#misses + 1] = string.format("%s (found %s-%s)", L.text(a, b, c), tostring(fa), tostring(fb)) end
  end
end
print(string.format("\nThe safecracker's way, in the model, on %d random locks (%.0f s): both numbers found exactly in %d,", tried, os.clock() - t1, right))
print(string.format("  within one (still opening) in %d more%s; the lock opened, trying the last wheel, in %d (%.1f tries each).", near, #misses > 0 and ("; missed: " .. table.concat(misses, ", ")) or "; none missed", opened, triesAll / math.max(1, opened)))
print(string.format("  The contact points felt %.1f times a lock, for the two numbers.", readings / math.max(1, tried)))
print(string.format("  The gap narrows by %.3f numbers each time the fence drops from one wheel to the next (0.1 mm).", (gapOn1 or 0) - (select(4, crack({ 31, 72, 46 })) or 0)))
