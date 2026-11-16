-- plan-test.lua -- the suanpan's rules (plan.lua) checked against plain
-- arithmetic, without the beads. Run from this folder with any Lua:
--
--   lua plan-test.lua
--
-- Each step's rod must hold what the step says it starts from, and the
-- rods at the end must read the right answer. Prints which rules came up,
-- and "plan-test: PASS" or "FAIL".
local plan = dofile("plan.lua")
local R = 7
math.randomseed(1)

local function rodsOf(x)
  local s, d = string.format("%07d", x), {}
  for i = 1, R do d[i] = tonumber(s:sub(i, i)) end
  return d
end
-- (the steps replayed on a copy: each must start from what the rod holds)
local function replay(start, steps, seen)
  local m, bad = {}, 0
  for i = 1, R do m[i] = start[i] end
  for _, st in ipairs(steps) do
    if st.d0 then
      if m[st.rod] ~= st.d0 then bad = bad + 1 end
      m[st.rod] = st.d1
    end
    seen[st.rule .. (st.b and "" or ("-" .. st.a))] = true
  end
  return plan.value(m), bad
end
local function count(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end
local wrong = 0

-- adding
local seen = {}
for t = 1, 100000 do
  local x = math.random(0, 9999999)
  local y = math.random(1, math.max(1, math.min(9999999 - x, t % 5 == 0 and 999 or 9999999)))
  if x + y <= 9999999 then
    local d = rodsOf(x)
    local start = rodsOf(x)
    local steps = plan.number(d, y)
    local v, bad = replay(start, steps, seen)
    if bad > 0 or v ~= x + y or plan.value(d) ~= x + y then wrong = wrong + 1 end
  end
end
print(string.format("adding: 100,000 sums; %d rules came up (26 can)", count(seen)))
local nAdd = count(seen)

-- taking away
seen = {}
for t = 1, 100000 do
  local x = math.random(1, 9999999)
  local y = math.random(1, t % 5 == 0 and math.min(x, 999) or x)
  local d = rodsOf(x)
  local start = rodsOf(x)
  local steps = plan.subNumber(d, y)
  local v, bad = replay(start, steps, seen)
  if bad > 0 or v ~= x - y or plan.value(d) ~= x - y then wrong = wrong + 1 end
end
print(string.format("taking away: 100,000 differences; %d rules came up (26 can)", count(seen)))
local nSub = count(seen)

-- multiplying: every 2-digit times 2-digit, and random ones up to 9999 x 9
seen = {}
local n = 0
local function mul(a, b)
  local d = rodsOf(0)
  local steps = plan.multiply(d, a, b)
  local v, bad = replay(rodsOf(0), steps, seen)
  n = n + 1
  if bad > 0 or v ~= a * b or plan.value(d) ~= a * b then wrong = wrong + 1; print("  WRONG", a, b, v) end
end
for a = 1, 99 do for b = 1, 99 do mul(a, b) end end
for t = 1, 20000 do mul(math.random(1, 9999), math.random(1, 9)) end
print(string.format("multiplying: %d products; fits 99 x 99: %s, 9999 x 9: %s, 123 x 45: %s", n,
      tostring(plan.layout(R, 99, 99) ~= nil), tostring(plan.layout(R, 9999, 9) ~= nil),
      tostring(plan.layout(R, 123, 45) ~= nil)))

local ok = wrong == 0 and nAdd == 26 and nSub == 26
print(string.format("plan-test: %s (%d wrong)", ok and "PASS" or "FAIL", wrong))
