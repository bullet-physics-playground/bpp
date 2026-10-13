# Walker room

All twelve walkers from `../Walkers/` on one meadow, each scaled to the
same leg length, walking freely inside a walled 10 m x 10 m arena. Open
`walker-room.lua`.

Each walker is built by its own `../Walkers/<name>_parts.lua`, the same
code its standalone file uses. All of them share one world, one
terrain, one gravity and one physics step (1/960 s).

## A fair comparison

- **Same leg length.** Each walker is scaled so its crank axles ride
  12 cm above the ground (its "hip height", measured on flat ground).
  A bump is then the same obstacle to every walker. Their footprints
  differ as a result: from about 16 x 25 cm (the 2-leg Spears) to
  86 x 30 cm (Klann, six legs in a row).
- **Same gravity.** Every standalone file uses 9.8 units/s^2, but the
  walkers are built at very different sizes in those units, so scaling
  each one's gravity with it left them under gravities from 1.3 cm/s^2
  (Jansen) to 30 (Chebyshev-Spears), and Klann floated off the ground
  for seconds at a time. Now all of them are under 20 cm/s^2 (about the
  middle of that range), each with its motors made stronger or weaker
  by the same factor as its gravity, so it can still lift itself.
- **Same pace on flat ground.** Each walker's crank turns at the speed
  that walks it at about 6 cm/s on flat ground (its pace: the length of
  its path, so veering doesn't count against it). These were found by
  sweeping crank speeds for each walker alone, because pace doesn't
  rise smoothly with crank speed for all of them: some stumble, hop or
  walk backwards at some speeds. Two can't reach it walking forwards:
  Chebyshev diag walks forwards steadily only near its own 3.0 rad/s
  (about 2.5 cm/s), and Jansen jumps from about 5 to about 9 cm/s
  between 3.25 and 3.35 rad/s, so it runs on the steady side (about 5).

The balanced 2-leg Spears' joints are solved with 40 solver iterations,
as its own file does (its notes: at Bullet's default 10 its rocking
roughly doubles); the others keep the default 10 their files use.

With equal legs and an equal start, a walker that falls behind as the
bumps rise is losing to the bumps. Pace over 3 minutes in the full room
(cm/s; one run each, so a few tenths either way mean little):

| Walker                 | Flat | 1 cm | 2 cm | 3 cm |
|------------------------|------|------|------|------|
| Jansen                 | 8.1  | 5.8  | 5.0  | 4.4  |
| Klann                  | 5.2  | 5.1  | 5.8  | 5.4  |
| Chebyshev              | 5.6  | 5.5  | 4.3  | 3.8  |
| Chebyshev diag         | 3.0  | 4.4  | 3.5  | 3.4  |
| Chebyshev-Spears       | 5.7  | 5.8  | 5.6  | 5.9  |
| Chebyshev-Spears diag  | 4.7  | 4.5  | 4.7  | 5.5  |
| Hoecken                | 6.0  | 5.9  | 5.7  | 6.6  |
| Hoecken slider         | 5.8  | 5.5  | 5.3  | 5.5  |
| Hoecken-Spears slider  | 6.5  | 7.2  | 7.2  | 7.2  |
| Spears 4-bar           | 3.9  | 3.7  | 4.0  | 4.7  |
| Spears 2-leg           | 5.6  | 5.3  | 1.6  | 1.5  |
| Spears 2-leg balanced  | 6.2  | 0.2  | 0.2  | 0.1  |

Some of these aren't the bumps:

- The Spears 4-bar walks at 6 cm/s for about a minute, then slows
  almost to a stop on any ground. Its four cranks each have their own
  motor, nothing keeps them in step, and over a couple of minutes its
  legs drift from their designed timing (225, 180, 225 degrees behind
  the first) into step with each other. Every walker with separately
  driven cranks drifts like this to some degree; only the 2-leg Spears,
  whose legs share one axle, keep their timing.
- The balanced 2-leg Spears' counterweight hangs only about 1 cm above
  flat ground (its own file's design; there too it brushes the ground
  now and then). On bumps it comes to rest on one, and its motor can't
  drag it off.
- Hoecken-Spears slider jumps now and then, up to about 15 cm (more
  than its own hip height), as it does in its own file over a few
  minutes; Klann hops up to about 8 cm now and then.

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
the room: `LEG` (leg length, cm, 12), `CRANK_OVERRIDE` (one crank
speed, rad/s, for every walker), `ARENA` (side, cm, 1000), `CELL` (terrain cell, cm, 4), `AMP`
(starting bump height, cm, 1), `SEED` (starting headings and turns, 1),
`ONLY` (build just the walker of that name), `WALKERS_DIR` (where the
parts files are, `../Walkers/`).
