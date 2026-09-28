# Pinball Machine A

A playable pinball table for the Bullet Physics Playground (bpp), in the
style of Williams' 1983 *Time Fantasy*: Bullet physics for the ball,
flippers, pop bumpers and slingshots; a small rules engine you can edit; a
seven-segment scoreboard in the backbox; hooks for sound effects; and a
layout editor for reshaping the playfield before you play.

## Files

| File | What it is |
|---|---|
| `pinball-machine-a.lua` | The table. Open this in bpp. |
| `pinball-machine-a-rules.lua` | The game rules: points, target banks, bonus, multiplier, extra balls, balls per game, and which sound plays when. Edit it and reload the table. |
| `pinball-machine-a-ai.lua` | The computer player (press `P`). |
| `pinball-machine-a-brain.lua` | What the computer player has learned. Delete it to start it from scratch. |
| `pinball-machine-a-train.lua` | Trains the computer player without the display, much faster than real time. |
| `pinball-machine-a-sounds/` | Sound files (WAV, or OGG/FLAC/MP3 if your SDL_mixer supports them). Its README lists the expected names; missing ones are skipped. `bumper.wav` is included. |

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
| arrows | move the selection: a tap moves 0.5 cm; hold to slide (speeds up the longer you hold) |
| `0` | put the selection back where it was built |
| `R` | reset the whole layout to the default (a saved layout is kept until you press `E`; reload the table to get it back) |
| `E` | finish editing and save the layout (launching the ball also does) |

Moves that would make parts collide, or leave a gap where the ball could get
stuck, are refused, and the Shortcuts pane says why. The layout is saved in
bpp's settings and restored the next time the table is opened.

**Play:**

| Key | Action |
|---|---|
| `Return` | hold to draw the plunger back, release to launch (launching with no game running starts one) |
| `Left Shift` / `Right Shift` (or `Z` / `/`) | flippers |
| `1` | start a new game (when no game is running) |
| `P` | the computer plays, learning as it goes (press again to stop) |

## Default rules

Pop bumpers 100 (added bumpers 100 each); each F-A-N-T-A-S-Y letter 1,000
and 1,000 bonus, all seven 25,000 and the extra ball lit at the blue ramp
target; all five top lanes 10,000 and the bonus multiplier up to 5x (the
flipper buttons shift which lanes are lit); the left loop 5,000, rising by
5,000 each time round to 25,000; bonus x multiplier added at each drain;
3 balls per game; the high score is kept. All of it is in the rules file.

## The computer player

Press `P` and the computer plays: it finishes the layout editor, starts a
game, pulls the plunger and works the flippers, game after game, until you
press `P` again. The Shortcuts pane shows how it's doing.

It learns as it plays:

- **Flippers: reinforcement learning (Q-learning).** Every frame the ball is
  near a flipper, it looks at where the ball is relative to that flipper
  and how fast it's moving, and chooses to flip or wait. A ball that goes
  back up the table counts as a success, one that drains between the
  flippers as a failure, and Q-learning passes that back to the choices
  that led there. Both flippers share what they learn (the right side is
  the mirror image of the left). A few percent of its choices are random,
  so it keeps discovering better timing.
- **Plunger: a multi-armed bandit.** It tries eight plunger strengths and
  keeps a running average of how many points each one leads to, mostly
  using the best and now and then trying the others.

What it has learned is saved in `pinball-machine-a-brain.lua` (every 50
balls and when you stop it), so it carries on where it left off. The one
included has already played about a thousand games.

To train it faster than real time, without the display, run this from the
table's folder (60 frames = one second of play; bpp runs them as fast as it
can -- a million frames takes a few minutes):

    bpp -f pinball-machine-a-train.lua -n 1000000

It can't nudge the table, so balls that go down the outlanes are lost to
it just as they are to you. If you change the layout, it adapts over a few
games: its view of the ball is measured from wherever the flippers are.
