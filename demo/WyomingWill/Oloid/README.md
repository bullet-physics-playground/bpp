# The Oloid and the Sphericon

Three wooden rollers, each the convex hull of two circular arcs, are given
a push along a level board. None of them is round, yet each one rolls. As
it rolls, every part of its surface touches the board: it lays its whole
surface down, as a cylinder or a cone does, but in a wobbling, weaving
line.

| Roller | What it is |
|---|---|
| back: the oloid (Paul Schatz, 1929) | two circles in perpendicular planes, each through the other's centre. Its centre of mass rises and falls a little as it rolls. |
| middle: the two-circle roller (A. T. Stewart, 1966) | the same, but with the circles' centres R sqrt(2) apart. Its centre of mass stays at exactly one height as it rolls, so on a level table it would stay put wherever it was set down. |
| front: the sphericon | a double cone with right angles at its points, cut along its axis and one half turned a quarter turn. It rolls on one cone, then the other, weaving from side to side. Its centre of mass stays at one height too: R / sqrt 2. |

When all three have reached the far end, they're pushed off again.

## Seeing it: the pens

The centres' heights change by a quarter of a centimetre at most, too
little to see, so each roller carries a pen:

* **Above each roller**, on a dotted stem from its centre, a pen draws its
  centre's height, magnified 20 times, in a line straight above its lane.
  * The oloid's (red) line waves between two thin rods: the lowest and
    highest its centre can be, in theory, R/√2 and 3R/4.
  * The two-circle roller's (blue) and the sphericon's (green) lines lie
    flat on their one rod, at R/√2.
* **On the board**, a dotted track under each roller marks where its
  centre has been, so its weaving from side to side shows there and not
  in the height line.

## Keys

| Key | Action |
|---|---|
| `R` | push them off again |
| `Z` | slow motion (1/4) <-> real time |

Rest the mouse on a roller to see how high its centre is.

## The theory, and what the console says

As the script loads, it works out from the shapes alone how high each
roller's centre of mass is, for every way the roller can lie on the board
touching it along a line (both arcs touching). Then it compares what each
does as it rolls:

    Oloid     461.5 g; lying along a line on the board, its centre is between 4.2426 and 4.5000 cm up (theory)
    2-circle  496.2 g; lying along a line on the board, its centre is always 4.2426 cm up (theory)
    Sphericon 316.7 g; lying along a line on the board, its centre is always 4.2426 cm up (theory: R/sqrt 2 = 4.2426)
    Sphericon reaches the far end at 3.93 s, 108.3 cm along the board, weaving 5.8 cm side to side:
              its centre 4.2426 to 4.2426 cm up (theory: 4.2426 to 4.2426);
              energy: of what the push gave it, 6.6% went to rolling resistance, and 0.229% otherwise (rolling without slipping, it should lose none)
    ...
    Oloid     reaches the far end at 9.02 s, 108.8 cm along the board, weaving 5.1 cm side to side:
              its centre 4.2426 to 4.5000 cm up (theory: 4.2426 to 4.5000);

* **The centre's height.** It stays at 4.2426 cm for the two-circle roller
  and the sphericon, within a micron. For the oloid it goes up
  and down between the two limits, R/sqrt 2 and 3R/4.
* **Energy.** Rolling without slipping, a roller loses only what the
  rolling resistance takes. The rest of the loss is the step size: 0.2 to
  0.7% at 2400 steps a second, and about a fifth of that at 9600.

## The rollers

Each is made from arcs of radius 6 cm, in a light wood (0.7 g/cm^3): the
oloid weighs 462 g, the two-circle roller 496 g and the sphericon 317 g.
Their volumes, centres of mass and moments of inertia are worked out from
their shapes by `reconstruction/gen-meshes.py`: the oloid's volume comes to
3.0524 R^3, as it should.

Each is set down so that, on average, it rolls straight along the board.
The direction that does it isn't across the line of the circles' centres
but 12 to 26 degrees off it, found by trying. Then each is pushed off at
15 cm/s.

## Physics

* Bullet moves each roller, a rigid body. Its contact with the board is
  worked out in the script, before every physics step, exactly for its
  shape:
  * the lowest point of each of its two arcs, where it touches the board
    (along the line between them);
  * impulses that stop it going into the board, and friction (0.6, so it
    doesn't slip), solved together eight times over, as Bullet solves its
    contacts;
  * Euler's equations for its spin (Bullet's gyroscopic term is off).
* A little rolling resistance (20 microns) slows each roller.
* 2400 physics steps a second.
* On a sloping board they run faster and faster. Past about 40 cm/s, one
  arc's push on the board nearly vanishes as they wobble, and they skid.
  That's why the board is level and they're pushed.

## Files

* `oloid.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`).
* `oloid-meshes/`: each roller and its two arcs (painted), and
  `rollers.lua`, their arcs and mass properties.
* `reconstruction/gen-meshes.py`: makes them (`python3 gen-meshes.py`, from
  that folder; it needs NumPy and SciPy).

Headless testing: `OL_SPEED`, `OL_STEPS`, `OL_PUSH` (cm/s), `OL_SLOPE`
(degrees: the board tilted down along it), `OL_LOG=file.csv`.
