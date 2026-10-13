# Walker room

All twelve walkers from `../Walkers/` on one meadow, each scaled to the
same stride, walking freely inside a walled 10 m x 10 m arena. Open
`walker-room.lua`.

Each walker is built by its own `../Walkers/<name>_parts.lua`, the same
code its standalone file uses. All of them share one world, one
terrain, one gravity and one physics step (1/960 s).

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
  a result: hip heights from about 5 cm (Chebyshev-Spears) to about
  25 cm (the 2-leg Spears).
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

Speed over 3 minutes in the full room (cm/s, horizontal, along its
path; one run each, so a few tenths either way mean little):

| Walker                 | Flat | 1 cm | 2 cm | 3 cm | 4 cm | 6 cm | 8 cm |
|------------------------|------|------|------|------|------|------|------|
| Jansen                 | 10.1 | 7.9  | 7.6  | 6.7  | 5.8  | 6.0  | 5.4  |
| Klann                  | 4.2  | 4.2  | 3.9  | 4.5  | 4.3  | 4.2  | 4.5  |
| Chebyshev              | 7.7  | 7.8  | 6.8  | 6.0  | 6.2  | 6.2  | 7.5  |
| Chebyshev diag         | 4.1  | 4.2  | 5.8  | 4.9  | 5.3  | 5.6  | 7.5  |
| Chebyshev-Spears       | 6.7  | 6.7  | 6.3  | 6.3  | 6.5  | 6.4  | 5.8  |
| Chebyshev-Spears diag  | 3.9  | 3.4  | 3.1  | 4.3  | 4.3  | 5.3  | 5.7  |
| Hoecken                | 8.2  | 8.3  | 7.7  | 7.6  | 7.4  | 9.5  | 9.7  |
| Hoecken slider         | 7.4  | 7.3  | 7.3  | 6.6  | 6.7  | 7.2  | 8.3  |
| Hoecken-Spears slider  | 5.9  | 6.1  | 6.6  | 6.0  | 6.0  | 5.8  | 7.0  |
| Spears 4-bar           | 6.1  | 7.9  | 7.3  | 6.7  | 7.2  | 7.8  | 9.0  |
| Spears 2-leg           | 10.3 | 11.3 | 11.1 | 10.6 | 9.0  | 6.2  | 8.5  |
| Spears 2-leg balanced  | 10.2 | 10.2 | 7.7  | 4.6  | 4.7  | 0.9  | 0.3  |

The bumps are smooth rolling hills 18 to 33 cm long (a stride or two),
so most walkers just walk up and down them: only Jansen and the two
2-leg Spears slow down much. Some of the rest isn't the bumps:

- Klann is slow on flat ground too: about a third of the time it is
  moving backwards.
- The Spears 4-bar's four cranks each have their own motor, nothing
  keeps them in step, and over a couple of minutes its legs drift from
  their designed timing (225, 180, 225 degrees behind the first) into
  step with each other, and it slows. Every walker with separately
  driven cranks drifts like this to some degree; only the 2-leg Spears,
  whose legs share one axle, keep their timing.
- The 2-leg Spears falls over and is stood up again three or four times
  in 3 minutes, on any ground.
- The balanced 2-leg Spears' counterweight hangs only a little above
  flat ground (its own file's design; there too it brushes the ground
  now and then). On bigger bumps it comes to rest on one, and its motor
  can't drag it off.
- Hoecken-Spears slider and Klann hop off the ground now and then.

When a walker comes within 40 cm of a wall, or of another walker ahead
of it, it turns smoothly (over a second) to a new heading pointing away
from what is near. The balanced 2-leg Spears is held to move only along
its heading, so it turns only in right angles. A walker
that falls over and stays down for 2 seconds is stood up again, facing
the way it was facing, and carries on.

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
`GRAVITY` (cm/s^2, 20), `ARENA` (side, cm, 1000), `CELL` (terrain cell, cm, 4), `AMP`
(starting bump height, cm, 1), `SEED` (starting headings and turns, 1),
`ONLY` (build just the walker of that name), `WALKERS_DIR` (where the
parts files are, `../Walkers/`).
