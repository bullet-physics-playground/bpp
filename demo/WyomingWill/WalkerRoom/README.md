# Walker room

All twelve walkers from `../Walkers/` on one meadow, each scaled to the
same stride, walking freely inside a walled 10 m x 10 m arena. Open
`walker-room.lua`.

Each walker is built by its own `../Walkers_For_Room/<name>_parts.lua`, a
copy of the build its standalone file uses with one option added (see that
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
| Chebyshev diag         | 4.66 | 5.21        | 112% |
| Chebyshev-Spears       | 6.03 | 6.29        | 104% |
| Spears 2-leg           | 10.08| 9.80        | 97%  |
| Hoecken-Spears slider  | 5.60 | 5.19        | 93%  |
| Chebyshev              | 5.95 | 5.25        | 88%  |
| Hoecken slider         | 6.36 | 4.83        | 76%  |
| Chebyshev-Spears diag  | 4.73 | 3.07        | 65%  |
| Spears 2-leg balanced  | 9.58 | 6.13        | 64%  |
| Klann                  | 2.02 | 1.28        | 63%  |
| Hoecken                | 6.79 | 3.96        | 58%  |
| Jansen                 | 10.04| 5.52        | 55%  |
| Spears 4-bar           | 8.03 | 3.35        | 42%  |

On the default bumps (22 cm long, a stride and a half) the walkers keep
most of their speed even 8 cm high: those are rolling hills they walk up
and down. Shorter bumps are obstacles a foot has to get over within a
step. Some of the rest isn't the bumps:

- Klann is slow on flat ground too: part of the time it is moving
  backwards.
- The Spears 4-bar's four cranks each have their own motor, nothing
  keeps them in step, and over a couple of minutes its legs drift from
  their designed timing (225, 180, 225 degrees behind the first) into
  step with each other. Every walker with separately driven cranks
  drifts like this to some degree; only the 2-leg Spears, whose legs
  share one axle, keep their timing.
- The 2-leg Spears falls over and is stood up again two to four times in
  3 minutes, on any ground.
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

## Keys

Click the 3D view first so it has keyboard focus.

| Key       | What it does |
|-----------|--------------|
| Tab       | Follow the next walker |
| Shift+Tab | Follow the one before |
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
`ONLY` (build just the walker of that name).
