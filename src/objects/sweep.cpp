/**
 * @file sweep.cpp
 * @brief Implementation of the sweep primitive.
 */

#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "sweep.h"

#ifdef WIN32
#include <windows.h>
#endif

#include "glutils.h"

#include <QDebug>
#include <cmath>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

Sweep::Sweep(int type, const btVector3 &axis, btScalar length, btScalar mass) {
  m_type = static_cast<SweepType>(type);
  m_axis = axis.normalized();
  m_length = length;

  // Build a convex hull from swept profile points
  btConvexHullShape *hull = new btConvexHullShape();

  // Default profile: a circle segment
  m_profile.push_back(btVector3(1.0, 0.0, 0.0));
  m_profile.push_back(btVector3(1.0, 1.0, 0.0));
  m_profile.push_back(btVector3(0.0, 1.0, 0.0));

  if (m_type == SWEEP_ROTATIONAL) {
    // Rotate profile around Y axis, create points
    int segments = 16;
    for (const auto &p : m_profile) {
      for (int i = 0; i <= segments; ++i) {
        btScalar angle = 2.0 * SIMD_PI * i / segments;
        btScalar x = p.x() * btSin(angle);
        btScalar z = p.x() * btCos(angle);
        btScalar y = p.y();
        hull->addPoint(btVector3(x, y, z));
      }
    }
  } else if (m_type == SWEEP_TRANSLATIONAL) {
    // Translate profile along axis
    int segments = 8;
    for (const auto &p : m_profile) {
      for (int i = 0; i <= segments; ++i) {
        btScalar t = btScalar(i) / segments;
        btVector3 pos =
            btVector3(p.x(), p.y(), 0) + m_axis * (m_length * t);
        hull->addPoint(pos);
      }
    }
  } else if (m_type == SWEEP_TAPER) {
    // Taper profile along axis (scale down)
    int segments = 8;
    for (const auto &p : m_profile) {
      for (int i = 0; i <= segments; ++i) {
        btScalar t = btScalar(i) / segments;
        btScalar scale = 1.0 - t;
        btVector3 pos =
            btVector3(p.x() * scale, p.y() * scale, 0) + m_axis * (m_length * t);
        hull->addPoint(pos);
      }
    }
  }

  shape = hull;

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

Sweep::~Sweep() {
  deleteOwnShape(false);
}

void Sweep::addProfilePoint(btScalar x, btScalar y) {
  m_profile.push_back(btVector3(x, y, 0));
  // Rebuild the shape with the new profile
  btConvexHullShape *hull = new btConvexHullShape();

  if (m_type == SWEEP_ROTATIONAL) {
    int segments = 16;
    for (const auto &p : m_profile) {
      for (int i = 0; i <= segments; ++i) {
        btScalar angle = 2.0 * SIMD_PI * i / segments;
        btScalar x = p.x() * btSin(angle);
        btScalar z = p.x() * btCos(angle);
        btScalar y = p.y();
        hull->addPoint(btVector3(x, y, z));
      }
    }
  } else if (m_type == SWEEP_TRANSLATIONAL) {
    int segments = 8;
    for (const auto &p : m_profile) {
      for (int i = 0; i <= segments; ++i) {
        btScalar t = btScalar(i) / segments;
        btVector3 pos =
            btVector3(p.x(), p.y(), 0) + m_axis * (m_length * t);
        hull->addPoint(pos);
      }
    }
  } else if (m_type == SWEEP_TAPER) {
    int segments = 8;
    for (const auto &p : m_profile) {
      for (int i = 0; i <= segments; ++i) {
        btScalar t = btScalar(i) / segments;
        btScalar scale = 1.0 - t;
        btVector3 pos =
            btVector3(p.x() * scale, p.y() * scale, 0) + m_axis * (m_length * t);
        hull->addPoint(pos);
      }
    }
  }

  delete shape;
  shape = hull;

  btVector3 inertia;
  shape->calculateLocalInertia(1.0, inertia);
  body->setMassProps(1.0, inertia);
}

void Sweep::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<Sweep, Object>("Sweep")
                .def(constructor<>(), adopt(result))
                .def(constructor<int>(), adopt(result))
                .def(constructor<int, const btVector3 &, btScalar, btScalar>(),
                     adopt(result))
                .def("addProfilePoint", &Sweep::addProfilePoint)
                .property("type", &Sweep::getSweepType, &Sweep::setSweepType)
                .def(tostring(const_self))
                .def(const_self == const_self)];
}

QString Sweep::toString() const { return QString("Sweep"); }

void Sweep::toPOV(QTextStream *s) const {
  if (body != nullptr && body->getMotionState() != nullptr) {
    btTransform trans;

    body->getMotionState()->getWorldTransform(trans);
    trans.getOpenGLMatrix(matrix);
    povMatrixFromGL(matrix, matrix);
  }

  if (s != nullptr) {
    if (mPreSDL.isNull()) {
      *s << "mesh {\n";
      *s << "  // Swept profile object\n";
      // Export vertices from the convex hull if available
      const btConvexHullShape *hull =
          dynamic_cast<const btConvexHullShape *>(shape);
      if (hull) {
        const btVector3 *pts = hull->getPoints();
        int numPoints = hull->getNumPoints();
        for (int i = 0; i < numPoints; ++i) {
          btVector3 pt = pts[i];
          *s << "  triangle { <" << pt.x() << ", " << pt.y() << ", " << pt.z()
             << ">, <" << (pt.x() + 0.01) << ", " << pt.y() << ", " << pt.z()
             << ">, <" << pt.x() << ", " << (pt.y() + 0.01) << ", " << pt.z()
             << ">\n";
          *s << "    texture { pigment { color rgb <1,1,1> } }\n";
          *s << "  }\n";
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

void Sweep::renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) {
  Q_UNUSED(minaabb)
  Q_UNUSED(maxaabb)

  glApplyColor();

  const btConvexHullShape *hull = dynamic_cast<const btConvexHullShape *>(shape);
  if (!hull) return;

  const btVector3 *pts = hull->getPoints();
  int numPoints = hull->getNumPoints();
  glBegin(GL_TRIANGLES);
  for (int i = 0; i < numPoints - 2; ++i) {
    btVector3 p0 = pts[0];
    btVector3 p1 = pts[i + 1];
    btVector3 p2 = pts[i + 2];
    btVector3 normal = (p1 - p0).cross(p2 - p0);
    normal.normalize();
    glNormal3fv(normal);
    glVertex3fv(p0);
    glNormal3fv(normal);
    glVertex3fv(p1);
    glNormal3fv(normal);
    glVertex3fv(p2);
  }
  glEnd();
}
