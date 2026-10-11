# Walker room

All twelve walkers from `../Walkers/` on one meadow, each scaled to the
same leg length, walking freely inside a walled 10 m x 10 m arena. Open
`walker-room.lua`.

Each walker is built by its own `../Walkers/<name>_parts.lua`, the same
code its standalone file uses, so it walks in the room as it does on its
own. Its gravity is scaled with it, so it moves as it does full size.
All of them share one world, one terrain and one physics step (1/960 s).

## A fair comparison

- **Same leg length.** Each walker is scaled so its crank axles ride
  12 cm above the ground (its "hip height", measured on flat ground).
  A bump is then the same obstacle to every walker. Their footprints
  differ as a result: from about 16 x 25 cm (the 2-leg Spears) to
  86 x 30 cm (Klann, six legs in a row).
- **Same pace on flat ground.** Each walker's crank turns at the speed
  that walks it at about 6 cm/s on flat ground (its pace: the length of
  its path, so veering doesn't count against it). These were found by
  sweeping crank speeds for each walker alone, because pace doesn't
  rise smoothly with crank speed for all of them: some stumble or hop
  at some speeds. Three can't reach it walking forwards and run at
  their best: the 2-leg Spears tips over between 2.5 and 3.4 rad/s, so
  it runs just below (about 5.6 cm/s); faster than 3.5 rad/s Chebyshev
  slides backwards more and more (it runs at about 4 cm/s); and faster
  than 3.25 Chebyshev diag walks backwards outright (it runs at its own
  3.0, about 3 cm/s).

With equal legs and an equal start, a walker that falls behind as the
bumps rise is losing to the bumps. Pace over 3 minutes in the full room
(cm/s; one run each, so a few tenths either way mean little):

| Walker                 | Flat | 1 cm | 2 cm | 3 cm |
|------------------------|------|------|------|------|
| Jansen                 | 5.6  | 3.6  | 1.9  | 1.6  |
| Klann                  | 5.5  | 5.1  | 3.6  | 5.8  |
| Chebyshev              | 4.9  | 4.6  | 4.3  | 3.8  |
| Chebyshev diag         | 3.1  | 4.5  | 3.5  | 3.3  |
| Chebyshev-Spears       | 5.6  | 5.7  | 6.0  | 6.2  |
| Chebyshev-Spears diag  | 5.0  | 4.8  | 5.2  | 5.8  |
| Hoecken                | 6.7  | 6.0  | 5.9  | 6.2  |
| Hoecken slider         | 5.8  | 5.6  | 5.4  | 5.5  |
| Hoecken-Spears slider  | 5.8  | 6.0  | 6.0  | 5.6  |
| Spears 4-bar           | 3.3  | 3.3  | 3.1  | 3.5  |
| Spears 2-leg           | 5.0  | 4.6  | 1.6  | 1.4  |
| Spears 2-leg balanced  | 5.8  | 5.8  | 1.1  | 1.7  |

The Spears 4-bar's 3.3 isn't the bumps: it walks at 6 cm/s for about a
minute, then slows almost to a stop on any ground. Its four cranks
each have their own motor, nothing keeps them in step, and over a
couple of minutes its legs drift from their designed timing (225, 180,
225 degrees behind the first) into step with each other. Every walker
with separately driven cranks drifts like this to some degree; only the
2-leg Spears, whose legs share one axle, keep their timing.

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
