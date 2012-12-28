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

Cam::Cam(QObject *parent) : Camera() {
    setParent(parent);
    // qDebug() << "Cam::Cam()";
//    setUpVector(Vec(0,0,-1), false);
//    setViewDirection(Vec(0,1,0));
}

Cam::~Cam() {
    // qDebug() << "Cam::~Cam()";
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
     class_<Camera, boost::shared_ptr<Camera> >("Camera")
          .def(constructor<>())
     ];

  module(s)
    [
     class_<Cam,Camera>("Cam")
          .def(constructor<>())
          .def(constructor<QObject *>())

     .def("setFieldOfView", &Cam::setFieldOfView)
     .def("setHorizontalFieldOfView", &Cam::setHorizontalFieldOfView)

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

  _lookAt = v;
}

btVector3 Cam::getLookAt() const {
  return _lookAt;
}
