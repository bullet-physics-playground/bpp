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
- **Same crank speed.** Every crank turns at 2.6 rad/s, whatever its
  standalone slider says, so what differs is how far each mechanism
  carries its body per turn.

On flat ground that gives (cm/s): Chebyshev-Spears 13.7, Chebyshev-Spears
diag 12.2, Spears 4-bar 9.0, Hoecken 8.2, Hoecken slider 7.9, Spears
2-leg 6.6, Jansen 6.3, Hoecken-Spears slider 6.3, Spears 2-leg balanced
3.9, Klann 3.4, Chebyshev diag 2.7, Chebyshev 2.6.

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
the room: `LEG` (leg length, cm, 12), `CRANK` (crank speed, rad/s,
2.6), `ARENA` (side, cm, 1000), `CELL` (terrain cell, cm, 4), `AMP`
(starting bump height, cm, 1), `SEED` (starting headings and turns, 1),
`ONLY` (build just the walker of that name), `WALKERS_DIR` (where the
parts files are, `../Walkers/`).
