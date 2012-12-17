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
  Cam();
  virtual ~Cam() {};

  static void luaBind(lua_State *s);

  virtual QString toString() const;

  void setPosition(const btVector3& v);

  btVector3 getPosition() const;

  void setLookAt(const btVector3& v);
  btVector3 getLookAt() const;

 protected:
  btVector3 _lookAt;

};

#endif
