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

    Left   Gamma 0.8: the bed never left the floor (the floor's push never less than 0.19 of its weight; a rigid bed's: 0.20)
    Middle Gamma 3.0: the bed leaves the floor 48 to 50 degrees into the upswing (a rigid bed: arcsin 1/Gamma = 19.5);
           it can't till it has landed: at 18 to 20 degrees its middle is still coming down (11 cm/s); landed at 42 to 44
    Right  Gamma 3.0: the bed leaves the floor 44 to 46 degrees into the upswing (a rigid bed: arcsin 1/Gamma = 19.5);
           it can't till it has landed: at 18 to 20 degrees its middle is still coming down (12 cm/s); landed at 42 to 44
    Middle the big bead reaches the top at 6.3 s (44 shakes), having risen 8.4 cm
    Right  the coloured bead reaches the top at 11.6 s (81 shakes), having risen 8.9 cm
    Middle from 5 s to a minute: beads in the middle rising 5.5 mm/s on average, beside the walls falling 10.1 mm/s
    Middle the big bead, since reaching the top, has been in the bed's upper half 77% of the time
    Right  from 5 s to a minute: beads in the middle rising 7.8 mm/s on average, beside the walls falling 12.9 mm/s
    Right  the coloured bead has gone round 4 times: going up it was 3.6 cm from the middle on average, going down 4.6 cm (the walls are 7.5 cm out)

