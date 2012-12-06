#ifndef SPHERE_H
#define SPHERE_H

#include "object.h"

#include <btBulletDynamicsCommon.h>

class Sphere : public Object
{
public:
  Sphere(btScalar radius = 0.5, btScalar mass = 1.0);

  void setRadius(btScalar radius);
  btScalar getRadius() const;
  
  static void luaBind(lua_State *s);
  QString toString() const;

protected:
  virtual void renderInLocalFrame(QTextStream *s) const;
  
  btScalar         radius;
};

#endif // SPHERE_H
