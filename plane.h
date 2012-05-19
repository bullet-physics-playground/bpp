#ifndef PLANE_H
#define PLANE_H

#include "object.h"

#include <btBulletDynamicsCommon.h>

class Plane : public Object
{
 public:
  Plane(const btVector3& dim, btScalar nConst, btScalar size);
  Plane(btScalar nx = 0.0, btScalar ny = 0.0, btScalar nz = 0.0,
		btScalar nConst = 0.0, btScalar size = 10.0);

  void setPigment(QString pigment);

  static void luaBind(lua_State *s);
  QString toString() const;
  
  virtual void renderInLocalFrame(QTextStream *s) const;
 protected:
  void init(btScalar nx, btScalar ny, btScalar nz,
			btScalar nConst, btScalar size);
  
  btScalar       size;

  QString mPigment;
};

#endif // PLANE_H
