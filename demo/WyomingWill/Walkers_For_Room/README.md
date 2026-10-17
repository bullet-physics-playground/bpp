# Walkers for the walker room

Copies of `../Walkers/<name>_parts.lua`, built by `../WalkerRoom/walker-room.lua`.
The walkers in `../Walkers/` are left as they are; changes made only so the
room can compare linkages fairly go here.

Seven changes. First, `M.build` takes an option `bodyRaise` (default 0, the
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
`cube_d` (the body's depth, which sets how far apart their two sides'
legs are: 150 in their own files), and `hingeCFM` (how soft their hinges are: 0.1 in their own files, 0 --
the engine's default, as in every other build -- in the room).

Sixth, Chebyshev-Spears takes `sidePhase`: the phase of its back face's
legs (90 degrees in its own file; the room uses 180, as Chebyshev's).

Seventh, Chebyshev-Spears takes `geometry = { g, a, h, r, leg, legAngle,
groundAngle }`: the ground link, crank, coupler-to-rocker-joint, the
rocker (unset: h), the leg from that joint, the leg's angle off the
coupler, and the ground link's angle, in its own units, so that the same
file builds other linkages of its kind (the room's Hoecken-Spears 4-bar
and long-stance, and Spears lift 44 and 53). Unset, it is
Chebyshev-Spears (2.5, 1.875, 5.729, 5.729, 5.729, 90, -45).
Chebyshev-Spears diag takes the same `geometry`.

Eighth, the two diag builds take `diagGive`: how far, in degrees, their
braces may turn on the legs they are welded to (3 in their own files,
against crank drift; the room uses 0, its cranks being locked).

Jansen's and Klann's feet (`foot`) reach inward from the outer face of
their outer links, as the other builds' do, so that every walker's
stance is measured the same way, and grip as the others' (friction 0.8;
0.9 in their own files).
