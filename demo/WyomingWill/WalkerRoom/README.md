# Walker room

Eleven walkers on one meadow -- ten of WyomingWill's and the
Hoeckens-Spears 4-bar (below) -- all four-legged, each scaled
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
  | Hoeckens-Spears 4-bar  | 2.98 | 8.8 |
  | Chebyshev diag         | 2.83 | 8.8 |
  | Hoecken-Spears slider  | 3.32 | 8.6 |
  | Hoecken                | 2.23 | 8.4 |
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
  the middles of its front and back feet's paths); all but Jansen and
  Klann (whose width is fixed) the same side-to-side width (30 cm, outer
  foot edge to outer foot edge). This uses each file's own leg-spacing
  and body-depth options and the room's `bodyRaise` option, none of
  which change its foot path.
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
| Motor strength for the walker's weight | 35 times apart: 1.7 (Chebyshev diag) to 59 (Spears 4-bar), in units of weight x stride |
| Body | Each file's own box and weight (7 to 220) |
| Bracing between the legs | Side plates (Chebyshev, Hoecken, the sliders), diagonal braces (the diag walkers), none (Spears 4-bar, Jansen, Klann) |
| Link weights, damping, foot friction | Each file's own (foot friction 0.9 for Jansen and Klann, 0.8 for the rest) |

Progress in the full room over 3 minutes (cm/s, measured in 5 s steps,
so rocking in place doesn't count as getting anywhere; one run each,
with avoidance turns, so a few tenths either way mean little), on flat
ground and on short bumps (TerrainHeight 4 cm, BumpLength 11 cm):

| Walker                 | Flat | Short bumps | Kept |
|------------------------|------|-------------|------|
| Chebyshev-Spears       | 8.84 | 7.87        | 89%  |
| Hoecken-Spears slider  | 8.12 | 7.18        | 88%  |
| Chebyshev-Spears diag  | 8.53 | 7.28        | 85%  |
| Hoecken                | 7.96 | 5.70        | 72%  |
| Hoecken slider         | 7.00 | 4.20        | 60%  |
| Spears 4-bar           | 8.35 | 4.74        | 57%  |
| Klann                  | 7.38 | 2.70        | 37%  |
| Chebyshev              | 7.24 | 2.29        | 32%  |
| Jansen                 | 8.92 | 1.80        | 20%  |
| Chebyshev diag         | 8.45 | 1.23        | 15%  |

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
stride; measured on the builds, as the linkage reference measures it)
and its mean speed over all the bumps:

| Walker                 | Lift | 2/11 | 2/15 | 2/22 | 4/11 | 4/15 | 4/22 | 6/11 | 6/15 | 6/22 | Mean | On bumps, cm/s |
|------------------------|------|------|------|------|------|------|------|------|------|------|------|----------------|
| Chebyshev-Spears       | 26%  | 97%  | 99%  | 94%  | 85%  | 94%  | 75%  | 63%  | 72%  | 20%  | 78%  | 7.1 |
| Hoeckens-Spears 4-bar  | 28%  | 93%  | 97%  | 94%  | 84%  | 91%  | 77%  | 64%  | 74%  | 32%  | 78%  | 6.9 |
| Chebyshev-Spears diag  | 24%  | 91%  | 95%  | 87%  | 89%  | 87%  | 22%  | 83%  | 43%  | 10%  | 67%  | 6.1 |
| Hoecken                | 17%  | 85%  | 88%  | 84%  | 71%  | 75%  | 55%  | 50%  | 65%  | 27%  | 67%  | 5.6 |
| Hoecken-Spears slider  | 28%  | 89%  | 95%  | 83%  | 77%  | 87%  | 32%  | 43%  | 78%  | 3%   | 65%  | 5.6 |
| Klann                  | 44%  | 89%  | 82%  | 79%  | 76%  | 73%  | 23%  | 46%  | 58%  | 10%  | 59%  | 4.6 |
| Jansen                 | 28%  | 88%  | 92%  | 90%  | 48%  | 41%  | 57%  | 29%  | 33%  | 14%  | 55%  | 5.0 |
| Spears 4-bar           | 28%  | 71%  | 75%  | 73%  | 59%  | 60%  | 11%  | 47%  | 53%  | 3%   | 50%  | 4.5 |
| Hoecken slider         | 21%  | 68%  | 79%  | 72%  | 51%  | 44%  | 25%  | 5%   | 16%  | 8%   | 41%  | 3.0 |
| Chebyshev              | 16%  | 50%  | 68%  | 59%  | 27%  | 26%  | 18%  | 7%   | 3%   | 8%   | 30%  | 2.3 |
| Chebyshev diag         | 14%  | 55%  | 34%  | 24%  | 37%  | 14%  | 5%   | 9%   | 7%   | 4%   | 21%  | 1.8 |

