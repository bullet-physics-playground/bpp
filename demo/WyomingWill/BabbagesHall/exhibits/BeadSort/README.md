# The Bead Sort

*Babbage's Hall, west bay 3: sorting by gravity, and by height.*

**`MANUAL.pdf`** is the manual: how the bead sort works and why it sorts,
with pictures, what it can't do, and the exhibit's keys (`H` opens it,
here or in the hall); its section 8 is the spaghetti sort. This README is
the builder's reference.

The exhibit has **two ways** (`BS_WAY`; in the hall, `Tab` steps from one
to the other): the bead sort, below, and **the spaghetti sort**, rods cut
to the numbers' lengths and stood on end (see "The second way", further
down).

Nine steel rods in a frame. A number from 0 to 9 is a **row of beads**,
laid from the left: 3 is a bead on each of rods 1, 2 and 3. Up to eight
numbers, one row each, the first at the bottom. Laid flat, the beads stay
where they are put. Then the operator's hand turns the frame upright on its
hinge, and every bead slides down its rod until it rests on the bead
below. Rod k then holds as many beads as there are numbers of k or more,
all at the bottom; so the bottom row reaches as far as the largest number,
the next row as far as the next largest, and the rows, read from the
bottom, are the numbers **sorted**.

Each bead keeps the colour of the number it was laid in. After the sort the
rows are mixed colours: the beads moved, not the numbers. A bead sort sorts
values only.

Joshua Arulanandham, Cristian Calude and Michael Dinneen described it in
2002 ("Bead-Sort: a natural sorting algorithm", *Bulletin of the EATCS*
76), as an algorithm found in nature.

```
build/release/bpp -f demo/WyomingWill/BabbagesHall/exhibits/BeadSort/bead-sort.lua
```

The slate behind the frame shows the numbers as laid, the rows as they are
now (counted from the beads as they fall), and what the hand is doing; the
digits beside the frame's rows count each row's beads too. When the beads
have settled the hand reads the rows: green, sorted.

| Key | |
|---|---|
| `0`–`9` | a number, laid as the next row (up to eight; the slate shows them) |
| `Return` | sort them: the beads are threaded on, the frame turned upright, the rows read |
| `Backspace` | the last number off |
| `R` | eight numbers at random, sorted |
| `C` | lay the frame down and take the beads off |
| `T` | the tour: 3 7 1 9 4 2 6 5; 5 0 5 2 8 2 (a nought, and numbers twice); 1 2 3 4 5 6 7 8 (every bead above the bottom row falls) |
| `H` | the manual, `MANUAL.pdf`, opened in your PDF viewer |

Sliders: **hand**, how fast the frame is turned upright (degrees a
second); **friction**, a bead on its rod (the force that holds it,
kg cm/s²; the bead weighs 4.4); **speed**.

Rest the mouse on a bead and it says which number it was laid in, and
which row it is in now.

## What is simulated, and what is the script's

Each bead is a body on a slider along its rod, tied to the frame (a motor
on the slider at no speed and a small force is the rod's friction, so a
bead laid flat stays where it is put). The frame is a body on a hinge; the
operator's hand turns it, by a motor on the hinge, from flat to upright,
and the hinge's limits are the rest it lies on and the stop it leans on.
The beads fall under gravity, as far as their rods and the beads below
them let them. The rows are read from where the beads are.

The script threads the beads on as each number is laid (they appear on
their row) and takes them off at the end: the rods are fixed in the frame,
and a bead waiting on a rod would fall too. The hand, the slate, the digits
by the rows and the reading of the rows are the script's. `FINDINGS.md`
has the measurements.

## The parts

Every part is printed but the rods and the hinge's pin. `./make-stls.sh`
makes them, each turned to lie on the printer's bed (OpenSCAD); all are
under 200 mm.

| Part | Print | Notes |
|---|---|---|
| `bead.stl` | 72 | 20 mm across, 12 mm along the rod, chamfered, a 3.6 mm hole (loose: they must slide down under their own weight); eight colours, nine of each |
| `bar-bottom-left.stl`, `bar-bottom-right.stl` | 1 each | the bottom bar in halves, 129 × 12 × 22 mm, each with a hinge knuckle; blind holes for the rods |
| `bar-top-left.stl`, `bar-top-right.stl` | 1 each | the top bar in halves |
| `bar-side.stl` | 2 | 100 × 12 × 22 mm |
| `foot-left.stl`, `foot-right.stl` | 1 each | the foot in halves: a plate with the two inner knuckles and the stop the frame leans on upright |
| `rest.stl` | 1 | under the top bar, for the frame to lie on flat |
| `knob.stl` | 1 | on the top bar, to lift it by |

Buy: nine 3 mm steel rods, 116 mm long (silver steel or stainless), and a
3 mm steel pin, 264 mm long, for the hinge.

