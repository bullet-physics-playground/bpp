#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "cone.h"

#ifdef WIN32
#include <windows.h>
#endif

#include "glutils.h"

#include <QDebug>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

void Cone::init(btScalar pradius, btScalar pheight, btScalar mass) {
  radius = pradius;
  height = pheight;

  shape = new btConeShapeZ(radius, height);

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

Cone::Cone(btScalar pradius, btScalar pheight, btScalar mass) {
  init(pradius, pheight, mass);
}

Cone::~Cone() {
  delete shape;
  if (body && body->getMotionState())
    delete body->getMotionState();
}

void Cone::setRadius(btScalar pradius) {
  radius = pradius;
  delete shape;
  shape = new btConeShapeZ(radius, height);
}

btScalar Cone::getRadius() const { return radius; }

void Cone::setHeight(btScalar pheight) {
  height = pheight;
  delete shape;
  shape = new btConeShapeZ(radius, height);
}

btScalar Cone::getHeight() const { return height; }

void Cone::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<Cone, Object>("Cone")
                .def(constructor<>(), adopt(result))
                .def(constructor<btScalar>(), adopt(result))
                .def(constructor<btScalar, btScalar>(), adopt(result))
                .def(constructor<btScalar, btScalar, btScalar>(), adopt(result))
                .property("radius", &Cone::getRadius, &Cone::setRadius)
                .property("height", &Cone::getHeight, &Cone::setHeight)
                .def(tostring(const_self))];
}

QString Cone::toString() const { return QString("Cone"); }

void Cone::toPOV(QTextStream *s) const {
  if (body != nullptr && body->getMotionState() != nullptr) {
    btTransform trans;

    body->getMotionState()->getWorldTransform(trans);
    trans.getOpenGLMatrix(matrix);
    povMatrixFromGL(matrix, matrix);
  }

  if (s != nullptr) {
    if (mPreSDL.isNull()) {
      *s << "cone { <0, 0, " << height / 2.0 << ">, " << radius << ", <0, 0, " << -height / 2.0 << ">, 0"
         << "\n";
    } else {
      *s << mPreSDL << "\n";
    }

    if (!mSDL.isNull()) {
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

    if (mPostSDL.isNull()) {
      *s << "}" << "\n"
         << "\n";
    } else {
      *s << mPostSDL << "\n";
    }
  }
}

void Cone::renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) {
  Q_UNUSED(minaabb)
  Q_UNUSED(maxaabb)

  glTranslated(0, 0, -height * .5);
  glScalef(radius, radius, height);
  glColor3ubv(color);
  solidCone(1, 1, 16, 16);
}
