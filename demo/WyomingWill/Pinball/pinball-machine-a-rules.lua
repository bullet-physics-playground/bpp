--
-- pinball-machine-a-rules.lua -- the game rules for Pinball Machine A
-- (pinball-machine-a.lua)
--
-- Edit this file to change how the game scores, then reload the table to
-- load your changes (R during play, Ctrl+R, or reopen it). Everything here is plain Lua data, plus
-- one optional function at the end for rules that need real logic.
--
-- SWITCH NAMES used below (every place the ball can score):
--   leftBumper, rightBumper, bottomBumper       the three pop bumpers
--   bumper4, bumper5, ...                        bumpers added in the editor
--   leftSling, rightSling                       the two slingshots
--   F, A1, N, T, A2, S, Y                        the F-A-N-T-A-S-Y targets
--   top1 .. top5                                 the top rollover lanes
--   orbitEntrance                                entering the left orbit
--   leftLoop                                     travelling round the orbit
--   topLoop                                      going over the top arch
--   rampTarget                                   the blue target, upper right
--   lowerLeftStandup, upperLeftStandup,          the six 10-point standups
--   rightStandup1, rightStandup2, rightStandup3,
--   lowerRightStandup
--   leftInlane, rightInlane, leftOutlane, rightOutlane
--

return {

  -- balls per game (extra balls come on top of these)
  ballsPerGame = 3,

  -- Points for every hit of a switch. Switches that belong to a bank below
  -- score through the bank instead, so they are not listed here.
  points = {
    leftBumper = 100, rightBumper = 100, bottomBumper = 100,
    addedBumper = 100,        -- each bumper added in the layout editor (B);
                              -- one of them can be set alone, e.g. bumper4 = 250
    leftSling = 10, rightSling = 10,
    orbitEntrance = 500,
    topLoop = 1000,
    rampTarget = 3000,
    lowerLeftStandup = 500, upperLeftStandup = 500,
    rightStandup1 = 500, rightStandup2 = 500, rightStandup3 = 500,
    lowerRightStandup = 500,
    leftInlane = 1000, rightInlane = 1000,
    leftOutlane = 5000, rightOutlane = 5000,
  },

  -- Banks: groups of switches, each with a lamp. Hitting an unlit one lights
  -- it; lighting all of them gives the completion award and turns them all
  -- off again.
  --   litPoints       points for lighting one
  --   repeatPoints    points for hitting one that is already lit
  --   bonusPerLit     added to the end-of-ball bonus for each one lit
  --   completePoints  points for completing the bank
  --   onComplete      what completing it also does:
  --                     "advanceMultiplier"  raise the bonus multiplier
  --                     "lightExtraBall"     light the extra ball, to be
  --                                          collected at extraBall.collectAt
  --                     "extraBall"          award an extra ball at once
  --   flippersRotate  true: each flipper press shifts the lit lamps one place
  --                   (left flipper to the left, right flipper to the right),
  --                   so you can steer an unlit lane under the ball
  banks = {
    {
      name = "FANTASY",
      switches = { "F", "A1", "N", "T", "A2", "S", "Y" },
      litPoints = 1000, repeatPoints = 100, bonusPerLit = 1000,
      completePoints = 25000, onComplete = "lightExtraBall",
    },
    {
      name = "top lanes",
      switches = { "top1", "top2", "top3", "top4", "top5" },
      litPoints = 1000, repeatPoints = 100, bonusPerLit = 0,
      completePoints = 10000, onComplete = "advanceMultiplier",
      flippersRotate = true,
    },
  },

  -- The end-of-ball bonus is multiplied by this; it goes back to 1 each ball.
  multiplier = { max = 5 },

  -- Where a lit extra ball is collected.
  extraBall = { collectAt = "rampTarget" },

  -- The left loop's value rises each time round, and resets each ball.
  loop = { switch = "leftLoop", start = 5000, step = 5000, max = 25000 },

  -- Sound effects: event name -> file in the pinball-machine-a-sounds folder next
  -- to the table. WAV always works; OGG, FLAC and MP3 work if your SDL_mixer
  -- supports them. A missing file is just skipped, so add them as you go.
  -- A switch name (e.g. rampTarget = "ramp.wav") overrides its general event.
  sounds = {
    flipperUp    = "flipper_up.wav",     -- a flipper button pressed
    flipperDown  = "flipper_down.wav",   -- a flipper button released
    bumper       = "bumper.wav",         -- any pop bumper
    sling        = "sling.wav",          -- either slingshot
    target       = "target.wav",         -- a standup target
    rollover     = "rollover.wav",       -- a lane or inlane rollover
    outlane      = "outlane.wav",
    loop         = "loop.wav",           -- round the left orbit
    bankComplete = "bank_complete.wav",  -- a bank of targets or lanes completed
    multiplier   = "multiplier.wav",     -- bonus multiplier raised
    extraBallLit = "extra_ball_lit.wav",
    extraBall    = "extra_ball.wav",     -- extra ball collected
    plungerPull  = "plunger_pull.wav",
    launch       = "launch.wav",         -- plunger released
    drain        = "drain.wav",          -- ball lost
    bonusCount   = "bonus_count.wav",    -- played as the bonus is added up
    ballServe    = "ball_serve.wav",     -- new ball into the shooter lane
    gameStart    = "game_start.wav",
    gameOver     = "game_over.wav",
    highScore    = "high_score.wav",
  },

  -- Optional: extra rules in Lua. Called for every switch hit after the
  -- rules above have been applied. `game` offers:
  --   game.addScore(n), game.addBonus(n), game.advanceMultiplier(),
  --   game.lightExtraBall(), game.awardExtraBall(), game.playSound(event),
  --   game.message(text)   (shown on the scoreboard for a few seconds),
  --   game.score, game.ball, game.bonus, game.multiplier (read only)
  -- Example: double points for the ramp target on the last ball:
  --   onSwitch = function(game, name)
  --     if name == "rampTarget" and game.ball == game.ballsPerGame then
  --       game.addScore(3000)
  --     end
  --   end,
  onSwitch = nil,
}
