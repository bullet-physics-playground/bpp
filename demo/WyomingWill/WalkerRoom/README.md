# Walker room

All twelve walkers from `../Walkers/` on one meadow, each scaled to the
same stride, walking freely inside a walled 10 m x 10 m arena. Open
`walker-room.lua`.

Each walker is built by its own `../Walkers_For_Room/<name>_parts.lua`, a
copy of the build its standalone file uses with a few options added (see that
folder's README); the walkers in `../Walkers/` are left as they are. All of
them share one world, one terrain, one gravity and one physics step
(1/960 s).

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
  are under 20 cm/s^2 here, each with its motors made stronger or
  weaker by the same factor as its gravity, so it can still lift
  itself.

The balanced 2-leg Spears' joints are solved with 40 solver iterations,
as its own file does (its notes: at Bullet's default 10 its rocking
roughly doubles); the others keep the default 10 their files use.

Progress in the full room over 3 minutes (cm/s, measured in 5 s steps,
so rocking in place doesn't count as getting anywhere; one run each,
with avoidance turns, so a few tenths either way mean little), on flat
ground and on short bumps (TerrainHeight 4 cm, BumpLength 11 cm):

| Walker                 | Flat | Short bumps | Kept |
|------------------------|------|-------------|------|
| Chebyshev-Spears diag  | 5.61 | 5.96        | 106% |
| Hoecken-Spears slider  | 5.98 | 6.13        | 103% |
| Chebyshev-Spears       | 6.75 | 6.83        | 101% |
| Hoecken                | 8.73 | 8.72        | 100% |
| Jansen                 | 6.73 | 5.90        | 88%  |
| Chebyshev diag         | 7.74 | 6.78        | 88%  |
| Spears 2-leg           | 10.45| 8.72        | 83%  |
| Hoecken slider         | 8.91 | 7.02        | 79%  |
| Chebyshev              | 9.54 | 6.95        | 73%  |
| Spears 4-bar           | 13.46| 7.28        | 54%  |
| Spears 2-leg balanced  | 11.03| 4.83        | 44%  |
| Klann                  | 1.21 | 4.17        | --   |

On the default bumps (22 cm long, a stride and a half) the walkers keep
most of their speed even 8 cm high: those are rolling hills they walk up
and down. Shorter bumps are obstacles a foot has to get over within a
step. Some of the rest isn't the bumps:

- Klann gets almost nowhere on flat ground, even with its cranks in
  step; something else about its build is wrong.
- The 2-leg Spears falls over and is stood up again now and then, on any
  ground.
- The balanced 2-leg Spears' counterweight hangs only a little above
  flat ground (its own file's design). On bigger bumps it comes to rest
  on one, and its motor can't drag it off.

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
columns are bump height / bump length, in cm), on 8 cm feet, with the lift
of its foot path (how high its foot rises above its stance, as a share of
its stride; measured on the builds, as the linkage reference measures it):

| Walker                 | Lift | Flat cm/s | 2/11 | 2/15 | 2/22 | 4/11 | 4/15 | 4/22 | 6/11 | 6/15 | 6/22 | Mean | Mean, 4 cm feet |
|------------------------|------|-----------|------|------|------|------|------|------|------|------|------|------|------|
| Chebyshev-Spears       | 26%  | 7.4  | 102% | 102% | 96%  | 98%  | 99%  | 88%  | 71%  | 91%  | 42%  | 88%  | 83%  |
| Hoecken                | 17%  | 9.5  | 93%  | 94%  | 92%  | 89%  | 93%  | 72%  | 83%  | 88%  | 25%  | 81%  | 74%  |
| Hoecken-Spears slider  | 28%  | 6.2  | 102% | 105% | 98%  | 90%  | 100% | 61%  | 80%  | 87%  | 0%   | 80%  | 64%  |
| Chebyshev-Spears diag  | 24%  | 6.1  | 109% | 112% | 79%  | 97%  | 98%  | 41%  | 88%  | 59%  | 8%   | 77%  | 61%  |
| Chebyshev diag         | 14%  | 8.2  | 95%  | 103% | 98%  | 84%  | 85%  | 50%  | 72%  | 38%  | 13%  | 71%  | 51%  |
| Hoecken slider         | 21%  | 9.7  | 84%  | 87%  | 78%  | 83%  | 73%  | 59%  | 72%  | 67%  | 14%  | 69%  | 57%  |
| Jansen                 | 28%  | 7.1  | 112% | 88%  | 58%  | 76%  | 85%  | 22%  | 61%  | 72%  | 11%  | 65%  | 60%  |
| Chebyshev              | 16%  | 10.2 | 84%  | 85%  | 72%  | 74%  | 78%  | 37%  | 61%  | 69%  | 4%   | 63%  | 51%  |
| Spears 4-bar           | 28%  | 15.0 | 56%  | 51%  | 35%  | 53%  | 41%  | 14%  | 46%  | 33%  | 6%   | 37%  | 38%  |
| Spears 2-leg balanced  | 32%  | 12.1 | 62%  | 60%  | 62%  | 39%  | 40%  | 28%  | 8%   | 12%  | 6%   | 35%  | 40%  |
| Spears 2-leg           | 32%  | 11.5 | 38%  | 38%  | 55%  | 20%  | 30%  | 21%  | 22%  | 22%  | 19%  | 30%  | --   |
| Klann                  | 44%  | 2.1  | 93%  | 68%  | 27%  | 116% | 53%  | 10%  | 136% | 65%  | 19%  | 65%  | --   |

The cleanest comparisons are the three pairs where the Spears version is
the same mechanism with more lift, on the same chassis, feet and crank
speed:

| Pair (lift)                                     | 8 cm feet  | 4 cm feet  |
|-------------------------------------------------|------------|------------|
| Chebyshev (16%) -> Chebyshev-Spears (26%)       | 63% -> 88% | 51% -> 83% |
| Chebyshev diag (14%) -> Chebyshev-Spears diag (24%) | 71% -> 77% | 51% -> 61% |
| Hoecken slider (21%) -> Hoecken-Spears slider (28%) | 69% -> 80% | 57% -> 64% |

In all three, on both foot sizes, the version with more lift keeps more of
its speed on bumps. Across all twelve, lift isn't the whole story:

- Hoecken, with little lift, does nearly as well as the best.
- The Spears 4-bar is the fastest walker on flat ground but keeps little
  of it on bumps (on bumps it goes about as fast as the others, 5.6 cm/s).
- The 2-leg Spears fall over often (37 and 31 times in 40 runs), and
  depend more than the others on long feet.
- Klann gets almost nowhere even on flat ground (2 cm/s, against 8-15
  for the others), with its cranks in step, so its shares mean little.
  Something else about its build is wrong.
- Long, high bumps (22 cm long, 6 cm high: steep hills) stop nearly
  everyone.

Four starts per condition is few: differences of a few points mean
little.

### Hinged feet (ANKLES)

The 2-leg Spears' own files hinge each foot to its leg about the
side-to-side axis, like an ankle (up to 90 degrees either way, damped), so
it can tip to lie flat on the ground; every other walker's feet are
welded to its legs. `ANKLES = true` gives every walker those ankles. On
8 cm feet, share of flat-ground speed kept (mean over the 9 bump
conditions, 4 starts each):

| Walker                 | Welded | Ankles | On bumps, cm/s (welded -> ankles) |
|------------------------|--------|--------|-----------------------------------|
| Chebyshev-Spears       | 88%    | 86%    | 6.5 -> 6.3 |
| Jansen                 | 65%    | 81%    | 4.6 -> 6.4 |
| Hoecken                | 81%    | 79%    | 7.7 -> 7.5 |
| Hoecken-Spears slider  | 80%    | 74%    | 5.0 -> 4.7 |
| Klann                  | 65%    | 72%    | 1.4 -> 2.5 |
| Spears 4-bar           | 37%    | 68%    | 5.6 -> 7.6 |
| Chebyshev-Spears diag  | 77%    | 62%    | 4.7 -> 4.5 |
| Chebyshev              | 63%    | 60%    | 6.4 -> 6.1 |
| Hoecken slider         | 69%    | 56%    | 6.6 -> 5.7 |
| Chebyshev diag         | 71%    | 50%    | 5.8 -> 4.7 |

Ankles help the walkers whose feet hang from a link that turns a lot
during a step -- the Spears 4-bar's leg-arm, Jansen's and Klann's
triangles -- whose welded feet meet the ground tilted; the Spears 4-bar
becomes the fastest walker on bumps. They do nothing for, or hurt, the
walkers whose feet hang from a pendant, which stays nearly upright, so
their welded feet already land flat. In the three Spears / non-Spears
pairs, the version with more lift still keeps more of its speed with
ankles: Chebyshev 60% -> Chebyshev-Spears 86%, Chebyshev diag 50% ->
Chebyshev-Spears diag 62%, Hoecken slider 56% -> Hoecken-Spears slider
74%.

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
`GRAVITY` (cm/s^2, 20), `BUMP` (starting bump length, cm, 22), `WALKERS_DIR` (where the builds are,
`../Walkers_For_Room/`), `ARENA` (side, cm, 1000), `CELL` (terrain cell, cm;
by default it follows the bump length), `AMP`
(starting bump height, cm, 1), `SEED` (starting headings and turns, 1),
`ONLY` (build just the walker of that name), `FOOT_LENGTH`, `FOOT_WIDTH`,
`FOOT_THICK` (cm: 8, 12, 0.5) and `FOOT_MASS` (1.5), `SAME_FEET` (false:
each walker keeps its own file's feet), `LOCK_CRANKS` (false: the cranks
run free, as in the standalone files), `ANKLES` (true: every walker's
feet hinged like ankles; Walker Room1 has them welded).
