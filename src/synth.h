#ifndef SYNTH_H
#define SYNTH_H

#include <atomic>
#include <cstdint>
#include <mutex>

/**
 * @brief A few continuously sounding synthesised voices, for engine-like
 * sounds that follow the simulation (rotors, motors, wind ...).
 *
 * Scripts set each voice's pitch, loudness and pan every frame (Viewer's
 * setTone()); the synth glides to the new values over ~30 ms, so updates at
 * frame rate don't click. A voice is a harmonic tone -- the fundamental and
 * its overtones, rolling off by brightness -- plus a band of noise chopped
 * at the fundamental, which together make a rotor's buzz-and-whoosh.
 *
 * The voices are mixed into SDL_mixer's output after its own channels
 * (Mix_SetPostMix), so loadSound()/playSound() effects play on top as
 * before. They fall silent while the simulation is stopped (setGate()) and
 * when a new script is loaded (reset()). With no audio device nothing is
 * attached and the voices only record their settings.
 *
 * The same voices can also be rendered into an exported audio track
 * (renderInto()), from their own state so the export stays in step with
 * the exported frames rather than with the sound card.
 */
class ToneSynth {
public:
  static const int MAX_VOICES = 24;

  ToneSynth();
  ~ToneSynth();

  /** Voice @p voice (0-based) to @p freq Hz at @p amp (0..1 of full scale),
   *  panned @p pan from -1 (left) to 1 (right). amp 0 silences it. */
  void setTone(int voice, double freq, double amp, double pan);

  /** Voice @p voice's tone colour: @p brightness 0 (a pure sine) .. 1
   *  (buzzy, overtones falling off as 1/k), @p noise 0..1 the level of the
   *  chopped noise band relative to the tone. */
  void setTimbre(int voice, double brightness, double noise);

  /** Fades every voice out and restores the default timbre. */
  void reset();

  /** Open (sound) or closed (fade to silence, e.g. while paused). */
  void setGate(bool open) { _gate.store(open); }

  /** True if any voice is set to sound. */
  bool audible() const;

  /** Starts mixing into SDL_mixer's output (call once Mix_OpenAudio
   *  succeeded). Only 16-bit output is supported; anything else is left
   *  silent. */
  void attach();

  /** Stops mixing (call before Mix_CloseAudio). */
  void detach();

  /** Adds @p frames sample frames of the voices to @p mix (interleaved,
   *  @p channels per frame, 16-bit scale) at @p rate Hz, from the export's
   *  own voice state. */
  void renderInto(int *mix, int frames, int channels, int rate);

  /** Forgets the export's voice state, so a new export starts silent. */
  void restartExport();

private:
  struct Target {
    float freq, amp, pan, bright, noise;
  };
  struct Voice {
    double phase;     // of the fundamental, 0..1
    float freq, amp, pan, bright, noise;
    float lp1, lp2;   // noise filter state
    uint32_t rng;
  };
  struct Bank {
    Voice v[MAX_VOICES];
    float gate;
    bool fresh;       // take the targets as they are (no glide from 0 Hz)
  };

  void initBank(Bank &b);
  // Renders n frames into stereo float buffers (added to them).
  void render(Bank &b, float *L, float *R, int n, int rate, bool gated);
  static void postMix(void *udata, uint8_t *stream, int len);

  mutable std::mutex _mutex; // guards _target
  Target _target[MAX_VOICES];
  std::atomic<bool> _gate;
  Bank _live, _export;
  bool _attached;
  int _rate, _channels;
};

#endif // SYNTH_H
