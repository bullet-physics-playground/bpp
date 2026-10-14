# The Falling Slinky

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

## Keys

| Key | Action |
|---|---|
| `R` | hang it up again (it lets go after two seconds) |
| `Z` | a tenth of real speed <-> real speed |

Sliders: stiffness (N/m) and mass (g), which hang it up again with the new
setting half a second after you let go; hold (the seconds, on screen, it
hangs before the hand lets go); speed; steps. After each drop the console
prints when the bottom started to move and when theory says it should have,
how far the ball had fallen by then, and when the Slinky landed.

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
* The wire is drawn as a helix, 8 straight pieces a coil, running from each
  coil's height to the next one's.
* 4800 physics steps a second. It runs at a tenth of real speed, since the
  whole fall is over in half a second.

## Files

* `falling-slinky.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`).

Headless testing: `SL_COILS`, `SL_K` (N/m), `SL_MASS` (g), `SL_SPEED`,
`SL_LOG=file.csv` (time, top, bottom, the bottom's speed, the ball, the
centre of mass).
