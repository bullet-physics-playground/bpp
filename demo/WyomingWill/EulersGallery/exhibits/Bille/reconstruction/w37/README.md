# w37: design study for the weighted 37-corner print

These are the scripts and logs behind `../../print/w37/`: a Conway (6,6)-spiral with a stock
weight in a printed pocket at each of its 37 corners. The ring radii and heights are
refitted for the real mass distribution. **Status: designed and simulated, not yet printed.**

## Why this study exists: the 9 cm p26/p37 cannot be built as stated

The headers of `../../bille-meshes/p26.lua` and `p37.lua` used to call them "a REAL object,
not an idealisation: a 0.5 mm polycarbonate shell with a 5.2 g tungsten weight in every
corner, centred 3 mm inside it". `fitcheck.py` (log: `runs/fitcheck.log`) tests that claim
using the gallery's own construction (`../../../Gomboc/variety-reconstruction/genshell.py`:
each weight centre 3 mm from its corner, towards the mean of the corners):

| | p26 (5,5) | p37 (6,6) |
|---|---|---|
| mass (stated / reproduced) | 141.67 / 141.67 g | 201.15 / 201.15 g |
| margin, the fit's own measure (stated / reproduced) | 1.43 / 1.43 mm | 3.36 / 3.36 mm |
| margin as the distance the centre of mass must move (core.py): faces / corners | 1.43 / **0.71** mm | 3.36 / **2.41** mm |
| 5.2 g of tungsten (19.25 g/cm³) | an 8.02 mm ball, or a 6.46 mm cube | same |
| weight centre to the nearest face plane | 1.11–2.46 mm (a ball needs 4.01 mm, plus the 0.5 mm shell) | 1.54–2.45 mm |
| closest weight centres | 3.78 mm (a ball needs 8.02); 15 pairs closer than 8.02 mm | 2.46 mm; 24 pairs |
| corner spacing between the bottom rings | 4.40–4.62 mm | 2.78–3.79 mm |

So a real 5.2 g tungsten weight would stick 2–3 mm out through the shell, and neighbouring
weights near the base would overlap. Neither body can be built at 9 cm as described.
(The earlier study reported 201.0 g, 3.37 mm and 2.43 mm for p37 with its own
reimplementation; the small differences come from the different implementation.)

The gallery still simulates p26 and p37 unchanged. They are now described honestly as
idealised designs: a thin shell plus point-like corner weights, with the mass properties
exactly as computed for that model.

## What the study found

