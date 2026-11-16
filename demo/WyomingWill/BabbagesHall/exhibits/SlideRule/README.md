# The Slide Rule

*Babbage's Hall, east bay 1: multiplying by adding lengths.*

The second machine on the walk, facing the suanpan. On the D scale every
number stands as far along as its logarithm: over 25 cm, 2 stands at
7.5 cm (log 2 = 0.301), 4 at 15.1 cm, 10 at the end. C, on the slide, is
the same scale. Put C's 1 over a number a on D, and every number b on C
stands over a × b on D: the slide has added the two lengths, as
logarithms add when numbers multiply.

This is a **Mannheim** rule, the kind most people used for a century:
A on the upper stator; B, CI and C on the slide; D, K and L on the lower
stator; a cursor with a hairline that reads them all at once.

| Scale | Where | What it is |
|---|---|---|
| A | upper stator | squares: two decades (1 to 100) in the length of one |
| B | slide, top | A on the slide |
| CI | slide, middle, red | C backward: over x on C, 1/x |
| C | slide, bottom | one decade, 1 to 10, as D |
| D | lower stator, top | one decade: the number v at log v of the way along |
| K | lower stator | cubes: three decades (1 to 1000) |
| L | lower stator, bottom | the logarithm itself, 0 to 1, evenly divided |

The operator's finger sets the slide and the cursor, one at a time, and a
slate behind the rule shows the problem, each step, what the rule reads,
the estimate that places the decimal point, and the answer.

## Two ways

In the hall, Tab steps through them (each has its own label on the
lectern); on its own, `SR_WAY` chooses.

**Multiplying and dividing** (the default). Type 2.5, X, 3.2 and press
Return:

1. The cursor to 2.5 on D.
2. The slide: C's 1 under the hairline.
3. The cursor to 3.2 on C.
4. Read D under the hairline: 8.00.

If C's 1 would put the answer off the right end (3 × 4), C's **10** goes
under the hairline instead, and the slide stands out to the left. To
divide, 7.5 / 2.5: the cursor to 7.5 on D, the slide so that 2.5 on C is
under the hairline, the cursor to C's index (the 1, or the 10 if the 1 is
off the rule), and the quotient on D.

The rule shows only figures: 2 × 3 and 20 × 300 look the same on it. The
decimal point is placed by a rough estimate, one figure of each number:
2.5 × 3.2 is about 3 × 3 = 9, so the rule's 8.00 is 8, not 0.8 or 80. The
slate shows the estimate. A 25 cm rule gives three figures, four from 1 to
2 on C and D (its marks there are every 0.01).

At one setting the slide gives a whole table: with C's 1 over 1.609 on D
(miles to kilometres), every number on C stands over its product; the
tour reads 2, 3 and 5 without touching the slide.

**Squares, roots, cubes, reciprocals, logarithms** (`SR_WAY=powers`).
Type a number, then a key; each needs only the cursor (the slide closed):

| Key | | How |
|---|---|---|
| `S` | square | the number on D, its square on A |
| `R` | square root | the number on A, its left half if it has an odd number of figures before the point (2, 200), its right half if even (20, 2000); the root on D |
| `K` | cube | the number on D, its cube on K |
| `I` | reciprocal | the number on C, 1/x on CI |
| `L` | logarithm | the number on D, the logarithm's figures on L; the whole number before them is where the point is (log 2000 = 3.301) |

    bpp -f slide-rule.lua                  (or walk to it in the hall)
    SR_WAY=powers bpp -f slide-rule.lua

| Key | |
|---|---|
| `0`–`9`, `.` | a number (the slate shows it) |
| `X`, `/` | multiplying: times, divided by, between the two numbers |
| `Return` | multiplying: work it |
| `S`, `R`, `K`, `I`, `L` | the second way: square, square root, cube, reciprocal, logarithm of the number |
| `Backspace` | a figure off |
| `C` | close the rule: the slide home, the cursor to the left |
| `M` | the camera over the hairline, following it, close enough to read the scales; again: back (walking on puts the view back too) |
| `T` | the tour. Multiplying: 2 × 3, 1.5 × 4.5, 3 × 4 (by C's 10), 7.5 / 2.5, 2 / 8, 0.25 × 36, and 1.609 × 2, 3 and 5 at one setting. The second way: 3², √2, √20, 2³, 1/4, log 2 |

The sliders: the slide's friction in its groove (the cursor's is 0.6 of
it), the finger's speed, and the simulation's speed. Resting the mouse on
a part says what it is and what every scale reads under the hairline.

