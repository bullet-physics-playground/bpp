Sound effects for bumper-pool.lua. Replace any of these with your own
recordings (WAV; OGG/FLAC/MP3 too if your SDL_mixer supports them) using
the same names. A missing file is simply skipped.

  cue_hit.wav         the cue tip strikes a ball (louder for harder shots)
  ball_hit.wav        two balls click (volume follows how hard they hit)
  cushion.wav         a ball hits a cushion (volume follows how hard)
  bumper.wav          a ball hits a bumper (volume follows how hard)
  pocket.wav          a ball drops into a cup
  scratch.wav         a foul
  rack.wav            the balls are set up for a new game
  table_cleared.wav   the game is won

The ones included were synthesised (tools/make_sounds.py in the table's
package), not recorded.
