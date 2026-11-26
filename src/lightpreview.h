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
 * - point, area (step 3: a point at its middle), spot: positional (w = 1);
 *   parallel: a direction (w = 0), from point_at toward pos.
 * - colour: col * power; a LightSys light, col normalised (LightSys's
 *   Light_Color(): the view can't evaluate the SDL in lightsys, so the hue
 *   comes from col) times lumens, with Lightsys_Brightness taken as 1.
 * - fall-off: POV-Ray's 2 / (1 + (d/fade_distance)^fade_power) is GL's
 *   1 / (c + l d + q d^2) exactly for a power of 1 or 2 (c = 1/2 and l or
 *   q from the distance); other powers mix the two. A LightSys light fades
 *   with power 2 over 2 pi (Light_Fading(), Lightsys_Scene_Scale 1).
 * - spot: GL's cutoff is falloff (at most 90); its exponent gives half the
 *   light midway between radius and falloff, and tightness adds to it.
 *   (GL has no flat full-strength core: an approximation.) LightSys's
 *   cosine spot (radius -89.9, falloff 89.9, tightness 1) comes out as
 *   exactly cos^1, which is what it means.
 * - cylinder: not shown yet (step 4).
 */

#include "objects/light.h"

#include <vector>

namespace LightPreview {

/// What one fixed-function light is given.
struct GL {
  float position[4];
  float diffuse[4];             ///< (specular too)
  float spotDirection[3];
  float spotCutoff = 180;       ///< 180: not a spot
  float spotExponent = 0;
  float constant = 1, linear = 0, quadratic = 0;
};

/// @p l as a fixed-function light. False for a kind the view can't show yet.
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
