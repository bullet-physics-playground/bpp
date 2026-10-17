# Shared code

Modules every Artificial Physics port uses (`BOOK.md` §2). Load them with
`require "lib.<name>"` from a script in this folder or below it; BPP puts the
script's folder on the Lua path. They also run in plain `lua5.1`.

| Module | Groundwork | What |
| --- | --- | --- |
| `rng.lua` | G2 | The shared multiply-with-carry generator, seedable, with independent streams |
| `batch.py`, `batch.lua` | G3 | Headless runs over seeds × settings, two at a time, into one CSV |

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
