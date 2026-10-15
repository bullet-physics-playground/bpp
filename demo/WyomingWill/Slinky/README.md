# The Falling Slinky, and the Slinky on the Stairs

A Slinky hangs from a hand, stretched out by its own weight. Beside its
bottom, a steel ball hangs from a thread. The hand lets go of both at the
same moment.

The ball falls at once. The Slinky's bottom doesn't: it hangs in mid-air,
quite still, while the top comes down, coil after coil closing up. Only
when the collapsing coils reach it does the bottom move, and then the whole
Slinky falls together.

What holds the bottom up is the stretch of the coils just above it, and
that stretch can't change until news of the release gets there. The news
travels down the spring as the collapse itself. Until it arrives, the
bottom feels just what it felt before: gravity, and the same pull up. All
the while, the Slinky's centre of mass falls exactly as the ball does; the
top falls faster to make up for the bottom.

Right beside it, the same Slinky walks down a flight of seven stairs, end
over end, and starts again once it reaches the floor.

## Keys

| Key | Action |
|---|---|
| `R` | hang it up again (it lets go after half a second) |
| `V` | views: both Slinkys (to start with); the falling one and the ball close up; the stairs close up |
| `W` | set the Slinky on the stairs going again, from the top |
| `Z` | a tenth of real speed <-> real speed |

Sliders: stiffness (N/m) and mass (g), which hang it up again with the new
setting half a second after you let go (and set the one on the stairs going
again with it); hold (the seconds, on screen, it
hangs before the hand lets go); speed; steps. After each drop the console
prints when the bottom started to move and when theory says it should have,
how far the ball had fallen by then, and when the Slinky landed. For the
stairs it prints each time one of its ends lands on a step, and how long it
took to reach the floor.

## The theory

Once the hand lets go, nothing acts on the Slinky but gravity, so its
momentum is M g t. All of that momentum is in the collapsed coils at the
top, since the rest is still. Following the collapse down the hanging
spring with that, the bottom stays put for

    sqrt( M / 3k )

where M is the Slinky's mass and k its stiffness (for a spring with no
pre-tension). There's no g in it: on the Moon the bottom would hang for just
as long. The Slinky's closed-up length drops out too.

## The Slinky

The original metal one: 215 g, 86 coils 7 cm across, 5.6 cm tall closed up.
It's given no pre-tension (a real one has a little) and a stiffness of
1.76 N/m, so hung up it stretches 60 cm. The bottom should stay put for
0.202 s.

It stays put for 0.2038 s, while the ball beside it falls 20.4 cm: 1.0%
longer than the theory. Two things make that up, in about equal parts.

* **The coils.** The theory is for a smooth spring; this one is 86 coils,
  each a mass, joined by 85 springs, that stick when they meet. That chain,
  worked out on its own outside bpp (a plain mass-and-spring model with
  sticking collisions, a millionth of a second a step:
  `reconstruction/slinky-chain.c`), waits 0.2030 s:
  0.6% longer. With 43 coils it waits 0.2041 s, with 172, 0.2024, with
  344, 0.2021: half the gap each time the coils double.
* **The step.** Bullet, at 4800 steps a second, adds 0.4%: 0.2038 s, where
  9600 steps a second give 0.2033, 19200 give 0.2031 and 38400 give 0.2030,
  the chain's own. The step's share grows with the coils, because the
  collapse then passes each coil in fewer steps. So at 4800 steps a second
  more coils don't bring it closer: 43, 86 and 172 coils wait 0.2046,
  0.2038 and 0.2048 s. At 19200 they do: 0.2042, 0.2031, 0.2026 s.
  (`SL_COILS`, `SL_STEPS`; 19200 is beyond the steps slider, too slow to
  watch.)

The bottom is caught moving once it passes 1 cm/s; at 10 cm/s it's the same
0.2038 s, so that isn't it.

## Physics

* Each coil is a rigid body, 2.5 g. Each is joined to the next by a slide
  along the Slinky's axis. The slide stops the coils at their closed-up
  spacing (coils hitting coils, with no bounce) and keeps them square to
  each other.
* Between neighbours, a spring force acts whenever they're apart: k times
  85, since 85 springs in a row make k. It's applied before every physics
  step.
* It starts exactly as it hangs, each coil's stretch set from the weight
  below it, so nothing moves until the hand lets go.
