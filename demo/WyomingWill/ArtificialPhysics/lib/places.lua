--
-- lib/places.lua -- the world generator's realistic presets (BOOK.md §6)
--
-- Five parameter tables for one generator, modelled on how real places are
-- built, in general rather than any particular place: rural, suburban, city
-- centre, industrial port, and the harbour town of the capstone. Each layer
-- of the generator reads its own part of the table; this file holds the
-- numbers and where they come from, the layers hold the rules.
--
--   local World = require "lib.world"
--   local w = World.preset("harbour-town", { seed = 3 })
--   w.terrain:ground(x, y)   -- metres above sea level
--
-- So far: terrain and water (lib/terrain.lua). Zones, streets, lots and
-- buildings, vegetation and the mission features come next, in that order.
--
-- UNITS: metres; x east, y north; elevation above sea level. The sea, when
-- there is one, is to the south.
--
-- WHERE THE NUMBERS COME FROM:
--   * dredged depths: Port of Los Angeles main channel 53 ft (16.2 m);
--     Long Beach approach channel 76 ft (23.2 m), 60 ft (18.3 m) at its
--     container wharf (WorldAtlas, "US harbors deep enough for the largest
--     ships"). Our approach 24 m, channels, basins and berths 16 m.
--   * turning basin: about 1.5 to 2 design-ship lengths across: 500 m in
--     the industrial port (300 m ships), 400 m in the harbour town.
--   * dredged side slopes 1:3; quay walls vertical; quay decks about 4 m
--     above sea level.
--   * rivers: width over depth 12, meander wavelength 11 widths, sinuosity
--     1.39 (lib/terrain.lua's constants and their sources).
--   * offshore shelf 1:80 to 1:100 near the shore.
-- The choices made where nothing real decides (sizes of the areas, where
-- the river runs, how high the hills are) are ours; each preset's notes
-- say so.
--

local P = {}

local presets = {}

-- Rural: rolling farmland, a river crossing it, two ponds. 3 x 3 km.
presets["rural"] = function(o)
  return {
    name = "rural", bounds = { 0, 0, 3000, 3000 }, cell = 10,
    land = { height = 40, rise = 0.004, relief = 18, wavelength = 1200, octaves = 3 },
    rivers = { { from = { 900, 3000 }, to = { 2100, 0 }, width = 20 } },
    ponds = { count = 2, radius = { 25, 45 }, depth = 2 },
    notes = { "3 x 3 km of rolling farmland (relief 18 m, hills ~1.2 km apart), rising 4 m per km to the north; a 20 m river and two ponds (our choices)" },
  }
end

-- Suburban: gentle relief, a creek, one larger pond for a park. 2 x 2 km.
presets["suburban"] = function(o)
  return {
    name = "suburban", bounds = { 0, 0, 2000, 2000 }, cell = 8,
    land = { height = 20, rise = 0.003, relief = 10, wavelength = 900, octaves = 3 },
    rivers = { { from = { 300, 2000 }, to = { 1500, 0 }, width = 12 } },
    ponds = { count = 1, radius = { 45, 60 }, depth = 2.5 },
    notes = { "2 x 2 km, gentle relief (10 m), a 12 m creek and one pond for a park (our choices)" },
  }
end

-- City centre: nearly flat, on a wide river. 1.6 x 1.6 km.
presets["city-centre"] = function(o)
  return {
    name = "city-centre", bounds = { 0, 0, 1600, 1600 }, cell = 8,
    land = { height = 8, rise = 0.002, relief = 3, wavelength = 1000, octaves = 2 },
    rivers = { { from = { 0, 950 }, to = { 1600, 650 }, width = 60 } },
    notes = { "1.6 x 1.6 km, nearly flat (relief 3 m), on a 60 m river running east (our choices)" },
  }
end

-- Industrial port: a coastal plain with a reclaimed quay platform, two
-- basins cut into it with vertical quay walls, and the harbour works.
-- 2 x 2 km.
presets["industrial-port"] = function(o)
  local dredge = {
    -- the approach from the south edge straight into the turning basin
    -- (the basin's 1:3 side ends at the quay face, so it does not bite into the deck)
    { name = "approach", shape = { kind = "strip", pts = { 1000, -50, 1000, 100 }, w = 220 }, depth = 24 },
    { name = "turning basin", shape = { kind = "disc", x = 1000, y = 230, r = 250 }, depth = 16 },
    -- the outer quay face and two basins, 180 m wide, cut north into the
    -- platform (quay walls)
    { name = "quay front", shape = { kind = "rect", x = 1000, y = 520, sx = 1500, sy = 60 }, depth = 16, run = 0 },
    { name = "basin west", shape = { kind = "rect", x = 700, y = 900, sx = 180, sy = 700 }, depth = 16, run = 0 },
    { name = "basin east", shape = { kind = "rect", x = 1300, y = 900, sx = 180, sy = 700 }, depth = 16, run = 0 },
  }
  return {
    name = "industrial-port", bounds = { 0, 0, 2000, 2000 }, cell = 8,
    coast = { y = 800, wobble = 20, wavelength = 700, shelf = 0.0125 },
    land = { height = 2, rise = 0.003, relief = 4, wavelength = 900, octaves = 2, flatNearCoast = 400 },
    fill = { { shape = { kind = "rect", x = 1000, y = 950, sx = 1500, sy = 800 }, height = 4, run = 2 } },
    dredge = dredge,
    notes = { "2 x 2 km; a quay platform 1.5 x 0.8 km at +4 m reclaimed out over the shore, a 1.5 km quay face and two basins 180 x 700 m with vertical walls, 16 m deep; a 24 m approach from the south edge into a turning basin 500 m across, 16 m deep (layout ours, depths from Los Angeles / Long Beach)" },
  }
end

-- Harbour town: hills behind a bay, a river into the bay's head, a quay
-- with a berth, the harbour works, a pond. 3 x 2.5 km.
presets["harbour-town"] = function(o)
  local dredge = {
    { name = "approach", shape = { kind = "strip", pts = { 1500, -50, 1500, 450 }, w = 220 }, depth = 24 },
    { name = "main channel", shape = { kind = "strip", pts = { 1500, 450, 1500, 750 }, w = 200 }, depth = 16 },
    { name = "turning basin", shape = { kind = "disc", x = 1500, y = 850, r = 200 }, depth = 16 },
    -- the berth beside a quay on the bay's east side, 400 m long, at +4 m
    { name = "berth", shape = { kind = "rect", x = 1730, y = 800, sx = 80, sy = 400 }, depth = 16, run = 0 },
  }
  return {
    name = "harbour-town", bounds = { 0, 0, 3000, 2500 }, cell = 10,
    coast = { y = 600, wobble = 30, wavelength = 800, shelf = 0.012,
              bay = { x = 1500, depth = 450, width = 350 } },
    land = { height = 2, rise = 0.012, relief = 25, wavelength = 1000, octaves = 3, flatNearCoast = 450 },
    fill = { { shape = { kind = "rect", x = 1850, y = 820, sx = 200, sy = 460 }, height = 4, run = 2 } },
    rivers = { { from = { 2500, 2500 }, to = { 1550, 900 }, width = 25 } },
    ponds = { count = 1, radius = { 30, 45 }, depth = 2 },
    dredge = dredge,
    notes = { "3 x 2.5 km: a bay 450 m deep into the coast, hills rising 12 m per km behind it (relief 25 m), a 25 m river into the bay's head, a 400 m quay at +4 m on the bay's east side with a 16 m berth; a 24 m approach to the bay's mouth, a 16 m main channel and a turning basin 400 m across in the bay (layout ours)" },
  }
end

-- The spec for a preset: its table, with opts.seed (default 1) and any
-- overrides in opts.
function P.spec(name, opts)
  opts = opts or {}
  local f = presets[name]
  if not f then return nil end
  local spec = f(opts)
  spec.seed = opts.seed or 1
  if opts.cell then spec.cell = opts.cell end
  if opts.maxSlope then spec.maxSlope = opts.maxSlope end
  return spec
end

function P.names()
  return { "rural", "suburban", "city-centre", "industrial-port", "harbour-town" }
end

-- A World holding the preset's terrain (lib/world.lua does the rest).
function P.build(World, name, opts)
  local Terrain = require "lib.terrain"
  local spec = P.spec(name, opts)
  local t = Terrain.generate(spec)
  local w = World.new({ name = name, units = "m", bounds = { t.x0, t.y0, t.x1, t.y1 },
                        height = 0, seed = spec.seed, terrain = t })
  for _, n in ipairs(spec.notes or {}) do w.notes[#w.notes + 1] = n end
  return w
end

return P
