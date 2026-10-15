# The Spinning Egg

Spin a hard-boiled egg fast on its side and it rises up onto its end,
raising its centre of mass, and spins there like a top. Friction does it, as
with the tippe top: the egg slides on the table as it spins, and the drag
of the table at the sliding point tips it up. A raw egg, spun the same way,
won't. The liquid inside doesn't turn with the shell, so the egg barely
spins at all.

Three eggs stand on a table, each in its own dish:

| Egg | What happens |
|---|---|
| left (red band) | hard-boiled, spun at 25 turns a second. It rises onto its end in under a second and spins there for about 20 s. When it has slowed to about 6 turns a second, it sinks back onto its side. (How long it stays up depends on the step size: see Energy, below.) |
| middle (blue band) | hard-boiled, spun at 40 turns a second. It rises the same way, and as it rises it **jumps**: it leaves the table for a hundredth of a second or two, a fraction of a millimetre, twenty-odd times. Its lamp lights while it's off the table. |
| right (green band) | raw, spun at 25 turns a second. The liquid takes up the spin, the egg slows to about 5 turns a second, and it stays on its side. Two seconds in, a finger stops it for a moment. Let go, it starts turning again by itself, because the liquid inside is still turning. |

When all three are at rest, they're spun again.

## Keys

| Key | Action |
|---|---|
| `R` | spin them again |
| `S` | stop all three with a finger for a moment (0.3 s), then let go |
| `V` | views: all three (to start with); the left, middle and right egg close up |
| `Z` | slow motion (1/4) <-> real time |

Sliders: spin (the left and right eggs), fast spin (the middle one), in
turns a second; friction (sliding, at the table); spin friction and
rolling (in microns: see Physics); speed; steps. Rest the mouse on an egg
to see what it's doing.

## The theory, and what the console says

As each hard-boiled egg stands up, the console checks three things against
theory, and reports the jumps:

    Left   standing on its end at  0.67 s (tilt 10 deg, spinning 25.3 turns/s)
           spinning 25.31 turns/s; by Jellett's J it should be 25.17 (J 48.74, from 49.87, 48.33 with spin friction: +0.83%)
           energy lost 41.17 microjoules; friction took 41.73, landings -0.02: 41.71 (-1.29% apart)
           it rose from 60 to 30 deg in 0.259 s; by J dtheta/dt = mu M g h^2 (sliding) it should take 0.240 (+8.2%)
           it never left the table
    Middle standing on its end at  1.22 s (tilt 2 deg, spinning 41.0 turns/s)
           spinning 40.95 turns/s; by Jellett's J it should be 40.26 (J 78.64, from 79.80, 77.31 with spin friction: +1.73%)
           energy lost 106.19 microjoules; friction took 97.08, landings 10.00: 107.08 (-0.83% apart)
           it rose from 60 to 30 deg in 0.468 s; by J dtheta/dt = mu M g h^2 (sliding) it should take 0.384 (+22.0%)
           it jumped 24 times as it rose (0.32 to 1.08 s): longest 19.8 ms, highest 0.58 mm off the table

**Jellett's constant.** Take the egg's angular momentum about its centre of
mass, and dot it with the line from where it touches the table up to that
centre: J = L . (G - P). Moffatt and Shimomura (*Nature*, 2002) showed that
J hardly changes as the egg rises, as long as it spins fast. Spinning on
its side about the upright, J = A b W0. Here A is the moment of inertia
across the egg and b its half-width. Standing on its end, J = C a W, with C
about its long axis and a its half-length. So, standing up, the egg should
spin at

    W = W0 A b / (C a)

That's 4% faster than it started, although it has lost about a fifth of its
energy to friction and raised its centre of mass 7 mm. The console works out J from
the egg's motion and compares. Spin friction (below) takes a little of J
away as the egg rises; the console adds that up and allows for it.

J is kept only approximately: it changes by 0.8% here (at 25 turns a
second) and 1.7% for the middle egg, which jumps. The faster the spin, the
better it's kept: with no spin friction, J changes by 1.4% at 20 turns a
second and 1.0% at 30 (at 4800 steps a second; 0.8% at 30 with 19200).

**The rise.** While the egg slides, Moffatt and Shimomura's gyroscopic
balance gives its rate of rise: J dtheta/dt = -mu M g h^2, with theta the
tilt of its long axis from upright, mu the friction, M its mass and h the
height of its centre. The console times the egg from 60 to 30 degrees and
compares, starting from the J it has at 60 degrees and letting spin
friction take J as it goes. The left egg takes 0.259 s against 0.240 (8%
slower), at every step size from 2400 to 38400 a second. The theory is the
slow part of the motion: it leaves out the wobble (nutation) the egg starts
with, spun about the upright from 6 degrees. Started in the balance itself
(`EG_BALANCED=1`, which adds the little spin about its long axis the
balance needs), it takes 0.246 s against 0.241 (2%). The middle egg takes
0.468 s against 0.384 (22% slower; 4% when started in balance); it is
jumping all the way up, and the theory has it on the table with a steady
push.

**Energy.** All the energy the egg loses goes to friction at the table:
sliding friction, plus the small spin friction and rolling resistance. For
an egg that jumps, it also goes to the landings, which don't bounce. The
console adds up the work they do and compares it with what the egg lost.
At 4800 steps a second they agree to within 1.3% (the left egg) and 0.8%
(the middle one), and the gap shrinks with the step: for the left egg 0.69%
at 9600 steps a second, 0.50% at 14400, 0.40% at 19200; for the middle one
0.44%, 0.32%, 0.29% (above 9600, beyond the steps slider, set with
`EG_STEPS`). The left egg starts to rise (passes 60 degrees) at 0.30 s and
stands at 0.67-0.68 s at every step size from 2400 to 38400; the middle one
at 0.52 s and 1.18-1.22 s.

