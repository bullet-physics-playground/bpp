# Rec Room

A 1970s basement games room, about 11 by 11 metres, with four playable
games in it:

- **Pinball Machine A**, against the back wall, between the bar and the
  jukebox.
- The **Pool Table**, the **Bumper Pool** table and the **Snooker Table**,
  one behind another down the right-hand side of the room. Each stands on
  its own rug with at least 1.5 m all round for the cue, and each has its
  scoreboard against the right-hand wall.

One of WyomingWill's clocks, **N7**, hangs on the back wall between the bar
and the pinball machine, running. The room also has wood panelling, a
carpet, a bar with stools and a shelf of bottles, flickering "GAME ROOM"
and "POOL" neon signs, a jukebox whose light bars move, a dartboard, two
cue racks, a sofa and coffee table across from the tables, a door and wall
lamps.

The games are the real ones from `../pinball-machine-a/`, `../pool-table/`,
`../snooker-table/` and `../bumper-pool/`, loaded unchanged. Everything
they do on their own works here too: scoring, sounds, the high scores,
saved layouts, the ramp, nudging and tilt, the computer players, and the
tables' cameras and aiming guides. All of it keeps running wherever you
stand: every computer player and the clock at once.

## Running it

Open `rec-room.lua` in bpp. The game folders must be next to this one, as
they are in the repository:

```
demo/claude/
  pinball-machine-a/     (or Pinball/)
  pool-table/            (or Pool/)
  snooker-table/         (or Snooker/)       optional
  bumper-pool/           (or BumperPool/)    optional
  rec-room/              <- this folder
```

The pinball machine and pool table are required. The snooker and bumper
pool tables and the clock are used if they're found; without one, the room
goes without it (the console says where it looked). The lists of folder
names it tries are near the top of `rec-room.lua`. It works with bpp built
on Lua 5.1 or on 5.2 and later.

## Keys

Click the 3D view first so it has keyboard focus.

| Key | Action |
|---|---|
| `Tab` | walk to the next spot: the pinball machine, the pool table, the snooker table, the bumper pool table, the clock, a view of the whole room, then back to the pinball machine |
| `Shift+Tab` | walk the other way |

Everything else goes to the game you are standing at, and its keys are the
same as when it runs by itself (the Shortcuts pane shows them, headed with
where you are):

- **At the pinball machine:** `Left Shift` / `Right Shift` (or `Z` / `/`)
  flippers, `Return` plunger, `Space` shake, `1` new game, `P` computer
  player, `V` its views, `E` edit the layout. See
  `../pinball-machine-a/README.md`.
- **At the pool table:** arrows aim and set the force, `W` / `A` / `S` / `D`
  spin, `Space` shoot, `G` guide, `V` / `B` / `T` cameras, `P` computer
  player, `N` re-rack. See `../pool-table/README.md`.
- **At the snooker table:** the same keys as the pool table. See
  `../snooker-table/README.md`.
