# Bumper Pool

Bumper pool for the Bullet Physics Playground (bpp). You play red against
the computer (white), or two people take turns. The table has twelve
bumpers, two cups and five balls a side, and you work the cue from the
keyboard. Bullet does the physics: the balls, the cushions and the
bumpers. The cue, spin, massé, the aiming guide and the cushions come from
the Pool Table.

## The game

Each side has five balls. One of them is marked with a spot of the other
colour.

- **Where the balls start:** red's balls start around the white cup, at
  your end. They are played into the red cup at the far end. White's balls
  go the other way.
- **No cue ball:** you shoot your own balls directly, any one you choose,
  but your **marked ball must go in first**.
- **Turns:** sink one of yours in your cup and you shoot again. Otherwise
  it's the other side's turn.
- **Winning:** the first side to sink all five wins.
- **The opening:** both marked balls are shot at the same moment.
  - You set up your shot and press Space. Then the computer (or the second
    player) sets up theirs, and both balls go together.
  - Each marked ball must bank off a side cushion first.
  - Whoever sinks his marked ball, or finishes nearer his cup, takes the
    first turn.
- **Fouls:** a foul lets the other side drop two of its own balls straight
  into its cup: its marked ball first, then the balls furthest from the
  cup. These are fouls:
  - sinking another of your balls before your marked ball (the ball stays
    down)
  - sinking one of your balls in the other cup. The ball goes back to where
    it started. If it was your last ball, you lose the game.
  - jumping a ball, over a bumper or a ball
  - knocking a ball off the table. The other side places it: your ball goes
    back where it started, theirs goes in front of their cup.
- **Knocking in the other side's balls:** a ball of theirs that you knock
  into their cup counts for them. A ball of theirs knocked into your cup
  goes back to where it started.

## The computer player

It sends the ball it's going to play off in every direction, a degree
apart, at eight speeds. For each shot it works out the ball's path off the
cushions and bumpers and over the cups: exactly, in straight lines between
bounces, using bounce figures measured from the simulation.

- **Choosing a pot:** among the shots that drop, it prefers ones that
  still drop with the aim or force slightly off. Shots where a small miss
  would send the ball into the other cup count against a pot. It aims at
  the middle of the range of angles that work. Then it checks the few best
  pots with the aiming guide's more detailed model before choosing.
- **With no pot worth trying:** it plays for position, leaving the ball
  near its cup with a clear run to it. It prefers slow shots with few
  bounces, and avoids passing over the other cup.
- **Level (`L`):**
  - Level 1: takes any pot it finds and misses its aim by about 3°.
  - Level 2: plays the safest pot, about 0.8° off.
  - Level 3: plays the safest pot, about 0.1° off.

Computer against computer, with no display, four games at each level:

| Level | Shots | Pots made / tried | Fouls |
|---|---|---|---|
| 1 | 91 | 21 / 45 (47%) | 3 |
| 2 | 71 | 28 / 47 (60%) | 2 |
| 3 | 73 | 30 / 47 (64%) | none |

Its misses at level 3 come from the simulation itself: long banks off
several cushions and bumpers can't be predicted to the centimetre.

**Thinking time.** Following all those paths used to take up to a third
of a second, and everything else waited, the picture included (in the rec
room, every other game too). Now the computer thinks a few milliseconds a
frame (`PLAN_BUDGET`, 0.003 s) and picks up where it left off on the next,
so the picture keeps moving and it starts swinging the cue a moment
later. It also reads the balls' positions once per shot rather than tens
of thousands of times, which roughly halved the time and the garbage left
for Lua's collector to a sixth. It chooses exactly the shots it did before.

## Running smoothly

- **Waiting for a shot.** The balls are set never to go to sleep, so the
  gentlest touch always moves them; on their own they'd be solved 900
  times a second sitting still. While the table waits for a shot with every
  ball still, it takes them out of the simulation, and puts them back as
  the stroke begins. That about halves what a waiting table costs.
