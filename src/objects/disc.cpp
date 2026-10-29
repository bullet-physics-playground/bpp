/**
 * @file disc.cpp
 * @brief Implementation of the disc primitive.
 */

#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "disc.h"

#ifdef WIN32
#include <windows.h>
#endif

#include "glutils.h"

#include <QDebug>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

Disc::Disc(btScalar radius, btScalar height, btScalar mass) {
  init(radius, height, mass);
}

Disc::Disc(const btVector3 &dim, btScalar mass) {
  init(dim.getX(), dim.getY(), mass);
}

void Disc::init(btScalar r, btScalar h, btScalar mass) {
  radius = r;
  height = h;

  // Use btCylinderShape for disc collision
  shape = new btCylinderShapeZ(btVector3(radius, radius, height * .5));

  btQuaternion qtn;
  btTransform trans;
  btDefaultMotionState *motionState = nullptr;

  trans.setIdentity();
  qtn.setEuler(0.0, 0.0, 0.0);
  trans.setRotation(qtn);
  trans.setOrigin(btVector3(0, 0, 0));
  motionState = new btDefaultMotionState(trans);

  btVector3 inertia;
  shape->calculateLocalInertia(mass, inertia);
  body = new btRigidBody(mass, motionState, shape, inertia);
}

Disc::~Disc() {
  deleteOwnShape(true);
}

void Disc::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<Disc, Object>("Disc")
                 .def(constructor<>(), adopt(result))
                 .def(constructor<btScalar, btScalar>(), adopt(result))
                 .def(constructor<btScalar, btScalar, btScalar>(), adopt(result))
                 .def(constructor<const btVector3 &>(), adopt(result))
                 .def(constructor<const btVector3 &, btScalar>(), adopt(result))
                 .def(tostring(const_self))
                 .def(const_self == const_self)];
}

QString Disc::toString() const { return QString("Disc"); }

void Disc::povPigment(QTextStream *s) const {
  if (s == nullptr || getTexture().isEmpty()) {
    Object::povPigment(s);
    return;
  }

  // For disc, use planar mapping
  *s << "  texture {\n";
  *s << "    pigment {\n";
  *s << "      image_map {\n";
  *s << "        \"" << getTexture().toStdString().c_str() << "\"\n";
  *s << "        map_type 0\n";  // planar
  *s << "      }\n";
  *s << "    }\n";
  *s << "  }\n";
}

void Disc::toPOV(QTextStream *s) const {
  if (body != nullptr && body->getMotionState() != nullptr) {
    btTransform trans;

    body->getMotionState()->getWorldTransform(trans);
    if (placed)
      trans = place * trans;
    trans.getOpenGLMatrix(matrix);
    povMatrixFromGL(matrix, matrix);
  }

  if (s != nullptr) {
    if (mPreSDL.isNull()) {
      // POV-Ray disc: disc { <center>, normal, radius }
      *s << "disc { <0, 0, 0>, <0, 0, 1>, " << radius << "\n";
    } else {
      *s << mPreSDL << "\n";
    }

    if (!mSDL.isNull()) {
      *s << mSDL << "\n";
    } else {
      povPigment(s);
    }

    *s << "  matrix <" << matrix[0] << "," << matrix[1] << "," << matrix[2]
       << "," << "\n"
       << "          " << matrix[4] << "," << matrix[5] << "," << matrix[6]
       << "," << "\n"
       << "          " << matrix[8] << "," << matrix[9] << "," << matrix[10]
       << "," << "\n"
       << "          " << matrix[12] << "," << matrix[13] << "," << matrix[14]
       << ">" << "\n";

    if (mPostSDL.isNull()) {
      *s << "}" << "\n"
         << "\n";
    } else {
      *s << mPostSDL << "\n";
    }
  }
}

void Disc::renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) {
  Q_UNUSED(minaabb)
  Q_UNUSED(maxaabb)

  // Disc lies in XY plane, centred on origin
  glScalef(radius, radius, height);
  glApplyColor();
  solidDisc(1.0, 1.0, 32, 1);
}