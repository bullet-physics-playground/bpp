#include "cubeaxes.h"

#ifdef WIN32
#pragma warning (disable : 4251)
#include <windows.h>
#endif

#include <GL/glut.h>

#include <QDebug>

using namespace std;

CubeAxes::CubeAxes(btScalar width, btScalar height, btScalar depth, btScalar mass)
{
  lengths[0] = width;
  lengths[1] = height;
  lengths[2] = depth;

  shape = new btBoxShape(btVector3(width * .5, height * .5, depth * .5));

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

void CubeAxes::renderInLocalFrame(QTextStream *s) const
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

  glPushMatrix();
  glColor3ub(255, 0, 0);
  glRotatef(90.0, 0.0, 1.0, 0.0);
  // FIXME glutSolidCylinder(0.25, 1.0, 8, 8);
  glPopMatrix();

  glPushMatrix();
  glColor3ub(0, 255, 0);
  glRotatef(90.0, 1.0, 0.0, 0.0);
  // FIXME glutSolidCylinder(0.25, 1.0, 8, 8);
  glPopMatrix();

  glPushMatrix();
  glColor3ub(0, 0, 255);
  glRotatef(180.0, 0.0, 0.0, 1.0);
  // FIXME glutSolidCylinder(0.25, 1.0, 8, 8);
  glPopMatrix();

  glPopMatrix();
  
  if (s != NULL) {
    *s << "box { <" << -lengths[0]/2.0 << ", " << -lengths[1]/2.0 << ", " << -lengths[2]/2.0 << ">, <" << lengths[0]/2.0 << ", " << lengths[1]/2.0 << ", " << lengths[2]/2.0 << ">\n      pigment { rgb <" << color[0]/255.0 << ", " << color[1]/255.0 << ", " << color[2]/255.0 << "> }" << endl;
    *s <<  "  matrix <" << m[0] << "," << m[1] << "," << m[2] << ",\n        " << m[4] << "," << m[5] << "," << m[6] << ",\n        " << m[8] << "," << m[9] << "," << m[10] << ",\n        " << m[12] << "," << m[13] << "," << m[14] << ">" << endl;
    *s << "}" << endl << endl;
  }
}
