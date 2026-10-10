# The Tippe Top

A ball with a stem, its weight a little below the ball's centre. Spin it on
its ball, stem up, and within a few seconds it turns itself upside down and
spins on its stem, its centre of mass now higher than where it started.
Sliding friction at the table does it.

Three tops, each in its own dish:

* **Left (red), spun fast** (40 turns a second): turns over in about 3
  seconds and stands up on its stem; twenty-odd seconds later, slowing
  down, it sinks back and ends where it began, stem up.
* **Middle (blue), the same top spun slowly** (15 turns a second): turns
  over as far as lying on its ball and stem, but hasn't the spin to stand
  up on the stem; as it slows it rights itself again.
* **Right (green), its weight at the ball's centre**: looks the same, never
  turns over.

All three end stem up again in about a minute and a half. The white bands
show the spin.

## Keys

| Key | Action |
|---|---|
| `R` | spin them again |
| `Z` | slow motion (1/4) <-> real time |

Sliders: fast spin and slow spin (turns a second), friction, spin friction
(how fast the spin about the upright dies away), rolling (rolling
resistance, microns), speed, steps. Rest the mouse on a top to see what
it's doing. The console reports each change ("Left up on its stem at 3.3 s")
and every 2 seconds each top's tilt and spin.

## The top

A ball 3 cm across with a short stem, 15 g, hollow: its moment of inertia
about the stem is 2/3 m r^2, across it 0.9 of that. Its centre of mass is
4.5 mm below the ball's centre (0.3 of the radius). A top can turn over
only if 1 - 0.3 < 0.9 < 1 + 0.3, which this one passes. The green one's
centre of mass is 0.6 mm off centre: 0.9 is outside 1 -/+ 0.04, so it can't.

Getting a top to stand up on its stem took some finding:

* A solid ball (moment of inertia 2/5 m r^2) turned over but never stood up:
  standing on the stem needs about 100 rad/s or more, and a solid ball
  hadn't the spin left after turning over. The hollow one has.
* A long thin stem left the top stuck leaning on ball and stem; a short,
  round-ended one (radius 6 mm, standing 6 mm out of the ball) lets it up.
* Rolling resistance of 100 microns stops the top turning over at all; 30
  is enough to settle the tops at the end.

## Physics

* Bullet's gyroscopic term is off; each top's spin is advanced by Euler's
  equations (RK4) before every physics step, as in the rattleback.
* Contact: a true sphere for the ball and a capsule for the stem (a compound
  shape), sliding friction 0.2.
* Spin friction 0.5 rad/s^2 about the upright, so a top on its stem slows
  down and in the end falls over (without it, the red one spins on its stem
  for ever).
* 4800 physics steps a second.

Headless testing: `TT_FAST`, `TT_SLOW` (turns a second), `TT_MU`,
`TT_SPINF`, `TT_ROLL`, `TT_LOG=file.csv`.

## Files

* `tippe-top.lua`: the exhibit. It runs on its own or in the Cabinet.
* `tippe-top-meshes/`: the balls, stems and painted bands.
* `reconstruction/gen-meshes.py`: makes them.