**Why 6 degrees.** Spun nearly level, the egg needn't slide at all:
friction can hold the point where it touches the table still, and the egg
rolls on its side without slipping. Then nothing tips it up. At 25 turns a
second and friction 0.3 that happens from 3 degrees or less (the faster the
spin, or the less the friction, the nearer level it has to be for that). Close to
that edge, whether and when the egg breaks free is decided by the step's
small errors: started at 3 degrees (`EG_TILT=3`), the left egg rises at
0.50 s at 4800 steps a second, 0.65 s at 9600, 0.90 s at 14400, 2.45 s at
19200, and not at all at 28800 or 38400: there it rolls on its side,
slowing down (followed for 20 s at 28800). From 6 degrees it slides from
the start.

The same small errors are not gone once the egg is up. Standing on its end
at about 10 degrees, the egg rolls without slipping, and the step's errors
slowly tip it further up: at 3 s it leans 4 degrees at 4800 steps a second,
7 at 9600, 9 at 19200. So how long it stays up isn't settled: it starts
falling back at 22.3 s (spinning 6.4 turns a second) at 4800 steps a
second, 20.6 s (7.6) at 9600 and 17.6 s (10.0) at 19200.

**Jumps.** In 2006, Shimomura and colleagues at Keio University spun egg
shapes at up to 2500 turns a minute, and real hard-boiled eggs at 1800.
They measured them leaving the table as they rose: a fraction of a
millimetre, for up to a few hundredths of a second. Here the egg jumps when
spun faster than about 30 turns a second (1800 a minute): at 30 it leaves
the table once, for 4 ms; at 32, eight times. At 40 turns a second it jumps
24 times as it rises, up to 0.6 mm and 20 ms. The friction hardly matters:
from 0.2 to 0.5 it still jumps at 35 turns a second.

**The raw egg.** Only the shell is spun; the liquid starts still. Sharing
the shell's spin with the liquid, they should turn together at 5.5 turns a
second. With no spin friction at the table they nearly do: at 1.2 s the
shell turns at 5.81 and the liquid at 5.24, together (weighted by their
moments of inertia) 5.37, 2% short. Tipped up 6 degrees, the egg touches
the table a little off its middle, and sliding friction there takes a
little of the spin. Stopped by the finger and let go, the shell picks up the
liquid's spin. With no spin friction, that's 3.34 turns a second against
3.38 for sharing. With the default spin friction it's about half that,
since the light shell is slowed hard by the table.

## The egg

The egg is a spheroid 5.7 cm long and 4.3 cm across, weighing 58 g. That's
the shape the theory has; a real egg is a little fatter at one end.

The raw one has a shell 0.35 mm thick, 10% of its mass, with the liquid
inside.

## Physics

* Bullet moves each egg, a rigid body. Everything else is done in the
  script, before every physics step:
  * Euler's equations for the egg's spin (Bullet's gyroscopic term is off),
    and gravity.
  * Its contact with the table, worked out exactly for the spheroid. That
    means its lowest point; an impulse that stops it going into the table
    (and never pulls it down, so it can leave the table); and sliding
    friction (0.3) at that point. They're solved together six times over,
    as Bullet solves its contacts.
  * The dish's rim, in the same way.
* **Spin friction:** a small moment against the spin about the upright,
  0.01 cm times the push of the table. It's what slows an egg standing on
  its end, until it falls back.
* **Rolling resistance:** a moment against rolling, 0.01 cm times the push.
  It stops an egg that has fallen back from rolling off across its dish.
* **The raw egg:** its shell is the rigid body. Some of the liquid has to
  move when the shell turns about an axis across it, since the shell isn't
  round; that part is added to the shell (the potential-flow added inertia,
  m/5 (a^2 - b^2)^2 / (a^2 + b^2) for liquid of mass m in a spheroid). The
  rest of the liquid is a second body inside, free to turn, with the moment
  of inertia it has across the egg. The shell drags it round with a time
  constant of 1.5 s.
* Each egg starts on its side, tipped up 6 degrees and spun about the
  upright (see "Why 6 degrees", above).
* 4800 physics steps a second.

## Files

* `spinning-egg.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`).
* `spinning-egg-meshes/`: the egg (a spheroid) and its painted bands.
* `reconstruction/gen-meshes.py`: makes them (`python3 gen-meshes.py`, from
  that folder).

Headless testing: `EG_SPIN`, `EG_FAST` (turns a second), `EG_MU`,
`EG_KAPPA`, `EG_DELTA` (microns), `EG_SPEED`, `EG_STEPS`, `EG_TILT`
(degrees up from level at the start), `EG_BALANCED=1` (start the
hard-boiled eggs in Moffatt and Shimomura's balance), `EG_TOUCH_AT`
(when the finger stops the raw egg, s), `EG_LOG=file.csv` (time, egg, tilt,
spin about the upright, the table's push over the weight, the gap under it
in microns, J, energy, where it is in its dish).

## Sources

* H. K. Moffatt and Y. Shimomura, "Spinning eggs — a paradox resolved",
  *Nature* 416, 385 (2002).
* Y. Shimomura and colleagues, *Proc. R. Soc. A* (2006), on spinning eggs
  jumping; reported in *Science News*, 23 May 2006, "Well-spun egg also
  jumps".
