#ifndef POVEXPORT_H
#define POVEXPORT_H

#include "orderedset.h"
#include <QList>
#include <QString>

#include <LinearMath/btVector3.h>

class Cam;
class Light;
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
 * and copies of the settings includes and texture images. Each function
 * writes one of them from what it is given; Viewer decides where and when.
 */
namespace PovExport {

// (Each write... below returns false when its file couldn't be written in
// full: not opened, or the disk full.)

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

/**
 * @brief Copies the objects' texture images into the scene directory.
 * @param objects  The objects whose textures the export uses.
 * @param sceneDir The exported scene's directory.
 */
void copyTextures(const ObjectSet &objects, const QString &sceneDir);

/// Writes the animation's @c .ini: frames @p firstFrame to @p lastFrame of
/// @p sceneName, with named sections for common render sizes.
bool writeIni(const QString &path, const QString &byline,
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
  /// The script added lights of its own: settings.inc makes none (BPP_Lights).
  bool lights = false;
  /// One of them is a LightSys light: the LightSys includes are pulled in.
  bool lightsys = false;
  /// Render settings the POV-Ray menu changed (use_rad = 2, ...), declared
  /// before the include, whose own values are the defaults.
  QMap<QString, int> declares;
};

/**
 * @brief Where bpp's shipped include @p settingsInc is: next to the
 * executable, above it, in @p startupDir/includes, or installed.
 * @return Its path, or an empty string when there is none.
 */
QString findSettingsInc(const QString &settingsInc, const QString &startupDir);

/// Writes the main @c .pov file, which includes the frame of the clock.
bool writeMain(const QString &path, const QString &byline, const Scene &scene);

/**
 * @brief Writes one frame's @c .inc: the scene's pre-SDL, the camera, the
 * script's lights, every object exported to POV-Ray, and the post-SDL.
 * @param cam      The viewer's camera (nullptr: no camera block).
 * @param view     The same camera, as QGLViewer's.
 * @param lights   The lights the script added (PointLight ...).
 * @param objects  The scene's objects.
 * @param sceneDir The scene directory (meshes and terrains write their data
 *                 files there).
 */
bool writeFrame(const QString &path, const QString &byline,
                const QString &preSDL, Cam *cam, qglviewer::Camera *view,
                const QList<Light *> &lights,
                const ObjectSet &objects, const QString &postSDL,
                const QString &sceneDir);

/// Writes the scene directory's @c GNUmakefile, unless it has one already
/// (it may have been edited).
bool writeMakefile(const QString &sceneDir);

} // namespace PovExport

#endif // POVEXPORT_H
