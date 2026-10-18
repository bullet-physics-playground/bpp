## The Brazil-Nut Effect

**What it shows** — Two glass-fronted boxes of real glass beads, a layer one bead thick and 20 cm deep, are shaken vertically at 5 Hz: gently (peak 0.8 g) for 2 s, then hard (3 g). A 3 cm solid glass bead starts at the bottom of each. The boxes differ only in their side walls. The left box's walls are lined with glued 1-cm glass beads, as laboratories roughen theirs. There the bed turns over in two rolls, up the middle and down the walls (Knight, Jaeger and Nagel's mechanism), and the big bead comes up about 10 cm within seconds and stays in the upper part of the bed. The right box has smooth glass walls: the rolls run the other way, up beside the walls, and the big bead stays down. Each big bead carries a painted band that turns with its spin. A red bead in each, poured at the top by the left wall, trails a fading line of its last 6 s. The boxes are closed by a lid. Runs at 1/4 of real time, until R pours again.

**Model** — Not Bullet. Each box is a **DemBed**, bpp's C++ port of the reference model `reconstruction/bead-bed.c` (FINDINGS.md, GLASS-DESIGN.md), one thread per box. Bullet only draws display-only spheres.
- **Port.** bead-bed.c's code was lifted mechanically into `src/demcore.cpp`: globals became members and bodies are unchanged (`reconstruction/port/`, HOOK.md). Its frame loop is bead-bed.c's main loop cut into steps. Wrapper and Lua binding: `src/dembed.cpp`, registered in `viewer.cpp`.
- **Contacts.** Hertz normal force K d^1.5, K = 4/3 E* sqrt(R_eff), E* = E / 2(1 - nu^2), nu 0.22, with Tsuji's damping alpha sqrt(m_eff K) d^1/4 d'; alpha is bisected so that a two-body collision returns e = 0.95. Tangential: a Cundall-Strack spring kt = 2(1 - nu)/(2 - nu) x 1.5 K sqrt(d) (Mindlin), with the same damping ratio, capped by Coulomb at mu Fn.
- **Materials.** mu 0.1 bead-bead, bead-wall and bead to glued bead; e 0.95 everywhere (Foerster et al. 1994, Cornell table: glass e 0.92-0.97, mu 0.05-0.18).
- **Stiffness.** E = 0.63 GPa, 1/100 of glass, with NS 40 steps per contact time: DT = 5.0 us, 3326 steps per 1/60 s.
- **Beads.** 280 small beads, radius 0.5 cm x (0.95 + 0.1 x ((37 i) mod 100)/99), density 2.5 g/cm^3; big bead radius 1.5 cm. Held to the plane, spinning about its normal.
- **Box.** 15 cm wide and 44 cm high inside, closed by a flat lid that moves with it and is met like the walls (glass: mu 0.1, e 0.95). Without the lid, beads fly up to 67-84 cm (16 pours) and some bead is above 44 cm in 32-45% of frames: they would leave a real open box. The lid was added to bead-bed.c (`LID`, `TEST=lid`) and ported. Floor, walls and lid move as y = A(t) sin(wt). A is 0.8 g's (8.0 mm) for 0 to 2 s, ramps linearly to 3 g's (29.8 mm) over 2 to 3 s, then stays. The speed includes A'(t) sin wt.
- **Rough walls.** Glued spheres of radius 0.5 cm, centres 1 cm apart from the floor to the lid, half-embedded, 44 per wall. Each is a fixed sphere met by the full contact law.
- **Integration and pour.** Velocity Verlet with a cell list. bead-bed.c's pour (the old lua's rows and random-number generator, `BN_SEED` 7), then 0.5 s to settle.
- **Measurements, all in C++ on the 1/60 s frame clock** (so independent of the display speed):
  - the floor's push from the bed's momentum change, in 2-degree phase bins, over shakes 4-10 (gentle) and 26-75 (hard);
  - lift-off below 0.1 W, and landing when the CoM stops approaching the floor;
  - rise rates every 0.5 s for |x| < 3 cm and |x| > 5 cm, 8-45 s;
  - the big bead's centre height: when its 2 s mean first reaches 12 cm, then its mean and least height and its time in the upper half over 25-45 s and again over 45-120 s;
  - the red bead's lowest point, and the highest any bead reaches.
- **Drawing.** The big bead's band is turned by its spin in the model, integrated each step; the red beads' trails are their positions every 0.25 s. Both are display only.
- **No automatic re-pour** (it used to re-pour every 50 s): the boxes run until R, so the big bead's place after minutes can be seen. The last check prints at 2 minutes.

**Theory checks** (default run, `BN_SEED` 7; "reference" = the same boxes run headless for seeds 1, 2, 7 and 8 with `reconstruction/dembed-check`, the same code)

