#include "synth.h"

#include <SDL2/SDL_mixer.h>

#include <algorithm>
#include <cmath>
#include <vector>

namespace {

const int HARMONICS = 8;
const int TABLE_BITS = 12;
const int TABLE_SIZE = 1 << TABLE_BITS;
const double TWO_PI = 6.283185307179586;

// one cycle of sine, plus a guard point for interpolation
const float *sineTable() {
  static float table[TABLE_SIZE + 1];
  static bool init = false;
  if (!init) {
    for (int i = 0; i <= TABLE_SIZE; ++i)
      table[i] = (float)std::sin(TWO_PI * i / TABLE_SIZE);
    init = true;
  }
  return table;
}

// sin(2 pi x) for x in [0, 1)
inline float sine(const float *t, double x) {
  double p = x * TABLE_SIZE;
  int i = (int)p;
  float f = (float)(p - i);
  i &= TABLE_SIZE - 1;
  return t[i] + f * (t[i + 1] - t[i]);
}

inline float clampf(float x, float lo, float hi) {
  return x < lo ? lo : (x > hi ? hi : x);
}

} // namespace

ToneSynth::ToneSynth() : _gate(false), _attached(false), _rate(0), _channels(0) {
  sineTable();
  for (int i = 0; i < MAX_VOICES; ++i)
    _target[i] = {0.f, 0.f, 0.f, 0.5f, 0.15f};
  initBank(_live);
  initBank(_export);
}

ToneSynth::~ToneSynth() { detach(); }

void ToneSynth::initBank(Bank &b) {
  for (int i = 0; i < MAX_VOICES; ++i) {
    Voice &v = b.v[i];
    v.phase = 0;
    v.freq = v.amp = v.pan = 0;
    v.bright = 0.5f;
    v.noise = 0.15f;
    v.lp1 = v.lp2 = 0;
    v.rng = 0x9e3779b9u * (uint32_t)(i + 1);
  }
  b.gate = 0;
  b.fresh = true;
}

void ToneSynth::setTone(int voice, double freq, double amp, double pan) {
  if (voice < 0 || voice >= MAX_VOICES)
    return;
  std::lock_guard<std::mutex> lock(_mutex);
  Target &t = _target[voice];
  t.freq = clampf((float)freq, 0.f, 20000.f);
  t.amp = clampf((float)amp, 0.f, 1.f);
  t.pan = clampf((float)pan, -1.f, 1.f);
}

void ToneSynth::setTimbre(int voice, double brightness, double noise) {
  if (voice < 0 || voice >= MAX_VOICES)
    return;
  std::lock_guard<std::mutex> lock(_mutex);
  _target[voice].bright = clampf((float)brightness, 0.f, 1.f);
  _target[voice].noise = clampf((float)noise, 0.f, 1.f);
}

void ToneSynth::reset() {
  std::lock_guard<std::mutex> lock(_mutex);
  for (int i = 0; i < MAX_VOICES; ++i)
    _target[i] = {_target[i].freq, 0.f, _target[i].pan, 0.5f, 0.15f};
}

bool ToneSynth::audible() const {
  std::lock_guard<std::mutex> lock(_mutex);
  for (int i = 0; i < MAX_VOICES; ++i)
    if (_target[i].amp > 0 && _target[i].freq > 0)
      return true;
  return false;
}

void ToneSynth::attach() {
  if (_attached)
    return;
  Uint16 format;
  if (!Mix_QuerySpec(&_rate, &format, &_channels))
    return;
  if (format != AUDIO_S16SYS || _channels < 1)
    return; // (the default format; anything else stays silent)
  _attached = true;
  Mix_SetPostMix(&ToneSynth::postMix, this);
}

void ToneSynth::detach() {
  if (!_attached)
    return;
  Mix_SetPostMix(nullptr, nullptr);
  _attached = false;
}

void ToneSynth::restartExport() { initBank(_export); }

