#ifndef GIMPACTPLANE_H
#define GIMPACTPLANE_H

#include <BulletCollision/Gimpact/btGImpactCollisionAlgorithm.h>

class btGImpactMeshShapePart;
class btStaticPlaneShape;

/**
 * @brief Bullet's GImpact collision algorithm, with contacts against a
 * plane also when a mesh is entirely behind it.
 *
 * Bullet's GImpact-plane test returns without contacts unless the mesh's
 * bounding box straddles the plane. A thin mesh (a Patch, a flat Mesh)
 * falling fast can pass from in front of a plane to behind it in one step,
 * and then falls through. Here a mesh is skipped only when it is entirely
 * in front of the plane; otherwise every vertex behind the plane gives a
 * contact, as in Bullet's own test. Other shape pairs are left to Bullet.
 */
class GImpactPlaneAlgorithm : public btGImpactCollisionAlgorithm {
public:
  GImpactPlaneAlgorithm(const btCollisionAlgorithmConstructionInfo &ci,
                        const btCollisionObjectWrapper *body0Wrap,
                        const btCollisionObjectWrapper *body1Wrap)
      : btGImpactCollisionAlgorithm(ci, body0Wrap, body1Wrap) {}

  void processCollision(const btCollisionObjectWrapper *body0Wrap,
                        const btCollisionObjectWrapper *body1Wrap,
                        const btDispatcherInfo &dispatchInfo,
                        btManifoldResult *resultOut) override;

  struct CreateFunc : public btCollisionAlgorithmCreateFunc {
    btCollisionAlgorithm *
    CreateCollisionAlgorithm(btCollisionAlgorithmConstructionInfo &ci,
                             const btCollisionObjectWrapper *body0Wrap,
                             const btCollisionObjectWrapper *body1Wrap) override {
      void *mem = ci.m_dispatcher1->allocateCollisionAlgorithm(
          sizeof(GImpactPlaneAlgorithm));
      return new (mem) GImpactPlaneAlgorithm(ci, body0Wrap, body1Wrap);
    }
  };

  /** @brief Registers Bullet's GImpact algorithm, and this one for GImpact
   * shapes against planes. Use in place of
   * btGImpactCollisionAlgorithm::registerAlgorithm(). */
  static void registerAlgorithm(btCollisionDispatcher *dispatcher);

private:
  void meshPartVsPlane(const btCollisionObjectWrapper *meshWrap,
                       const btCollisionObjectWrapper *planeWrap,
                       const btGImpactMeshShapePart *part,
                       const btStaticPlaneShape *plane, bool swapped);
};

#endif // GIMPACTPLANE_H
