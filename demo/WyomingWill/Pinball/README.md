# Pinball Machine A

A playable pinball table for the Bullet Physics Playground (bpp), in the
style of Williams' 1983 *Time Fantasy*: Bullet physics for the ball,
flippers, pop bumpers and slingshots; a small rules engine you can edit; a
seven-segment scoreboard in the backbox; hooks for sound effects; a ramp;
and a layout editor for reshaping the playfield before you play.

## Files

| File | What it is |
|---|---|
| `pinball-machine-a.lua` | The table. Open this in bpp. |
| `pinball-machine-a-rules.lua` | The game rules: points, target banks, bonus, multiplier, extra balls, balls per game, and which sound plays when. Edit it and reload the table. |
| `pinball-machine-a-ai.lua` | The computer player (press `P`). |
| `pinball-machine-a-brain.lua` | What the computer player has learned. Delete it to start it from scratch. |
| `pinball-machine-a-train.lua` | Trains the computer player without the display, much faster than real time. |
| `pinball-machine-a-sounds/` | Sound files (WAV, or OGG/FLAC/MP3 if your SDL_mixer supports them). Its README lists the expected names; missing ones are skipped. Your own sounds are included, with synthesised nudge, tilt and ramp sounds. |

## Requirements

bpp with the keyboard hook (`v:onKey`) added alongside this table: the
changes to `src/viewer.cpp` and `src/viewer.h`. Nothing else is needed.

## Keys

Click the 3D view first so it has keyboard focus. The Shortcuts pane always
shows the keys and, while editing, the position of every part.

**Layout editor** (before the first ball is launched):

| Key | Action |
|---|---|
| `L` | select the rollover lanes (as a group) |
| `1` `2` `3` … | select a pop bumper (1 left, 2 right, 3 bottom, 4+ added) |
| `B` | add a pop bumper (up to 9) |
| `Delete` | remove the selected added bumper |
| `A` | select the top arch: Up/Down raise or lower it (the lanes come with it), Left/Right shift its flat top |
| `O` | select the orbit entrance: the inner orbit wall, its post and targets |
| `X` | select the orbit exit: over the outlane, balls coming down the orbit drain; over the inlane, they come back to the flipper |
| `F` | select the flippers, inlane guides and slingshots (together) |
| `M` | select the ramp: the arrows move its entrance, `,` and `.` turn it 2.5° at a time (`0` puts both back) |
| arrows | move the selection: a tap moves 0.5 cm; hold to slide (speeds up the longer you hold) |
| `0` | put the selection back where it is in the default layout |
| `R` | reset the whole layout to the default (a saved layout is kept until you press `E`; reload the table to get it back) |
| `E` | finish editing and save the layout (launching the ball also does) |

Moves that would make parts collide, or leave a gap where the ball could get
stuck, are refused, and the Shortcuts pane says why. The layout is saved in
bpp's settings (not in the table's files) and restored the next time the
table is opened.

The default layout has the flippers and slingshots lowered (pivots 9.5 cm
up), which keeps the ball in play better and sends fewer balls down the
left side, with the pop bumpers, arch, orbit, lanes and ramp entrance
arranged to suit. The computer player averaged 80,000-90,000 on it,
against about 57,000 with everything where the table first builds it.

**Play:**

| Key | Action |
|---|---|
| `Return` | hold to draw the plunger back, release to launch (launching with no game running starts one) |
| `Left Shift` / `Right Shift` (or `Z` / `/`) | flippers |
| `Space` | shake (nudge) the machine: the ball gets a push up the table, and the view jolts. Too many shoves close together is a warning (DANGER); after two warnings in one ball, the next is a TILT |
| `1` | start a new game (when no game is running) |
| `P` | the computer plays, learning as it goes (press again to stop) |
| `V` | the view: the player's, at the front of the machine, or the whole machine from the side |

## The cabinet and artwork

The table stands in an arcade cabinet on four chrome legs:

- **Outside:** a black cabinet with yellow, orange and pink side stripes
  and slashes, chrome side rails and a lockdown bar, a coin door with lit
  price inserts, a start button and flipper buttons.
- **Backbox:** the scores, with a lit marquee reading PINBALL MACHINE A,
  ringed by chasing bulbs.
- **Playfield artwork:**
  - a sunburst behind the bumpers, whose colours swap every so often
  - a diamond above the flippers, and a band behind the multiplier lamps
  - chevron arrows that chase into the ramp and into the orbit (they move
    with them in the layout editor)
  - the apron below the flippers, with the machine's name

Between games the coin inserts and the start button blink. It's all only
for show: none of it touches the ball.

## The ramp

A clear plastic ramp climbs from the right-hand side of the playfield,
turns left over the top of the pop bumpers and runs back down the left
side, dropping the ball into the left inlane, so a made ramp comes straight
back to the left flipper. It's a shot for the left flipper: catch the ball
and flip it late, as it reaches the flipper's tip. A weak shot rolls back
out.

