# The Domino Half Adder: what the simulation showed

`FINDINGS.pdf` beside this file is a typeset copy of it.

Every junction was tested on its own before the machine used it, with
`tests/junctions.lua` (run from `tests/`; its header lists the settings).
Dominoes are 48 x 24 x 7.5 mm, 8 g, friction 0.4, no bounce, at 2400 steps a
second, unless a line says otherwise.

## Lines

- **Spacing.** A straight line of 30 fell completely at every spacing from 1.6
  to 4.6 cm. The wave runs at 113 cm/s at 1.6 cm, 99 at 2.8 and 63 at 4.6.
  The machine uses 2.6 cm.
- **Turns** of radius 5, 8 and 12 cm through 90 degrees: all fell.
- **Pushing the first domino:** setting a spin about its centre does nothing;
  most of it is lost against the table at once. It has to be turned about its
  front foot (spin plus the matching forward speed), as a finger pushes it.

## Junctions

- **Fork:** the trunk's last domino strikes the two branches' first dominoes,
  1.0 or 1.4 cm either side of its line, at 20 or 30 degrees. All four
  settings worked.
- **Merge:** two feeders at 15 to 35 degrees, ending 0.3 to 0.7 cm either side
  of the outgoing line, each set off it alone. All worked; 0.5 cm and 30
  degrees are used.
  - At 1.4 cm a single feeder only twisted the outgoing domino, so the merge
    acted as an AND.
  - A feeder's last domino must stand exactly where it should. Spacing a
    feeder to fit its length, instead of stopping it up to a spacing short,
    fixed a wave that died at the first domino it struck.
- **Tap** (a branch leaving a line that carries on, 1.4 cm aside, at 25
  degrees):
  - **with the wave:** taken.
  - **against the wave:** not taken. Only the branch's first domino falls
    (20 and 30 degrees both).

  This is what makes the XOR.
- **Head-on:** two waves on one line, from both ends: they meet and stop.
- **Back-running:** a wave reaching the far end of the collision line also runs
  back up the other input's feeder. It is harmless: it passes the carry's tap
  the wrong way (not taken) and stops at that input's switch gap.

## The cut (inhibitor)

A line arriving square to another, its last domino 3.6 cm from that line's
centre, knocks dominoes out of it sideways. The gap stops the other line's
wave if the cut comes first.

- **Distance:** at 3.2, 3.6 and 4.0 cm the cut worked; at 2.4 cm the main
  line ran on.
- **Head start:** the inhibitor needs about 4 frames (70 ms). 1 frame was not
  enough; 4 to 12 always worked at 3.6 and 4.0 cm.
- **Aim:** aimed between two dominoes, it can slip through the gap between them
  without touching either; there is only 0.27 cm to spare. So the carry line is
  spaced wide where it is cut: three dominoes 4.25 cm apart, the inhibitor
  aimed at the middle one. One domino out leaves 8.5 cm, which no wave jumps.
  - At 3.8 cm the wave still got across at friction 0.3: a domino slid over
    the fallen one.
  - At 4.5 cm the wave didn't cross even uncut at friction 0.3.
  - 4.1 to 4.4 cm worked at both 0.3 and 0.5.

## Switches

A single missing domino is not a gap: the next one is 4.45 cm away, within
reach of a 4.8 cm domino. Two missing leave 7.8 cm, which stops a wave. The
two dominoes taken out must be laid well aside, across the line. Laid 7 cm
along it, they bridged the gap.

## The template

The template's pocket walls (1.6 mm high, 1.2 mm wide, 0.4 mm clearance) are
in the simulation as fixed boxes.

At first a wall of one pocket stood inside a neighbour's pocket at the
crowded junctions. That domino was pushed over at the start: SUM fell with
both inputs 0. The walls are now cut where they would stand in another pocket,
as on the print (frames minus pockets). That leaves 1076 wall boxes round 268
dominoes.

## The whole machine

**Before the tell-tales were added** (the half adder alone, and the full
machine started from GO through its switches):
- **Half adder:** all three non-zero sums right at friction 0.3, 0.35, 0.4,
  0.45 and 0.5. At each friction, four placings with every domino misplaced
  at random (1 mm, 2 degrees): 20 of 20 right.
- **Full machine, from GO through the switches, with the template:** all four
  sums right at friction 0.3, 0.4 and 0.5. At each friction, three placings
  with every domino misplaced within its pocket (0.3 mm, 1.5 degrees): 9 of 9
  right.

**The finished exhibit** (`domino-adder.lua`'s own tour of all four sums,
with the tell-tales and the switches laid aside), at friction 0.3, 0.4 and
0.5, three placings each with every domino misplaced within its pocket
(`DA_JIT=0.03`): 9 tours of 9, 36 sums of 36, right.

Two faults were found on the way:
- **Switches:** the removed dominoes were first laid 7 to 10 cm along the
  line instead of across it, and bridged the gap; the waves ran on with both
  inputs 0.
- **Paths:** the parts file was looked for by `$PWD`, which is wrong when bpp
  has moved into the script's folder; the real working directory is used now.

## Resting

Once the hand has nothing to do and nothing has moved for half a second,
the Domino Half Adder stops stepping until there is something to do again. Stepped at
2400 steps a second, a machine at rest costs as much as one running, and
its parts never quite stop (their sleeping is turned off, as it must be
while they work): what was left once it had settled was up to about 0.15 cm/s and 0.07 rad/s (fallen dominoes rocking against each other).
"Not moving" is set just above that: 0.3 cm/s and 0.1 rad/s. Resting can't change a
result: woken, it carries on from exactly the state it stopped in,
speeds and all. It rests only between runs, so the runs themselves are as before. Over a 50 s run, 165 s of computing became 88 s.
