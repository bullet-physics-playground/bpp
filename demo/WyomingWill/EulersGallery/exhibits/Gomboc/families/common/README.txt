FAMILIES 1-3: SHARED BUILDER, SCORE AND SEARCH (families chat, 18 Nov 2026) -- work in progress

  python3 fam.py FAMILY TAG SECONDS SEED [K] [START.npy]     (fam.py header has the details and env options)
Families: c3 (one free piece copied at 0/120/240 deg about +Y, edged's polar axis, plus a round m = 0 piece),
mirror (K pieces even under x -> -x), free (K pieces, MINPIECES must show). Symmetries are exact to 1e-15.
Score: convex to 0.3 um, (1,1) at 0.5 um on levels 5 and 6, then the mean shortfall of the exact face lever
below 0.45 mm at 36 mm (beyond 25 deg from upright, more than 10 deg from the top). 0.45 = friction 0.05 +
a 1 deg slope push 0.3 + about 0.1 lost to printed layer flats (family0/README.txt).

FAMILY 3 (c3), first two 9-minute runs:
  best_c3_r1.npy     random start: stuck at ~1.2 mm of extra equilibria; the farthest points were on the
                     three creases below the equator, the top junction only a secondary maximum
  best_c3_acorn.npy  start: copies taller toward +Y and tilted outward (a three-sided tip): stuck at ~2 mm;
                     the round piece vanished and the body became a rounded triangular barrel with maxima at
                     both poles and a resting point mid-face on each copy (3 rests + 2 tops)
  A convex corner can only be a balancing point, so the junction must be the top and the rest must sit on
  the round piece at the bottom. Next: build the round piece so it cannot vanish (e.g. it alone below a
  latitude), then search the copies for faces whose distance rises monotonically from the cap to the tip.
