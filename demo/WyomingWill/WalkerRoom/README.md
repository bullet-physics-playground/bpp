# Walker room

Twelve walkers on one meadow -- ten of WyomingWill's, the
Hoecken-Spears 4-bar and the Hoecken-Spears long-stance (below) -- all
four-legged, each scaled
to the same stride, walking freely inside a walled 10 m x 10 m arena.
Open `walker-room.lua`.

Each walker is built by its own `../Walkers_For_Room/<name>_parts.lua`, a
copy of the build its standalone file uses with a few options added (see that
folder's README); the walkers in `../Walkers/` are left as they are. All of
them share one world, one terrain, one gravity and one physics step
(1/960 s). Jansen and Klann, six-legged in their own files, have two rows
of legs here instead of three. The two 2-leg Spears are left out (a side
experiment: two legs can't be compared fairly with four); `TWO_LEGS =
true` brings them back.

`test-square.lua` shows each walker's best version on each kind of
ground, one at a time (Test square, below).

## A fair comparison

The aim: every walker the same in everything but its linkage, so that on
flat ground they all go the same speed, and on bumps the differences are
the linkages'. A walker that doesn't make the flat-ground speed has
something wrong with its build.

The speeds quoted in this section, and the results further down, were
measured before the October 2026 geometry (Link planes, Balance and
Earlier results, below) and are void until measured again.

- **Same stride.** Each walker is scaled so its stride -- the length of
  its foot's path, measured with its body held still and its cranks
  turned slowly -- is 15 cm. A bump is then the same obstacle to every
  walker's step, and each foot lifts as high, for its stride, as its
  linkage lifts it (the "lift" of the linkage reference). Measured this
  way, every build's foot path matches its reference linkage's duty,
  lift and flatness. Their sizes differ as a result. (The diag builds'
  braces were welded to the legs with 3 degrees of give, against crank
  drift, which `LOCK_CRANKS` now stops; with it each leg rocked about 6
  degrees a turn and the diag builds' feet followed other paths --
  Chebyshev diag lift 13% against 16%. The welds are rigid now,
  `DIAG_GIVE = 0`, and the diag builds' feet trace the plated builds'
  paths: Chebyshev diag stride 4.705, lift 16.2%, Chebyshev 4.705 and
  16.3%.)
- **Same flat-ground speed.** Each walker's cranks turn at the speed at
  which, if its feet never slipped, it would cross flat ground at 9 cm/s
  (`FLAT_SPEED`). A foot covers its stride while it is down, so a
  walker whose feet are down for less of each turn has to turn its
  cranks slower: from 1.9 rad/s (Klann, Spears 4-bar) to 3.5
  (Chebyshev-Spears diag). Measured on the test track (mean of 4 starts):

  | Walker | Crank, rad/s | Flat, cm/s |
  |--------|--------------|------------|
  | Chebyshev-Spears       | 3.20 | 9.2 |
  | Jansen                 | 2.23 | 9.1 |
  | Chebyshev-Spears diag  | 3.45 | 9.1 |
  | Spears 4-bar           | 1.95 | 9.0 |
  | Hoecken-Spears 4-bar  | 2.98 | 8.8 |
  | Hoecken-Spears long-stance | 3.60 | 8.9 |
  | Chebyshev diag         | 2.83 | 8.8 |
  | Hoecken-Spears slider  | 3.32 | 8.6 |
  | Hoecken 4-bar          | 2.23 | 8.4 |
  | Klann                  | 1.91 | 7.7 |
  | Chebyshev              | 2.25 | 7.7 |
  | Hoecken slider         | 2.24 | 7.4 |

  All within 82-104% of 9; Chebyshev, Klann and Hoecken slider lose the
  most to their feet slipping, and are the builds to look at next.
  (Walker Room1 and the gravity-70 version turned every crank at 2.6
  rad/s, so flat speeds differed from 3.8 to 15 cm/s.)
- **Same chassis.** So that only the linkage differs, every walker gets
  the same front-to-back spacing of its feet (35 cm, between the middles
  of its front and back feet's paths) and the same side-to-side width
  (38.0 cm, outer foot edge to outer foot edge, as Jansen's own file has
  it). The width is measured on the walker as built, standing still, in
  its body's own frame; it had been measured from the walker's outline
  in the world while it walked, which swings with every step and came
  out 38.1 to 38.7. Its body is 12 cm up (its lowest point above flat
  ground), or higher where that would leave less than 1 cm between the
  top of a foot and the lowest link above it: Spears lift 44 12.46 cm,
  its diag build 13.13, Spears lift 53 14.33, its diag build 15.2. This
  uses each file's own leg-spacing and body-depth options and the room's
  `bodyRaise` option, none of which change its foot path. A walker's
  body width is where its legs are mounted, so the bodies look
  different widths even though the feet stand on the same rectangle.
  `WIDE = false` gives every walker a 30-31 cm stance instead (until
  Walker Room 2, Jansen's feet were 38 cm apart, Klann's 35 and the
  others' about 30).
- **Same links.** Every link is 0.3 cm thick (`LINK_THICK`), in planes
  0.7 cm apart, centre to centre (`PLANE_GAP`), leaving 0.4 cm between
  neighbouring faces; at 0.2 cm, loaded links, which twist a little at
  their joints, rubbed their neighbours up to 10% of the time. Their
  files' links were 0.18 to 0.46 cm thick, their planes 0.25 to 2.1 cm
  apart. Each walker uses as few planes as keep its links apart (Link
  planes, below).
- **Same feet.** Every walker stands on the same flat feet: 8 cm long
  (along the walk), 12 cm wide, 0.5 cm thick, weighing 1.5, each centred
  under its leg (Jansen's and Klann's had been off-centre). Big
  feet get over bumps by resting on them; small ones have to be lifted
  over. Their own files' feet ranged from 2.6 cm long (Chebyshev-Spears
  diag) to 12.6 cm (the balanced 2-leg Spears), and Jansen and Klann had
  none.
- **Cranks in step.** Most walkers have a motor for each crank, and
  nothing kept them in step: Chebyshev's cranks drifted 47 degrees apart
  in 10 s, Jansen's over 1000 degrees in a minute, and Klann ended up
  walking back and forth. Every walker's cranks are now held at the timing
  they were built with, as one motor driving them all through gears would
  hold them (`LOCK_CRANKS`).
- **Same material, same body.** Every bar of every walker -- links,
  plates and diagonal braces -- weighs 0.18 per cm of its length plus
  0.15 for each joint on it (a bolt), as if all were cut from the same
  stock (`BAR_MASS`; 0.18 per cm is Jansen's and Klann's own 0.04 per
  unit of their files, and 0.15 a joint their 0.3 a bar). A triangle
  counts as its three sides, a plate as a bar its width long; the ideal
  guides of `UNBRACED` weigh nothing. Every body weighs 40
  (`BODY_MASS`), turning as a 40 x 3 x 30 cm box of that weight would
  (`BODY_BOX`), and the legs add what they weigh: more legs, more
  weight. (Until October 2026 that turning was each body's own shape's:
  the room gave the body BODY_BOX's turning and then set its weight, and
  in bpp setting an object's weight works its turning out again from its
  shape. The order is now the other way round, so every body turns as
  BODY_BOX says. Every result measured before then had each walker's own
  body's turning.) The body is a frame carrying a load (Balance, below):
  the frame spans the leg mounts, is drawn and can touch things, and its
  depth sets where the legs are mounted. Before, each file weighed its own links
  (Chebyshev's 0.3-1.0 each, Spears 4-bar's 2-4) and every walker
  weighed 100 in all, its body whatever its legs didn't, so moving legs
  were from 16% (Chebyshev) to 62% (Jansen) of the weight. Now:

  | Walker | Body | Legs | Braces | Feet | In all |
  |--------|------|------|--------|------|--------|
  | Jansen | 40 | 89.4 | 0 | 6 | 135 |
  | Klann | 40 | 80.5 | 0 | 6 | 127 |
  | Chebyshev diag | 40 | 48.7 | 16.5 | 6 | 111 |
  | Hoecken 4-bar | 40 | 48.3 | 13.2 | 6 | 108 |
  | Chebyshev | 40 | 47.6 | 13.2 | 6 | 107 |
  | Chebyshev-Spears diag | 40 | 41.7 | 16.3 | 6 | 104 |
  | Spears 4-bar | 40 | 55.5 | 0 | 6 | 102 |
  | Hoecken slider | 40 | 42.4 | 13.2 | 6 | 102 |
  | Hoecken-Spears 4-bar | 40 | 40.9 | 13.3 | 6 | 100 |
  | Chebyshev-Spears | 40 | 39.3 | 13.2 | 6 | 99 |
  | Hoecken-Spears slider | 40 | 32.3 | 13.2 | 6 | 92 |
  | Hoecken-Spears long-stance | 40 | 30.6 | 13.3 | 6 | 90 |

  Weighed again after the October 2026 geometry (thinner links weigh
  the same: a bar's weight is its length and joints), every total is
  within 0.5 of this. The builds not in the table weigh, in all:
  Hoecken 4-bar diag 115, Hoecken-Spears 4-bar diag 106,
  Hoecken-Spears long-stance diag 100, Spears lift 44 108 (diag 121),
  Spears lift 53 113 (diag 128).

  `BAR_MASS = false` gives each file's own link weights and the old
  rule (`TOTAL_MASS`, 100 in all); `SAME_BODY = false` each file's own
  body weight. The results above the factorial runs (below) were
  measured with the old weights.
- **Same motors.** All of a walker's crank motors together can give at
  most 10 times its weight x gravity x stride of twisting effort
  (`MOTOR_STRENGTH`), the same for every walker. Their own files' motors
  ranged from 1.4 (Chebyshev-Spears diag) to 71 (Spears 4-bar) in these
  units. Stronger isn't better: at 70 the results are the same as at 10,
  except that the Hoecken-Spears long-stance fell 13 times. The walkers whose
  own motors were weakest (1.4-3.3: Chebyshev, Hoecken and their Spears
  versions) kept a little more of their speed on bumps with them
  (Chebyshev-Spears 65% against 57%), as if a motor that gives way a
  little when a foot meets a bump helps it get over. `MOTOR_STRENGTH =
  false` gives each walker its own file's motors.
- **Same physics precision.** Every joint of every walker is worked
  over 40 times a physics step (`SOLVER_ITERATIONS`), against Bullet's
  default 10. At 10, linkages under load have their joints pulled
  slightly apart, and walkers whose braces close a loop across the body
  (the diag walkers) jam on hills: Chebyshev-Spears diag made 1.3-1.8
  cm/s on 4 cm x 22 cm bumps at 10, and 7.2-8.4 at 40 (100 gives the
  same as 40). Stronger motors didn't help, as they wouldn't with a
  numerical fault. The Chebyshev and Hoecken families, the walkers
  with the weakest joints-to-load, were held back most.
- **Braces clear the bumps.** The plates and bars joining a walker's
  legs (its braces) hung as low as 0.9 cm above flat ground (Chebyshev,
  Chebyshev-Spears, the Hoecken-Spears 4-bars) and caught on bumps
  between the feet: on 4 cm bumps they touched 11-23% of the time. Every
  brace now stands at least 7 cm up (`BRACE_CLEARANCE`), above the
  tallest bumps: a plate loses that much off its bottom, its top staying
  where it was. (Hoecken slider's plates were already 6.5 cm up; Jansen,
  Klann and Spears 4-bar have none.) A diag walker's bottom brace can't
  be lifted that far: it once was, passing through the walker's other
  parts as if they weren't there, but lifted it went through the body
  (all the time for Hoecken 4-bar diag, 2-31% for the others) and the
  circles the cranks turn in. So both a diag walker's braces now ride
  over its body (`DIAG_ARCH`), at the height of its own top brace on the
  pendants -- no pendant longer -- the front-left/back-right one arched
  up in the middle to pass over the other where they cross: three
  straight pieces welded into one bent bar, its rise (`brace.rise`) the
  least that kept the two from touching on flat ground, 6 cm waves,
  logs and steps, plus 2 cm (10 cm; Spears lift 44 diag 14, Spears lift
  53 diag 16, with its top braces at 4 units above the leg's end, not
  2.75, where its file's top brace hit a link). Nothing of a diag walker
  now passes through anything of its own.
- **Same joints.** Jansen's and Klann's own files soften every hinge
  (constraint force mixing 0.1); no other walker's do. Under this
  gravity their joints gave, and four-legged they barely moved (0.3
  cm/s). Here their hinges are as stiff as everyone else's.
- **Same gravity.** Every standalone file uses 9.8 units/s^2, but the
  walkers are built at very different sizes in those units. All of them
  are under 70 cm/s^2 here (`GRAVITY`), each with its motors made
  stronger or weaker by the same factor as its gravity, so it can still
  lift itself. Earth's would be 981, at which almost every walker
  stalls. Walker Room1 used 20, and there the walkers whose feet lift
  most were off the ground much of the time (share of a minute on flat
  ground with no foot down):

  | Gravity, cm/s^2 | Klann | Hoecken-Spears slider | Chebyshev-Spears | Spears 2-leg | Others |
  |-----------------|-------|-----------------------|------------------|--------------|--------|
  | 20 (Walker Room1) | 31% | 18% | 17.5% | 15.5% | under 0.5% |
  | 70              | 0.5%  | 0%  | 0%    | 0%    | under 2% |

Not the same yet:

| What | How it differs |
|------|----------------|
| Gait (the timing between the legs) | Both legs on a side together, the sides opposite: Chebyshev, Chebyshev-Spears (here; a quarter turn apart in its own file), Hoecken, the two sliders, and (here) Jansen and Klann. Diagonal pairs: the two diag walkers. 0/225/180/225 degrees: Spears 4-bar (its design) |
| Body length | Each frame spans its own leg mounts, 3 cm past the first and last: 41.0 to 49.8 cm, Spears 4-bar 59.9 (its mounts are 54 cm apart). Its weight and turning are the same for all: see Same material, same body |
| Bracing between the legs | Side plates (Chebyshev, Hoecken, the sliders), diagonal braces (the diag walkers), none (Spears 4-bar, Jansen, Klann); all at least 7 cm up now |
| Damping | Each file's own (foot friction is 0.8 for every walker now; Jansen's and Klann's files had 0.9) |

### Link planes

Each link moves in a plane parallel to the walker's side, and each
walker uses as few planes as keep its links from touching (`spec.planes`:
link to plane, counted out from the body's face). This was found by
turning every walker's cranks through a full turn, its body held still,
and logging where every link went:

- links of the same leg may share a plane if they are never in the same
  place at the same moment, with 0.2 cm to spare;
- links of different legs may share one only if the areas they sweep
  never meet, whatever the gait;
- links hinged together are in different planes; links welded together
  may share one;
- where there are braces, the pendant (the link the foot hangs from) is
  outermost.

| Walker | Planes |
|--------|--------|
| Spears 4-bar | 2 |
| Jansen (was 7), Klann (was 5) | 3 |
| Chebyshev, Chebyshev diag, Chebyshev-Spears, Hoecken 4-bar and its diag build, Hoecken-Spears 4-bar and its diag build, Spears lift 44 and 53 and their diag builds | 3 |
| Chebyshev-Spears diag, Hoecken-Spears long-stance and its diag build | 4 |
| The two sliders | 2, their own layout (given others, they jammed) |

With these, no walker jams, and links touch each other at most 0.7% of
the time (Chebyshev-Spears diag, brief brushes; flat ground, 6 cm waves,
4 cm logs and 4 cm steps, a minute each). `handover/walkers_from_above.png`
shows every build from above.

### Balance

Most files mount their legs off the middle of the body, so the walkers'
weight was shared unevenly between their front and back feet: Klann put
77% of its on one pair. With `BALANCE` (on), each walker's 40 kg load is
slid along the walk (`spec.bodyShift`) until the whole walker's centre of
mass, averaged over a crank turn, sits midway between the middles of its
front and back feet's paths; every walker is within 0.01 cm of that. The
slides, in each file's own frame (cm):

| Walker | Slide | Walker | Slide |
|--------|-------|--------|-------|
| Klann | -29.44 | Spears 4-bar | +19.44 |
| Spears lift 53 | +17.77 | Spears lift 53 diag | +18.07 |
| Spears lift 44 | +12.77 | Spears lift 44 diag | +12.99 |
| Jansen | -5.94 | the other 4-bars and diag builds | +2.9 to +5.5 |
| the sliders | about -0.3 | | |

(A walker with `forward = -1` is turned round in the room, so its file's
forward is the room's backward.)

The body is one rigid body: the load, at the balance point, and a frame
(`spec.frame`, a box spanning the leg mounts from 3 cm before the first
to 3 cm past the last), set off from the load along the walk. The frame
is what is drawn and what can touch the ground; the load's weight and
turning are `BODY_BOX`'s whatever the frame's length. Klann's load sits
0.2 cm off the back end of its frame. No body touches the ground in the
checks above.

The balance was a suspect for one pattern in the earlier results: a
walker reversed often did better, though most foot paths are the same
at both ends.

### Earlier results

Everything below this point that gives speeds, shares kept or ranks was
measured before the geometry above (October 2026: uniform links, fewest
planes, centred feet, the 38.0 cm stance measured at rest, the body
height rule, balance, frame bodies and the turning fix) and is void. It
is kept as a record of what was tried and why. The factorial runs are
being redone with the new geometry.

Progress in the full room over 3 minutes (braces as built, before
`BRACE_CLEARANCE`; cm/s, measured in 5 s steps,
so rocking in place doesn't count as getting anywhere; one run each,
with avoidance turns, so a few tenths either way mean little), on flat
ground and on short bumps (TerrainHeight 4 cm, BumpLength 11 cm):

| Walker                     | Flat | Short bumps | Kept |
|----------------------------|------|-------------|------|
| Chebyshev-Spears diag      | 7.69 | 8.56        | 111% |
| Hoecken-Spears slider      | 7.55 | 7.73        | 102% |
| Hoecken-Spears 4-bar       | 8.06 | 7.62        | 95%  |
| Hoecken-Spears long-stance | 8.11 | 7.51        | 93%  |
| Chebyshev-Spears           | 8.44 | 7.54        | 89%  |
| Hoecken slider             | 6.60 | 5.85        | 89%  |
| Hoecken 4-bar              | 8.00 | 6.87        | 86%  |
| Klann                      | 8.01 | 6.75        | 84%  |
| Chebyshev diag             | 8.39 | 7.04        | 84%  |
| Jansen                     | 8.35 | 6.76        | 81%  |
| Chebyshev                  | 6.91 | 5.17        | 75%  |
| Spears 4-bar               | 8.42 | 5.67        | 67%  |

The five Spears changes are the top five.

On the default bumps (22 cm long, a stride and a half) the walkers keep
most of their speed when the bumps are low: those are rolling hills they
walk up and down. Shorter bumps are obstacles a foot has to get over
within a step.

When a walker comes within 40 cm of a wall or of another walker ahead
of it, or another walker's path and its own would bring them within
20 cm in the next 4 seconds (from any side), it turns smoothly (over a
second) to a new heading pointing away from what is near. It steers by
the way it actually travels, not the way it faces: some walkers walk
sideways or backwards part of the time, and each keeps a running
average of the difference. The balanced 2-leg Spears is held to move
only along its heading, so it turns only in right angles. A walker that
falls over and stays down for 2 seconds is stood up again, facing the
way it was facing, and carries on.

## Test track

`test-track.lua` runs one walker from the room -- the same stride, chassis,
feet, crank speed and gravity -- straight down a 10 m x 2 m strip of the
room's terrain, with no avoidance turns, and prints how far it got in
60 s. Open it in bpp to watch one walker (the settings are at its top; Tab
and Shift+Tab put the next or previous walker on the track, timed from
when it is put there), or run `./test-track-all.sh path/to/bpp` to run
every walker on flat ground and at bump heights 2, 4 and 6 cm and lengths
11, 15 and 22 cm, from 4 starting points each (about 25 minutes); the
results go to `test-track-results.txt`. `EXTRA` adds settings to every run
(`EXTRA="FOOT_LENGTH=4" ./test-track-all.sh ...`) and `OUT` names the
results file.

Share of its flat-ground speed each walker kept (mean of the 4 starts;
columns are bump height / bump length, in cm), with the lift of its foot
path (how high its foot rises above its stance, as a share of its
stride; measured on the builds, as the linkage reference measures it),
its mean speed over all the bumps, and its mean before the braces were
raised (`BRACE_CLEARANCE = false`):

| Walker                     | Lift | 2/11 | 2/15 | 2/22 | 4/11 | 4/15 | 4/22 | 6/11 | 6/15 | 6/22 | Mean | On bumps, cm/s | Low braces |
|----------------------------|------|------|------|------|------|------|------|------|------|------|------|----------------|------------|
| Chebyshev-Spears diag      | 24%  | 111% | 116% | 110% | 102% | 107% | 76%  | 88%  | 66%  | 44%  | 91%  | 7.6 | 94% |
| Hoecken-Spears slider      | 28%  | 103% | 105% | 98%  | 98%  | 100% | 69%  | 86%  | 82%  | 19%  | 84%  | 7.0 | 84% |
| Hoecken-Spears 4-bar       | 28%  | 95%  | 95%  | 89%  | 91%  | 92%  | 74%  | 87%  | 82%  | 11%  | 80%  | 7.1 | 84% |
| Hoecken 4-bar              | 17%  | 92%  | 91%  | 91%  | 86%  | 87%  | 65%  | 82%  | 78%  | 45%  | 80%  | 6.7 | 78% |
| Klann                      | 44%  | 95%  | 93%  | 90%  | 85%  | 81%  | 70%  | 77%  | 66%  | 44%  | 78%  | 6.8 | 78% |
| Chebyshev-Spears           | 26%  | 96%  | 95%  | 91%  | 91%  | 90%  | 62%  | 82%  | 82%  | 6%   | 77%  | 6.9 | 81% |
| Chebyshev diag             | 14%  | 103% | 105% | 95%  | 89%  | 72%  | 65%  | 75%  | 40%  | 20%  | 74%  | 6.4 | 71% |
| Hoecken-Spears long-stance | 29%  | 98%  | 99%  | 87%  | 92%  | 89%  | 29%  | 78%  | 74%  | 7%   | 73%  | 6.2 | 75% |
| Hoecken slider             | 21%  | 88%  | 88%  | 88%  | 78%  | 81%  | 51%  | 57%  | 67%  | 20%  | 68%  | 5.1 | 71% |
| Jansen                     | 28%  | 80%  | 92%  | 87%  | 68%  | 72%  | 54%  | 53%  | 43%  | 3%   | 61%  | 5.6 | 61% |
| Chebyshev                  | 16%  | 80%  | 82%  | 81%  | 76%  | 68%  | 40%  | 52%  | 54%  | 2%   | 59%  | 4.4 | 64% |
| Spears 4-bar               | 28%  | 77%  | 80%  | 75%  | 50%  | 69%  | 7%   | 41%  | 34%  | 11%  | 49%  | 4.5 | 49% |

Raising the braces helped no one much: the low plates had been carrying
some walkers over the steepest hills (6 cm x 22 cm) like skids. Across
all twelve, lift alone does not go with the share kept (correlation
0.10; it was 0.74-0.84 at Bullet's default precision, which held the
low-lift Chebyshev and Hoecken walkers back most). What does is how high
the foot is at the front of its swing, where it meets a bump: see "Why
the Spears changes work", below.

The cleanest comparisons are the pairs where the Spears version is the
same mechanism with more lift, on the same chassis, feet, weight, motors
and gait:

| Pair (lift)                                         | Now        | Low braces | At 10, wide | At 10, narrow | Room 2 (same weight) | Room1 (gravity 20) |
|-----------------------------------------------------|------------|------------|------------|------------|------------|--------------------|
| Chebyshev (16%) -> Chebyshev-Spears (26%)           | 59% -> 77% | 64% -> 81% | 27% -> 69% | 18% -> 57% | 23% -> 65% | 63% -> 88% |
| Chebyshev diag (14%) -> Chebyshev-Spears diag (24%) | 74% -> 91% | 71% -> 94% | 31% -> 54% | 32% -> 58% | 33% -> 52% | 71% -> 77% |
| Hoecken slider (21%) -> Hoecken-Spears slider (28%) | 68% -> 84% | 71% -> 84% | 59% -> 79% | 34% -> 65% | 40% -> 62% | 69% -> 80% |
| Hoecken 4-bar (17%) -> Hoecken-Spears 4-bar (28%)   | 80% -> 80% | 78% -> 84% | 54% -> 70% | 39% -> 63% | 43% -> 65% | --         |

In three of the four the Spears version keeps 16-18 points more of its
speed; Hoecken 4-bar and its Spears version now keep the same share,
though the Spears version is still faster on bumps (7.1 cm/s against
6.7: Hoecken 4-bar is slower on flat ground). (Chebyshev-Spears' own
file has its sides a quarter turn apart; here they are opposite, as
Chebyshev's are. That changed nothing: 78% both ways, before the weights
were made the same.)

The diag builds tie each front leg to the opposite back leg with braces
that cross the body, so diagonal legs step together (a trot); the others
tie the two legs on a side together (both legs on a side step
together). At Bullet's default precision that crossed loop of joints
couldn't be held together on hills and the diag walkers jammed; at 40
passes they do as well as or better than the side-braced ones.

Hoecken and Chebyshev are, in the room, the same kind of linkage -- a
coupler carried straight on past the rocker joint to the foot -- with
proportions 2-4% apart (crank 1: ground 2.09 against 2, coupler and
rocker 2.55 against 2.5). At the default precision Chebyshev did far
worse; at 40 passes most of that gap closes (64% against 78%).

Long, high bumps (22 cm long, 6 cm high: steep hills) stop nearly
everyone. Four starts per condition is few: differences of a few points
mean little.

### The best version of each walker

Each walker run the way it does best -- forward or reversed (`REVERSE`),
with its own timing or trotting (`GAIT`; plated walkers with `UNBRACED`,
or the diag-braced builds in `trotting-walkers.lua`) -- and 8 starts per
setting. Ranked by speed on bumps, the fairest measure once the walkers
run differently (the reversed, trotting Spears 4-bar is slow on flat
ground, which inflates its share kept); +- is the standard error over the
8 starts:

| Walker | Best version | Flat, cm/s | 2/11 | 2/15 | 2/22 | 4/11 | 4/15 | 4/22 | 6/11 | 6/15 | 6/22 | Kept | On bumps, cm/s |
|--------|--------------|------------|------|------|------|------|------|------|------|------|------|------|----------------|
| Klann                      | reverse, trot          | 8.9 | 96%  | 96%  | 98%  | 91%  | 91%  | 84% | 88% | 81% | 68% | 88% | 7.89 +-0.02 |
| Hoecken-Spears 4-bar       | trot, diagonal braces  | 8.8 | 95%  | 98%  | 98%  | 100% | 101% | 88% | 87% | 77% | 46% | 88% | 7.71 +-0.07 |
| Jansen                     | reverse, trot          | 8.9 | 106% | 95%  | 108% | 87%  | 85%  | 87% | 79% | 70% | 60% | 86% | 7.70 +-0.03 |
| Chebyshev-Spears diag      | trot, diagonal braces  | 8.4 | 111% | 115% | 110% | 102% | 105% | 71% | 86% | 70% | 47% | 91% | 7.64 +-0.07 |
| Spears 4-bar               | reverse, trot          | 7.5 | 112% | 104% | 107% | 103% | 96%  | 95% | 94% | 90% | 83% | 98% | 7.41 +-0.02 |
| Hoecken slider             | trot, guides           | 8.8 | 95%  | 91%  | 88%  | 88%  | 87%  | 72% | 83% | 80% | 47% | 81% | 7.16 +-0.02 |
| Hoecken-Spears slider      | trot, guides           | 8.7 | 97%  | 96%  | 88%  | 91%  | 92%  | 66% | 83% | 82% | 41% | 82% | 7.11 +-0.03 |
| Hoecken 4-bar              | trot, guides           | 9.0 | 94%  | 91%  | 89%  | 84%  | 84%  | 76% | 78% | 74% | 41% | 79% | 7.09 +-0.05 |
| Chebyshev-Spears           | sides, plates          | 8.9 | 95%  | 95%  | 91%  | 91%  | 91%  | 66% | 84% | 81% | 8%  | 78% | 6.96 +-0.04 |
| Chebyshev diag             | trot, diagonal braces  | 8.7 | 103% | 104% | 95%  | 92%  | 74%  | 63% | 79% | 35% | 14% | 73% | 6.42 +-0.06 |
| Chebyshev                  | trot, guides           | 8.9 | 91%  | 88%  | 82%  | 81%  | 80%  | 46% | 78% | 65% | 35% | 72% | 6.41 +-0.09 |
| Hoecken-Spears long-stance | sides, plates          | 8.6 | 98%  | 99%  | 88%  | 93%  | 90%  | 32% | 81% | 73% | 8%  | 74% | 6.33 +-0.06 |

The +- covers only the starting points, not modelling choices such as
guides against plates, which moved results by more. Each linkage against
its Spears version, best version each (speed on bumps): Chebyshev 6.41
-> 7.0 (Chebyshev-Spears), Chebyshev diag 6.42 -> 7.64, Hoecken 4-bar
7.09 -> 7.71, Hoecken slider 7.16 -> 7.11 (level). The Spears 4-bar's
four bars do about as well as Klann's six and Jansen's eight.

None of them floats: on flat ground no best version is ever wholly more
than 0.5 cm off the ground, and on 4 cm x 15 cm bumps the most any is
(the long-stance walker) is 3.6% of the time, never more than 2 cm up or
for longer than 0.4 s -- short hops over bumps, not the floating of
gravity 20.

### Other terrains

All the results above are on one landscape: three sine waves, the same
pattern everywhere, only scaled. To check that they don't hang on it,
`TERRAIN` gives other ground, at the same bump heights (`AMP`) and scale
(`BUMP`): `"random"` (twelve waves at random directions, spacings and
offsets, a different landscape for each start; its highest point is
AMP, as for the waves, but it is gentler on average), `"logs"`
(separate rounded ridges AMP high across the way, at random angles and
spacings) and `"steps"` (flat ground with sharp-edged ledges AMP high,
up and down by turns). Each walker in its best version, unchanged, on
bump heights 2, 4 and 6 cm and lengths 11 and 22 cm, 4 starts (speed
on bumps, cm/s, and rank):

| Walker | Waves | Random | Logs | Steps |
|--------|-------|--------|------|-------|
| Jansen                     | 7.89 (1)  | 8.78 (1)  | 3.99 (3)  | 6.97 (2)  |
| Klann                      | 7.84 (2)  | 8.72 (2)  | 6.80 (1)  | 8.34 (1)  |
| Hoecken-Spears 4-bar       | 7.50 (3)  | 7.67 (4)  | 2.61 (4)  | 4.67 (6)  |
| Spears 4-bar               | 7.50 (4)  | 7.83 (3)  | 5.56 (2)  | 6.10 (3)  |
| Chebyshev-Spears diag      | 7.42 (5)  | 7.48 (6)  | 1.63 (8)  | 4.17 (9)  |
| Hoecken 4-bar              | 6.95 (6)  | 7.12 (9)  | 2.23 (6)  | 4.10 (10) |
| Hoecken slider             | 6.86 (7)  | 7.33 (8)  | 2.42 (5)  | 5.04 (5)  |
| Hoecken-Spears slider      | 6.79 (8)  | 7.10 (10) | 1.61 (9)  | 4.27 (8)  |
| Chebyshev diag             | 6.50 (9)  | 6.94 (11) | 1.44 (10) | 3.62 (11) |
| Chebyshev-Spears           | 6.36 (10) | 7.59 (5)  | 1.02 (11) | 5.16 (4)  |
| Chebyshev                  | 6.13 (11) | 6.79 (12) | 2.11 (7)  | 3.52 (12) |
| Hoecken-Spears long-stance | 5.60 (12) | 7.41 (7)  | 0.82 (12) | 4.38 (7)  |

On irregular bumps the order holds well (rank correlation with the waves
0.75; the same four lead). Logs and steps are different: a walker whose
foot rises less than the obstacle is high stops dead in front of it. At
4 cm logs every walker but three makes under 0.6 cm/s; Klann, whose
foot rises furthest (6.6 cm at this stride), is the only one that clears
6 cm logs and ledges reliably, and the reversed, trotting Spears 4-bar
and Jansen (4.2 cm) get over 4 cm. So the earlier finding that lift
doesn't matter holds for rolling ground only: over separate obstacles,
how high the foot rises sets a hard limit. The Spears changes raise it
(Chebyshev 2.4 cm -> Chebyshev-Spears 3.9). Each pair, Spears version
minus original (speed on bumps, cm/s):

| Pair | Waves | Random | Logs | Steps |
|------|-------|--------|------|-------|
| Chebyshev -> Chebyshev-Spears           | +0.23 | +0.79 | -1.09 | +1.64 |
| Chebyshev diag -> Chebyshev-Spears diag | +0.92 | +0.54 | +0.19 | +0.55 |
| Hoecken 4-bar -> Hoecken-Spears 4-bar   | +0.55 | +0.55 | +0.37 | +0.57 |
| Hoecken slider -> Hoecken-Spears slider | -0.07 | -0.23 | -0.81 | -0.77 |

Two pairs favour the Spears version on every terrain; Chebyshev-Spears
on three of four; the sliders favour the original on every one. (On
logs, a stopped walker's speed depends on where its first log falls, so
4 starts give rough numbers there.)

### The factorial runs

Every walker in every way it can be built, timed and turned, under the
same material and body (`BAR_MASS`, `BODY_MASS`) and rigid diag braces
(`DIAG_GIVE = 0`), with no ankles: bracing (its own frame -- Jansen,
Klann, Spears 4-bar --, side plates, diagonal braces, or guides),
timing (sides: both legs on a side together; trot: diagonal legs
together) and direction (forward, reversed). Plates fix the timing at
sides and diagonal braces at trot; guides take either. The diagonal
builds of Hoecken-Spears long-stance and Spears lift 44 and 53 are in
`spears-lift-walkers.lua`; the sliders have none (their diagonal bars
shook). 80 configurations in all, first on the waves (10 settings, 2 to
4 starts), then the best two of each linkage on the other terrains (6
settings, 2 starts).

Flat speed was first set to 9 cm/s for each configuration by its crank
speed. That rewarded walkers that slip on flat ground: Spears lift 44
and 53 make only 7.4-7.6 cm/s on flat at their own crank speed, needed
cranks 38-43% faster, and then bounded -- off the ground (the whole
walker more than 0.5 cm up) 33-39% of the time, and faster on bumps
than on flat. So no crank turns faster than its own speed here (a
walker that slips on flat ground shows it), only slower (Klann's, by 5%).
The test track's results now include `air`, that share of the time.

The best configuration of each linkage on the waves (speed on bumps,
cm/s; flat speed; air on flat / on bumps):

| Linkage | Bracing | Timing | Direction | Flat | On bumps | Kept | Air | Next best |
|---------|---------|--------|-----------|------|----------|------|-----|-----------|
| Chebyshev-Spears | diagonal | trot | reversed | 8.93 | 8.53 | 96% | 5 / 11 | diagonal, trot, forward 7.96 |
| Spears lift 44 | diagonal | trot | reversed | 7.81 | 8.38 | 107% | 9 / 5 | diagonal, trot, forward 7.95 |
| Hoecken-Spears long-stance | diagonal | trot | forward | 8.11 | 8.33 | 103% | 14 / 20 | diagonal, trot, reversed 8.16 |
| Hoecken-Spears 4-bar | diagonal | trot | reversed | 8.68 | 8.12 | 94% | 6 / 7 | plates, sides, reversed 7.60 |
| Klann | own | trot | reversed | 8.95 | 8.03 | 90% | 0 / 0 | own, sides, reversed 7.88 |
| Jansen | own | trot | reversed | 9.07 | 7.76 | 86% | 0 / 1 | own, sides, reversed 6.60 |
| Hoecken 4-bar | guides | trot | reversed | 8.98 | 7.68 | 85% | 0 / 6 | guides, trot, forward 7.42 |
| Hoecken-Spears slider | guides | trot | forward | 8.34 | 7.52 | 90% | 3 / 8 | guides, trot, reversed 7.48 |
| Chebyshev | guides | trot | reversed | 9.07 | 7.45 | 82% | 0 / 0 | guides, trot, forward 7.13 |
| Spears 4-bar | own | trot | reversed | 7.37 | 7.42 | 101% | 0 / 2 | own, sides, reversed 7.00 |
| Spears lift 53 | diagonal | trot | forward | 7.20 | 7.39 | 103% | 22 / 10 | guides, trot, forward 7.22 |
| Hoecken slider | guides | trot | reversed | 8.76 | 7.14 | 82% | 0 / 3 | guides, trot, forward 6.89 |

The best two of each on all four terrains (speed on bumps, cm/s; air on
random / logs / steps), ranked by the mean of the four:

| Linkage | Bracing | Timing | Direction | Waves | Random | Logs | Steps | Mean | Air |
|---------|---------|--------|-----------|-------|--------|------|-------|------|-----|
| Klann | own | trot | reversed | 8.03 | 8.49 | 7.24 | 8.30 | 8.01 | 2 / 1 / 0 |
| Klann | own | sides | reversed | 7.88 | 8.40 | 7.39 | 8.06 | 7.93 | 2 / 1 / 0 |
| Spears lift 44 | diagonal | trot | forward | 7.95 | 7.37 | 6.44 | 6.65 | 7.10 | 7 / 7 / 6 |
| Spears lift 44 | diagonal | trot | reversed | 8.38 | 7.89 | 3.93 | 6.98 | 6.79 | 5 / 15 / 6 |
| Jansen | own | trot | reversed | 7.76 | 8.91 | 3.33 | 7.02 | 6.76 | 1 / 0 / 0 |
| Spears 4-bar | own | trot | reversed | 7.42 | 7.82 | 5.38 | 5.50 | 6.53 | 3 / 1 / 1 |
| Spears lift 53 | guides | trot | forward | 7.22 | 7.07 | 5.29 | 6.03 | 6.40 | 2 / 4 / 2 |
| Spears 4-bar | own | sides | reversed | 7.00 | 7.84 | 4.73 | 5.43 | 6.25 | 2 / 1 / 1 |
| Chebyshev-Spears | diagonal | trot | reversed | 8.53 | 8.13 | 3.17 | 5.06 | 6.22 | 9 / 17 / 9 |
| Spears lift 53 | diagonal | trot | forward | 7.39 | 6.96 | 4.07 | 5.99 | 6.10 | 12 / 17 / 15 |
| Hoecken-Spears long-stance | diagonal | trot | reversed | 8.16 | 7.48 | 3.42 | 5.19 | 6.06 | 16 / 23 / 19 |
| Hoecken-Spears 4-bar | diagonal | trot | reversed | 8.12 | 7.78 | 3.17 | 4.91 | 5.99 | 6 / 13 / 6 |
| Hoecken-Spears 4-bar | plates | sides | reversed | 7.60 | 7.21 | 3.01 | 5.70 | 5.88 | 6 / 14 / 5 |
| Jansen | own | sides | reversed | 6.60 | 7.27 | 3.10 | 6.22 | 5.80 | 1 / 0 / 0 |
| Hoecken-Spears long-stance | diagonal | trot | forward | 8.33 | 7.57 | 3.67 | 3.60 | 5.79 | 18 / 25 / 24 |
| Chebyshev-Spears | diagonal | trot | forward | 7.96 | 7.81 | 3.23 | 4.09 | 5.77 | 9 / 16 / 15 |
| Hoecken 4-bar | guides | trot | reversed | 7.68 | 7.05 | 2.56 | 5.17 | 5.61 | 3 / 6 / 2 |
| Hoecken-Spears slider | guides | trot | reversed | 7.48 | 7.49 | 2.63 | 4.67 | 5.57 | 7 / 17 / 8 |
| Hoecken 4-bar | guides | trot | forward | 7.42 | 7.30 | 2.75 | 4.69 | 5.54 | 3 / 6 / 4 |
| Hoecken-Spears slider | guides | trot | forward | 7.52 | 7.46 | 2.45 | 4.39 | 5.46 | 8 / 19 / 10 |
| Hoecken slider | guides | trot | reversed | 7.14 | 7.13 | 2.52 | 4.73 | 5.38 | 3 / 6 / 1 |
| Chebyshev | guides | trot | reversed | 7.45 | 7.19 | 2.50 | 4.25 | 5.35 | 2 / 5 / 1 |
| Hoecken slider | guides | trot | forward | 6.89 | 7.36 | 2.59 | 4.24 | 5.27 | 2 / 4 / 3 |
| Chebyshev | guides | trot | forward | 7.13 | 7.42 | 2.55 | 3.95 | 5.26 | 2 / 3 / 2 |

- Trot is the best timing for every linkage, and reversed the best
  direction for most; Spears lift 44 and 53 do best forward over all
  four terrains.
- The waves alone mislead: Chebyshev-Spears is best there and sixth of
  the linkages over all four, held back by logs and steps.
- On logs, the hard one, foot lift decides: Chebyshev-Spears (26% lift)
  makes 3.17 cm/s, Spears lift 44 (44%) 6.44, second only to Klann.
  Spears lift 53 lifts more and does no better.
- The Spears diagonal builds come off the ground on logs (7-25% of the
  time); Klann, Jansen and Spears 4-bar stay down.
- The diagonal builds of Spears lift 44 and 53 and the plated lift 53
  have their link planes closer together than their files' (see
  `spears-lift-walkers.lua`): with the files' spacing, their bodies had
  come out less than nothing deep (their legs crossing in the middle)
  to stand on the 38 cm stance. Their parts don't touch each other
  walking with the closer spacing.
- The diagonal builds have both braces over the body (Braces clear the
  bumps, above); with the bottom brace lifted through the body, as at
  first, they had done much the same (Chebyshev-Spears diag 6.12 over
  the four, now 6.22; Spears lift 44 diag 7.15, now 7.10).

`test-square.lua` shows the best of each walking on each terrain.

### Hoecken-Spears 4-bar

The true 4-bar Hoecken linkage and the Chebyshev lambda are the same
kind of linkage -- a crank, a rocker, and a coupler carried straight on
past the rocker joint to the foot -- with slightly different
proportions (crank 1: ground 2.09 against 2, coupler and rocker 2.55
against 2.5). Chebyshev-Spears came from the lambda by shortening the
ground link (to 1.33), lengthening the coupler and rocker (to 3.06),
turning the leg 90 degrees off the coupler (the same length as the
coupler) and tilting the ground link 45 degrees. The same changes made
to Hoecken give the Hoecken-Spears 4-bar: ground 1.39, coupler, rocker
and leg 3.11, the leg at 90 degrees, the ground link at 45 degrees
(foot path: duty 79%, flatness 4.9%, mono 1.000, lift 27.7%, against
Chebyshev-Spears' 83%, 4.7%, 0.981, 26.4%). It is built by
Chebyshev-Spears' own file with those lengths, on the same chassis.

On the test track it keeps 78% of its flat speed on bumps, as
Chebyshev-Spears does, and more of it on the longest, highest bumps (32%
against 20% on 6 cm x 22 cm); from Hoecken (67%) it is the fourth pair
in which the version with more lift does better.

A search of the same family for more lift found linkages with longer
stances -- one with duty 94%, flatness 5.8% and lift 33% -- but these
come very close to locking: in that one, the crank pin passes within
0.07 crank lengths of the rocker's pivot, leaving the coupler and rocker
within 1.4 degrees of a straight line (Chebyshev-Spears: 6.3 degrees).
Built, its cranks jam. Kept at least as far from locking as
Chebyshev-Spears, the search finds at most duty 89%, flatness 5.2% and
lift 29%, or duty 85%, flatness 5.6% and lift 32%.

The first of those is the Hoecken-Spears long-stance (found while
looking for a Hoecken-Spears with more lift): crank 1, ground 1.16,
coupler, rocker and leg 1.50, the leg 39.8 degrees off the coupler, the
ground link at 20.1 degrees -- a much shorter coupler and rocker than
Chebyshev-Spears' 3.06. Built, its foot path comes out at duty 85%,
flatness 5.0%, lift 28.7% (the calculation: 89%, 5.2%, 29.4%). On the
test track it keeps 66% of its flat speed on bumps: more lift than
Chebyshev-Spears, but less of its speed kept, about as much as Hoecken.

### Why the Spears changes work

Every Spears change raised three things about the foot's path at once:
its duty (the share of each turn it is down: Chebyshev 72% -> 84%,
Hoecken 4-bar 67% -> 79%), its lift, and how high the foot is at the
front and back ends of its swing (Chebyshev 0.10 -> 0.17 of the stride
in the front tenth of the stride, Hoecken 4-bar 0.12 -> 0.19). Across
the twelve walkers, duty (correlation 0.65) and the front height (0.61)
go with the share kept, lift (0.10) doesn't; but across different
mechanisms these come mixed together.

To separate them, linkages of Chebyshev-Spears' kind (its file, with
other link lengths and a leg of its own length and angle) were found
that change one thing and hold the others at Chebyshev-Spears' values,
no nearer locking than it is, and built on the same chassis
(`foot-path-variants.lua`; 8 starts each, about +-0.5 points):

| Walker | Duty | Lift | Front height | Kept |
|--------|------|------|--------------|------|
| Chebyshev-Spears | 84% | 26.4% | 0.174 | 78.0% |
| V duty 72        | 72% | 26.4% | 0.178 | 79.0% |
| V front low      | 84% | 25.3% | 0.150 | 71.2% |
| V front high     | 83% | 29.0% | 0.216 | 82.2% |

(Front height: the highest the foot gets in the front tenth of its
stride, where it comes down, as a share of the stride; measured on the
builds.) Duty makes no difference. The height of the foot as it comes
down does: the Spears changes lift the foot steeply and bring it down
steeply, so it is already high when it meets the face of a bump, where
the originals' rounded arches meet it low. In this family the front
height can't be raised much without raising the lift too (V front high
has both), but V front low loses 7 points for 1 point less lift, which
lift alone doesn't explain. The Spears 4-bar has the lowest front
height of all (0.06) and is last; Jansen comes down high (0.15) but
lifts off low (0.09) and drags its back foot.

Running a walker in reverse (`REVERSE`) is a cleaner test still: the
same machine, its feet going round the same paths the other way, so the
end of the swing it came down at becomes the one it lifts off at. The
linkages whose paths aren't the same at both ends, on the test track
(share kept, 4 starts each), with the angle of the foot's path over its
last 0.06 of a stride before it touches down (degrees from level; 90 is
straight down):

| Walker | Forward | Reversed | Coming down at, forward -> reversed |
|--------|---------|----------|---------------------------------------|
| Spears 4-bar          | 49% | 80% | 9 -> 23  |
| Klann                 | 78% | 87% | 53 -> 65 |
| V front high          | 83% | 90% | 16 -> 22 |
| Jansen                | 61% | 63% | 2 -> 19  |
| V front low           | 72% | 68% | 16 -> 13 |
| Chebyshev-Spears diag | 91% | 82% | 13 -> 13 |

Reversed, the Spears 4-bar goes from last to among the best; it comes
down more than twice as steeply. In five of the six the walker does
better the way its foot comes down more steeply; Chebyshev-Spears diag's
foot comes down the same both ways, and it does worse reversed for some
other reason (its braces, perhaps). V front high does better reversed
though its foot is then lower at the front (0.18 against 0.22): the
angle it comes down at matters more than how high it is a little before.
Across all the walkers and both directions the angle goes with the share
kept less closely (rank correlation 0.49): Klann comes down by far the
most steeply (53 degrees) without being the best.

The Spears 4-bar's legs are also timed unusually: its cranks at 0, 225,
180 and 225 degrees (found by an optimizer in its own file), where the
others step both legs on a side together or diagonal pairs together.
Running it backward also changes that timing (the back legs then come
135 degrees after the first leg, not 225). `GAIT` sets every leg's phase
on the walkers without braces locking their legs together (Jansen,
Klann, Spears 4-bar; the braced walkers' plates and bars only work with
their own timing). On the test track (share kept; speed on bumps, cm/s;
the Spears timing put on Jansen and Klann both ways round, front legs
first or back legs first, the better shown):

| Walker | Timing | Forward | Reversed |
|--------|--------|---------|----------|
| Spears 4-bar | its own, 0/225/180/225 | 49%, 4.5 | 80%, 7.1 |
| Spears 4-bar | 0/0/180/180            | 59%, 5.1 | 80%, 7.3 |
| Klann        | 0/0/180/180            | 78%, 6.8 | 87%, 7.7 |
| Klann        | Spears'                | 70%, 5.7 | 80%, 7.7 |
| Jansen       | 0/0/180/180            | 61%, 5.6 | 63%, 6.0 |
| Jansen       | Spears'                | 59%, 3.2 | 72%, 4.7 |

It was the direction, not the timing, that lifted the Spears 4-bar:
reversed, it does as well with either timing. The Spears timing didn't
help Jansen or Klann: their flat-ground speed fell (Jansen to 4.9-6.4
cm/s, Klann as low as 3.9), so a share kept that looks similar hides a
slower walker; on bumps neither got faster. (Their slower flat speed is
legs fighting each other, not the timing changing how far a turn should
carry them, which stays within 10%.)

The diag walkers beat their side-braced versions by 15-17 points
(Chebyshev-Spears diag 91% against 77%, Chebyshev diag 74% against 59%),
but there the gait (diagonal legs together, a trot) and the bracing come
together. The unbraced walkers separate them: with `GAIT = { 0, 180, 180,
0 }` they trot with no braces at all (share kept; speed on bumps, cm/s):

| Walker | Timing | Forward | Reversed |
|--------|--------|---------|----------|
| Spears 4-bar | 0/0/180/180 (sides) | 59%, 5.1 | 80%, 7.3 |
| Spears 4-bar | trot                | 69%, 6.1 | 99%, 7.4 |
| Klann        | sides               | 78%, 6.8 | 87%, 7.7 |
| Klann        | trot                | 81%, 7.2 | 88%, 7.9 |
| Jansen       | sides               | 61%, 5.6 | 63%, 6.0 |
| Jansen       | trot                | 67%, 6.6 | 87%, 7.7 |

Trotting helps all three, both ways round: it is the gait, not the
braces. Jansen gains most (reversed, from 6.0 to 7.7 cm/s on bumps). The
reversed, trotting Spears 4-bar keeps 99% of its speed, though partly
because it is slower on flat ground (7.5 cm/s); on bumps it makes 7.4.

The side-plated walkers can only step both legs on a side together: the
plate locks them. It also holds each leg at its angle to the body (two
legs welded to one plate, each hinged to a coupler moving in step with
the other's, can only move without turning); without it, a slider's leg
swings freely and its stride triples, so a walker with its plates simply
left off is a different machine. `UNBRACED = true` leaves the plates off
and holds each leg at its angle to the body by itself (a guide), so the
legs can take any `GAIT`. With side timing the guided walkers match the
plated ones closely (the Hoecken-Spears slider least well), which checks
the guides; trotting (`GAIT = { 0, 180, 180, 0 }`) then helps all four
Hoecken walkers and Chebyshev (a lot), and Chebyshev-Spears and the
long-stance walker little or not at all (share kept; speed on bumps,
cm/s; 4 starts):

| Walker | Plates (sides) | Guides, sides | Guides, trot |
|--------|----------------|---------------|--------------|
| Hoecken-Spears 4-bar  | 80%, 7.1 | 78%, 7.0 | 81%, 7.4 |
| Hoecken 4-bar         | 80%, 6.7 | 78%, 6.5 | 79%, 7.1 |
| Hoecken-Spears slider | 84%, 7.0 | 73%, 6.2 | 82%, 7.1 |
| Hoecken slider        | 68%, 5.1 | 65%, 4.9 | 81%, 7.1 |
| Chebyshev-Spears      | 77%, 6.9 | 70%, 6.4 | 68%, 6.4 |
| Hoecken-Spears long-stance | 73%, 6.2 | 68%, 5.9 | 68%, 6.1 |
| Chebyshev             | 59%, 4.4 | 52%, 3.8 | 72%, 6.4 |

Trotting, the Spears versions keep their lead only narrowly: the 4-bars
7.4 against 7.1 cm/s on bumps, the sliders level at 7.1. For
Chebyshev-Spears and the long-stance walker the guides fall short of the
plates even with side timing (70% against 77%, 68% against 73%), so
their trotting results may understate them; Chebyshev-Spears diag, which
trots with its own braces, is the fairer trotting version of that
linkage.

### Trotting the Hoecken walkers

The 4-bars can also be built the way the diag walkers are, with braces
joining diagonal legs (`trotting-walkers.lua`: the diag walkers' files
with Hoecken's proportions; the diag bracing tilts the legs slightly, so
their lift comes out a little lower, as for the diag walkers). Built so:

| Walker | Plates (sides) | Diagonal braces, trotting |
|--------|----------------|---------------------------|
| Hoecken-Spears 4-bar | 80%, 7.1 | 88%, 7.7 |
| Hoecken 4-bar        | 80%, 6.7 | 77%, 6.6 |

Diagonal bars on the sliders were tried too, and dropped: welded across
the body they shook the walker, and its speed swung from 2.4 to 14.6
cm/s with nothing changed but the bars' weight. The guides above do the
same job without the shaking.

Not explained yet: the Hoecken-Spears long-stance comes down as high as
Chebyshev-Spears (0.19) with more lift and duty, but keeps less (73%);
its foot swings forward in about 0.2 s, the quickest of all.

### Hinged feet (ANKLES)

With the current setup, each walker in its best version (above), ankles
help no one clearly and hurt most (speed on bumps, cm/s, 4 starts):

| Walker | Welded | Ankles |
|--------|--------|--------|
| Hoecken-Spears 4-bar (diag) | 7.7 | 7.8 |
| Chebyshev-Spears diag       | 7.6 | 7.6 |
| Klann (reverse, trot)       | 7.9 | 7.2 |
| Hoecken slider (trot)       | 7.1 | 7.0 |
| Spears 4-bar (reverse, trot)| 7.4 | 6.9 |
| Chebyshev-Spears            | 6.9 | 6.7 |
| Hoecken 4-bar (trot)        | 7.1 | 6.7 |
| Hoecken-Spears slider (trot)| 7.1 | 6.6 |
| Jansen (reverse, trot)      | 7.7 | 6.6 |
| Hoecken-Spears long-stance  | 6.2 | 6.1 |
| Chebyshev diag              | 6.4 | 5.8 |
| Chebyshev                   | 4.4 | 4.4 |

The walkers that gained most from reversing and trotting lose most: a
hinged foot rocks back as the leg drives it, undoing some of the steep
touchdown. So `ANKLES` stays off. The earlier test, below, was made with
gravity 20 (when the high-lift walkers floated) and every crank at 2.6
rad/s.

The 2-leg Spears' own files hinge each foot to its leg about the
side-to-side axis, like an ankle (up to 90 degrees either way, damped), so
it can tip to lie flat on the ground; every other walker's feet are
welded to its legs. `ANKLES = true` gives every walker those ankles.
Share of flat-ground speed kept (mean over the 9 bump conditions, 4
starts each), at gravity 70:

| Walker                 | Welded | Ankles | On bumps, cm/s (welded -> ankles) |
|------------------------|--------|--------|-----------------------------------|
| Chebyshev-Spears       | 75%    | 77%    | 5.9 -> 5.9 |
| Hoecken 4-bar          | 61%    | 71%    | 6.3 -> 7.2 |
| Chebyshev-Spears diag  | 62%    | 66%    | 4.4 -> 4.5 |
| Spears 4-bar           | 53%    | 63%    | 6.8 -> 6.8 |
| Jansen                 | 36%    | 61%    | 1.7 -> 1.9 |
| Hoecken-Spears slider  | 57%    | 49%    | 3.9 -> 3.3 |
| Chebyshev              | 30%    | 38%    | 2.8 -> 3.5 |
| Hoecken slider         | 40%    | 37%    | 3.7 -> 3.4 |
| Chebyshev diag         | 17%    | 16%    | 1.4 -> 1.5 |

(At gravity 20 the Spears 4-bar went from 37% to 68% with ankles and
Jansen from 65% to 81%, while the pendant walkers lost ground.) Ankles
help most the walkers whose feet hang from a link that turns a lot during
a step -- the Spears 4-bar's leg-arm, Jansen's triangles -- whose welded
feet meet the ground tilted. With ankles the pairs still favour the
version with more lift: Chebyshev 38% -> Chebyshev-Spears 77%, Chebyshev
diag 16% -> Chebyshev-Spears diag 66%, Hoecken slider 37% ->
Hoecken-Spears slider 49%.

## Test square

`test-square.lua`: the test track on a 7 m square, for watching the best
version of each walker (The factorial runs) on each kind of ground. Click
the 3D view, then Tab and Shift+Tab put the next or previous walker on
it, built, timed and turned its own best way, and 1, 2, 3 and 4 change
the ground (waves, random, logs, steps). The status line at the bottom
shows its speed so far and how much of the time it has been off the
ground (its lowest part more than 0.5 cm up); its body turns red
whenever it is. The TerrainHeight and BumpLength sliders build it again
(it starts at 4 cm and 15 cm).

`test-square-all.lua` is the same square, but Tab goes through all 19
builds, each as built (its own timing, forward, its own crank speed), for
looking them over. `test-square-soft.lua` is that, with every foot on a soft-spring
ankle (`ANKLE_SPRING`, below). `test-square-yaw.lua` is that with the body free to pitch and
roll (`YAW_DAMP`, below), then the builds that can trot, trotting.

## Telling the walkers apart

Each walker's body (and the plates or bars between its legs) is painted
its linkage's colour, the rest of it grey, and its code is written on
top (`MARKS = false`: each walker as its own file paints it). The code
is its linkage's inventor(s), a space, and its number of bars (S added
for a slider):

- inventors: J Jansen, K Klann, C Chebyshev, H Hoecken, S Spears; "-S"
  after a letter, a linkage Spears changed (C-S: Chebyshev, changed by
  Spears), which also gets a gold rim round its body
- bars: as counted in the linkage reference (a four-bar counts its
  ground link; a slider counts 2 bars and the slider)
- L after the bars: the long-stance version
- a line across the body: a diag build -- the same linkage, braced
  diagonally and walking with its diagonal legs together

| Walker                     | Code   | Colour  | Gold rim | Line across |
|----------------------------|--------|---------|----------|-------------|
| Jansen                     | J 8    | red     |          |             |
| Klann                      | K 6    | purple  |          |             |
| Chebyshev                  | C 4    | blue    |          |             |
| Chebyshev diag             | C 4    | blue    |          | yes         |
| Chebyshev-Spears           | C-S 4  | blue    | yes      |             |
| Chebyshev-Spears diag      | C-S 4  | blue    | yes      | yes         |
| Hoecken 4-bar              | H 4    | magenta |          |             |
| Hoecken-Spears 4-bar       | H-S 4  | magenta | yes      |             |
| Hoecken-Spears long-stance | H-S 4L | magenta | yes      |             |
| Hoecken slider             | H 2S   | white   |          |             |
| Hoecken-Spears slider      | H-S 2S | white   | yes      |             |
| Spears 4-bar               | S 4    | gold    |          |             |

The code and walker are also in the help text and shown when the
pointer rests on a walker.

## Keys

Click the 3D view first so it has keyboard focus.

| Key       | What it does |
|-----------|--------------|
| Tab       | Follow the next walker (on the test track: put the next walker on the track) |
| Shift+Tab | Follow the one before (on the test track: put the one before on it) |
| 1 2 3 4   | On the test track (and test square): the ground -- waves, random, logs, steps (built again) |
| O         | Look over the whole room |
| T         | Clear the trails |
| Mouse     | Turn and zoom the view (it keeps following) |

Rest the pointer on a walker, or on a trail, to see whose it is, how far
it has gone, its average speed and how often it has turned or been
stood up.

## Slider

| Slider        | Range     | What it does |
|---------------|-----------|--------------|
| TerrainHeight | 0 to 8 cm | How high the bumps are. The room is built again, every walker back at its start, when you let go. |
| BumpLength    | 11 to 44 cm | How long they are (every stride is 15 cm). The default, 22, gives rolling hills; shorter bumps are obstacles. The room is built again when you let go; short bumps need a finer terrain (four times the triangles at 11 cm), which takes about 5 s to build and is slower to draw. |

The point of the room: raise the bumps until some walkers can't cover
ground any more.

## Trails

| Walker                 | Trail    |
|------------------------|----------|
| Jansen                 | red      |
| Klann                  | orange   |
| Chebyshev              | yellow   |
| Chebyshev diag         | white    |
| Chebyshev-Spears       | black    |
| Chebyshev-Spears diag  | cyan     |
| Hoecken 4-bar          | blue     |
| Hoecken slider         | purple   |
| Hoecken-Spears slider  | pink     |
| Spears 4-bar           | maroon   |
| Hoecken-Spears 4-bar  | teal     |
| Hoecken-Spears long-stance | lavender |
| Spears 2-leg           | navy (with `TWO_LEGS`) |
| Spears 2-leg balanced  | olive (with `TWO_LEGS`) |

## Settings for a launcher

A script that sets these globals and then runs `walker-room.lua` changes
the room: `STRIDE` (cm, 15),
`GRAVITY` (cm/s^2, 70), `SAME_BODY` (false: each walker's own body
weight), `BAR_MASS` ({ density = 0.18, bolt = 0.15 }: every bar weighed
by its length and joints; false: each file's own), `BODY_MASS` (40),
`TOTAL_MASS` (100, with `BAR_MASS = false`), `BODY_BOX` (cm, {40, 3, 30}),
`DIAG_GIVE` (degrees, 0: how far a diag build's braces may turn on the
legs), `DIAG_ARCH` (true: a diag build's braces both over its body, one
arched; false: its bottom brace lifted by `BRACE_CLEARANCE`, through its
body), `CRANK_SCALE` (a walker's crank speed times this: a number, or a
table by name), `VIEWS` and `VIEW` (the test track's list of walkers to
Tab through, each set its own way: see `test-square.lua`), `MOTOR_STRENGTH` (10;
false: each walker's own file's motors), `SOLVER_ITERATIONS` (40; false:
Bullet's default 10), `WIDE` (true; false: a 30-31 cm stance), `FLAT_SPEED` (cm/s, 9), `CRANK` (rad/s:
every walker's crank at that speed instead), `TWO_LEGS` (true: the 2-leg
Spears too), `BUMP` (starting bump length, cm, 22), `WALKERS_DIR` (where the builds are,
`../Walkers_For_Room/`), `ARENA` (side, cm, 1000), `CELL` (terrain cell, cm;
by default it follows the bump length), `AMP`
(starting bump height, cm, 1), `SEED` (starting headings and turns, 1),
`ONLY` (build just the walker of that name), `FOOT_LENGTH`, `FOOT_WIDTH`,
`FOOT_THICK` (cm: 8, 12, 0.5) and `FOOT_MASS` (1.5), `SAME_FEET` (false:
each walker keeps its own file's feet), `LOCK_CRANKS` (false: the cranks
run free, as in the standalone files), `ANKLES` (true: every walker's
feet hinged like ankles; Walker Room1 has them welded), `ANKLE_SPRING`
({ stiffness =, damping = }: ankles as `ANKLES`, each foot also held level
to the body by an angular spring about the ankle's axis, as a parallel link
would hold it, so it swings and lands level but can rock on a bump; the
ankle's +-90 degree limit, which counts from the leg link and held a level
foot under a steep link at its stop, is lifted; the soft one tried is
{ stiffness = 3000, damping = 300 }), `FOOT_TIPS` ({ length =, angle = }, cm
and degrees: both ends of every foot turned up, the foot as long, wide and
heavy in all), `FOOT_ROD` (r, cm: every foot a round rod r in radius across
the walk), `FOOT_POINT` (r, cm: no foot, each leg ending in a ball r in
radius; each body widened so the outer edges of the points are as far
apart as a flat foot's were), `BODY_ANG_DAMP` (0-1: the body's turning
damped this much about every axis, instead of its file's 1.0, which stops
it pitching and rolling as well as turning off course), `YAW_DAMP` (0-1:
the body's turning about the vertical damped this much each frame, its
pitch and roll left free; with it a walker standing on one side's feet
tips toward the lifted side, as a four-legged walker would, and the
trotting walkers keep going), `BRACE_CLEARANCE` (cm, 7: braces at
least that far above flat ground; false: as built), `EXTRA_WALKERS` (more
walkers, as in `foot-path-variants.lua`), `TERRAIN` ("waves", "random", "logs" or
"steps"; `TERRAIN_SEED` picks the landscape, default `SEED`), `REVERSE` (true: every walker's cranks run
backward, so it walks the other way; or a table of names), `GAIT` (four crank
phases, degrees, for Jansen, Klann and Spears 4-bar: see above), `UNBRACED` (true or a table of
names: the side plates left off and each leg held at its angle by a
guide, so `GAIT` applies to those walkers too -- Chebyshev, Chebyshev-Spears,
the Hoecken walkers and Hoecken-Spears 4-bars and sliders), and the trotting Hoecken
4-bars in `trotting-walkers.lua`.
