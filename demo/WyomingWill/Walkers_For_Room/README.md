# Walkers for the walker room

Copies of `../Walkers/<name>_parts.lua`, built by `../WalkerRoom/walker-room.lua`.
The walkers in `../Walkers/` are left as they are; changes made only so the
room can compare linkages fairly go here.

Six changes. First, `M.build` takes an option `bodyRaise` (default 0, the
walker's own units) that raises its body that much further above its feet
without changing its foot path, so every walker in the room can be given
the same body clearance.

| Build | How `bodyRaise` does it |
|-------|-------------------------|
| Chebyshev, Chebyshev diag, Hoecken, Hoecken slider, Hoecken-Spears slider | lengthens each pendant (`p_len`) |
| Chebyshev-Spears, Chebyshev-Spears diag | lengthens each pendant below C (`EXT_DOWN`) |
| Spears 4-bar, Jansen, Klann | moves the body relative to its crank mounts (no pendant: the leg is part of the linkage) |

Where a crossbar, a brace or the floor height (`FLOOR_TOP_Y`) depended on the
pendant's length, it follows it. With `bodyRaise` 0 every build is the same as
in `../Walkers/`. (The 2-leg Spears builds don't take it.)

Second, an option `foot = { length, width, thick, mass }` replaces every
foot with the same flat box: `length` along the walk, `width` across,
`thick` its thickness (all in cm, the room's units) and `mass`. Each foot
keeps its outer edge where it was. Jansen and Klann, whose files have a
foot builder but don't call it (their legs stand on the corner of a
link), get a pad of that size at the foot point, reaching outward from
the leg's outermost plane. Without `foot`, every build keeps its own
feet, and Jansen and Klann none.

Third, each build tells the room about its crank motors: if `M.onMotor` is
set, it is called with each motor's hinge, speed and impulse limit, so the
room can keep the cranks in step. Unset, nothing changes.

Fourth, an option `ankle` (true) hinges each foot to its leg about the
side-to-side axis instead of welding it -- the joint the 2-leg Spears'
own files use (limited to 90 degrees either way, the foot's turning
damped). The 2-leg Spears builds always have it.

Fifth, Jansen and Klann take `rows` (rows of legs: 3 in their own files,
2 makes them four-legged, with the body shortened to match),
`rowSpacing` (front-to-back spacing of the rows, their own units),
`rowPhase` and `sidePhase` (degrees between one row's crank and the
next's, and between a row's two sides: 105 and 45 in their own files),
and `hingeCFM` (how soft their hinges are: 0.1 in their own files, 0 --
the engine's default, as in every other build -- in the room).

Sixth, Chebyshev-Spears takes `sidePhase`: the phase of its back face's
legs (90 degrees in its own file; the room uses 180, as Chebyshev's).
