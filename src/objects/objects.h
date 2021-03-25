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
    virtual void toPOV(QTextStream *s) const;

    virtual void renderInLocalFrame(btVector3& minaabb, btVector3& maxaabb);

protected:
    QList<Object *> _objects;
};

#endif // OBJECTS_H
