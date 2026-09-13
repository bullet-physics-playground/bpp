#ifndef BPPVFEDISPLAY_H
#define BPPVFEDISPLAY_H

/**
 * @file bppvfedisplay.h
 * @brief POV-Ray VFE display target backed by a QImage.
 */

#if USE_VFE

#include <atomic>

#include <QImage>
#include <QMutex>

#include "vfe.h"

/**
 * @brief Collects the pixels POV-Ray renders into a QImage bpp can display.
 *
 * The Virtual Front End hands rendered pixels to a display object as they are
 * produced. This one writes them into a QImage so the viewer can show the
 * render in progress as an OpenGL texture.
 *
 * @b Threading: POV-Ray draws from its own worker thread while the Qt GUI
 * thread reads. Every drawing method takes the mutex, and snapshot() hands
 * back a deep copy so the GUI never reads the buffer POV-Ray is still writing
 * to. The dirty flag is atomic so it can be polled without locking.
 */
class BppVfeDisplay : public vfe::vfeDisplay {
public:
  /**
   * @brief Constructs the display for a render of a given size.
   * @param width   Render width in pixels.
   * @param height  Render height in pixels.
   * @param session The session this display belongs to.
   * @param visible Whether POV-Ray should consider the display visible.
   */
  BppVfeDisplay(unsigned int width, unsigned int height, vfe::vfeSession *session, bool visible = false);

  /**
   * @brief Allocates the pixel buffer and clears it to black.
   */
  virtual void Initialise() override;

  /**
   * @brief Sets one pixel.
   *
   * POV-Ray's coordinates are not guaranteed to stay within the render size -
   * its own reference @c unix/disp_sdl.cpp bounds-checks for exactly this
   * reason - so out-of-range pixels are dropped rather than written past the
   * end of a row.
   *
   * @param x      Column.
   * @param y      Row.
   * @param colour The pixel value.
   */
  virtual void DrawPixel(unsigned int x, unsigned int y, const RGBA8 &colour) override;

  /**
   * @brief Draws the outline of a rectangle.
   * @param x1     Left column.
   * @param y1     Top row.
   * @param x2     Right column; clamped to the last column.
   * @param y2     Bottom row; clamped to the last row.
   * @param colour The pixel value.
   */
  virtual void DrawRectangleFrame(unsigned int x1, unsigned int y1, unsigned int x2, unsigned int y2, const RGBA8 &colour) override;

  /**
   * @brief Fills a rectangle with one colour.
   * @param x1     Left column.
   * @param y1     Top row.
   * @param x2     Right column; clamped to the last column.
   * @param y2     Bottom row; clamped to the last row.
   * @param colour The pixel value.
   */
  virtual void DrawFilledRectangle(unsigned int x1, unsigned int y1, unsigned int x2, unsigned int y2, const RGBA8 &colour) override;

  /**
   * @brief Copies a block of pixels into the buffer.
   * @param x1     Left column.
   * @param y1     Top row.
   * @param x2     Right column; clamped to the last column.
   * @param y2     Bottom row; clamped to the last row.
   * @param colour Pixel values for the block, row by row. The caller must
   *               supply enough for the unclamped rectangle, since clamping
   *               narrows what is written but not what is read.
   */
  virtual void DrawPixelBlock(unsigned int x1, unsigned int y1, unsigned int x2, unsigned int y2, const RGBA8 *colour) override;

  /**
   * @brief Clears the whole buffer to black.
   */
  virtual void Clear() override;

  /**
   * @brief Takes a copy of the current pixel buffer.
   *
   * Deep copy of the current pixel buffer, safe to call from the Qt GUI
   * thread while the vfe worker thread keeps drawing into this display.
   * Taking the copy also clears the dirty flag.
   *
   * @return An independent copy of the image.
   */
  QImage snapshot();

  /**
   * @brief Reports whether anything has been drawn since the last snapshot().
   * @return True if there are new pixels to collect.
   */
  bool dirty() const { return _dirty; }

private:
  /**
   * @brief Writes one pixel straight into the buffer.
   *
   * The caller must already hold the mutex and must have bounds-checked the
   * coordinates.
   *
   * @param x      Column.
   * @param y      Row.
   * @param colour The pixel value.
   */
  void setPixelLocked(unsigned int x, unsigned int y, const RGBA8 &colour);

  QImage _image;            ///< The pixel buffer POV-Ray renders into.
  QMutex _mutex;            ///< Guards #_image against the GUI thread.
  std::atomic<bool> _dirty; ///< Set by every draw, cleared by snapshot().
};

#endif // USE_VFE

#endif // BPPVFEDISPLAY_H
