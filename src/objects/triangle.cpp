#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "triangle.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <QDebug>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

Triangle::Triangle(const btVector3 &p0, const btVector3 &p1,
                   const btVector3 &p2, btScalar mass) {
  init(p0, p1, p2, mass);
}

void Triangle::init(const btVector3 &p0, const btVector3 &p1,
                     const btVector3 &p2, btScalar mass) {
  vertices[0] = p0;
  vertices[1] = p1;
  vertices[2] = p2;

  btConvexHullShape *hullShape = new btConvexHullShape();
  hullShape->addPoint(p0);
  hullShape->addPoint(p1);
  hullShape->addPoint(p2);
  shape = hullShape;

  btQuaternion qtn;
  btTransform trans;
  btDefaultMotionState *motionState = nullptr;

  trans.setIdentity();
  qtn.setEuler(0.0, 0.0, 0.0);
  trans.setRotation(qtn);
  trans.setOrigin(btVector3(0, 0, 0));
  motionState = new btDefaultMotionState(trans);

  bool isDynamic = (mass != 0.f);
  btVector3 inertia(0, 0, 0);
  if (isDynamic)
    shape->calculateLocalInertia(mass, inertia);
  btRigidBody::btRigidBodyConstructionInfo bodyCI(mass, motionState, shape,
                                                  inertia);

  body = new btRigidBody(bodyCI);
}

Triangle::~Triangle() {
  delete shape;
  if (body && body->getMotionState())
    delete body->getMotionState();
}

void Triangle::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<Triangle, Object>("Triangle")
                .def(constructor<>(), adopt(result))
                .def(constructor<const btVector3 &, const btVector3 &,
                                 const btVector3 &>(),
                     adopt(result))
                .def(constructor<const btVector3 &, const btVector3 &,
                                 const btVector3 &, btScalar>(),
                     adopt(result))
                .def(tostring(const_self))
                .def(const_self == const_self)];
}

QString Triangle::toString() const { return QString("Triangle"); }

void Triangle::toPOV(QTextStream *s) const {
  if (body != nullptr && body->getMotionState() != nullptr) {
    btTransform trans;

    body->getMotionState()->getWorldTransform(trans);
    trans.getOpenGLMatrix(matrix);
    povMatrixFromGL(matrix, matrix);
  }

  if (s != nullptr) {
    if (mPreSDL.isNull()) {
      *s << "triangle { <" << vertices[0].x() << ", " << vertices[0].y()
         << ", " << -vertices[0].z() << ">, <" << vertices[1].x() << ", "
         << vertices[1].y() << ", " << -vertices[1].z() << ">, <"
         << vertices[2].x() << ", " << vertices[2].y() << ", "
         << -vertices[2].z() << ">" << "\n";
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
       << "          " << matrix[12] << "," << matrix[13] << ","
       << matrix[14] << ">" << "\n";

    if (mPostSDL.isNull()) {
      *s << "}" << "\n"
         << "\n";
    } else {
      *s << mPostSDL << "\n";
    }
  }
}

void Triangle::renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) {
  Q_UNUSED(minaabb)
  Q_UNUSED(maxaabb)

  btVector3 edge1 = vertices[1] - vertices[0];
  btVector3 edge2 = vertices[2] - vertices[0];
  btVector3 normal = edge1.cross(edge2).normalized();

  glApplyColor();

  glBegin(GL_TRIANGLES);
  glNormal3f(normal.x(), normal.y(), normal.z());
  glVertex3f(vertices[0].x(), vertices[0].y(), vertices[0].z());
  glVertex3f(vertices[1].x(), vertices[1].y(), vertices[1].z());
  glVertex3f(vertices[2].x(), vertices[2].y(), vertices[2].z());
  glEnd();

  glBegin(GL_LINES);
  glVertex3f(vertices[0].x(), vertices[0].y(), vertices[0].z());
  glVertex3f(vertices[1].x(), vertices[1].y(), vertices[1].z());
  glVertex3f(vertices[1].x(), vertices[1].y(), vertices[1].z());
  glVertex3f(vertices[2].x(), vertices[2].y(), vertices[2].z());
  glVertex3f(vertices[2].x(), vertices[2].y(), vertices[2].z());
  glVertex3f(vertices[0].x(), vertices[0].y(), vertices[0].z());
  glEnd();
}
