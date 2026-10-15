# The Dzhanibekov Effect

In 1985 the cosmonaut Vladimir Dzhanibekov, on Salyut 7, unscrewed a wing
nut that spun off on its own, and every few seconds flipped over, end for
end, then flipped back, again and again. It is the "tennis racket
theorem": a body with three different moments of inertia spins steadily
about the axes of its largest and its smallest moment, but not about the
middle one. Spun about that one, the slightest wobble grows until the body
turns over, and the motion repeats for ever.

Three aluminium T-handles, the same each time, shaped like a wing nut (a
10 cm bar and a short, thick 4 cm stem), float without gravity in glass
boxes. Each is spun at a turn a second about a different one of its axes,
each with the same small extra wobble (the "nudge", 1% of the spin, about
the next axis):

| Handle | Spun about | Its moment | What it does |
|---|---|---|---|
| left (blue) | the stem | middle | flips over and back, every 3.3 s, like Dzhanibekov's wing nut |
| middle (red) | the bar | smallest | spins steadily, its axis wandering 2 degrees |
| right (green) | across both | largest | spins steadily, its axis wandering 1 degree |

The shape matters: which axis is the middle one depends on proportions.
With a long stem (7 cm) the stem has the smallest moment and spin about it
is steady, while spin about the bar flips instead.

## Keys

| Key | Action |
|---|---|
| `R` | start all three again (with the current spin and nudge) |
| `Z` | slow motion (1/4) <-> real time |

Sliders: spin (turns a second), nudge (% of the spin), speed, steps.
Moving the spin or nudge slider starts them again.
Rest the mouse on a handle to see which moment it's spun about, its axis's
tilt, its flips and how often they come.

## The theory, and what the console says

Spun about the middle axis, the handle's spin goes round a path that
passes close to the unstable one; Euler's equations can be solved exactly
for it, with elliptic integrals, and give the time between flips:
T/2 = 2 K(k) / w_p, here 3.3131 s (with
w_p = sqrt((I3 - I2)(L^2 - 2 E I1) / (I1 I2 I3)) and
k^2 = (I2 - I1)(2 E I3 - L^2) / ((I3 - I2)(L^2 - 2 E I1)) = 0.99968).
A smaller nudge brings the path closer and the flips further apart.

The console reports every flip, and every 10 s, for each handle, its
flips, how far its spin axis has wandered from straight up, and its
energy and angular momentum, relative to the start:

    --- spin 1.0 turns/s, nudge 1.0% ---
      Left   flipped at   1.67 s  (flip 1)
      Left   flipped at   4.98 s, 3.32 s after the last  (flip 2)
      Left   flipped at   8.28 s, 3.30 s after the last  (flip 3)
    t=   10s  Left: flips 3, axis wandered up to 90 deg, energy +8.0e-08, ang. mom. +4.0e-08 | Middle: flips 0, axis wandered up to 2 deg, energy +1.3e-07, ang. mom. +6.7e-08 | Right: flips 0, axis wandered up to 1 deg, energy +2.3e-07, ang. mom. +1.2e-07
    ...
      Left   flipped at 117.62 s, 3.30 s after the last  (flip 36)

* **The flip period is the test.** Each interval is printed as 3.30 or
  3.32 s (the console sees the flips once a frame, every 1/60 s); over
  two minutes, 36 flips, 35 intervals, their mean is 3.3129 s, against
  the exact 3.3131 s. The first flip comes at 1.67 s (exactly, 1.657 s),
  the 36th at 117.62 s (exactly, 117.615).
* **Energy and angular momentum are not a test.** The script holds them
  itself (below), so the console's figures, at most 4.3e-7 and 2.2e-7 in
  two minutes, show only Bullet's single-precision rounding. What they
  can't hold is where on its path the spin is; that's what sets the flip
  times.

## Physics

* Each handle is a Bullet rigid body: solid aluminium (2.7 g/cm^3), a bar
  1 cm across and 10 cm long, a stem 1.6 cm across and 4 cm long;
  42.9 g; moments of inertia 0.1021 (about the bar), 0.1850 (about the
  stem), 0.2775 (across both) kg cm^2. No gravity, and nothing touches
  anything (its outline is there for the mouse); Bullet only turns each
  handle as its spin says.
* Bullet's own handling of free rotation isn't good enough here.
  `bullet-rotation-test.lua` spins a body with moments 1:2:3 about its
  middle axis for a minute, 600 steps a second, and logs the spin; against
  the exact solution (21 flips, the first at 1.437 s):
  * its gyroscopic term off: nothing flips;
  * its "explicit" term: the spin gains energy, +59.1% (angular momentum
    +26.1%), and flips too often, 26 times;
  * its default ("implicit", in the body's frame, flag 8; and in the
    world's frame, flag 4, which does the same): the first
    flip is on time (1.433 s), but the spin drains away, energy -31.9%,
    angular momentum -17.5%; at 16 times the steps, still -3.3% and
    -1.7%.
* So the gyroscopic term is off, and before every physics step the
  script advances each handle's spin by Euler's equations itself, with
  RK4, then puts it back onto its starting energy and angular momentum:
  two Newton steps along the gradients of the two.
* 600 physics steps a second.

## Files

* `dzhanibekov.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`).
* `dzhanibekov-meshes/`: the handle (`t-handle.obj`) and
  `t-handle-data.lua`, its mass and moments of inertia.
* `bullet-rotation-test.lua`: the test of Bullet's own free rotation
  above. It prints nothing; it logs time and the body-frame spin to
  `DZ_LOG` (which it needs). `DZ_FLAGS` (0, 2, 4 or 8: off, explicit,
  implicit in the world's frame, implicit in the body's, the default), `DZ_HZ` (steps a second), `DZ_NUDGE`
  (rad/s; the spin is 10 rad/s), `DZ_EULER=1` (Euler's equations in the
  script, holding energy only, not angular momentum).

Headless testing: `DZ_SPIN` (turns a second), `DZ_NUDGE` (%),
`DZ_STEPS`, `DZ_LOG=file.csv` (time, handle, body-frame spin, tilt).
