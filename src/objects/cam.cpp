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

Cam::Cam() {
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
	 class_<Camera>("Camera")
     .def(constructor<>(), adopt(result))
	 ];

  module(s)
    [
     class_<Cam,Camera>("Cam")
     .def(constructor<>(), adopt(result))

     .property("pos",
               (btVector3(Cam::*)(void))&Cam::getPosition,
               (void(Cam::*)(const btVector3&))&Cam::setPosition)
     .property("look",
               (btVector3(Cam::*)(void))&Cam::getLookAt,
               (void(Cam::*)(const btVector3&))&Cam::setLookAt)
     .def(tostring(const_self))
     ];
}

void Cam::setPosition(const btVector3& v) {
  Camera::setPosition(Vec(v[0], v[1], v[2]));
}

btVector3 Cam::getPosition() const {
  Vec pos = Camera::position();
  return btVector3(pos[0], pos[1], pos[2]);
}

void Cam::setLookAt(const btVector3& v) {
  Camera::lookAt(Vec(v[0], v[1], v[2]));
}

btVector3 Cam::getLookAt() const {
  return btVector3(0.0,0.0,0.0); // FIXME
}
