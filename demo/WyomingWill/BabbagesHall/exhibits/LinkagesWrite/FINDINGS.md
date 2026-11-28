# Linkages That Write: findings

What was found while building the linkages that write (2026-11-28). The
searches ran William Spears's synthesizer (`synthesis/`), 2 cores, a
population of 40 a parameter, 1500 generations; the simulations at 600
steps a second, the solver at 80 iterations.

## 1. The margin: a linkage near toggle snaps in Bullet

The first linkage tried in bpp, an 8-bar C at the synthesizer's default
margin (`--min_margin_frac 0.05`), followed its computed curve for half a
turn, then went wrong for good: a dyad had snapped to its other assembly.
All three of its loops ran within 0.05 cranks of toggle, about 0.3 mm on
an 8 cm letter: the search had used near-dead-centre positions for its
sharp moves. At a margin of 0.6 cranks the C still fitted to 1.1%, and in
bpp its pen kept within 0.03 mm of the computed curve on average, 0.1 mm at
worst, over a whole turn. Every search since used 0.6.

## 2. One pen can't draw a letter with junctions

The 26 capitals as one closed pen walk each (the strokes that meet are
gone over twice, by the shortest way: the Chinese postman's tour), up to
14 bars, two seeds:

- well (within about 1.5%): C, D, J, L, O, P, S, T, U, V;
- roughly: A (its bar an arch), B, F, G, I, N, Y, Z;
- not at all (5 to 13%): E, H, K, M, Q, R, W, X.

The pen of one linkage never lifts and can't turn back on itself sharply;
where strokes meet, it must. More bars barely helped. Cursive, each
letter one smooth closed curve (as William's writing cam does "Daisy"),
did no better: a, b, e, h and l at 2.3 to 5.8% with 12 bars.

## 3. A pen to each stroke

Split at its junctions, every stroke is like an L, a V or an S, which one
linkage draws well. With 2 or 3 pens, G, H, Q and X came within 1%, B, R,
I, A and N close, W, Y and M good. Split further, into single lines and
arcs, each kind found once and carried onto every stroke like it (one
linkage draws every straight stroke: a four-bar within 3% of the line's
length, six bars within 1.5%), every letter reaches every setting.

The slider's three settings: every pen within 8%, 4% or 2% of the
letter's height (the farthest the pen gets from its stroke, or a point of
the stroke from the pen). For each, the cheapest split and linkages (fewest
bars, then fewest pens). Very good takes 1 pen (O, C, L) to 7 (B), 4 bars
(O) to 34 (B).

## 4. Their reach

The synthesizer lets an arm be eight cranks long; a small crank under a
large letter then reaches far: B's one-pen linkage spanned 177 letter
heights. The picks allow no more than four letter heights over a turn, and
the straight lines and half circles were found again with arms at most
three cranks long (`LK_BOUND=3`, an addition): the line's four-bar then
reaches 1.6 line lengths instead of 4.2, as close.

A linkage can also whip a bar round: G's ten-bar arc moved a pin 19
cranks for every radian of its crank, and with the crank turning once in
4 s its pen lagged to 1.1% off (computed 0.3%; at 6 s, 0.4%). The picks
allow no pin faster than 20 cranks a radian (the S's halves were found
again compact for it), and the slider turns the crank in no less than 6 s.

## 5. The warm start

Searched from nothing, a bigger linkage often came out worse than a
smaller one (A: 4.9% with 8 bars, 3.7% with 6). Started from the best
smaller linkage, with the new dyad hung where it draws nothing new (its
pen at its first point, u = v = 0, on equal arms from a pivot clear of the
curve), a bigger linkage never does worse.

## 6. Keeping the cranks in step

Every pen's crank turns once, 1:1 with the first, as a timing belt would
keep them. Bullet's gear constraint ties two bodies' speeds, not their
angles: in H and B (3 and 7 linkages) the cranks kept within 0.9°, but
in S, whose lower stroke's linkage pulls hard part of the way round, a
crank fell 114° behind in one turn and the stroke came out 14.6% off. Each
other crank's hinge now drives it to the first crank's angle (its speed,
plus 30 per second of the angle it is behind): every crank within 0.6° of
the first, the S's stroke as computed.

## 7. Bpp against the search

Each pen's drawn dots against its stroke, beside what the search computed
(the letter 8 cm tall):

| letter, setting | pens, bars | worst pen, drawn | computed |
|---|---|---|---|
| B, very good | 7, 34 | 1.56% | 1.46% |
| G, very good | 2, 14 | 0.76% | 0.75% |
| H, very good | 3, 18 | 1.79% | 1.79% |
| S, sloppy | 2, 12 | 3.71% | 3.79% |

Against its own computed curve, at its own crank's angle: H's pens within
0.08 mm, B's within 0.14 mm (a 10 cm letter).

Every letter at every setting, 78 drawings (`LW_ALL=1`, the crank turning
once in 6 s): every pen within 0.5% of the letter's height of what the
search computed for it, the cranks in step within 2.2°.
`tools/check-all.sh` runs the tour.
