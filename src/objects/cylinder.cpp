#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "cylinder.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <GL/freeglut.h>

#include <QDebug>

using namespace std;

#include <luabind/operator.hpp>

Cylinder::Cylinder(const btVector3 &dim, btScalar mass) : Object() {
  init(dim.getX(), dim.getZ(), mass);
}

Cylinder::Cylinder(btScalar radius, btScalar depth, btScalar mass) : Object() {

  init(radius, depth, mass);
}

void Cylinder::init(btScalar radius, btScalar depth, btScalar mass) {

  lengths[0] = radius;
  lengths[1] = radius;
  lengths[2] = depth;

  shape = new btCylinderShapeZ(btVector3(radius, radius, depth * .5));

  btQuaternion qtn;
  btTransform trans;
  btDefaultMotionState *motionState;

  trans.setIdentity();
  qtn.setEuler(0.0, 0.0, 0.0);
  trans.setRotation(qtn);
  trans.setOrigin(btVector3(0, 0, 0));
  motionState = new btDefaultMotionState(trans);

  btVector3 inertia;
  shape->calculateLocalInertia(mass, inertia);
  body = new btRigidBody(mass, motionState, shape, inertia);
}

void Cylinder::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<Cylinder, Object>("Cylinder")
                .def(constructor<>())
                .def(constructor<const btVector3 &>())
                .def(constructor<const btVector3 &, btScalar>())
                .def(constructor<btScalar, btScalar>())
                .def(constructor<btScalar, btScalar, btScalar>())
                .def(tostring(const_self))];
}

QString Cylinder::toString() const { return QString("Cylinder"); }

void Cylinder::toPOV(QTextStream *s) const {
  if (body != NULL && body->getMotionState() != NULL) {
    btTransform trans;

    body->getMotionState()->getWorldTransform(trans);
    trans.getOpenGLMatrix(matrix);
  }

  if (s != NULL) {
    if (mPreSDL == NULL) {
      *s << "cylinder { " << -lengths[2] / 2.0 << "*z, " << lengths[2] / 2.0
         << "*z, " << lengths[0] << "\n";
    } else {
      *s << mPreSDL << "\n";
    }

    if (mSDL != NULL) {
      *s << mSDL << "\n";
    } else {
      *s << "  pigment { rgb <" << color[0] / 255.0 << ", " << color[1] / 255.0
         << ", " << color[2] / 255.0 << "> }" << "\n";
    }

    *s << "  matrix <" << matrix[0] << "," << matrix[1] << "," << matrix[2]
       << "," << "\n"
       << "          " << matrix[4] << "," << matrix[5] << "," << matrix[6]
       << "," << "\n"
       << "          " << matrix[8] << "," << matrix[9] << "," << matrix[10]
       << "," << "\n"
       << "          " << matrix[12] << "," << matrix[13] << "," << matrix[14]
       << ">" << "\n";

    if (mPostSDL == NULL) {
      *s << "}" << "\n"
         << "\n";
    } else {
      *s << mPostSDL << "\n";
    }
  }
}

void Cylinder::renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) {
  Q_UNUSED(minaabb)
  Q_UNUSED(maxaabb)

  // translate to match Bullet cylinder origin
  glTranslated(0, 0, -lengths[2] * .5);
  glScalef(lengths[0], lengths[1], lengths[2]);
  glColor3ubv(color);
  glutSolidCylinder(1, 1, 16, 16);
}
