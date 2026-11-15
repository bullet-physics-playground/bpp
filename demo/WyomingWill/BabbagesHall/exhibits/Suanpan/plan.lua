-- plan.lua -- the suanpan's rules for adding, as moves of beads (Babbage's Hall)
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
-- plan.add(digits, rod, a) changes digits (digits[1] the leftmost rod) and
-- returns the steps: each { rod, rule, a, moves }, a move { rod, deck,
-- count } ("heaven" or "earth": how many beads at the beam after it).
-- plan.number(digits, n) adds a whole number, digit by digit from the
-- left, as an abacus is worked. The rule names are the slate's.

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

function M.value(digits)
  local v = 0
  for _, d in ipairs(digits) do v = v * 10 + d end
  return v
end

return M
