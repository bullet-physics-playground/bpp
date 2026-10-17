# Shared code

Modules every Artificial Physics port uses (`BOOK.md` §2). Load them with
`require "lib.<name>"` from a script in this folder or below it; BPP puts the
script's folder on the Lua path. They also run in plain `lua5.1`.

| Module | Groundwork | What |
| --- | --- | --- |
| `rng.lua` | G2 | The shared multiply-with-carry generator, seedable, with independent streams |

## `rng.lua`

```lua
local rng = require "lib.rng"
rng.init(v)          -- once at load: SEED env, else the "seed" parameter, else the clock
rng.reseed()         -- first line of setup(): a fixed seed repeats the same start
rng.random()         -- [0, 1);  rng.random(n) -> 1..n;  rng.random(m, n) -> m..n
rng.gauss()          -- standard normal
local s = rng.new(7) -- an independent stream: s:random(), s:gauss(), s:seed(k)
```

- **Why:** BPP's Lua 5.1 `math.random` is glibc `rand()`, biased in the way the
  book's appendix describes. `checks/rng_appendix.lua` shows it and checks that
  this generator is not (`FIXES.md` item 34).
- **Seed 0 means the clock** (the old behaviour). The seed used is printed as
  `rng: MWC seed=…`, so any run can be repeated with `SEED=…`.
- **Same stream as before:** the generator and its seeding are unchanged from
  `Uniform_Coverage.lua`, so a seed gives the stream it gave there.
- The generator is exact in Lua 5.1 doubles (no bit operations), so a seed
  gives the same numbers on every platform.