## What is simulated, and what is the script's

The slide and the cursor are bodies, each on a slider constraint along
the rule (the slide's dovetail; the cursor's tongues in the stock's edge
grooves), held where they are left by friction (a motor on the slider at
no speed and a small force). The finger takes hold of one and moves it,
slowing as it nears its place, and lets go when it is within 0.02 mm.

Each part is set against the other **as it stands**: C's 1 goes under the
hairline wherever the hairline was left, and the cursor goes to 3.2 on C
wherever the slide was left. So an error in setting one part is carried
into the reading, as on a real rule. Every reading is taken from where the
slide and the cursor are, rounded to the figures a person reads, and
checked against the true answer to those figures.

The finger, the slate, the reading of the figures and the estimate that
places the point are the script's: a person works a slide rule, and the
slate shows what the person knows. The parts do not touch in the
simulation: the sliders are the grooves (its help says so).
`FINDINGS.md` has the measurements.

## The parts

Printed but the cursor's window. `./make-stls.sh` makes the STLs, each
turned to lie on the printer's bed (OpenSCAD); all are under 200 mm.

| Part | Print | Notes |
|---|---|---|
| `stock-left.stl`, `stock-right.stl` | 1 each | the stock in two halves, 145 × 46 × 8 mm: a dovetail channel for the slide, a V groove in each long edge for the cursor; printed face up (the dovetail's overhang is 20 degrees) |
| `stock-splice.stl` | 2 | 40 × 6 × 2 mm: glued into the recesses behind the stators, across the joint |
| `slide-left.stl`, `slide-right.stl` | 1 each | the slide in two halves, 145 × 20.6 × 4.3 mm, 0.2 mm clearance in the channel; printed on its wide back |
| `slide-splice.stl` | 1 | 40 × 10 × 1.4 mm: in the recess behind the slide, across its joint |
| `cursor.stl` | 1 | the cursor's frame, 30 × 51 mm: printed face down |
| `foot.stl` | 2 | the feet the rule lies on, tilted 25 degrees toward you; a peg in each fits a hole in the stock's back |
| `slate-left.stl`, `slate-right.stl`, `slate-frame-left.stl`, `slate-frame-right.stl` | 1 each | the slate (34 × 12 cm) and its frame, in halves; paint the face with blackboard paint |

Buy: a piece of 2 mm clear acrylic, 25.8 × 46.2 mm, for the cursor's
window. Scribe the hairline across its middle with a sharp point against a
square and rub red paint into it (here it is drawn 0.3 mm wide, to be
seen; finer is better).

**The scales.** `scales.pdf` has the three faces' scales at full size on
one A4 page (`make-scales.py` draws them, for the PDF and for the
simulation alike). Print it at 100%, no "fit to page", and check the bar is
100 mm. Cut the strips on their grey lines and glue each on its face,
lining its index marks up with the others' (the slide's strip on the
slide, the others on the stock); a thin spray adhesive keeps the paper
flat. Many old rules were faced with printed card or celluloid the same way.

**Assembly.** Glue the stock's halves end to end on a flat surface, with
the splices in their recesses behind; the same for the slide. Sand the
channel and the slide's sides smooth, and wax them: the slide should move
with a firm push (about half a newton) and stay where it is left. Slide
the cursor on from one end (its tongues in the edge grooves), glue the
window into its recess, and slide the slide into the channel. Stand the
rule on the feet, their pegs in the holes behind the lower stator.

## Files

| File | |
|---|---|
| `slide-rule.lua` | the exhibit |
| `rule.lua` | the scales, and how each problem is worked: the moves, the reading, the decimal point |
| `rule-test.lua` | the plans against plain arithmetic, with the parts exactly placed and off by up to 0.2 mm (`lua rule-test.lua`) |
| `parts/slide-rule.scad` | every part's shape |
| `make-scales.py`, `scales/`, `scales.pdf` | the scales: textures for the simulation, and the sheet to print (`--svg` also keeps it as SVG) |
| `make-slate.py`, `slate/` | the slate's pictures, and the steps' words |
| `make-stls.sh` | the STL files (not kept in the repository) |
| `FINDINGS.md` | what was measured |
