--
-- rule.lua -- the slide rule's scales and how it is worked (Babbage's Hall)
--
-- Every scale is a function from a number to a place along the rule (cm,
-- from the left index; L = 25 cm, one decade of C and D). The slide's
-- place s is how far its left index (C's 1) stands right of D's (C reads
-- 10^((x - s) / L) where D reads 10^(x / L)); the cursor's place c is
-- where its hairline is. A plan is the moves a person makes, one at a
-- time ({ say, part = "slide" | "cursor", x }), then a reading: which
-- scale, under the hairline, and how that reading becomes the answer (the
-- decimal point is not on the rule: the person places it).
--
-- A move is made as a person makes it, against what is there: the cursor
-- to a number on the stock (x), or to a mark on the slide wherever the
-- slide is (onSlide: that far along it from C's 1; "index", C's 1 or 10,
-- whichever is on the rule); the slide to put one of its marks under the
-- hairline wherever the hairline is (toHairline). So an error in setting
-- one part is carried into the reading, as on a real rule. R.target
-- resolves a move against where the parts stand.
--
-- No physics here: slide-rule.lua makes the moves with the parts, reads
-- the scales from where they ended up, and checks the answer;
-- rule-test.lua checks the plans against plain arithmetic.
--

local R = {}
local L = 25
R.L = L
local log10 = function(v) return math.log(v) / math.log(10) end
R.log10 = log10

-- a number as mantissa (1 <= m < 10) and exponent
function R.split(v)
  local e = math.floor(log10(v) + 1e-9)
  local m = v / 10 ^ e
  if m >= 10 - 1e-9 then m, e = m / 10, e + 1 end
  if m < 1 then m, e = m * 10, e - 1 end
  return m, e
end

-- what each scale reads at a place (x along the stock; s the slide's place)
R.read = {
  D = function(x, s) return 10 ^ (x / L) end,
  C = function(x, s) return 10 ^ ((x - s) / L) end,
  CI = function(x, s) return 10 ^ (1 - (x - s) / L) end,
  A = function(x, s) return 10 ^ (2 * x / L) end,
  B = function(x, s) return 10 ^ (2 * (x - s) / L) end,
  K = function(x, s) return 10 ^ (3 * x / L) end,
  L = function(x, s) return x / L end,
}

-- how a person reads a scale: the figures the marks allow. C, D and CI to
-- three figures, four from 1 to 2 (marks every 0.01 there, and a fifth
-- of a gap is easily judged); A, B and K to three; L to three decimals.
function R.figures(scale, v)
  if scale == "L" then return nil, 3 end
  local m = R.split(v)
  if (scale == "D" or scale == "C" or scale == "CI") and m < 2 then return 4 end
  return 3
end
-- (a number rounded to so many figures, or decimals)
function R.round(v, figs, decs)
  if decs then local f = 10 ^ decs; return math.floor(v * f + 0.5) / f end
  if v == 0 then return 0 end
  local e = math.floor(log10(math.abs(v)) + 1e-9)
  local f = 10 ^ (figs - 1 - e)
  return math.floor(v * f + 0.5) / f
end
-- (the size of the last figure read)
function R.unit(v, figs, decs)
  if decs then return 10 ^ -decs end
  local e = math.floor(log10(math.abs(v)) + 1e-9)
  return 10 ^ (e - figs + 1)
end
-- a number as the slate writes it, with so many figures (or decimals)
function R.text(v, figs, decs)
  if decs then return string.format("%." .. decs .. "f", v) end
  local e = math.floor(log10(math.abs(v)) + 1e-9)
  local d = math.max(0, figs - 1 - e)
  local s = string.format("%." .. d .. "f", v)
  return s
end
-- (one figure, for an estimate)
local function one(v) return R.round(v, 1) end

-- the decimal point: of the numbers 10^k times the figures read, the one
-- nearest the estimate
function R.place(mant, estimate)
  local best, bd
  for k = -8, 8 do
    local v = mant * 10 ^ k
    local d = math.abs(log10(v) - log10(estimate))
    if not bd or d < bd then best, bd = v, d end
  end
  return best
end

-- ---------------------------------------------------------------------
-- the plans
-- ---------------------------------------------------------------------
-- multiplying: the cursor to a on D, C's index under it, the cursor to b
-- on C, the product on D. If b would run off the right end, C's right
-- index (10) goes under a instead, and the slide stands out to the left.
function R.multiply(a, b)
  local ma, mb = R.split(a), R.split(b)
  local xa, xb = L * log10(ma), L * log10(mb)
  local right = ma * mb >= 10
  local s = right and xa - L or xa
  local est = one(a) * one(b)
  return {
    what = "x", a = a, b = b, exact = a * b, read = "D",
    estimate = { one(a), "x", one(b), est },
    steps = {
      { say = "m1", part = "cursor", x = xa },
      { say = right and "m2r" or "m2", part = "slide", toHairline = right and L or 0 },
      { say = "m3", part = "cursor", onSlide = xb },
      { say = "m4" },
    },
    answer = function(r) return R.place(r, est) end,
  }
end
-- one setting, many products: the slide set for a, then the cursor to
-- each b in turn (a table of a times anything; the index chosen so that
-- every b is on the rule, if one is)
function R.table(a, bs)
  local ma = R.split(a)
  local xa = L * log10(ma)
  local lo, hi = 10, 1
  for _, b in ipairs(bs) do local m = R.split(b); lo, hi = math.min(lo, m), math.max(hi, m) end
  local right = ma * lo >= 10
  if not right and ma * hi >= 10 then return nil end
  local s = right and xa - L or xa
  local t = { what = "table", a = a, bs = bs, s = s, items = {} }
  t.steps = {
    { say = "m1", part = "cursor", x = xa },
    { say = right and "m2r" or "m2", part = "slide", toHairline = right and L or 0 },
  }
  for k, b in ipairs(bs) do
    local mb = R.split(b)
    local est = one(a) * one(b)
    t.items[k] = { what = "x", a = a, b = b, exact = a * b, read = "D", estimate = { one(a), "x", one(b), est },
                   steps = { { say = k == 1 and "m3" or "mt", part = "cursor", onSlide = L * log10(mb) }, { say = "m4" } },
                   answer = function(r) return R.place(r, est) end }
  end
  return t
end
-- dividing: the cursor to a on D, b on C under it, the quotient on D at
-- C's index (the left one if it is on the rule, else the right)
function R.divide(a, b)
  local ma, mb = R.split(a), R.split(b)
  local xa, xb = L * log10(ma), L * log10(mb)
  local s = xa - xb
  local c = s >= 0 and s or s + L
  local est = one(a) / one(b)
  return {
    what = "d", a = a, b = b, exact = a / b, read = "D",
    estimate = { one(a), "d", one(b), one(est) },
    steps = {
      { say = "d1", part = "cursor", x = xa },
      { say = "d2", part = "slide", toHairline = xb },
      { say = s >= 0 and "d3" or "d3r", part = "cursor", onSlide = "index" },
      { say = "d4" },
    },
    answer = function(r) return R.place(r, est) end,
  }
end
-- (the slide home: for the scales read with the slide closed)
local function closed(steps, slideAt)
  if slideAt and math.abs(slideAt) > 0.001 then table.insert(steps, 1, { say = "close", part = "slide", x = 0 }) end
  return steps
end
-- a square: the cursor to x on D, its square on A
function R.square(v, slideAt)
  local m, e = R.split(v)
  return { what = "q", a = v, exact = v * v, read = "A",
           steps = closed({ { say = "s1", part = "cursor", x = L * log10(m) }, { say = "s2" } }, slideAt),
           answer = function(r) return r * 10 ^ (2 * e) end }
end
-- a square root: x on A, in its left half if x has an odd number of
-- figures before the point (1 to 9, 100 to 999 ...), else in its right
-- half; the root on D
function R.root(v, slideAt)
  local m, e = R.split(v)
  local odd = e % 2 == 0                       -- (1 figure before the point: e = 0)
  local a = odd and m or 10 * m
  local half = odd and "r1a" or "r1b"
  return { what = "r", a = v, exact = math.sqrt(v), read = "D",
           steps = closed({ { say = half, part = "cursor", x = L / 2 * log10(a) }, { say = "r2" } }, slideAt),
           answer = function(r) return r * 10 ^ math.floor(e / 2) end }
end
-- a cube: x on D, its cube on K
function R.cube(v, slideAt)
  local m, e = R.split(v)
  return { what = "c", a = v, exact = v ^ 3, read = "K",
           steps = closed({ { say = "k1", part = "cursor", x = L * log10(m) }, { say = "k2" } }, slideAt),
           answer = function(r) return r * 10 ^ (3 * e) end }
end
-- a reciprocal: x on C, 1/x on CI (the slide closed, or anywhere: C and
-- CI are both on it; closed, so that D reads x too)
function R.reciprocal(v, slideAt)
  local m, e = R.split(v)
  return { what = "i", a = v, exact = 1 / v, read = "CI",
           steps = closed({ { say = "i1", part = "cursor", onSlide = L * log10(m) }, { say = "i2" } }, slideAt),
           -- (CI reads 10 / m: from 1 to 10)
           answer = function(r) return r * 10 ^ (-e - 1) end }
end
-- a logarithm: x on D, the figures of its logarithm on L; the whole
-- number before them is where x's point is (its exponent)
function R.logarithm(v, slideAt)
  local m, e = R.split(v)
  return { what = "l", a = v, exact = log10(v), read = "L",
           steps = closed({ { say = "l1", part = "cursor", x = L * log10(m) }, { say = "l2" } }, slideAt),
           answer = function(r) return e + r end, decs = 3 }
end

-- where a move puts its part, given where the slide (s) and the hairline
-- (c) stand now
function R.target(st, s, c)
  if st.x then return st.x end
  if st.toHairline then return c - st.toHairline end
  if st.onSlide == "index" then return s >= 0 and s or s + L end
  return s + st.onSlide
end

-- the reading checked: the figures read from the scale where the hairline
-- stands, the answer, and whether it is the true answer to the figures read
-- (within one in the last figure)
function R.check(p, c, s)
  local raw = R.read[p.read](c, s)
  local figs, decs = R.figures(p.read, raw)
  local seen = R.round(raw, figs, decs)
  local ans = p.answer(seen)
  local afigs, adecs = figs, decs
  if p.what == "l" then adecs = 3 end
  local want = R.round(p.exact, afigs, adecs)
  local unit = R.unit(ans, afigs, adecs)
  local ok = math.abs(R.round(ans, afigs, adecs) - want) <= unit * 1.0001
  return { raw = raw, seen = seen, figs = figs, decs = decs, answer = R.round(ans, afigs, adecs),
           want = want, ok = ok, text = R.text(R.round(ans, afigs, adecs), afigs, adecs) }
end

-- the slate's text for a problem: one character a picture (x times, d
-- divided by, q squared, c cubed, r root, s slash, l log, ~ about)
local function num(v)
  local s = string.format("%.6g", v)
  return s
end
function R.problem(p)
  if p.what == "x" then return num(p.a) .. "x" .. num(p.b)
  elseif p.what == "d" then return num(p.a) .. "d" .. num(p.b)
  elseif p.what == "q" then return num(p.a) .. "q"
  elseif p.what == "c" then return num(p.a) .. "c"
  elseif p.what == "r" then return "r" .. num(p.a)
  elseif p.what == "i" then return "1s" .. num(p.a)
  elseif p.what == "l" then return "l" .. num(p.a) end
end
function R.estimateText(p)
  local e = p.estimate
  if not e then return "" end
  return "~" .. num(e[1]) .. e[2] .. num(e[3]) .. "=" .. num(e[4])
end

return R
