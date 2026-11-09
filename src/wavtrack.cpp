#include "wavtrack.h"

#include <QByteArray>
#include <QDataStream>
#include <QDebug>
#include <QFile>

#include <algorithm>

#include "synth.h"

namespace {

// Frame rate the exported GNUmakefile encodes the frames at (ffmpeg's default
// for an image sequence), which the exported audio track keeps in step with.
const int POV_EXPORT_FPS = 25;

// Header of a 16-bit PCM WAV holding dataBytes of samples.
QByteArray wavHeader(int freq, int channels, quint32 dataBytes) {
  QByteArray h;
  QDataStream s(&h, QIODevice::WriteOnly);
  s.setByteOrder(QDataStream::LittleEndian);
  s.writeRawData("RIFF", 4);
  s << quint32(36 + dataBytes);
  s.writeRawData("WAVEfmt ", 8);
  s << quint32(16) << quint16(1) << quint16(channels) << quint32(freq)
    << quint32(freq * channels * 2) << quint16(channels * 2) << quint16(16);
  s.writeRawData("data", 4);
  s << dataBytes;
  return h;
}

} // namespace

void WavTrack::record(Mix_Chunk *chunk, double volume, int frameNum) {
  // Once this frame is exported, the next one is the first to show what the
  // sound is about.
  int frame = (_frame == frameNum) ? frameNum + 1 : frameNum;
  _events.push_back({frame, chunk, volume});
}

void WavTrack::write(const QString &file, int firstFrame, int frameNum, ToneSynth &synth) {
  int freq, channels;
  Uint16 format;
  // The chunks hold their samples in the mixer's format; only 16-bit
  // little-endian PCM goes into the WAV as it is.
  if (!Mix_QuerySpec(&freq, &format, &channels) || format != AUDIO_S16LSB) {
    _events.clear();
    return;
  }

  // A new export: an older track no longer lines up with the frames.
  if (file != _file || firstFrame != _firstFrame ||
      frameNum < _frame) {
    QFile::remove(file);
    _file = file;
    _firstFrame = firstFrame;
    _written = -1;
    _mix.clear();
    synth.restartExport();
  }
  _frame = frameNum;

  const bool tones = synth.audible();
  if (_written < 0 && _events.empty() && !tones)
    return; // nothing played yet, so no track

  QFile f(file);
  if (!f.open(QIODevice::ReadWrite)) {
    qWarning() << "WavTrack: cannot write" << file;
    _events.clear();
    return;
  }
  if (_written < 0)
    _written = 0;

  // first sample frame of exported frame n
  auto start = [&](int n) {
    return qint64(n - firstFrame) * freq / POV_EXPORT_FPS;
  };

  // Appends the track up to sample frame end: the mix, then silence.
  auto append = [&](qint64 end) {
    qint64 n = (end - _written) * channels;
    if (n <= 0)
      return;
    std::vector<qint16> out(n, 0);
    qint64 m = std::min<qint64>(n, _mix.size());
    for (qint64 i = 0; i < m; ++i)
      out[i] = qBound(-32768, _mix[i], 32767);
    _mix.erase(_mix.begin(), _mix.begin() + m);
    f.seek(44 + _written * channels * 2);
    f.write((const char *)out.data(), n * 2);
    _written = end;
  };

  append(start(frameNum)); // silence up to the first sound

  for (const Event &e : _events) {
    const qint16 *src = (const qint16 *)e.chunk->abuf;
    qint64 len = e.chunk->alen / 2;
    qint64 at = (start(e.frame) - _written) * channels;
    if (at + len <= 0)
      continue;
    if ((qint64)_mix.size() < at + len)
      _mix.resize(at + len, 0);
    for (qint64 i = std::max<qint64>(0, -at); i < len; ++i)
      _mix[at + i] += int(src[i] * e.volume);
  }
  _events.clear();

  // the synthesised voices, through this frame
  if (tones || _written > 0) {
    qint64 n = start(frameNum + 1) - _written;
    if (n > 0) {
      if ((qint64)_mix.size() < n * channels)
        _mix.resize(n * channels, 0);
      synth.renderInto(_mix.data(), (int)n, channels, freq);
    }
  }

  append(start(frameNum + 1)); // this frame's share

  f.seek(0);
  f.write(wavHeader(freq, channels, quint32(_written * channels * 2)));
}
