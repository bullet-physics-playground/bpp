# The Brazil-Nut Effect, in real glass

Shake a jar of mixed nuts and the Brazil nuts come up to the top: the
biggest rise, though they're the heaviest. Here two glass-fronted boxes of
real glass beads, a layer one bead thick and 20 cm deep, are shaken up and
down five times a second on a shaker table. A big glass bead starts at the
bottom of each. The boxes differ only in their side walls:

| Box | Walls | What happens |
|---|---|---|
| left | lined with glass beads glued to them, the way laboratories roughen their walls | the bed turns over in two rolls, up the middle and down the walls, and the big bead comes up about 10 cm within seconds and stays in the upper part of the bed |
| right | smooth glass | the rolls turn the other way, up beside the walls, and the big bead stays down |

Both are shaken gently first (peak acceleration 0.8 g for 2 s: the bed
never leaves the floor and nothing happens), then hard (3 g, from 3 s). A
red bead in each, poured at the top by the left wall, trails a fading line
of where it has been in the last 6 s, showing which way the beads go round.
Each big bead has a painted band round it, so you see it turn. The boxes are
closed by a lid. They run on until you pour them again (`R`): where the big
bead is after minutes is part of the point. The exhibit
runs at a quarter of real time.

## Keys

| Key | Action |
|---|---|
| `R` | pour them again (they run on until you do) |
| `Z` | slow motion (1/4, the default) <-> real time |

Sliders: hard (the peak acceleration after the opening, in g; from the next
pour) and speed. Rest the mouse on a big bead to see how high it is.

## Why

Shaken hard, the bed leaves the floor for part of each shake and lands
again. Beads beside a rough wall are held back by it, so they come down
along the walls, and the bed comes up in the middle: it turns over in two
rolls. The rolls carry the big bead up. At the top the small beads go down
again in the narrow stream by the walls, but the big one is too big to
follow them, so it stays up (J. B. Knight, H. M. Jaeger and S. R. Nagel,
*Phys. Rev. Lett.* 70, 3728 (1993)).

Smooth glass walls don't hold the beads back. Glass beads are slippery
(friction about 0.1) and bouncy (restitution about 0.95), and beside smooth
glass the rolls run the other way: up the walls and down the middle. The big
bead isn't carried up.

That's why laboratories roughen their walls. Hejmady et al. lined theirs
with sandpaper because "for smooth walls ... the convection patterns were
irreproducible and often the system would jam" (arXiv:1111.4484). The MRI
experiments on convection glued a layer of the grains themselves to the
walls. Here the left box's walls are lined with the bed's own 1-cm glass
beads, glued touching and half sunk in.

The bed is deep (280 beads, 20 cm) and shaken at 5 Hz for a reason. A bed of
bouncy glass half as deep is too lively: a heavy big bead stays at the
bottom even with rough walls, as in the "reverse Brazil-nut effect" of
fluidised beds (Hong, Quinn and Luding 2001; Breu et al. 2003). A deeper bed
loses more energy in its collisions and moves more like a solid. 5 Hz at
3 g shakes faster than 7 Hz at 3 g (94 cm/s against 67 at the peak), and
rise time goes with that speed (Hejmady et al.). See
`reconstruction/GLASS-DESIGN.md` for the study behind this design.

## The theory, and what the console says

