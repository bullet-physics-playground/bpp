# Checks: the regression suite

`bash checks/run_all.sh` runs every check and exits 0 only if all pass
(about 2 min 40 s; `--quick` about 1 min 50 s with smaller samples).

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
| `terrain.lua` | `lib/terrain.lua` and the five realistic presets (`lib/places.lua`): seeds repeat on every Lua, the shared stream untouched, ground() is the drawn mesh, the slope rule (15% along the grid, 21.2% across), river levels and depths, long rivers' mean sinuosity 1.4 and meander wavelength 11 widths, no lasting period, natural disturbances, no channel touching itself, ponds hold water, the sea and its shelf, dredged depths, 1:3 sides and vertical quay walls, the world cut at a height (21 tests) | 8 s |
| `town.lua` | `lib/town.lua` on the five presets: the LCZ table, Clark's exponential, zones stepping down the ladder outward, water as zone G, woods' share of open land, seeds, streets on dry land except bridges (≤ 150 m), every street reached from an arterial (an independent raster flood), the city's Manhattan spacing and widths, cul-de-sacs up to 229 m with a 15 m turning circle, each starting on a collector (16 tests) | 10 s |
| `buildings.lua` | `lib/buildings.lua` on the five presets: every built zone covering ≥ 3% of a preset inside Stewart and Oke's ranges of building fraction and mean height, whole floors, the city's heavy-tailed skyline falling outward then level, the gap rule (touching buildings make one obstacle; obstacles ≥ 3 m apart), buildings off the streets and out of the water, farmsteads, seeds, the shared stream, `blockedAt` and `writeCPT` with buildings (13 tests) | 35 s |
| `features.lua` | `lib/features.lua`, `lib/vegetation.lua` and the outputs: the ship afloat with its leak, piers, warehouses' doorways, the container yard, the storm drain (falling invert, cover, open inside, outfall), launch pads, the woods (300 trees a hectare, in zone A and off streets, open between the trunks and closed above), trees and hedgerows, rasters, line of sight, traps, seeds (20 tests) | 15 s |
| `lattice.lua` | `lib/lattice.lua`: Delaunay triangulation (Euler's counts on 200 random sets, empty circumcircles), Ch. 16.9's edge CV on perfect, jittered and square lattices, 3D nearest-neighbour and bond CV (10 tests) | < 1 s |
| `ch13.lua` | `lib/ch13.lua` against Figs. 13.3 and 13.8: AR damping η, smooth through D, minimum −50 at 2D, off at p_d = 0 bit for bit; the stop rule; the 2D particle replica of the drone law: dithers without η, settles at ~0.8 D with η at range 1.5, at D with range 1.25 or when switched on after forming, or in a band w = 0.2; Eqs. 13.23–13.25: adaptive and static friction, the adaptive speed cap (FINDINGS F43, F45, F49, F50; 26 tests) | 1 s |
| `mfp_theory.lua` | Listing 11.4 in 2D and 3D against the exact mean free path | 4 s |
| `rng_appendix.lua` | The appendix's Listing A.1: `lib/rng.lua` flat at every S, `math.random` biased at S = 25–27 | 1 min |
| `batch_repeat.sh` | `lib/batch.py` gives the same CSV serially and in parallel (needs BPP; skipped if none is built) | 30 s |
| `vehicles.sh` | The vehicle interface (`lib/swarm.lua`, G18): every vehicle module provides it; each vehicle meets its specification (`vehicle_physics.lua`: the ground robot's speed and turn caps and minimum-speed gap; the boat's draft, top speed, righting and sideways motion); the harness on the ideal vehicle forms the LJ 2D triangle at D (needs BPP) | 20 s |

A new port adds its check here and to `run_all.sh`. Checks use fixed seeds,
so their numbers repeat exactly.
