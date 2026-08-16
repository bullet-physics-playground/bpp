#ifndef BPPVFEDISPLAY_H
#define BPPVFEDISPLAY_H

#if USE_VFE

#include <atomic>

#include <QImage>
#include <QMutex>

#include "vfe.h"

class BppVfeDisplay : public vfe::vfeDisplay {
public:
  BppVfeDisplay(unsigned int width, unsigned int height, vfe::vfeSession *session, bool visible = false);

  virtual void Initialise() override;
  virtual void DrawPixel(unsigned int x, unsigned int y, const RGBA8 &colour) override;
  virtual void DrawRectangleFrame(unsigned int x1, unsigned int y1, unsigned int x2, unsigned int y2, const RGBA8 &colour) override;
  virtual void DrawFilledRectangle(unsigned int x1, unsigned int y1, unsigned int x2, unsigned int y2, const RGBA8 &colour) override;
  virtual void DrawPixelBlock(unsigned int x1, unsigned int y1, unsigned int x2, unsigned int y2, const RGBA8 *colour) override;
  virtual void Clear() override;

  // Deep copy of the current pixel buffer, safe to call from the Qt GUI
  // thread while the vfe worker thread keeps drawing into this display.
  QImage snapshot();
  bool dirty() const { return _dirty; }

private:
  void setPixelLocked(unsigned int x, unsigned int y, const RGBA8 &colour);

  QImage _image;
  QMutex _mutex;
  std::atomic<bool> _dirty;
};

#endif // USE_VFE

#endif // BPPVFEDISPLAY_H
