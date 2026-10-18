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
- **The realistic layers** (terrain, water with depth, zones, streets, lots,
  buildings, vegetation) are planned in `BOOK.md` §6 and come next.
- `checks/world.lua`: 21 tests, about 10 s.

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
f = C13.damp(f, r, D, pd)              -- Eq. 13.9-13.10: f x (|D - r|/D)^pd for r < 2D
if C13.stopped(fx, fy, fz, thr) then   -- the stop rule: |F| < thr
  vx, vy, vz = 0, 0, 0
end
```

- **One function per Ch. 13 mechanism**, so every vehicle uses the same code.
  Each is off at 0 (`pd = 0`, `thr = 0`), leaving the force bit for bit as it
  was. Adaptive friction (Eq. 13.23), static friction (Eq. 13.25) and the
  adaptive speed cap (Eq. 13.24) come in the next steps of milestone M1.
- `quadcopter/swarm.lua` applies η to every drone–drone pair force with the
  spin-modified distance the law itself uses, and the stop rule to each
  drone's summed force (sliders `etaPower`, `stopForce`).
- `checks/ch13.lua` reproduces Fig. 13.3 and Fig. 13.8 (11 tests).
