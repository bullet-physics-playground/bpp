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
| left (red band) | hard-boiled, spun at 25 turns a second. It rises onto its end in under a second and spins there. As it slows, it leans further and further over: past 15 degrees after 8 s, and back on its side after 24 s, spinning under 3 turns a second. |
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

    Left   standing on its end at  0.68 s (tilt 11 deg, spinning 25.2 turns/s)
           spinning 25.22 turns/s; by Jellett's J it should be 25.15 (J 48.59, from 49.87, 48.30 with spin friction: +0.60%)
           energy lost 41.88 microjoules; friction took 41.88, landings -0.00: 41.88 (0.00% apart)
           it rose from 60 to 30 deg in 0.261 s; by J dtheta/dt = mu M g h^2 (sliding) it should take 0.239 (+9.1%)
           it never left the table
    Middle standing on its end at  1.22 s (tilt 4 deg, spinning 40.8 turns/s)
           spinning 40.76 turns/s; by Jellett's J it should be 40.26 (J 78.31, from 79.80, 77.31 with spin friction: +1.29%)
           energy lost 109.15 microjoules; friction took 97.53, landings 11.62: 109.15 (0.00% apart)
           it rose from 60 to 30 deg in 0.471 s; by J dtheta/dt = mu M g h^2 (sliding) it should take 0.384 (+22.7%)
           it jumped 25 times as it rose (0.29 to 1.09 s): longest 21.3 ms, highest 0.59 mm off the table

and, as the left egg slows:

    Left   falling back at  7.97 s (tilt 15 deg, spinning 18.5 turns/s)
    Left   back on its side at 24.40 s (tilt 63 deg, spinning 2.6 turns/s)

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

J is kept only approximately: it changes by 0.6% here (at 25 turns a
second) and 1.3% for the middle egg, which jumps. With no spin friction, J
changes by 0.58% at 25 turns a second and 0.83% at 30 (where the egg jumps
a little), the same at every step size from 4800 to 19200 a second. (At 20
turns a second it stops rising at about 18 degrees, rolling, so the console
never has it standing.)

**The rise.** While the egg slides, Moffatt and Shimomura's gyroscopic
balance gives its rate of rise: J dtheta/dt = -mu M g h^2, with theta the
tilt of its long axis from upright, mu the friction, M its mass and h the
height of its centre. The console times the egg from 60 to 30 degrees and
compares, starting from the J it has at 60 degrees and letting spin
friction take J as it goes. The left egg takes 0.261 s against 0.239 (9%
slower), at every step size from 2400 to 38400 a second. The theory is the
slow part of the motion: it leaves out the wobble (nutation) the egg starts
with, spun about the upright from 6 degrees. Started in the balance itself
(`EG_BALANCED=1`, which adds the little spin about its long axis the
balance needs), it takes 0.247 s against 0.241 (2.5%). The middle egg takes
0.471 s against 0.384 (23% slower; 6% when started in balance); it is
jumping all the way up, and the theory has it on the table with a steady
push.

**Energy.** All the energy the egg loses goes to friction at the table:
sliding friction, plus the small spin friction and rolling resistance. For
an egg that jumps, it also goes to the landings, which don't bounce. The
console adds up the work they do and compares it with what the egg lost.
They agree to 0.01% or better, for both eggs, at every step size from 2400
to 38400 a second (above 9600, beyond the steps slider, set with
`EG_STEPS`). So the step itself makes and loses no energy: all the egg
loses, friction took (see Physics). The left egg starts to rise (passes 60
degrees) at 0.30 s and stands at 0.68 s at every step size from 2400 to
38400; the middle one at 0.50 s and 1.22 s.

**Why 6 degrees.** Spun nearly level, the egg needn't slide at all:
friction can hold the point where it touches the table still, and the egg
rolls on its side without slipping. Then nothing tips it up. At 25 turns a
second and friction 0.3 that happens from 3 degrees or less (the faster the
spin, or the less the friction, the nearer level it has to be for that).
Started at 3 degrees (`EG_TILT=3`), the left egg rolls on its side, slowing
down, and never rises, at every step size from 2400 to 38400 a second. Close
to that edge, when it breaks free depends a little on the step: from 3.5
degrees it rises at 0.38 s at 2400 and 4800 steps a second, 0.42 s at
19200. From 4 degrees it rises at 0.35 s at every step size; from 6 it
slides from the start and rises at 0.30 s.

**Standing up.** Up on its end the egg no longer slides: it rolls on the
table without slipping (friction never needs more than 86% of what it can
give). Rolling, it can't rise any further, since the rise needs sliding, so
it stands at 11 degrees, not upright. Then spin friction slows it. It takes
Jellett's J at a steady 1.78 a second, and standing J = C a W, so the spin
falls by 0.93 turns a second each second. As it slows, the egg leans
further over: 12 degrees at 3 s, 17 at 10 s, 23 at 15 s. The console has it
falling back when it passes 15 degrees, at 7.97 s (spinning 18.5 turns a
second), and back on its side at 24.40 s (2.6 turns a second). That's the
same, to 0.01 s, at every step size from 2400 to 19200 a second. At 38400
it passes 15 degrees at 8.15 s: with that many steps, the rounding in
Bullet's numbers (single precision) begins to show.