* A twentieth of a second after it lands, it's laid to rest: a closed-up
  pile where it landed, kept still until it's hung up again. Left to
  themselves, 86 thin coils piled on each other jostle in Bullet, and now
  and then fly apart.
* The wire is drawn as a helix, 8 straight pieces a coil, running from each
  coil's height to the next one's.
* 4800 physics steps a second. It runs at a tenth of real speed, since the
  whole fall is over in half a second.

## The Slinky on the stairs

Seven steps, 12 cm up and 13 cm deep, from a landing 84 cm up. It starts as
a hand would set it going: half of it closed up in a pile at the top step's
front edge, the rest lifted over in an arch with its end set down on the
next step. The pile pours over into the arch; the far end becomes the pile;
and the Slinky turns end over end, each end landing one step lower than the
other did:

    stairs t= 0.65s  its first end lands on step 3
    stairs t= 0.92s  its other end lands on step 4
    stairs t= 1.26s  its first end lands on step 5
    stairs t= 1.71s  its other end lands on step 6
    stairs t= 1.99s  its first end lands on step 7
    stairs t= 2.39s  its other end lands on the floor
    stairs t= 3.03s  its first end lands on the floor
    stairs t= 3.75s  the walking Slinky comes to rest, on the floor: 7 steps down in 3.03 s

About 0.4 s a step (2.6 to 3.1 s for a clean walk, in simulated time; it runs at a tenth of
real speed, as the falling one does, so a walk takes half a minute on
screen; `Z` for real speed).

Each walk is a little different. Like a real one, it is sensitive: the
smallest difference in how a step goes changes the next, so the times vary
from walk to walk (1.9 to 3.1 s to the floor), and often one goes wrong. In
21 walks in a row, at the tenth of real speed it runs at: 12 went down every
step to the floor; 4 reached the floor but galloped, skipping a step or two;
3 stopped short on step 7; and 2 never got going, settling where they were
set down. So nearly one walk in two goes wrong. (At real speed, `Z`, the
landings are looked for only once a frame, a sixtieth of a second rather
than a six-hundredth, so a quick landing can be missed and a clean walk
logged as skipping a step; count them at a tenth of real speed.)
Whatever happens, it starts again three seconds after it comes to rest. These
stairs (12 cm up, 13 cm deep) are the size it walks best on; with deeper
treads it more often stops, with shallower ones it more often gallops.

It's the same Slinky as the falling one, built more simply:

* It moves in the plane of the drawing only (along the stairs and up and
  down, turning about the axis across them), which is how a Slinky walks.
* It's 43 pieces of two coils each. Each piece is a capsule as wide as the
  Slinky and as thick as two closed coils, so closed up the pieces touch.
  The pieces touch the stairs and each other.
* Each piece's two sides (its ends, either side of the middle) are joined to
  the next piece's by a spring that pulls when they're apart and never
  pushes: half of k times 42 each, so the two sides together make the
  Slinky's stiffness k, with a little damping (0.05 N s/m: without it the
  Slinky gallops more often, with twice as much it more often stops).
  Stretched on one side and closed on the other, the Slinky bends, as a
  real one does.
* A stiff spring between each two pieces' middles keeps them in line, so
  they can't slide sideways off each other.
* Each piece is drawn as a coil, and another coil is drawn half way to the
  next piece.

The stiffness and mass sliders set it too.

## Files

* `falling-slinky.lua`: the exhibit, both Slinkys. It also stands in
  Euler's Cabinet of Curiosities (`../Cabinet/`).
* `slinky-meshes/coil.obj`: one coil of the Slinky on the stairs, a ring of
  flat wire.
* `reconstruction/gen-meshes.py`: makes it (`python3 gen-meshes.py`, from
  that folder).
* `reconstruction/slinky-chain.c`: the plain chain of coils, worked out
  outside bpp, for the check above (`cc -O2 -o slinky-chain slinky-chain.c
  -lm`, then `./slinky-chain 86 1e-6`: coils, step).

Headless testing: `SL_COILS`, `SL_K` (N/m), `SL_MASS` (g), `SL_SPEED`,
`SL_STEPS`, `SL_LOG=file.csv` (time, top, bottom, the bottom's speed, the
ball, the centre of mass).
