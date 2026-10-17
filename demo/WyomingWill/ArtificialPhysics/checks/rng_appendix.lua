--
-- checks/rng_appendix.lua -- the book's appendix test as a regression check
--
-- Listing A.1 (PDF 646-648): for each sample make S superfluous calls, then
-- rejection-sample a point in the unit disk and bin its angle. glibc's
-- random(), which is what Lua 5.1's math.random calls, gives a sinusoidal
-- angle histogram at S = 25 (peaks at +-90 deg) and S = 27 (peaks at 0 and
-- 180 deg). The shared generator (lib/rng.lua) must stay flat at every S.
--
-- Test: 10^6 accepted points, 36 bins of 10 deg, chi-square against
-- uniform (35 degrees of freedom, 99.9% cut 66.6), plus the cos 2theta
-- moment (0 for a uniform angle; 1 sigma about 7e-4 at 10^6 points).
--
-- PASS needs lib/rng.lua under the cut at every S. math.random is the
-- negative control: on Linux (glibc) it is expected to fail at S = 25 and
-- 27; if it doesn't, the platform's generator has changed, which is
-- reported as a note, not a failure.
--
-- Run from the ArtificialPhysics folder (about a minute):
--   lua5.1 checks/rng_appendix.lua            (all S below)
--   lua5.1 checks/rng_appendix.lua 0 25 27    (chosen S values)
--   N=200000 lua5.1 checks/rng_appendix.lua   (quicker, less power)
-- It also runs inside BPP: bpp -f checks/rng_appendix.lua -n 1
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local rng = require "lib.rng"

local N      = tonumber(os.getenv("N") or "") or 1000000
local BINS   = 36
local CUT    = 66.6           -- chi-square, 35 dof, 99.9%
local SEED   = 1              -- the book uses srandom(1)
local S_LIST = { 0, 1, 3, 10, 25, 26, 27, 28, 31 }

if arg and #arg > 0 then
  S_LIST = {}
  for i = 1, #arg do S_LIST[#S_LIST + 1] = tonumber(arg[i]) end
end

local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local floor, cos, pi = math.floor, math.cos, math.pi

-- Returns chi-square and the cos 2theta moment for generator `rand`.
local function test(rand, S)
  local counts = {}
  for b = 1, BINS do counts[b] = 0 end
  local m2 = 0
  for _ = 1, N do
    for _ = 1, S do rand() end
    local x, y
    repeat
      x = 2 * rand() - 1
      y = 2 * rand() - 1
    until x * x + y * y <= 1
    local th = atan2(y, x)                       -- (-pi, pi]
    local b = floor((th + pi) / (2 * pi) * BINS) + 1
    if b > BINS then b = BINS end
    counts[b] = counts[b] + 1
    m2 = m2 + cos(2 * th)
  end
  local e, chi2 = N / BINS, 0
  for b = 1, BINS do chi2 = chi2 + (counts[b] - e) ^ 2 / e end
  return chi2, m2 / N
end

print(string.format("rng_appendix: %s, N = %d points, %d bins, cut %.1f, seed %d",
                    _VERSION, N, BINS, CUT, SEED))
print(string.format("%4s  %22s  %22s", "S", "lib/rng.lua chi2 cos2t", "math.random chi2 cos2t"))

local failures, controlNotes = 0, {}
for _, S in ipairs(S_LIST) do
  local mwc = rng.new(SEED)
  local c1, m1 = test(function() return mwc:random() end, S)
  math.randomseed(SEED)
  local c2, m2 = test(math.random, S)
  local ok = c1 < CUT
  if not ok then failures = failures + 1 end
  print(string.format("%4d  %10.1f %+.5f %s  %10.1f %+.5f %s", S,
                      c1, m1, ok and "ok  " or "FAIL",
                      c2, m2, c2 < CUT and "ok" or "biased"))
  if (S == 25 or S == 27) and c2 < CUT then
    controlNotes[#controlNotes + 1] = string.format("math.random passed at S = %d", S)
  end
end

for _, n in ipairs(controlNotes) do
  print("note: " .. n .. (N < 1000000
    and " (at N < 10^6 the test may be too weak to see the bias)"
    or " (expected to fail on glibc; the platform generator differs)"))
end
if failures == 0 then
  print("PASS rng_appendix: lib/rng.lua is flat at every S tested")
else
  print(string.format("FAIL rng_appendix: lib/rng.lua over the cut at %d S value(s)", failures))
end

-- Exit status for scripts that run every check (not inside BPP, where
-- os.exit would close the program).
if not v then os.exit(failures == 0 and 0 or 1) end
