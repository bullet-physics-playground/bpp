#include "cam.h"

#include <QGLViewer/camera.h>

#include <QDebug>

#include <boost/shared_ptr.hpp>
#include <memory>
#include <luabind/adopt_policy.hpp>

using namespace std;

std::ostream &operator<<(std::ostream &ostream, const Cam &cam) {
  ostream << cam.toString().toUtf8().data();

  return ostream;
}

bool operator==(const Cam &a, const Cam &b) { return &a == &b; }

// qglviewer::Camera has no operator<</== of its own, and luabind's
// tostring()/comparison policies need one reachable via ADL for every class
// registered with them (see the identity-operator comment in
// lua_bullet.cpp). ADL for a qglviewer::Camera argument only searches the
// qglviewer namespace, so these have to live inside it rather than in the
// global namespace like Cam's own operator<< above.
namespace qglviewer {
inline std::ostream &operator<<(std::ostream &ostream, const Camera &cam) {
  return ostream << "Camera(" << static_cast<const void *>(&cam) << ")";
}
inline bool operator==(const Camera &a, const Camera &b) { return &a == &b; }
}

Cam::Cam(QObject *parent) : Camera() {
  setParent(parent);
  setUseFocalBlur(0);

  standard = true;
  orthoSize = 1.0;

  // Initialize focal point, aperture and lookAt to avoid uninitialized reads
  _focalPoint = btVector3(0, 0, 0);
  _focalAperture = 0.0;
  _lookAt = btVector3(0, 0, 0);
}

Cam::~Cam() {
  // qDebug() << "Cam::~Cam()";
}

QString Cam::toString() const { return QString("Cam"); }

#include <luabind/operator.hpp>

void Cam::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<Camera>("Camera")
                .def(constructor<>())
                .def(tostring(const_self))
                .def(const_self == const_self)];

  module(
      s)[class_<Cam, Camera>("Cam")
             .def(constructor<>())
             .def(constructor<QObject *>())

             .def("setFieldOfView", &Cam::setFieldOfView)
             .def("setHorizontalFieldOfView", &Cam::setHorizontalFieldOfView)

.def("setUpVector",
                 (void(Cam::*)(const btVector3 &, bool)) & Cam::setUpVector)
              .def("getUpVector", &Cam::getUpVector)

             .property("pos", (btVector3(Cam::*)(void)) & Cam::getPosition,
                       (void(Cam::*)(const btVector3 &)) & Cam::setPosition)
.property("look", (btVector3(Cam::*)(void)) & Cam::getLookAt,
                        (void(Cam::*)(const btVector3 &)) & Cam::setLookAt)
              .property("up", (btVector3(Cam::*)(void)) & Cam::getUpVector,
                        (void(Cam::*)(const btVector3 &)) & Cam::setUpVector)

             .property("focal_blur", (int(Cam::*)(void)) & Cam::getUseFocalBlur,
                       (void(Cam::*)(int)) & Cam::setUseFocalBlur)
             .property("focal_point",
                       (btVector3(Cam::*)(void)) & Cam::getFocalPoint,
                       (void(Cam::*)(const btVector3 &)) & Cam::setFocalPoint)
             .property("focal_aperture",
                       (double(Cam::*)(void)) & Cam::getFocalAperture,
                       (void(Cam::*)(double)) & Cam::setFocalAperture)

             .property("pre_sdl", (QString(Cam::*)(void)) & Cam::getPreSDL,
                       (void(Cam::*)(QString)) & Cam::setPreSDL)

             .property("post_sdl", (QString(Cam::*)(void)) & Cam::getPostSDL,
                       (void(Cam::*)(QString)) & Cam::setPostSDL)

             .def(tostring(const_self))
             .def(const_self == const_self)];
}

// see
// http://libqglviewer.com/refManual/classqglviewer_1_1Camera.html#ab442b71a46297223ae12b163653eeb7e
void Cam::setUpVector(const btVector3 &v) {
  if (isfinite(v.length()))
    Camera::setUpVector(Vec(v[0], v[1], v[2]));
}

void Cam::setUpVector(const btVector3 &v, bool noMove) {
  if (isfinite(v.length()))
    Camera::setUpVector(Vec(v[0], v[1], v[2]), noMove);
}

btVector3 Cam::getUpVector() const {
  return btVector3(upVector().x, upVector().y, upVector().z);
}

void Cam::setPosition(const btVector3 &v) {
  if (isfinite(v[0]) && isfinite(v[1]) && isfinite(v[2]))
    Camera::setPosition(Vec(v[0], v[1], v[2]));
}

btVector3 Cam::getPosition() const {
  Vec pos = Camera::position();
  return btVector3(pos[0], pos[1], pos[2]);
}

void Cam::setLookAt(const btVector3 &v) {
  if (isfinite(v[0]) && isfinite(v[1]) && isfinite(v[2])) {
    Camera::lookAt(Vec(v[0], v[1], v[2]));
    _lookAt = v;
  }
}

btVector3 Cam::getLookAt() const { return _lookAt; }

void Cam::setFocalPoint(const btVector3 &v) {
  if (isfinite(v[0]) && isfinite(v[1]) && isfinite(v[2]))
    _focalPoint = v;
}

btVector3 Cam::getFocalPoint() const { return _focalPoint; }

void Cam::setUseFocalBlur(const int ufb) { _useFocalBlur = ufb; }

int Cam::getUseFocalBlur() const { return _useFocalBlur; }

void Cam::setFocalAperture(double aperture) { _focalAperture = aperture; }

double Cam::getFocalAperture() const { return _focalAperture; }

void Cam::setPostSDL(QString post_sdl) { mPostSDL = post_sdl; }

QString Cam::getPostSDL() const { return mPostSDL; }

void Cam::setPreSDL(QString pre_sdl) { mPreSDL = pre_sdl; }

QString Cam::getPreSDL() const { return mPreSDL; }

#if QGLVIEWER_VERSION >= 0x020600
qreal Cam::zNear() const { return Camera::zNear(); }
#else
float Cam::zNear() const { return Camera::zNear(); }
#endif

#if QGLVIEWER_VERSION >= 0x020600
qreal Cam::zFar() const { return Camera::zFar(); }
#else
float Cam::zFar() const { return Camera::zFar(); }
#endif

void Cam::changeOrthoFrustumSize(int delta) {
  double factor = 1.000005;

  if (delta > 0)
    orthoSize *= factor;
  else
    orthoSize /= factor;
}

void Cam::getOrthoWidthHeight(GLdouble &halfWidth, GLdouble &halfHeight) const {
  if (standard) {
    halfHeight = orthoSize;
    halfWidth = aspectRatio() * orthoSize;
  } else
    Camera::getOrthoWidthHeight(halfWidth, halfHeight);
}
