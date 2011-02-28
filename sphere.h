#ifndef SPHERE_H
#define SPHERE_H

#include "object.h"

#include <btBulletDynamicsCommon.h>

class Sphere : public Object
{
public:
  Sphere(btScalar radius, btScalar mass);
  
 protected:
  virtual void renderInLocalFrame(QTextStream *s) const;
  
  btScalar         radius;
};

#endif // SPHERE_H
