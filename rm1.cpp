#include "rm1.h"

#include <QDebug>

#define pi (3.1415926535f)

static btScalar d2r(btScalar degrees)
{
  return degrees * pi / 180;
}

static btScalar r2d(btScalar radians)
{
  return radians * 180 / pi;
}

#define MAX_N_JOINTS 5

static btScalar prev_dAngle[MAX_N_JOINTS] = {0.0};//stores the last desired angle of each joint.
static btScalar jIntErr[MAX_N_JOINTS] = {0.0};

static btScalar Pk[5] = {  40.0f,    40.0f,    40.0f,    40.0f,    40.0f};
static btScalar Dk[5] = {   5.0f,     5.0f,     5.0f,     5.0f,     10.0f};
static btScalar Ik[5] = {    0.01f,   0.01f,   0.01f,   0.01f,   0.01f};

static btScalar Ikmax[5]={10.0f, 10.0f, 30.0f, 30.0f, 30.0f};

void RM1::pidControl(btHingeConstraint &joint, btScalar jAngle, btScalar dAngle, int jointNum) {

  btScalar jAngleRate = 0.0;

  int jntChk = -1;

  //Determine if new desired angle is chosen. If so, reset error integral
  if( prev_dAngle[jointNum] != dAngle) {
    jIntErr[jointNum] = 0;
    //printf ("reseting joint[%i] integral term...\n", jointNum);
  }
  prev_dAngle[jointNum] = dAngle;//update latest desired angle for the joint

  btScalar prop = dAngle - jAngle;//proportional difference.

  //integrate error term and assign torque
  jIntErr[jointNum] =  jIntErr[jointNum] + (prop);
  if( jIntErr[jointNum] > Ikmax[jointNum])//integral term saturates
    jIntErr[jointNum] = Ikmax[jointNum];

  btScalar torque = Pk[jointNum]*(prop)-Dk[jointNum]*jAngleRate+Ik[jointNum]*jIntErr[jointNum];

  if( jointNum == jntChk)
    printf( "torque: %g , Pcomp: %g , jAng: %g  ,  dAng:%g\n", torque, prop, jAngle, dAngle );
  
  joint.enableAngularMotor(true, torque * 0.04, 1000);
}

void RM1::cmdHome() {
  state = FORWARD_KINS;

  angle[0] = 0.0;
  angle[1] = 0.0;
  angle[2] = 0.0;
  angle[3] = 0.0;
  angle[4] = 0.0;
}

void RM1::cmdMoveTo(double x, double y, double z) {
  state = INV_KINS;

  pos[0] = x;
  pos[1] = y;
  pos[2] = z;
}

int matime = 0;

void RM1::animate() {
  matime++;

  if (state == INV_KINS) {
    testInvKins();
  } else if (state == FORWARD_KINS) {
    testForwardKins();
  } else if( state == HALTED) {
    rmJoint0->enableAngularMotor(false, 0, 100);
    rmJoint1->enableAngularMotor(false, 0, 100);
    rmJoint2->enableAngularMotor(false, 0, 100);
    rmJoint3->enableAngularMotor(false, 0, 100);
    rmJoint4->enableAngularMotor(false, 0, 100);
  }
}

