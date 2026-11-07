#ifndef POVEXPORT_H
#define POVEXPORT_H

#include <QSet>
#include <QString>

#include <LinearMath/btVector3.h>

class Cam;
class Object;
namespace qglviewer {
class Camera;
}

/**
 * @brief The files of a POV-Ray export: what Viewer::savePOV() writes into
 * an exported scene's directory.
 *
 * A scene directory holds the animation's @c .ini, the main @c .pov (global
 * settings, the view's lights, the settings include), one @c .inc per frame
 * (camera and objects), a @c GNUmakefile that renders and encodes the frames,
 * and copies of the settings includes. Each function writes one of them from
 * what it is given; Viewer decides where and when.
 */
namespace PovExport {

/// "yyyy-MM-dd hh:mm:ss by USER", for the header comment of each file
/// (computed once per export, so all its files agree).
QString byline();

/**
 * @brief Copies the settings include and its sibling includes into the
 * scene directory, so the scene renders without POV-Ray's include path.
 * @param settingsInc The include's name (v.pov_settings); empty: none.
 * @param startupDir  The directory bpp was started in.
 * @param sceneDir    The exported scene's directory.
 */
void copySettingsIncludes(const QString &settingsInc, const QString &startupDir,
                          const QString &sceneDir);

/// Writes the animation's @c .ini: frames @p firstFrame to @p lastFrame of
/// @p sceneName, with named sections for common render sizes.
void writeIni(const QString &path, const QString &byline,
              const QString &sceneName, int firstFrame, int lastFrame);

/// What the main @c .pov file of an export holds.
struct Scene {
  bool radiosity = false;  ///< A radiosity block.
  bool photons = false;    ///< A photons block.
  bool fog = false;        ///< Fog.
  bool atmosphere = false; ///< Atmospheric media.
  btVector4 light0;        ///< The view's main light (GL_POSITION).
  btVector4 light1;        ///< The view's second light (GL_POSITION).
  btVector4 diffuse;       ///< The view's diffuse light colour.
  QString settingsInc;     ///< The include it pulls in (empty: none).
};

/// Writes the main @c .pov file, which includes the frame of the clock.
void writeMain(const QString &path, const QString &byline, const Scene &scene);

/**
 * @brief Writes one frame's @c .inc: the scene's pre-SDL, the camera, every
 * object exported to POV-Ray, and the post-SDL.
 * @param cam      The viewer's camera (nullptr: no camera block).
 * @param view     The same camera, as QGLViewer's.
 * @param objects  The scene's objects.
 * @param sceneDir The scene directory (meshes and terrains write their data
 *                 files there).
 */
void writeFrame(const QString &path, const QString &byline,
                const QString &preSDL, Cam *cam, qglviewer::Camera *view,
                const QSet<Object *> &objects, const QString &postSDL,
                const QString &sceneDir);

/// Writes the scene directory's @c GNUmakefile, unless it has one already
/// (it may have been edited).
void writeMakefile(const QString &sceneDir);

} // namespace PovExport

#endif // POVEXPORT_H
