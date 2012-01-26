#ifndef RM_H
#define RM_H

#include "objects.h"
#include "cube.h"
#include "mesh3ds.h"

#include "robot.h"

class RM : public Objects {
 public:
  RM();

  static void luaBind(lua_State *s);
  QString toString() const;

  void animate();

  void pidControl(btHingeConstraint &joint, btScalar jAngle, btScalar dAngle, int jointNum);

  Mesh3DS *rm0;
  Mesh3DS *rm1;
  Mesh3DS *rm2;
  Mesh3DS *rm3;
  Cube    *rm4;
  Mesh3DS *rm5;

  btHingeConstraint* rmJoint0;
  btHingeConstraint* rmJoint1;
  btHingeConstraint* rmJoint2;
  btHingeConstraint* rmJoint3;
  btGeneric6DofConstraint* rmJoint4;

  Robot *robot;
  Cube *cube;

 protected:
  virtual void renderInLocalFrame(QTextStream *s) const;

 private:
};

#endif
