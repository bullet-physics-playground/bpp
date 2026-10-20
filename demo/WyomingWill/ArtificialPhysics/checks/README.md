# Checks: the regression suite

`bash checks/run_all.sh` runs every check and exits 0 only if all pass
(about 1 min 35 s; `--quick` about 45 s with smaller samples).

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
| `ch02.lua` | Ch. 2's results on `ch02/models.lua`: spring1D, spring2D, solar_system experiments a–e; our spring3D, tetrahedron (tennis-racket flips), planets (circular and elliptical: the gap and time-step rules) and spring lattice (47 tests) | 8 s |
| `world.lua` | `lib/world.lua` and its book presets: point tests, cells, corridor coverage, seeds, shadow cells, grids, CPT format (22 tests) | 7 s |
| `terrain.lua` | `lib/terrain.lua` and the five realistic presets (`lib/places.lua`): seeds repeat on every Lua, the shared stream untouched, ground() is the drawn mesh, the slope rule (15% along the grid, 21.2% across), river levels and depths, a long river's sinuosity 1/J0(1.1) and meander wavelength 11 widths, ponds hold water, the sea and its shelf, dredged depths, 1:3 sides and vertical quay walls, the world cut at a height (20 tests) | 7 s |
| `lattice.lua` | `lib/lattice.lua`: Delaunay triangulation (Euler's counts on 200 random sets, empty circumcircles), Ch. 16.9's edge CV on perfect, jittered and square lattices, 3D nearest-neighbour and bond CV (10 tests) | < 1 s |
| `ch13.lua` | `lib/ch13.lua` against Figs. 13.3 and 13.8: AR damping η, smooth through D, minimum −50 at 2D, off at p_d = 0 bit for bit; the stop rule; the 2D particle replica of the drone law: dithers without η, settles at ~0.8 D with η at range 1.5, at D with range 1.25 or when switched on after forming, or in a band w = 0.2; Eqs. 13.23–13.25: adaptive and static friction, the adaptive speed cap (FINDINGS F43, F45, F49, F50; 26 tests) | 1 s |
| `mfp_theory.lua` | Listing 11.4 in 2D and 3D against the exact mean free path | 4 s |
| `rng_appendix.lua` | The appendix's Listing A.1: `lib/rng.lua` flat at every S, `math.random` biased at S = 25–27 | 1 min |
| `batch_repeat.sh` | `lib/batch.py` gives the same CSV serially and in parallel (needs BPP; skipped if none is built) | 30 s |

A new port adds its check here and to `run_all.sh`. Checks use fixed seeds,
so their numbers repeat exactly.
