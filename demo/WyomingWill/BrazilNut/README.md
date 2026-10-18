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
red bead in each, poured at the top by the left wall, shows which way the
beads go round. Every 50 s (simulated) they're poured again. The exhibit
runs at a quarter of real time.

## Keys

| Key | Action |
|---|---|
| `R` | pour them again |
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
  Left  the big bead is up: its middle 12 cm above the floor (over 2 s) at 10.6 s, 7.6 s into the hard shaking (the reference, 4 pours: 7.6 to 10.6 s)
  Left  Gamma 3.0: the bed leaves the floor 38 to 40 degrees into the upswing (a rigid bed: arcsin 1/Gamma = 19.5; the reference: 38 to 42);
        it can't till it has landed: at 18 to 20 degrees its middle is still coming down (14 cm/s); landed at 46 to 48 (the reference: landed at 44 to 48)
  Right Gamma 3.0: the bed leaves the floor 42 to 44 degrees into the upswing (a rigid bed: arcsin 1/Gamma = 19.5; the reference: 40 to 44);
        it can't till it has landed: at 18 to 20 degrees its middle is still coming down (14 cm/s); landed at 46 to 48 (the reference: landed at 44 to 48)
  Left  from 8 s to 45 s: beads in the middle rising 6.1 mm/s on average, beside the walls falling 11.7 mm/s (the reference: +5.9 to +7.5 / -13.8 to -11.7)
  Left  the big bead from 25 s to 45 s: its middle 15.7 cm above the floor on average, never below 11.1; in the bed's upper half 83% of the time (the reference: 15.7 to 16.3 cm, 81 to 88%)
  Left  the red bead, poured at the top by the left wall: lowest 9.5 cm above the floor, at 43.4 s, 1.8 cm from the left wall
  Right from 8 s to 45 s: beads in the middle rising 0.4 mm/s on average, beside the walls rising 4.0 mm/s (the reference: -0.7 to +0.4 / +3.1 to +4.0)
  Right the big bead from 25 s to 45 s: its middle 7.9 cm above the floor on average, never below 4.1; in the bed's upper half 0% of the time (the reference: 7.9 to 9.2 cm, 0 to 0%)
  Right the red bead, poured at the top by the left wall: lowest 9.0 cm above the floor, at 44.8 s, 8.2 cm from the left wall
  The walls decide: with rough walls the beads go down beside the walls and up the middle (-11.7 mm/s by the walls) and the big bead comes up (15.7 cm);
  with smooth glass walls they go up beside the walls (+4.0 mm/s) and it stays down (7.9 cm).
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
  as it's down, at 38 to 44. Real shaken layers do this too (J. Bougie et al.,
  *Phys. Rev. E* 66, 051301 (2002); J. M. Pastor et al., *Physica D* 232, 128
  (2007)).
- **The rolls.**
  - Rough walls: the middle rises 6 to 7.5 mm/s and the beads beside the walls
    fall 12 to 14 mm/s.
  - Smooth walls: the beads beside the walls rise 3 to 4 mm/s, and the middle
    barely moves (-0.7 to +0.4).
- **The big bead.**
  - With rough walls its middle passes 12 cm above the floor (averaged over
    2 s) 7.6 to 10.6 s into the hard shaking, from 1.5 cm at rest. From 25 to
    45 s it averages 15.7 to 16.3 cm, is never below 10.8 cm, and spends 81
    to 88% of the time in the bed's upper half. The bed is 20.2 cm deep at
    rest.
  - With smooth walls it averages 7.9 to 9.2 cm, dips to 3.7 to 4.2 cm, and
    is never in the upper half (its 2 s average never reaches 12 cm).
- **The red bead.** It starts at the top beside the left wall.
  - With rough walls it goes down beside the wall, in the wall stream: in
    the run shown it is lowest at 9.5 cm, 1.8 cm from the wall, at 43 s.
  - With smooth walls it goes down the middle: lowest at 9.0 cm, 8.2 cm
    from the wall, at 45 s.

  One bead's path is slow and varies from pour to pour; the rolls'
  averages above are the measure.
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
- Boxes: 15 cm wide inside and 44 cm tall.
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
- **Threads.** One per box. A box shares nothing with the other, so its
  numbers don't depend on the threads.
- **Stiffness.** Young's modulus 0.63 GPa, a hundredth of glass's 63, so
  that it can run at a quarter of real time. Its numbers against stiffer
  beads, the same pours (seeds 7 and 8, left box / right box):

  | Young's modulus | middle / walls, mm/s | big bead up (into the hard shaking) | its height 25-45 s |
  |---|---|---|---|
  | 0.63 GPa (as run) | +6.1, +7.5 / -11.7, -13.5; right +0.4, -0.7 / +4.0, +3.9 | 7.6, 10.6 s; right never | 15.7, 16.3 cm; right 7.9, 8.1 |
  | 6.3 GPa (steps a 80th of a contact) | +6.0, +5.2 / -12.4, -11.3; right +0.5, -0.2 / +2.9, +2.9 | 7.7, 8.5 s; right never | 14.6, 15.6 cm; right 7.9, 8.0 |

  The design study found the same from 0.63 to 63 GPa
  (`reconstruction/GLASS-DESIGN.md` §3.5): the same rise and height, with
  rolls about 10% faster at 0.63 GPa.
- **Cost.** Two threads, one per box (`DemBed:start`/`finish`); the next frame's stepping starts as soon as a frame is reported, so drawing overlaps it. Measured headless (no drawing) on this 2-core Xeon at 2.1 GHz, idle, at the default 1/4 speed, 300 frames at a time: 24-33 ms a frame over the first 4 simulated s (the settled bed and the gentle opening: a packed bed has more contacts), then 20-21 ms in the hard shaking; in the Cabinet 24-31, then 20-21 ms. Nearly all of it is waiting for the beads (19-20 ms). The 60 fps frame has 16.7 ms, so here the exhibit runs at about 0.8 of its quarter speed once shaking hard (about 1/5 of real time), and about half to two thirds of it in the first 4 s; a machine about 1.2x faster per core holds 60 fps. A box costs 4.8 CPU-s per simulated second in bpp (`-O3`, plain x86-64); `-march=native` would cut that by about a quarter but changes the rounding (fused multiply-adds), so the numbers would no longer match `bead-bed.c` bit for bit. Real time (Z) needs four times as much: about 80 ms a frame here.

## Files

- `brazil-nut.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`). It needs bpp from 17 October 2026 or later
  (`DemBed`). With an older bpp it shows the empty boxes and says so in the
  console.
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
