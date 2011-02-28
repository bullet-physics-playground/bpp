#ifndef CYLINDER_H
#define CYLINDER_H

#include "object.h"

#include <btBulletDynamicsCommon.h>

class Cylinder : public Object
{
public:
	Cylinder(btScalar width, btScalar height, btScalar depth, btScalar mass);

	btScalar         lengths[3];
protected:
	virtual void renderInLocalFrame(QTextStream *s) const;
};


#endif // CYLINDER_H
