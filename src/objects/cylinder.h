#ifndef CYLINDER_H
#define CYLINDER_H

#include "object.h"

#include <btBulletDynamicsCommon.h>

class Cylinder : public Object {
public:
  Cylinder(const btVector3 &dim, btScalar mass = 1.0);
  Cylinder(btScalar radius = 1.0, btScalar depth = 1.0, btScalar mass = 1.0);

  btScalar lengths[3];

  static void luaBind(lua_State *s);
  QString toString() const;
  virtual void toPOV(QTextStream *s) const;

protected:
  void init(btScalar radius, btScalar depth, btScalar mass);
  virtual void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb);
};

#endif // CYLINDER_H
