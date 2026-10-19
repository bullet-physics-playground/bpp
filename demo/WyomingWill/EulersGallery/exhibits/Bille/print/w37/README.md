# Weighted 37-corner monostable polyhedron (w37)

**Status: designed and simulated, not yet printed.** Every number below is calculated:
exact mass properties, simulated print errors, and Bullet runs in the gallery's harness.
Nobody has printed, weighed or tested one yet.

This is a polyhedron with 37 faces and 37 corners: an apex above six regular hexagons (a
Conway (6,6)-spiral after Domokos & Kovács, 2023). It has a tungsten weight sealed into
every corner. Set down on any face, it tips band by band (S6 → … → S1) onto its base. It has
one stable face (the base) and one unstable corner (the apex).

It is the buildable counterpart of the gallery's 9 cm `p37` body
(`../../bille-meshes/p37.lua`). That body is an **idealised** design and cannot be built as
it stands: a 5.2 g tungsten weight is an 8 mm ball or a 6.5 mm cube, so it cannot sit 3 mm
inside a corner. Also, the corners of the bottom rings are only 2.8–3.8 mm apart, so the
weights would overlap. The 26-corner `p26` has the same problem
(`../../reconstruction/w37/fitcheck.py`, `runs/fitcheck.log`). Here every weight is a real
stock part in a real pocket, and the ring radii and heights were refitted for that.

**The full instructions are in [`w37-build-guide.pdf`](w37-build-guide.pdf)** (12 pages):
theory, choice of weights, bill of materials, slicer settings, step-by-step printing and
assembly, checks, safety, and how robust the design is.

## Which file to print

| file | what |
|---|---|
| **`w37-W.stl`** | **the recommended body**: 200 mm tall, mm units, base on z = 0, printed base down. One outer shell plus 44 inner cavity shells: the void, 37 pockets, and six thin closed slivers of air (9.4 mm³ each) between the top ring's pocket blocks and the wall. If a slicer fills the slivers, the body gains 0.07 g, which does not matter. trimesh reports the STL watertight with consistent winding |
| `coupon-W.stl` | **print this first**: a fit test with three pockets exactly like the body's (pause at Z = 12.80 mm) |
| `w37-St.stl`, `coupon-St.stl` | the cheaper steel-dowel body (220 mm) and its coupon (pause at Z = 21.60 mm). It is fragile: see below |
| `w37-W-props.txt`, `w37-St-props.txt` | design numbers: ring radii and heights, the margin of every face and corner, pocket positions, pause table |
| `w37-W.gcode.check.json`, `w37-St.gcode.check.json` | PrusaSlicer 2.7.2 check: each pocket stays open until its pause and is closed straight after; filament mass |
| `w37-*-cutaway3d.png`, `-section.png`, `-bottom.png`, `materials.png` | the figures in the guide (the St ones are for the steel body) |

## Bill of materials (recommended build)

| item | qty | spec | mass |
|---|---|---|---|
| tungsten cylinder | 37 (+3 spare) | 3/8″ (9.53 mm) dia × 0.44″ (11.2 mm), 0.5 oz, e.g. pinewood-derby cylinders. Must fit a 9.83 × 11.58 mm pocket | 14.17 g nominal each, 524.3 g in total. Weigh them: all within ±1% (ideally ±0.5%) |
| PLA filament | 1 spool | 1.75 mm, 1.24 g/cm³ assumed | 100 g in the part |
| thin CA glue | optional | at most one small drop (0.03 g) per pocket | 1.1 g allowed for |
| **finished body** | | 200 mm tall, 132 mm across the corners | **626 g** |

Print with a 0.4 mm nozzle, 0.2 mm layers, 2 perimeters, 100% infill and no supports, base
down, with an 8–10 mm brim. The full settings table is in Section 4 of the guide.

## Pause heights (0.2 mm layers)

Pause **after the layer ending at** each Z below, drop that ring's weights into the open
pockets, and resume. There are 7 stops:

| pockets | count | pause at Z (mm) |
|---|---|---|
| ring 0 (base ring) | 6 | 12.80 |
| ring 1 | 6 | 14.80 |
| ring 2 | 6 | 19.60 |
| ring 3 | 6 | 29.00 |
| ring 4 | 6 | 48.20 |
| ring 5 | 6 | 78.20 |
| apex | 1 | 187.60 |

These heights are only valid for 0.2 mm layers. For other layer heights, re-derive them with
`../../reconstruction/w37/export.py`. The guide also gives the steel-dowel build's pauses.

## How good is the design (calculated)

- **Margin.** The centre of mass would have to move at least **4.16 mm** before a second
  rest face or balance corner appeared. For comparison, p37 measured the same way has 2.4 mm.
- **Face errors.** With every face plane independently off by 0.1 / 0.2 / 0.3 / 0.5 mm,
  100 / 95 / 81 / 27% of simulated builds keep exactly one stable face (300 trials each).
  Under a layer-by-layer model of an FDM print (as sliced, with layer shifts and size errors),
  the figure is 100%.
- **Dynamics in bpp, at real size.** 88 of 88 random drops and 36 of 36 set-downs (each wrong
  face once) ended on the base.
- **Cheaper alternative.** Hardened steel dowel pins, 10 × 20 mm, in a 220 mm body, 601 g.
  The margin is only 1.4 mm, and 85 / 22% of builds survive face errors of 0.1 / 0.2 mm, so
  this build is fragile. Steel balls, lead balls and 1/4″ tungsten cubes do **not** give a
  working body. The other options, with their margins, are in the guide's materials table
  (Section 2).

What is not modelled: warping, a slicer that fills the void, soft or uneven tables, and
vendor masses that differ from nominal. Weigh the parts and run the coupon test first.

## Where it came from

The scripts, optimiser and robustness logs, and the simulation harness and its logs are in
[`../../reconstruction/w37/`](../../reconstruction/w37/). Its README explains how to rerun
them and how to rebuild the guide.