```
--- poured: 280 glass beads a box, shaken at 5 Hz: gently (0.8 g, 8.0 mm) for 2 s, then hard (3.0 g, 29.8 mm) from 3 s ---
  Gamma 0.8: below 1 -- the bed should never leave the floor; Gamma 3.0: it should leave it 19.5 degrees into each upswing (arcsin 1/Gamma), if it has landed by then
  Left  Gamma 0.8: the bed never left the floor (the floor's push never less than 0.19 of its weight; a rigid bed's: 0.20; the reference: 0.18 to 0.19)
  Right Gamma 0.8: the bed never left the floor (the floor's push never less than 0.19 of its weight; a rigid bed's: 0.20; the reference: 0.19 to 0.19)
  Left  the big bead is up: its middle 12 cm above the floor (over 2 s) at 10.5 s, 7.5 s into the hard shaking (the reference, 4 pours: 7.5 to 9.5 s)
  Left  Gamma 3.0: the bed leaves the floor 40 to 42 degrees into the upswing (a rigid bed: arcsin 1/Gamma = 19.5; the reference: 40 to 42);
        it can't till it has landed: at 18 to 20 degrees its middle is still coming down (14 cm/s); landed at 46 to 48 (the reference: landed at 44 to 48)
  Right Gamma 3.0: the bed leaves the floor 42 to 44 degrees into the upswing (a rigid bed: arcsin 1/Gamma = 19.5; the reference: 40 to 44);
        it can't till it has landed: at 18 to 20 degrees its middle is still coming down (14 cm/s); landed at 44 to 46 (the reference: landed at 44 to 48)
  Left  from 8 s to 45 s: beads in the middle rising 6.7 mm/s on average, beside the walls falling 13.3 mm/s (the reference: +5.4 to +6.7 / -14.0 to -11.4)
  Left  the big bead from 25 s to 45 s: its middle 15.7 cm above the floor on average, never below 10.6; in the bed's upper half 85% of the time (the reference: 15.5 to 16.1 cm, 83 to 91%)
  Left  the red bead, poured at the top by the left wall: lowest 7.9 cm above the floor, at 45.0 s, 14.1 cm from the left wall
  Right from 8 s to 45 s: beads in the middle falling 0.3 mm/s on average, beside the walls rising 4.2 mm/s (the reference: -0.6 to +1.2 / +3.1 to +4.2)
  Right the big bead from 25 s to 45 s: its middle 8.9 cm above the floor on average, never below 5.0; in the bed's upper half 0% of the time (the reference: 7.6 to 10.4 cm, 0 to 3%)
  Right the red bead, poured at the top by the left wall: lowest 9.2 cm above the floor, at 26.8 s, 2.3 cm from the left wall
  The walls decide: with rough walls the beads go down beside the walls and up the middle (-13.3 mm/s by the walls) and the big bead comes up (15.7 cm);
  with smooth glass walls they go up beside the walls (+4.2 mm/s) and it stays down (8.9 cm).
  Left  the big bead from 45 s to 2 minutes: its middle 15.7 cm above the floor on average, never below 10.4; in the bed's upper half 85% of the time (the reference: 15.3 to 16.0 cm, 78 to 89%)
  Right the big bead from 45 s to 2 minutes: its middle 8.9 cm above the floor on average, never below 2.5; in the bed's upper half 0% of the time (the reference: 8.1 to 10.9 cm, 0 to 3%)
```

Each number is printed next to the reference: the same two boxes run
headless four times (`BN_SEED` 1, 2, 7 and 8, by `reconstruction/dembed-check`,
the same code as here), lowest to highest. The run shown is `BN_SEED` 7, one
of the four, so its numbers equal the reference's seed 7 exactly.

- **Gently (0.8 g).** The floor's push never drops below (1 - Gamma) = 0.20 of
  a rigid bed's weight, since below Gamma = 1 the floor never drops away
  faster than the beads fall. The bed never leaves the floor. Its least push
  is 0.18 to 0.19, a little below the rigid bed's: its contacts are a
  hundredth as stiff as glass (see Physics) and it rebounds a little on
  them. With beads ten times stiffer it is 0.198 to 0.199.
- **Hard (3 g).** A bed resting on the floor leaves it at arcsin(1/Gamma) =
  19.5 degrees into the upswing. This one is still landing then, coming down
  bottom-up at 14 cm/s, and has landed at 44 to 48 degrees; it leaves as soon
  as it's down, at 40 to 44. Real shaken layers do this too (J. Bougie et al.,
  *Phys. Rev. E* 66, 051301 (2002); J. M. Pastor et al., *Physica D* 232, 128
  (2007)).
- **The rolls.**
  - Rough walls: the middle rises 5.4 to 6.7 mm/s and the beads beside the
    walls fall 11 to 14 mm/s.
  - Smooth walls: the beads beside the walls rise 3 to 4 mm/s, and the middle
    barely moves (-0.6 to +1.2).
