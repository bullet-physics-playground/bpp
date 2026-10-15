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

## A fair comparison

The aim: every walker the same in everything but its linkage, so that on
flat ground they all go the same speed, and on bumps the differences are
the linkages'. A walker that doesn't make the flat-ground speed has
something wrong with its build.

- **Same stride.** Each walker is scaled so its stride -- the length of
  its foot's path, measured with its body held still and its cranks
  turned slowly -- is 15 cm. A bump is then the same obstacle to every
  walker's step, and each foot lifts as high, for its stride, as its
  linkage lifts it (the "lift" of the linkage reference). Measured this
  way, every build's foot path matches its reference linkage's duty,
  lift and flatness, except that the diag walkers' braces hold their
  legs at a slightly different angle (Chebyshev diag: lift 13% against
  16%; Chebyshev-Spears diag: 23-25% against 26%). Their sizes differ as
  a result.
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
  the same body clearance (12 cm: its body's lowest point above flat
  ground) and the same front-to-back spacing of its feet (35 cm, between
  the middles of its front and back feet's paths) and the same
  side-to-side width (38 cm, outer foot edge to outer foot edge, as
  Jansen's own file has it; measured, 38.1 to 38.7). This uses each
  file's own leg-spacing and body-depth options and the room's
  `bodyRaise` option, none of which change its foot path. A walker's
  body width is where its legs are mounted, so the bodies look
  different widths even though the feet stand on the same rectangle.
  `WIDE = false` gives every walker a 30-31 cm stance instead (until
  Walker Room 2, Jansen's feet were 38 cm apart, Klann's 35 and the
  others' about 30).
- **Same feet.** Every walker stands on the same flat feet: 8 cm long
  (along the walk), 12 cm wide, 0.5 cm thick, weighing 1.5. Big feet get
  over bumps by resting on them; small ones have to be lifted over. Their
  own files' feet ranged from 2.6 cm long (Chebyshev-Spears diag) to
  12.6 cm (the balanced 2-leg Spears), and Jansen and Klann had none.
- **Cranks in step.** Most walkers have a motor for each crank, and
  nothing kept them in step: Chebyshev's cranks drifted 47 degrees apart
  in 10 s, Jansen's over 1000 degrees in a minute, and Klann ended up
  walking back and forth. Every walker's cranks are now held at the timing
  they were built with, as one motor driving them all through gears would
  hold them (`LOCK_CRANKS`).
- **Same weight.** Every walker weighs 100 in all (`TOTAL_MASS`): its
  body makes up whatever its legs, feet and braces don't (from 38 for
  Jansen, whose legs are heaviest, to 84 for Chebyshev diag), and turns
  as a 40 x 3 x 30 cm box of that weight would (`BODY_BOX`). Before,
  walkers weighed from 27 (Hoecken) to 282 (Jansen). Each body keeps its
  own shape for drawing and for touching things; it rides 12 cm up,
  clear of the ground, and its depth sets where the legs are mounted.
  `SAME_BODY = false` gives each walker its own file's body weight again.
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
  where it was, and a diag walker's low bar is moved up. Raised that far,
  the diag bar would cross the circles its own cranks turn in and jam (2.5
  cm/s on flat ground), so it passes the walker's other parts as if built
  in a plane of its own, and still meets the ground. (Hoecken slider's
  plates were already 6.5 cm up; Jansen, Klann and Spears 4-bar have
  none.)
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
| Body shape | Each file's own box (its weight is now the same: see Same weight) |
| Bracing between the legs | Side plates (Chebyshev, Hoecken, the sliders), diagonal braces (the diag walkers), none (Spears 4-bar, Jansen, Klann); all at least 7 cm up now |
| Link weights, damping, foot friction | Each file's own (foot friction 0.9 for Jansen and Klann, 0.8 for the rest) |

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

Not explained yet: the Hoecken-Spears long-stance comes down as high as
Chebyshev-Spears (0.19) with more lift and duty, but keeps less (73%);
its foot swings forward in about 0.2 s, the quickest of all.

### Hinged feet (ANKLES)

(Measured before the crank speeds were set for equal flat speed, with
every crank at 2.6 rad/s.)

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
weight), `TOTAL_MASS` (100), `BODY_BOX` (cm, {40, 3, 30}), `MOTOR_STRENGTH` (10;
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
feet hinged like ankles; Walker Room1 has them welded), `BRACE_CLEARANCE` (cm, 7: braces at
least that far above flat ground; false: as built), `EXTRA_WALKERS` (more
walkers, as in `foot-path-variants.lua`), `REVERSE` (true: every walker's cranks run
backward, so it walks the other way; or a table of names), `GAIT` (four crank
phases, degrees, for Jansen, Klann and Spears 4-bar: see above).
