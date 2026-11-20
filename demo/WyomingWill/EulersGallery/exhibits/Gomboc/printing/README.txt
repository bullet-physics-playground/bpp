Printing the gombocs and self-righting loaves (Ender 3, PLA, Cura) -- from the printing chat, Nov 2026

gomboc_split.scad   OpenSCAD (Customizer): splits a body into two halves for support-free printing,
                    with 1.75 mm filament pin holes and a 0.4 mm chamfer on the cut-face edges.
  shape   gomboc900 | l4 | f2 | mono_p1 | mono_s2 | mono_s4
  cut     across (recommended), along, current, old8, custom (the loaves: across only)
  size    long-axis length in mm (36 tested). Pin holes and chamfer are not scaled.
  plumb_mark: a 1.6 mm dent at the top of the vertical through the centre of mass. With the across cut it
          lies on the seam; resting upright, it sits straight above the contact point and the seam is
          vertical, so you can judge "upright" by eye on any shape. The hull bridges it (no effect).
  seam_line auto: Z seam along the TOP for the gombocs, along the UNDERSIDE for the loaves.
          Each piece is turned on the bed so that side faces the slicer's seam position;
          slicer_seam = front matches the profiles here. Place the STLs in Cura without rotating.
*_90mm.stl          the meshes the .scad imports (90 mm long, centre of mass at the origin,
                    upright = +Y). gomboc900 = ../gomboc-meshes/gomboc.obj, l4 = l4.obj, f2 = f2.obj;
                    mono_s2 / mono_s4 are the genomes rebuilt on a 163,842-plane icosphere;
                    mono_p1 is ../monostable-search/meshes/mono-p1.obj.
gomboc_split_ender3.curaprofile, gomboc_split_brim_ender3.curaprofile
                    0.12 mm adaptive layers, 5 walls, 100% infill, first-layer xy offset -0.1 mm,
                    Z seam user-specified at the front of each part.

What we found (36 mm, across cut):
  - Table slope, not friction, is the main real-world failure: h tan(slope) is 0.24 mm per degree
    for the gombocs (h = 13.9 mm). On a 1.4 deg table GOMBOC900 and L4 can be balanced on their side.
  - L4: 79/80 upright on levelled glass. GOMBOC900: about 19/20.
  - The Z seam on the side of the cylinder traps a gomboc at about 100 deg; along the top it is harmless.
    On the loaves the seam goes underneath (on top it traps near 162 deg).
  - Simulated drops (BPP, printed hulls): mono-s2 100% on level and 1-2 deg tilted tables, also
    with a 0.1 mm slip between the halves.
