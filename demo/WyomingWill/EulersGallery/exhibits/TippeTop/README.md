# The Tippe Top

A ball with a stem, its weight a little below the ball's centre. Spin it on
its ball, stem up, and within a few seconds it turns itself upside down and
spins on its stem, its centre of mass now higher than where it started.
Sliding friction at the table does it.

Three tops, each in its own dish:

* **Left (red), spun fast** (40 turns a second): turns over in about 3.5
  seconds and stands up on its stem; twenty-odd seconds later, slowing
  down, it sinks back and ends where it began, stem up.
* **Middle (blue), the same top spun slowly** (15 turns a second): turns
  over as far as lying on its ball and stem, but hasn't the spin to stand
  up on the stem; as it slows it rights itself again.
* **Right (green), its weight at the ball's centre**: looks the same, never
  turns over.

All three end stem up again in about a minute and a half. The white bands
show the spin.

The stem is short, as on a real tippe top, so it is drawn in pale gold to
stand out against the felt. Above each top, a needle points the way its
stem points, its gold tip being the stem's end. It points up while the top
spins on its ball and down once it stands on its stem. The needles are
only drawn; they touch nothing.

## Keys

| Key | Action |
|---|---|
| `R` | spin them again |
| `Z` | slow motion (1/4) <-> real time |

Sliders: fast spin and slow spin (turns a second), friction, spin friction
(how fast the spin about the upright dies away), rolling (rolling
resistance, microns), speed, steps. Rest the mouse on a top to see what
it's doing. The console reports each change ("Left   up on its stem at   3.5 s")
and every 2 seconds each top's tilt and spin.

## The top

A ball 3 cm across with a short stem, 15 g, hollow: its moment of inertia
about the stem is 2/3 m r^2, across it 0.9 of that. Its centre of mass is
4.5 mm below the ball's centre (0.3 of the radius). A top can turn over
only if 1 - 0.3 < 0.9 < 1 + 0.3, which this one passes. The green one's
centre of mass is 0.6 mm off centre: 0.9 is outside 1 -/+ 0.04, so it can't.

Getting a top to stand up on its stem took some finding:

* A solid ball (moment of inertia 2/5 m r^2) turned over but never stood up:
  standing on the stem needs about 80 rad/s or more, and a solid ball
  hadn't the spin left after turning over. The hollow one has: the red
  top comes up onto its stem with about 91 rad/s (14.6 turns a second at
  4 s), stands steady while it has 83 or more, and starts to sink, 24 s in, at 82. A
  top's rule (I3 w > 2 sqrt(I m g l), l = 1.95 cm from its centre of mass
  to the centre of the stem's round end) gives 68 rad/s with I about the
  centre of mass, as for a tip that slides freely, and 130 to 160 with I
  about the tip, as for one that can't slide; the stem's end, sliding at
  friction 0.2, comes between. (The blue top, spun slowly, has at most 44
  rad/s left once it's on its ball and stem.)
* A long thin stem left the top stuck leaning on ball and stem; a short,
  round-ended one (radius 6 mm, standing 6 mm out of the ball) lets it up.
* Rolling resistance (30 microns) settles the tops. With none, they never
  settle: the blue one rocks on, 16 to 65 degrees, and after 40 s even the
  green one starts rocking and has fallen to 71 degrees by 78 s (why the
  green one does that hasn't been looked into). More of it doesn't stop
  the red top turning over: from 0 to 300 microns it is up on its stem at
  3.4 to 3.7 s each time. It brings it down sooner: back onto its ball and
  stem at 47 s with none, 39 s at 30 microns, 30 s at 100, 13 s at 300
  (`TT_ROLL`; the slider stops at 100), but 22 s at 10. And from 50
  microns the slow blue top doesn't turn over at all (8 degrees at most,
  in the 2-second reports), where at 30 it gets as far as its ball and
  stem.

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

* `tippe-top.lua`: the exhibit. It runs on its own or in the Gallery.
* `tippe-top-meshes/`: the balls, stems and painted bands.
* `reconstruction/gen-meshes.py`: makes them.
