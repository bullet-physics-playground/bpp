# The Slide Adder

*Babbage's Hall, west bay 4: adding with a stylus and a hook.*

**`MANUAL.pdf`** is the manual: how to add, carry, subtract and borrow on
a slide adder, step by step, with pictures, and the exhibit's keys (`H`
opens it, here or in the hall). This README is the builder's reference.

The seventh machine on the walk, after the Domino Half Adder. A pocket
adding machine with no gears at all: six bands slide up and down behind a
cover, and a stylus moves them. Heinrich Kummer put the carry into a hook
in the 1840s; Louis Troncet's arithmographe (1889) made the design
popular, and the Addiator (1920 to 1982) put it in millions of pockets.
This one is the same machine, printed larger (8 mm a step), and standing
upright.

Each **band** has a row of pegs along its left edge, 8 mm apart, and the
digits 0 to 9 on its face; the column's **window** shows one of them. The
**cover** has a slot over each row of pegs, joined at the top and at the
bottom by channels: the hooks. Beside each slot are the digits to add, on
the right, going up from 1 to 9, and the digits to subtract, on the left,
in red, going down. The band's face behind its pegs is red from its tenth
gap on, so the gaps seen through the slot are red where the band is too
far down for the digit beside them.

The operator's hand moves the stylus, and a slate beside the adder shows
what the windows read, the number being added or subtracted, and what the
hand is doing.

## Two ways

In the hall, Tab steps through them (each has its own label on the
lectern); on its own, `SA_WAY` chooses.

**Adding** (the default). Type a number and press Return. For each digit
d, from the units leftward:

1. The stylus between the pegs beside the d on the slot's right.
2. If the gap is not red: down to the bottom of the slot. The band goes
   down d steps, and the window shows d more.
3. If the gap is red (the window already shows 10 − d or more): up to the
   top instead. The band goes up 10 − d steps, which shows d more, less
   ten. Then along the top channel into the next slot to the left, and one
   step down: that column shows one more. That is the carry.
4. If that column shows 9, the stylus won't go down (its band is at the
   bottom). Take the stylus out, put it beside that column's 1, push up to
   the top (9 becomes 0), and carry again into the column after.

**Subtracting** (`SA_WAY=subtract`). Return subtracts the number typed; `+`
adds one (to put the first number on). For each digit d: the stylus beside
the red d on the slot's left. If the gap is red, up to the top: the band
goes up d steps, d fewer. If not, down to the bottom instead (d fewer,
plus ten), along the bottom channel into the next slot, and one step up:
the borrow. A column at 0 won't go up: beside its red 1, down to the
bottom (0 becomes 9), and borrow again. A borrow past the last column has
nowhere to go: the answer is less than nothing, and the windows show a
million less it (853 − 4729 shows 996124: −3876).

    bpp -f slide-adder.lua                  (or walk to it in the hall)
    SA_WAY=subtract bpp -f slide-adder.lua

| Key | |
|---|---|
| `0`–`9` | a number, up to six figures (the slate shows it) |
| `Return` | add it (subtract it, in the second way) |
| `+`, `-` | add it; subtract it |
| `Backspace` | a figure off |
| `C` | the zeroing bar: every band to 0 |
| `R` | a number at random, added (subtracted) |
| `T` | the tour. Adding: 47295 + 85358 (three carries), 99999 + 1 (a carry through five nines), 1889 + 2026. Subtracting: 132653 − 85358, 100000 − 1 (a borrow through five noughts), 853 − 4729 (less than nothing). Each from 0 |
| `H` | the manual, `MANUAL.pdf`, opened in your PDF viewer |

The sliders: the hand's speed, a band's friction in its groove, and the
simulation's speed. Resting the mouse on a band says what it reads and how
far down it is.

## What is simulated, and what is the script's

The **bands** are bodies, each on a slider constraint (its groove between
two ribs), held where they are left by friction: a motor on the slider at
no speed and a limited force, 20 kg cm/s² (0.2 N). The adder stands
upright, so that friction must be more than a band's weight, 11.8: less,
and the bands slide to the bottom (`FINDINGS.md`). Each band's shape is
its 21 pegs (cylinders) and its body.

