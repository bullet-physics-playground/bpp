# Pool Table

A one-player game of pool for the Bullet Physics Playground (bpp): a 9-foot
table with fifteen numbered balls (solids and stripes), a cue you control
from the keyboard, and a scoreboard. Bullet does the physics: the break,
cushions, pockets, and the cue ball's spin (follow, draw and side spin).

## The game: clear the table

The balls are racked at the foot spot. Break from the kitchen (behind the
head string, the line across the table through the white head spot at your
end), then pocket all fifteen in as few shots as you can. Any ball in any
pocket counts, in any order. Your best (lowest) score is saved.

- **Scratch** (the cue ball goes in a pocket): one extra shot, and ball in
  hand in the kitchen.
- **Shooting from the kitchen:** after a scratch you can't shoot straight
  at a ball that's also behind the head string. The aiming guide turns red
  and the shot is refused. The cue ball has to cross the line before it
  hits one.
- **Foul:** if it hits a kitchen ball before crossing the line anyway (off
  a cushion, say), that costs one extra shot, any balls it pocketed come
  back out onto the foot spot, and you have ball in hand in the kitchen
  again.
- **Off the table:** a ball that jumps off the table, or comes to rest on a
  rail, is also a foul, scored the same way; an object ball is spotted.

While the cue ball is in hand or shooting from the kitchen, the head string
is drawn across the table as a dashed line.

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
| `C` | back to a centre-ball hit. Every shot starts from one, with the cue level; the aim and force carry over |
| `E` / `Q` | raise / lower the back of the cue. Hitting down on the cue ball off centre makes it curve (a massé); only a little raised, a side-spin shot swerves gently. Steep and firm, it jumps: about 45–60° at 50–70% force clears a ball 30 cm away; harder, it may fly off the table |
| `Space` / `Return` | shoot |
| `G` | aiming guide on or off: the cue ball's path to a ghost ball where it will meet the first ball, then the object ball's path (yellow) and the cue ball's (blue, for a hit without spin). The path allows for spin: squirt and swerve from side spin, a massé's curve, and throw (the object ball dragged slightly off the line of centres) |
| `V` | back to the starting view, along the table (also undoes any turning or zooming with the mouse) |
| `B` | camera behind the cue (it follows your aim) |
| `T` | camera overhead |
| `N` or `R` | re-rack and start again |
| `P` | auto-play: the computer plays the rack for you. It breaks, picks the easiest pot each time, places the cue ball when it has ball in hand, and stops when the table is clear. Press `P` again to take over at any point |

With ball in hand the arrows move the cue ball around the kitchen (Up is
away from you; in the behind-the-cue view, along the aim) and `Space` or `Return` puts it
down.

The scoreboard past the foot of the table shows shots taken, balls left and
your best, the force as a bar of lamps, and where the tip will strike the
cue ball (the red dot on the white ball).

## The computer's thinking time

With ball in hand the computer tries well over a hundred spots for the cue
ball, which used to hold everything up, the picture included, for up to a
tenth of a second (in the rec room, every other game too). Now it thinks a
few milliseconds a frame (`PLAN_BUDGET`, 0.003 s) and picks up where it
left off on the next. It also reads the balls' positions once per shot
rather than thousands of times, which halved the time and leaves Lua's
garbage collector about a thirtieth as much to clear up. It chooses
exactly the shots it did before. The aiming guide reads them once per
redraw for the same reason.

## Physics notes

- Units are centimetres. The playing surface is 254 x 127 cm; balls are
  57.15 mm and 170 g; corner pockets are 11.3 cm at the mouth, side pockets
  13 cm.
- The shot is an impulse on the cue ball at the point the tip strikes,
  along the cue, so follow, draw, side spin and massé come from Bullet
  itself: the cloth's friction turns the spin into motion. With the cue
  raised, the part of the stroke driving the ball into the cloth is
  absorbed by the cloth, but its spin is kept, so the ball sets off along
  the cue and then curves. Side spin also pushes the ball slightly off the
  cue's line (squirt, up to 1.5°), so aim a little to allow for it.
- The cue is raised by itself as far as it must be to clear the rail or a
  ball behind the cue ball, and such shots curve too, as they would on a
  real table.
- Jumps: a steep, firm stroke drives the ball into the slate, which throws
  it back up; the cloth's grip takes some of its forward speed. A falling
  ball bounces off the cloth at half its speed. (Bullet's cloth itself
  doesn't bounce, so rolling stays smooth; the script supplies both
  bounces.)
- Rolling resistance and side spin wearing off are added by the script
  (Bullet has no rolling friction for spheres).
- The cushion noses sit a little above the middle of the ball, as on a real
  table, so balls don't climb them.
- Cushions (and pocket jaws, more softly) are handled partly by the
  script: a ball comes off at 85% of the speed it hit with, whatever that
  speed, and the cushion's nose takes away its roll into the cushion so it
  leaves rolling outward. On its own Bullet let slow balls stop dead or
  slide along the rail, and let a rolling ball's spin drag it back after
  the bounce.
- Rolling resistance is about 1% of gravity, so a ball rolling at 1 m/s
  travels about 5 m.
- The simulation runs at 900 steps a second so the break spreads the rack
  the way a real one does.
