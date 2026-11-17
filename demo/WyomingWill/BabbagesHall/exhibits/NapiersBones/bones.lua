--
-- bones.lua -- Napier's bones and Genaille-Lucas rods: what is on them,
-- which rods lay a number, and how a row is read (Babbage's Hall)
--
-- No physics here: napiers-bones.lua lays the rods with the parts and reads
-- them from where they lie (which face is up, which cell is on the row);
-- bones-test.lua checks this against plain arithmetic.
--
-- THE SET. Ten four-sided rods, each carrying the tables of four digits, as
-- Glaisher describes Napier's (quoted by MacTutor): 0 1 9 8, 0 2 9 7, 0 3 6
-- 9, 0 4 9 5, 1 2 8 7, 1 3 8 6, 1 4 8 5, 2 3 7 6, 2 4 7 5, 3 4 6 5. Every
-- digit is on four rods, no rod has one twice, and any four-digit number can
-- be laid with four of them (bones-test.lua tries all 10,000). Around each
-- rod the faces go a, b, 9 - a, 9 - b: opposite faces make 9. That is
-- Glaisher's order for nine of the rods; the third he lists 0 3 6 9, and
-- here its 9 is opposite its 0 like the others' (which faces Napier put
-- opposite, the sources don't say).
--
-- A NAPIER FACE: the digit d at the top, then nine cells, the multiples d x
-- 1 to d x 9, each split by a diagonal: the tens above it, the units below.
-- A GENAILLE FACE: rows for 2 to 9 only (1 "is not really needed", Roegel);
-- the row for m holds m entries, one for each carry c the rod to its right
-- can send (0 to m - 1): the units of d x m + c, and a triangle pointing
-- left to the entry on the next rod that the tens (the carry on) selects.
--

local B = {}

B.RODS = {
  { 0, 1, 9, 8 }, { 0, 2, 9, 7 }, { 0, 3, 9, 6 }, { 0, 4, 9, 5 }, { 1, 2, 8, 7 },
  { 1, 3, 8, 6 }, { 1, 4, 8, 5 }, { 2, 3, 7, 6 }, { 2, 4, 7, 5 }, { 3, 4, 6, 5 },
}

-- the digits of a number, left to right (a string of digits in, a table out)
function B.digits(s)
  local t = {}
  for ch in tostring(s):gmatch("%d") do t[#t + 1] = tonumber(ch) end
  return t
end

-- which rods lay a number, and with which face up: one rod for each digit,
-- no rod twice (a matching, by augmenting paths; the lowest rods first).
-- Returns { { rod = r, face = f } ... } left to right, or nil if the set
-- can't lay it
function B.choose(ds)
  local owner = {}                 -- rod -> the place it is given to
  local function try(i, seen)
    for r = 1, #B.RODS do
      if not seen[r] then
        for f = 1, 4 do
          if B.RODS[r][f] == ds[i] then
            seen[r] = true
            if not owner[r] or try(owner[r], seen) then owner[r] = i; return true end
            break
          end
        end
      end
    end
    return false
  end
  for i = 1, #ds do if not try(i, {}) then return nil end end
  local out = {}
  for r, i in pairs(owner) do
    for f = 1, 4 do if B.RODS[r][f] == ds[i] then out[i] = { rod = r, face = f } end end
  end
  return out
end

-- ---------------------------------------------------------------------
-- reading a row of Napier's bones: the cells side by side, then along the
-- diagonals from the right, carrying as a person does
-- ---------------------------------------------------------------------
-- cells: { {tens, units} ... } left to right. Returns the sums along the
-- diagonals (left to right, the leftmost the first rod's tens alone), the
-- carries, and the row's product as a string of digits
function B.diagonals(cells)
  local n = #cells
  -- (n rods make n + 1 places: the first rod's tens; each rod's units with
  -- the next rod's tens, the diagonal between them; the last rod's units)
  local sums = {}
  sums[1] = cells[1][1]
  for i = 1, n - 1 do sums[i + 1] = cells[i][2] + cells[i + 1][1] end
  sums[n + 1] = cells[n][2]
  local out, carry = {}, 0
  local carries = {}
  for i = n + 1, 1, -1 do
    local v = sums[i] + carry
    out[i] = v % 10
    carry = math.floor(v / 10)
    carries[i] = carry
  end
  local s = (carry > 0 and tostring(carry) or "")
  for i = 1, n + 1 do s = s .. out[i] end
  s = s:gsub("^0+(%d)", "%1")
  return sums, carries, s
end
-- the cell of a Napier face: d x k, split
function B.cell(d, k) local v = d * k; return { math.floor(v / 10), v % 10 } end

-- ---------------------------------------------------------------------
-- a Genaille face's row m: its entries, one for each carry coming in
-- ---------------------------------------------------------------------
function B.entries(d, m)
  local e = {}
  for c = 0, m - 1 do local v = d * m + c; e[c + 1] = { units = v % 10, tens = math.floor(v / 10) } end
  return e
end
-- following the triangles: from the top entry of the rightmost rod, right to
-- left; the last carry is read on the index rod. ds: the rods' digits left
-- to right. Returns the product (a string) and the path: { {rod place,
-- entry (0-based)} ... } right to left, the index rod as place 0
function B.genaille(ds, m)
  local path, c, s = {}, 0, ""
  for i = #ds, 1, -1 do
    local e = B.entries(ds[i], m)[c + 1]
    path[#path + 1] = { i, c }
    s = e.units .. s
    c = e.tens
  end
  path[#path + 1] = { 0, c }
  if c > 0 then s = c .. s end
  s = s:gsub("^0+(%d)", "%1")
  return s, path
end

-- ---------------------------------------------------------------------
-- a whole problem: the number laid in rods times a multiplier of one or
-- more digits: a row for each of the multiplier's digits (none for a 0),
-- each moved a place left of the one after it, added up
-- ---------------------------------------------------------------------
-- (a sum of digit strings: the person's addition)
function B.add(a, b)
  local out, carry = "", 0
  local i, j = #a, #b
  while i > 0 or j > 0 or carry > 0 do
    local v = (i > 0 and tonumber(a:sub(i, i)) or 0) + (j > 0 and tonumber(b:sub(j, j)) or 0) + carry
    out = (v % 10) .. out
    carry = math.floor(v / 10)
    i, j = i - 1, j - 1
  end
  out = out:gsub("^0+(%d)", "%1")
  return out == "" and "0" or out
end
-- rowOf(m) gives a row's product as a digit string (from the rods as laid,
-- read the one way or the other). Returns the rows, each { m, product,
-- shifted }, and the total
function B.multiply(mdigits, rowOf)
  local rows, total = {}, "0"
  local n = #mdigits
  for k = 1, n do
    local m = mdigits[k]
    if m > 0 then
      local p = rowOf(m)
      local shifted = p .. string.rep("0", n - k)
      rows[#rows + 1] = { m = m, product = p, shifted = shifted, place = n - k }
      total = B.add(total, shifted)
    end
  end
  return rows, total
end

-- (big products as digit strings, to check against: the schoolbook way)
function B.times(a, b)
  local A, Bd = B.digits(a), B.digits(b)
  local r = {}
  for i = 1, #A + #Bd do r[i] = 0 end
  for i = #A, 1, -1 do
    for j = #Bd, 1, -1 do
      local p = i + j
      r[p] = r[p] + A[i] * Bd[j]
    end
  end
  for p = #r, 2, -1 do r[p - 1] = r[p - 1] + math.floor(r[p] / 10); r[p] = r[p] % 10 end
  local s = table.concat(r):gsub("^0+(%d)", "%1")
  return s
end

return B