| Quantity | Theory (formula / source) | Simulation, seed 7 | Reference, 4 pours | Agreement |
|---|---|---|---|---|
| Amplitude | A = Gamma g / (2 pi f)^2 | 8.0 mm, 29.8 mm | same | exact (definition) |
| Gamma = 0.8: bed stays on the floor | least push (1 - Gamma) W = 0.20 W, rigid bed | never left; least 0.19 W, both boxes | 0.18-0.19 W | 0.01-0.02 W low: the soft bed rebounds a little on its contacts |
| Gamma = 3: lift-off | arcsin(1/Gamma) = 19.5 deg if landed by then; else as soon as landed | left 40-42, right 42-44 deg | 40-44 | still landing at 19.5 (CoM coming down at 14 cm/s); leaves once down, as in FINDINGS |
| Gamma = 3: landed | rigid inelastic bed lands at 1.4 deg (Mehta and Luck 1990) | 46-48, 44-46 deg | 44-48 | **departs from the rigid model, as real layers do** (Bougie et al. 2002; Pastor et al. 2007) |
| Rolls, rough walls | up the middle, down the walls (Knight et al. 1993) | +6.7 / -13.3 mm/s | +5.4 to +6.7 / -14.0 to -11.4 | right direction, every pour |
| Rolls, smooth glass walls | reversed at low wall friction (Gallas et al. 1992; FINDINGS §6) | -0.3 / +4.2 mm/s | -0.6 to +1.2 / +3.1 to +4.2 | up beside the walls, every pour |
| Big bead rises, rough walls | carried up by the rolls (Knight et al. 1993) | 2 s mean at 12 cm 7.5 s into the hard shaking (10.5 s) | 7.5-9.5 s | yes, every pour |
| Big bead stays up, rough walls | trapped above the wall stream | 25-45 s: mean 15.7 cm, least 10.6, upper half 85%; 45-120 s: 15.7 cm, least 10.4, 85% | 15.5-16.1 cm, 83-91%; 45-120 s 15.3-16.0 cm, 78-89% | yes, for 2 minutes (bed 20.2 cm deep at rest) |
| Big bead, smooth walls | not carried up | 25-45 s: mean 8.9 cm, least 5.0, upper half 0%; 45-120 s: 8.9 cm, least 2.5, 0% | 7.6-10.4 cm, 0-3%; 45-120 s 8.1-10.9 cm, 0-3% (one pour's 2 s mean touched 12 cm once, at 41 s) | stays down |
| The lid | closed cell; must not change the bed's behaviour | touched in 0.06-0.14% of frames | open box (lining to 70 cm), same 4 pours: rough +6.2 to +7.4 / -12.5 to -15.0, up at 11.4-14.1 s, 15.2-16.0 cm; smooth -0.7 to +0.4 / +3.1 to +4.0, 7.9-9.2 cm; push, lift-off, landing the same | unchanged within the pour spread |
| Big bead's turn | rolling: a = 5/7 g sin(theta), slip from tan(theta) = 3.5 mu; turns clockwise rolling right | the band turns by the model's spin | bead-bed.c's incline test through the hook: identical | right magnitude and sense |
| The red bead | down the wall stream (rough) | left: lowest 7.9 cm at 45.0 s, by the right wall; right: 9.2 cm at 26.8 s, 2.3 cm from the left wall | not in the reference | qualitative only: one bead is slow and pour-dependent; its trail shows the direction |
| Stiffness (open box, before the lid) | results independent of E | 0.63 GPa (seeds 7, 8): left +6.1, +7.5 / -11.7, -13.5 mm/s, up 7.6, 10.6 s into the hard shaking, late 15.7, 16.3 cm; right +0.4, -0.7 / +4.0, +3.9, never up, 7.9, 8.1 cm; gentle push 0.19 | 6.3 GPa, NS 80: left +6.0, +5.2 / -12.4, -11.3, up 7.7, 8.5 s, late 14.6, 15.6 cm; right +0.5, -0.2 / +2.9, +2.9, never up, 7.9, 8.0 cm; gentle push 0.199, 0.198 | the same within the pour-to-pour spread; the gentle push nears 0.20 with stiffer beads (the 0.01 shortfall is the softening) |
| Port vs bead-bed.c | bit for bit | `hook-check.lua` through bpp: bead-bed.c's tests (drop, pair, incline, gdrop, ghollow) and lid give the same 100 lines; a 4 s design run gives the same settle, rolls, overlaps | `dembed-check` against `bead-bed`: 11 configurations (both laws, both boxes, glued walls, grit, plates, rolling, ETH, push report) and a low-lid run the same | identical |

**Cost** — Two threads, one per box (`DemBed:start`/`finish`); the next frame's stepping starts as soon as a frame is reported, so drawing overlaps it. Measured headless (no drawing) on this 2-core Xeon at 2.1 GHz, idle, at the default 1/4 speed, 300 frames at a time: 23-31 ms a frame over the first 4 simulated s (the settled bed and the gentle opening: a packed bed has more contacts), then 20-21 ms in the hard shaking; in the Cabinet 23-30, then about 20 ms. Nearly all of it is waiting for the beads (19-20 ms). (The lid, band and trail changed nothing measurable.) The 60 fps frame has 16.7 ms, so here the exhibit runs at about 0.8 of its quarter speed once shaking hard (about 1/5 of real time), and about half to two thirds of it in the first 4 s; a machine about 1.2x faster per core holds 60 fps. A box costs 4.8 CPU-s per simulated second in bpp (`-O3`, plain x86-64); `-march=native` would cut that by about a quarter but changes the rounding (fused multiply-adds), so the numbers would no longer match `bead-bed.c` bit for bit. Real time (Z) needs four times as much: about 80 ms a frame here.

**Run used**

```
cd demo/WyomingWill/BrazilNut && HOLD_S=0 timeout 7000 ../../../release/bpp -f brazil-nut.lua -n 29000
  (and BN_SPEED=1 HOLD_S=0 -n 7260; the default pause -n 29030; cmp2.sh brazil BrazilNut brazil-nut.lua 29030 bn;
   the reference: reconstruction/dembed-check with the exhibit's keys, seeds 1 2 7 8, rough and smooth, to 120 s,
   with the lid (LID=44 H=42) and open (H=70), and seeds 3-6 open to 60 s; YM 6.3e8 NS 40; earlier, open with
   H=44, 6.3e9 NS 80 for the stiffness check; HOOK.md has the port checks)
```
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
The README's console block matches this run. Hall against standalone (cmp2.sh, 29030 frames): IDENTICAL (17 run lines: the first three are printed as the hall loads). HOLD_S=0 for 29000 frames is the default pause's output for 29030 frames, all 20 lines. BN_SPEED=1 for 7260 frames prints the same 20 lines as 1/4 speed, number for number: everything is measured in C++ on the 1/60 s simulated frame clock. The bead threads stepping while a frame is drawn changed nothing (speed 1, 2760 frames, before and after). An older bpp, without DemBed: the console says the exhibit needs bpp from 17 October 2026 and the boxes stand empty, with no Lua error.

**Known departures and honest caveats**
- **Softer than glass.** E = 0.63 GPa, 1/100 of glass, so that two boxes run at 1/4 speed. Against 6.3 GPa the design gives the same rolls, rise and height within the pour-to-pour spread (seeds 7, 8, both boxes; table), and a gentle-phase push of 0.198-0.199 instead of 0.18-0.19. GLASS-DESIGN.md §3.5 found the rise times and plateau unchanged from 0.63 to 63 GPa, with rolls about 10% faster at 0.63.
- **No front and back panes, no air.** In a real one-bead-thick cell the panes and the air dissipate energy, so a real bed would likely be calmer.
- **The lid is part of the design.** An open box of this height can't hold the bed: shaken hard, bouncy glass throws beads up to 84 cm. The lid is touched rarely and doesn't change the results beyond the spread (table), but it is a closed cell, not the open box of the earlier exhibit.
- **Glued beads assumed to bounce like free glass** (e 0.95); an epoxy-backed bead may bounce less.
- **The big bead rises to the upper part, not to the surface.** It levels off about 4 cm below the bed's packed top (20.2 cm). The shaken surface is lively, its top tenth of beads well above 20 cm, so the old "reaches the top" test is never met.
- **Not converged with bed depth or frequency.** The design was chosen in GLASS-DESIGN.md over Gamma, f, depth, width and wall type. A shallower bed (140 beads) is fluidised and its glass big bead stays down even with rough walls.
- **Mostly a model.** No experiment with 1-cm glass beads in a one-bead cell was found to compare with. The qualitative facts (rough walls give normal rolls and a rising intruder; smooth walls don't, or the patterns are irreproducible) are from Knight et al. 1993, Hejmady et al. (arXiv:1111.4484) and the MRI experiments.
- **The earlier exhibit (Bullet, until 17 Oct 2026)** used friction 0.64 / 0.8 and bounce 0.01: not glass. Its rolls and rise weren't step-converged (FINDINGS.md). Bullet can't run e 0.95: restitution pumps energy into a packed bed at any step rate, and raising its restitution threshold doesn't fix it (GLASS-DESIGN.md §4). So the exhibit was moved off Bullet.

**References**
- J. B. Knight, H. M. Jaeger, S. R. Nagel, Phys. Rev. Lett. 70, 3728 (1993).
- R. Hejmady et al., "Scaling behavior in the convection-driven Brazil-nut effect", arXiv:1111.4484 (sandpaper walls).
- J. A. C. Gallas, H. J. Herrmann, S. Sokolowski, Phys. Rev. Lett. 69, 1371 (1992) (via FINDINGS.md).
- D. A. Hong, P. V. Quinn, S. Luding, Phys. Rev. Lett. 86, 3423 (2001); A. P. J. Breu et al., Phys. Rev. Lett. 90, 014302 (2003) (heavy intruders in fluidised beds).
- A. Mehta, J. M. Luck, Phys. Rev. Lett. 65, 393 (1990); J. Bougie et al., Phys. Rev. E 66, 051301 (2002); J. M. Pastor et al., Physica D 232, 128 (2007).
- S. F. Foerster, M. Y. Louge, H. Chang, K. Allia, Phys. Fluids 6, 1108 (1994); Cornell impact-results table.
- Y. Tsuji, T. Tanaka, T. Ishida, Powder Technol. 71, 239 (1992); R. D. Mindlin (tangential stiffness); P. A. Cundall, O. D. L. Strack (1979) (named in bead-bed.c, from memory).
