# The Brazil-Nut Effect

Shake a jar of mixed nuts and the Brazil nuts come up to the top: the
biggest rise, though they're the heaviest. Here, three glass-fronted boxes
of beads, a layer one bead thick, are shaken up and down seven times a
second on a shaker table:

| Box | What happens |
|---|---|
| left | a big bead at the bottom, shaken gently (peak acceleration 0.8 g): the beads never leave the floor, and nothing happens |
| middle | the same, shaken hard (3 g): the big bead comes up (within seconds with this pour; it can take twenty) and stays up, three quarters of the time in the bed's upper half |
| right | no big bead, but a coloured small one at the bottom in the middle, shaken the same: it comes up too, then goes down again beside a wall, and round and round |

Every 90 s they're poured again.

## Keys

| Key | Action |
|---|---|
| `R` | pour them again (the big bead at the bottom) |
| `Z` | slow motion (1/4) <-> real time |

Sliders: hard, gentle (the peak acceleration, in g), speed, steps. Rest
the mouse on the big bead or the coloured one to see how high it is.

## Why

Shaken hard, the bed leaves the floor for part of each shake and lands
again. Rubbing on the walls holds back the beads beside them, so beads go
down along the walls and come up in the middle: the bed turns over slowly,
in two rolls. Anything in the middle comes up with it. At the top, the
small beads go down again in the narrow layer along the walls, but the big
one is too big to follow them, so it stays up. (J. B. Knight, H. M. Jaeger
and S. R. Nagel, *Phys. Rev. Lett.* 70, 3728 (1993): the big bead rises
with the convection.)

## The theory, and what the console says

    Left   Gamma 0.8: the bed never left the floor (the floor's push never less than 0.18 of its weight; a rigid bed's: 0.20)
    Middle Gamma 3.0: the bed leaves the floor 46 to 48 degrees into the upswing (a rigid bed: arcsin 1/Gamma = 19.5;
           this one presses on longer: Bullet's contacts give a little, and the stiffer they are, the sooner it leaves)
    Middle the big bead reaches the top at 6.3 s (44 shakes), having risen 8.4 cm
    Right  the coloured bead reaches the top at 11.6 s (81 shakes), having risen 8.9 cm
    Middle from 5 s to a minute: beads in the middle rising 5.5 mm/s on average, beside the walls falling 10.1 mm/s
    Middle the big bead, since reaching the top, has been in the bed's upper half 77% of the time
    Right  from 5 s to a minute: beads in the middle rising 7.8 mm/s on average, beside the walls falling 12.9 mm/s
    Right  the coloured bead has gone round 4 times: going up it was 3.6 cm from the middle on average, going down 4.6 cm (the walls are 7.5 cm out)

* **Leaving the floor.** The box's floor accelerates downward at up to
  Gamma g, with Gamma = A w^2 / g. Below Gamma = 1 the floor never drops
  away faster than the beads fall, so the bed rides on it, and the floor's
  push never drops below (1 - Gamma) of the bed's weight: 0.18 here,
  against 0.20 for a rigid bed. Above Gamma = 1, a rigid bed would leave
  the floor once the floor's downward acceleration passes g, at a phase of
  arcsin(1 / Gamma) into the upswing. This bed presses on until about 47
  degrees, against 19.5 for a rigid one. The push is measured from how much
  each (heavy) box is slowed by the beads, averaged by phase over shakes 5
  to 12.
* **Why so late?** Not, mostly, because a bed of beads is springy: because
  Bullet's contacts are. Its contacts let the beads sink into each other a
  little and push them apart again over the next steps, and the softer
  they are, the longer the bed keeps pressing. Made stiffer, the bed leaves
  sooner (the middle box, then the right; one pour, BN_SEED 7):

      2400 steps a second, 20 solver iterations (as shown):  46-48, 50-52 degrees
      4800 steps a second, 20 iterations:                    36-38, 32-34
      2400 steps a second, 100 iterations:                   36-38, 38-40
      9600 steps a second, 60 iterations:                    28-30, 36-38

  It hasn't settled even at the stiffest, which is too slow to show here;
  so the 47 degrees is mostly the simulation's, not the beads'. No bounce
  (0 instead of 0.1) gives 42-44 and 40-42; less friction (0.3) 40-42 and
  54-56. How much later than 19.5 degrees a real bed of glass beads leaves
  is not tested here.
* **The convection.** Over a minute, beads in the middle of the box rise
  and those beside the walls fall: the two rolls.
* **The big bead** stays up. The coloured one, as small as the rest, goes
  round with them: up nearer the middle, down nearer the walls.
* **How soon** the big bead comes up depends a lot on how the beads were
  poured: 6.3 s (44 shakes) with the pour shown (`BN_SEED` 7), 21.4 s (149
  shakes) with `BN_SEED=8`. With stiffer contacts (4800 steps a second) it
  still comes up, at 11.9 s, and the coloured bead at 19.3 s.

## The beads and boxes

The beads are glass, 0.95 to 1.05 cm across, 140 to a box. (All the same
size, in a flat layer they'd stack like a honeycomb and lock.) The big one
is 3 cm across. The boxes are 15 cm wide inside. They're shaken at 7 Hz:
4.1 mm for 0.8 g, 15.2 mm for 3 g.

## Physics

* Bullet. The beads are spheres held to the plane of the box (a layer one
  bead thick, between glass), with friction 0.8 (the walls 1.0) and little
  bounce (0.1).
* Each box is a heavy body moved exactly as the shaker moves it, and given
  the shaker's speed, before every step.
* 2400 physics steps a second.
* How a shaken bed behaves depends on the friction, the bounce, the
  shaking and the beads' sizes. These settings (7 Hz, 3 g, high friction)
  were found by trying. At 10 Hz and 2.5 g with less friction, the big bead
  rose only now and then.

## Files

* `brazil-nut.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`).

Headless testing: `BN_SPEED`, `BN_STEPS`, `BN_SEED`, `BN_HARD`,
`BN_GENTLE` (g), `BN_F` (Hz), `BN_POLY` (the beads' spread in size),
`BN_MUB`, `BN_MUW` (friction), `BN_E` (bounce), `BN_LOG=file.csv`.
