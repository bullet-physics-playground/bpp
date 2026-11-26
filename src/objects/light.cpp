/**
 * @file light.cpp
 * @brief The light sources' POV-Ray SDL and their Lua classes (light.h).
 */

#include "light.h"
#include "object.h"

#include <QTextStream>

#include <luabind/luabind.hpp>
#include <luabind/operator.hpp>

#include "lua_converters.h"

#include <ostream>

namespace {

// A point or direction in POV-Ray's left-handed coordinates.
QString pov(const btVector3 &v) {
  QString s;
  QTextStream(&s) << "<" << v.x() << ", " << v.y() << ", " << -v.z() << ">";
  return s;
}

} // namespace

void Light::setLooksLike(Object *o) {
  looks_like = o;
  if (o != nullptr)
    o->setCastShadow(false);
}

QString Light::toPOV() const {
  return toPOV(looks_like ? looks_like->toPOV() : QString(),
               projected_through ? projected_through->toPOV() : QString());
}

QString Light::toPOV(const QString &looksLike, const QString &through) const {
  QString out;
  QTextStream s(&out);

  s << "light_source {\n";
  s << "  " << pov(pos) << "\n";

  const QString rgb = QString("<%1, %2, %3>")
                          .arg(col.redF()).arg(col.greenF()).arg(col.blueF());
  if (lumens > 0)
    s << "  Light_Color(" << (lightsys.isEmpty() ? rgb : lightsys) << ", " << lumens << ")\n";
  else
    s << "  color rgb " << rgb << " * " << power << "\n";

  switch (_kind) {
  case Spot:
  case Cylinder:
    s << "  " << (_kind == Spot ? "spotlight" : "cylinder") << "\n";
    s << "  point_at " << pov(point_at) << "\n";
    s << "  radius " << radius << " falloff " << falloff << " tightness " << tightness << "\n";
    break;
  case Parallel:
    s << "  parallel\n";
    s << "  point_at " << pov(point_at) << "\n";
    break;
  case Point:
  case Area:
    break;
  }

  if (n1 > 0 && n2 > 0) {
    s << "  area_light " << pov(axis1) << ", " << pov(axis2) << ", " << n1 << ", " << n2 << "\n";
    if (adaptive > 0) s << "  adaptive " << adaptive << "\n";
    if (jitter) s << "  jitter\n";
    if (circular) s << "  circular\n";
    if (orient) s << "  orient\n";
  }

  // (LightSys's own fading; its sun, a parallel light, has none)
  if (lumens > 0) {
    if (_kind != Parallel) s << "  Light_Fading()\n";
  } else if (fade_distance > 0) {
    s << "  fade_distance " << fade_distance << " fade_power " << fade_power << "\n";
  }

  // (POV-Ray moves a looks_like object to the light: it comes back here)
  if (!looksLike.isEmpty())
    s << "  looks_like {\n" << looksLike << "    translate -" << pov(pos) << "\n  }\n";
  if (!through.isEmpty())
    s << "  projected_through {\n" << through << "  }\n";

  if (shadowless) s << "  shadowless\n";
  if (!media_interaction) s << "  media_interaction off\n";
  if (media_attenuation) s << "  media_attenuation on\n";

  s << "}\n";
  s.flush();
  return out;
}

QString Light::toString() const {
  switch (_kind) {
  case Point: return "PointLight";
  case Spot: return "SpotLight";
  case Cylinder: return "CylinderLight";
  case Parallel: return "ParallelLight";
  case Area: return "AreaLight";
  }
  return "Light";
}

std::ostream &operator<<(std::ostream &os, const Light &l) {
  return os << l.toString().toUtf8().data();
}

void Light::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[
    class_<Light>("Light")
      .property("col", &Light::getCol, &Light::setCol)
      .def_readwrite("pos", &Light::pos)
      .def_readwrite("power", &Light::power)
      .def_readwrite("lumens", &Light::lumens)
      .def_readwrite("lightsys", &Light::lightsys)
      .def_readwrite("fade_distance", &Light::fade_distance)
      .def_readwrite("fade_power", &Light::fade_power)
      .def_readwrite("shadowless", &Light::shadowless)
      .def_readwrite("media_interaction", &Light::media_interaction)
      .def_readwrite("media_attenuation", &Light::media_attenuation)
      .def_readwrite("axis1", &Light::axis1)
      .def_readwrite("axis2", &Light::axis2)
      .def_readwrite("n1", &Light::n1)
      .def_readwrite("n2", &Light::n2)
      .def_readwrite("adaptive", &Light::adaptive)
      .def_readwrite("jitter", &Light::jitter)
      .def_readwrite("circular", &Light::circular)
      .def_readwrite("orient", &Light::orient)
      .property("looks_like", &Light::getLooksLike, &Light::setLooksLike)
      .property("projected_through", &Light::getProjectedThrough, &Light::setProjectedThrough)
      .def("toPOV", (QString(Light::*)() const) & Light::toPOV)
      .def(tostring(const_self)),

    class_<PointLight, Light>("PointLight")
      .def(constructor<>())
      .def(constructor<const btVector3 &>()),

    class_<SpotLight, Light>("SpotLight")
      .def(constructor<>())
      .def(constructor<const btVector3 &, const btVector3 &>())
      .def_readwrite("point_at", &Light::point_at)
      .def_readwrite("radius", &Light::radius)
      .def_readwrite("falloff", &Light::falloff)
      .def_readwrite("tightness", &Light::tightness),

    class_<CylinderLight, Light>("CylinderLight")
      .def(constructor<>())
      .def(constructor<const btVector3 &, const btVector3 &>())
      .def_readwrite("point_at", &Light::point_at)
      .def_readwrite("radius", &Light::radius)
      .def_readwrite("falloff", &Light::falloff)
      .def_readwrite("tightness", &Light::tightness),

    class_<ParallelLight, Light>("ParallelLight")
      .def(constructor<>())
      .def(constructor<const btVector3 &, const btVector3 &>())
      .def_readwrite("point_at", &Light::point_at),

    class_<AreaLight, Light>("AreaLight")
      .def(constructor<>())
      .def(constructor<const btVector3 &>())
  ];
}
