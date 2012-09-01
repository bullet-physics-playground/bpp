#include "cam.h"

#include <QGLViewer/camera.h>

#include <QDebug>

#include <boost/shared_ptr.hpp>
#include <luabind/adopt_policy.hpp>

using namespace std;

std::ostream& operator<<(std::ostream& ostream, const Cam& cam) {
  ostream << cam.toString().toAscii().data() << "[ pos: " << "]";

  return ostream;
}

Cam::Cam() : qglviewer::Camera() {
}

QString Cam::toString() const {
  return QString("Cam");
}

#include <luabind/operator.hpp>

void Cam::luaBind(lua_State *s) {
  using namespace luabind;

  open(s);

  module(s)
    [
     class_<Cam>("Cam")
     .def(constructor<>(), adopt(result))

     .property("pos",
               (btVector3(Cam::*)(void))&Cam::getPosition,
               (void(Cam::*)(const btVector3&))&Cam::setPosition)
     .def(tostring(const_self))
     ];
}

void Cam::setPosition(const btVector3& v) {
  setPosition(v[0], v[1], v[2]);
}

void Cam::setPosition(btScalar x, btScalar y, btScalar z) {
}

btVector3 Cam::getPosition() const {
  return btVector3(0,0,0);
}
