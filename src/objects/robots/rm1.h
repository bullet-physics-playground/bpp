#ifndef RM1_H
#define RM1_H

#include "objects/object.h"
#include "objects/cube.h"
#include "objects/cubeaxes.h"

#include "robot.h"

class RM1 : public Object {
 public:
  RM1();

  void animate();

  void pidControl(btHingeConstraint &joint, btScalar jAngle, btScalar dAngle, int jointNum);

  void testForwardKins();
  void testInvKins();

  void cmdHome();
  void cmdMoveTo(double x, double y, double z);

  Cube *rm0;
  Cube *rm1;
  Cube *rm2;
  Cube *rm3;
  Cube *rm4;
  Cube *rm5;

  btHingeConstraint* rmJoint0;
  btHingeConstraint* rmJoint1;
  btHingeConstraint* rmJoint2;
  btHingeConstraint* rmJoint3;
  btHingeConstraint* rmJoint4;

  Robot *robot;
  CubeAxes *cube;

  ColumnVector oldqs;

  // control (cmd line)
  double angle[5];
  double pos[3];

  enum state_types {
    HALTED,
    FORWARD_KINS,
    INV_KINS
  };

  state_types state;

 protected:
  virtual void renderInLocalFrame(QTextStream *s) const;
 private:
};

#endif
