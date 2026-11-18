Robust smooth g-type (shape chat, 18 Nov 2026; family "option 2" in the handover doc)

GOAL: mono-g1/g3 (smooth, one resting and one balancing point, 90 deg apart, no crease) made to survive drops.

SCORE: the families chat's lever shortfall (families/common/fam.py): over directions more than 25 deg from the rest
  and 10 deg from the top, the mean of max(0, 0.45 - lever), lever = face lever in mm at 36 mm.
  glever.py measures it for smooth genomes (smooth.py) in exactly fam.face_lever's units; f0_best_b comes out at
  0.158 mm minimum, as the families chat reported.

TOOL: gdeficit.py in.npy out.npy MINUTES  -- trust-region linear-programme steps that lower the shortfall.
  Linearised in each step: lever floors (no lever below min(now, 0.1 mm); within 25 deg of upright below
  min(now, 1.2 mm)) and least radius of curvature >= 0.25 mm. A step is kept only if the level-6 grid still
  counts 1/1 at 0.5 um, radius >= 0.2 mm and the shortfall falls; every 5th kept step must pass smooth_check.
  Lessons (gdeficit_first_try.log and the runs in between):
    * without the curvature limit in the step, every step went concave and was rejected;
    * without a floor near the top, steps made a second balancing point;
    * without the bowl floor, the optimiser weakened the levers at 10-25 deg (1.2-1.5 mm down to 0.5 mm),
      which the score ignores: shortfall 0.0095 but drops FELL from 66% to 50% (stops at 10-25 deg).

RESULT: mono-g3b = gdeficit.py ../genomes/mono-g3.npy g3b.npy 25   (gdeficit_g3b.log; stops on time)
             shortfall  below 0.45  weakest (mm at 36)  bowl 10-25 deg min   drops upright, drop.py 120 x 2 seeds
  mono-g3    0.0375     19.9%       0.082               1.20-1.49            66%, 64%  = 65%
  mono-g3b   0.0087      6.2%       0.070               1.20-1.43            87%, 83%  = 85%
  f0_best_b  0.0087      9.1%       0.158               (edged, for comparison)
  smooth_check mono-g3b: exact 1 resting, 1 balancing, 0 saddles; grid L7 1/1 at every depth; least radius 0.25 mm;
  widths 82.3 x 82.7 x 89.7 mm.  Seed 1: python3 -c "import drop, numpy as np; drop.run(np.load(F), 120, seed=1)"
  Weakest lever 0.070 mm at 36 mm is half f0_best_b's: printed-hull flats (about 0.15 mm) may undo it.
FILES: ../genomes/mono-g3b.npy, ../meshes/mono-g3b.obj/.lua (build.py --write; like mono-g1's, this faceted mesh
  has shallow false resting faces: 18 deeper than 5 um, 1 deeper than 20 um).
NOT DONE: printed-hull BPP drops (printing chat's rig); a fine mesh for printing.
