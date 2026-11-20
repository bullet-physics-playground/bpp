# The Slide Rule: findings

*What was tried and measured in building it (2026-11-16).*

## Not much to simulate, said plainly

`MACHINES.md` scored it 1 for complexity: "one slide; nothing to
simulate". That held. The computing is geometry (lengths added along a
line), and the physics is two parts sliding in grooves, held by friction.
Both are simulated as bodies, as the hall's standard asks, and every
reading is taken from where they are; but nothing here is chaotic or
delicate, and the sweeps below change nothing but the time taken.

The slide and the cursor are each a body on a slider constraint along
the rule (the slider is the groove: the slide's dovetail, the cursor's
tongues in the stock's edge grooves; the printed parts' 0.2 mm clearance
is not modelled, and the parts don't touch in the simulation). A motor on
each slider at no speed and a small force is its friction, as the
suanpan's beads have: 50 kg cm/s² (0.5 N) for the slide, 0.6 of it for the
cursor. The rule lies tilted 25 degrees toward you, so gravity pulls the
slide across its groove, which the constraint holds; along the rule it
has no pull.

## Setting each part against the other

The first version planned every move as a number: the cursor to the
place where 3.2 on C *would* be, given where the plan had put the slide.
That is a shortcut in the part that computes. A sweep found it: with the
finger slowed to 2 cm/s, a long slide move ran out of time and the slide
stopped 10 mm short of its place, yet 7.5 / 2.5 still read 3.00, because
the cursor went to the planned place of C's index, not to the index
itself.

Now each move is made as a person makes it, against what is there
(`R.target` in `rule.lua`): the cursor to a number on the stock; the slide
to put one of its marks under the hairline wherever the hairline stands;
the cursor to a mark on the slide wherever the slide stands. An error in
setting the slide is carried into the reading. (The finger's give-up time
is now the distance over its speed plus 4 s, so a slow finger finishes.)

## How exactly the parts must be set

`rule-test.lua` works each kind of problem 20,000 times on random numbers
of three figures (0.001 to 999), with no physics: first with the parts
placed exactly, then with every move left off by a random amount up to
0.05, 0.1 and 0.2 mm, each move made against where the other part was
left. Right means the answer equals the true answer, to the figures read,
within one in the last figure.

| | exactly | ±0.05 mm | ±0.1 mm | ±0.2 mm |
|---|---|---|---|---|
| multiply | 100% | 98.97% | 91.95% | 75.98% |
| divide | 100% | 98.59% | 89.46% | 69.59% |
| square | 100% | 100% | 97.38% | 80.08% |
| square root | 100% | 100% | 98.41% | 88.31% |
| cube | 100% | 99.75% | 89.92% | 68.74% |
| reciprocal | 100% | 100% | 97.23% | 77.45% |
| logarithm | 100% | 100% | 100% | 100% |

So a 25 cm rule's third figure asks for each setting to within about a
twentieth of a millimetre; a tenth costs a tenth of all products, since
multiplying and dividing set three things and their errors add. The cube
is hardest of the one-setting problems (K's three decades magnify the
cursor's error three times); L, evenly divided, forgives most.

The finger lets go when its part is within 0.02 mm (`SR_TOL`, 0.002 cm),
held there 0.08 s; the part creeps on meanwhile and stops 0.009 to 0.010
mm from its place, every time. Loosened, the tours begin to fail where the
table says:

| The finger lets go within | Left off by (largest) | Multiplying tour | The second way's |
|---|---|---|---|
| 0.02 mm (the default) | 0.010 mm | PASS | PASS |
| 0.05 mm | 0.024 mm | PASS | PASS |
| 0.1 mm | 0.050 mm | FAIL: 3 × 4 read 12.02 | PASS |
| 0.2 mm | 0.099 mm | FAIL: 12.03 | FAIL: 2³ read 8.02 |
| 0.5 mm | 0.244 mm | FAIL: 3 of 9 | FAIL: 3 of 6 |

3 × 4 goes first: its product is read at D's left end to four figures
(1.200), the most demanding place on the rule.

## Sweeps

Each tour, headless (`SR_...`): every reading right, and every part left
within 0.010 mm of its place, whatever was changed.

| | Multiplying tour (9 readings) | The second way's (6) |
|---|---|---|
| as it is: friction 50, finger 6 cm/s, 600 steps/s | PASS, 8491 frames | PASS, 3007 frames |
| friction 5 | PASS | PASS |
| friction 200 | PASS | PASS |
| finger 2 cm/s | PASS, 13,675 frames | |
| finger 15 cm/s | PASS, 7013 frames | PASS, 2700 frames |
| 300 steps a second | PASS | PASS |
| 2400 steps a second | PASS | PASS |
| 40 random problems (`SR_RANDOM=40`) | PASS: 40 right, 20 products and 20 quotients | PASS: 40 right |

Headless, a tour takes a few seconds of computing: the cheapest exhibit
in the hall. check-all allows 9500 frames (10,100 in the hall) and 3600
(4200).

## The scales

`make-scales.py` draws the scales once and writes them twice: as
textures for the simulation and as an A4 sheet (SVG, then PDF through
Chromium's printing) to glue on a printed rule. Rasterised at 600 dpi, the
sheet's check bar measures 99.99 mm and D's two indexes stand 249.999 mm
apart.

bpp draws a texture with linear filtering and no mipmaps, so a texture
much finer than the screen shows its ticks unevenly (some vanish, some
shimmer). At 10 pixels a millimetre, with no line thinner than 1.5
pixels, the ticks hold up at the exhibit's view, and `M` (the camera
over the hairline, following it) shows every figure clearly. In the
exhibit's own view the figures are too small to read on a 1920-pixel
screen: that is what `M` is for.

`M` first put the camera 11 cm from the hairline. On its own that was
fine; in the hall the screen showed the underside of the table. bpp sets
its near clipping plane from the size of the whole scene (QGLViewer: 0.005
× √3 × the scene's radius), which for the 42 m hall is about 21 cm, so the
rule and most of the table top were cut away. The camera now stands 30 cm
off with a narrow field of view (0.36 rad, for π/4), put back when `M` is
pressed again or you walk on (the hall's `v:onLeave`). It also stands
upright, (0, 1, 0): the hall turns an exhibit's camera points into its bay
but passes an up vector through as it is, so a tilted one came out wrong
in an east bay; looking down onto the tilted face, upright puts the
scales the right way up anyway.

## The printed parts

Every STL is one watertight solid under 200 mm. Put together, with the
slide closed, at both ends of its travel and between, and the cursor at
each end, in the middle and right over each foot, no two parts overlap
(the largest common volume is 0.003 mm³: faces that touch, the feet under
the stock and the window in its recess). The cursor's tongues first came
out as separate bodies (they only touched the end pieces); they now start
inside them.

**Not tested:** a printed rule. How freely a printed dovetail slides and
how well a paper scale stays put; whether a 0.2 mm clearance lets the slide
rock enough to matter (a tenth of a millimetre at the hairline costs the
third figure, above). Measure the force to move the slide before trusting
the friction slider's 0.5 N.
