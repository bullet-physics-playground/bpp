#ifndef DICE_H
#define DICE_H

#include "object.h"

#include <btBulletDynamicsCommon.h>

class Dice : public Object {
 public:
  Dice(btScalar width = 1.0, btScalar mass = 1.0);

  btScalar         lengths[3];

  static void luaBind(lua_State *s);
  QString toString() const;
 protected:
  virtual void renderInLocalFrame(QTextStream *s) const;
};


#endif // DICE_H
