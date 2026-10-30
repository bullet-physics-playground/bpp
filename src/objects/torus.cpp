/**
 * @file torus.cpp
 * @brief Implementation of the torus primitive.
 */

#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "torus.h"

#ifdef WIN32
#include <windows.h>
#endif

#include "glutils.h"

#include <QDebug>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

Torus::Torus(btScalar innerRadius, btScalar outerRadius, btScalar mass) {
  init(innerRadius, outerRadius, mass);
}

Torus::Torus(const btVector3 &dim, btScalar mass) {
  init(dim.getX(), dim.getY(), mass);
}

void Torus::init(btScalar innerR, btScalar outerR, btScalar mass) {
  innerRadius = innerR;
  outerRadius = outerR;

  // Build a convex hull approximation of a torus for collision
  btAlignedObjectArray<btVector3> points;
  const int majorSteps = 16;
  const int minorSteps = 8;
  for (int i = 0; i < majorSteps; i++) {
    double u = i * 2.0 * M_PI / majorSteps;
    float cu = cos(u), su = sin(u);
    for (int j = 0; j < minorSteps; j++) {
      double v = j * 2.0 * M_PI / minorSteps;
      float cv = cos(v), sv = sin(v);

      double x = (outerR + innerR * cv) * cu;
      double y = (outerR + innerR * cv) * su;
      double z = innerR * sv;

      points.push_back(btVector3(x, y, z));
    }
  }

  shape = new btConvexHullShape(points[0], points.size(), sizeof(btVector3));

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

Torus::~Torus() {
  deleteOwnShape(true);
}

void Torus::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<Torus, Object>("Torus")
                 .def(constructor<>(), adopt(result))
                 .def(constructor<btScalar, btScalar>(), adopt(result))
                 .def(constructor<btScalar, btScalar, btScalar>(), adopt(result))
                 .def(constructor<const btVector3 &>(), adopt(result))
                 .def(constructor<const btVector3 &, btScalar>(), adopt(result))
                 .def(tostring(const_self))
                 .def(const_self == const_self)];
}

QString Torus::toString() const { return QString("Torus"); }

void Torus::povPigment(QTextStream *s) const {
  if (s == nullptr || getTexture().isEmpty()) {
    Object::povPigment(s);
    return;
  }

  // For torus, use a simple planar mapping
  *s << "  texture {\n";
  *s << "    pigment {\n";
  *s << "      image_map {\n";
  *s << "        \"" << getTexture().toStdString().c_str() << "\"\n";
  *s << "        map_type 0\n";  // planar
  *s << "      }\n";
  *s << "    }\n";
  *s << "  }\n";
}

void Torus::toPOV(QTextStream *s) const {
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
      // POV-Ray torus: torus { major_radius, minor_radius }
      *s << "torus { " << outerRadius << ", " << innerRadius << "\n";
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

void Torus::renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) {
  Q_UNUSED(minaabb)
  Q_UNUSED(maxaabb)

  // POV-Ray torus lies in XZ plane (hole along Y axis). solidTorus draws in XY
  // plane (hole along Z axis), so rotate -90 deg around X to match.
  glPushMatrix();
  glRotatef(-90.0f, 1.0f, 0.0f, 0.0f);
  glApplyColor();
  solidTorus(innerRadius, outerRadius, 32, 16);
  glPopMatrix();
}