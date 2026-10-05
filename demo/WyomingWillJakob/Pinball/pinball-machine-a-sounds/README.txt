Sound effects for Pinball Machine A (pinball-machine-a.lua)
===========================================================

Put sound files in this folder. The table looks for these names (set in
pinball-machine-a-rules.lua, under "sounds" -- change a name there to use a
different file). A file that isn't here is simply skipped, and the Debug
pane lists which ones were not found each time the table loads.

  flipper_up.wav        a flipper button pressed
  flipper_down.wav      a flipper button released
  bumper.wav            any pop bumper
  sling.wav             either slingshot
  target.wav            a standup target (including F-A-N-T-A-S-Y)
  rollover.wav          a top lane, inlane, orbit entrance or top loop
  outlane.wav           a ball entering an outlane
  loop.wav              round the left orbit
  bank_complete.wav     all of F-A-N-T-A-S-Y, or all five top lanes
  multiplier.wav        bonus multiplier raised
  extra_ball_lit.wav    extra ball lit (at the blue ramp target)
  extra_ball.wav        extra ball collected
  plunger_pull.wav      plunger pulled back
  launch.wav            plunger released
  drain.wav             ball lost
  bonus_count.wav       end-of-ball bonus added
  ball_serve.wav        new ball into the shooter lane
  game_start.wav
  game_over.wav
  high_score.wav
  nudge.wav             the machine shaken (Space)
  tilt_warning.wav      DANGER: shaken too much
  tilt.wav              TILT
  ramp_enter.wav        a ball going up the ramp
  ramp_made.wav         the ramp made

A single switch can have its own sound too: add a line to "sounds" in the
rules file named after the switch, e.g.  rampTarget = "ramp.wav",
and it plays instead of the general one for that switch.

Formats: WAV always works. OGG, FLAC and MP3 work if bpp's SDL_mixer was
built with them. Short files (well under a second) suit most of these.
