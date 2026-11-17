--
-- bones-test.lua -- Napier's bones and Genaille's rods against plain
-- arithmetic, with no physics (Babbage's Hall). From this folder:
-- lua bones-test.lua
--
local B = dofile("bones.lua")
local bad = 0
local function check(what, got, want)
  if got ~= want then bad = bad + 1; if bad <= 10 then print("  WRONG", what, got, want) end end
end

-- the set: every digit on four rods, no rod with a digit twice
local count = {}
for r, faces in ipairs(B.RODS) do
  local seen = {}
  for _, d in ipairs(faces) do
    assert(not seen[d], "rod " .. r .. " has " .. d .. " twice"); seen[d] = true
    count[d] = (count[d] or 0) + 1
  end
  -- (opposite faces make 9)
  assert(faces[1] + faces[3] == 9 and faces[2] + faces[4] == 9, "rod " .. r .. ": opposite faces")
end
for d = 0, 9 do assert(count[d] == 4, "digit " .. d .. " on " .. tostring(count[d]) .. " rods") end

-- every four-digit string (0000 to 9999) laid with four of the ten rods
local four = 0
for v = 0, 9999 do
  local ds = B.digits(string.format("%04d", v))
  local ch = B.choose(ds)
  if ch then
    four = four + 1
    local used = {}
    for i, c in ipairs(ch) do
      assert(B.RODS[c.rod][c.face] == ds[i]); assert(not used[c.rod]); used[c.rod] = true
    end
  end
end
print(string.format("four-digit numbers the set can lay: %d of 10000", four))
-- and longer ones: how many of each length
for n = 5, 7 do
  local ok, N = 0, 20000
  math.randomseed(n)
  for i = 1, N do
    local s = ""
    for k = 1, n do s = s .. math.random(0, 9) end
    if B.choose(B.digits(s)) then ok = ok + 1 end
  end
  print(string.format("%d-digit numbers the set can lay: %.1f%% (of %d random)", n, 100 * ok / N, N))
end

-- the products: random numbers of 1 to 6 digits (those the set can lay)
-- times 1 to 3 digits, both ways, against the schoolbook product
math.randomseed(1)
local N, tried = 30000, 0
for i = 1, N do
  local s = tostring(math.random(1, 9))
  for k = 2, math.random(1, 6) do s = s .. math.random(0, 9) end
  local m = tostring(math.random(1, 999))
  local ds = B.digits(s)
  if B.choose(ds) then
    tried = tried + 1
    local want = B.times(s, m)
    local _, napier = B.multiply(B.digits(m), function(k)
      local cells = {}
      for j, d in ipairs(ds) do cells[j] = B.cell(d, k) end
      local _, _, p = B.diagonals(cells)
      return p
    end)
    check(s .. " x " .. m .. " (Napier)", napier, want)
    local _, genaille = B.multiply(B.digits(m), function(k)
      if k == 1 then return s end        -- (no row for 1: the number itself)
      return (B.genaille(ds, k))
    end)
    check(s .. " x " .. m .. " (Genaille)", genaille, want)
  end
end
print(string.format("products: %d problems, each both ways; %s", tried, bad == 0 and "all right" or (bad .. " WRONG")))

-- the sources' examples
local function napierOf(s, m)
  local ds = B.digits(s)
  local _, t = B.multiply(B.digits(m), function(k)
    local cells = {}
    for j, d in ipairs(ds) do cells[j] = B.cell(d, k) end
    return select(3, B.diagonals(cells))
  end)
  return t
end
check("6785 x 8 (Wikipedia)", napierOf("6785", "8"), "54280")
check("4138 x 567 (MacTutor)", napierOf("4138", "567"), "2346246")
check("52749 x 4 (Genaille, Wikipedia)", (B.genaille(B.digits("52749"), 4)), "210996")
check("874 x 7 (Genaille, Giesen)", (B.genaille(B.digits("874"), 7)), "6118")
local e = B.entries(4, 7)
local u = {}
for k, x in ipairs(e) do u[k] = x.units end
check("the 4 rod's row 7 (Roegel: 8 9 0 1 2 3 4)", table.concat(u, " "), "8 9 0 1 2 3 4")
print(bad == 0 and "all right" or (bad .. " WRONG"))
