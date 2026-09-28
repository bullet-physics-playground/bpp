# Pool Table

A one-player game of pool for the Bullet Physics Playground (bpp): a 9-foot
table with fifteen numbered balls (solids and stripes), a cue you control
from the keyboard, and a scoreboard. Bullet does the physics: the break,
cushions, pockets, and the cue ball's spin (follow, draw and side spin).

## The game: clear the table

The balls are racked at the foot spot. Break from behind the head string,
then pocket all fifteen in as few shots as you can. Any ball in any pocket
counts, in any order. Pocketing the cue ball (a scratch) costs one extra
shot and gives you ball in hand anywhere on the table. Your best (lowest)
score is saved.

## Files

| File | What it is |
|---|---|
| `pool-table.lua` | The table. Open this in bpp. |
| `pool-table-meshes/` | The cue and the ball markings (number spots, stripes, the cue ball's dots). |
| `pool-table-sounds/` | Sound effects. Its README lists the names; replace any with your own. |

## Requirements

bpp with the keyboard hook (`v:onKey`), the `v:playSound(id, volume)`
overload and the `collides` object property: the changes to
`src/viewer.cpp`, `src/viewer.h`, `src/objects/object.cpp` and
`src/objects/object.h` that come with this table.

## Keys

Click the 3D view first so it has keyboard focus. The Shortcuts pane shows
the keys along with the current aim, force and spin.

| Key | Action |
|---|---|
| `Left` / `Right` | aim: a tap turns a quarter degree; hold to swing (faster the longer you hold) |
| `,` / `.` | fine aim (a fiftieth of a degree a tap) |
| `Up` / `Down` | force, 1% a tap (hold to slide); the cue draws back further the harder you'll hit |
| `W` / `S` | strike the cue ball higher (follow) or lower (draw) |
| `A` / `D` | strike it left or right of centre (side spin) |
| `C` | back to a centre-ball hit |
| `Space` / `Return` | shoot |
| `G` | aiming guide on or off: a line to a ghost ball where the cue ball will meet the first ball, the object ball's path (yellow) and the cue ball's (blue, for a hit without spin) |
| `V` | camera: along the table, behind the cue, or overhead |
| `N` or `R` | re-rack and start again |

With ball in hand the arrows move the cue ball (Up is away from you; in
the behind-the-cue view, along the aim) and `Space` or `Return` puts it
down.

The scoreboard past the foot of the table shows shots taken, balls left and
your best, the force as a bar of lamps, and where the tip will strike the
cue ball (the red dot on the white ball).

## Physics notes

- Units are centimetres. The playing surface is 254 x 127 cm; balls are
  57.15 mm and 170 g; corner pockets are 11.3 cm at the mouth, side pockets
  13 cm.
- The shot is an impulse on the cue ball at the point the tip strikes, so
  follow, draw and side spin come from Bullet itself: the cloth's friction
  turns the spin into motion.
- Rolling resistance and side spin wearing off are added by the script
  (Bullet has no rolling friction for spheres).
- The cushion noses sit a little above the middle of the ball, as on a real
  table, so balls don't climb them.
- The simulation runs at 900 steps a second so the break spreads the rack
  the way a real one does.
