# Shared code

Modules every Artificial Physics port uses (`BOOK.md` §2). Load them with
`require "lib.<name>"` from a script in this folder or below it; BPP puts the
script's folder on the Lua path. They also run in plain `lua5.1`.

| Module | Groundwork | What |
| --- | --- | --- |
| `rng.lua` | G2 | The shared multiply-with-carry generator, seedable, with independent streams |
| `batch.py`, `batch.lua` | G3 | Headless runs over seeds × settings, two at a time, into one CSV |
| `status.lua` | — | The one-line status at the bottom of the BPP window: `label=value` fields of fixed width |
| `world.lua` | G21 | The world generator's core: pieces, cells, masks, BPP geometry, the book's worlds as presets |
| `terrain.lua` | G21 | The realistic worlds' ground and water: a heightfield with sea, rivers and ponds, depths, dredged channels and quays |
| `town.lua` | G21 | The realistic worlds' zones (Local Climate Zones) and streets (arterials, grids, collectors, cul-de-sacs) |
| `buildings.lua` | G21 | The realistic worlds' lots and buildings: frontage lots, rect/L/T/U footprints, whole floors, the gap rule, calibrated to the LCZ ranges |
| `places.lua` | G21 | The five realistic presets (rural, suburban, city centre, industrial port, harbour town) as parameter tables |
| `monitors.lua` | G1 | Centre-of-mass drift, linear and angular momentum, energy; the book's integrator with a chosen Δt |
| `lattice.lua` | G16 | Lattice quality: Delaunay triangulation, Ch. 16.9's edge-length CV, nearest-neighbour and bond CV (2D and 3D) |
| `ch13.lua` | — | Ch. 13's motion-control mechanisms, one function each: AR damping η and the stop rule so far |

## `rng.lua`

```lua
local rng = require "lib.rng"
rng.init(v)          -- once at load: SEED env, else the "seed" parameter, else the clock
rng.reseed()         -- first line of setup(): a fixed seed repeats the same start
if rng.isSeedChange(name) then setup(n) end  -- in onParamChanged: the slider restarts
rng.random()         -- [0, 1);  rng.random(n) -> 1..n;  rng.random(m, n) -> m..n
rng.gauss()          -- standard normal
local s = rng.new(7) -- an independent stream: s:random(), s:gauss(), s:seed(k)
```

- **Why:** BPP's Lua 5.1 `math.random` is glibc `rand()`, biased in the way the
  book's appendix describes. `checks/rng_appendix.lua` shows it and checks that
  this generator is not (`FIXES.md` item 34).
- **The seed slider** runs 0–1000 (a wider float range overflows BPP's
  integer slider); larger seeds go through `SEED`.
- **Seed 0 means the clock** (the old behaviour). The seed used is printed as
  `rng: MWC seed=…`, so any run can be repeated with `SEED=…`.
- **Same stream as before:** the generator and its seeding are unchanged from
  `Uniform_Coverage.lua`, so a seed gives the stream it gave there.
- The generator is exact in Lua 5.1 doubles (no bit operations), so a seed
  gives the same numbers on every platform.

## `batch.py` and `batch.lua`

Run from this folder's parent (`ArtificialPhysics/`):

```
python3 lib/batch.py Uniform_Coverage.lua --seeds 1-4 --set meanFreePath=10,17,30 \
    --frames 3000 --match ticks= --out uc.csv --summary deviation

python3 lib/batch.py Formations-Newtonian-Quadcopter.lua --probe probes/batch_drones.lua \
    --seeds 1-3 --set friction=0.3,0.5 --frames 5400 --out drones.csv --summary nn50
```

- **One run per setting combination × seed**, `--jobs` (default 2) at a time.
  Each run gets `SEED`, so it repeats exactly; the CSV is the same whatever
  `--jobs` is (`checks/batch_repeat.sh`).
- **Settings** (`--set name=a,b,c`, repeatable) are applied after the script
  loads, as if the slider were moved. `--resetup` re-runs `setup()` afterwards,
  for settings that only matter at the start. An unknown name is warned about
  in the run's log.
