/**
 * @file bound.cpp
 * @brief Implementation of the bound object primitive.
 */

#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "bound.h"

#ifdef WIN32
#include <windows.h>
#endif

#include "glutils.h"

#include <QDebug>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

Bound::Bound(btCollisionShape *boundShape, btScalar mass) {
  m_boundShape = boundShape;

  if (m_boundShape) {
    shape = m_boundShape;
  } else {
    shape = new btSphereShape(1.0);
  }

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

Bound::~Bound() {
  deleteOwnShape(false);
}

void Bound::setBoundShape(btCollisionShape *shape) {
  m_boundShape = shape;
  // Note: changing the shape after construction requires rebuilding the body,
  // which is not supported here for simplicity.
}

void Bound::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<Bound, Object>("Bound")
                .def(constructor<>(), adopt(result))
                .def(constructor<btCollisionShape *>(), adopt(result))
                .def(constructor<btCollisionShape *, btScalar>(),
                     adopt(result))
                .property("boundShape", &Bound::getBoundShape,
                          &Bound::setBoundShape)
                .def(tostring(const_self))
                .def(const_self == const_self)];
}

QString Bound::toString() const { return QString("Bound"); }

void Bound::toPOV(QTextStream *s) const {
  if (body != nullptr && body->getMotionState() != nullptr) {
    btTransform trans;

    body->getMotionState()->getWorldTransform(trans);
    trans.getOpenGLMatrix(matrix);
    povMatrixFromGL(matrix, matrix);
  }

  if (s != nullptr) {
    if (mPreSDL.isNull()) {
      // Write the bound shape as a POV-Ray primitive inside bounded_by
      *s << "bounded_by { ";
      if (m_boundShape) {
        if (dynamic_cast<btSphereShape *>(m_boundShape)) {
          btSphereShape *sphere = static_cast<btSphereShape *>(m_boundShape);
          *s << "sphere { <0,0,0>, " << sphere->getRadius() << " }";
        } else if (dynamic_cast<btBoxShape *>(m_boundShape)) {
          btBoxShape *box = static_cast<btBoxShape *>(m_boundShape);
          btVector3 half = box->getHalfExtentsWithMargin();
          *s << "box { <" << -half.x() << ", " << -half.y() << ", " << -half.z()
             << ">, <" << half.x() << ", " << half.y() << ", " << half.z()
             << "> }";
        } else if (dynamic_cast<btCylinderShape *>(m_boundShape)) {
          btCylinderShape *cyl = static_cast<btCylinderShape *>(m_boundShape);
          btVector3 half = cyl->getHalfExtentsWithMargin();
          *s << "cylinder { <0,0,0>, <0," << half.y() * 2 << ",0>, "
             << half.x() << " }";
        } else {
          *s << "sphere { <0,0,0>, 1 }";
        }
      } else {
        *s << "sphere { <0,0,0>, 1 }";
      }
      *s << "}\n";
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

void Bound::renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) {
  Q_UNUSED(minaabb)
  Q_UNUSED(maxaabb)

  glApplyColor();
  if (m_boundShape) {
    if (dynamic_cast<btSphereShape *>(m_boundShape)) {
      btSphereShape *sphere = static_cast<btSphereShape *>(m_boundShape);
      solidSphere(sphere->getRadius(), 16, 16);
    } else if (dynamic_cast<btBoxShape *>(m_boundShape)) {
      btBoxShape *box = static_cast<btBoxShape *>(m_boundShape);
      btVector3 half = box->getHalfExtentsWithMargin();
      glScalef(half.x() * 2, half.y() * 2, half.z() * 2);
      solidCube(1.0f);
    } else {
      solidSphere(1.0f, 16, 16);
    }
  }
}
