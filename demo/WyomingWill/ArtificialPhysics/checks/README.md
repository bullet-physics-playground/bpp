# Checks: the regression suite

`bash checks/run_all.sh` runs every check and exits 0 only if all pass
(about 1 min 40 s; `--quick` about 45 s with smaller samples).

**Which Lua.** The Lua checks run *inside BPP* when a BPP is built, so they
test the Lua the demos really use; BPP links Lua 5.1 or 5.2 depending on the
build, and the first line of the output names it. Without BPP (or with
`BPP=none`) they run in a standalone Lua: `$LUA`, else the first of `lua5.1`,
`lua5.2`, `lua5.3`, `lua5.4`, `lua`. Every check and `lib/` module runs on
Lua 5.1 to 5.4, and the shared generator gives the same numbers on all of
them. Run it before
sending any patch that touches shared code (`WORKFLOW.md` §3). Each check
prints `ok`/`FAIL` lines and ends with `PASS` or `FAIL`; each can also be run
on its own from the `ArtificialPhysics` folder.

| Check | Tests | Time |
| --- | --- | --- |
| `monitors.lua` | `lib/monitors.lua` and the book's integrator against closed forms: spring periods, Kepler period, conservation, friction decay, external force, third-law violation, caps (22 tests) | < 1 s |
| `ch02.lua` | Ch. 2's results on `ch02/models.lua`: spring1D, spring2D, solar_system experiments a–e (27 tests) | 2 s |
| `world.lua` | `lib/world.lua` and its book presets: point tests, cells, corridor coverage, seeds, shadow cells, grids, CPT format (20 tests) | 10 s |
| `mfp_theory.lua` | Listing 11.4 in 2D and 3D against the exact mean free path | 4 s |
| `rng_appendix.lua` | The appendix's Listing A.1: `lib/rng.lua` flat at every S, `math.random` biased at S = 25–27 | 1 min |
| `batch_repeat.sh` | `lib/batch.py` gives the same CSV serially and in parallel (needs BPP; skipped if none is built) | 30 s |

A new port adds its check here and to `run_all.sh`. Checks use fixed seeds,
so their numbers repeat exactly.