- **`delayMs` is set to 0** in every run (`FIXES.md` item 1).
- **Rows** come from a probe's `batch.row{...}` (printed as `ROW k=v …`), or
  with `--match PREFIX` from the script's own `key=value` lines, so existing
  demos need no change. A probe measures with `batch.every(frames, fn)` and
  `batch.atEnd(fn)` (BPP's `preDraw` and `preStop`, which demos here leave
  free).
- **CSV:** `job, seed`, the settings, `status` (ok / failed / timeout / norows),
  `wall_s`, then the row fields. A run that fails still gets a row. Each
  run's full output is in `<out>.logs/`; `--summary KEY` prints mean, sd,
  min and max of KEY over seeds from each run's last row.
- **BPP binary:** `$BPP`, else the newer of `debug/bpp` and `release/bpp`.
- **Speed:** a 3000-tick Uniform Coverage run takes about 3 s; 1800 frames
  of 50 drones about 11 s.

## `monitors.lua`

```lua
local mon = require "lib.monitors"
local ps = { { x = -30, m = 1 }, { x = 30, m = 1 } }      -- x, y, z, vx, vy, vz, m
local law = {
  pair      = function(r, a, b) return -10 * (r - 50) end, -- > 0 repels (swarm.lua's convention)
  potential = function(r, a, b) return 5 * (r - 50)^2 end, -- optional, for the energy monitor
  friction = 0, forceMax = nil, speedMax = nil,            -- optional
}
local t = mon.tracker(ps, law)
for _ = 1, 20000 do mon.step(ps, 0.001, law) end
print(mon.format(t:drift()))   -- com= dp= dl= de= relE=
```

- **The step is the book's** (Listings 2.1–2.6): friction `v ← (1 − FR)v`
  first, then every force from the same snapshot, then semi-implicit Euler.
  Δt is whatever you pass, unlike Bullet's fixed substeps.
- **Pairs are applied equally and oppositely** by default, so momentum is
  conserved to rounding. `asymmetric = true` evaluates the force on each
  particle separately, for laws that break Newton's third law (Ch. 4.1's
  triangle); the momentum monitor then shows the drift.
