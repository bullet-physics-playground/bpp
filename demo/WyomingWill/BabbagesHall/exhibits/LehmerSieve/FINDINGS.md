# Lehmer's number sieve: findings

`FINDINGS.pdf` beside this file is a typeset copy of it.

How the sieve was made to work in the simulation, in the order the
problems turned up. All the sizes live in `parts/make-geometry.py`.

## Choosing the mechanism

- **One turn, one place, every wheel.** Wheels of different sizes must each
  move on by one place for each step, whatever their number of places.
  Gearing them to one shaft would need a different ratio for each, and fine
  teeth. A **Geneva drive** does it by itself: one turn of its pin moves its
  star on by one slot, for a star of any number of slots, and its locking
  disc holds the star still for the rest of the turn. So the four stars sit
  on one axle, their drives on one shaft beside them, the pins all pointing
  the same way, so that every star moves in the same part of the turn
  (from 110 to 250 degrees for the 9, 126 to 234 for the 5).
- **A probe, not a falling ball.** A ball lying on the top wheel drops into
  the first open hole that passes under it and is then caught there by the
  next turn. So the probe is lifted, by a cam on the drive shaft, from 12 to
  100 degrees of each turn, before any wheel moves, and let down from 260 to
  348 degrees, after they have all stopped. It falls as far as the first
  pegged hole, under its own weight (18 g).
- **The wheels' sizes.** With the drive shaft 8.5 cm from the axle, the
  stars are 12 (5 places) to 15 cm (9 places) across. The ring of holes
  (radius 2.4 cm) lies inside the slots' inner ends, so the holes never
  meet a slot, whichever wheel is above.
- **What it sieves.** Fermat's way of factoring: the pegs are set by the
  number N. For 1241 the wheels leave open 3, 4, 4 and 3 of their 9, 8, 7
  and 5 holes, so 144 of every 2520 x pass all four (one in 17). 1241 was
  chosen for the tour because its first ten x hold two of them, one false
  (39) and one true (45), and every wheel has pegs for it.

## Convex pieces

The parts are not convex (holes, slots, arcs), and Bullet's contacts want
convex shapes. `make-geometry.py` cuts each outline into convex pieces (a
constrained triangulation, its triangles merged while they stay convex:
Hertel and Mehlhorn), and the simulation builds each body as a compound
of them. Three things about that:

1. **Corners inside an outline cost pieces.** Drawn as printed, the
   9-place star took 528 pieces. In the shape the contacts use, the holes
   are squares inside the round ones (a little more wheel round the probe,
   never less), the slots' ends square, the locking arcs drawn every 8
   degrees, and the bore filled (the axle is the hinge): 95 to 193 pieces
   a star. The printed shape is the fine one.
2. **The first merging was wrong** (it joined the wrong edges, and the
   pieces covered a third of each wheel). It is checked now: the pieces'
   areas add up to the outline's, and each piece is its own convex hull.
3. **bpp's Lua lets a compound have only a few dozen children** (each is
   kept alive by one of the compound's dependencies, and luabind has room
   for only so many: past it, bpp stops with an assertion). The bodies are
   built as trees of compounds of 12, neighbours together, which also keeps
   each group's bounds tight. And bpp's Lua has no upright cylinder
   (`btCylinderShape` has no constructor there): the shaft, pins, pegs and
   probe are `btCylinderShapeZ`, stood up.

## The tuning history

1. **Nothing collided.** An OpenSCAD part is made not to collide by the
   exhibit's `part()`; a part that becomes a body has to be made to collide
   again before it is added.
2. **The drive jammed 10 degrees into its first turn**, with the 7-place star
   pressed hard against its locking disc. The disc was cut away (its
   relief) only where the star passes in a perfect turn, 0.5 mm clear. But
   the pin has play in its slot, so a star leads or lags a little as it
   turns, and stands a little off its place between turns: the disc's
   edge caught it. The relief is now 1.5 mm clear of the star's path.
3. **The pin met a slot's corner** on the third turn of the tour (at 116
   degrees): the star it was coming to stood a little off its place, more
   than the pin's play (0.5 mm) at the slot's mouth, 8 cm out. **The
   locking disc doesn't put a star on its place.** Its rim and the star's
   arc are both circles round the drive's axis, so a star turned a little
   slides along the rim. Measured by turning the outlines against each
   other: with 0.2 mm between them, a star could still turn 1.2 to 1.6
   degrees either way, 2 mm at the slot's mouth.
4. **Making room instead didn't hold.** Opening the slots' mouths out (1.5
   to 2 mm) let the pin in, and the tour passed once; but a star then
   stopped short as the pin left it, by as much, and the locking disc's
   edge caught the end of its arc on the way in. Easing the arcs' ends (a
   ramp, 1.5 mm, over their last 15 degrees) helped, but the stars still
   wandered within their play (up to 0.03 of a place, with friction 0 too)
   until one wedged. Wider slots made the arcs shorter and the play worse
   (3 degrees).
