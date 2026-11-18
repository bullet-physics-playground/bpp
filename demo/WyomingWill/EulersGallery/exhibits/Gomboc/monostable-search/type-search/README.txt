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
