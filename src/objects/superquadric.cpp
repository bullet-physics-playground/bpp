/**
 * @file superquadric.cpp
 * @brief Implementation of the superquadric primitive.
 */

#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "superquadric.h"

#ifdef WIN32
#include <windows.h>
#endif

#include "glutils.h"

#include <QDebug>
#include <cmath>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

SuperQuadric::SuperQuadric(btScalar roundness, btScalar thickness,
                           btScalar size, btScalar mass) {
  m_roundness = roundness;
  m_thickness = thickness;
  m_size = size;

  shape = new btBoxShape(btVector3(m_size * 0.5, m_size * 0.5, m_size * 0.5));

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

SuperQuadric::~SuperQuadric() {
  deleteOwnShape(false);
}

void SuperQuadric::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<SuperQuadric, Object>("SuperQuadric")
                .def(constructor<>(), adopt(result))
                .def(constructor<btScalar>(), adopt(result))
                .def(constructor<btScalar, btScalar>(), adopt(result))
                .def(constructor<btScalar, btScalar, btScalar>(),
                     adopt(result))
                .def(constructor<btScalar, btScalar, btScalar, btScalar>(),
                     adopt(result))
                .property("roundness", &SuperQuadric::getRoundness,
                          &SuperQuadric::setRoundness)
                .property("thickness", &SuperQuadric::getThickness,
                          &SuperQuadric::setThickness)
                .property("size", &SuperQuadric::getSize,
                          &SuperQuadric::setSize)
                .def(tostring(const_self))
                .def(const_self == const_self)];
}

QString SuperQuadric::toString() const { return QString("SuperQuadric"); }

void SuperQuadric::toPOV(QTextStream *s) const {
  if (body != nullptr && body->getMotionState() != nullptr) {
    btTransform trans;

    body->getMotionState()->getWorldTransform(trans);
    trans.getOpenGLMatrix(matrix);
    povMatrixFromGL(matrix, matrix);
  }

  if (s != nullptr) {
    if (mPreSDL.isNull()) {
      *s << "superellipsoid { <" << m_roundness << ", " << m_thickness << ">\n";
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

    if (mBoundShape != nullptr) {
      *s << "  bounded_by { ";
      if (dynamic_cast<btSphereShape *>(mBoundShape)) {
        btSphereShape *sphere = static_cast<btSphereShape *>(mBoundShape);
        *s << "sphere { <0,0,0>, " << sphere->getRadius() << " }";
      } else if (dynamic_cast<btBoxShape *>(mBoundShape)) {
        btBoxShape *box = static_cast<btBoxShape *>(mBoundShape);
        btVector3 half = box->getHalfExtentsWithMargin();
        *s << "box { <" << -half.x() << ", " << -half.y() << ", " << -half.z()
           << ">, <" << half.x() << ", " << half.y() << ", " << half.z()
           << "> }";
      } else {
        *s << "sphere { <0,0,0>, 0 }";
      }
      *s << "}" << "\n";
    }

    if (mNoImage)
      *s << "  no_image" << "\n";
    if (mNoReflection)
      *s << "  no_reflection" << "\n";
    if (mDoubleIlluminate)
      *s << "  double_illuminate" << "\n";
    if (mHollow)
      *s << "  hollow" << "\n";

    QString photons = getPovPhotons();
    if (!photons.isEmpty())
      *s << photons;

    if (!mPreMatrixSDL.isNull())
      *s << mPreMatrixSDL << "\n";

    if (mPostSDL.isNull()) {
      *s << "}" << "\n"
         << "\n";
    } else {
      *s << mPostSDL << "\n";
    }
  }
}

void SuperQuadric::renderInLocalFrame(btVector3 &minaabb,
                                      btVector3 &maxaabb) {
  Q_UNUSED(minaabb)
  Q_UNUSED(maxaabb)

  glApplyColor();
  glScalef(m_size, m_size, m_size);
  solidSphere(1.0f, 32, 16);
}