- **Scoring:** 100 for going up it, and each time it's made 5,000, then
  10,000, rising by 5,000 to 25,000 (the value goes back to 5,000 each
  ball). Both are in the rules file (`ramp`, and `rampEntrance` under
  `points`).
- **Moving it:** in the layout editor, `M` selects it. The arrows move the
  entrance and `,` `.` turn it. The rest of the ramp follows: it always
  turns at the top and drops the ball into the left inlane, wherever you've
  put the flippers.
- **What's refused:** a turn too tight, the ramp running into itself or off
  the playfield, and its low end near the entrance landing on something
  or leaving a gap where the ball could stick. The same checks stop you
  moving other parts into its way. The high part passes over everything.
- **How it works:** the glass sits just above the ball everywhere else, so
  it lets the ball through while the ball is on the ramp and until it's
  back down on the playfield. The ramp has its own clear cover.
  - Switches know whether the ball is up on the ramp or down on the
    playfield, so the targets under the ramp don't score for a ball riding
    over them.
  - The last stretch slows the ball, as a real ramp's wire return does, so
    it drops into the inlane instead of bouncing off the posts.

The ramp climbs only as high as it must to clear everything under it
(4.2 cm), in an S-shaped climb that starts and ends level, and turns as
soon as it has climbed: the ball has the tilted table to climb as well, so
every centimetre further up the table makes it harder. A ball rolling into
the mouth at about 1.4 m/s or faster makes it; slower ones roll back out.
In testing with the computer playing on a lowered-flipper layout, every
ball that went up that fast made it.

The computer player can make the ramp, but only by chance: it learns to
keep the ball in play, not to aim.

## Default rules

Pop bumpers 100 (added bumpers 100 each); each F-A-N-T-A-S-Y letter 1,000
and 1,000 bonus, all seven 25,000 and the extra ball lit at the blue ramp
target; all five top lanes 10,000 and the bonus multiplier up to 5x (the
flipper buttons shift which lanes are lit); the left loop 5,000, rising by
5,000 each time round to 25,000; the ramp likewise; bonus x multiplier added at each drain;
3 balls per game; the high score is kept. All of it is in the rules file.

**Tilt.** The tilt bob swings a little with each shove and settles over a
second; three shoves within about half a second swing it far enough for a
warning (DANGER on the display). The third warning in one ball is a TILT:
the flipper buttons, bumpers and slingshots go dead, nothing scores, and
the ball drains with no bonus. The next ball starts clean. The push, the
swing, the settling and the number of warnings are `tilt` in the rules
file (`warnings = false` turns tilting off).

## The computer player

Press `P` and the computer plays: it finishes the layout editor, starts a
game, pulls the plunger and works the flippers, game after game, until you
press `P` again. The console shows how it's doing: a line at each new ball
and game over, with the score and the computer player's record.

It learns as it plays:

- **Flippers: reinforcement learning (Q-learning).** Every frame the ball is
  near a flipper, it looks at where the ball is relative to that flipper
  and how fast it's moving, and chooses to flip or wait. A ball that goes
  back up the table counts as a success, one that drains between the
  flippers as a failure, and Q-learning passes that back to the choices
  that led there. Both flippers share what they learn (the right side is
  the mirror image of the left). A few percent of its choices are random,
  so it keeps discovering better timing.
- **Time counts.** Every frame the ball spends at the flippers costs a
  little (0.004), and every flip a little more (0.02), so the quickest way
  back up the table is worth the most. A ball that stays at the flippers
  for four seconds without going back up the table counts as badly as a
  drain. Without this it learned to keep the ball alive by flicking it
  over and over on the base of the flipper, where it barely moves: the
  ball never drained, but it never went anywhere either. The Shortcuts
  pane counts these "stalled" visits.
- **Plunger: a multi-armed bandit.** It tries eight plunger strengths and
  keeps a running average of how many points each one leads to, mostly
  using the best and now and then trying the others.

What it has learned is saved in `pinball-machine-a-brain.lua` (every 50
balls and when you stop it), so it carries on where it left off. The one
included has played about 2,900 games, the last 1,900 of them with time
counting (see above).

To train it faster than real time, without the display, run this from the
table's folder (60 frames = one second of play; bpp runs them as fast as it
can -- a million frames takes a few minutes):

    bpp -f pinball-machine-a-train.lua -n 1000000

A brain trained before time counted (one without `stalls =` on its third
line) still has the flicking habit; it unlearns it as it plays under the
new rules. About 500 games does it -- `-n 2000000`, fifteen minutes or so.

It can't nudge the table, so balls that go down the outlanes are lost to
it just as they are to you. If you change the layout, it adapts over a few
games: its view of the ball is measured from wherever the flippers are.
