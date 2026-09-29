# Snooker Table

One-player snooker for the Bullet Physics Playground (bpp). It uses a
full-size 12-foot table with 15 reds and six colours, and you work the cue
from the keyboard. It's for practising break building, or you can press `P`
and let the computer play. Bullet handles the physics, including the break-off,
cushions, pockets and the cue ball's spin. The table is built on the Pool
Table's code: the cue, the aiming guide, spin, massé and the cushions all
work in the same way.

## The game: break building

The balls are set up as for a frame. The reds form a triangle behind the
pink, and the colours sit on their spots. The cue ball starts in hand in the
D.

- Pot a red (1 point), then a colour of your choice: yellow 2, green 3,
  brown 4, blue 5, pink 6 or black 7. The colour goes back onto its spot.
  Then pot a red again, and so on.
- Once the reds are gone, pot the colours in order from yellow to black.
  They stay down. Clearing the lot after 15 reds with 15 blacks makes 147.
- Every point you score without missing is your **break**. A miss ends the
  break. You carry on from wherever the balls lie with a new break, and the
  ball on goes back to a red (or to the lowest colour once the reds are
  gone). Your highest break is saved.
- You don't have to nominate a colour. After a red, the first colour the
  cue ball hits is taken as the one you chose.
- **Fouls** end the break. They're counted with the points they would give
  an opponent: the value of the ball on or the ball concerned, whichever is
  higher, and at least 4. These are fouls:
  - the cue ball goes in a pocket (an in-off; you get ball in hand in the D)
  - the cue ball hits nothing
  - the cue ball hits a ball that isn't on first
  - you pot a ball that isn't on
  - a ball leaves the table

  Colours potted on a foul are respotted. Reds stay down.
- A colour is respotted on its own spot. If that spot is covered, it goes
  on the highest free spot. If every spot is covered, it goes as near its
  own spot as it can, toward the top cushion.

This is a practice table, so a few match rules are left out: free ball, the
miss rule, the touching-ball rule and re-spotted black.

## Files

| File | What it is |
|---|---|
| `snooker-table.lua` | The table. Open this in bpp. |
| `snooker-table-meshes/` | The cue and the cue ball's dots. |
| `snooker-table-sounds/` | Sound effects (the same as the pool table's). |

## Requirements

You need the same bpp changes as the Pool Table:

- the keyboard hook (`v:onKey`)
- `v:playSound(id, volume)`
- the `collides` object property

These are in `src/viewer.cpp`, `src/viewer.h`, `src/objects/object.cpp`
and `src/objects/object.h`.

## Keys

Click the 3D view first so it has keyboard focus. The Shortcuts pane lists
the keys, and also shows the ball on, the aim, the force and the spin.

| Key | Action |
|---|---|
| `Left` / `Right` | aim: a tap turns a quarter degree; hold to swing |
| `,` / `.` | fine aim (a fiftieth of a degree a tap) |
| `Up` / `Down` | force, 1% a tap (hold to slide) |
| `W` / `S` | strike the cue ball higher (follow) or lower (screw) |
| `A` / `D` | strike it left or right of centre (side) |
| `C` | back to a centre-ball hit. Every shot starts from one, with the cue level |
| `E` / `Q` | raise / lower the back of the cue (swerve and massé; a steep, firm stroke can jump, but a ball leaving the table is a foul) |
| `Space` / `Return` | shoot |
| `G` | aiming guide on or off. The ghost ball turns red when the first ball the cue ball would hit isn't on |
| `V` | the starting view, from behind the baulk end |
| `B` | camera behind the cue (it follows your aim) |
| `T` | camera overhead |
| `N` or `R` | set up a new frame |
| `P` | the computer plays (press again to take over) |

With ball in hand, the arrows move the cue ball around the D, and `Space`
or `Return` puts it down.

The scoreboard past the top of the table shows:

- **BREAK**: the current break
- **HIGH**: your highest break
- **PTS**: the points scored this frame
- a message line (the last shot, the break when it ends, fouls)
- the force
- where the tip will strike the cue ball
- **ON**: a row of lamps showing the ball or balls on. A red lamp is lit
  for a red, and the colour lamps are lit for a free choice of colour.

## The computer player

Press `P` and the computer plays the frame from where it stands, trying to
build breaks. It uses no learning. For each shot it:

1. Looks at every pot on offer: each ball that is on, into each pocket. It
   checks that the paths are clear and estimates how likely each pot is from
   the cut angle and the distances.
2. For the best few pots, tries follow, stun and screw at several speeds.
   For each, it works out where the cue ball will end up, allowing for
   cushions.
3. Scores each position by what the next shot would be worth from there.
4. Chooses the shot with the most points expected over the two shots,
   counting a red as 3 because of the colour that follows.

If nothing is worth going for, it plays safe with a soft hit on a ball
that's on, or a one-cushion escape when it's snookered. It breaks off
thin off the end red of the triangle. With ball in hand, it searches the D
for the best place to put the cue ball.

I ran it on its own, with no display, on three frames. It cleared all
three:

| Frame | Points | Shots | Highest break | Fouls |
|---|---|---|---|---|
| 1 | 101 | 50 | 35 | none |
| 2 | 86 | 49 | 20 | one in-off |
| 3 | 107 | 53 | 21 | none |

## Physics notes

- Units are centimetres.
- The playing area is 356.9 × 177.8 cm (12 feet).
- Balls are 52.5 mm and 142 g.
- The baulk line is 73.7 cm from the baulk cushion, and the D has a radius
  of 29.2 cm.
- The black spot is 32.4 cm from the top cushion. The pink is midway
  between the blue and the top cushion.
- Snooker pockets are tighter and more rounded than pool pockets. Here they
  are about 8.9 cm at the corner mouths and 10.1 cm at the middles. These
  are approximations of a match table's templates.
- Cushions, roll, spin, squirt, swerve and jumps all work as on the Pool
  Table (see its README).
- The simulation runs at 900 steps a second.
