Are there (1,1) types other than the gomboc, mono-g1 and the e-type?  (shape chat, 17 Nov 2026)

TYPE MARKER: the angle between the resting and the balancing point, seen from the centre of mass (describe.py).
  gomboc F2 179 deg   mono-g1 91 deg (smooth, um tolerances)   mono-e1 71, mono-e2 81 deg (top on a crease)
  e1 and e2 are one type, found from two independent starts.

SEARCH: edged_search_t.py = ../edged_search.py (K = 3 pieces, L = 4) with an optional target angle; 15 min each, 2 cores.
  run (TARGET, seed)   result after 15 min                                       angle   type
  120, 21              stuck: 508 um of extra equilibria, one smooth piece        107
  150, 22              stuck: 303 um, one smooth piece                             63
  180, 23              (1,1) at 2 um (0.5 um extra on level 6), 3 pieces            75    e-type (top on crease), a 3rd time
  none, 7              stuck: 220 um, one smooth piece                             93
  none, 8              stuck: 316 um, one smooth piece                             60
  Every run that reached (1,1) landed in the e-type; the angle target only acts once level 6 is clean, so it never
  bit (a weakness: it should act at every stage). The others never formed a crease in 15 min, as K = 1, 2 never did.
FILES: e_best_<run>.npy (75 numbers, edged.body(a, 3, 4, level)), <run>.log; describe.py works on edged genomes and .obj.

Run 2 (18 Nov 2026), angle penalty at every stage, 20 min each, K=3 L=4:
  t2_w120  target 120, warm start mono-e2: (1,1) at 2 um, angle 91, smooth (one piece)
  t2_r150  target 150, random:             (1,1) at 5 um, angle 68, smooth
  t2_r180  target 180, random:             (1,1) at 0.5 um, angle 56, smooth, Q 0.028 mm/rad
  t2_r120  target 120, random:             (1,1) at 0.5 um, angle 84, top on crease (e-type again)
None reached its target; the angle penalty loses to the equilibrium-count stages.
t2_r180 is a smooth (1,1) at 56 deg, an angle no known shape has, but its lever is very weak.

Run 3 (18 Nov 2026), checking t2_r180:
  Drops (edged_drop.py 120 e_best_t2_r180.npy): upright 0 of 120, stops spread 10-163 deg (median 84).
    Mathematically (1,1), physically not self-righting: the lever (0.028 mm/rad) is too weak for friction.
  Polish: TARGET=56, X0=e_best_t2_r180.npy, 20 min, seeds 51 and 52 (t3_p56a, t3_p56b):
    both LOST (1,1) (3/3 and 1/4 at 0.5 um), angle 63-64, Q 0.011 and 0.002. No stronger 56 deg body nearby.
  Verdict: the 56 deg smooth body is a fragile point, not a usable new type.
