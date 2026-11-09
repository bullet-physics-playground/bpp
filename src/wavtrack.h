#ifndef WAVTRACK_H
#define WAVTRACK_H

#include <QString>
#include <QtGlobal>

#include <vector>

#include <SDL2/SDL_mixer.h>

class ToneSynth;

/**
 * @brief An exported scene's sound track: the sounds played while exporting,
 * mixed into a @c .wav that keeps in step with the exported frames.
 *
 * Each sound played is recorded with the frame it starts at; each exported
 * frame then mixes what was recorded into the track, with the tone synth's
 * voices, and appends the frame's share of it, 1/25 s -- the rate the
 * export's GNUmakefile encodes at -- so the file on disk is always a complete
 * WAV as long as the video. The track is started by the first sound, padded
 * with silence back to the export's first frame, so a scene that plays
 * nothing gets no @c .wav. A new export starts the track over.
 */
class WavTrack {
public:
  /**
   * @brief Queues a sound just played.
   *
   * A sound played after the current frame was exported (from postSim, say)
   * is first seen in the next exported frame and is queued for that one.
   *
   * @param chunk    The sound played (loaded chunks live as long as the
   *                 Viewer).
   * @param volume   Its volume from 0 to 1.
   * @param frameNum The frame being simulated.
   */
  void record(Mix_Chunk *chunk, double volume, int frameNum);

  /**
   * @brief Writes an exported frame's audio to the track.
   * @param file       Path of the scene's @c .wav.
   * @param firstFrame The export's first frame.
   * @param frameNum   The frame exported.
   * @param synth      The tone synth, whose voices go into the track too.
   */
  void write(const QString &file, int firstFrame, int frameNum, ToneSynth &synth);

private:
  struct Event {
    int frame;        ///< Exported frame the sound starts at.
    Mix_Chunk *chunk; ///< The sound.
    double volume;    ///< Volume from 0 to 1.
  };
  std::vector<Event> _events; ///< Sounds played since the last frame.
  std::vector<int> _mix;      ///< Mixed samples not written yet, the first
                              ///< one at _written.
  QString _file;              ///< The track being written.
  int _firstFrame = 0;        ///< Export start the track was begun for.
  int _frame = 0;             ///< Last frame whose audio was written.
  qint64 _written = -1;       ///< Sample frames in the file, -1 before the
                              ///< first sound.
};

#endif // WAVTRACK_H
