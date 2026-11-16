-- plan.lua -- the suanpan's rules, as moves of beads (Babbage's Hall)
--
-- A rod's digit is 5 h + e: h heaven beads down at the beam (0 or 1), e
-- earth beads up at it (0 to 4). Adding a digit a to a rod, as it is taught:
--
--   direct          there is room: earth beads up (a < 5), or the heaven
--                   bead down and earth beads up (a >= 5)
--   five-complement a < 5 and not enough earth beads left: the heaven bead
--                   down and 5 - a earth beads down (a = 5 - (5 - a))
--   ten-complement  the rod would pass 9: take 10 - a from it and carry 1
--                   to the rod on the left (a = 10 - (10 - a)); taking it
--                   may itself need the heaven bead (10 - a = 5 - ...)
--
-- Taking a digit away is the same rules backward (rule names begin "s"):
--
--   direct          enough on the rod: earth beads down, or the heaven bead
--                   up and earth beads down
--   five-complement not enough earth beads: the heaven bead up and 5 - a
--                   earth beads up (-a = -5 + (5 - a))
--   ten-complement  not enough on the rod: borrow 1 from the rod on the
--                   left, then add 10 - a to this one (-a = -10 + (10 - a));
--                   adding it may itself need the heaven bead
--
-- Multiplying (Kojima's way, the modern method): the multiplier on the
-- rods at the left, the multiplicand to its right, with m + 1 rods free
-- to its right (m the multiplier's digits). The multiplicand's digits are
-- used from its right: each times each digit of the multiplier, from its
-- left, a two-digit product (3 x 2 is 06), added with its tens on the rod
-- k to the right of the digit (k = 1 for the multiplier's first digit)
-- and its units on the next. The digit's rod is then cleared. When all
-- are used the product is on the rods at the right, and the multiplier is
-- cleared too, so the abacus reads the product.
--
-- plan.add(digits, rod, a) changes digits (digits[1] the leftmost rod) and
-- returns the steps: each { rod, rule, a, moves }, a move { rod, deck,
-- count } ("heaven" or "earth": how many beads at the beam after it).
-- plan.number(digits, n) adds a whole number, digit by digit from the
-- left, as an abacus is worked; plan.subNumber(digits, n) takes one away.
-- plan.multiply(digits, a, b) works a times b on a clear abacus. The rule
-- names are the slate's.

local M = {}

local function hOf(d) return d >= 5 and 1 or 0 end
local function eOf(d) return d % 5 end

-- (moves to take the rod from digit d0 to d1, in the order a hand makes them)
local function moves(rod, d0, d1, heavenFirst)
  local m = {}
  local h0, e0, h1, e1 = hOf(d0), eOf(d0), hOf(d1), eOf(d1)
  local hm = h0 ~= h1 and { rod, "heaven", h1 } or nil
  local em = e0 ~= e1 and { rod, "earth", e1 } or nil
  if heavenFirst then m[#m + 1] = hm; m[#m + 1] = em else m[#m + 1] = em; m[#m + 1] = hm end
  return m          -- (a nil move was never stored: m holds only the moves made)
end

-- add a (1..9) to rod; carry is true when it is a carry from the right
function M.add(digits, rod, a, carry, steps)
  steps = steps or {}
  local d = digits[rod]
  assert(d, "plan: no rod " .. tostring(rod))
  if d + a <= 9 then
    local rule
    if a < 5 then
      rule = (eOf(d) + a <= 4) and "direct" or "five"
    else
      rule = "direct5"
    end
    -- (the five-complement: the heaven bead down first, then the earth beads)
    steps[#steps + 1] = { rod = rod, rule = rule, a = a, carry = carry, d0 = d, d1 = d + a,
                          moves = moves(rod, d, d + a, rule ~= "direct") }
    digits[rod] = d + a
  else
    assert(rod > 1, "plan: the abacus is full")
    local c = 10 - a
    local rule
    if c < 5 then rule = (eOf(d) >= c) and "ten" or "tenfive"
    else rule = "ten5" end
    steps[#steps + 1] = { rod = rod, rule = rule, a = a, carry = carry, d0 = d, d1 = d - c,
                          moves = moves(rod, d, d - c, rule == "ten5") }
    digits[rod] = d - c
    M.add(digits, rod - 1, 1, true, steps)
  end
  return steps
end

-- add a whole number, its digits lined up with the rods from the right
function M.number(digits, n)
  local s = tostring(math.floor(n))
  local steps = {}
  local R = #digits
  assert(#s <= R, "plan: too many digits")
  for i = 1, #s do
    local a = tonumber(s:sub(i, i))
    local rod = R - #s + i
    if a > 0 then M.add(digits, rod, a, false, steps) end
  end
  return steps
end

-- take a (1..9) from rod; borrow is true when it is a borrow for the right
function M.sub(digits, rod, a, borrow, steps)
  steps = steps or {}
  local d = digits[rod]
  assert(d, "plan: no rod " .. tostring(rod))
  if d - a >= 0 then
    local rule
    if a < 5 then rule = (eOf(d) >= a) and "sdirect" or "sfive"
    else rule = "sdirect5" end
    steps[#steps + 1] = { rod = rod, rule = rule, a = a, borrow = borrow, d0 = d, d1 = d - a,
                          moves = moves(rod, d, d - a, rule ~= "sdirect") }
    digits[rod] = d - a
  else
    assert(rod > 1, "plan: not that much on the abacus")
    local c = 10 - a
    local rule
    if c < 5 then rule = (eOf(d) + c <= 4) and "sten" or "stenfive"
    else rule = "sten5" end
    -- (the rule said first; the borrow from the left done; then this rod's
    -- beads: as it is taught, "take one from the left, then add ...")
    steps[#steps + 1] = { rod = rod, rule = rule, a = a, borrow = borrow, d0 = d, d1 = d, moves = {} }
    M.sub(digits, rod - 1, 1, true, steps)
    steps[#steps + 1] = { rod = rod, rule = rule, a = a, borrow = borrow, d0 = d, d1 = d + c,
                          moves = moves(rod, d, d + c, rule ~= "sten"), again = true }
    digits[rod] = d + c
  end
  return steps
end

-- take a whole number away, its digits lined up with the rods from the right
function M.subNumber(digits, n)
  local s = tostring(math.floor(n))
  local steps = {}
  local R = #digits
  assert(#s <= R, "plan: too many digits")
  assert(n <= M.value(digits), "plan: not that much on the abacus")
  for i = 1, #s do
    local a = tonumber(s:sub(i, i))
    local rod = R - #s + i
    if a > 0 then M.sub(digits, rod, a, false, steps) end
  end
  return steps
end

-- (a rod cleared by hand: its beads away from the beam, not a rule)
local function clearRod(digits, rod, rule, steps)
  local d = digits[rod]
  if d == 0 then return end
  steps[#steps + 1] = { rod = rod, rule = rule, a = d, d0 = d, d1 = 0, moves = moves(rod, d, 0, true) }
  digits[rod] = 0
end

-- where a times b goes on R rods: the multiplier's rods, the multiplicand's
-- first rod (nil if it doesn't fit). b the multiplier, m digits; a the
-- multiplicand, n digits: needs n + 2 m <= R - 1 (the product, n + m digits,
-- ends on the units rod, and starts right of the multiplicand's first rod)
function M.layout(R, a, b)
  local n, m = #tostring(a), #tostring(b)
  local s = R - n - m
  if s <= m then return nil end
  return s, n, m
end

-- a times b on a clear abacus: the steps, each as plan.add's, and some of
-- their own: { rule = "mset" | "aset" } (setting the multiplier, the
-- multiplicand: the rod is the first), { rule = "times", a = digit, b =
-- digit, rod = where its tens go }, { rule = "mdone" } (a digit used, its
-- rod cleared), { rule = "mclear" } (a rod of the multiplier cleared)
function M.multiply(digits, a, b)
  local R = #digits
  for i = 1, R do assert(digits[i] == 0, "plan: multiplying needs a clear abacus") end
  local s, n, m = M.layout(R, a, b)
  assert(s, "plan: too long for the rods")
  local A, B = tostring(a), tostring(b)
  local steps = {}
  steps[#steps + 1] = { rule = "mset", rod = 1, a = b, moves = {} }
  for k = 1, m do
    local d = tonumber(B:sub(k, k))
    if d > 0 then M.add(digits, k, d, false, steps) end
  end
  steps[#steps + 1] = { rule = "aset", rod = s, a = a, moves = {} }
  for k = 1, n do
    local d = tonumber(A:sub(k, k))
    if d > 0 then M.add(digits, s + k - 1, d, false, steps) end
  end
  for i = n, 1, -1 do
    local r = s + i - 1
    local d = tonumber(A:sub(i, i))
    if d > 0 then
      for k = 1, m do
        local e = tonumber(B:sub(k, k))
        if e > 0 then
          local p = d * e
          steps[#steps + 1] = { rule = "times", a = d, b = e, rod = r + k, moves = {} }
          local t, u = math.floor(p / 10), p % 10
          if t > 0 then M.add(digits, r + k, t, false, steps) end
          if u > 0 then M.add(digits, r + k + 1, u, false, steps) end
        end
      end
      clearRod(digits, r, "mdone", steps)
    end
  end
  for k = 1, m do clearRod(digits, k, "mclear", steps) end
  return steps
end

function M.value(digits)
  local v = 0
  for _, d in ipairs(digits) do v = v * 10 + d end
  return v
end

return M
