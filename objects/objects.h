#ifndef OBJECTS_H
#define OBJECTS_H

#include "object.h"

#include <btBulletDynamicsCommon.h>

class Objects : public Object {

 public:
  Objects();

  QList<Object *>getObjects() const;
  
  static void luaBind(lua_State *s);
  QString toString() const;

  virtual void renderInLocalFrame(QTextStream *s) const;

 protected:
  QList<Object *> _objects;
};


#endif // CUBE_H
