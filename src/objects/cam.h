#ifndef CAM_H
#define CAM_H

/**
 * @file cam.h
 * @brief The scene camera, scriptable from Lua and exportable to POV-Ray.
 */

#include <lua.hpp>
#include <luabind/luabind.hpp>

#include <QObject>

#include <QGLViewer/camera.h>
// #include <QGLViewer/manipulatedCameraFrame.h>

#include <btBulletDynamicsCommon.h>

using namespace qglviewer;

/**
 * @brief The viewer's camera.
 *
 * Extends QGLViewer's Camera in three directions: its position, up vector and
 * look-at point are also available as Bullet vectors, so a script can drive it
 * with the same types it uses for everything else; it carries the focal blur
 * settings and the SDL overrides that the POV-Ray export needs but OpenGL has
 * no use for; and it adds an alternative orthographic frustum whose size the
 * user can change directly, selected with toggleMode().
 */
class Cam : public Camera {
  Q_OBJECT;

public:
  /**
   * @brief Constructs the camera with focal blur off.
   * @param parent Parent object, passed through to QObject.
   */
  Cam(QObject *parent = 0);

  /**
   * @brief Destroys the camera.
   */
  ~Cam();

  /**
   * @brief Registers the Cam class with a Lua state.
   *
   * Exposes the position, up vector and look-at point, the focal blur settings
   * and the SDL overrides as the @c Cam class.
   *
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns the object's type name.
   * @return The literal @c "Cam".
   */
  virtual QString toString() const;

  /**
   * @brief Sets the camera's up vector, turning the camera to match.
   * @param v The new up vector.
   */
  void setUpVector(const btVector3 &v);

  /**
   * @brief Sets the camera's up vector.
   * @param v      The new up vector.
   * @param noMove True to keep the camera where it is and only re-orient it,
   *               rather than letting QGLViewer move it to preserve the
   *               pivot point.
   */
  void setUpVector(const btVector3 &v, bool noMove);

  /**
   * @brief Returns the camera's up vector.
   * @return The up vector.
   */
  btVector3 getUpVector() const;

  /**
   * @brief Moves the camera.
   * @param v The new position.
   */
  void setPosition(const btVector3 &v);

  /**
   * @brief Returns where the camera is.
   * @return Its position.
   */
  btVector3 getPosition() const;

  /**
   * @brief Points the camera at a world position.
   *
   * A non-finite position is ignored, so a script computing a look-at point
   * from a diverging simulation cannot destroy the view.
   *
   * @param v The point to look at.
   */
  void setLookAt(const btVector3 &v);

  /**
   * @brief Returns the last point the camera was pointed at.
   * @return The stored look-at point, which is not updated when the camera is
   *         moved by other means.
   */
  btVector3 getLookAt() const;

  /**
   * @brief Sets the focal blur quality for POV-Ray renders.
   *
   * Affects the exported scene only; the interactive view never blurs.
   *
   * @param v 0 for off, 1 for low quality, up to about 10 for high.
   */
  void setUseFocalBlur(const int v);

  /**
   * @brief Returns the focal blur quality.
   * @return The quality, 0 when focal blur is off.
   */
  int getUseFocalBlur() const;

  /**
   * @brief Sets the point that stays sharp when focal blur is on.
   * @param v The focal point.
   */
  void setFocalPoint(const btVector3 &v);

  /**
   * @brief Returns the point that stays sharp when focal blur is on.
   * @return The focal point.
   */
  btVector3 getFocalPoint() const;

  /**
   * @brief Sets the aperture, that is how strong the focal blur is.
   * @param aperture The aperture; larger blurs more.
   */
  void setFocalAperture(double aperture);

  /**
   * @brief Returns the focal blur aperture.
   * @return The aperture.
   */
  double getFocalAperture() const;

  /**
   * @brief Replaces the exported POV-Ray camera block entirely.
   *
   * When set, the export writes this instead of building a camera from the
   * view, so a script can specify any camera POV-Ray supports.
   *
   * @param pre_sdl The SDL to emit.
   */
  void setPreSDL(QString pre_sdl);

  /**
   * @brief Returns the replacement camera SDL.
   * @return The text, or a null string when the camera is exported normally.
   */
  QString getPreSDL() const;

  /**
   * @brief Sets SDL emitted after the camera block.
   * @param post_sdl The SDL to emit.
   */
  void setPostSDL(QString post_sdl);

  /**
   * @brief Returns the SDL emitted after the camera block.
   * @return The text, or a null string when there is none.
   */
  QString getPostSDL() const;

#if QGLVIEWER_VERSION >= 0x020600
  /**
   * @brief Returns the near clipping plane distance.
   * @return QGLViewer's own value.
   */
  virtual qreal zNear() const;

  /**
   * @brief Returns the far clipping plane distance.
   * @return QGLViewer's own value.
   */
  virtual qreal zFar() const;
#else
  /**
   * @brief Returns the near clipping plane distance.
   * @return QGLViewer's own value.
   */
  virtual float zNear() const;

  /**
   * @brief Returns the far clipping plane distance.
   * @return QGLViewer's own value.
   */
  virtual float zFar() const;
#endif

  /**
   * @brief Switches between the fixed and the scene-fitted ortho frustum.
   */
  void toggleMode() { standard = !standard; }

  /**
   * @brief Reports which orthographic frustum is in use.
   * @return True when the fixed frustum sized by changeOrthoFrustumSize() is
   *         used, false when QGLViewer fits it to the scene.
   */
  bool isStandard() { return standard; }

  /**
   * @brief Zooms the fixed orthographic frustum in or out.
   *
   * Has no visible effect unless isStandard() is true.
   *
   * @param delta Positive to enlarge the frustum, negative to shrink it. Only
   *              the sign is used; each call changes the size by a fixed,
   *              very small factor.
   */
  void changeOrthoFrustumSize(int delta);

  /**
   * @brief Returns the half extents of the orthographic frustum.
   *
   * In the fixed mode the height is the size set by changeOrthoFrustumSize()
   * and the width follows the aspect ratio; otherwise QGLViewer's own
   * scene-fitted values are used.
   *
   * @param[out] halfWidth  Receives half the frustum width.
   * @param[out] halfHeight Receives half the frustum height.
   */
  virtual void getOrthoWidthHeight(GLdouble &halfWidth,
                                   GLdouble &halfHeight) const;

protected:
  btVector3 _lookAt; ///< The last point passed to setLookAt().

  int _useFocalBlur;      ///< Focal blur quality; 0 is off.
  btVector3 _focalPoint;  ///< The point that stays sharp.
  double _focalAperture;  ///< How strong the blur is.

  QString mPreSDL;  ///< Replacement POV-Ray camera block, or null.
  QString mPostSDL; ///< SDL emitted after the camera block, or null.

private:
  bool standard;    ///< True while the fixed ortho frustum is in use.
  float orthoSize;  ///< Half height of the fixed ortho frustum.
};

#endif // CAM_H
