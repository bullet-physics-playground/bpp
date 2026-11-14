#ifndef CULLING_H
#define CULLING_H

#include "orderedset.h"

#include <LinearMath/btVector3.h>

class Object;
class ShadowMap;
namespace qglviewer {
class Camera;
}

/**
 * @brief Culling (v.culling): which objects a frame can skip, for the
 * screen and for the shadow map.
 */
namespace Culling {

/**
 * @brief Sets each object's drawOnScreen and drawInShadow for this frame.
 *
 * An object is drawn for the screen when its box meets the camera's view;
 * into the shadow map when it is in view, or its box, swept the way the
 * light shines until past everything in view, meets the view. An object
 * that can't be boxed is always drawn.
 *
 * Must be called with the camera's own projection and modelview matrices
 * loaded.
 *
 * @param objects   The scene's objects.
 * @param camera    The camera (its scene's centre and radius).
 * @param shadows   Shadows are on: decide drawInShadow too (otherwise every
 *                  object's is left true).
 * @param light0    The main light (GL_POSITION).
 * @param shadowMap The shadow map (its size and softness); used only with
 *                  @p shadows.
 */
void cull(const ObjectSet &objects, const qglviewer::Camera *camera,
          bool shadows, const btVector4 &light0, const ShadowMap *shadowMap);

} // namespace Culling

#endif // CULLING_H
