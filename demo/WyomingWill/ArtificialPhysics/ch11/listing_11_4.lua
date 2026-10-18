--
-- ch11/listing_11_4.lua -- Listing 11.4 as printed, with the book's generator
--
-- Sec. 11.3 (PDF 381-382) prints Listing 11.4 with the entry point at
-- x2 = 1.001 and says it "yields a mean free path of 0.6517". This script
-- runs the listing line for line with glibc's random(), the generator the
-- book's C code used (Appendix A), to see which entry point gives 0.6517.
-- It is the evidence for FINDINGS F14.
--
-- DEFINITIONS:
--   x1, y1   the robot, uniform in the unit cell (U = math.random)
--   x2, y2   the entry point: x2 fixed (1.001 as printed, or 1), y2 uniform
--   mean     average of sqrt((x2-x1)^2 + (y2-y1)^2) over N samples
--   s.e.     its standard error; z = (mean - exact) / s.e.
--   exact    the integral for that x2 (ch11/mfp_exact.py; ch11/mfp_theory.lua)
--
-- The generator: Lua 5.1 to 5.3 call the C library's rand(), which on glibc
-- is the same generator as random(); math.randomseed(1) is srandom(1).
-- Only Lua 5.1 gives the book's exact stream: 5.2 and 5.3 discard the
-- first number after seeding, so their stream is glibc's shifted by one
-- draw (statistically the same, different digits; BPP's Lua 5.2 too).
-- Lua 5.4 has its own generator, so this script refuses to run there.
-- lib/rng.lua is not used here on purpose.
--
-- Run from the ArtificialPhysics folder (about 6 s in all at N = 10^7):
--   lua5.1 ch11/listing_11_4.lua            N=1000000 lua5.1 ch11/listing_11_4.lua
-- Measured on glibc, Lua 5.1, N = 10^7 (2026-10-17):
--   x2 = 1.001: 0.652454 (seed 1), 0.652486 (seed 2); exact 0.652501
--   x2 = 1    : 0.651711 (seed 1, the book's srandom(1)), 0.651742 (seed 2);
--               exact 0.651757. Seed 1 prints as 0.6517, the book's number;
--               x2 = 1.001 is about 9 s.e. (0.000087) away from it
--

if _VERSION == "Lua 5.4" then
  print("listing_11_4: needs Lua 5.1-5.3, whose math.random is the C library's")
  return
end

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]ch11[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local theory = require "ch11.mfp_theory"

local N = tonumber(os.getenv("N") or "") or 10000000
local U = math.random

-- Listing 11.4, with x2 as a parameter.
local function listing(seed, x2)
  math.randomseed(seed)
  local sum, sq = 0, 0
  for _ = 1, N do
    local x1 = U(); local y1 = U(); local y2 = U()
    local d = math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
    sum, sq = sum + d, sq + d * d
  end
  local mean = sum / N
  return mean, math.sqrt((sq / N - mean * mean) / (N - 1))
end

print(string.format("Listing 11.4 with the C library's generator (%s), N = %d", _VERSION, N))
print(string.format("  %-6s %4s %10s %9s %10s %7s", "x2", "seed", "mean", "s.e.", "exact", "z"))
for _, x2 in ipairs({ 1.001, 1 }) do
  local exact = x2 == 1 and theory.exact["2D"] or theory.exactAt1001["2D"]
  for seed = 1, 2 do
    local mean, se = listing(seed, x2)
    print(string.format("  %-6s %4d %10.6f %9.6f %10.6f %7.2f", tostring(x2), seed, mean, se, exact, (mean - exact) / se))
  end
end
print("  the book prints 0.6517")
