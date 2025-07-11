#ifndef CAM_H
#define CAM_H

#include <lua.hpp>
#include <luabind/luabind.hpp>

#include <QObject>

#include <QGLViewer/camera.h>
// #include <QGLViewer/manipulatedCameraFrame.h>

#include <btBulletDynamicsCommon.h>

using namespace qglviewer;

class Cam : public Camera {
  Q_OBJECT;

public:
  Cam(QObject *parent = 0);
  ~Cam();

  static void luaBind(lua_State *s);

  virtual QString toString() const;

  void setUpVector(const btVector3 &v, bool noMove);
  btVector3 getUpVector() const;

  void setPosition(const btVector3 &v);

  btVector3 getPosition() const;

  void setLookAt(const btVector3 &v);
  btVector3 getLookAt() const;

  void setUseFocalBlur(const int v);
  int getUseFocalBlur() const;

  void setFocalPoint(const btVector3 &v);
  btVector3 getFocalPoint() const;

  void setFocalAperture(double aperture);
  double getFocalAperture() const;

  void setPreSDL(QString pre_sdl);
  QString getPreSDL() const;

  void setPostSDL(QString post_sdl);
  QString getPostSDL() const;

#if QGLVIEWER_VERSION >= 0x020600
  virtual qreal zNear() const;
  virtual qreal zFar() const;
#else
  virtual float zNear() const;
  virtual float zFar() const;
#endif

  void toggleMode() { standard = !standard; }
  bool isStandard() { return standard; }

  void changeOrthoFrustumSize(int delta);
  virtual void getOrthoWidthHeight(GLdouble &halfWidth,
                                   GLdouble &halfHeight) const;

protected:
  btVector3 _lookAt;

  int _useFocalBlur;
  btVector3 _focalPoint;
  double _focalAperture;

  QString mPreSDL;
  QString mPostSDL;

private:
  bool standard;
  float orthoSize;
};

#endif // CAM_H