- **`bonds`** limits the pairs to a list `{ {i, j, ...}, ... }` (springs in a
  structure); each bond table is passed to `pair` and `potential` as a
  fourth argument, e.g. its own rest length (`ch02/models.lua`'s lattice).
- **`forceMax`** caps |F| per pair (Ch. 2.3's Force_Maximum); **`speedMax`**
  caps each speed (Velocity_Maximum), keeping the direction, or clips each
  component with **`speedCapPerAxis`**; **`external(p)`** adds a force.
- **`measure`** gives the centre of mass and its velocity, P, L about the
  centre of mass (a vector: a run in the x–z plane has only `ly`), KE, PE, E;
  **`tracker`** reports drift from the first measurement.
- `mon.frictionRate(FR, dt)` is the continuous damping rate the per-step
  friction amounts to, −ln(1 − FR)/Δt. It depends on Δt (`book/ch02.md`).
- `checks/monitors.lua` tests it against closed forms: two-body spring
  periods, the Kepler period and conserved quantities, friction decay, an
  external force, third-law violation and the caps.

## `world.lua`

```lua
local World = require "lib.world"
local w = World.preset("ch07-corridor", { percent = 30, seed = 4 })
w:blocked(x, y)            -- in an obstacle or wall, or outside the bounds?
w:cellOf(x, y)             -- cell index for the metrics, or nil
w:occupancy()              -- per-cell obstacle fraction
w:shadowCells()            -- Ch. 7's cells just downstream of obstacles
local objs = w:toBPP(v, { scale = 0.02, cellFloor = true })
w:writeGrid("corridor.txt")
```

- **A world** is 2D footprints with heights in the book's units: discs,
  turned rectangles, triangles, walls, named regions and a cell tiling.
  `World.new{}` plus `disc`, `rect`, `tri`, `wall`, `boxWalls`, `region`,
  `cells`, `scatter` builds your own.
- **Presets** (`World.presets()`):
  - `ch03-obstacles`: Fig. 3.25's 12 discs of radius 10, measured from the
    figure, in `formation_goal_obs.nlogo`'s 701 × 401 world with its goal
    (−175.25, 0) and start cloud (175.25, 0);
  - `ch03-wall`: Fig. 3.26's own field, 6 discs of radius 45 (measured; the
    text says 50) merged into a wall;
  - `ch04-coverage`: the coverage box, nine cells on ±40 (`netlogo = true`
    moves the walls to NetLogo's ±42);
  - `ch07-corridor`: 1000″ × 5000″, random rectangles, triangles and circles
    covering `percent`, 50 × 250 cells of 20″, start and goal strips.
- **Seeded:** random worlds use their own stream, so the same seed gives the
  same world and building one never shifts the agents' random numbers.
- **BPP:** book (x, y) becomes BPP (x, −z) with y up, so a camera looking
  down −z sees the book's orientation (`World.bppZ`). Objects are static
  with no contact response. `Worlds.lua` shows the presets.
- Each preset lists in `w.notes` the choices made where the book is silent.
- **`writeCPT(path, nx, ny)`** writes Zarzhitsky's map format (nx lines of
  ny characters, `' '` open, `'b'` blocked), any size, so his PlumeGen and
  TraceGen can run on our worlds as a check. His reader as shipped wants a
  square of at most 1024 (one `#define` and one check in `PlumeGen.c`), and
  his `Scenario.h` expects 128; change those in a copy for other sizes. Checked against his real reader: PlumeGen
  (built from `PlumeGen.c` + `MapUtils.c` with glib) loads it and reports the
  same coverage. His map makers are not used. `writeGrid` writes a
  human-readable `#`/`.` grid.
- **The realistic presets** (`rural`, `suburban`, `city-centre`,
  `industrial-port`, `harbour-town`) come through the same
  `World.preset(name, { seed = n })`; `lib/places.lua` holds their
  parameters. A world with a terrain also answers `w:groundAt(x, y)`,
  `w:waterAt(x, y)` (level, depth, kind), `w:zoneAt(x, y)` (its Local
  Climate Zone) and `w:blockedAt(x, y, z)`
  (below the ground or inside a piece at height z; pieces stand on their
  own `base`); `writeCPT(path, nx, ny, { z = h })` writes the world cut at
  height h. `toBPP` draws the terrain's ground (coloured by zone) and water
  instead of the floor, and the streets (`contact = true` lets bodies land
  on the ground and the streets).
- **The realistic layers** so far: terrain and water (`terrain.lua`), zones
  and streets (`town.lua`), lots and buildings (`buildings.lua`; as World
  pieces tagged `building`, standing on their own `base`, so `blocked`,
  `blockedAt` and `writeCPT` see them, drawn as one mesh). Vegetation and
  the mission features come next (`BOOK.md` §6).
- `checks/world.lua`: 22 tests, about 7 s.

## `terrain.lua`

```lua
local Terrain = require "lib.terrain"
local t = Terrain.generate(spec)   -- spec: a table from lib/places.lua
t:ground(x, y)                     -- elevation, m above sea level (seabed < 0)
t:water(x, y)                      -- level, depth, kind ("sea"|"river"|"pond") or nil
t:slope(x, y)                      -- rise over run of the triangle there
t:stats()                          -- land, sea, river, pond shares; deepest; steepest
t:toBPP(v, { contact = true })     -- one ground mesh, one translucent water mesh
```

- **Metres, x east, y north, elevation above sea level**, the sea (when
  there is one) to the south. In BPP (x, y, z) becomes (x, z, −y), as for
  every world.
- **Eight layers in a fixed order:** land (a coastal plain rising inland,
  hills 0 to `relief` above it from fractal value noise, fading out toward
  the shore); fill (reclaimed platforms); rivers; ponds; dredging with 1:3
  sides; the slope rule; quay walls (vertical, after the slope rule); the
  sea (everything below 0 connected to the open boundary).
- **One rule makes the land drivable:** no dry slope along the grid steeper
  than `MAX_SLOPE` = 15% (a triangle across the grid up to √2 × that,
  21.2%). It lowers, never raises, and it also shapes the river valleys'
  walls, the ponds' banks and the dry part of a dredged cut, so none of
  them needs its own setting.
- **Rivers** are sine-generated curves (Langbein and Leopold 1966): angle to
  the valley 1.1 sin φ, sinuosity 1/J0(1.1) = 1.39, meander wavelength 11
  widths (Leopold and Wolman 1960), each bend ±30% in length; channels 12
  times wider than deep, on a floodplain 0.5 m above the water, two widths
  each side. The water level only falls downstream and reaches 0 at the sea.
- **Ponds** sit 0.3 m below the lowest ground on a ring of 1.3 radii, so
  their rim holds them.
- **`ground(x, y)` is the drawn and collided surface:** linear on the mesh's
  triangles, split the same way everywhere.
- **Seeded** from its own stream; the same seed gives the same terrain on Lua
  5.1–5.4, and building one leaves the shared stream alone.
- All constants are fixed and stated at the top of the file, with their
  sources.
- `checks/terrain.lua`: 20 tests, about 7 s.

## `town.lua`

```lua
local w = World.preset("harbour-town", { seed = 1 })
w:zoneAt(x, y)                 -- "1".."10" built, "A".."G" land cover
w.town:intensity(x, y)         -- 0..1, Clark's exponential from the centres
w.town.streets                 -- { pts = { x1, y1, ... }, width, kind, bulb } each
w.town:streetDistance(x, y)    -- to the nearest street's edge (< 0 on it), and the street
w.town:stats()                 -- zone shares, km of street by kind
```

- **Zones** are Local Climate Zones (Stewart and Oke 2012; `Town.LCZ` holds
  each one's published building fraction and mean height). Density falls
  exponentially from each centre (Clark 1951): u = peak exp(−d/r). A
  preset's *ladder* maps bands of u to zones, each with a street style;
  *districts* (a port terminal, a park, an industrial estate) override it
  inside their shapes; water is G; woods (A) take a stated share of the
  open land (D), where a noise field is highest.
- **Streets** come in one hierarchy: arterials wander through everything
  and bridge rivers; grids fill the zones whose style is `grid`, at a
  city's spacing and widths (Manhattan: streets 18.3 m every 80 m, avenues
  30.5 m every 274 m; Chicago: 20.1 m, 100 × 200 m); curving collectors
  (a warped grid, 400 m) fill the zones whose style is `collectors`, with
  local streets between them, parallel and 80 m apart (two 32 m lots back
  to back and a 15 m street); half of the locals are cut midway between
  collectors into two cul-de-sacs, so each block has through streets and
  dead ends. Kinds: `arterial`, `grid`, `collector`, `local`, `culdesac`,
  `bridge`.
- **Fixed rules, stated in the file:** bridges up to 150 m (arterials, a
  grid's long family and one in four of its short family; collectors up to
  60 m, locals never); a local is split where it crosses the collectors:
  through streets between crossings, cul-de-sacs (up to the fire code's
  229 m, a 15 m turning circle, the 96 ft turnaround) from a crossing to a
  cut, dead ends to a zone's edge; pieces with no crossing and pieces under
  30 m are dropped.
- **One rule keeps the network whole:** every street must connect to an
  arterial (or to the largest network, without one); the rest are dropped.
  `checks/town.lua` confirms it independently, with a raster flood.
- **Width** is the right of way, building line to building line; streets
  are drawn as one mesh 0.3 m over the ground, bridges as flat decks at
  least 2 m over the water.
- Seeded from its own stream (`seed + 1000`); identical on Lua 5.1–5.4.
- `checks/town.lua`: 16 tests, about 8 s.

## `buildings.lua`

```lua
local w = World.preset("city-centre", { seed = 1 })
w.lots                         -- rectangles along the streets: x, y, ux, uy, hu, hv, zone
w.buildings                    -- { parts, zone, floors, height, base, top } each
w:blockedAt(x, y, z)           -- buildings are World pieces tagged "building"
require("lib.buildings").stats(w)   -- per zone: building fraction, share under lots, mean height
```

- **Lots** are laid frontage first: along each side of each street (grids,
  arterials, collectors, locals, cul-de-sacs, in that order), one after
  another at the zone's frontage, as deep as the zone's lot depth or as
  deep as fits (bisection); each cul-de-sac gets a lot at its head. A lot
  must lie in its zone, be dry, keep clear of every right of way and
  turning circle (exactly; its own curved street may cut its front corners
  by up to 1 m, the sagitta) and of earlier lots.
- **Buildings,** one per lot inside the setbacks: rectangles, L, T or U;
  whole floors of 3.5 m from a lognormal (heavy-tailed) clamped to the
  zone's range; sheds (large low-rise, industry) and tanks have heights.
  Farmsteads (a house, a barn, a shed) every 400–900 m along rural roads.
- **The gap rule** (the Android app's): two buildings touch (closed, as
  party walls are) or stand at least 3 m apart (two 1.5 m side setbacks);
  a building that breaks it is made shallower, then narrower, then left
  out. Compact zones' rear setback is 1.5 m, so back-to-back lots leave
  exactly 3 m.
- **Calibrated:** each built zone's footprint and lot numbers are set so
  that its measured building fraction and mean height fall in Stewart and
  Oke's published ranges, in every preset where the zone covers ≥ 3% of
  the area, on seeds 1–3 (`B.TYPES`; `FINDINGS.md` F62).
- Drawn as one mesh: walls from the lowest ground under the building
  (so no gap shows on a slope), flat roofs, a small tint per building.
- `checks/buildings.lua`: 13 tests, about 30 s.

## `places.lua`

The realistic presets as parameter tables, one per place; the layers hold
the rules, this file the numbers and where they come from.

| Preset | Area | Ground and water | Zones and streets |
| --- | --- | --- | --- |
| `rural` | 3 × 3 km, 10 m cells | Rolling farmland (hills to 18 m, ~1.2 km apart), a 20 m river, two ponds | Fields, a quarter of them wooded; two winding 10 m roads crossing at a hamlet (sparsely built), farmsteads along them |
| `suburban` | 2 × 2 km, 8 m cells | Gentle relief (10 m), a 12 m creek, a pond for a park | Open low-rise to ~760 m from the centre, sparsely built beyond; collectors 400 m apart, locals 80 m apart, half cut into cul-de-sacs; two arterials; a shopping centre (large low-rise) at the crossroads; a park round the pond; ~2,300 houses |
| `city-centre` | 1.6 × 1.6 km, 8 m cells | Nearly flat (3 m), a 60 m river | A Manhattan grid turned 29° to the edges: compact high-rise just north of the river, compact mid-rise, then open mid-rise; a park of 2 × 4 blocks; bridges on the avenues; one diagonal avenue; ~1,100 buildings, the tallest ~170 m |
| `industrial-port` | 2 × 2 km, 8 m cells | Coastal plain; a quay platform at +4 m with a 1.5 km quay face and two basins 180 × 700 m (vertical walls, 16 m); a 24 m approach into a turning basin 500 m across | The platform a terminal (large low-rise) on a 150 × 300 m road grid; heavy industry behind on a 200 × 250 m grid; two arterials along their shared edge and inland |
| `harbour-town` | 3 × 2.5 km, 10 m cells | Hills behind a bay; a 25 m river into the bay's head; a 400 m quay at +4 m with a 16 m berth; a 24 m approach, a 16 m main channel, a turning basin 400 m across; a pond | An old town on a Chicago grid by the bay (compact mid- then low-rise), suburbs on the hills (collectors, cul-de-sacs), the quay large low-rise, an industrial estate east of it, a park round the pond, woods on 30% of the open land, a coast road and two roads inland |

Depths follow Los Angeles (main channel 53 ft, 16.2 m) and Long Beach
(approach 76 ft, 23.2 m); grids follow Manhattan's 1811 plan and Chicago;
layouts, sizes, centres and the ladders' bands are ours, and each preset's
`notes` say so. `opts.seed` picks the layout, `opts.cell` and
`opts.maxSlope` override the grid and the slope rule, and `opts.layers`
stops early (1 the terrain only, 2 with zones and streets, 3, the default,
with buildings) for a port that needs only the ground or the streets.

## `status.lua`

Every simulation shows its most important information on BPP's status line,
one line where only the numbers change (design decision, 2026-10-17).

```lua
local status = require "lib.status"
status.show({ "Uniform Coverage",
              status.int("ticks", ticks, 10),                -- label=value, padded after
              status.num("deviation", dev, 6, false, 9),     -- places, signed, width
              status.num("speed", v, 2, false, 5, "m/s"),    -- unit stays with the number
              status.pct("cornerSpread", spread, 1, 6),
              status.text("goal", "off", 7) })
```

Values sit directly after their labels with padding after them, so each
number reads with its own label; fields have fixed widths and are separated
by ` | `, so nothing shifts (BPP shows the line in a fixed-pitch font). Put
parts that appear and disappear at the end.

## `lattice.lua`

```lua
local L = require "lib.lattice"
local pts = { { x = 0, y = 0 }, { x = 3, y = 0 }, ... }   -- add z for 3D
local tris, edges = L.delaunay2D(pts)  -- {i, j, k} triangles, {i, j} edges
local cv, mean, n = L.delaunayCV(pts)  -- Ch. 16.9: edges inside 80% of the max radius
local nncv = L.nnCV(pts)               -- nearest-neighbour distance CV, 2D or 3D
local bcv, bond = L.bondCV(pts, sep)   -- pairs closer than 1.2 sep: CV, mean / sep
```

- **Ch. 16.9's lattice quality** (PDF 556): the Delaunay triangulation of the
  settled agents, the nodes within 80% of the swarm's maximum radius from its
  centroid, and the coefficient of variation (sd / mean) of the edge lengths
  among them. 0 for a perfect triangular lattice.
- **Compare like with like:** a perfect square lattice is degenerate (four
  points on a circle), so a diagonal per cell gives it a CV of 0.171. For 3D
  lattices use `nnCV` or `bondCV`.
- Bowyer–Watson with a super-triangle 10⁴ × the points' span; a smaller one
  (40 ×) lost a hull triangle in 32 of 200 random sets.
- `checks/lattice.lua`: Euler's counts on 200 random sets, empty
  circumcircles, perfect and jittered lattices, square and cubic lattices,
  degenerate inputs (10 tests, < 1 s).

## `ch13.lua`

```lua
local C13 = require "lib.ch13"
f = C13.damp(f, r, D, pd, w)           -- Eq. 13.9-13.10: f x (|D - r|/(w D))^pd within w D of D (w = 1: the book's)
if C13.stopped(fx, fy, fz, thr) then   -- the stop rule: |F| < thr
  vx, vy, vz = 0, 0, 0
end
mu = C13.adaptMu(mu, uNew, uOld, kMore, kLess)   -- Eq. 13.23
if not C13.staticMoves(mu, m, g, f) then u = 0 end  -- Eq. 13.25 (corrected)
uMax = C13.adaptCap(uMax, near, 0.5, 0.1, 1.0, kMore, kLess)  -- Eq. 13.24
```

- **One function per Ch. 13 mechanism**, so every vehicle uses the same code.
  Each is off at 0 (`pd = 0`, `thr = 0`, `kMore = kLess = 0`), leaving the
  behaviour bit for bit as it was. `adaptMu` is Eq. 13.23, `staticMoves` Eq. 13.25
  (corrected), `adaptCap` Eq. 13.24.
- **Where each is needed** is in the module's header and
  `quadcopter/README.md`: on the drones only η (in a 0.2 D band) is needed;
  static friction and the adaptive cap are for the ground robots (M2) and
  sensor noise (G7), and are not wired into the drone harness.
- `quadcopter/swarm.lua` applies η to every drone–drone pair force with the
  spin-modified distance the law itself uses, and the stop rule to each
  drone's summed force (sliders `etaPower`, `etaWidth`; on by default in
  the Newtonian scene, band 0.2 D in 2D and 0.5 D in 3D). The other functions are not wired into the drones.
- `checks/ch13.lua` reproduces Figs. 13.3 and 13.8 and tests each mechanism (26 tests).
