#ifndef BPPVFESESSION_H
#define BPPVFESESSION_H

/**
 * @file bppvfesession.h
 * @brief bpp's POV-Ray Virtual Front End session.
 */

#if USE_VFE

#include "vfeplatform.h"

#ifdef _WIN32
/// Platform-specific VFE session base class: the Windows one.
using BppVfeSessionBase = vfePlatform::vfeWinSession;
#else
/// Platform-specific VFE session base class: the Unix one.
using BppVfeSessionBase = vfePlatform::vfeUnixSession;
#endif

/**
 * @brief A POV-Ray VFE session that reports critical errors through bpp.
 *
 * The Virtual Front End is POV-Ray's embedding API: a session owns the render
 * worker thread and is how bpp drives an in-process render for the quick
 * render preview. Everything but critical-error reporting comes from the
 * platform base class.
 */
class BppVfeSession : public BppVfeSessionBase {
public:
  /**
   * @brief Constructs the session.
   * @param id Session identifier, passed through to the platform base class.
   */
  BppVfeSession(int id = 0);

  /**
   * @brief Records a critical error where bpp can read it back.
   *
   * The base class would otherwise report this somewhere bpp never sees; this
   * folds the originating file and line into the message and appends it to the
   * session's own error and status queue, which Viewer::drainVfeMessages()
   * drains into the debug pane.
   *
   * @param message The error text.
   * @param file    Source file the error was raised from.
   * @param line    Line in that file.
   */
  virtual void NotifyCriticalError(const char *message, const char *file, int line) override;
};

#endif // USE_VFE

#endif // BPPVFESESSION_H
