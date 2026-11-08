#include "culling.h"

#include <QGLViewer/camera.h>

#include <qopengl.h>

#include <typeinfo>
#include <vector>

#include "objects/object.h"
#include "objects/softbody.h"
#include "shadowmap.h"

namespace Culling {

// Culling. The camera's view is six planes (left, right, bottom, top, near,
// far), read off its projection and modelview matrices; a box is out of view
// when it lies wholly on the outer side of any one of them. An object's box
// is its collision shape's, where and as the object is drawn, with a tenth of
// its size to spare.
//
// For the shadow map: a shadow that falls into the view only shows where it
// lands on something drawn there, so an object out of view still goes into
// the map if its box, swept the way the light shines (one direction for the
// whole scene, as the shadow map takes it) until it is past everything in
// view, meets the view.
void cull(const QSet<Object *> &objects, const qglviewer::Camera *camera,
          bool shadows, const btVector4 &light0, const ShadowMap *shadowMap) {
  GLdouble proj[16], mv[16], m[16];
  glGetDoublev(GL_PROJECTION_MATRIX, proj);
  glGetDoublev(GL_MODELVIEW_MATRIX, mv);
  for (int c = 0; c < 4; ++c)            // m = proj * mv (column-major)
    for (int r = 0; r < 4; ++r) {
      double sum = 0;
      for (int k = 0; k < 4; ++k)
        sum += proj[k * 4 + r] * mv[c * 4 + k];
      m[c * 4 + r] = sum;
    }
  double planes[6][4];
  for (int p = 0; p < 6; ++p) {
    const int row = p / 2;
    const double sign = (p % 2 == 0) ? 1.0 : -1.0;
    for (int c = 0; c < 4; ++c)
      planes[p][c] = m[c * 4 + 3] + sign * m[c * 4 + row];
  }
  auto outside = [&](const btVector3 &lo, const btVector3 &hi) {
    for (int p = 0; p < 6; ++p) {
      const double *q = planes[p];
      const double x = q[0] >= 0 ? hi.x() : lo.x();
      const double y = q[1] >= 0 ? hi.y() : lo.y();
      const double z = q[2] >= 0 ? hi.z() : lo.z();
      if (q[0] * x + q[1] * y + q[2] * z + q[3] < 0)
        return true;
    }
    return false;
  };

  const double radius = camera->sceneRadius();
  const btScalar spare = btScalar(1e-3 * radius);

  // 1: the screen. (Everything in view, or that can't be boxed, makes up
  // what a shadow can land on.)
  struct Box { Object *o; btVector3 lo, hi; };
  std::vector<Box> offScreen;
  bool anyInView = false, unboxedInView = false;
  btVector3 viewLo(BT_LARGE_FLOAT, BT_LARGE_FLOAT, BT_LARGE_FLOAT), viewHi = -viewLo;
  foreach (Object *o, objects) {
    o->drawOnScreen = true;
    o->drawInShadow = true;
    btRigidBody *b = o->body;
    // (always drawn: no shape to box; drawn by a script, or by a plain
    // Object, which draws a ball whatever its shape; a soft body)
    if (b == nullptr || b->getCollisionShape() == nullptr || o->hasRenderFunction() ||
        typeid(*o) == typeid(Object) || dynamic_cast<SoftBody *>(o) != nullptr) {
      unboxedInView = true;
      continue;
    }
    // (where it is drawn: a body without a motion state is drawn as it
    // stands, in world coordinates)
    btTransform t;
    if (b->getMotionState() != nullptr)
      b->getMotionState()->getWorldTransform(t);
    else
      t.setIdentity();
    if (o->placed)
      t = o->place * t;
    btVector3 lo, hi;
    b->getCollisionShape()->getAabb(t, lo, hi);
    const btVector3 shift = t.getBasis() * o->drawnOffset();
    lo += shift;
    hi += shift;
    const btVector3 pad = (hi - lo) * btScalar(0.1) + btVector3(spare, spare, spare);
    lo -= pad;
    hi += pad;
    o->drawOnScreen = !outside(lo, hi);
    if (o->drawOnScreen) {
      anyInView = true;
      viewLo.setMin(lo);
      viewHi.setMax(hi);
    } else {
      offScreen.push_back(Box{o, lo, hi});
    }
  }

  // 2: the shadow map
  if (!shadows)
    return;
  const qglviewer::Vec sc = camera->sceneCenter();
  btVector3 toLight(light0.x(), light0.y(), light0.z());
  if (light0.w() != 0.0)
    toLight = toLight / light0.w() - btVector3(sc.x, sc.y, sc.z);
  const bool lit = toLight.length2() > 0;
  const btVector3 d = lit ? -toLight.normalized() : btVector3(0, -1, 0);
  // (a soft shadow's blur reaches a few texels of the map further)
  const btScalar blur = btScalar(2.0 * 1.02 * radius / qMax(1, shadowMap->mapSize()) *
                                 (shadowMap->softness() + 1.0));
  for (Box &x : offScreen) {
    x.o->drawInShadow = false;
    if (!lit || !(anyInView || unboxedInView))
      continue;
    // (how far until the whole box is past everything in view, along d;
    // with something in view that can't be boxed, all the way)
    btScalar reach = btScalar(BT_LARGE_FLOAT);
    if (!unboxedInView) {
      for (int k = 0; k < 3; ++k) {
        if (d[k] < 0)
          reach = btMin(reach, (viewLo[k] - x.hi[k]) / d[k]);
        else if (d[k] > 0)
          reach = btMin(reach, (viewHi[k] - x.lo[k]) / d[k]);
      }
      reach = btMax(reach, btScalar(0));
    }
    btVector3 lo = x.lo - btVector3(blur, blur, blur), hi = x.hi + btVector3(blur, blur, blur);
    btVector3 slo = lo, shi = hi;
    slo.setMin(lo + d * reach);
    shi.setMax(hi + d * reach);
    x.o->drawInShadow = !outside(slo, shi);
  }
}

} // namespace Culling