- **At the bumper pool table:** the same keys again, plus `O` (white: the
  computer or a second player) and `L` (the computer's level). On its own
  the table also uses `Tab` to choose your next ball; here `Tab` walks on,
  so use `X` / `Z`, which do the same. See `../bumper-pool/README.md`.
- **At the clock:** `T` starts tuning its gravity toward 60 s for one turn
  of the second hand, `G` locks it, `S` turns the tick-tock on or off. Its
  gravity is the **clock_gravity** slider in the Params pane, and it
  applies to the clock alone.
- **Looking round the room:** the mouse turns and zooms the view as usual.

When you walk away from a game, any keys you are holding are let go (a raised
flipper drops; a drawn plunger launches), and the game carries on
running. A ball in play on the pinball machine keeps rolling while you are at
the pool table, and a computer player keeps playing while you're elsewhere.

## The clock

The clock is `N7_Clock_handcheck.lua`, loaded unchanged. The room looks
for it in `../Clocks/` or `../../WyomingWill/Clocks/` (where it is in the
repository); without it the room has no clock and everything else works.

- **Size:** built full size it is about 4 m tall, so it hangs at a quarter
  of that. Shrinking is done so the physics is unchanged: every length is
  scaled by 1/4, its gravity by 1/4 and its motor torques by 1/16, which
  gives the same motion in the same time. Its gravity slider keeps its
  usual values: 1166 means what it means when the clock runs on its own.
- **Physics settings:** the clock's escapement only works at the settings
  it was built with: bpp's usual 100 physics steps a second and its own ERP.
  At the tables' 900 steps a second it stalls. So the clock gets its own
  steps. Every frame, bpp steps the games as usual. Then, whenever the clock
  is due a step, the room freezes the games, steps the clock once with its
  own settings (and runs its script around it), and unfreezes them. The
  games get every frame, and everything runs all the time, wherever you're
  standing: every table's computer player, the pinball's and the clock
  together.
- **Pace:** the clock is due a step whenever it has had fewer than 25 for
  each real second since it started, the pace bpp's frame timer gives it
  when it runs on its own. The room measures that with a stopwatch (bpp's
  elapsed-time timer, the one the clock times its own beats with), never the
  time of day, and it only decides when the clock's world takes a step:
  nothing ever sets or corrects the hands, wheel or pendulum. So the
  clock's world runs at the same speed however busy the room is, and a
  gravity you tune and lock stays right while you play the other games.
- **Hold-ups:** if something holds the room up (a table's computer player
  can think for up to a second), the clock catches up on the next frames,
  taking up to 4 steps a frame (`MAX_CATCHUP`). A beat that falls in a
  hold-up is timed late and the next one early, but none are lost. After a
  hold-up of more than five seconds (bpp paused, say) the clock lets the
  rest go and says so in the console.
- **Older bpp:** stepping the clock within a frame needs bpp's
  `v:stepSimulation` (this commit's change to `src/viewer.cpp` and
  `src/viewer.h`). Without it the room falls back to taking turns: some
  frames step the games, others the clock (never two in a row), at 83
  frames a second. On a 60 Hz screen that leaves the games only about 35
  frames a second, running at about 60% speed.
- **Timing:** the beat is measured against real time. Tuning with `T` at
  the clock finds the gravity for that.

## The cost meter

The top of the Shortcuts pane shows what each frame spends its time on,
averaged over the last second, in milliseconds per frame:

```
COST METER -- ms per frame, averaged over the last second
  60 frames a second: 60 for the games, 25 clock steps
  physics  games 2.10, clock 0.80
  scripts  pinball 0.40, pool 0.50, snooker 0.44, bumper pool 0.19, clock 0.02, room 0.30
  garbage  0.10      drawing 3.00
  busy     7.9 of the 16 ms a frame has (49%)
```

- **frames a second:** the room's, how many of them stepped the games,
  and how many steps the clock took (which should be 25).
- **physics:** Bullet's time stepping the games and the clock. (They're
  one physics world, so it can't be split game by game.)
- **scripts:** each game's own Lua code, including its computer player,
  and the room's (taking turns, resting tables and so on).
- **garbage:** Lua's garbage collector. It runs only once the heap has
  grown by half since the last collection, a couple of milliseconds a frame
  until that collection is done, so this is usually near zero.
- **drawing:** bpp drawing the scene. Time the graphics card spends after
  that, and waiting for the next frame, isn't counted.
- **busy:** all of the above, against the 16 ms each frame has (a 60 Hz
  screen shows 60 frames a second; the room doesn't try for more). Over 100%
  and the room can't keep up: the games slow down. The clock keeps its pace
  as long as it can fit its steps in.

While the simulation is paused, the meter says so and shows only the
drawing and garbage time per drawn frame (bpp keeps drawing).

The same lines go to the console every 10 seconds, so they can be copied.
Set `METER_PRINT = 0` at the top of `rec-room.lua` to stop that, or
`METER = false` to turn the meter off. The stopwatch it uses ticks in whole
milliseconds, but averaged over a second's worth of frames the figures come
out right to about a hundredth of a millisecond.

## How it works

`rec-room.lua` runs each game in its own sandbox (a Lua environment of its
own) so the scripts can't interfere with each other:

- **Position.** Each game is moved to its place in the room (the clock is
  also shrunk). Positions it reads or sets are converted between its own
  coordinates and the room's, so the game's code doesn't need to know it
  has been moved.
- **Gravity.** The tables use ordinary gravity. The pinball
  playfield uses gravity tilted by 6.5°, and the clock whatever its slider
  says, each set on its own bodies only.
- **Camera and help text.** A game only controls the camera and the
  Shortcuts pane while you are standing at it.
- **Callbacks.** Each game's per-frame and key callbacks are collected, and
  the room calls them in turn.
- **Files.** The file each game opens, and each sound or mesh it loads, is
  looked up in that game's own folder.
- **Physics.** The pinball machine and the tables share a 1/900 s physics
  step, which the tables need for their breaks. The pinball flippers
  scale their motor strength to the step, so they flip exactly as they do
  on their own. The clock takes turns with them at its own settings (see
  above). Each game counts only its own frames, so its timers work as they
  do on their own.
- **Keys and sliders.** A game's keys, its keyboard shortcuts included,
  go to it only while you're at it. Its sliders are renamed in the Params
  pane when needed (the clock's gravity is `clock_gravity`).
- **Resting tables.** The tables keep their balls awake on purpose, so on
  their own they're solved 900 times a second even sitting still. Here, a
  table that's waiting for a shot, with every ball still, has its balls
  taken out of the simulation until the stroke begins (or anything moves
  them). The table's own scripts, its computer player included, carry on
  as usual.
- **Garbage.** bpp keeps Lua's garbage collector stopped, and each game
  normally collects everything every couple of seconds. The games share one
  Lua heap here, so each of those collections would clear the whole room's
  garbage at once, a noticeable pause. Instead the room collects
  gradually: once the heap has grown by half since its last collection, it
  collects for up to 2 ms a frame until done. The games' own full
  collections are skipped.

The room's own furniture is scenery only; it doesn't collide with anything.

## Requirements

- bpp with the keyboard hook (`v:onKey`) and `v:playSound`, which the
  games need as well.
- For a smooth frame rate, bpp with cached drawing (this commit's changes
  to `src/objects/mesh.cpp` and `src/glutils.cpp`): each mesh, and each
  sphere, cylinder, cone and cube shape, is compiled into an OpenGL display
  list once and replayed every frame, instead of being sent a triangle at
  a time. The clock's gears alone are well over 100,000 triangles. The
  room runs without it, only using more of the processor.
- bpp with `v:stepSimulation` (this commit's change to `src/viewer.cpp`
  and `src/viewer.h`), so the room can step the clock within the games'
  frames (see "The clock"). Without it the room still works, but the games
  get fewer frames.
- Also for speed, bpp that brings only moved objects' bounding boxes up to
  date (this commit's change to `src/viewer.cpp` and `src/viewer.h`).
  Bullet's default recomputes every object's box on every physics step,
  moving or not. With 900 steps a second and thousands of fixed parts
  (cushions, rails, scoreboard digits, scenery), that was most of the
  physics time at rest. Now Bullet updates only moving objects, and before
  each frame bpp updates any fixed or sleeping object a script has moved.
- OpenSCAD, for the clock's gears (as the clock needs on its own).
- The game folders beside this one, at least at the versions in this
  commit. The pinball's flipper strength now
  follows the physics step, and older copies would flip weakly in the room.
