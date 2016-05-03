#ifndef CYLINDER_H
#define CYLINDER_H

#include "object.h"

#include <btBulletDynamicsCommon.h>

class Cylinder : public Object {
public:
    Cylinder(const btVector3& dim, btScalar mass = 1.0);
    Cylinder(btScalar width = 0.5, btScalar height = 0.5, btScalar depth = 1.0,
             btScalar mass = 1.0);

    btScalar         lengths[3];

    static void luaBind(lua_State *s);
    QString toString() const;

protected:
    void init(btScalar width, btScalar height, btScalar depth, btScalar mass);
    virtual void renderInLocalFrame(QTextStream *s);
};

#endif // CYLINDER_H
