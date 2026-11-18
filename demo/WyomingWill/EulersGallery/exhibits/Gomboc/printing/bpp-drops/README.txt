Printed-hull drop rig for BPP (printing chat, Nov 2026)

  1. python3 printed_hull.py shape.obj --out cases          -> cases/NAME_al, NAME_sz, NAME_sy
     (convex body, upright = +Y; scaled to a 36 mm longest extent, cut across through the centre of mass,
     built layer by layer as printed; sz/sy = one half slipped 0.1 mm sideways / up. See the docstring.)
  2. BPP=/path/to/bpp ./run.sh cases/NAME_al 50 0 1 5400    -> cases/NAME_al.r50_a0_s1.log
     arguments: case folder, rolling resistance in um (GC_ROLL), table tilt in degrees (GC_SLOPE),
     seed, frames (60 a second; 5400 = 90 s, 6 bodies at a time, each re-dropped 5 s after it rests)
  3. python3 tally.py cases/*.log                          -> upright share and where the others stopped

gomboc-drop-slope.lua = ../../gomboc-drop-c.lua plus three changes: gravity tilted by GC_SLOPE degrees
toward +x; tilt measured from "up" against gravity; each rest line also gives the position and whether
the body is on the flat table or the edge ramp (tally.py counts only the flat).

Settings we use: GC_ROLL 50 (rolling resistance measured on PLA prints: glass 20-30 um, butcher block
50-70 um; earlier runs used 150), tilt 0, 1 and 2 deg, 1 seed (about 25-50 rests a run). On a tilted
table some bodies are still rolling downhill when the run ends; they are not counted. Identical rest
angles repeated in one log are usually the same body landing in the same place after re-drops.

Hulls of 80,000+ points are slow in Bullet; --step 0.2 halves them (the hull moves by well under 1 um).

../hulls/: printed hulls used in the printing chat's runs (NAME_case.npy, mm, build frame, +y up,
+x = cut normal) and their logs. families-e2: the families chat's mono-e2.obj (fd897ee), hull thinned to
every second vertex before the drops (volume change about 110 ppm).
