#include "bppvfedisplay.h"

#if USE_VFE

#include <QMutexLocker>

BppVfeDisplay::BppVfeDisplay(unsigned int width, unsigned int height, vfe::vfeSession *session, bool visible)
    : vfeDisplay(width, height, session, visible), _dirty(false) {}

void BppVfeDisplay::Initialise() {
  QMutexLocker lock(&_mutex);
  _image = QImage(GetWidth(), GetHeight(), QImage::Format_RGBA8888);
  _image.fill(Qt::black);
  _dirty = true;
}

void BppVfeDisplay::setPixelLocked(unsigned int x, unsigned int y, const RGBA8 &colour) {
  auto *row = reinterpret_cast<RGBA8 *>(_image.scanLine(y));
  row[x] = colour;
}

void BppVfeDisplay::DrawPixel(unsigned int x, unsigned int y, const RGBA8 &colour) {
  QMutexLocker lock(&_mutex);
  setPixelLocked(x, y, colour);
  _dirty = true;
}

void BppVfeDisplay::DrawPixelBlock(unsigned int x1, unsigned int y1, unsigned int x2, unsigned int y2, const RGBA8 *colour) {
  QMutexLocker lock(&_mutex);
  for (unsigned int y = y1; y <= y2; ++y)
    for (unsigned int x = x1; x <= x2; ++x)
      setPixelLocked(x, y, *colour++);
  _dirty = true;
}

void BppVfeDisplay::DrawFilledRectangle(unsigned int x1, unsigned int y1, unsigned int x2, unsigned int y2, const RGBA8 &colour) {
  QMutexLocker lock(&_mutex);
  for (unsigned int y = y1; y <= y2; ++y)
    for (unsigned int x = x1; x <= x2; ++x)
      setPixelLocked(x, y, colour);
  _dirty = true;
}

void BppVfeDisplay::DrawRectangleFrame(unsigned int x1, unsigned int y1, unsigned int x2, unsigned int y2, const RGBA8 &colour) {
  QMutexLocker lock(&_mutex);
  for (unsigned int x = x1; x <= x2; ++x) {
    setPixelLocked(x, y1, colour);
    setPixelLocked(x, y2, colour);
  }
  for (unsigned int y = y1; y <= y2; ++y) {
    setPixelLocked(x1, y, colour);
    setPixelLocked(x2, y, colour);
  }
  _dirty = true;
}

void BppVfeDisplay::Clear() {
  QMutexLocker lock(&_mutex);
  _image.fill(Qt::black);
  _dirty = true;
}

QImage BppVfeDisplay::snapshot() {
  QMutexLocker lock(&_mutex);
  _dirty = false;
  return _image.copy();
}

#endif // USE_VFE
