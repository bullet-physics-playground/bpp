#include "sphere.h"
#include <GL/glut.h>

#include <QDebug>

using namespace std;

Sphere::Sphere(btScalar pradius, btScalar mass)
{
  radius = pradius;

  shape = new btSphereShape(radius);

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

void Sphere::renderInLocalFrame(QTextStream *s) const
{
  btTransform trans;
  btScalar m[16];

  glPushMatrix();

  body->getMotionState()->getWorldTransform(trans);
  trans.getOpenGLMatrix(m);

  /*
  m[ 0] = r[ 0];m[ 1] = r[ 4];m[ 2] = r[ 8];m[ 3] = 0;
  m[ 4] = r[ 1];m[ 5] = r[ 5];m[ 6] = r[ 9];m[ 7] = 0;
  m[ 8] = r[ 2];m[ 9] = r[ 6];m[10] = r[10];m[11] = 0;
  m[12] = p[ 0];m[13] = p[ 1];m[14] = p[ 2];m[15] = 1;
  */
  glMultMatrixf(m);
  
  glScalef(radius, radius, radius);
  glColor3ubv(color);
  glutSolidSphere(1.0f, 8, 8);
  glPopMatrix();
  
  if (s != NULL) {
    *s << "sphere { <.0,.0,.0>, " << radius << "\n      pigment { rgb <" << color[0]/255.0 << ", " << color[1]/255.0 << ", " << color[2]/255.0 << "> }" << endl;
    *s <<  "  matrix <" << m[0] << "," << m[1] << "," << m[2] << ",\n        " << m[4] << "," << m[5] << "," << m[6] << ",\n        " << m[8] << "," << m[9] << "," << m[10] << ",\n        " << m[12] << "," << m[13] << "," << m[14] << ">" << endl;
    *s << "}" << endl << endl;
  }
}
