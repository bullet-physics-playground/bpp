#include "gimpactplane.h"

#include <BulletCollision/CollisionDispatch/btCollisionDispatcher.h>
#include <BulletCollision/CollisionShapes/btStaticPlaneShape.h>
#include <BulletCollision/Gimpact/btBoxCollision.h>
#include <BulletCollision/Gimpact/btGImpactShape.h>

void GImpactPlaneAlgorithm::registerAlgorithm(btCollisionDispatcher *dispatcher) {
  static CreateFunc createFunc;
  btGImpactCollisionAlgorithm::registerAlgorithm(dispatcher);
  dispatcher->registerCollisionCreateFunc(GIMPACT_SHAPE_PROXYTYPE,
                                          STATIC_PLANE_PROXYTYPE, &createFunc);
  dispatcher->registerCollisionCreateFunc(STATIC_PLANE_PROXYTYPE,
                                          GIMPACT_SHAPE_PROXYTYPE, &createFunc);
}

void GImpactPlaneAlgorithm::processCollision(const btCollisionObjectWrapper *body0Wrap,
                                             const btCollisionObjectWrapper *body1Wrap,
                                             const btDispatcherInfo &dispatchInfo,
                                             btManifoldResult *resultOut) {
  // Only GImpact meshes against a plane are handled here.
  const bool swapped = body0Wrap->getCollisionShape()->getShapeType() != GIMPACT_SHAPE_PROXYTYPE;
  const btCollisionObjectWrapper *meshWrap = swapped ? body1Wrap : body0Wrap;
  const btCollisionObjectWrapper *planeWrap = swapped ? body0Wrap : body1Wrap;
  const btGImpactShapeInterface *gimpact =
      static_cast<const btGImpactShapeInterface *>(meshWrap->getCollisionShape());
  const eGIMPACT_SHAPE_TYPE type = gimpact->getGImpactShapeType();
  if (planeWrap->getCollisionShape()->getShapeType() != STATIC_PLANE_PROXYTYPE ||
      (type != CONST_GIMPACT_TRIMESH_SHAPE && type != CONST_GIMPACT_TRIMESH_SHAPE_PART)) {
    btGImpactCollisionAlgorithm::processCollision(body0Wrap, body1Wrap, dispatchInfo, resultOut);
    return;
  }

  // As btGImpactCollisionAlgorithm::processCollision() starts.
  clearCache();
  m_resultOut = resultOut;
  m_dispatchInfo = &dispatchInfo;

  const btStaticPlaneShape *plane =
      static_cast<const btStaticPlaneShape *>(planeWrap->getCollisionShape());
  int &partIndex = swapped ? m_part1 : m_part0;
  if (type == CONST_GIMPACT_TRIMESH_SHAPE) {
    const btGImpactMeshShape *mesh = static_cast<const btGImpactMeshShape *>(gimpact);
    for (partIndex = mesh->getMeshPartCount() - 1; partIndex >= 0; --partIndex)
      meshPartVsPlane(meshWrap, planeWrap, mesh->getMeshPart(partIndex), plane, swapped);
  } else {
    meshPartVsPlane(meshWrap, planeWrap,
                    static_cast<const btGImpactMeshShapePart *>(gimpact), plane, swapped);
  }

  if (getLastManifold())
    m_resultOut->refreshContactPoints();
}

void GImpactPlaneAlgorithm::meshPartVsPlane(const btCollisionObjectWrapper *meshWrap,
                                            const btCollisionObjectWrapper *planeWrap,
                                            const btGImpactMeshShapePart *part,
                                            const btStaticPlaneShape *plane, bool swapped) {
  const btTransform &meshTrans = meshWrap->getWorldTransform();
  const btTransform &planeTrans = planeWrap->getWorldTransform();

  // The plane in world space: normal . x = constant
  const btVector3 normal = planeTrans.getBasis() * plane->getPlaneNormal();
  const btScalar constant = plane->getPlaneConstant() + normal.dot(planeTrans.getOrigin());
  const btScalar margin = part->getMargin() + plane->getMargin();

  // Bullet's test, with the box grown by the plane's margin; but the mesh
  // is skipped only when entirely in front of the plane (Bullet also skips
  // it when entirely behind).
  btAABB box;
  part->getAabb(meshTrans, box.m_min, box.m_max);
  box.increment_margin(plane->getMargin());
  const btVector4 equation(normal.x(), normal.y(), normal.z(), constant);
  if (box.plane_classify(equation) == BT_CONST_FRONT_PLANE)
    return;

  // As Bullet's test: a contact for each vertex closer than the margins.
  part->lockChildShapes();
  btVector3 vertex;
  for (int i = part->getVertexCount() - 1; i >= 0; --i) {
    part->getVertex(i, vertex);
    vertex = meshTrans(vertex);
    const btScalar distance = normal.dot(vertex) - constant - margin;
    if (distance < 0) {
      if (swapped)
        addContactPoint(planeWrap, meshWrap, vertex, -normal, distance);
      else
        addContactPoint(meshWrap, planeWrap, vertex, normal, distance);
    }
  }
  part->unlockChildShapes();
}