- **No garbage from the picture.** The cue, the aiming guide, the ghost
  ball, the selector ring and the spin dot are moved every frame while you aim. They're
  placed with a few Bullet vectors and transforms filled in again each
  time, not new ones: new ones were garbage that held everything up now
  and then while Lua's collector swept it away.

## Files

| File | What it is |
|---|---|
| `bumper-pool.lua` | The table. Open this in bpp. |
| `bumper-pool-meshes/` | The cue and the spots on the marked balls. |
| `bumper-pool-sounds/` | Sound effects. Its README lists the names; replace any with your own. |

## Requirements

You need the same bpp changes as the Pool Table and the Snooker Table:

- the keyboard hook (`v:onKey`)
- `v:playSound(id, volume)`
- the `collides` object property

These are in `src/viewer.cpp`, `src/viewer.h`, `src/objects/object.cpp`
and `src/objects/object.h`.

## Keys

Click the 3D view first so it has keyboard focus. The Shortcuts pane lists
the keys. The console shows whose turn it is and the score whenever they
change, and each shot's aim, force and spin as it's played.

| Key | Action |
|---|---|
| `Tab` or `X` / `Z` | the next / previous of your balls. A yellow ring shows which one you'll play; choosing one aims it at your cup |
| `Left` / `Right` | aim: a tap turns a quarter degree; hold to swing |
| `,` / `.` | fine aim (a fiftieth of a degree a tap) |
| `Up` / `Down` | force, 1% a tap (hold to slide) |
| `W` / `S` | strike the ball higher (follow) or lower (draw) |
| `A` / `D` | strike it left or right of centre (side) |
| `C` | back to a centre-ball hit |
| `E` / `Q` | raise / lower the back of the cue. The cue raises itself as far as it must to clear a bumper or ball behind; a raised cue with side makes the ball curve |
| `Space` / `Return` | shoot |
| `G` | aiming guide, which cycles through three settings: (1) to the first cushion, bumper or ball, with the direction it comes off; (2) the whole path, green if it drops in your cup, red if in the other; (3) off |
| `V` | the view from your end of the table |
| `B` | camera behind the cue |
| `T` | camera overhead |
| `N` or `R` | new game |
| `O` | white: the computer, or a second player (turns alternate, and the view follows whoever is playing) |
| `L` | the computer's level: 1, 2 or 3 |
| `P` | the computer plays red as well. With both sides on the computer, a new game starts by itself a few seconds after each one ends |

The scoreboard past the red cup shows:

- a lamp for each side, lit on its turn and for the winner, with the
  number of balls it still has to sink
- games won ("SCORE", red–white, kept between runs)
- a message line (fouls, "4 TO GO", "NO POT")
- the force
- where the tip will strike the ball
- the computer's level

Sunk balls are shown in the tray along the right-hand rail: red's at your
end, white's at the far end.

## Physics notes

- Units are centimetres.
- The playing surface is 121.9 × 81.3 cm (48 × 32 inches), a common size.
  Real tables vary.
- Balls are 57.15 mm and 170 g.
- The cups are 8.6 cm holes, 6 cm from the end cushions.
- The bumpers have 6 cm rubber rings and stand 7 cm high.
  - Eight form the cross in the middle, with two arms of two along each
    axis.
  - Two guard each cup, 10 cm in front of it and 10 cm to either side.
- These are my approximations: the layout is standard, but the exact
  spacing varies from maker to maker.
- The cups are holes in the cloth, handled by the script.
  - A ball whose centre passes over a hole drops if it would fall more
    than 30% of its radius before it reached the far edge. Otherwise it
    skips across.
  - So slow balls drop, a fast ball straight across the middle can skip
    over (above about 2 m/s), and a ball clipping the edge must be slower
    still.
- The bumpers work like the cushions. A ball comes off at 80% of the speed
  it hit with (cushions 85%), and loses its roll into the rubber. Friction
  keeps about 88% of its speed along the surface.
- Full force is 6 m/s, lower than the pool table's: it's a short table
  and a short cue.
- Cushions, roll, spin, squirt, swerve and jumps otherwise work as on the
  Pool Table (see its README).
- The simulation runs at 900 steps a second.