The study placed each weight as close to its corner as 0.8 mm PLA walls allow, using the
real shape of each stock weight, with at least 0.8 mm of PLA between pockets, then refitted
the rings (`opt.py`). Results (`runs/materials.json`, the guide's Section 2):

- **Recommended:** 37 tungsten pinewood-derby cylinders, 3/8″ × 0.44″, 0.5 oz (14.17 g), in a
  0.8 mm PLA shell, 200 mm tall, 626 g. Smallest margin 4.16 mm. 7 pauses at Z = 12.80,
  14.80, 19.60, 29.00, 48.20, 78.20 and 187.60 mm (0.2 mm layers). With every face plane
  independently off by 0.1 / 0.2 / 0.3 / 0.5 mm, 100 / 95 / 81 / 27% of builds keep exactly
  one stable face (`final/robust-W.log`). In bpp, 88 of 88 drops and 36 of 36 set-downs
  ended on the base (`sim-W/logs`).
- **Cheap but fragile:** hardened steel dowel pins, 10 × 20 mm, in a 220 mm body. Margin
  1.37 mm; 85 / 22% of builds survive 0.1 / 0.2 mm face errors (`final/robust-St.log`).
- **Fail:** steel balls, lead balls and 1/4″ tungsten cubes. Lead rod, 12 mm tungsten balls,
  tungsten putty and bismuth cylinders work, with less margin (`final/robust-alt-*.log`).

## Files

| file | what |
|---|---|
| `core.py` | exact polytope mass properties, equilibria and margins (identical to `../pla/core.py`) |
| `w37.py` | the weighted body: shell, pocket blocks, pockets, weights and glue, all exact; `Body`, `Weight` |
| `materials.py` | the stock weights (dimensions, masses) |
| `meshbuild.py` | the printable solid (manifold3d): shell, pocket blocks, pockets, void |
| `from_gallery.py` | the gallery's p37 shape as a starting point |
| `opt.py` | refits ring radii and heights for one weight and height (Nelder–Mead); `opt_robust.py` is a robustness-weighted refit (logs `runs/rob_W_s0*.log`: it lowered the margin to 3.5–3.7 mm and was not adopted) |
| `scan*.sh`, `job.sh`, `refine.sh`, `jobs*.txt` | the optimiser runs in the order they were made → `runs/scan_*.log`, `runs/refine_*.log`, `runs/opt_*.npy` (design vectors) |
| `gather.py`, `matfig.py` | best result per weight and height → `runs/materials.json`, `materials.png` |
| `robust.py`, `alt_robust.sh` | print-error trials → `final/robust-W.log`, `robust-St.log` (300 per row), `robust-alt-*.log` (200 per row) |
| `export.py` | writes the STL, OBJ, bpp data file, props and summary; `figs.py` the figures; `coupon.py` the fit coupons |
| `slicecheck.py`, `slicer/w37-pla.ini` | slices with PrusaSlicer and checks the pockets against the pauses in the G-code → `*.gcode.check.json` |
| `finalize.sh` | export → figures → coupon → slicer check for one design, then publishes the print files to `../../print/w37/` |
| `sim/w37-drop.lua`, `sim/run_tests.sh` | the Bille Drop harness with only the body list changed (via `../pla/sim/pla-drop.lua`); drops and set-downs at real size → `sim-W/logs`, `sim-St/logs` |
| `simtally.py`, `prep_guide.py` | tallies of the sim logs (`final/sim-tally*.json`); coupon pause heights (`final/coupons.json`) |
| `make_extra.py`, `build_guide.py` | the guide's text and tables (`final/extra.json`), then the PDF → `../../print/w37/w37-build-guide.pdf` |
| `fitcheck.py` | the p26/p37 check above |
| `final/` | design vectors (`w37-W.npy`, `w37-St.npy`), bpp body files (`-data.lua`, `.obj`), summaries, export and slicer logs, robustness logs, sim tallies |

## Running

Run everything from this folder; paths inside the scripts are relative (`runs/`, `final/`,
`../../print/w37/`). You need Python 3 with numpy and scipy. export, figs, coupon and
meshbuild also need trimesh, manifold3d and matplotlib. build_guide needs reportlab, Pillow
and the DejaVu fonts in `/usr/share/fonts/truetype/dejavu/`. slicecheck needs `prusa-slicer`
(2.7.2 was used) on the PATH.

```
python3 fitcheck.py                                       # the p26/p37 check
python3 opt.py W-cyl-3/8x.44 200 0.8 1 210 0.8 none runs/opt_W-cyl-3_8x.44_H220_t0.8.npy   # one refit
python3 robust.py final/w37-W.npy W-cyl-3/8x.44 300 0.8   # robustness table
sh finalize.sh w37-W W-cyl-3/8x.44 runs/opt_W-cyl-3_8x.44_H200_t0.8.npy   # STL, figures, coupon, slicer check
sh sim/run_tests.sh W                                     # bpp drops and set-downs (BPP=... to override)
python3 simtally.py sim-W/logs final/sim-tally-W.json
python3 prep_guide.py && python3 make_extra.py && python3 build_guide.py   # the guide
```

The guide was rebuilt in this folder on 19 Oct 2026. `make_extra.py` reproduced the study's
`extra.json` byte for byte, and `prep_guide.py` reproduced the coupons byte for byte. Only
wording changed after that: repository paths, the p26 note, and the cavity count of
w37-W.stl (the study said 38 inner shells; trimesh finds 44: the void, 37 pockets and six
9.4 mm³ air slivers by the top ring's pocket blocks, which are part of the exact model too). The optimiser, robustness and
sim runs were not repeated here; their logs are as the study wrote them.

## Not included (size or duplicates)

- G-code (`final/w37-W.gcode`, `w37-St.gcode`, about 17 MB each, judging by the 17.5 MB test G-code; not kept by the study either): `finalize.sh` regenerates
  it. The checks are in `../../print/w37/*.gcode.check.json`.
- `out_test/` (18 MB: a first test export of the 220 mm design, with G-code), `figtest/`,
  `pages/` and the page previews (`final/pg-*.png`, `final/sheet.png`), used only for
  proof-reading the guide.
- `sim/meshes/` (copies of `final/w37-*-data.lua` / `.obj` that `run_tests.sh` makes) and
  `sim/logs/` (the same as `sim-St/logs/`); `__pycache__/`; two empty logs
  (`runs/o_st12_200.log`, `runs/test_st12_200.log`).
- No `.npy` file was too large to include: all of them are 224-byte design vectors.

The STL, PDF, figures, props and slicer checks are kept only in `../../print/w37/`, not
duplicated here. The bpp body files of the two designs are in `final/`. They are not
gallery exhibits.
