#include "dice.h"

#include <GL/glut.h>

#include <QDebug>

using namespace std;

Dice::Dice(btScalar width, btScalar mass)
{
  lengths[0] = width;
  lengths[1] = width;
  lengths[2] = width;

  shape = new btBoxShape(btVector3(width * .5, width * .5, width * .5));

  btQuaternion qtn;
  btTransform trans;
  btDefaultMotionState *motionState;

  trans.setIdentity();
  qtn.setEuler(0.0, 0.0, 0.0);
  trans.setRotation(qtn);
  trans.setOrigin(btVector3(0, 0, 0));
  motionState = new btDefaultMotionState(trans);

  body = new btRigidBody(mass, motionState, shape, btVector3(mass, mass, mass));
}

void Dice::renderInLocalFrame(QTextStream *s) const
{
  btTransform trans;
  btScalar m[16];

  body->getMotionState()->getWorldTransform(trans);
  trans.getOpenGLMatrix(m);

  glPushMatrix();
  glMultMatrixf(m);
  glScalef(lengths[0], lengths[1], lengths[2]);
  glColor3ubv(color);
  glutSolidCube(1.0f);
  glPopMatrix();
  
  if (s != NULL) {
    *s << "object { Dice(";

    *s << "color rgb <" << color[0]/255.0 << ", " << color[1]/255.0 << ", " << color[2]/255.0 << ">" << ")" << endl;

    *s <<  "  matrix <" << m[0] << "," << m[1] << "," << m[2] << ",\n        " << m[4] << "," << m[5] << "," << m[6] << ",\n        " << m[8] << "," << m[9] << "," << m[10] << ",\n        " << m[12] << "," << m[13] << "," << m[14] << ">" << endl;

    *s << getPovPhotons();

    *s << "}" << endl << endl;
  }
}
