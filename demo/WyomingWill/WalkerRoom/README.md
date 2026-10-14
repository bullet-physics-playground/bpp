# Walker room

All twelve walkers from `../Walkers/` on one meadow, each scaled to the
same stride, walking freely inside a walled 10 m x 10 m arena. Open
`walker-room.lua`.

Each walker is built by its own `../Walkers_For_Room/<name>_parts.lua`, a
copy of the build its standalone file uses with a few options added (see that
folder's README); the walkers in `../Walkers/` are left as they are. All of
them share one world, one terrain, one gravity and one physics step
(1/960 s). Gravity is 70 cm/s^2; Walker Room1, the version before this
one, used 20 (see Same gravity, below).

## A fair comparison

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
- **Same chassis.** So that only the linkage differs, every four-legged
  walker gets the same body clearance (12 cm: its body's lowest point
  above flat ground), the same front-to-back spacing of its feet (35 cm,
  between the middles of its front and back feet's paths) and the same
  side-to-side width (30 cm, outer foot edge to outer foot edge), using
  its own file's leg-spacing and body-depth options and the room's
  `bodyRaise` option, none of which change its foot path. Jansen and
  Klann get the same clearance, but their rows of legs can't come closer
  than about 1.8 strides without colliding, and their width is fixed;
  the two 2-leg Spears, with a single column of legs, keep their own
  chassis.
- **Same crank speed.** Every crank turns at 2.6 rad/s. Speeds on flat
  ground still differ, by design: a foot covers its stride while it is
  down, a duty's share of each turn, so a walker whose feet never
  slipped would go stride / (duty x turn time) -- faster for a short
  stance. What to compare on bumps is how much of its flat-ground speed
  each walker keeps.
- **Same feet.** Every walker stands on the same flat feet: 8 cm long
  (along the walk), 12 cm wide, 0.5 cm thick, weighing 1.5. Big feet get
  over bumps by resting on them; small ones have to be lifted over. Their
  own files' feet ranged from 2.6 cm long (Chebyshev-Spears diag) to
  12.6 cm (the balanced 2-leg Spears), and Jansen and Klann had none.
  8 cm is the shortest the 2-leg Spears can stand on (on 4 cm feet the
  2-leg one fell and went nowhere); on 2 cm feet several walkers' physics
  failed.
- **Cranks in step.** Most walkers have a motor for each crank, and
  nothing kept them in step: Chebyshev's cranks drifted 47 degrees apart
  in 10 s, Jansen's over 1000 degrees in a minute, and Klann ended up
  walking back and forth. Every walker's cranks are now held at the timing
  they were built with, as one motor driving them all through gears would
  hold them (`LOCK_CRANKS`).
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

The balanced 2-leg Spears' joints are solved with 40 solver iterations,
as its own file does (its notes: at Bullet's default 10 its rocking
roughly doubles); the others keep the default 10 their files use.

Progress in the full room over 3 minutes (cm/s, measured in 5 s steps,
so rocking in place doesn't count as getting anywhere; one run each,
with avoidance turns, so a few tenths either way mean little), on flat
ground and on short bumps (TerrainHeight 4 cm, BumpLength 11 cm):

| Walker                 | Flat | Short bumps | Kept |
|------------------------|------|-------------|------|
| Chebyshev-Spears       | 7.14 | 6.51        | 91%  |
| Chebyshev-Spears diag  | 6.75 | 5.53        | 82%  |
| Hoecken                | 9.25 | 7.08        | 77%  |
| Hoecken-Spears slider  | 6.57 | 4.72        | 72%  |
| Jansen                 | 4.91 | 3.35        | 68%  |
| Spears 4-bar           | 12.09| 7.63        | 63%  |
| Spears 2-leg           | 11.37| 7.01        | 62%  |
| Hoecken slider         | 8.70 | 4.64        | 53%  |
| Chebyshev              | 8.45 | 3.02        | 36%  |
| Chebyshev diag         | 7.63 | 2.10        | 28%  |
| Klann                  | 3.34 | 3.24        | --   |
| Spears 2-leg balanced  | 0.12 | 0.21        | --   |

On the default bumps (22 cm long, a stride and a half) the walkers keep
most of their speed when the bumps are low: those are rolling hills they
walk up and down. Shorter bumps are obstacles a foot has to get over
within a step. Some of the rest isn't the bumps:

- Klann is slow on flat ground too, even with its cranks in step;
  something else about its build is wrong.
- The 2-leg Spears falls over and is stood up again now and then.
- The balanced 2-leg Spears barely moves at this gravity: its
  counterweight hangs only a little above flat ground (its own file's
  design) and drags.

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
columns are bump height / bump length, in cm), at gravity 70 cm/s^2 on
8 cm feet, with the lift of its foot path (how high its foot rises above
its stance, as a share of its stride; measured on the builds, as the
linkage reference measures it), and the mean in Walker Room1 (gravity
20) for comparison:

| Walker                 | Lift | Flat cm/s | 2/11 | 2/15 | 2/22 | 4/11 | 4/15 | 4/22 | 6/11 | 6/15 | 6/22 | Mean | Room1 |
|------------------------|------|-----------|------|------|------|------|------|------|------|------|------|------|-------|
| Chebyshev-Spears       | 26%  | 7.8  | 97%  | 100% | 89%  | 85%  | 89%  | 68%  | 54%  | 81%  | 16%  | 75%  | 88%  |
| Chebyshev-Spears diag  | 24%  | 7.1  | 89%  | 93%  | 78%  | 86%  | 72%  | 20%  | 79%  | 34%  | 5%   | 62%  | 77%  |
| Hoecken                | 17%  | 10.2 | 84%  | 85%  | 85%  | 66%  | 78%  | 59%  | 20%  | 67%  | 9%   | 61%  | 81%  |
| Hoecken-Spears slider  | 28%  | 6.8  | 86%  | 90%  | 79%  | 77%  | 81%  | 20%  | 24%  | 61%  | -5%  | 57%  | 80%  |
| Spears 4-bar           | 28%  | 12.9 | 77%  | 72%  | 68%  | 59%  | 62%  | 27%  | 47%  | 57%  | 6%   | 53%  | 37%  |
| Hoecken slider         | 21%  | 9.1  | 67%  | 75%  | 67%  | 57%  | 62%  | 21%  | 1%   | 10%  | 4%   | 40%  | 69%  |
| Jansen                 | 28%  | 4.7  | 73%  | 54%  | 54%  | 28%  | 62%  | 5%   | 6%   | 29%  | 9%   | 36%  | 65%  |
| Chebyshev              | 16%  | 9.3  | 57%  | 70%  | 51%  | 30%  | 33%  | 17%  | 4%   | 4%   | 6%   | 30%  | 63%  |
| Chebyshev diag         | 14%  | 8.2  | 55%  | 28%  | 22%  | 18%  | 16%  | 4%   | 5%   | 5%   | 4%   | 17%  | 71%  |
| Klann                  | 44%  | 3.8  | 90%  | 73%  | 71%  | 106% | 77%  | 26%  | 83%  | 68%  | 18%  | --   | --   |
| Spears 2-leg balanced  | 32%  | 0.6  | 82%  | 61%  | 81%  | 1%   | 26%  | 48%  | -7%  | 34%  | 42%  | --   | 35%  |
| Spears 2-leg           | 32%  | 12.8 | 24%  | 22%  | 21%  | 3%   | 3%   | 2%   | 7%   | 4%   | 6%   | 10%  | 30%  |

The bumps are harder for every walker at gravity 70 than at 20 (where a
walker thrown up by a bump came down slowly), but much harder for the
walkers with little lift. The cleanest comparisons are the three pairs
where the Spears version is the same mechanism with more lift, on the
same chassis, feet and crank speed:

| Pair (lift)                                         | Gravity 70 | Room1 (gravity 20) |
|-----------------------------------------------------|------------|--------------------|
| Chebyshev (16%) -> Chebyshev-Spears (26%)           | 30% -> 75% | 63% -> 88% |
| Chebyshev diag (14%) -> Chebyshev-Spears diag (24%) | 17% -> 62% | 71% -> 77% |
| Hoecken slider (21%) -> Hoecken-Spears slider (28%) | 40% -> 57% | 69% -> 80% |

In all three the version with more lift keeps more of its speed, and at
gravity 70 by much more. Among the four-legged walkers, the four Spears
linkages and Hoecken are the top five. Lift isn't the whole story:

- Hoecken, with little lift (17%), is third.
- Jansen, with as much lift as the Spears 4-bar, is slow on flat ground
  at this gravity (4.7 cm/s, against 7.1 at 20) and keeps little.
- Klann is still slow on flat ground (3.8 cm/s) with its cranks in step;
  something else about its build is wrong, so its shares mean little.
- The 2-leg Spears are a side experiment: the plain one falls over in
  almost every run (118 times in 40), and the balanced one barely moves
  on flat ground at this gravity (its counterweight drags).
- Long, high bumps (22 cm long, 6 cm high: steep hills) stop nearly
  everyone.

Four starts per condition is few: differences of a few points mean
little. Walker Room1's runs (gravity 20) also had 8 cm feet and cranks
in step; at 4 cm feet the pairs came out the same way (51% -> 83%,
51% -> 61%, 57% -> 64%).

### Hinged feet (ANKLES)

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
| Spears 2-leg           | teal     |
| Spears 2-leg balanced  | lavender |

## Settings for a launcher

A script that sets these globals and then runs `walker-room.lua` changes
the room: `STRIDE` (cm, 15), `CRANK` (crank speed, rad/s, 2.6),
`GRAVITY` (cm/s^2, 70), `BUMP` (starting bump length, cm, 22), `WALKERS_DIR` (where the builds are,
`../Walkers_For_Room/`), `ARENA` (side, cm, 1000), `CELL` (terrain cell, cm;
by default it follows the bump length), `AMP`
(starting bump height, cm, 1), `SEED` (starting headings and turns, 1),
`ONLY` (build just the walker of that name), `FOOT_LENGTH`, `FOOT_WIDTH`,
`FOOT_THICK` (cm: 8, 12, 0.5) and `FOOT_MASS` (1.5), `SAME_FEET` (false:
each walker keeps its own file's feet), `LOCK_CRANKS` (false: the cranks
run free, as in the standalone files), `ANKLES` (true: every walker's
feet hinged like ankles; Walker Room1 has them welded).