* **Leaving the floor.** The box's floor accelerates downward at up to
  Gamma g, with Gamma = A w^2 / g. Below Gamma = 1 the floor never drops
  away faster than the beads fall, so the bed rides on it, and the floor's
  push never drops below (1 - Gamma) of the bed's weight: 0.19 here,
  against 0.20 for a rigid bed. Above Gamma = 1, a bed resting on the
  floor leaves it once the floor's downward acceleration passes g, at a
  phase of arcsin(1 / Gamma) into the upswing: 19.5 degrees at 3 g. A
  rigid bed that sticks where it lands (the "completely inelastic bouncing
  ball" of A. Mehta and J. M. Luck, *Phys. Rev. Lett.* 65, 393 (1990))
  lands at 1.4 degrees, rests on the floor, and leaves at 19.5. The floor's
  push is worked out from the bed's momentum (how much it changes each
  step, and the bed's weight), averaged by phase over shakes 5 to 32; the
  bed has left when it's less than a tenth of the bed's weight.
* **Why so late?** Because this bed hasn't landed by 19.5 degrees. It
  flies spread out, its middle half a centimetre to a centimetre higher
  than when it's packed, and it lands from the bottom up: the lowest beads
  touch down 20 to 40 degrees before the shake ends, and the rest pile
  on to them. At 19.5 degrees its middle is still coming down onto the
  floor at about 10 cm/s, and the floor is still stopping it; it's down at
  about 40 degrees, and only then can it leave. Shaken beds of real beads
  do this too: they land as a wave of packing that runs up through the
  layer (J. Bougie et al., *Phys. Rev. E* 66, 051301 (2002), simulating
  hard beads), and from about 3 g up the landing lasts about as long as
  the bed then rests on the floor (J. M. Pastor et al., *Physica D* 232,
  128 (2007), glass beads). So 19.5 degrees is the earliest a bed can
  leave, not when this one should. How long it takes to land doesn't depend on Bullet's steps:
  the bed is down at 38 to 44 degrees in every run below. Where it leaves
  does, a little: at 2400 steps a second (as shown) it presses on a few
  degrees after it's down, because Bullet's contacts give a little and
  spring back; at 4800 or more it leaves as soon as it's down. Each
  number is the start of a 2-degree bin; middle box, then right; the pour
  shown (BN_SEED 7), then BN_SEED 8:

      steps a second, solver iterations     leaves              landed
      2400, 20 (as shown)                   48, 44 | 44, 46     42, 42 | 38, 42
      2400, 50                              44, 44 | 40, 42     40, 42 | 40, 42
      3600, 30                              38, 38 | 42, 44     40, 40 | 40, 40
      4800, 20                              36, 38 | 40, 42     38, 38 | 42, 42
      9600, 20                              42, 36 | 42, 42     38, 42 | 38, 40

  So the bed leaves at about 40 degrees (36 to 42) once the contacts are
  stiff enough, and at about 46 (44 to 48) as shown: about 6 degrees of
  the 27 past 19.5 are Bullet's, the rest is the landing. Stiffer runs
  cost more (on the machine these were run on: 2400 and 50 iterations a
  third more time a frame, 4800 steps nearly twice as much), and this one
  already takes about twice the time a frame has at 60 frames a second, so
  2400 stays. The slider goes to 4800.
* **The convection.** Over a minute, beads in the middle of the box rise
  and those beside the walls fall: the two rolls. How fast depends on
  Bullet's steps, and hasn't settled: in the middle box the beads in the
  middle rise 5.5 mm/s at 2400 steps a second (as shown), 3.2 at 4800 and
  2.4 at 9600 (the right box: 7.8, 5.3, 4.9). The stiffer the contacts,
  the slower the rolls turn; which way they turn doesn't change.
* **The big bead** stays up. The coloured one, as small as the rest, goes
  round with them: up nearer the middle, down nearer the walls.
* **How soon** the big bead comes up depends a lot on how the beads were
  poured: 6.3 s (44 shakes) with the pour shown (`BN_SEED` 7), 21.4 s (149
  shakes) with `BN_SEED=8`. With stiffer contacts it comes up later, as
  the rolls are slower: at 11.9 s with 4800 steps a second (the coloured
  bead at 19.3 s), and at 43.6 s with 9600 (the coloured bead at 31.9 s).
  With `BN_SEED=8` and 4800 steps a second it isn't up within the minute.

## The beads and boxes

The beads are glass, 0.95 to 1.05 cm across, 140 to a box. (All the same
size, in a flat layer they'd stack like a honeycomb and lock.) The big one
is 3 cm across. The boxes are 15 cm wide inside. They're shaken at 7 Hz:
4.1 mm for 0.8 g, 15.2 mm for 3 g.

## Physics

* Bullet. The beads are spheres held to the plane of the box (a layer one
  bead thick, between glass). Bullet multiplies the two bodies' friction
  and bounce: the beads' are 0.8 and 0.1, the box's 1.0 and 0.1, so it's
  friction 0.64 between beads and 0.8 on the walls and floor, and almost
  no bounce (0.01). Real glass beads are slipperier and much bouncier
  (friction about 0.1, bounce 0.92 to 0.97, measured for 3 mm glass
  spheres at Cornell: S. F. Foerster et al., *Phys. Fluids* 6, 1108
  (1994)). But Bullet bounces every contact that's closing faster than 2
  mm/s, at every step, packed or not, and with bounce 0.95 this bed never
  settles at all. At 4800 steps a second, no bounce at all leaves the
  lift-off where it was (42 and 40 degrees), and friction 0.09 everywhere
  moves it a few degrees later (44 and 44).
* Each box is a heavy body moved exactly as the shaker moves it, and given
  the shaker's speed, before every step.
* 2400 physics steps a second, 20 solver iterations.
* How a shaken bed behaves depends on the friction, the bounce, the
  shaking and the beads' sizes. These settings (7 Hz, 3 g, high friction)
  were found by trying. At 10 Hz and 2.5 g with less friction, the big bead
  rose only now and then.

## Files

* `brazil-nut.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`).

Headless testing: `BN_SPEED`, `BN_STEPS`, `BN_ITER` (solver
iterations), `BN_SEED`, `BN_HARD`,
`BN_GENTLE` (g), `BN_F` (Hz), `BN_POLY` (the beads' spread in size),
`BN_MUB`, `BN_MUW` (friction), `BN_E` (bounce), `BN_LOG=file.csv`.
