# The Bead Sort: a manual

`MANUAL.pdf` beside this file is a typeset copy of it. In Babbage's Hall,
press `H` at the bead sort to open it.

How the bead sort works and why it sorts, what it can and can't sort, and
how long it takes. Then the exhibit in the hall, and making one.

The pictures are drawn by `manual/make-figures.py` with the exhibit's
sizes and colours, and sorted by the machine's own rule: on each rod the
beads fall to the bottom, none passing another.

**The whole idea in one paragraph.** Write each number as a row of beads
from the left, one row under another, on vertical rods. Let go. Each bead
falls until it lands on the bead below it. On each rod the beads simply
pile up at the bottom, so rod 4 ends up holding one bead for every number
that was 4 or more. Read the rows from the bottom up: the first reaches as
far as the largest number, the next as far as the next largest. The
numbers are sorted, and nobody compared any two of them.

## 1. Laying the numbers

The frame has nine rods, numbered 1 to 9 from the left, and room for eight
rows of beads. A number from 0 to 9 is laid as a row: a bead on each of
rods 1 to n. So 3 is three beads, on rods 1, 2 and 3; 9 fills the row;
0 is an empty row. The first number goes in the bottom row (nearest the
hinge), the next above it, and so on.

![The tour's first list, 3 7 1 9 4 2 6 5, laid flat. Each number's beads have their own colour, and the digit beside each row counts its beads.](manual/fig-laid.png)

The frame lies flat while the numbers are laid, so the beads stay where
they are put: nothing pulls them along the rods.

## 2. Turning it upright

Now turn the frame upright on its hinge. Gravity pulls every bead down its
rod, and it slides until it rests on the bead below it, or on the bottom
bar. A bead can't pass the one below it, but where a row below has no bead
on that rod, the bead falls through the gap.

![The same beads with the frame upright: the rows, from the bottom, are 9 7 6 5 4 3 2 1.](manual/fig-sorted.png)

Read the rows from the bottom: 9, 7, 6, 5, 4, 3, 2, 1. The numbers,
largest first.

Look at the colours. The bottom row holds a red bead, an orange one, a
green one and more: beads from several numbers. **The beads moved; the
numbers didn't.** No row is "the 9" that was laid: the bottom row is nine
beads long because nine rods each kept a bead at the bottom. A bead sort
sorts values. If each number had a name with it (sort these people by
age), the names would be lost.

## 3. Why it sorts

Look at one rod at a time. Rod k gets a bead from every row whose number
is k or more, and keeps them all, piled at the bottom. So the number of
beads on rod k is the number of numbers that are at least k.

![Rod k keeps a bead for every number of k or more: rod 1 has eight (all eight numbers are 1 or more), rod 9 one (only the 9).](manual/fig-counts.png)

Now read row r. It has a bead on rod k exactly when rod k holds at least r
beads, that is, when at least r of the numbers are k or more. Going along
the row from the left, that stays true until k passes the r-th largest
number. So row r reaches exactly as far as the r-th largest number: the
bottom row the largest, the second row the second largest. That is the
whole proof. Every rod counts for itself, at the same time.

This is close to a sort computers use, the counting sort, which counts how
many numbers are at least each value; here each rod does its own counting,
by gravity.

## 4. What it can't do, and what it costs

- **Only whole numbers, not less than 0,** each as many beads as its value:
  this frame takes 0 to 9, and at most eight of them.
- **It sorts values, not records.** As above: the beads mix.
- **It needs a bead for every unit of every number:** eight numbers up to
  9 need up to 72 beads. A thousand numbers up to a million would need a
  billion.
- **It is fast.** All the beads fall at once. However many numbers there
  are, the time is how long a bead takes to fall the frame's height: here,
  about a seventh of a second (10 cm), though the frame takes three
  seconds to turn. A
  computer imitating it must move each bead itself, and is slow.

Joshua Arulanandham, Cristian Calude and Michael Dinneen, at the
University of Auckland, described the bead sort in 2002 ("Bead-Sort: a
natural sorting algorithm", *Bulletin of the EATCS* 76), as an algorithm
found in nature: "gravity sort".

## 5. Mistakes to avoid

- **Don't leave a gap in a row.** A number's beads go on rods 1 to n with
  none missing; 3 as beads on rods 1, 2 and 5 is not 3, and the sort will
  give nonsense.
- **Turn it the right way up.** The rows are read from the bottom, where
  the beads land. Upside down, the beads fall the other way and the
  largest number ends at the top.
- **Sticky beads.** A bead must slide freely on its rod. If one sticks
  where it was laid, the rows below it are short a bead and above it have
  one too many. The exhibit counts every row and says so if they aren't
  sorted.

## 6. The bead sort in the hall

![The exhibit (a screenshot of the simulation), the frame upright after sorting 1 2 3 4 5 6 7 8: the slate shows the numbers as laid, 1 2 3 4 5 6 7 8, and the rows now, 8 7 6 5 4 3 2 1.](manual/fig-exhibit.png)

The bead sort stands in the west bay 3. Type up to eight digits and press
Return: the hand threads each number's beads onto its row (the frame
flat), lifts the frame by its knob and turns it upright, waits for the
beads to settle, and reads the rows. The slate shows the numbers as laid,
the rows as they are now, counted from the beads as they fall, and what
the hand is doing; green when the rows are the numbers sorted.

| Key | |
|---|---|
| `0`–`9` | a number, laid as the next row (up to eight) |
| `Return` | sort them |
| `Backspace` | the last number off |
| `R` | eight numbers at random, sorted |
| `C` | lay the frame down and take the beads off |
| `T` | the tour: 3 7 1 9 4 2 6 5; 5 0 5 2 8 2; 1 2 3 4 5 6 7 8 |
| `H` or `F1` | this manual |
| `I` | in the hall: the lectern's label close up, and `PgDn` turns its pages |

The beads are bodies on their rods, and they fall by physics; the rows are
read from where they end up. Threading the beads on and taking them off,
turning the frame, the slate and the counting are the script's. Resting
the mouse on a bead says which number it was laid in and which row it is
in now. The sliders set how fast the hand turns the frame, the beads'
friction on their rods (too much, and they don't fall: see `FINDINGS.md`),
and the simulation's speed.

On its own, outside the hall: `bpp -f bead-sort.lua`.

## 7. Making one

Every part is printed but the rods and the hinge's pin; `./make-stls.sh`
makes the STL files from `parts/bead-sort.scad`, each turned to lie on the
bed, and all fit a 200 mm printer.

| Part | Print | |
|---|---|---|
| `bead.stl` | 72 | eight colours, nine of each; a loose 3.6 mm hole |
| `bar-bottom-*.stl`, `bar-top-*.stl` | 1 each | the end bars, in halves; the bottom bar has the hinge's knuckles |
| `bar-side.stl` | 2 | |
| `foot-*.stl` | 1 each | the foot in halves, with the stop |
| `rest.stl`, `knob.stl` | 1 each | |

Buy nine 3 mm steel rods, 116 mm long, and a 3 mm steel pin, 264 mm long.

1. Glue each end bar's halves. Push the rods into the bottom bar, the top
   bar onto them, and glue the side bars between.
2. Glue the foot's halves; put the frame's knuckles outside the foot's and
   push the pin through.
3. Glue on the knob, and set the rest under the top bar.
4. A bead must fall freely on a rod held upright: open the holes to 3.8 mm
   if they stick.

`README.md` has the details, and `FINDINGS.md` what was measured in the
simulation.
