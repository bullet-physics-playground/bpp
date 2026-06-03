#ifndef CONE_H
#define CONE_H

#include "object.h"

#include <btBulletDynamicsCommon.h>

class Cone : public Object {
public:
  Cone(btScalar radius = 0.5, btScalar height = 1.0, btScalar mass = 1.0);
  ~Cone();

  void setRadius(btScalar radius);
  btScalar getRadius() const;
  void setHeight(btScalar height);
  btScalar getHeight() const;

  static void luaBind(lua_State *s);
  QString toString() const override;
  void toPOV(QTextStream *s) const override;

protected:
  void init(btScalar radius, btScalar height, btScalar mass);
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

  btScalar radius;
  btScalar height;
};

#endif // CONE_H
