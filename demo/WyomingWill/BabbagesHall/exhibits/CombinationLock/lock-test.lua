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
  for i = 1, 3 do wps[i] = L.wheelPieces(gates[i] * L.DEG) end
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
