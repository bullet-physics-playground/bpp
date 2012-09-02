#ifndef CUBE_AXES_H
#define CUBE_AXES_H

#include "object.h"

#include <btBulletDynamicsCommon.h>

class CubeAxes : public Object
{
public:
	CubeAxes(btScalar width, btScalar height, btScalar depth, btScalar mass);

	btScalar         lengths[3];
protected:
	virtual void renderInLocalFrame(QTextStream *s) const;
};


#endif // CUBE_AXES_H
