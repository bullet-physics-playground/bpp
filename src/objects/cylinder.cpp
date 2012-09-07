#ifdef WIN32_VC90
#pragma warning (disable : 4251)
#endif

#include "cylinder.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <GL/freeglut.h>

#include <QDebug>

using namespace std;

#include <luabind/operator.hpp>

Cylinder::Cylinder(const btVector3& dim, btScalar mass) {
  init(dim.getX(), dim.getY(), dim.getZ(), mass);
}

Cylinder::Cylinder(btScalar width, btScalar height, btScalar depth,
				   btScalar mass) {

  init(width, height, depth, mass);
}

void Cylinder::init(btScalar width, btScalar height, btScalar depth,
					btScalar mass) {

  lengths[0] = width;
  lengths[1] = height;
  lengths[2] = depth;

  shape = new btCylinderShape(btVector3(width * .5, height * .5, depth * .5));

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

void Cylinder::luaBind(lua_State *s) {
  using namespace luabind;

  open(s);

  module(s)
    [
     class_<Cylinder, Object>("Cylinder")
     .def(constructor<>())
     .def(constructor<const btVector3&>())
     .def(constructor<const btVector3&, btScalar>())
     .def(constructor<btScalar, btScalar, btScalar>())
     .def(constructor<btScalar, btScalar, btScalar, btScalar>())
     .def(tostring(const_self))
     ];

  Object::luaBind(s);
}

QString Cylinder::toString() const {
  return QString("Cylinder");
}

void Cylinder::renderInLocalFrame(QTextStream *s) const
{
  btTransform trans;
  btScalar m[16];

  body->getMotionState()->getWorldTransform(trans);
  trans.getOpenGLMatrix(m);

  glPushMatrix();
  glMultMatrixf(m);
  glScalef(lengths[0] * .5, lengths[1] *.5, lengths[2] *.5);
  glColor3ubv(color);
  // FIXME glutSolidCylinder(1, 1, 8, 8);
  glPopMatrix();

  //TODO  
  if (s != NULL) {
    *s << "box { <" << -lengths[0]/2.0 << ", " << -lengths[1]/2.0 << ", " << -lengths[2]/2.0 << ">, <" << lengths[0]/2.0 << ", " << lengths[1]/2.0 << ", " << lengths[2]/2.0 << ">\n      pigment { rgb <" << color[0]/255.0 << ", " << color[1]/255.0 << ", " << color[2]/255.0 << "> }" << endl;
    *s <<  "  matrix <" << m[0] << "," << m[1] << "," << m[2] << ",\n        " << m[4] << "," << m[5] << "," << m[6] << ",\n        " << m[8] << "," << m[9] << "," << m[10] << ",\n        " << m[12] << "," << m[13] << "," << m[14] << ">" << endl;
    *s << "}" << endl << endl;
  }
}
