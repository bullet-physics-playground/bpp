/**
 * @file referenceobject.cpp
 * @brief Implementation of the reference object primitive.
 */

#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "referenceobject.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <QDebug>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

ReferenceObject::ReferenceObject(const QString &targetName, Object *target) {
  m_targetName = targetName;
  m_target = target;
}

ReferenceObject::~ReferenceObject() {
  // No shape to delete; m_target is non-owning
}

void ReferenceObject::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<ReferenceObject, Object>("ReferenceObject")
                .def(constructor<>(), adopt(result))
                .def(constructor<const QString &>(), adopt(result))
                .def(constructor<const QString &, Object *>(), adopt(result))
                .property("targetName", &ReferenceObject::getTargetName,
                          &ReferenceObject::setTargetName)
                .property("target", &ReferenceObject::getTarget,
                          &ReferenceObject::setTarget)
                .def(tostring(const_self))
                .def(const_self == const_self)];
}

QString ReferenceObject::toString() const { return QString("ReferenceObject"); }

void ReferenceObject::toPOV(QTextStream *s) const {
  if (s != nullptr) {
    if (mPreSDL.isNull()) {
      if (!m_targetName.isEmpty()) {
        *s << "object { " << m_targetName << "\n";
      } else {
        *s << "object { <unnamed> }\n";
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

void ReferenceObject::renderInLocalFrame(btVector3 &minaabb,
                                         btVector3 &maxaabb) {
  Q_UNUSED(minaabb)
  Q_UNUSED(maxaabb)
  // Reference has no geometry of its own
}
