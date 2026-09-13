/**
 * @file lua_bullet_1.cpp
 * @brief The first quarter of the Bullet-to-Lua registrations.
 *
 * Split out of lua_bullet.cpp purely to shorten the build; see
 * lua_bullet_p.h. The registrations appear here in the same order they had
 * in the original single function.
 */

#include "lua_bullet_p.h"

/**
 * @brief Registers the first quarter of the Bullet API.
 * @param s The Lua state to register in.
 */
void luaBindBulletPart1(lua_State *s) {
  using namespace luabind;

  // https://pybullet.org/Bullet/BulletFull/

  module(
      s) // https://pybullet.org/Bullet/BulletFull/classbtCollisionShape.html
      [class_<btCollisionShape>("btCollisionShape")
           .property("userPointer", &btCollisionShape::getUserPointer,
                     &btCollisionShape::setUserPointer)
           .def("isPolyhedral", &btCollisionShape::isPolyhedral)
           .def("isConvex2d", &btCollisionShape::isConvex2d)
           .def("isConvex", &btCollisionShape::isConvex)
           .def("isNonMoving", &btCollisionShape::isNonMoving)
           .def("isConcave", &btCollisionShape::isConcave)
           .def("isCompound", &btCollisionShape::isCompound)
           .def("isSoftBody", &btCollisionShape::isSoftBody)
           .def("isInfinite", &btCollisionShape::isInfinite)
           .def("setLocalScaling", &btCollisionShape::setLocalScaling)
           .def("getLocalScaling", &btCollisionShape::getLocalScaling)
           .def("calculateLocalInertia",
                &btCollisionShape::calculateLocalInertia)
           .def("getName", &btCollisionShape::getName)
           .def("getShapeType", &btCollisionShape::getShapeType)
           .def("setMargin", &btCollisionShape::setMargin)
           .def("getMargin", &btCollisionShape::getMargin)
           .def("setUserPointer", &btCollisionShape::setUserPointer)
           .def("getUserPointer", &btCollisionShape::getUserPointer)
           .def("calculateSerializeBufferSize",
                &btCollisionShape::calculateSerializeBufferSize)
           .def("serialize", &btCollisionShape::serialize)
           .def("serializeSingleShape",
                &btCollisionShape::serializeSingleShape)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  // TODO
  // btStridingMeshInterface
  // btBroadphaseProxy

  // https://pybullet.org/Bullet/BulletFull/classbtMotionState.html
  module(s)[class_<btMotionState, btMotionState *, btMotionState_wrap>(
             "btMotionState")
             .def("getWorldTransform", &btMotionState_wrap::getWorldTransform)
             .def("setWorldTransform", &btMotionState_wrap::setWorldTransform)
             .def(tostring(const_self))
             .def(const_self == const_self)];

  // https://pybullet.org/Bullet/BulletFull/structbtDefaultMotionState.html
  module(s)[class_<btDefaultMotionState, btDefaultMotionState *,
                   btDefaultMotionState_wrap, btMotionState>(
                "btDefaultMotionState")
                .def(constructor<const btTransform &, const btTransform &>())
                .def(constructor<const btTransform &>(), adopt(result))
                .def(tostring(const_self))
                .def(const_self == const_self)];

  // BULLET SHAPE CLASSES

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtCompoundShape.html
      [class_<btCompoundShape, btCollisionShape>("btCompoundShape")
           .def(constructor<bool>(), adopt(result))
           .def("addChildShape", &btCompoundShape::addChildShape)
           .def("removeChildShape", &btCompoundShape::removeChildShape)
           .def("removeChildShapeByIndex",
                &btCompoundShape::removeChildShapeByIndex)
           .def("getNumChildShapes", &btCompoundShape::getNumChildShapes)
           .def("getChildShape",
                (btCollisionShape * (btCompoundShape::*)(int)) &
                    btCompoundShape::getChildShape)
           .def("getChildTransform", (btTransform & (btCompoundShape::*)(int)) &
                                         btCompoundShape::getChildTransform)
           .def("updateChildTransform", &btCompoundShape::updateChildTransform)
           .def("getChildList", &btCompoundShape::getChildList)
           .def("getDynamicAabbTree", (btDbvt * (btCompoundShape::*)(void)) &
                                          btCompoundShape::getDynamicAabbTree)
           .def("createAabbTreeFromChildren",
                &btCompoundShape::createAabbTreeFromChildren)
           .def("calculatePrincipalAxisTransform",
                &btCompoundShape::calculatePrincipalAxisTransform)
           .def("getUpdateRevision", &btCompoundShape::getUpdateRevision)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtConcaveShape.html
      [class_<btConcaveShape, btCollisionShape>("btConcaveShape")
           .property("margin", &btConcaveShape::getMargin,
                     &btConcaveShape::setMargin)

           .def("getMargin", &btConcaveShape::getMargin)
           .def("setMargin", &btConcaveShape::setMargin)

           .def("processAllTriangles", &btConcaveShape::processAllTriangles)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtStaticPlaneShape.html
      [class_<btStaticPlaneShape, btConcaveShape>("btStaticPlaneShape")
           .def(constructor<const btVector3 &, btScalar>(), adopt(result))
           .def("getPlaneNormal", &btStaticPlaneShape::getPlaneNormal)
           .def("getPlaneConstant", &btStaticPlaneShape::getPlaneConstant)
           .property("planeNormal", &btStaticPlaneShape::getPlaneNormal)
           .property("planeConstant", &btStaticPlaneShape::getPlaneConstant)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtTriangleMeshShape.html
      [class_<btTriangleMeshShape, btConcaveShape>("btTriangleMeshShape")
           .def("getMeshInterface",
                (btStridingMeshInterface * (btTriangleMeshShape::*)()) &
                    btTriangleMeshShape::getMeshInterface)
           .property("meshInterface",
                     (btStridingMeshInterface * (btTriangleMeshShape::*)()) &
                         btTriangleMeshShape::getMeshInterface)
           .def("getLocalAabbMin", &btTriangleMeshShape::getLocalAabbMin)
           .def("getLocalAabbMax", &btTriangleMeshShape::getLocalAabbMax)
           .def("recalcLocalAabb", &btTriangleMeshShape::recalcLocalAabb)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtBvhTriangleMeshShape.html
      [class_<btBvhTriangleMeshShape, btTriangleMeshShape>(
           "btBvhTriangleMeshShape")
           .def(constructor<btStridingMeshInterface *, bool, bool>(),
                adopt(result))
           .def("getOwnsBvh", &btBvhTriangleMeshShape::getOwnsBvh)
           .def("usesQuantizedAabbCompression",
                &btBvhTriangleMeshShape::usesQuantizedAabbCompression)
           .def("buildOptimizedBvh",
                &btBvhTriangleMeshShape::buildOptimizedBvh)
           .def("refitTree", &btBvhTriangleMeshShape::refitTree)
           .def("partialRefitTree", &btBvhTriangleMeshShape::partialRefitTree)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtEmptyShape.html
      [class_<btEmptyShape, btConcaveShape>("btEmptyShape")
           .def("getMargin", &btEmptyShape::getMargin)
           .def("setMargin", &btEmptyShape::setMargin)
           .property("margin", &btEmptyShape::getMargin,
                     &btEmptyShape::setMargin)

           .def("processAllTriangles", &btEmptyShape::processAllTriangles)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtGImpactShapeInterface.html
      [class_<btGImpactShapeInterface, btConcaveShape>(
           "btGImpactShapeInterface")
           .def("updateBound", &btGImpactShapeInterface::updateBound)
           .def("getAABB", &btGImpactShapeInterface::getAabb)
           .property("aabb", &btGImpactShapeInterface::getAabb)
           .def("getLocalBox", &btGImpactShapeInterface::getLocalBox)
           .property("localBox", &btGImpactShapeInterface::getLocalBox)
           .def("getBoxSet", &btGImpactShapeInterface::getBoxSet)
           .property("boxSet", &btGImpactShapeInterface::getBoxSet)
           .def("getHasBoxSet", &btGImpactShapeInterface::hasBoxSet)
           .property("hasBoxSet", &btGImpactShapeInterface::hasBoxSet)
           .def(tostring(const_self))
           .def(const_self == const_self)

       // XXX
  ];

  module(s) // http://bulletphysics.org/Bullet/BulletFull/classbtGImpactMeshShape.html
      [class_<btGImpactMeshShape, btGImpactShapeInterface>("btGImpactMeshShape")
           .def(constructor<btStridingMeshInterface *>(), adopt(result))

           .property("margin", &btGImpactMeshShape::getMargin,
                     &btGImpactMeshShape::setMargin)
           .def("getMargin", &btGImpactMeshShape::getMargin)
           .def("setMargin", &btGImpactMeshShape::setMargin)

           .property("meshInterface",
                     (btStridingMeshInterface * (btGImpactMeshShape::*)()) &
                         btGImpactMeshShape::getMeshInterface)
           .def("getMeshInterface",
                (btStridingMeshInterface * (btGImpactMeshShape::*)()) &
                    btGImpactMeshShape::getMeshInterface)

           .def("updateBound", &btGImpactMeshShape::updateBound)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtConvexShape.html
      [class_<btConvexShape, btCollisionShape>("btConvexShape")
           .def("localGetSupportVertexWithoutMarginNonVirtual",
                &btConvexShape::localGetSupportVertexWithoutMarginNonVirtual)
           .def("localGetSupportVertexNonVirtual",
                &btConvexShape::localGetSupportVertexNonVirtual)
           .def("getMarginNonVirtual", &btConvexShape::getMarginNonVirtual)
           .def("getAabbNonVirtual", &btConvexShape::getAabbNonVirtual)
           .def("getAabb", &btConvexShape::getAabb)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtConvexInternalShape.html
      [class_<btConvexInternalShape, btConvexShape>("btConvexInternalShape")
           .def("getImplicitShapeDimensions",
                &btConvexInternalShape::getImplicitShapeDimensions)
           .def("setImplicitShapeDimensions",
                &btConvexInternalShape::setImplicitShapeDimensions)
           .def("setSafeMargin",
                (void(btConvexInternalShape::*)(btScalar, btScalar)) &
                    btConvexInternalShape::setSafeMargin)
           .def("getAabb", &btConvexInternalShape::getAabb)
           .def("getLocalScalingNV", &btConvexInternalShape::getLocalScalingNV)
           .def("getMarginNV", &btConvexInternalShape::getMarginNV)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtCapsuleShape.html
      [class_<btCapsuleShape, btConvexInternalShape>("btCapsuleShape")
           .def(constructor<btScalar, btScalar>(), adopt(result))
           .property("upAxis", &btCapsuleShape::getUpAxis)
           .def("getUpAxis", &btCapsuleShape::getUpAxis)
           .property("radius", &btCapsuleShape::getRadius)
           .def("getRadius", &btCapsuleShape::getRadius)
           .property("halfHeight", &btCapsuleShape::getHalfHeight)
           .def("getHalfHeight", &btCapsuleShape::getHalfHeight)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtCapsuleShapeX.html
      [class_<btCapsuleShapeX, btCapsuleShape>("btCapsuleShapeX")
           .def(constructor<btScalar, btScalar>(), adopt(result))
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtCapsuleShapeZ.html
      [class_<btCapsuleShapeZ, btCapsuleShape>("btCapsuleShapeZ")
           .def(constructor<btScalar, btScalar>(), adopt(result))
           .def(tostring(const_self))
           .def(const_self == const_self)];}
