--
-- rule-test.lua -- the slide rule's plans against plain arithmetic, with
-- no physics (Babbage's Hall). From this folder: lua rule-test.lua
--
-- Each plan is worked with the parts put exactly where it says, and then
-- with each move off by a random amount up to so many tenths of a
-- millimetre, as a hand might leave it: how often is the answer still
-- right to the figures read? Each move is made against where the other
-- part was left (as slide-rule.lua makes it), so errors add up.
--
local R = dofile("rule.lua")
math.randomseed(1)

-- a random number of three figures, 0.001 to 999
local function rnd()
  local v = math.random(100, 999) / 100
  return v * 10 ^ math.random(-2, 2)
end
-- (each move made against where the parts are, then left off by up to err)
local function work(p, err, s, c)
  s, c = s or 0, c or 0
  for _, st in ipairs(p.steps) do
    if st.part then
      local x = R.target(st, s, c) + (err > 0 and (math.random() * 2 - 1) * err or 0)
      if st.part == "slide" then s = x else c = x end
    end
  end
  return s, c
end
local OPS = {
  { "multiply", function() return R.multiply(rnd(), rnd()) end },
  { "divide", function() return R.divide(rnd(), rnd()) end },
  { "square", function() return R.square(rnd()) end },
  { "root", function() return R.root(rnd()) end },
  { "cube", function() return R.cube(rnd()) end },
  { "reciprocal", function() return R.reciprocal(rnd()) end },
  { "logarithm", function() return R.logarithm(rnd()) end },
}
local N = 20000
local bad = 0
print(string.format("%-11s %8s   right to the figures read, with each part off by up to", "", "cases"))
print(string.format("%-11s %8s   %8s %8s %8s %8s", "", "", "0", "0.05 mm", "0.1 mm", "0.2 mm"))
for _, op in ipairs(OPS) do
  local row = {}
  for k, err in ipairs({ 0, 0.005, 0.01, 0.02 }) do
    local ok = 0
    for i = 1, N do
      local p = op[2]()
      local s, c = work(p, err)
      -- (the parts' limits: the slide at most a scale's length out, the
      -- hairline on the scales)
      assert(s >= -R.L - 1e-9 and s <= R.L + 1e-9, op[1] .. ": slide off its limits")
      assert(c >= -0.5 and c <= R.L + 0.5, op[1] .. ": cursor off the scales")
      if R.check(p, c, s).ok then ok = ok + 1 elseif err == 0 then bad = bad + 1
        print("  WRONG", op[1], p.a, p.b, R.check(p, c, s).text, p.exact) end
    end
    row[k] = 100 * ok / N
  end
  print(string.format("%-11s %8d   %7.2f%% %7.2f%% %7.2f%% %7.2f%%", op[1], N, row[1], row[2], row[3], row[4]))
end
-- the tables: every b on the rule at one setting
local t = R.table(1.609, { 2, 3, 5 })
assert(t, "the table of 1.609 should fit")
local s, c = work(t, 0)
for _, it in ipairs(t.items) do
  s, c = work(it, 0, s, c)
  local r = R.check(it, c, s)
  if not r.ok then bad = bad + 1 end
  print(string.format("  1.609 x %g = %s (%g)", it.b, r.text, it.exact))
end
print(bad == 0 and "all right with the parts exactly placed" or (bad .. " WRONG"))
