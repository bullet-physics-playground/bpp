/**
 * @file blob.cpp
 * @brief Implementation of the blob primitive.
 */

#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "blob.h"

#ifdef WIN32
#include <windows.h>
#endif

#include "glutils.h"

#include <QDebug>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

Blob::Blob(btScalar threshold, btScalar mass) {
  m_threshold = threshold;

  // Start with an empty compound shape
  shape = new btCompoundShape();

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

Blob::~Blob() {
  deleteOwnShape(false);
}

void Blob::addSphereComponent(const btVector3 &center, btScalar radius,
                              btScalar strength) {
  BlobComponent comp;
  comp.center = center;
  comp.radius = radius;
  comp.strength = strength;
  comp.isCylinder = false;
  comp.axis = btVector3(0, 1, 0);
  comp.height = 0;
  m_components.push_back(comp);

  // Add a sphere to the compound shape
  btSphereShape *sphereShape = new btSphereShape(radius);
  btTransform localTrans;
  localTrans.setIdentity();
  localTrans.setOrigin(center);
  static_cast<btCompoundShape *>(shape)->addChildShape(localTrans, sphereShape);

  // Recalculate inertia
  btVector3 inertia;
  shape->calculateLocalInertia(1.0, inertia);
  body->setMassProps(1.0, inertia);
}

void Blob::addCylinderComponent(const btVector3 &center,
                                const btVector3 &axis, btScalar radius,
                                btScalar height, btScalar strength) {
  BlobComponent comp;
  comp.center = center;
  comp.radius = radius;
  comp.strength = strength;
  comp.isCylinder = true;
  comp.axis = axis.normalized();
  comp.height = height;
  m_components.push_back(comp);

  // Approximate cylinder with a sphere for collision
  btSphereShape *sphereShape = new btSphereShape(radius > height ? radius : height);
  btTransform localTrans;
  localTrans.setIdentity();
  localTrans.setOrigin(center);
  static_cast<btCompoundShape *>(shape)->addChildShape(localTrans, sphereShape);

  btVector3 inertia;
  shape->calculateLocalInertia(1.0, inertia);
  body->setMassProps(1.0, inertia);
}

void Blob::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<Blob, Object>("Blob")
                .def(constructor<>(), adopt(result))
                .def(constructor<btScalar, btScalar>(), adopt(result))
                .def("addSphereComponent", &Blob::addSphereComponent)
                .def("addCylinderComponent", &Blob::addCylinderComponent)
                .property("threshold", &Blob::getThreshold,
                          &Blob::setThreshold)
                .def("componentCount", &Blob::componentCount)
                .def(tostring(const_self))
                .def(const_self == const_self)];
}

QString Blob::toString() const { return QString("Blob"); }

void Blob::toPOV(QTextStream *s) const {
  if (body != nullptr && body->getMotionState() != nullptr) {
    btTransform trans;

    body->getMotionState()->getWorldTransform(trans);
    trans.getOpenGLMatrix(matrix);
    povMatrixFromGL(matrix, matrix);
  }

  if (s != nullptr) {
    if (mPreSDL.isNull()) {
      *s << "blob { threshold " << m_threshold << "\n";
      for (const auto &comp : m_components) {
        if (comp.isCylinder) {
          *s << "  cylinder { <" << comp.center.x() << ", " << comp.center.y()
             << ", " << comp.center.z() << ">, <"
             << (comp.center.x() + comp.axis.x() * comp.height) << ", "
             << (comp.center.y() + comp.axis.y() * comp.height) << ", "
             << (comp.center.z() + comp.axis.z() * comp.height) << ">, "
             << comp.radius << " strength " << comp.strength << "\n";
        } else {
          *s << "  sphere { <" << comp.center.x() << ", " << comp.center.y()
             << ", " << comp.center.z() << ">, " << comp.radius
             << " strength " << comp.strength << "\n";
        }
      }
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

void Blob::renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) {
  Q_UNUSED(minaabb)
  Q_UNUSED(maxaabb)

  glApplyColor();
  for (const auto &comp : m_components) {
    glPushMatrix();
    glTranslatef(comp.center.x(), comp.center.y(), comp.center.z());
    if (comp.isCylinder) {
      solidCylinder(comp.radius, comp.height, 16, 8);
    } else {
      solidSphere(comp.radius, 16, 16);
    }
    glPopMatrix();
  }
}
