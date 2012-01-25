#include "cube.h"
#include <GL/glut.h>

#include <QDebug>

using namespace std;

#include <luabind/operator.hpp>

Cube::Cube(btVector3 dim, btScalar mass) {
  init(dim.getX(), dim.getY(), dim.getZ(), mass);
}

Cube::Cube(btScalar width, btScalar height, btScalar depth, btScalar mass) {
  init(width, height, depth, mass);
}

void Cube::init(btScalar width, btScalar height, btScalar depth, btScalar mass) {
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

  btRigidBody::btRigidBodyConstructionInfo bodyCI(mass, motionState, shape, btVector3(mass, mass, mass));
  bodyCI.m_friction = 5.0f;
  bodyCI.m_restitution = 0.50f;
  bodyCI.m_linearDamping = 0.5f;
  bodyCI.m_angularDamping = 0.05f;

  body = new btRigidBody(bodyCI);

  //body = new btRigidBody(mass, motionState, shape, btVector3(mass, mass, mass));
  //  body->SetMargin(0.05f);
}

void Cube::luaBind(lua_State *s) {
  using namespace luabind;

  open(s);

  module(s)
    [
     class_<Cube,Object>("Cube")
     .def(constructor<>())
     .def(constructor<btScalar, btScalar, btScalar, btScalar>())
     .def(constructor<btVector3>())
     .def(constructor<btVector3, btScalar>())
	 .def(tostring(const_self))
	 ];

  Object::luaBind(s);
}

QString Cube::toString() const {
  return QString("Cube");
}

void Cube::renderInLocalFrame(QTextStream *s) const {
  GLfloat no_mat[] = { 0.0, 0.0, 0.0, 1.0 };
  GLfloat mat_ambient[] = { color[0] / 255.0, color[1] / 255.0, color[2] / 255.0, 1.0 };
  GLfloat mat_diffuse[] = { 0.5, 0.5, 0.5, 1.0 };
  GLfloat mat_specular[] = { 1.0, 1.0, 1.0, 1.0 };
  GLfloat no_shininess[] = { 0.0 };
  GLfloat low_shininess[] = { 5.0 };
  GLfloat high_shininess[] = { 100.0 };
  GLfloat mat_emission[] = {0.3, 0.2, 0.2, 0.0};

  btTransform trans;
  btScalar m[16];

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
    *s << "box { <" << -lengths[0]/2.0 << ", " << -lengths[1]/2.0 << ", " << -lengths[2]/2.0 << ">, <" << lengths[0]/2.0 << ", " << lengths[1]/2.0 << ", " << lengths[2]/2.0 << ">\n";

    if (mTexture == NULL) {
      *s << "      pigment { rgb <" << color[0]/255.0 << ", " << color[1]/255.0 << ", " << color[2]/255.0 << "> }" << endl;
    } else {
      *s << mTexture << endl;
    }

    *s <<  "  matrix <" << m[0] << "," << m[1] << "," << m[2] << ",\n        " << m[4] << "," << m[5] << "," << m[6] << ",\n        " << m[8] << "," << m[9] << "," << m[10] << ",\n        " << m[12] << "," << m[13] << "," << m[14] << ">" << endl;
    *s << "}" << endl << endl;
  }
}