5. **A detent for each star.** What fixed it was what the Pascaline has: a
   printed PLA leaf spring for each wheel, its round nose (10 mm) resting in
   the mouth of the slot opposite the drive, against both corners. It
   centres the star exactly. It is simulated as the Pascaline's is: a body
   on a hinge at the leaf's root, turned back by the leaf's own stiffness
   (3EI/L with PLA at 3.5 GPa: 1.2 x 5 mm, 30 mm long, so 0.25 N m a
   radian), pressed back 0.5 mm at rest, with a stop 1 mm further in so that
   between the slots the nose floats. With it, every star stands on its
   place to within 0.001 of a place between turns (before: up to 0.03), and
   the locking disc, 0.5 mm from the arc, only keeps it there. The slots
   are back to 0.5 mm of play on the pin, with no opening out; the arcs'
   eased ends are kept.

## The checks

The tour (1241: x from 36; the probe through 1, 0, 0, 4, 2, 1, 0, 0, 2 and 4
of the four wheels; stops at 39, not a square, and at 45: 17 x 73) checks at
every turn that the probe went exactly as far as the pegs say, and that the
wheels, read on their own (the Chinese remainder of their four places),
show the x the hand counted to.

| friction | turn rate (turns/s) | steps a second | result |
|---|---|---|---|
| 0.10 | 0.5 | 2400 | PASS |
| 0.25 | 0.5 | 2400 | PASS |
| 0.40 | 0.5 | 2400 | PASS |
| 0.25 | 0.25 | 2400 | PASS |
| 0.25 | 1.0 | 2400 | PASS |
| 0.40 | 1.0 | 2400 | PASS |
| 0.25 | 0.5 | 1200 | PASS |

The other numbers, with the tour's own checks (friction 0.25, half a turn a
second):

| N | x from | stops (false, then true) | result |
|---|---|---|---|
| 1241 (the tour) | 36 | 39, then 45: 17 x 73 | PASS |
| 1679 | 41 | 48: 23 x 73 | PASS |
| 1157 | 35 | 39, then 51: 13 x 89 | PASS |
| 2813 | 54 | 57, then 63: 29 x 97 | PASS |

It also passes inside the hall (`HALL_START=lehmer`), in the exhibit's own
sandboxed world.

Every STL checks as a single watertight solid (trimesh), and the parts do
not overlap at rest (manifold3d), with the wheels set for 1241 at x = 36:
every pair among the four wheels, the drive, the detents, their posts, the
frame and the probe. Over a whole turn, in the plan, each star clears its
locking disc and its pin everywhere (shapely, every 2 degrees).

## What it costs the computer

The sieve is the most expensive exhibit so far to step: four stars of 95 to
193 pieces and a drive of 179 (the cam is 72 of them), at 2400 steps a
second. Here (no graphics
card, one core) its tour of about 25 simulated seconds took about three minutes
of computing headless. At 1200 steps a second it took less than half that
and still passes (see the table), but it stays at the hall's 2400. Resting
(it stops stepping once the hand is idle and nothing has moved for half a
second) makes it free between turns.

## Seeing what it computes

The first version showed its working only in the console and in the
mouse's tooltips; in the 3D view the probe's depth was hidden inside the
stack, and nothing showed N, x or the answer. Now:

- **A depth scale** on the probe's guide (printed with it) and a pointer
  on the probe's top read how many wheels the probe went through. Its marks
  are where the probe's tip rests on each wheel (and on the bell), from the
  same geometry; the simulated probe comes to rest there to within 0.01 cm
  (6.50, 5.40, 4.30, 3.20, 2.25 cm, from the logs).
- **A board** (the exhibit's) shows N, x, each wheel's hole under the probe
  in green or red, the depth, and at a stop x * x - N, whether it is a
  square, y and the factors, on drums like a counter's, each turning
  forward to its new figure. Checked in the GUI: mid-tour, at a false stop,
  and at the end (1241 = 17 x 73); and choosing 1679 with `N` and running
  its tour with `T` (48: 23 x 73).
- `T` now runs the tour for the number `N` chose, not always 1241's.
- The hole numbers on the wheels are larger (5.5 mm, from 4.2).

The table grew to 120 x 80 to hold the board.

## Resting

Once the hand has nothing to do and nothing has moved for half a second,
the sieve stops stepping until there is something to do again (a key).
What is left moving once it has settled is about 0.002 cm/s and 0.001
rad/s; it rests below 0.05 cm/s and 0.02 rad/s.

## What a real build should watch

- **The detents** are what put the wheels on their places. Too stiff a leaf,
  and the pins have to force each star off its detent; too weak, and a
  star isn't centred. The leaf here is 1.2 mm thick.
- **The locking discs** must stand clear of the stars where the stars pass
  (the relief); file them back if a star catches as it starts or stops.
- **The pins and the cam** want to go on the shaft at their angles: the
  flat filed along the shaft and the D-shaped bores do that. A pin out of
  line moves its wheel at another part of the turn, perhaps while the probe
  is down.
- **The probe** must fall freely: 5 mm in 8 mm holes leaves 1.5 mm all
  round. A burr on a hole will hold it up.
