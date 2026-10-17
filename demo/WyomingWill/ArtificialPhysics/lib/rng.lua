--
-- lib/rng.lua -- the shared random number generator (BOOK.md G2)
--
-- Marsaglia's multiply-with-carry (MWC) generator, moved here unchanged
-- from Uniform_Coverage.lua so every Artificial Physics script draws from
-- one well-behaved, seedable source instead of math.random.
--
-- Why not math.random: BPP embeds Lua 5.1, whose math.random() is glibc
-- rand(), i.e. random(), the additive lagged-Fibonacci generator that the
-- book's appendix shows to be biased when each sample takes a fixed small
-- number of draws (book/ch20-appendix.md). Measured in BPP's Lua 5.1 with
-- the appendix's sampling it fails at S = 25 and 27; this generator passes
-- at every S (checks/rng_appendix.lua). It needs only multiply, floor and
-- modulo, and every intermediate value stays below 2^53, so it is exact in
-- Lua 5.1's doubles and gives the same stream on every platform.
--
-- Seeding (the order in which the seed is chosen by rng.init):
--   1. the SEED environment variable, if set (batch runs, probes, checks);
--   2. otherwise the "seed" GUI parameter, if a viewer is passed;
--   3. otherwise the script's own default (e.g. cfg.seed);
--   4. a value of 0 (or none) means a new seed from the clock at each load,
--      which is the old behaviour.
-- The seed actually used is printed ("rng: MWC seed=..."), so every run can
-- be repeated exactly. BPP resets GUI parameters to their defaults whenever a
-- script loads, so the "seed" parameter takes effect through rng.reseed(),
-- which each script calls at the start of its setup (R): with SEED or a
-- nonzero seed parameter, R restarts the stream and repeats the same start;
-- with 0, R carries on with the stream, as before. Each script also re-runs
-- its setup when the seed parameter changes (rng.isSeedChange in its
-- onParamChanged): moving the slider restarts from that seed, and so does
-- BPP's reload, which restores the slider only after the script has run.
-- A probe that seeds
-- explicitly (rng.seed) before calling setup is left alone when neither is
-- set.
--
-- Use:
--   local rng = require "lib.rng"
--   rng.init(v)                  -- once, before the scene draws anything
--   rng.reseed()                 -- at the start of setup (see above)
--   if rng.isSeedChange(name) then setup(...) end  -- in onParamChanged
--   rng.random()                 -- float in [0, 1)
--   rng.random(n), rng.random(m, n) -- integers, as math.random
--   rng.gauss()                  -- standard normal
--   rng.seed(s)                  -- reseed the shared stream explicitly
--   local s = rng.new(42)        -- an independent stream with its own state,
--   s:random(); s:gauss()        -- e.g. one per purpose (placement, noise)
--
-- Works in BPP and in plain lua5.1 (the viewer argument is optional).
--

local M = {}

local TWO32 = 4294967296
local Z0, W0 = 362436069, 521288629   -- Marsaglia's defaults

local floor, sqrt, log, cos, pi = math.floor, math.sqrt, math.log, math.cos, math.pi

-- One generator stream. Fields: z, w (state), seedValue (last seed given).
local Stream = {}
Stream.__index = Stream

-- Same seeding as the original mwcSeed() in Uniform_Coverage.lua, so a
-- given seed gives the same stream it would have given there.
function Stream:seed(seed)
  seed = floor(math.abs(tonumber(seed) or 1)) % TWO32
  if seed == 0 then seed = 1 end
  self.seedValue = seed
  self.z = seed
  self.w = (seed * 69069 + 1) % TWO32
  if self.z == 0 then self.z = Z0 end
  if self.w == 0 then self.w = W0 end
  self.gaussSpare = nil
  return seed
end

-- Uniform float in [0, 1): the original rnd().
local function nextFloat(self)
  local z = 36969 * (self.z % 65536) + floor(self.z / 65536)
  local w = 18000 * (self.w % 65536) + floor(self.w / 65536)
  self.z, self.w = z, w
  return (((z % 65536) * 65536 + w) % TWO32) / TWO32
end