As a check, the egg was followed from its state at 1 s by the exact
equations of a body of revolution rolling without slipping, with the same
spin friction and rolling resistance, integrated separately to 11 digits
(`reconstruction/rolling-check.py`). It leans 11.97 degrees at 3 s (the
exhibit: 11.99), 17.10 at 10 s (17.12) and 22.69 at 15 s (22.65). It
passes 15 degrees at 8.05 s, counted as the console counts (7.97), and is
back at 60 degrees at 24.39 s (24.40).

With no spin friction and no rolling resistance (`EG_KAPPA=0
EG_DELTA=0`), nothing takes energy from a rolling egg, and it should stay
up for good. Here its energy stays the same to 0.002 microjoules from 1 s
to 10 s, and its tilt swings between 9.4 and 10.6 degrees, at every step
size.

Until 17 Oct 2026 this part wasn't right. The egg rolled by a step that
was only first-order right, and up on its end the error slowly tipped it
upright: at 3 s it leaned 4 degrees at 4800 steps a second, 9 at 19200.
So how long it stayed up depended on the step: it started falling back at
22.3 s at 4800 steps a second, 17.6 s at 19200.

**Jumps.** In 2006, Shimomura and colleagues at Keio University spun egg
shapes at up to 2500 turns a minute, and real hard-boiled eggs at 1800.
They measured them leaving the table as they rose: a fraction of a
millimetre, for up to a few hundredths of a second. Here the egg jumps when
spun at about 30 turns a second (1800 a minute) or faster: at 29 it stays
on the table; at 30 it leaves it four times, for up to 16 ms and 0.1 mm;
at 32, nine times. At 40 turns a second it jumps 25 times as it rises, up
to 0.6 mm and 21 ms. The friction hardly matters: from 0.2 to 0.5 it still
jumps at 35 turns a second.

**The raw egg.** Only the shell is spun; the liquid starts still. Sharing
the shell's spin with the liquid, they should turn together at 5.5 turns a
second. With no spin friction at the table they nearly do: at 1.2 s the
shell turns at 5.87 and the liquid at 5.27, together (weighted by their
moments of inertia) 5.40, 2% short. Tipped up 6 degrees, the egg touches
the table a little off its middle, and sliding friction there takes a
little of the spin. Stopped by the finger and let go, the shell picks up the
liquid's spin. With no spin friction, that's 3.37 turns a second against
3.40 for sharing. With the default spin friction it's about half that,
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
    (and never pulls it down, so it can leave the table); and friction
    (0.3) at that point: enough to stop it slipping if it can, and
    otherwise sliding friction against the slip. They're solved together
    six times over, as Bullet solves its contacts.
  * The dish's rim, in the same way.
* **Spin friction:** a small moment against the spin about the upright,
  0.01 cm times the push of the table. It's what slows an egg standing on
  its end, until it falls back.
* **Rolling resistance:** a moment against rolling, 0.01 cm times the push.
  It stops an egg that has fallen back from rolling off across its dish.
  Both are part of the same solve as the contact, so the egg still rolls
  after them.
* **The step.** Bullet moves the egg on with the velocities the script
  leaves it: the centre by the velocity times the step, and it turns it by
  the turning times the step. So those velocities belong to the middle of
  each move. The script has the egg roll without slipping where it will
  touch the table half a step on, and puts the impulses where it touches
  now. It takes Euler's gyroscopic term and sliding friction at the mean of
  the step's start and end (solving the contact twice, the second time with
  the end it found the first time). Each step is then second-order right,
  and the same run backwards as forwards. That's what keeps a rolling egg's
  energy, and makes the run the same at any step size.
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

* `spinning-egg.lua`: the exhibit. It also stands in Euler's Gallery (`../../`).
* `spinning-egg-meshes/`: the egg (a spheroid) and its painted bands.
* `reconstruction/gen-meshes.py`: makes them (`python3 gen-meshes.py`, from
  that folder).
* `reconstruction/rolling-check.py`: the check on the standing egg (above).
  It follows the egg rolling exactly, from a state the exhibit writes with
  `EG_STATE` (Python, with numpy and scipy; how to run it is at its top).

Headless testing: `EG_SPIN`, `EG_FAST` (turns a second), `EG_MU`,
`EG_KAPPA`, `EG_DELTA` (microns), `EG_SPEED`, `EG_STEPS`, `EG_TILT`
(degrees up from level at the start), `EG_BALANCED=1` (start the
hard-boiled eggs in Moffatt and Shimomura's balance), `EG_TOUCH_AT`
(when the finger stops the raw egg, s), `EG_LOG=file.csv` (time, egg, tilt,
spin about the upright, the table's push over the weight, the gap under it
in microns, J, energy, where it is in its dish), `EG_STATE=time:file` (the
left egg's state then, for `rolling-check.py`).

## Sources

* H. K. Moffatt and Y. Shimomura, "Spinning eggs — a paradox resolved",
  *Nature* 416, 385 (2002).
* Y. Shimomura and colleagues, *Proc. R. Soc. A* (2006), on spinning eggs
  jumping; reported in *Science News*, 23 May 2006, "Well-spun egg also
  jumps".
* On steps that are the same backwards as forwards, for things that roll:
  R. McLachlan and M. Perlmutter, "Integrators for nonholonomic mechanical
  systems", *J. Nonlinear Sci.* (2006); K. Modin and O. Verdier, "What
  makes nonholonomic integrators work?", *Numer. Math.* 145, 405 (2020).