void ToneSynth::render(Bank &b, float *L, float *R, int n, int rate,
                       bool gated) {
  Target tgt[MAX_VOICES];
  {
    std::lock_guard<std::mutex> lock(_mutex);
    std::copy(_target, _target + MAX_VOICES, tgt);
  }
  const float *table = sineTable();
  const float glide = 1.f - (float)std::exp(-1.0 / (0.03 * rate));
  const float gateGlide = 1.f - (float)std::exp(-1.0 / (0.05 * rate));
  const float gateTarget = (!gated || _gate.load()) ? 1.f : 0.f;
  const float nyquist = 0.45f * rate;

  // the gate, sample by sample (shared by all voices)
  std::vector<float> gate(n);
  for (int s = 0; s < n; ++s) {
    b.gate += gateGlide * (gateTarget - b.gate);
    gate[s] = b.gate;
  }

  for (int i = 0; i < MAX_VOICES; ++i) {
    Voice &v = b.v[i];
    const Target &t = tgt[i];
    if (b.fresh) {
      v.freq = t.freq;
      v.pan = t.pan;
      v.bright = t.bright;
      v.noise = t.noise;
    }
    if (v.amp < 1e-5f && t.amp <= 0) {
      v.amp = 0;
      continue; // silent and staying so
    }
    if (v.amp < 1e-5f) {
      v.freq = t.freq; // (a voice coming in starts at its pitch)
      v.pan = t.pan;
    }

    // timbre, per block: the overtone weights and the noise band
    v.bright += 0.2f * (t.bright - v.bright);
    v.noise += 0.2f * (t.noise - v.noise);
    float w[HARMONICS], sum = 0;
    const float rolloff = 3.f - 2.f * v.bright; // 3 (near sine) .. 1 (buzz)
    for (int k = 0; k < HARMONICS; ++k) {
      w[k] = (float)std::pow(k + 1.0, -rolloff);
      sum += w[k];
    }
    for (int k = 0; k < HARMONICS; ++k)
      w[k] /= sum;
    const float fc = clampf(4.f * std::max(v.freq, t.freq), 200.f, 4000.f);
    const float lpA = 1.f - (float)std::exp(-TWO_PI * fc / rate);
    const float noiseGain = 2.5f * v.noise; // (the filtered band is quiet)

    for (int s = 0; s < n; ++s) {
      v.freq += glide * (t.freq - v.freq);
      v.amp += glide * (t.amp - v.amp);
      v.pan += glide * (t.pan - v.pan);

      v.phase += v.freq / rate;
      v.phase -= std::floor(v.phase);

      float tone = 0;
      for (int k = 0; k < HARMONICS; ++k) {
        if ((k + 1) * v.freq > nyquist)
          break;
        double x = (k + 1) * v.phase;
        tone += w[k] * sine(table, x - std::floor(x));
      }

      // noise band, chopped once per cycle of the fundamental
      v.rng ^= v.rng << 13;
      v.rng ^= v.rng >> 17;
      v.rng ^= v.rng << 5;
      float white = (float)(int32_t)v.rng * (1.f / 2147483648.f);
      v.lp1 += lpA * (white - v.lp1);
      v.lp2 += lpA * (v.lp1 - v.lp2);
      float chop = 0.55f + 0.45f * sine(table, v.phase);
      float y = v.amp * gate[s] * (tone + noiseGain * v.lp2 * chop);

      // equal-power pan
      float a = (v.pan + 1.f) * 0.25f; // 0 .. 0.5 of a quarter turn
      float gl = sine(table, a * 0.5 + 0.25), gr = sine(table, a * 0.5);
      L[s] += y * gl;
      R[s] += y * gr;
    }
  }
  b.fresh = false;
}

void ToneSynth::postMix(void *udata, uint8_t *stream, int len) {
  ToneSynth *self = (ToneSynth *)udata;
  const int ch = self->_channels;
  const int n = len / (2 * ch);
  if (n <= 0)
    return;
  static std::vector<float> L, R; // (the audio thread only)
  L.assign(n, 0.f);
  R.assign(n, 0.f);
  self->render(self->_live, L.data(), R.data(), n, self->_rate, true);

  int16_t *out = (int16_t *)stream;
  for (int s = 0; s < n; ++s) {
    float l = std::tanh(L[s]), r = std::tanh(R[s]); // (soft limit)
    for (int c = 0; c < ch; ++c) {
      float x = (ch == 1) ? 0.5f * (l + r) : (c % 2 == 0 ? l : r);
      int v = out[s * ch + c] + (int)(x * 32767.f);
      out[s * ch + c] = (int16_t)std::max(-32768, std::min(32767, v));
    }
  }
}

void ToneSynth::renderInto(int *mix, int frames, int channels, int rate) {
  if (frames <= 0)
    return;
  std::vector<float> L(frames, 0.f), R(frames, 0.f);
  // (exported frames are all simulated ones: no pause to hush)
  render(_export, L.data(), R.data(), frames, rate, false);
  for (int s = 0; s < frames; ++s) {
    float l = std::tanh(L[s]), r = std::tanh(R[s]);
    for (int c = 0; c < channels; ++c) {
      float x = (channels == 1) ? 0.5f * (l + r) : (c % 2 == 0 ? l : r);
      mix[s * channels + c] += (int)(x * 32767.f);
    }
  }
}