The **cover's** slots and channels are a fixed body (boxes round them).
The **stylus** is a body: a ball 3 mm across that goes between two pegs,
and a ball in the cover's slot above it. The operator's hand moves it with
a force toward where it means the stylus to be (stiff, like a hand, but
no more than 2 N), so the stylus goes where the slot and the pegs let it,
and stops where they don't. A band moves only because the stylus pushes
one of its pegs, and a carry gets into the next column only along the top
channel.

The **zeroing bar** is a body on a slider under the bands' feet; its tab
lifts it until every band is at its top (0), and it goes down again.

The **operator** is the script: it reads each window (and so knows
whether the gap beside a digit is red), chooses the moves a person would
make, and feels when the stylus will go no further: a 9 that won't take a
carry, a 0 that won't lend, the end of the channel past the last column.
It pushes a little past a slot's end (1 mm) so the band goes home, and a
little past a step when it carries (0.6 mm, the stylus's play between the
pegs), as a hand does. Every result is read from where the bands are.

The slate, the labels and the digits printed on the bands are drawn (the
labels are printed on paper for the real one: below). A band's digits
show through the bottom channel as well as through its window, since the
channel runs across every band below its pegs; the windows are the
reading.

## The parts

All printed. `./make-stls.sh` makes the STLs, each turned to lie on the
printer's bed (OpenSCAD); all are under 200 mm.

| Part | Print | Notes |
|---|---|---|
| `band.stl` | 6 | 22 × 189 × 6 mm: a 2.5 mm strip with 21 pegs (4 mm across, 3.5 mm high, 8 mm apart) along its left edge; printed on its back, pegs up |
| `cover-lower.stl`, `cover-upper.stl` | 1 each | the cover, 165 × 285 × 3 mm in two parts (cut 10 mm below the slots): the slots 4 mm wide, the channels joining them, the windows (9 × 7 mm), and the bar's tab's slot; printed face down |
| `island.stl` | 5 | the cover between two slots, 20 × 76 × 3 mm: the channels at the top and the bottom cut it off on every side, so it is a part of its own, glued onto the two studs on the rib behind it |
| `back-lower.stl`, `back-upper.stl` | 1 each | the back, 165 × 285 mm, cut where the cover is: the plate, the sides and ends that hold the cover 7 mm off it, a rib between each band and the next (from just above the bands' feet up; below, the zeroing bar runs free), and the studs for the islands |
| `bar.stl` | 1 | the zeroing bar, 148 mm, with its tab and knob |
| `stylus.stl` | 1 | 65 mm, a 3 mm ball at its tip; printed standing |
| `foot-left.stl`, `foot-right.stl` | 1 each | the case stands in a notch in each |

Buy: nothing.

**The labels.** `slate/labels-add.png` (the digits to add) and
`slate/labels-sub.png` (to subtract, in red) go beside every slot,
`slate/band-digits.png` on every band (0 at the bottom, in line with the
window), `slate/cover-top.png` over the slots and `slate/window-1.png` to
`window-6.png` under the windows. They are 10 pixels a millimetre: print
them at that size (a 50 px strip is 5 mm wide), cut them out, and glue
them on. The red behind each band's gaps from the tenth on is paint, or a
strip of red tape, 5 mm wide, from 76 mm above the band's gap 0 to its top.

**Assembly.** Glue the back's halves and the cover's halves edge to edge
on a flat surface. Lay the back on its back, drop the bands into their
grooves (pegs up, toward you, at each groove's left), and lay the bar
under their feet, its tab at the right. Glue the five islands on their
studs, flush with the cover, and the cover onto the sides and ends, its
slots over the pegs. A band should slide with a firm push and stay where
it is left, standing upright: about 0.2 N (more than its own weight, 12 g;
a little wax, or a strip of felt in the groove). Stand the case in its
feet.

## Files

| File | |
|---|---|
| `MANUAL.md`, `manual/` | the manual and its figures (`python3 manual/make-figures.py` redraws them, but for `fig-exhibit.png`, a screenshot) |
| `slide-adder.lua` | the exhibit, both ways |
| `parts/slide-adder.scad` | every part's shape, and the sizes the exhibit uses |
| `make-slate.py`, `slate/` | the slate's pictures, and the adder's printed labels |
| `make-stls.sh` | the STL files (not kept in the repository) |
| `FINDINGS.md` | what was measured |
