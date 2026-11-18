--
-- states.lua -- the suanpan manual's examples, worked by plan.lua itself
-- (Babbage's Hall). From the exhibit's folder: lua manual/states.lua
--
-- Prints one line for each state the manual draws:
--   example|caption|d1,d2,...,d7|rod,deck,count;...   (the moves just made)
-- make-figures.py reads them, so the pictures show exactly what the
-- exhibit's own rules do.
--
local P = dofile("plan.lua")
local function clear() return { 0, 0, 0, 0, 0, 0, 0 } end
local function set(n) local d = clear(); P.number(d, n); return d end
local NAMES = { "A", "B", "C", "D", "E", "F", "G" }
local RULE = { direct = "direct", direct5 = "direct, with the heaven bead", five = "five-complement",
               ten = "ten-complement", tenfive = "ten- and five-complement", ten5 = "ten-complement, with the heaven bead",
               sdirect = "direct", sdirect5 = "direct, with the heaven bead", sfive = "five-complement",
               sten = "ten-complement", stenfive = "ten- and five-complement", sten5 = "ten-complement, with the heaven bead",
               mset = "the multiplier set", aset = "the multiplicand set", times = "a product added",
               mdone = "the digit used: its rod cleared", mclear = "the multiplier cleared" }
local function out(ex, caption, d, mv)
  local m = {}
  for _, x in ipairs(mv or {}) do m[#m + 1] = x[1] .. "," .. x[2] .. "," .. x[3] end
  print(ex .. "|" .. caption .. "|" .. table.concat(d, ",") .. "|" .. table.concat(m, ";"))
end
local function copy(d) local c = {}; for i, v in ipairs(d) do c[i] = v end; return c end

-- the parts: 1972 on the abacus
out("parts", "1972", set(1972))

-- each rule once, on the units rod (and the tens for a carry)
local function one(ex, start, a, sub)
  local d = set(start)
  out(ex, "before", copy(d))
  local steps = sub and P.sub(d, 7, a) or P.add(d, 7, a)
  local shown = copy(set(start))
  for _, st in ipairs(steps) do
    for _, mv in ipairs(st.moves) do
      local dg = shown[mv[1]]
      local h, e = dg >= 5 and 1 or 0, dg % 5
      if mv[2] == "heaven" then h = mv[3] else e = mv[3] end
      shown[mv[1]] = 5 * h + e
      out(ex, (RULE[st.rule] or st.rule) .. (st.carry and " (the carry)" or st.borrow and " (the borrow)" or ""), copy(shown), { mv })
    end
  end
end
one("direct", 1, 3)           -- 1 + 3: three earth beads up
one("direct5", 2, 7)          -- 2 + 7: the heaven bead down, two earth beads up
one("five", 3, 3)             -- 3 + 3 = 3 + 5 - 2
one("ten", 4, 8)              -- 4 + 8 = 4 + 10 - 2
one("tenfive", 5, 6)          -- 5 + 6 = 5 + 10 - 4, and -4 = -5 + 1
one("sdirect", 4, 3, true)    -- 4 - 3
one("sfive", 6, 3, true)      -- 6 - 3 = 6 - 5 + 2
one("sten", 12, 8, true)      -- 12 - 8 = 12 - 10 + 2

-- a whole addition: 47 + 85, rod by rod from the left
do
  local d = set(47)
  out("add", "47 on the abacus", copy(d))
  local steps = P.number(d, 85)
  local shown = set(47)
  for _, st in ipairs(steps) do
    for _, mv in ipairs(st.moves) do
      local dg = shown[mv[1]]
      local h, e = dg >= 5 and 1 or 0, dg % 5
      if mv[2] == "heaven" then h = mv[3] else e = mv[3] end
      shown[mv[1]] = 5 * h + e
    end
    out("add", string.format("rod %s: %s %d, %s", NAMES[st.rod], st.carry and "carry" or "add", st.a, RULE[st.rule]), copy(shown), st.moves)
  end
end

-- taking 1 from 2000: the borrow runs left, then the nines fill back
do
  local d = set(2000)
  out("borrow", "2000 on the abacus", copy(d))
  local steps = P.subNumber(d, 1)
  local shown = set(2000)
  for _, st in ipairs(steps) do
    for _, mv in ipairs(st.moves) do
      local dg = shown[mv[1]]
      local h, e = dg >= 5 and 1 or 0, dg % 5
      if mv[2] == "heaven" then h = mv[3] else e = mv[3] end
      shown[mv[1]] = 5 * h + e
    end
    if #st.moves > 0 then
      local label
      if st.again and st.rod < 7 then label = string.format("rod %s: 9 (the ten borrowed, less the 1 passed on)", NAMES[st.rod])
      elseif st.again then label = string.format("rod %s: the ten borrowed, less %d: %d", NAMES[st.rod], st.a, 10 - st.a)
      else label = string.format("rod %s: 1 taken for the rod on its right", NAMES[st.rod]) end
      out("borrow", label, copy(shown), st.moves)
    end
  end
end

-- 36 x 4, Kojima's way: after each stage
do
  local d = clear()
  local steps = P.multiply(d, 36, 4)
  local shown = clear()
  local stage, label = 0, nil
  local function flush() if label then out("multiply", label, copy(shown)) end end
  for _, st in ipairs(steps) do
    if st.rule == "mset" or st.rule == "aset" or st.rule == "times" or st.rule == "mdone" or st.rule == "mclear" then
      flush()
      if st.rule == "mset" then label = "the multiplier, 4, on rod A"
      elseif st.rule == "aset" then label = "the multiplicand, 36, on rods " .. NAMES[st.rod] .. " and " .. NAMES[st.rod + 1]
      elseif st.rule == "times" then label = string.format("%d x %d = %02d, added on rods %s and %s", st.a, st.b, st.a * st.b, NAMES[st.rod], NAMES[st.rod + 1])
      elseif st.rule == "mdone" then label = "the " .. st.a .. " used: rod " .. NAMES[st.rod] .. " cleared"
      else label = "the multiplier cleared: the product, 144" end
    end
    for _, mv in ipairs(st.moves) do
      local dg = shown[mv[1]]
      local h, e = dg >= 5 and 1 or 0, dg % 5
      if mv[2] == "heaven" then h = mv[3] else e = mv[3] end
      shown[mv[1]] = 5 * h + e
    end
  end
  flush()
end
