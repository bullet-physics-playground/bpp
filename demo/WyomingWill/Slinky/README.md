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
| `R` | hang it up again (it lets go after two seconds) |
| `V` | views: both Slinkys (to start with); the falling one and the ball close up; the stairs close up |
| `W` | set the Slinky on the stairs going again, from the top |
| `Z` | a fifth of real speed <-> real speed |

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

It stays put for 0.204 s, while the ball beside it falls 20 cm. The 1%
difference is the coils: the theory is for a smooth spring, and a spring of
86 separate coils lags slightly behind it. With more coils (`SL_COILS`) it
comes closer, as an independent check outside bpp (a plain mass-and-spring
model with sticky collisions) also shows.

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
* Only the bottom coil touches anything (the floor); the rest stop on each
  other through their slides, so Bullet needn't look for contacts between
  coils piled close together. Each coil is drawn as a ring of flat wire.
* 4800 physics steps a second. It runs at a fifth of real speed, since the
  whole fall is over in half a second.

## The Slinky on the stairs

Seven steps, 12 cm up and 13 cm deep, from a landing 84 cm up. It starts as
a hand would set it going: half of it closed up in a pile at the top step's
front edge, the rest lifted over in an arch with its end set down on the
next step. The pile pours over into the arch; the far end becomes the pile;
and the Slinky turns end over end, each end landing one step lower than the
other did:

    stairs t= 0.64s  its first end lands on step 3
    stairs t= 0.92s  its other end lands on step 4
    stairs t= 1.29s  its first end lands on step 5
    stairs t= 1.60s  its other end lands on step 6
    stairs t= 1.97s  its first end lands on step 7
    stairs t= 2.32s  its other end lands on the floor
    stairs t= 2.95s  its first end lands on the floor
    stairs t= 3.66s  the walking Slinky comes to rest, on the floor: 7 steps down in 2.95 s

About a third of a second a step (in simulated time; it runs at a fifth of
real speed, as the falling one does).

Each walk is a little different. Like a real one, it is sensitive: the
smallest difference in how a step goes changes the next, so the times vary
by a few tenths of a second from walk to walk, and about one walk in five
goes wrong: it gallops, skipping a step or two, or stops short on a step.
Either way, it starts again three seconds after it comes to rest. These
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
  Slinky's stiffness k, with a little damping (0.05 N s/m: without it
  the Slinky gallops more often, with twice as much it more often stops). Stretched on one side and
  closed on the other, the Slinky bends, as a real one does.
* A stiff spring between each two pieces' middles keeps them in line, so
  they can't slide sideways off each other.
* Each piece is drawn as a coil, and another coil is drawn half way to the
  next piece.

The stiffness and mass sliders set it too.

## Files

* `falling-slinky.lua`: the exhibit, both Slinkys. It also stands in
  Euler's Cabinet of Curiosities (`../Cabinet/`).
* `slinky-meshes/coil.obj`: one coil, a ring of flat wire.
* `reconstruction/gen-meshes.py`: makes it (`python3 gen-meshes.py`, from
  that folder).

Headless testing: `SL_COILS`, `SL_K` (N/m), `SL_MASS` (g), `SL_SPEED`,
`SL_LOG=file.csv` (time, top, bottom, the bottom's speed, the ball, the
centre of mass).
