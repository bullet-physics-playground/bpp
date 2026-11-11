#ifndef QUICKRENDER_H
#define QUICKRENDER_H

#include <QSize>
#include <QString>
#include <QStringList>

#include <functional>

class QObject;
class QSettings;

/**
 * @brief A quick render (the toolbar's render button, v:quickRender): the
 * exported frame rendered by POV-Ray into a PNG on the desktop.
 *
 * plan() works out how POV-Ray is called, from the settings (the program,
 * the preview options, the render size, where exports go); start() runs it
 * as a process of its own and reports a failure. (With POV-Ray built in,
 * USE_VFE, the Viewer renders the plan itself instead.)
 */
class QuickRender {
public:
  /// How POV-Ray is called for one quick render.
  struct Plan {
    QString povray;     ///< The program (or "POV-Ray not found!").
    QStringList args;   ///< Its arguments, the options split on spaces.
    QString opts;       ///< The preview options, whole (as VFE wants them).
    int width = 0;      ///< Render size.
    int height = 0;
    QString sceneName;  ///< The script's name without its suffix.
    QString sceneDir;   ///< The scene's export folder, where POV-Ray runs.
    QString png;        ///< The image to write, on the desktop.
  };

  /**
   * @brief Works out a quick render of the current, just exported, frame.
   * @param settings   bpp's settings (gui/renderResolution, povray/...).
   * @param viewSize   The 3D view's size: the render size by default.
   * @param scriptName The script's file name (empty: "no_name").
   * @param frameNum   The frame: POV-Ray's clock and part of the PNG's name.
   * @param povargs    More options for POV-Ray, passed as one argument.
   */
  static Plan plan(QSettings *settings, const QSize &viewSize, const QString &scriptName,
                   int frameNum, const QString &povargs);

  /**
   * @brief Runs POV-Ray as planned, not waiting for it.
   * @param plan    The call.
   * @param context Owns the failure reports (they stop when it goes).
   * @param report  Shows a failure: POV-Ray not starting, or its output
   *                when it exits with an error.
   */
  static void start(const Plan &plan, QObject *context,
                    const std::function<void(const QString &)> &report);
};

#endif // QUICKRENDER_H
