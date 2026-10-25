--
-- checks/geo.lua -- BPP's compiled helpers for the world generator (the
-- global `geo`, src/geo.cpp) against the generator's own Lua: the same
-- worlds, bit for bit
--
-- DEFINITIONS:
--   Lua path   the generator's modules loaded with `geo` hidden, so every
--              function runs its own Lua (as under plain lua)
--   geo path   the modules loaded with `geo` there (as inside BPP)
--   print      every value of a world as text, numbers to 17 significant
--              digits (lib's layers: terrain nodes, the zone at every
--              node, streets, lots, buildings, trees, hedges, pads,
--              pieces); equal prints mean equal worlds
--   mesh hash  geo.meshHash: every corner of a drawn mesh, in order, as
--              the mesh holds it
--
-- For each of the five presets (seed 1) it builds the world both ways and
-- compares the prints and the hashes of every mesh World:toBPP draws, then
-- compares geo.fbm and geo.zone with the Lua at 20000 random points.
--
-- Needs BPP (about 60 s):  bpp -f checks/geo.lua -n 1
-- (run from the ArtificialPhysics folder; checks/run_all.sh skips it
-- without a BPP)
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-58s %s", ok and "ok  " or "FAIL", name, detail or ""))
end

print("geo: " .. _VERSION)
local geo = rawget(_G, "geo")
if not geo then
  print("FAIL no `geo` table: run this inside BPP (bpp -f checks/geo.lua -n 1)")
  return
end
local t0 = os.clock()

-- the generator's modules, loaded afresh with or without `geo`
local function load(withGeo)
  for k in pairs(package.loaded) do if k:match("^lib%.") then package.loaded[k] = nil end end
  _G.geo = withGeo and geo or nil
  local W = require "lib.world"           -- (and the layers it loads when used)
  for _, m in ipairs({ "places", "terrain", "town", "buildings", "features", "vegetation" }) do require("lib." .. m) end
  _G.geo = geo
  return W, package.loaded["lib.terrain"], package.loaded["lib.town"]
end

local function num(x) if x == 0 then x = 0 end return string.format("%.17g", x) end
local function dump(v, path, out, seen)
  local t = type(v)
  if t == "number" then out[#out + 1] = path .. "=" .. num(v)
  elseif t == "string" or t == "boolean" then out[#out + 1] = path .. "=" .. tostring(v)
  elseif t == "table" then
    if seen[v] then out[#out + 1] = path .. "=@" .. seen[v]; return end
    seen.n = seen.n + 1; seen[v] = seen.n
    local ks = {}
    for k, val in pairs(v) do
      local ok = type(val) ~= "function" and type(val) ~= "userdata"
      if type(k) == "string" and (k:sub(1, 1) == "_" or k:match("^buildTime")) then ok = false end
      if ok then ks[#ks + 1] = k end
    end
    table.sort(ks, function(a, b)
      if type(a) == type(b) then return a < b end
      return type(a) == "number"
    end)
    for _, k in ipairs(ks) do dump(v[k], path .. "." .. tostring(k), out, seen) end
  end
end
local function print_(w)
  local out, seen = {}, { n = 0 }
  local t = w.terrain
  for k = 1, t.stride * (t.ny + 1) do
    local x, y = t:nodeXY(k)
    out[#out + 1] = num(t.h[k]) .. " " .. (t.wl[k] and num(t.wl[k]) or "-") .. " " .. tostring(t.kind[k])
      .. " " .. tostring(w.town:zone(x, y))
  end
  for _, key in ipairs({ "streets", "centres", "districts" }) do dump(w.town[key], "town." .. key, out, seen) end
  for _, key in ipairs({ "lots", "buildings", "trees", "hedges", "pads", "pieces" }) do dump(w[key], key, out, seen) end
  return out
end
local viewer = { add = function() end }        -- (the meshes are hashed, not shown)
local function hashes(w)
  local h = {}
  for _, o in ipairs(w:toBPP(viewer, { scale = 1 })) do
    local ok, s, n = pcall(geo.meshHash, o)
    if ok then h[#h + 1] = s .. " " .. n end
  end
  return h
end
local function same(a, b)
  if #a ~= #b then return false, string.format("%d lines against %d", #a, #b) end
  for i = 1, #a do
    if a[i] ~= b[i] then return false, "first difference: " .. a[i] .. "  vs  " .. b[i] end
  end
  return true, #a .. " lines"
end

for _, name in ipairs({ "rural", "suburban", "city-centre", "industrial-port", "harbour-town" }) do
  local WL = load(false)
  local c0 = os.clock()
  local wl = WL.preset(name, { seed = 1 })
  local pl, hl = print_(wl), hashes(wl)
  local c1 = os.clock()
  local luaOnly = wl.town._geo == nil
  wl = nil
  local WG = load(true)
  local wg = WG.preset(name, { seed = 1 })
  local pg, hg = print_(wg), hashes(wg)
  local c2 = os.clock()
  check(name .. ": Lua path without geo, geo path with it", luaOnly and wg.town._geo ~= nil, "")
  local ok, d = same(pl, pg)
  check(name .. ": the same world, both ways", ok, d)
  ok, d = same(hl, hg)
  check(name .. ": the same meshes, both ways", ok and #hl > 0, d .. string.format("  (Lua %.1f s, geo %.1f s)", c1 - c0, c2 - c1))
  collectgarbage()
end

-- geo.fbm and geo.zone against the Lua at random points (on the harbour
-- town: districts, centres, ladder and woods), the area and 10% beyond it
-- for the noise; the same town for both
local W, Land, Town = load(true)
local w = W.preset("harbour-town", { seed = 1 })
local town, t = w.town, w.terrain
local rng = require "lib.rng"
local s = rng.new(7)
local nZ, badZ, nF, badF = 0, 0, 0, 0
local noise = town.woodsNoise
for _ = 1, 20000 do
  local x = t.x0 + (t.x1 - t.x0) * s:random()
  local y = t.y0 + (t.y1 - t.y0) * s:random()
  local g = town:entry(x, y, true)
  local gc, cc = town._geo, noise._c
  town._geo = nil
  local l = town:entry(x, y, true)
  town._geo = gc
  nZ = nZ + 1; if g ~= l then badZ = badZ + 1 end
  local fg = Land.fbm(noise, x - t.x0, y - t.y0)
  noise._c = nil
  local fl = Land.fbm(noise, x - t.x0, y - t.y0)
  noise._c = cc
  nF = nF + 1; if fg ~= fl then badF = badF + 1 end
end
check("harbour-town: geo.zone = Town:entry at random points", badZ == 0, badZ .. " of " .. nZ .. " differ")
check("harbour-town: geo.fbm = Land.fbm at random points", badF == 0, badF .. " of " .. nF .. " differ")

print(string.format("geo: %d checks, %d failed, %.0f s", count, fails, os.clock() - t0))
print(fails == 0 and "PASS geo" or "FAIL geo")
