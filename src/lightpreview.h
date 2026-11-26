#ifndef LIGHTPREVIEW_H
#define LIGHTPREVIEW_H

/**
 * @file lightpreview.h
 * @brief How the view shows the script's lights (light.h): each as one of
 * OpenGL's fixed-function lights, the 8 that light the camera most.
 *
 * Pure arithmetic, no GL calls: Viewer::draw() hands the result to
 * glLightfv(), and the shadow map's shader reads the same GL state, so the
 * view looks the same with shadows on and off (LIGHTS.md, step 3).
 *
 * - point, area (a point at its middle; soft shadows are POV-Ray's), spot,
 *   cylinder: positional (w = 1); parallel: a direction (w = 0), from
 *   point_at toward pos.
 * - colour: col * power; a LightSys light, col normalised (LightSys's
 *   Light_Color(): the view can't evaluate the SDL in lightsys, so the hue
 *   comes from col) times lumens, with Lightsys_Brightness taken as 1.
 * - fall-off: POV-Ray's 2 / (1 + (d/fade_distance)^fade_power) is GL's
 *   1 / (c + l d + q d^2) exactly for a power of 1 or 2 (c = 1/2 and l or
 *   q from the distance); other powers mix the two. A LightSys light fades
 *   with power 2 over 2 pi (Light_Fading(), Lightsys_Scene_Scale 1).
 * - spot and cylinder: the shader works POV-Ray's own formulas (its
 *   Attenuate_Light(): cos^tightness, then a cubic from falloff to radius,
 *   by angle for a spot, by distance from the beam's axis for a cylinder,
 *   whose light is parallel along it), from GL::shape. The fixed-function
 *   state is an approximation, for a GL with no shaders: GL's cutoff is
 *   falloff (at most 90) and its exponent gives half the light midway; a
 *   cylinder is a spot just wide enough at point_at.
 * - shadowless: no highlights; and, as in POV-Ray, where shadowless is
 *   written last (bpp's export does) it replaces spotlight or cylinder: a
 *   shadowless spot is a point light, a shadowless cylinder a parallel one.
 */

#include "objects/light.h"

#include <vector>

namespace LightPreview {

/// What one fixed-function light is given.
struct GL {
  float position[4];
  float diffuse[4];
  float specular[4];            ///< (none for a shadowless light)
  /// For the shader: kind (0: GL's own; 1: POV-Ray's spot, then the
  /// cosines of radius and falloff; 2: its cylinder, then radius and
  /// falloff), and tightness.
  float shape[4] = {0, 0, 0, 0};
  float spotDirection[3];
  float spotCutoff = 180;       ///< 180: not a spot
  float spotExponent = 0;
  float constant = 1, linear = 0, quadratic = 0;
};

/// The kind @p l renders as: its own, but a shadowless spot is a point
/// light and a shadowless cylinder a parallel one (POV-Ray: see above).
Light::Kind shownKind(const Light &l);

/// Where the shadow map looks from for @p l, when it casts from where it
/// is (point, area, spot: a perspective map; false for cylinder and
/// parallel light, which shadow along one direction as v.glLight0 does).
/// A spot looks along its cone; a light outside the scene's bounding
/// sphere at its centre, just wide enough; one inside it (a lamp in a
/// room) toward the centre, 150 degrees wide -- one map can't see every
/// way, so what is behind such a lamp casts no shadow.
struct ShadowView {
  btVector3 eye, look;
  double fov = 90, nearZ = 1, farZ = 2;
};
bool shadowView(const Light &l, const btVector3 &center, double radius, ShadowView &out);

/// @p l as a fixed-function light (and the shape the shader works from).
bool toGL(const Light &l, GL &out);

/// How brightly @p l lights the point @p p: its colour's luminance after
/// fall-off (the spot's cone left out: what it may light near the camera
/// counts too).
double strengthAt(const Light &l, const btVector3 &p);

/// The lights the view shows: at most @p max, those lighting @p eye most,
/// strongest first. @p shadow is the index (into the result) of the
/// strongest that isn't shadowless, or -1 when every one is.
std::vector<const Light *> pick(const std::vector<const Light *> &lights,
                                const btVector3 &eye, int max, int &shadow);

} // namespace LightPreview

#endif // LIGHTPREVIEW_H
