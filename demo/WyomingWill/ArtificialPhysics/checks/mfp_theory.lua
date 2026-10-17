--
-- checks/mfp_theory.lua -- Listing 11.4's simulation against the exact
-- mean free path, in 2D and 3D, with and without the 5% buffer
-- (ch11/mfp_theory.lua, ch11/README.md). Passes if every simulated mean
-- is within 4 standard errors of the exact value for the same entry
-- point (x2 = 1.001, as in the book).
--
-- Run from the ArtificialPhysics folder (about 5 s):
--   lua5.1 checks/mfp_theory.lua            N=10000000 for the full run
--
local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local mfp = require "ch11.mfp_theory"

local n = tonumber(os.getenv("N") or "") or 1000000
local fails = 0
for i, c in ipairs({ { 2, false, "2D" }, { 2, true, "2D buffer" }, { 3, false, "3D" }, { 3, true, "3D buffer" } }) do
  local mean, se = mfp.run(c[1], c[2], n, i)
  local ex = mfp.exactAt1001[c[3]]
  local z = (mean - ex) / se
  local ok = math.abs(z) < 4
  if not ok then fails = fails + 1 end
  print(string.format("%s %-10s simulated %.5f +- %.5f, exact %.6f, z %.2f; f = %.6f",
                      ok and "ok  " or "FAIL", c[3], mean, se, ex, z, mfp.exact[c[3]]))
end
print((fails == 0 and "PASS" or "FAIL") .. string.format(" mfp_theory: %d samples per case", n))
if not rawget(_G, "v") then os.exit(fails == 0 and 0 or 1) end
