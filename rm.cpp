#include "rm.h"

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

static btScalar Pk[5] = {  20,    20,    20,    20,    40};
static btScalar Dk[5] = {   5,     5,     5,     5,     10};
static btScalar Ik[5] = {    0.01,   0.01,   0.01,   0.01,   0.01};

static btScalar Ikmax[5]={10, 10, 30, 30, 30};

void RM::pidControl(btHingeConstraint &joint, btScalar jAngle, btScalar dAngle, int jointNum) {

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

int atime = 0;

void RM::animate() {
  atime++;

  if ( atime < 100 ) {
    pidControl(*rmJoint0, rmJoint0->getHingeAngle(), d2r(0), 0);
    pidControl(*rmJoint1, rmJoint1->getHingeAngle(), d2r(0), 1);
    pidControl(*rmJoint2, rmJoint2->getHingeAngle(), d2r(0), 2);
    pidControl(*rmJoint3, rmJoint3->getHingeAngle(), d2r(0), 3);
    //    pidControl(*rmJoint4, rmJoint4->getTwistAngle(), d2r(0), 4);
  } else if (atime < 200) {
    pidControl(*rmJoint0, rmJoint0->getHingeAngle(), d2r(0), 0);
    pidControl(*rmJoint1, rmJoint1->getHingeAngle(), d2r(0), 1);
    pidControl(*rmJoint2, rmJoint2->getHingeAngle(), d2r(0), 2);
    pidControl(*rmJoint3, rmJoint3->getHingeAngle(), d2r(0), 3);
    //pidControl(*rmJoint4, rmJoint4->getTwistAngle(), d2r(0), 4);
  } else if (atime < 300) {
    pidControl(*rmJoint0, rmJoint0->getHingeAngle(), d2r(0), 0);
    pidControl(*rmJoint1, rmJoint1->getHingeAngle(), d2r(0), 1);
    pidControl(*rmJoint2, rmJoint2->getHingeAngle(), d2r(0), 2);
    pidControl(*rmJoint3, rmJoint3->getHingeAngle(), d2r(0), 3);
    //pidControl(*rmJoint4, rmJoint4->getTwistAngle(), d2r(90), 4);
  } else {
    pidControl(*rmJoint0, rmJoint0->getHingeAngle(), d2r(0), 0);
    pidControl(*rmJoint1, rmJoint1->getHingeAngle(), d2r(0), 1);
    pidControl(*rmJoint2, rmJoint2->getHingeAngle(), d2r(0), 2);
    pidControl(*rmJoint3, rmJoint3->getHingeAngle(), d2r(0), 3);
    //pidControl(*rmJoint4, rmJoint4->getTwistAngle(), d2r(90), 4);
  }

  // cube
  ColumnVector qr = ColumnVector(5);
  qr << rmJoint0->getHingeAngle()
     << -rmJoint1->getHingeAngle()
     << -rmJoint2->getHingeAngle()
     << -rmJoint3->getHingeAngle()
     << 0.0;//rmJoint4->getHingeAngle();
  robot->set_q(qr);

  Matrix Tobj = robot->kine();

  /*
  cout << "Robot position\n";
  cout << setw(7) << setprecision(2) << Tobj;

  cout << "Robot angels:";
  cout << setw(7) << setprecision(2) << qr;
  */

  // cout << setw(7) << setprecision(2) << Tobj(1,4) << ", " << Tobj(2,4) << ", " << Tobj(3,4) << endl;
  cube->setPosition(-Tobj(2,4), Tobj(3,4), Tobj(1,4));
  /*
  btVector3 R (Tobj(1,3), Tobj(1,2), Tobj(1,1),
                Tobj(2,3), Tobj(2,2), Tobj(2,1),
	       Tobj(3,3), Tobj(3,2), Tobj(3,1));
	       cube->setRotation(R2); */

}

// type, theta, d, a, alpha, ..
const Real RR_data[] =
  {0,  1.57,  25.0,   0.0, -1.57, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0, -0.92, 0,      22.0,  0,    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0,  0.63, 0,      15.0,  0,    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0,  0.6,  0,      20.0,  1.57, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
   0,  0.0,  0,       0.0, -1.57, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

RM::RM() {

  Matrix initrob(5, 23), Tobj;
  ColumnVector qs, qr;
  int dof = 0;

  initrob << RR_data;
  robot = new Robot(initrob);
  dof = robot->get_dof();

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

  cube = new Cube(2.0, 2.0, 2.0, 0.0);
  cube->setColor(0, 255, 0);

  rm0 = new Mesh3DS("rm501_0.3ds", 0.0);
  rm0->setPosition(0.0, 0.0, 0.0);
  rm0->setRotation(btVector3(1.0, 0.0, 0.0), d2r(-90.0));
  rm0->setColor(155,155,155);
  rm0->body->setActivationState(DISABLE_DEACTIVATION);

  rm1 = new Mesh3DS("rm501_1.3ds", 1.0);
  rm1->setPosition(0.0, 0.0, 0.0);
  rm1->setRotation(btVector3(1.0, 0.0, 0.0), d2r(-90.0));
  rm1->setColor(255,155,155);
  rm1->body->setActivationState(DISABLE_DEACTIVATION);

  const btVector3 btPivot0( 0.0, 0.0f, 0.0f );
  btVector3 btAxis0( 0.0f, 0.0f, 1.0f );
  rmJoint0 = new btHingeConstraint(*rm0->body, *rm1->body, btPivot0, btPivot0, btAxis0, btAxis0);
  // dynamicsWorld->addConstraint(rmJoint0);

  rm2 = new Mesh3DS("rm501_2.3ds", 1.0);
  rm2->setPosition(0.0, 25.0, 0.0);
  rm2->setRotation(btVector3(1.0, 0.0, 0.0), d2r(-90.0));
  rm2->setColor(255,155,155);
  rm2->body->setActivationState(DISABLE_DEACTIVATION);

  btVector3 pivotInA1(0, 0.0, 25.0);
  btVector3 axisInA1(1,0,0);

  btVector3 pivotInB1 = rm2->body->getCenterOfMassTransform().inverse()(rm1->body->getCenterOfMassTransform()(pivotInA1));
  btVector3 axisInB1 = rm2->body->getCenterOfMassTransform().getBasis().inverse()*(rm1->body->getCenterOfMassTransform().getBasis() * axisInA1);

  rmJoint1 = new btHingeConstraint(*rm1->body, *rm2->body, pivotInA1, pivotInB1, axisInA1, axisInB1);

  rm3 = new Mesh3DS("rm501_3.3ds", 0.005);
  rm3->setPosition(0.0, 25.0, 22.5);
  rm3->setRotation(btVector3(1.0, 0.0, 0.0), d2r(-90.0));
  rm3->setColor(255,155,155);
  rm3->body->setActivationState(DISABLE_DEACTIVATION);

  btVector3 pivotInA2(0.0, -22, 0.0);
  btVector3 axisInA2(1, 0, 0);

  btVector3 pivotInB2(0.0, 1.0, 0.0);
  btVector3 axisInB2 (1, 0, 0);
  rmJoint2 = new btHingeConstraint(*rm2->body, *rm3->body, pivotInA2, pivotInB2, axisInA2, axisInB2);

  rm4 = new Cube(5.0, 5.0, 5.0, 0.001);
  rm4->setPosition(0.0, 25.0, 22.0+17.0+3);
  rm4->setColor(200,200,255);
  rm4->body->setActivationState(DISABLE_DEACTIVATION);

  btVector3 pivotInA3(0.0, -15, 0.0);
  btVector3 axisInA3(1, 0, 0);

  btVector3 pivotInB3(0.0, 3.0, 0.0);
  btVector3 axisInB3(1, 0, 0);

  rmJoint3 = new btHingeConstraint(*rm3->body, *rm4->body, pivotInA3, pivotInB3, axisInA3, axisInB3);

  rm5 = new Mesh3DS("rm501_4.3ds", 0.001);
  rm5->setPosition(0.0, 25.0, 22.0+17.0+3.0);
  rm5->setRotation(btVector3(1.0, 0.0, 0.0), d2r(-90.0));
  rm5->setColor(200,200,200);
  rm5->body->setActivationState(DISABLE_DEACTIVATION);

  btTransform localA, localB;
  localA.setIdentity(); localB.setIdentity();
  localA.getBasis().setEulerZYX(0,M_PI_2,0); localA.setOrigin(btVector3(btScalar(0.), btScalar(0.15), btScalar(0.)));
  localB.getBasis().setEulerZYX(0,M_PI_2,0); localB.setOrigin(btVector3(btScalar(0.), btScalar(-0.15), btScalar(0.)));
  rmJoint4 = new btGeneric6DofConstraint(*rm4->body, *rm5->body, localA, localB, false);

  btVector3 lowerSliderLimit = btVector3(0,0,-10);
  btVector3 hiSliderLimit = btVector3(0,0,10);

  rmJoint4->setLinearUpperLimit(hiSliderLimit);
}

void RM::renderInLocalFrame(QTextStream *) const {
}
