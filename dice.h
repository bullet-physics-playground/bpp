#ifndef DICE_H
#define DICE_H

#include "object.h"

#include <btBulletDynamicsCommon.h>

class Dice : public Object
{
public:
  Dice(btScalar width, btScalar mass);

	btScalar         lengths[3];
protected:
	virtual void renderInLocalFrame(QTextStream *s) const;
};


#endif // DICE_H
