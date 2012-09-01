#ifndef CAM_H
#define CAM_H

#include <lua.hpp>
#include <luabind/luabind.hpp>

#include <QObject>

#include <QGLViewer/camera.h>

#include <btBulletDynamicsCommon.h>

class Cam : public qglviewer::Camera {
 Q_OBJECT;

 public:
  Cam();
  virtual ~Cam() {};

  static void luaBind(lua_State *s);

  virtual QString toString() const;

  void setPosition(btScalar x, btScalar y, btScalar z);
  void setPosition(const btVector3& v);

  btVector3 getPosition() const;

};

#endif