The cleanest comparisons are the three pairs where the Spears version is
the same mechanism with more lift, on the same chassis and feet:

| Pair (lift)                                         | Now        | Gravity 70, same crank | Room1 (gravity 20) |
|-----------------------------------------------------|------------|------------|--------------------|
| Chebyshev (16%) -> Chebyshev-Spears (26%)           | 30% -> 78% | 30% -> 75% | 63% -> 88% |
| Chebyshev diag (14%) -> Chebyshev-Spears diag (24%) | 21% -> 67% | 17% -> 62% | 71% -> 77% |
| Hoecken slider (21%) -> Hoecken-Spears slider (28%) | 41% -> 65% | 40% -> 57% | 69% -> 80% |
| Hoecken (17%) -> Hoeckens-Spears 4-bar (28%)        | 67% -> 78% | --         | --         |

In all three the version with more lift keeps more of its speed, and
each pair now walks with the same gait. (Chebyshev-Spears' own file has
its sides a quarter turn apart; here they are opposite, as Chebyshev's
are. That changed nothing: 78% both ways.) Their bodies and motor
strengths still differ (see Not the same yet, above).
Hoecken, with little lift, does as well as the second-best Spears
walker; Chebyshev, nearly the same linkage, does far worse -- its
cranks slow down on bumps and its legs are pulled out of step, and a
lighter body, stronger motors or a higher side plate don't change that,
so the cause is still unknown. Long, high bumps (22 cm long, 6 cm high:
steep hills) stop nearly everyone. Four starts per condition is few:
differences of a few points mean little.

### Hoeckens-Spears 4-bar

The true 4-bar Hoeckens linkage and the Chebyshev lambda are the same
kind of linkage -- a crank, a rocker, and a coupler carried straight on
past the rocker joint to the foot -- with slightly different
proportions (crank 1: ground 2.09 against 2, coupler and rocker 2.55
against 2.5). Chebyshev-Spears came from the lambda by shortening the
ground link (to 1.33), lengthening the coupler and rocker (to 3.06),
turning the leg 90 degrees off the coupler (the same length as the
coupler) and tilting the ground link 45 degrees. The same changes made
to Hoeckens give the Hoeckens-Spears 4-bar: ground 1.39, coupler, rocker
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
| Hoecken                | 61%    | 71%    | 6.3 -> 7.2 |
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
| Hoecken                | blue     |
| Hoecken slider         | purple   |
| Hoecken-Spears slider  | pink     |
| Spears 4-bar           | maroon   |
| Hoeckens-Spears 4-bar  | teal     |
| Spears 2-leg           | lavender (with `TWO_LEGS`) |
| Spears 2-leg balanced  | navy (with `TWO_LEGS`) |

## Settings for a launcher

A script that sets these globals and then runs `walker-room.lua` changes
the room: `STRIDE` (cm, 15),
`GRAVITY` (cm/s^2, 70), `FLAT_SPEED` (cm/s, 9), `CRANK` (rad/s:
every walker's crank at that speed instead), `TWO_LEGS` (true: the 2-leg
Spears too), `BUMP` (starting bump length, cm, 22), `WALKERS_DIR` (where the builds are,
`../Walkers_For_Room/`), `ARENA` (side, cm, 1000), `CELL` (terrain cell, cm;
by default it follows the bump length), `AMP`
(starting bump height, cm, 1), `SEED` (starting headings and turns, 1),
`ONLY` (build just the walker of that name), `FOOT_LENGTH`, `FOOT_WIDTH`,
`FOOT_THICK` (cm: 8, 12, 0.5) and `FOOT_MASS` (1.5), `SAME_FEET` (false:
each walker keeps its own file's feet), `LOCK_CRANKS` (false: the cranks
run free, as in the standalone files), `ANKLES` (true: every walker's
feet hinged like ankles; Walker Room1 has them welded).