void RM1::testInvKins() {
  ColumnVector qr = ColumnVector(5);
  qr << angle[0] << angle[1]<< angle[2]<< angle[3]<< angle[4]; 
  robot->set_q(qr);
  Matrix Tobj = robot->kine();

  Tobj(1,4) = pos[0];
  Tobj(2,4) = pos[1];
  Tobj(3,4) = pos[2];

  ColumnVector qs = ColumnVector(5);
  bool converged;
  qs = robot->inv_kin(Tobj, 0, 5, converged);

  if (converged) {
    cube->setColor(0, 255, 0);
    oldqs = qs;
  } else {
    cube->setColor(255, 0, 0);
  }

  btScalar R[16] = {Tobj(1,1), Tobj(2,1), Tobj(3,1), 0.0,
		    Tobj(1,2), Tobj(2,2), Tobj(3,2), 0.0,
		    Tobj(1,3), Tobj(2,3), Tobj(3,3), 0.0,
		    -Tobj(2,4), 4-Tobj(3,4), Tobj(1,4), 1.0 };

  btTransform t;
  t.setFromOpenGLMatrix(R);

  btQuaternion r(btVector3(0, 0, 1), d2r(-90));
  t.setRotation( r * t.getRotation());

  btQuaternion r1(btVector3(1, 0, 0), d2r(90));
  t.setRotation( r1 * t.getRotation());
  cube->setTransform(t);

  pidControl(*rmJoint0, rmJoint0->getHingeAngle(), oldqs(1), 0);
  pidControl(*rmJoint1, rmJoint1->getHingeAngle(), oldqs(2), 1);
  pidControl(*rmJoint2, rmJoint2->getHingeAngle(), oldqs(3), 2);
  pidControl(*rmJoint3, rmJoint3->getHingeAngle(), oldqs(4), 3);
  pidControl(*rmJoint4, rmJoint4->getHingeAngle(), oldqs(5), 4);

  /*
  cout << "Robot position\n";
  cout << setw(7) << setprecision(2) << Tobj;

  cout << "Robot angels:" << endl;
  cout << setw(7) << setprecision(2) << qs;
  */
}

void RM1::testForwardKins() {

  cube->setColor(255, 255, 255);

  pidControl(*rmJoint0, rmJoint0->getHingeAngle(), angle[0], 0);
  pidControl(*rmJoint1, rmJoint1->getHingeAngle(), angle[1], 1);
  pidControl(*rmJoint2, rmJoint2->getHingeAngle(), angle[2], 2);
  pidControl(*rmJoint3, rmJoint3->getHingeAngle(), angle[3], 3);
  pidControl(*rmJoint4, rmJoint4->getHingeAngle(), angle[4], 4);

  // cube
  ColumnVector qr = ColumnVector(5);
  qr << rmJoint0->getHingeAngle()
     << rmJoint1->getHingeAngle()
     << rmJoint2->getHingeAngle()
     << rmJoint3->getHingeAngle()
     << rmJoint4->getHingeAngle();

  robot->set_q(qr);

  Matrix Tobj = robot->kine();

  //cout << "Robot position\n";
  //cout << setw(7) << setprecision(2) << Tobj;

  //cout << "Robot angels:";
  //cout << setw(7) << setprecision(2) << qr;

  //cout << setw(7) << setprecision(2) << Tobj(1,4) << ", " << Tobj(2,4) << ", " << Tobj(3,4) << endl;
  //  cube->setPosition(-Tobj(2,4), Tobj(3,4), Tobj(1,4));

  btScalar R[16] = {Tobj(1,1), Tobj(2,1), Tobj(3,1), 0.0,
		    Tobj(1,2), Tobj(2,2), Tobj(3,2), 0.0,
		    Tobj(1,3), Tobj(2,3), Tobj(3,3), 0.0,
		    -Tobj(2,4), Tobj(3,4), Tobj(1,4), 1.0 };

  btTransform t;
  t.setFromOpenGLMatrix(R);

  btQuaternion r(btVector3(0, 0, 1), d2r(-90));
  t.setRotation( r * t.getRotation());

  btQuaternion r1(btVector3(1, 0, 0), d2r(90));
  t.setRotation( r1 * t.getRotation());
  cube->setTransform(t);
}

