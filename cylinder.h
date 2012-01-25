#ifndef CYLINDER_H
#define CYLINDER_H

#include "object.h"

#include <btBulletDynamicsCommon.h>

class Cylinder : public Object {
 public:
  Cylinder(btVector3 dim, btScalar mass = 1.0);
  Cylinder(btScalar width = 1.0, btScalar height = 1.0, btScalar depth = 1.0,
		   btScalar mass = 1.0);

  btScalar         lengths[3];

  static void luaBind(lua_State *s);
  QString toString() const;

 protected:
  void init(btScalar width, btScalar height, btScalar depth, btScalar mass);
  virtual void renderInLocalFrame(QTextStream *s) const;
};


#endif // CYLINDER_H
