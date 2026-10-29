--
-- ch07/theory.lua -- Ch. 7's three theory experiments (PDF 239-243) on
-- Kerr's simulator (ch07/kerr.lua), measured as his 2004 drivers measured
-- them (ch07/kerr/*/experiments/) and as the book defines its error; with
-- any of kerr.lua's fixes switched on. Prints one line per run.
--
--   lua5.1 ch07/theory.lua speed   T SEED [FIXES]
--   lua5.1 ch07/theory.lua density N SEED [FIXES] [STEPS]
--   lua5.1 ch07/theory.lua profile SIDES MACH SEED [FIXES] [STEPS] [FROM]
--   lua5.1 ch07/theory.lua flow SIDES MACH PCT RULE SEED LAYOUT [STEPS] [FROM]
--
-- FIXES is a comma-separated list of kerr.lua's o.fix switches (iso, walls,
-- garcia, rest) or "none".
--
-- THE MEASUREMENTS (Kerr's, from his drivers; then the book's):
--   speed (AverageSpeed/experiments/KTPhysics.java): 500 particles in the
--     L x L box (10 x 10 cells) at T kelvin, 2,000 steps; the mean speed
--     over the particles, averaged over all the steps.
--       mean   that average (m/s); theory sqrt(pi kT / 2m) (PDF 240)
--       err    (mean - theory) / theory, signed (the book's |.|/theory)
--       kerr   his error: |mean - theory| / the largest speed met (over
--              his 20 runs; over the one run here)
--       v2     <|v|^2> / (2 kT/m) over the same steps, theory 1
--       shape  <|v|> / sqrt(<|v|^2>), per step, averaged; Maxwell's
--              sqrt(pi)/2 = 0.8862 at any temperature
--   density (UniformDistribution/experiments/KTPhysics.java): N particles
--     in the box (20 x 20 cells), started in the square [L/2, 3L/4]^2;
--     STEPS (30,000) steps; the counts in a 5 x 5 grid summed over the last
--     199 steps (p > STEPS - 200) and divided by 200, kept as integers.
--       kerr   his error: the sum of the cells' excess over N/25, divided
--              by N - N/25 (one run; his file's runs also carried the
--              previous run's grid along, a bug left out here)
--       book   the book's: the mean over the 25 cells of |count - N/25| /
--              (N/25), on the same counts (not truncated)
--   profile (StandardCouette/experiments/NewPhysics.java): 500 particles
--     in the channel L wide (7 x 70 cells over L x 10 L), one-sided (the
--     wall at x = L moving at MACH, the other at rest; his runs) or
--     two-sided (both at MACH the same way, the book's Fig. 7.8 right; his
--     driver's two-sided runs moved them opposite ways); each step the mean
--     vy in 7 columns across the channel, averaged over the steps FROM ..
--     STEPS (his: 1 .. 2,000).
--       prof   the 7 column means, in Mach (m/s divided by the Mach speed)
--       kerr   his error: the mean over the columns of |theory - sim| /
--              max(|theory|, |theory - V|) (the largest error possible)
--       book   the book's: the mean of |theory - sim| / theory
--       theory one-sided V x/L at the column's centre; two-sided V
--   flow (ours; Figs. 7.7-7.8 with obstacles, whose code is not in the
--     archive): 500 particles in an L x L channel periodic along y (7 x 7
--     cells; fix.periodic, with iso, walls and garcia, so the gas itself is
--     Garcia's), started at rest, obstacles covering PCT of it laid out by
--     Kerr's 2005 generator from seed LAYOUT, faces by RULE ("rest",
--     "couette", "specular"; ch07/obstacles.lua) or "none"; walls as in
--     profile; the mean vy over the particles in each of 8 subcorridors (the
--     book's), averaged over steps FROM .. STEPS (3,001 .. 8,000).
--       prof   the 8 subcorridor means, in Mach
--       rel    their mean over the subcorridors / V (two-sided: Fig. 7.8
--              right's level; one-sided: the slope's, see slope)
--       slope  one-sided: least-squares slope across the subcorridors /
--              the theory's V/8 per subcorridor
--       book   the book's error, mean |theory - sim| / theory
--       back   share of particles moving backward (vy < 0), over the steps
--       cover  the obstacles' actual share of the area
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]ch07[/\\][^/\\]*$"))
package.path = (here or ".") .. "/?.lua;" .. package.path
local K = require "ch07.kerr"

local T = {}
local abs, sqrt = math.abs, math.sqrt

local function fixes(s)
  local f = {}
  if s and s ~= "none" and s ~= "" then
    for w in s:gmatch("[^,]+") do f[w] = true end
  end
  return f
end
T.fixes = fixes

function T.speed(Tk, seed, fix, steps)
  steps = steps or 2000
  local m = K.new({ variant = "speed", npart = 500, ncell_x = 10, ncell_y = 10, length = 1,
                    T = Tk, seed = seed, fix = fix })
  local sum, sum2, shape, vmax = 0, 0, 0, 0
  for _ = 1, steps do
    K.step(m)
    local s1, s2 = 0, 0
    for i = 0, m.n - 1 do
      local v2 = m.vx[i] * m.vx[i] + m.vy[i] * m.vy[i]
      s1, s2 = s1 + sqrt(v2), s2 + v2
      if v2 > vmax then vmax = v2 end
    end
    sum, sum2 = sum + s1 / m.n, sum2 + s2 / m.n
    shape = shape + (s1 / m.n) / sqrt(s2 / m.n)
  end
  local mean, th = sum / steps, K.meanSpeedTheory(Tk)
  return { mean = mean, theory = th, err = (mean - th) / th, kerr = abs(mean - th) / sqrt(vmax),
           v2 = (sum2 / steps) / (2 * K.boltz * Tk / K.mass), shape = shape / steps,
           collisions = m.colSum / (steps * m.n) }
end

function T.density(N, seed, fix, steps)
  steps = steps or 30000
  local m = K.new({ variant = "uniform", npart = N, ncell_x = 20, ncell_y = 20, length = 1,
                    T = 273, seed = seed, fix = fix })
  local g, grid = 5, {}
  for c = 0, g * g - 1 do grid[c] = 0 end
  for p = 0, steps - 1 do
    K.step(m)
    if p > steps - 200 then
      for i = 0, m.n - 1 do
        local jx, jy = K.int(m.x[i] * g / K.L), K.int(m.y[i] * g / K.L)
        if jx >= g then jx = g - 1 end
        if jy >= g then jy = g - 1 end
        grid[jy * g + jx] = grid[jy * g + jx] + 1
      end
    end
  end
  local th = N / (g * g)
  local kerr, book = 0, 0
  for c = 0, g * g - 1 do
    local n = grid[c] / 200.0
    local e = K.int(n) - K.int(th)
    if e > 0 then kerr = kerr + e end
    book = book + abs(n - th) / th
  end
  return { kerr = kerr / (N - K.int(th)), book = book / (g * g), grid = grid }
end

function T.profile(sides, mach, seed, fix, steps, from)
  steps, from = steps or 2000, from or 1
  local two = sides == "two"
  local m = K.new({ variant = "couette", npart = 500, ncell_x = 7, ncell_y = 70, length = 10,
                    T = 273, VLm = two and mach or 0, VRm = mach, dir0 = two and 1 or -1, dir1 = 1,
                    seed = seed, fix = fix })
  local nc, V, L = 7, m.VR, K.L
  local avg, used = {}, 0
  for k = 0, nc - 1 do avg[k] = 0 end
  for p = 1, steps do
    K.step(m)
    if p >= from then
      local s, c = {}, {}
      for k = 0, nc - 1 do s[k], c[k] = 0, 0 end
      for i = 0, m.n - 1 do
        local jx = K.int(m.x[i] * nc / L)
        if jx >= nc then jx = nc - 1 end
        s[jx], c[jx] = s[jx] + m.vy[i], c[jx] + 1
      end
      for k = 0, nc - 1 do if c[k] > 0 then avg[k] = avg[k] + s[k] / c[k] end end
      used = used + 1
    end
  end
  local prof, kerr, book = {}, 0, 0
  local mach1 = K.mach(273)
  for k = 0, nc - 1 do
    local sim = avg[k] / used
    local xc = (k + 0.5) * L / nc
    local th = two and V or (xc / L) * V
    local maxE = math.max(abs(th), abs(th - V))
    if two then maxE = V end
    kerr = kerr + abs(th - sim) / maxE
    book = book + abs(th - sim) / th
    prof[k + 1] = sim / mach1
  end
  return { prof = prof, kerr = kerr / nc, book = book / nc,
           collisions = m.colSum / (steps * m.n), V = V / mach1 }
end

function T.flow(sides, mach, pct, rule, seed, layout, steps, from)
  steps, from = steps or 8000, from or 3001
  local two = sides == "two"
  local m = K.new({ variant = "couette", npart = 500, ncell_x = 7, ncell_y = 7, length = 1,
                    T = 273, VLm = two and mach or 0, VRm = mach, dir0 = two and 1 or -1, dir1 = 1,
                    seed = seed, fix = { iso = true, walls = true, garcia = true, rest = true, periodic = true } })
  local cover = 0
  if rule ~= "none" and pct > 0 then
    local O = require "ch07.obstacles"
    cover = O.attach(m, { pct = pct, seed = layout, rule = rule }).cover
  end
  local nc, V, L = 8, m.VR, K.L
  local avg, used, back, seen = {}, 0, 0, 0
  for k = 0, nc - 1 do avg[k] = 0 end
  for p = 1, steps do
    K.step(m)
    if p >= from then
      local s, c = {}, {}
      for k = 0, nc - 1 do s[k], c[k] = 0, 0 end
      for i = 0, m.n - 1 do
        local jx = K.int(m.x[i] * nc / L)
        if jx >= nc then jx = nc - 1 end
        s[jx], c[jx] = s[jx] + m.vy[i], c[jx] + 1
        if m.vy[i] < 0 then back = back + 1 end
      end
      seen = seen + m.n
      for k = 0, nc - 1 do if c[k] > 0 then avg[k] = avg[k] + s[k] / c[k] end end
      used = used + 1
    end
  end
  local mach1 = K.mach(273)
  local prof, book, mean, sx, sy, sxx, sxy = {}, 0, 0, 0, 0, 0, 0
  for k = 0, nc - 1 do
    local sim = avg[k] / used
    local th = two and V or (k + 0.5) / nc * V
    book = book + abs(th - sim) / th
    prof[k + 1] = sim / mach1
    mean = mean + sim / nc
    sx, sy, sxx, sxy = sx + k, sy + sim, sxx + k * k, sxy + k * sim
  end
  local slope = (nc * sxy - sx * sy) / (nc * sxx - sx * sx)
  return { prof = prof, rel = mean / V, slope = slope / (V / nc), book = book / nc,
           back = back / seen, cover = cover, collisions = m.colSum / (steps * m.n) }
end

if arg and arg[0] and arg[0]:match("theory%.lua$") then
  local exp = arg[1]
  if exp == "speed" then
    local Tk, seed, f = tonumber(arg[2]), tonumber(arg[3]), arg[4] or "none"
    local r = T.speed(Tk, seed, fixes(f))
    print(string.format("speed T %d seed %d fix %s mean %.3f theory %.3f err %+.4f kerr %.4f v2 %.4f shape %.4f coll %.4f",
      Tk, seed, f, r.mean, r.theory, r.err, r.kerr, r.v2, r.shape, r.collisions))
  elseif exp == "density" then
    local N, seed, f, steps = tonumber(arg[2]), tonumber(arg[3]), arg[4] or "none", tonumber(arg[5] or 30000)
    local r = T.density(N, seed, fixes(f), steps)
    print(string.format("density N %d seed %d fix %s steps %d kerr %.4f book %.4f", N, seed, f, steps, r.kerr, r.book))
  elseif exp == "profile" then
    local sides, mach, seed, f = arg[2], tonumber(arg[3]), tonumber(arg[4]), arg[5] or "none"
    local steps, from = tonumber(arg[6] or 2000), tonumber(arg[7] or 1)
    local r = T.profile(sides, mach, seed, fixes(f), steps, from)
    local p = {}
    for k = 1, 7 do p[k] = string.format("%.3f", r.prof[k]) end
    print(string.format("profile %s M %.3f seed %d fix %s steps %d from %d kerr %.4f book %.4f coll %.4f prof %s",
      sides, mach, seed, f, steps, from, r.kerr, r.book, r.collisions, table.concat(p, " ")))
  elseif exp == "flow" then
    local sides, mach, pct, rule, seed, layout = arg[2], tonumber(arg[3]), tonumber(arg[4]), arg[5], tonumber(arg[6]), tonumber(arg[7])
    local steps, from = tonumber(arg[8] or 8000), tonumber(arg[9] or 3001)
    local r = T.flow(sides, mach, pct, rule, seed, layout, steps, from)
    local p = {}
    for k = 1, 8 do p[k] = string.format("%.3f", r.prof[k]) end
    print(string.format("flow %s M %.3f pct %.2f rule %s seed %d layout %d steps %d from %d cover %.3f rel %.4f slope %.4f book %.4f back %.4f coll %.4f prof %s",
      sides, mach, pct, rule, seed, layout, steps, from, r.cover, r.rel, r.slope, r.book, r.back, r.collisions, table.concat(p, " ")))
  else
    error("usage: theory.lua speed T SEED [FIXES] | density N SEED [FIXES] [STEPS] | profile one|two MACH SEED [FIXES] [STEPS] [FROM]")
  end
end

return T
