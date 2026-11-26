/**
 * @file lightpreview.cpp
 * @brief The script's lights as fixed-function OpenGL lights (lightpreview.h).
 */

#include "lightpreview.h"

#include <algorithm>
#include <cmath>

namespace LightPreview {

namespace {

const double PI = 3.14159265358979323846;

// The light's colour, before fall-off.
btVector3 colourOf(const Light &l) {
  btVector3 c(l.col.redF(), l.col.greenF(), l.col.blueF());
  if (l.lumens > 0) {
    const btScalar n = c.length();
    return n > 0 ? c / n * btScalar(l.lumens) : btVector3(0, 0, 0);
  }
  return c * btScalar(l.power);
}

// POV-Ray's fade as GL's constant, linear and quadratic attenuation.
void fade(const Light &l, float &c, float &lin, float &q) {
  c = 1, lin = 0, q = 0;
  double d = l.fade_distance, p = l.fade_power;
  if (l.lumens > 0) {                   // (Light_Fading())
    d = 2 * PI;
    p = 2;
  }
  if (l.kind() == Light::Parallel || d <= 0)
    return;
  const double w = std::min(1.0, std::max(0.0, p - 1));   // 0 at power 1, 1 at 2
  c = 0.5f;
  lin = float(0.5 * (1 - w) / d);
  q = float(0.5 * w / (d * d));
}

} // namespace

bool toGL(const Light &l, GL &out) {
  if (l.kind() == Light::Cylinder)
    return false;

  out = GL();
  if (l.kind() == Light::Parallel) {
    const btVector3 dir = l.pos - l.point_at;
    out.position[0] = dir.x(), out.position[1] = dir.y(), out.position[2] = dir.z();
    out.position[3] = 0;
  } else {
    out.position[0] = l.pos.x(), out.position[1] = l.pos.y(), out.position[2] = l.pos.z();
    out.position[3] = 1;
  }

  const btVector3 c = colourOf(l);
  out.diffuse[0] = c.x(), out.diffuse[1] = c.y(), out.diffuse[2] = c.z();
  out.diffuse[3] = 1;

  fade(l, out.constant, out.linear, out.quadratic);

  if (l.kind() == Light::Spot) {
    btVector3 dir = l.point_at - l.pos;
    if (dir.length2() > 0)
      dir.normalize();
    out.spotDirection[0] = dir.x(), out.spotDirection[1] = dir.y(), out.spotDirection[2] = dir.z();
    out.spotCutoff = float(std::min(90.0, std::max(0.0, l.falloff)));
    // half the light midway between radius and falloff: cos(mid)^e = 1/2
    const double mid = (l.radius + l.falloff) / 2 * PI / 180;
    const double cm = std::cos(mid);
    double e = l.tightness;
    if (cm < 0.9999 && cm > 0)
      e += std::log(0.5) / std::log(cm);
    out.spotExponent = float(std::min(128.0, std::max(0.0, e)));
  }
  return true;
}

double strengthAt(const Light &l, const btVector3 &p) {
  const btVector3 c = colourOf(l);
  const double lum = 0.2126 * c.x() + 0.7152 * c.y() + 0.0722 * c.z();
  float k, lin, q;
  fade(l, k, lin, q);
  const double d = (l.kind() == Light::Parallel) ? 0 : (l.pos - p).length();
  return lum / (k + lin * d + q * d * d);
}

std::vector<const Light *> pick(const std::vector<const Light *> &lights,
                                const btVector3 &eye, int max, int &shadow) {
  std::vector<std::pair<double, const Light *>> s;
  GL unused;
  for (const Light *l : lights)
    if (toGL(*l, unused))
      s.emplace_back(strengthAt(*l, eye), l);
  // (stable: equal lights keep the order they were added in, so the choice
  // doesn't flicker between them)
  std::stable_sort(s.begin(), s.end(),
                   [](const std::pair<double, const Light *> &a,
                      const std::pair<double, const Light *> &b) { return a.first > b.first; });
  std::vector<const Light *> out;
  shadow = -1;
  for (const auto &e : s) {
    if ((int)out.size() >= max)
      break;
    if (shadow < 0 && !e.second->shadowless)
      shadow = (int)out.size();
    out.push_back(e.second);
  }
  return out;
}

} // namespace LightPreview
