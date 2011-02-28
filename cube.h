#ifndef CUBE_H
#define CUBE_H

#include "object.h"

#include <btBulletDynamicsCommon.h>

class Cube : public Object
{
public:
	Cube(btScalar width, btScalar height, btScalar depth, btScalar mass);

	btScalar         lengths[3];
protected:
	virtual void renderInLocalFrame(QTextStream *s) const;
};


#endif // CUBE_H
