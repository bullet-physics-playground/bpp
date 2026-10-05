Sound effects for pool-table.lua. Replace any of these with your own
recordings (WAV; OGG/FLAC/MP3 too if your SDL_mixer supports them) using
the same names. A missing file is simply skipped.

  cue_hit.wav         the cue tip strikes the cue ball (louder for harder shots)
  ball_hit.wav        two balls click (volume follows how hard they hit)
  cushion.wav         a ball hits a cushion (volume follows how hard)
  pocket.wav          an object ball drops
  scratch.wav         the cue ball drops
  rack.wav            the balls are racked
  table_cleared.wav   the last ball is down

The ones included were synthesised (make_sounds.py alongside the table's
package), not recorded.
