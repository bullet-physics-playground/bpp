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
--   w:zoneAt(x, y)           -- Local Climate Zone
--   w.town.streets           -- { pts, width, kind } each
--   w.buildings              -- { parts, zone, floors, height, base, top } each
--   World.preset(name, { seed = 3, layers = 1 })   -- the terrain only (2: + streets)
--
-- So far: terrain and water (lib/terrain.lua), zones and streets
-- (lib/town.lua), lots and buildings (lib/buildings.lua). Vegetation and
-- the mission features come next.
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
--   * zones: Local Climate Zones (Stewart and Oke 2012); density falling
--     exponentially from a centre (Clark 1951). Each preset's ladder of
--     intensity bands is ours.
--   * grids: Manhattan (Commissioners' Plan of 1811): streets 60 ft
--     (18.3 m) about 264 ft (80 m) apart, avenues 100 ft (30.5 m) about
--     900 ft (274 m) apart. Chicago: 66 ft (20.1 m) streets, blocks 330 x
--     660 ft (100 x 200 m) centre to centre.
--   * suburban streets: local 50 ft (15 m) right of way, collectors 20 m,
--     arterials 30 m; rural two-lane roads 10 m; cul-de-sacs as lib/town.lua.
-- The choices made where nothing real decides (sizes of the areas, where
-- the river runs, how high the hills are, where the centres are) are ours;
-- each preset's notes say so.
--

local P = {}

local presets = {}

local MANHATTAN = { spacing = { 80, 274 }, widths = { 18.3, 30.5 } }
local CHICAGO = { spacing = { 100, 200 }, widths = { 20.1, 20.1 } }

-- A grid frame at (x, y), turned by angle, with a city's spacing and widths.
local function grid(x, y, angle, city)
  return { x = x, y = y, angle = angle, spacing = city.spacing, widths = city.widths }
end

-- The rectangle covering grid cells i0..i1 (along the angle, between
-- family-2 lines) by j0..j1 (across it, between family-1 lines), inside
-- the streets: for districts that take whole blocks (a park).
local function blocks(F, i0, i1, j0, j1)
  local c, s = math.cos(F.angle), math.sin(F.angle)
  local a, b = F.spacing[2], F.spacing[1]          -- along, across
  local ci, cj = (i0 + i1 + 1) / 2, (j0 + j1 + 1) / 2
  return { kind = "rect", x = F.x + ci * a * c - cj * b * s, y = F.y + ci * a * s + cj * b * c,
           sx = (i1 - i0 + 1) * a - F.widths[2], sy = (j1 - j0 + 1) * b - F.widths[1], a = F.angle }
end

-- Rural: rolling farmland, a river crossing it, two ponds; two winding
-- roads meeting at a hamlet; fields and woods. 3 x 3 km.
presets["rural"] = function(o)
  return {
    name = "rural", bounds = { 0, 0, 3000, 3000 }, cell = 10,
    land = { height = 40, rise = 0.004, relief = 18, wavelength = 1200, octaves = 3 },
    rivers = { { from = { 900, 3000 }, to = { 2100, 0 }, width = 20 } },
    ponds = { count = 2, radius = { 25, 45 }, depth = 2 },
    zones = {
      centres = { { x = 1500, y = 1550, r = 150 } },
      ladder = { { u = 0.3, lcz = "9" } },
      woods = 0.25,
    },
    streets = {
      arterials = {
        { pts = { 0, 1300, 3000, 1800 }, width = 10, wander = 80, wavelength = 700 },
        { pts = { 1700, 3000, 1300, 0 }, width = 10, wander = 80, wavelength = 700 },
      },
    },
    notes = { "3 x 3 km of rolling farmland (relief 18 m, hills ~1.2 km apart), rising 4 m per km to the north; a 20 m river and two ponds (our choices)",
              "two winding 10 m roads crossing at a hamlet (sparsely built within ~180 m); a quarter of the open land wooded (our choices)" },
  }
end

-- Suburban: gentle relief, a creek, one larger pond in a park; houses on
-- curving collectors and cul-de-sacs; a shopping centre at the crossroads.
-- 2 x 2 km.
presets["suburban"] = function(o)
  return {
    name = "suburban", bounds = { 0, 0, 2000, 2000 }, cell = 8,
    land = { height = 20, rise = 0.003, relief = 10, wavelength = 900, octaves = 3 },
    rivers = { { from = { 300, 2000 }, to = { 1500, 0 }, width = 12 } },
    ponds = { count = 1, radius = { 45, 60 }, depth = 2.5 },
    zones = {
      centres = { { x = 1000, y = 1000, r = 1100, peak = 0.6 } },
      ladder = { { u = 0.3, lcz = "6", streets = "collectors" },
                 { u = 0.17, lcz = "9", streets = "collectors" } },
      districts = function(t)
        local d = { { shape = { kind = "rect", x = 1110, y = 1110, sx = 180, sy = 140 }, lcz = "8" } }
        for _, p in ipairs(t.ponds) do
          d[#d + 1] = { shape = { kind = "disc", x = p.x, y = p.y, r = p.r + 60 }, lcz = "B" }
        end
        return d
      end,
      woods = 0.3,
    },
    streets = {
      arterials = {
        { pts = { 0, 1000, 2000, 1000 }, width = 30, wander = 40, wavelength = 800 },
        { pts = { 1000, 2000, 1000, 0 }, width = 30, wander = 40, wavelength = 800 },
      },
      collectors = { angle = 0.2, spacing = 400, warp = 60, wavelength = 500, width = 20 },
      ["local"] = 15,
    },
    notes = { "2 x 2 km, gentle relief (10 m), a 12 m creek and one pond for a park (our choices)",
              "open low-rise within ~760 m of the centre, sparsely built to ~1.4 km, a shopping centre at the crossroads, a park round the pond; collectors 400 m apart (our choices)" },
  }
end

-- City centre: nearly flat, on a wide river; a Manhattan grid turned 29
-- degrees to the edges, high-rise at the centre (just north of the river)
-- falling to mid-rise and open mid-rise, a park of 2 x 4 blocks. 1.6 x
-- 1.6 km.
presets["city-centre"] = function(o)
  local F = grid(800, 1000, 0.5, MANHATTAN)
  return {
    name = "city-centre", bounds = { 0, 0, 1600, 1600 }, cell = 8,
    land = { height = 8, rise = 0.002, relief = 3, wavelength = 1000, octaves = 2 },
    rivers = { { from = { 0, 950 }, to = { 1600, 650 }, width = 60 } },
    zones = {
      centres = { { x = 800, y = 1000, r = 450 } },
      ladder = { { u = 0.62, lcz = "1", streets = "grid" },
                 { u = 0.40, lcz = "2", streets = "grid" },
                 { u = 0, lcz = "5", streets = "grid" } },
      districts = { { shape = blocks(F, -1, 0, 2, 5), lcz = "B" } },
    },
    streets = {
      grid = F,
      arterials = { { pts = { 0, 300, 1600, 1400 }, width = 30.5, wander = 0 } },
    },
    notes = { "1.6 x 1.6 km, nearly flat (relief 3 m), on a 60 m river running east (our choices)",
              "a Manhattan grid (streets 18.3 m every 80 m, avenues 30.5 m every 274 m) turned 29 degrees as Manhattan's is; compact high-rise within ~215 m of the centre, compact mid-rise to ~410 m, open mid-rise to the edges; a park 2 x 4 blocks; one diagonal avenue (our choices)" },
  }
end

-- Industrial port: a coastal plain with a reclaimed quay platform, two
-- basins cut into it with vertical quay walls, the harbour works; the
-- platform is a terminal (large low-rise) with its own road grid, heavy
-- industry behind it. 2 x 2 km.
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
  local platform = { kind = "rect", x = 1000, y = 950, sx = 1500, sy = 800 }
  local features = {
    -- a 300 m container ship (beam 40 m, draft 13 m) along the west
    -- basin's east quay (x = 790), off it by a cell (8 m) and 1 m of
    -- fenders, its leak on the basin side
    ship = { x = 761, y = 900, length = 300, beam = 40, draft = 13, freeboard = 10, angle = math.pi / 2, seaward = 1 },
    yard = { zone = "8" },
    warehouses = { zone = "8", count = 3 },
    pads = { { 1550, 1150 } },
  }
  return {
    name = "industrial-port", bounds = { 0, 0, 2000, 2000 }, cell = 8,
    coast = { y = 800, wobble = 20, wavelength = 700, shelf = 0.0125 },
    land = { height = 2, rise = 0.003, relief = 4, wavelength = 900, octaves = 2, flatNearCoast = 400 },
    fill = { { shape = platform, height = 4, run = 2 } },
    dredge = dredge,
    features = features,
    zones = {
      districts = {
        { shape = { kind = "rect", x = 1000, y = 1660, sx = 2000, sy = 680 }, lcz = "10",
          grid = { x = 1000, y = 1660, angle = 0, spacing = { 200, 250 }, widths = { 20, 20 } } },
        { shape = { kind = "rect", x = 1000, y = 925, sx = 1500, sy = 790 }, lcz = "8",
          grid = { x = 1000, y = 950, angle = 0, spacing = { 150, 300 }, widths = { 25, 25 } } },
      },
    },
    streets = {
      -- the east-west arterial runs along the two districts' shared edge,
      -- so both grids' streets end on it
      arterials = { { pts = { 1000, 2000, 1000, 1320 }, width = 30, wander = 0 },
                    { pts = { 0, 1320, 2000, 1320 }, width = 30, wander = 0 } },
    },
    notes = { "2 x 2 km; a quay platform 1.5 x 0.8 km at +4 m reclaimed out over the shore, a 1.5 km quay face and two basins 180 x 700 m with vertical walls, 16 m deep; a 24 m approach from the south edge into a turning basin 500 m across, 16 m deep (layout ours, depths from Los Angeles / Long Beach)",
              "the platform a terminal (large low-rise) on a 150 x 300 m road grid, heavy industry behind it on a 200 x 250 m grid, two 30 m arterials (our choices)",
              "a 300 m container ship at the west basin's east quay (draft 13 m), a container yard, three warehouses with doorways, a launch pad (our choices)" },
  }
end

-- Harbour town: hills behind a bay, a river into the bay's head, a quay
-- with a berth, the harbour works, a pond; an old town on a Chicago grid
-- by the bay, suburbs on the hills, an industrial estate east of the quay.
-- 3 x 2.5 km.
presets["harbour-town"] = function(o)
  local dredge = {
    { name = "approach", shape = { kind = "strip", pts = { 1500, -50, 1500, 450 }, w = 220 }, depth = 24 },
    { name = "main channel", shape = { kind = "strip", pts = { 1500, 450, 1500, 750 }, w = 200 }, depth = 16 },
    { name = "turning basin", shape = { kind = "disc", x = 1500, y = 850, r = 200 }, depth = 16 },
    -- the berth beside a quay on the bay's east side, 400 m long, at +4 m
    { name = "berth", shape = { kind = "rect", x = 1730, y = 800, sx = 80, sy = 400 }, depth = 16, run = 0 },
  }
  local F = grid(1300, 1300, 0.12, CHICAGO)
  local features = {
    -- the capstone's ship: a 180 m tanker (beam 28 m, draft 10 m) in the
    -- berth along the quay's face (x = 1770), off it by a cell (10 m) and
    -- 1 m of fenders, its leak on the bay side
    ship = { x = 1745, y = 800, length = 180, beam = 28, draft = 10, freeboard = 8, angle = math.pi / 2, seaward = 1 },
    yard = { zone = "8" },
    warehouses = { zone = "8", count = 2 },
    -- two piers of a marina on the bay's west shore
    piers = function(t)
      local out = {}
      for _, x in ipairs({ 1180, 1240 }) do
        local y = t.coastY(x)
        out[#out + 1] = { from = { x, y + 2 }, to = { x, y - 140 }, width = 6 }
      end
      return out
    end,
    -- the storm drain: from the old town down to the bay's head
    drain = function(t) return { pts = { 1250, 1500, 1380, t.coastY(1380) - 60 } } end,
    -- launch pads: on the quay, and by the pond
    pads = function(t)
      local p = t.ponds[1]
      return { { 1880, 700 }, p and { p.x, p.y - p.r - 80 } or { 1000, 1800 } }
    end,
  }
  return {
    name = "harbour-town", bounds = { 0, 0, 3000, 2500 }, cell = 10,
    features = features,
    coast = { y = 600, wobble = 30, wavelength = 800, shelf = 0.012,
              bay = { x = 1500, depth = 450, width = 350 } },
    land = { height = 2, rise = 0.012, relief = 25, wavelength = 1000, octaves = 3, flatNearCoast = 450 },
    fill = { { shape = { kind = "rect", x = 1850, y = 820, sx = 200, sy = 460 }, height = 4, run = 2 } },
    rivers = { { from = { 2500, 2500 }, to = { 1550, 900 }, width = 25 } },
    ponds = { count = 1, radius = { 30, 45 }, depth = 2 },
    dredge = dredge,
    zones = {
      centres = { { x = 1300, y = 1300, r = 400 } },
      ladder = { { u = 0.55, lcz = "2", streets = "grid" },
                 { u = 0.30, lcz = "3", streets = "grid" },
                 { u = 0.12, lcz = "6", streets = "collectors" },
                 { u = 0.05, lcz = "9", streets = "collectors" } },
      districts = function(t)
        local d = {
          { shape = { kind = "rect", x = 1850, y = 820, sx = 200, sy = 460 }, lcz = "8" },
          { shape = { kind = "rect", x = 2300, y = 1050, sx = 400, sy = 300, a = 0.1 }, lcz = "10",
            grid = { x = 2300, y = 1050, angle = 0.1, spacing = { 150, 150 }, widths = { 20, 20 } } },
        }
        for _, p in ipairs(t.ponds) do
          d[#d + 1] = { shape = { kind = "disc", x = p.x, y = p.y, r = p.r + 50 }, lcz = "B" }
        end
        return d
      end,
      woods = 0.3,
    },
    streets = {
      grid = F,
      arterials = function(t)
        local coast = {}
        for x = 0, 3000, 150 do coast[#coast + 1] = x; coast[#coast + 1] = t.coastY(x) + 140 end
        return {
          { pts = coast, width = 20, wander = 0 },
          { pts = { 1300, 1300, 1200, 2500 }, width = 20, wander = 60, wavelength = 600 },
          { pts = { 1700, 1250, 3000, 1700 }, width = 20, wander = 60, wavelength = 600 },
        }
      end,
      collectors = { angle = -0.3, spacing = 400, warp = 60, wavelength = 500, width = 20 },
      ["local"] = 15,
    },
    notes = { "3 x 2.5 km: a bay 450 m deep into the coast, hills rising 12 m per km behind it (relief 25 m), a 25 m river into the bay's head, a 400 m quay at +4 m on the bay's east side with a 16 m berth; a 24 m approach to the bay's mouth, a 16 m main channel and a turning basin 400 m across in the bay (layout ours)",
              "an old town on a Chicago grid by the bay (compact mid-rise within ~240 m of its centre, compact low-rise to ~480 m), suburbs on the hills, the quay a large low-rise district, an industrial estate east of it, a park round the pond, a coast road 140 m inland (our choices)",
              "the capstone's features: a 180 m tanker at the berth with its leak on the bay side, a container yard and two warehouses with doorways on the quay, two piers of a marina, a storm drain from the old town to an outfall at the bay's head, launch pads on the quay and by the pond (our choices)" },
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

-- A World holding the preset's terrain, zones and streets, lots and
-- buildings, mission features and vegetation (lib/world.lua does the
-- rest). opts.layers stops early: 1 the terrain only, 2 with zones and
-- streets, 3 with lots, buildings and features, 4 (default) with trees.
function P.build(World, name, opts)
  opts = opts or {}
  local t0 = os.clock()
  local layers = opts.layers or 4
  local Terrain = require "lib.terrain"
  local Town = require "lib.town"
  local spec = P.spec(name, opts)
  local t = Terrain.generate(spec)
  local w = World.new({ name = name, units = "m", bounds = { t.x0, t.y0, t.x1, t.y1 },
                        height = 0, seed = spec.seed, terrain = t })
  if layers >= 2 then w.town = Town.build(t, spec) end
  if layers >= 3 then
    local B = require "lib.buildings"
    B.build(w, spec.seed)
    require("lib.features").build(w, spec)
    if layers >= 4 then require("lib.vegetation").build(w, spec) end
    B.addPieces(w)
    if layers >= 4 then require("lib.vegetation").addPieces(w) end
  end
  w.buildTime = os.clock() - t0                    -- seconds, every layer
  for _, n in ipairs(spec.notes or {}) do w.notes[#w.notes + 1] = n end
  return w
end

return P