- **The big bead.**
  - With rough walls its middle passes 12 cm above the floor (averaged over
    2 s) 7.5 to 9.5 s into the hard shaking, from 1.5 cm at rest. From 25 to
    45 s it averages 15.5 to 16.1 cm, is never below 10.6 cm, and spends 83
    to 91% of the time in the bed's upper half. From 45 s to 2 minutes it
    averages 15.3 to 16.0 cm, in the upper half 78 to 89% of the time: it
    stays. The bed is 20.2 cm deep at rest.
  - With smooth walls it averages 7.6 to 10.4 cm from 25 to 45 s, and 8.1 to
    10.9 cm from 45 s to 2 minutes. It is in the upper half at most 3% of the
    time. In one pour of the four its 2 s average reached 12 cm once, at
    41 s.
- **The red bead.** It starts at the top beside the left wall, and its
  trail shows where it has been.
  - In the run shown, with rough walls it worked across the top and down
    beside the right wall: its lowest point by 45 s was 7.9 cm, at 45 s.
  - With smooth walls its lowest point was 9.2 cm, at 27 s, 2.3 cm from the
    left wall.

  One bead's path is slow and varies from pour to pour; the rolls' averages
  above are the measure.
- **The walls decide.** The two boxes have the same beads and the same
  shaking, and are poured alike (the rough box inside its lining, 1 cm
  narrower). Only the walls differ, and they set which way the bed turns and
  whether the big bead comes up.

## The beads and boxes

Soda-lime glass beads, 0.95 to 1.05 cm across (the spread keeps a flat
layer from stacking like a honeycomb and locking), 280 to a box. The big
bead is 3 cm across and solid glass: 27 times a small one's mass.

- Glass on glass: restitution 0.95 and friction 0.1, measured for 3 mm glass
  spheres at Cornell (S. F. Foerster et al., *Phys. Fluids* 6, 1108 (1994):
  e 0.92 to 0.97, friction 0.05 to 0.18). The same for the glued beads and
  the walls.
- Boxes: 15 cm wide and 44 cm tall inside, closed by a lid. The walls,
  floor and lid count as glass (friction 0.1, bounce 0.95). The rough box's
  lining runs from the floor to the lid.
- **Why a lid.** Shaken hard, a bed of bouncy glass throws beads up.
  - In an open box, the highest any bead's top reached, over 16 pours of 60
    to 240 s, was 67 to 84 cm above the floor. Some bead was above 44 cm in a
    third to almost half of the frames.
  - In a real box of this height they would fly out. A box tall enough would
    have to be about a metre, so the box is closed, as experiments' cells
    are.
  - The beads touch the lid only now and then: a bead is pressing on it in
    0.06 to 0.14% of the frames.
  - It changes the numbers only within the spread between pours (the same
    four pours, open against closed): rough walls +6.2 to +7.4 / -12.5 to
    -15.0 mm/s open against +5.4 to +6.7 / -11.4 to -14.0 closed; the big bead
    up at 11.4 to 14.1 s against 10.5 to 12.5 s; its height from 25 to 45 s
    15.2 to 16.0 cm against 15.5 to 16.1. The gentle push, the lift-off and
    the landing are the same.
  - In the open runs the lining went up to 70 cm, so the beads above the
    walls met no smooth wall above the lining.
- Shaking: 5 Hz, 8.0 mm for 0.8 g and 29.8 mm for 3 g. The amplitude ramps
  from the one to the other over the second between, as a shaker's would.

## Physics

The beads are not simulated by Bullet. Bullet's rigid contacts can't bounce
glass beads in a packed bed: its restitution, applied to every closing
contact each step, pumps energy into the bed until it boils, at any step
rate (`reconstruction/GLASS-DESIGN.md` §4). So each box is simulated by
bpp's **DemBed**: soft spheres, the reference model of
`reconstruction/` carried into bpp number for number
(`reconstruction/HOOK.md`). Bullet only draws the beads.

- **Contacts.** Hertz's law for the push, with Tsuji's damping, set from the
  restitution. A Mindlin tangential spring, capped by Coulomb friction. The
  glued beads are fixed spheres in the walls, met the same way.
- **Stepping.** Velocity Verlet, in steps of a 40th of a two-bead contact's
  duration (5.0 microseconds; 3326 steps per 1/60 s). Beads held to the
  box's plane, spinning about its normal, as in a one-bead-thick cell.
