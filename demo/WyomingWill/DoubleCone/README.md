# The Double Cone

Two cones joined base to base sit on two rails that rise and spread apart
like a V. Let go at the low, narrow end, and the double cone rolls up to
the high, wide end: uphill, it seems.

It doesn't really. As the rails spread, they meet the cone nearer its
points, where it's thinner, so it sinks between them faster than they
rise. Its centre of mass goes down all the way. It was a favourite of
18th-century lecture rooms, where instrument makers sold it as a
"mechanical paradox".

Three tracks stand on a table, back to front:

| Track | What happens |
|---|---|
| back (brass cone) | rails rising 1.5 cm over 50: the cone rolls up |
| middle (cylinder) | the same rails: a plain cylinder rolls down |
| front (steel cone) | rails rising 5 cm over 50, too steep: the same cone rolls down |

When all three have come to rest at an end, they're set going again.

## Keys

| Key | Action |
|---|---|
| `R` | set them going again |
| `Z` | slow motion (1/4) <-> real time |

Rest the mouse on a roller to see where it is, and where the geometry says
its centre should be.

## The theory

The rails rise at a slope tan(theta) and spread at tan(phi) on each side.
Where a rail meets the cone, the cone's radius shrinks by R/H for each cm
out from the middle (R is its radius at the middle, H each cone's length).
So the centre goes down as the cone rolls up if

    tan(theta) < tan(phi) R / H

Here tan(phi) R/H = 0.14 x 5/12 = 0.058. The back rails rise at 0.03, so
the cone rolls up; the front ones at 0.10, so it rolls down.

The console checks two things for each roller, all the way along:

    Back   nears the high, wide end at 2.32 s, having rolled 36.8 cm up the rails (the rails rising 1.10 cm): its centre went down 1.045 cm (the geometry: 1.045),
           off the geometry by 0.0000 cm at worst on the way; it lost 0.14% of the energy its centre's fall gave it

* **The geometry.** Where the centre should be, for the roller wherever it
  is along the rails, worked out exactly: the rails' thickness, the point
  where each rail touches the cone (not straight under its middle, since
  the rails slope), and Bullet's collision margin. The centre stays within
  a micron of it.
* **Energy.** Rolling without slipping, a roller keeps its energy: kinetic
  (moving and turning) plus potential. It loses 0.1 to 0.3% of what its
  centre's fall gave it.

## The pieces

* The double cone: radius 5 cm at the middle, each cone 12 cm long, 400 g,
  solid. Its moment of inertia is 3/10 m R^2 about its axis.
* The cylinder: radius 3 cm, 26 cm long, 400 g.
* The rails: 8 mm brass rods, 5 cm apart at the low end and 19 cm at the
  high end, 50 cm long, with stops at the ends.

## Physics

* Bullet, with its own contacts. The cone is a compound of two cone shapes,
  and the cylinder a cylinder shape.
* Each rail is a row of 10 cm capsules end to end. Bullet finds contacts on
  one long rod less surely: with a single 54 cm cylinder, the cone hit an
  invisible bump halfway up and rolled back. With 3 cm pieces it lost a few
  per cent of its energy at the joins. With 10 cm pieces both problems go.
* Friction 0.81 where a roller touches a rail (0.9 is set on each, and
  Bullet multiplies the two): high, so they roll without slipping. 2400
  physics steps a second.

## Files

* `double-cone.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`).
* `double-cone-meshes/`: the double cone, the cylinder and their painted
  stripes.
* `reconstruction/gen-meshes.py`: makes them (`python3 gen-meshes.py`, from
  that folder).

Headless testing: `DC_SPEED`, `DC_STEPS`, `DC_LOG=file.csv` (time, track,
x, the centre's height, the geometry's, energy).
