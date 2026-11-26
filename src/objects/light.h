#ifndef LIGHT_H
#define LIGHT_H

/**
 * @file light.h
 * @brief POV-Ray's light sources, for scripts: PointLight, SpotLight,
 * CylinderLight, ParallelLight and AreaLight.
 *
 * A script makes one, sets it up and adds it with @c v:add (taken out with
 * @c v:remove). Viewer keeps the Lua handle of each light added, so a light
 * stays the script's: Lua frees it once the script and the Viewer have both
 * let go. Every light added is written into each exported frame (toPOV()),
 * and the export then tells settings.inc to make none of its own (LIGHTS.md).
 *
 * Positions and directions are in bpp's world; toPOV() negates z, as the
 * export does for everything else. Names follow POV-Ray's keywords.
 */

#include <lua.hpp>

#include <QColor>
#include <QString>

#include <LinearMath/btVector3.h>

/**
 * @brief A light source: what all five kinds share.
 *
 * Any kind can be an area light too (POV-Ray's @c area_light is a
 * modifier): it is one when @c n1 and @c n2 are both above 0. A light with
 * @c lumens above 0 is a LightSys light: its colour is @c lightsys (a
 * LightSys or CIE colour, as SDL), or @c col when that is empty, and it
 * fades as LightSys's lights do.
 */
class Light {
public:
  /// The five kinds of POV-Ray light.
  enum Kind { Point, Spot, Cylinder, Parallel, Area };

  virtual ~Light() {}

  /// Which kind it is.
  Kind kind() const { return _kind; }

  /// The light as POV-Ray SDL: a @c light_source block.
  QString toPOV() const;

  /// The class name a script knows it by ("SpotLight" ...).
  QString toString() const;

  /// The colour as a name, "#rrggbb" (v.col's form).
  QString getCol() const { return col.name(); }
  /// Sets the colour from anything QColor reads ("#ffeedd", "white").
  void setCol(const QString &c) { col = QColor(c); }

  /// Registers Light and the five kinds with a Lua state.
  static void luaBind(lua_State *s);

  btVector3 pos = btVector3(0, 0, 0);       ///< Where it is.
  QColor col = QColor(255, 255, 255);       ///< Its colour.
  double power = 1;                         ///< Multiplies @c col (not a LightSys light's).
  double lumens = 0;                        ///< Above 0: a LightSys light this bright.
  QString lightsys;                         ///< A LightSys light's colour, as SDL.
  double fade_distance = 0;                 ///< Above 0: fades (not for a LightSys light).
  double fade_power = 0;                    ///< How it fades.
  bool shadowless = false;                  ///< Casts no shadows.
  bool media_interaction = true;            ///< Lights media.
  bool media_attenuation = false;           ///< Dimmed by media it crosses.

  // spot, cylinder, parallel
  btVector3 point_at = btVector3(0, 0, -1); ///< Where it points (POV-Ray's <0,0,1>).
  double radius = 0;                        ///< Full strength within (degrees, or units for a cylinder).
  double falloff = 0;                       ///< Gone by.
  double tightness = 0;                     ///< How fast it fades between.

  // area_light (any kind)
  btVector3 axis1 = btVector3(0, 0, 0);     ///< One side of the area.
  btVector3 axis2 = btVector3(0, 0, 0);     ///< The other side.
  int n1 = 0;                               ///< Lights along axis1.
  int n2 = 0;                               ///< Lights along axis2.
  int adaptive = 0;                         ///< Adaptive sampling level (above 0: on).
  bool jitter = false;                      ///< Jittered.
  bool circular = false;                    ///< Round, not rectangular.
  bool orient = false;                      ///< Turned to face what it lights.

protected:
  explicit Light(Kind k) : _kind(k) {}

private:
  Kind _kind;
};

/// Shines all round from a point.
class PointLight : public Light {
public:
  PointLight() : Light(Point) {}
  explicit PointLight(const btVector3 &p) : Light(Point) { pos = p; }
};

/// A cone: full strength within @c radius degrees, gone by @c falloff.
class SpotLight : public Light {
public:
  SpotLight() : Light(Spot) { radius = 30; falloff = 45; }
  SpotLight(const btVector3 &p, const btVector3 &at) : SpotLight() { pos = p; point_at = at; }
};

/// A round beam of parallel light, @c radius and @c falloff in units.
class CylinderLight : public Light {
public:
  CylinderLight() : Light(Cylinder) { radius = 0.75; falloff = 1; }
  CylinderLight(const btVector3 &p, const btVector3 &at) : CylinderLight() { pos = p; point_at = at; }
};

/// Light from one direction everywhere, from @c pos toward @c point_at.
class ParallelLight : public Light {
public:
  ParallelLight() : Light(Parallel) {}
  ParallelLight(const btVector3 &p, const btVector3 &at) : Light(Parallel) { pos = p; point_at = at; }
};

/// A point light spread over an area: soft shadows. Starts as settings.inc's
/// area light: 40 by 40, 4 by 4, adaptive 1, jittered.
class AreaLight : public Light {
public:
  AreaLight() : Light(Area) {
    axis1 = btVector3(40, 0, 0);
    axis2 = btVector3(0, 0, 40);
    n1 = n2 = 4;
    adaptive = 1;
    jitter = true;
  }
  explicit AreaLight(const btVector3 &p) : AreaLight() { pos = p; }
};

#endif // LIGHT_H