-- math.random's three forms: () -> [0, 1); (n) -> 1..n; (m, n) -> m..n.
function Stream:random(m, n)
  local r = nextFloat(self)
  if m == nil then return r end
  if n == nil then m, n = 1, m end
  m, n = floor(m), floor(n)
  if m > n then error("rng.random: interval is empty", 2) end
  return m + floor(r * (n - m + 1))
end

-- Standard normal by Box-Muller, using both values of each pair.
function Stream:gauss()
  local g = self.gaussSpare
  if g then self.gaussSpare = nil; return g end
  local u1 = nextFloat(self)
  local u2 = nextFloat(self)
  local r = sqrt(-2 * log(1 - u1))        -- 1 - u1 is in (0, 1]
  self.gaussSpare = r * math.sin(2 * pi * u2)
  return r * cos(2 * pi * u2)
end

function Stream:getSeed() return self.seedValue end

-- A new independent stream.
function M.new(seed)
  local s = setmetatable({}, Stream)
  s:seed(seed or 1)
  return s
end

-- The shared stream that scripts use through the module functions.
local shared = M.new(1)
M.shared = shared

function M.seed(s) return shared:seed(s) end
function M.random(m, n)
  if m == nil then return nextFloat(shared) end
  return shared:random(m, n)
end
function M.gauss() return shared:gauss() end
function M.getSeed() return shared.seedValue end

-- A seed from the clock (the old behaviour). os.clock separates two loads
-- within the same second; batch runs should pass SEED instead.
function M.clockSeed()
  return (os.time() + floor((os.clock() % 1) * 1e6)) % 2147483647 + 1
end

local viewerRef
local initialised = false

-- The slider's range. BPP keeps parameter ranges as floats and turns them
-- into an integer slider (value / step), so a huge maximum overflows it and
-- the slider will not move; floats are also exact only up to 2^24. Seeds
-- beyond this range are still fine through SEED.
M.SEED_PARAM_MAX = 1000

local SEED_COMMENT = "random number seed (applies on R): 0 = a new seed from the clock each load "
  .. "and each R carries on; 1-1000 = R repeats the same start. The SEED environment variable overrides it"

-- Choose the seed (see the header), seed the shared stream, print it and
-- return it. viewer is BPP's `v` (optional); default is the script's own
-- fallback seed (optional; 0 or nil = clock).
function M.init(viewer, default)
  viewerRef = viewer
  local s = default or 0
  local source = default and default ~= 0 and "script" or "clock"
  if viewer then
    pcall(function() viewer:addParam("seed", 0, 0, M.SEED_PARAM_MAX, 1, SEED_COMMENT) end)
    local ok, p = pcall(function() return viewer:getParam("seed") end)
    p = ok and tonumber(p) or 0
    if p ~= 0 then s, source = p, "seed parameter" end
  end
  local env = os.getenv("SEED")
  if env and env ~= "" and tonumber(env) then s, source = tonumber(env), "SEED" end
  if s == 0 then s, source = M.clockSeed(), "clock" end
  local used = M.seed(s)
  print(string.format("rng: MWC seed=%d (%s) %s", used, source, _VERSION))
  initialised = true
  return used
end

-- True when an onParamChanged callback sees the seed parameter change
-- after rng.init (so not for init's own addParam): the script should then
-- re-run its setup, which reseeds.
function M.isSeedChange(name)
  return name == "seed" and initialised
end

-- The seed fixed by SEED or a nonzero seed parameter, or nil if neither.
local function fixedSeed()
  local env = os.getenv("SEED")
  if env and env ~= "" and tonumber(env) then return tonumber(env), "SEED" end
  if viewerRef then
    local ok, p = pcall(function() return viewerRef:getParam("seed") end)
    p = ok and tonumber(p) or 0
    if p ~= 0 then return p, "seed parameter" end
  end
  return nil
end

-- Called at the start of a scene's setup: restart the stream from a fixed
-- seed if there is one; otherwise leave the stream as it is.
function M.reseed()
  local s, source = fixedSeed()
  if not s then return nil end
  local used = M.seed(s)
  print(string.format("rng: MWC seed=%d (%s, setup)", used, source))
  return used
end

return M