// type, theta, d, a, alpha, ..
const Real RR_data[] =
  {0,  0.0, 2.0,    0.0, 1.57,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0,  0.0, 0,      2.0,  0,    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0,  0.0, 0,      2.0,  0,    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0,  1.57, 0,      0.0, -1.57,    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0,  1.57, 1.0,   0.0, 0.0,    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

RM1::RM1() {

  state = HALTED;

  Matrix initrob(5, 23), Tobj;
  ColumnVector qs, qr;
  int dof = 0;

  initrob << RR_data;
  robot = new Robot(initrob);
  dof = robot->get_dof();

  /*
  cout << "\n";
  cout << "Robot D-H parameters\n";
  cout << "   type     theta      d        a      alpha\n";
  cout << setw(7) << setprecision(3) << initrob.SubMatrix(1,dof,1,5);
  cout << "\n";
  cout << "Robot joints variables\n";
  cout << setw(7) << setprecision(3) << robot->get_q();
  cout << "\n";
  cout << "Robot position\n";
  cout << setw(7) << setprecision(3) << robot->kine();
  cout << "\n";
  */

  cube = new CubeAxes(.55f, .55f, .55f, 0.0f);
  cube->setColor(255, 255, 255);

  rm0 = new Cube(.75, 1.0, .75, 0.0);
  rm0->setPosition(0.0, 0.5, 0.0);
  rm0->setColor(155,155,155);
  rm0->body->setActivationState(DISABLE_DEACTIVATION);

  rm1 = new Cube(.65f, 1.0f, .65f, 0.1f);
  rm1->setPosition(0.0, 0.5 + 1.0, 0.0);
  //  rm1->setRotation(btVector3(1.0, 0.0, 0.0), d2r(-90.0));
  rm1->setColor(255,55,55);
  rm1->body->setActivationState(DISABLE_DEACTIVATION);

  const btVector3 btPivot0( 0.0, 0.5f, 0.0f );
  const btVector3 btPivot1( 0.0, -0.5f, 0.0f );
  btVector3 btAxis0( 0.0f, 1.0f, 0.0f );
  rmJoint0 = new btHingeConstraint(*rm0->body, *rm1->body, btPivot0, btPivot1, btAxis0, btAxis0);

  rm2 = new Cube(.55f, .55f, 2.0f, 0.1f);
  rm2->setPosition(0.0, 0.5 + 1.5, 1);
  rm2->setColor(255,55,55);
  rm2->body->setActivationState(DISABLE_DEACTIVATION);

  btVector3 pivotInA1(0, 0.5, 0.);
  btVector3 pivotInB1(0, 0., -1);
  btVector3 axisInA1(1,0,0);
  btVector3 axisInB1(1,0,0);
  rmJoint1 = new btHingeConstraint(*rm1->body, *rm2->body, pivotInA1, pivotInB1, axisInA1, axisInB1);
  //  rmJoint1->setLimit(d2r(-30), d2r(90));

  rm3 = new Cube(.45f, .45f, 2.0f, 0.01f);
  rm3->setPosition(0.0, .5 + 1.5, 3.);
  rm3->setColor(255,55,55);
  rm3->body->setActivationState(DISABLE_DEACTIVATION);

  btVector3 pivotInA2(0.0, .0, 1.0);
  btVector3 pivotInB2(0.0, .0, -1.0);
  btVector3 axisInA2(1,0,0);
  btVector3 axisInB2(1,0,0);
  rmJoint2 = new btHingeConstraint(*rm2->body, *rm3->body, pivotInA2, pivotInB2, axisInA2, axisInB2);
  //  rmJoint2->enableAngularMotor(true, 0.4, 1000);
  //  rmJoint2->setLimit(d2r(-90), d2r(0));

  rm4 = new Cube(.35f, .35f, 0.35f, 0.001f);
  rm4->setPosition(0.0, 0.5 + 1.5, 4.0);
  rm4->setColor(255,55,55);
  rm4->body->setActivationState(DISABLE_DEACTIVATION);

  btVector3 pivotInA3(0.0, 0.0, 1.0);
  btVector3 pivotInB3(0.0, .0, .0);
  btVector3 axisInA3(1, 0, 0);
  btVector3 axisInB3(1, 0, 0);
  rmJoint3 = new btHingeConstraint(*rm3->body, *rm4->body, pivotInA3, pivotInB3, axisInA3, axisInB3);
  //  rmJoint3->setLimit(d2r(-90), d2r(90));

  rm5 = new Cube(.2f, 1.0f, .2f, 0.0001f);
  rm5->setPosition(0.0, .5 + 2.0, 4.0);
  rm5->setColor(255,255,255);
  rm5->body->setActivationState(DISABLE_DEACTIVATION);

  btVector3 pivotInA4(0.0, .0, 0.);
  btVector3 pivotInB4(0.0, -.5, 0);
  btVector3 axisInA4(0, 1, 0);
  btVector3 axisInB4(0, 1, 0);
  rmJoint4 = new btHingeConstraint(*rm4->body, *rm5->body, pivotInA4, pivotInB4, axisInA4, axisInB4);
}

void RM1::renderInLocalFrame(QTextStream *) const {
}
