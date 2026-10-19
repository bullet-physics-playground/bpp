# Printing the PLA-only monostable polyhedron (ppla37)

`ppla37.stl` is a polyhedron that rests on only one of its 37 faces: an apex above six
regular hexagons, 150 mm tall. It has no added weights. It is one PLA print that is solid
up to 23.65 mm above the base. Above that is a single closed air void with 1.0 mm walls, so
the centre of mass sits 23.7 mm up. Set down on any other face, it tips band by band
(S6 → … → S1) onto its base. `ppla37-cutaway.png` shows the section.

In effect it is a faceted Weeble, a self-righting toy with flat faces. The fill's top is
level with the centre of mass, which is the fill level that puts the centre of mass lowest
(the soda-can puzzle). Being bottom-heavy is not enough on its own for flat faces: the shape
and the fill were fitted together so it cannot rest on any of its 36 other faces.

This is the gallery's own design, not one from a paper. The design scripts and logs are in
`../reconstruction/pla/`.

The STL is in millimetres with the base on z = 0. It holds two shells: the outer surface,
and the void as an inward-facing inner surface. Together they form one watertight solid of
267.16 cm³. Its size is 148.5 × 128.6 × 150.0 mm.

## Settings

| setting | value |
|---|---|
| orientation | **base down**, as the file comes (the large hexagon on the bed) |
| supports | **none**. No surface overhangs more than 45° from vertical; the S1 band and the void's ceiling under the top band are right at 45°. |
| nozzle / layer | 0.4 mm nozzle, 0.2 mm layers |
| infill | **100%** (the design assumes solid PLA everywhere that is not void) |
| perimeters | at least 2 |
| material | PLA, 1.24 g/cm³ assumed |

## The slicer must keep the void

The design only works if the void stays empty. Some slicers merge the inner shell into the
outer one and fill the whole body solid. A filled body weighs 1.65 kg and its centre of
mass is 57.5 mm up instead of 23.7 mm. It can then rest on the base and on every band of
side faces except the top one, so it will **not** be monostable.

- **PrusaSlicer / OrcaSlicer:** use the "Regular" slicing mode (the default). Do not use
  "Close holes", which fills the void.
- **Cura:** turn **"Union Overlapping Volumes" off** (Mesh Fixes). This has not been tested.
- **Check the layer preview.** Up to about 23.6 mm every layer should be solid. Above about
  24 mm every layer should show only the 1 mm outer wall around an empty middle, all the
  way up to the closed top.
- **Check the estimate:** about 267 cm³, which is about 111 m of 1.75 mm filament.

## Check the print

Weigh it:

- **~331 g:** correct.
- **~1.65 kg:** the void was filled. It will not work; re-slice.
- In between: some of the void was filled, or the infill was not 100%. A body that is
  lighter than intended in its base raises the centre of mass.

Then set it down on each band of side faces. It should always end up on the base.

## How much error it tolerates (calculated, not tested on a real print)

`../reconstruction/pla/robust.py` runs 300 random builds per row, with exact mass
properties for each. It still has exactly one stable face in 100% of builds in each of these
cases:

- every face plane (outer and inner) off by 0.1–0.5 mm;
- walls 0.2 mm thinner or 0.4 mm thicker;
- perimeter and infill densities 3–10% apart, or a 2–5% density gradient;
- elephant foot up to 0.6 mm;
- all of these combined at 0.5 mm.

With 1 mm plane errors the rate drops to 89%. The nearest false face has the centre-of-mass
foot 12.35 mm outside it.

One caveat: in about a fifth of builds, plane errors split the apex into two unstable
vertices a fraction of a millimetre to a few millimetres apart. It still rests on only one
face, but strictly it is then not a "discrete Gömböc" (one stable and one unstable point).

No real print has been made or tested yet.
