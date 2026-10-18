--
-- ch11/mfp_theory.lua -- the mean free path for uniform coverage, 2D and 3D
--
-- Sec. 11.3 (PDF 380-383): the mean free path is the average distance a
-- robot travels to enter an adjacent cell. Listing 11.4 estimates it by
-- simulation: the robot uniform in a unit cell at (x1, y1), the entry point
-- just inside the next cell at (1.001, y2), y2 uniform; the text prints a
-- mean of 0.6517 (10^7 samples), and Eq. 11.2-11.4 integrate it exactly
-- (entry at 1) to 0.651757. At 1.001 the mean is 0.6525 (FINDINGS F14;
-- ch11/listing_11_4.lua runs the listing with the book's own generator).
-- Cells of size c then use a mean free path f * c.
--
-- In 3D the cells are cubes with face neighbours, and the same construction
-- puts the robot uniform in a unit cube at (x1, y1, z1) and the entry point
-- uniform on the shared face at (1.001, y2, z2).
--
-- The buffer variant follows Sec. 11.3's last paragraph: a robot keeps a
-- wall response range of 1 on cells of 20 (5%), so x1 is in [0.05, 1] and
-- the lateral coordinates are in [0.05, 0.95]. The book gives 0.6079.
--
-- Exact values (ch11/mfp_exact.py; see ch11/README.md):
--   2D  0.651756791456   = (2 + sqrt2 + 5 ln(1 + sqrt2)) / 12
--   2D, 5% buffer   0.607938826088
--   3D  0.771991712645   = (4 + 17 sqrt2 - 6 sqrt3 - 7 pi
--                           + 21 ln(1 + sqrt2) + 42 ln(2 + sqrt3)) / 90
--   3D, 5% buffer   0.713804036826
--
-- Run from the ArtificialPhysics folder (about a minute at 10^7 samples):
--   lua5.1 ch11/mfp_theory.lua            N=1000000 lua5.1 ch11/mfp_theory.lua
-- Returns (when required) a table with run(dim, buffer, n, seed).
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]ch11[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local rng = require "lib.rng"

local M = {}

-- The integrals (entry exactly at x2 = 1), and with the entry at 1.001 as
-- in Listing 11.4, which the simulation should match.
M.exact = {
  ["2D"] = 0.651756791455901, ["2D buffer"] = 0.607938826087858,
  ["3D"] = 0.771991712645039, ["3D buffer"] = 0.713804036825622,
}
M.exactAt1001 = {
  ["2D"] = 0.652500558554881, ["2D buffer"] = 0.608692822366324,
  ["3D"] = 0.772619589135733, ["3D buffer"] = 0.714445427977625,
}

-- Listing 11.4, in 2D or 3D, with or without the 5% buffer. Returns the
-- mean distance and its standard error.
function M.run(dim, buffer, n, seed, x2)
  local s = rng.new(seed or 1)
  local function U(a, b) return a + (b - a) * s:random() end
  local lo, hi = 0, 1                    -- lateral range
  local xlo = 0                          -- the robot's range across the cell
  if buffer then lo, hi, xlo = 0.05, 0.95, 0.05 end
  x2 = x2 or 1.001
  local sum, sq = 0, 0
  for _ = 1, n do
    local x1 = U(xlo, 1)
    local dy = U(lo, hi) - U(lo, hi)
    local d2 = (x2 - x1) ^ 2 + dy * dy
    if dim == 3 then
      local dz = U(lo, hi) - U(lo, hi)
      d2 = d2 + dz * dz
    end
    local d = math.sqrt(d2)
    sum, sq = sum + d, sq + d * d
  end
  local mean = sum / n
  local se = math.sqrt((sq / n - mean * mean) / (n - 1))
  return mean, se
end

-- As a script: all four cases.
if not ... then   -- run as a script, not required
  local n = tonumber(os.getenv("N") or "") or 10000000
  print(string.format("mean free path, Listing 11.4 extended: %d samples per case (%s)", n, _VERSION))
  print("  entry at x2 = 1.001 as in the book, compared with the exact value for 1.001;")
  print("  the last column is the integral itself (entry exactly at 1), the mean free path f")
  print(string.format("  %-10s %10s %9s %13s %7s %13s", "case", "simulated", "+- s.e.", "exact 1.001", "z", "f (exact)"))
  for i, c in ipairs({ { 2, false, "2D" }, { 2, true, "2D buffer" }, { 3, false, "3D" }, { 3, true, "3D buffer" } }) do
    local mean, se = M.run(c[1], c[2], n, i)
    local ex = M.exactAt1001[c[3]]
    print(string.format("  %-10s %10.6f %9.6f %13.9f %7.2f %13.9f", c[3], mean, se, ex, (mean - ex) / se, M.exact[c[3]]))
  end
end

return M