- **The band** on each big bead turns with the bead. It is drawn turned by
  the bead's spin in the model, integrated step by step.
  - The spin is the model's own, from the contacts' friction. Through the
    hook, bead-bed.c's incline test gives free rolling at a = 5/7 g sin(theta)
    and slipping from tan(theta) = 3.5 mu.
  - Its sense is a rolling bead's: one moving to the right turns clockwise
    as you see it.
  - The red beads' trails are drawn where each was every 0.25 s for the last
    6 s. They are for drawing only.
- **Threads.** One per box. A box shares nothing with the other, so its
  numbers don't depend on the threads.
- **Stiffness.** Young's modulus 0.63 GPa, a hundredth of glass's 63, so
  that it can run at a quarter of real time. Its numbers against stiffer
  beads, the same pours (seeds 7 and 8, left box / right box):

  | Young's modulus | middle / walls, mm/s | big bead up (into the hard shaking) | its height 25-45 s |
  |---|---|---|---|
  | 0.63 GPa (as run) | +6.1, +7.5 / -11.7, -13.5; right +0.4, -0.7 / +4.0, +3.9 | 7.6, 10.6 s; right never | 15.7, 16.3 cm; right 7.9, 8.1 |
  | 6.3 GPa (steps a 80th of a contact) | +6.0, +5.2 / -12.4, -11.3; right +0.5, -0.2 / +2.9, +2.9 | 7.7, 8.5 s; right never | 14.6, 15.6 cm; right 7.9, 8.0 |

  (These were run in the open box, before the lid, with the lining to 46
  cm.) The design study found the same from 0.63 to 63 GPa
  (`reconstruction/GLASS-DESIGN.md` §3.5): the same rise and height, with
  rolls about 10% faster at 0.63 GPa.
- **Cost.** Two threads, one per box. The next frame's stepping starts as
  soon as a frame is reported, so it overlaps the drawing. Measured headless
  (no drawing), idle, at the default 1/4 speed, 300 frames at a time, on a
  2-core Xeon at 2.1 GHz:

  | | First 4 simulated s | Hard shaking |
  |---|---|---|
  | Standalone | 23-31 ms a frame | 20-21 ms |
  | In the Gallery | 23-30 ms a frame | about 20 ms |

  - Nearly all of it is waiting for the beads.
  - In the first 4 s the bed is packed (settling and the gentle opening), so
    it has more contacts.
  - The 60 fps frame has 16.7 ms, so on that machine the exhibit runs at
    about 0.8 of its quarter speed once shaking hard, and at half to two
    thirds of it in the first 4 s. A machine about 1.2x faster per core
    holds 60 fps.
  - A box costs 4.8 CPU-s per simulated second. `-march=native` would cut
    that by roughly a quarter, but it changes the rounding (fused
    multiply-adds), so the numbers would no longer match `bead-bed.c` bit for
    bit.
  - Real time (Z) takes four times as much: about 80 ms a frame there.

## Files

- `brazil-nut.lua`: the exhibit. It also stands in Euler's Gallery
  (`../../`). It needs bpp from 17 October 2026 or later (`DemBed`).
  With an older bpp it shows the empty boxes and says so in the console.
- `reconstruction/`: how this design was found and how the exhibit is
  checked:
  - `FINDINGS.md`: the earlier exhibit against an independent model;
  - `GLASS-DESIGN.md`: the design study;
  - `HOOK.md`: how bpp's DemBed is `bead-bed.c`;
  - `bead-bed.c`: the reference model;
  - `dembed-check.cpp`, `hook-check.lua`: the checks;
  - `port/`: the tools that carried `bead-bed.c` into bpp.

Headless testing: `BN_SPEED`, `BN_SEED`, `BN_HARD`, `BN_GENTLE` (g), `BN_F`
(Hz), `BN_YM` (Pa), `BN_NS` (steps per contact time), `BN_TIMING=1` (prints
frame times), `HOLD_S`.

## The earlier version

Until 17 October 2026 this exhibit had three boxes of beads simulated by
Bullet, at 7 Hz. Their "glass" had friction 0.64 and 0.8 and bounce 0.01,
values found by trying. Its big bead rose because the beads were
frictional and dead, not glass-like, and its rolls and rise were not
converged in Bullet's step. `reconstruction/FINDINGS.md` gives the details.
With real glass in that bed the rolls run backwards, and no wall Bullet can
model brings them back. It was replaced by this design, which is real glass
throughout. The old version is in the repository's history.