**Assembly.** Glue each end bar's halves together. Push the rods' ends
into the bottom bar's holes, the top bar onto them, and glue the side bars
between the ends: the frame is 258 × 124 mm. Glue the foot's halves, set
the frame's knuckles outside the foot's and push the pin through all four.
Glue the knob to the top bar's middle and set the rest where the top bar
lies when the frame is flat. A bead must fall freely along a rod held
upright and stay where it is put on a rod lying flat: if the beads stick,
open their holes to 3.8 mm. The slate is the exhibit's own (any small
blackboard will do).

## The second way: the spaghetti sort

```
BS_WAY=spaghetti build/release/bpp -f demo/WyomingWill/BabbagesHall/exhibits/BeadSort/bead-sort.lua
```

(`bead-sort.lua` hands over to `spaghetti-sort.lua`, which also runs on
its own.) A. K. Dewdney's spaghetti sort (*Scientific American*, June
1984): cut a strand to each number's length, stand the bundle on the table
so their feet are level, and lower a flat hand onto them; the first strand
it touches is the longest. Take it out, lower on, and so on.

Here each number n is a printed rod 8 mm across and 30 + 12 n mm long (the
30 mm so that 0 has a rod). The hand drops each into a slot of the
**rack**: a base the rods stand on (the table that levels their feet), a
notch on the base for each foot, and a comb whose slots, open toward you,
hold them upright. The **palm** is a flat board on a post, lowered by the
operator's hand by its knob. The first rod it touches is the tallest: the
hand draws it out toward you and lays it in a row in front, and the palm
goes on down. The rods come out in order, each in its own colour: where
the bead sort moves beads and keeps only the values, the spaghetti sort
moves the numbers whole.

The slate shows the numbers as cut, the numbers as taken, and what the
hands are doing (green when sorted); a digit on the base under each slot,
and at the end of each rod laid down, gives its number. The keys are the
bead sort's (`0`–`9`, `Return`, `Backspace`, `R`, `C`, `T`, `H`); the
sliders are **palm**, how fast it comes down (cm a second), **friction**
(a rod on the rack and the palm) and **speed**.

**Simulated:** each rod is a body (a cylinder), dropped 6 mm into its slot;
it stands on the base, its foot in its notch and its upper part in the
comb's slot, upright (the clearances, 0.3 and 0.5 mm, let it lean at most
2.3 degrees, under the 3.3 degrees a 138 mm rod on an 8 mm foot can lean
and still stand up again). The palm is a body on a slider up the post,
lowered by the slider's motor; which rod it touched is read from the
contacts between the palm and the rods, after every step. **The
script's:** cutting the rods and dropping them in, drawing out the rod
touched and laying it down (it leaves the simulation there and is
carried), the slate and the digits. `FINDINGS.md`, "The spaghetti sort",
has the measurements.

| Part | Print | Notes |
|---|---|---|
| `rod-0.stl` … `rod-9.stl` | as needed | 8 mm across, 30 + 12 n mm long, chamfered, the number engraved on the foot; two of each is a set for most lists (eight 9s need eight `rod-9`). Or cut 8 mm dowel to length, as Dewdney cut spaghetti |
| `base-left.stl`, `base-right.stl` | 1 each | the base, 272 × 60 × 6 mm, in halves (120 and 152 mm), with the feet's strip: 3 mm high, a notch 8.6 mm wide for each foot, open at the back |
| `comb-left.stl`, `comb-right.stl` | 1 each | the comb, 224 × 28 × 6 mm on 14 mm cheeks, in halves cut through a tooth; slots 9 mm wide, open toward you |
| `post.stl` | 1 | 12 × 12 × 190 mm |
| `palm-left.stl`, `palm-right.stl` | 1 each | the palm, a 250 × 40 × 6 mm board in halves; the right half carries the arm and the sleeve that slides on the post (0.4 mm clear) |
| `palm-knob.stl` | 1 | glued on the palm near its right end, for the hand |

Nothing is bought. **Assembly.** Glue the base's halves; glue the comb's
halves and stand it on its cheeks on the base, its slots over the notches
(the slots' back 0.5 mm behind a rod's back when its foot is against its
notch's front); glue the post upright at the base's right end. Glue the
palm's halves and the knob, and slide the sleeve down the post. A rod must
drop into its slot and stand upright by itself, and come out toward you
with a lift of 3 mm over the notch's front. Lower the palm slowly and
level: `FINDINGS.md` has how level.

## Files

| File | |
|---|---|
| `bead-sort.lua` | the exhibit (`BS_WAY=spaghetti` hands over to the next) |
| `spaghetti-sort.lua` | the spaghetti sort, its second way |
| `parts/spaghetti-sort.scad` | the spaghetti sort's parts (the slate and the hands are `bead-sort.scad`'s) |
| `parts/bead-sort.scad` | every part (the single source of the geometry), and what the exhibit draws |
| `make-stls.sh` | the printed parts, into `stl/` |
| `make-slate.py`, `slate/` | the slate's pictures: digits, labels, and what the hand is doing (`say-sp-*`, `label-cut`, `label-taken`: the spaghetti sort's) |
| `manual/make-figures.py`, `manual/make-figures-spaghetti.py` | the manual's figures, drawn with the exhibit's sizes and colours |
| `MANUAL.md` | the manual |
| `FINDINGS.md` | what was measured |
