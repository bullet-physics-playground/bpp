#include "dice.h"

#include <GL/glut.h>

#include <QDebug>

using namespace std;

#include <luabind/operator.hpp>

Dice::Dice(btScalar width, btScalar mass) {
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

void Dice::luaBind(lua_State *s) {
  using namespace luabind;

  open(s);

  module(s)
    [
     class_<Dice, Object>("Dice")
     .def(constructor<>())
     .def(constructor<btScalar>())
     .def(constructor<btScalar, btScalar>())
     .def(tostring(const_self))
     ];

  Object::luaBind(s);
}

QString Dice::toString() const {
  return QString("Dice");
}

void Dice::renderInLocalFrame(QTextStream *s) const {
  btTransform trans;
  btScalar m[16];

  GLfloat no_mat[] = { 0.0, 0.0, 0.0, 1.0 };
  GLfloat mat_ambient[] = { color[0] / 255.0, color[1] / 255.0, color[2] / 255.0, 1.0 };
  GLfloat mat_diffuse[] = { 0.5, 0.5, 0.5, 1.0 };
  GLfloat mat_specular[] = { 1.0, 1.0, 1.0, 1.0 };
  //GLfloat no_shininess[] = { 0.0 };
  // GLfloat low_shininess[] = { 5.0 };
  GLfloat high_shininess[] = { 100.0 };
  // GLfloat mat_emission[] = {0.3, 0.2, 0.2, 0.0};

  body->getMotionState()->getWorldTransform(trans);
  trans.getOpenGLMatrix(m);

  glPushMatrix();
  glMultMatrixf(m);
  glScalef(lengths[0], lengths[1], lengths[2]);

  glMaterialfv(GL_FRONT, GL_AMBIENT, mat_ambient);
  glMaterialfv(GL_FRONT, GL_DIFFUSE, mat_diffuse);
  glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
  glMaterialfv(GL_FRONT, GL_SHININESS, high_shininess);
  glMaterialfv(GL_FRONT, GL_EMISSION, no_mat);

  //  glColor3ubv(color);

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
