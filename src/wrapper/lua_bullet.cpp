#include "lua_bullet.h"

#include <QDebug>

std::ostream& operator<<(std::ostream& ostream, const btVector3& v) {
    ostream << "btVector3(" << v.x() << ", " << v.y() << ", " << v.z() << ")";
    return ostream;
}

#include <boost/shared_ptr.hpp>

#include <btBulletDynamicsCommon.h>

#include <BulletDynamics/Vehicle/btRaycastVehicle.h>
#include <BulletCollision/Gimpact/btGImpactShape.h>
#include <BulletCollision/Gimpact/btGImpactCollisionAlgorithm.h>

#include <luabind/luabind.hpp>
#include <luabind/wrapper_base.hpp>
#include <luabind/operator.hpp>
#include <luabind/adopt_policy.hpp>

#define LuaClassNonDeletable(in_class) \
    namespace luabind{namespace detail{ \
    template<> struct delete_s<in_class> {static void apply(void*) {}}; \
    template<> struct destruct_only_s<in_class> {static void apply(void*){}}; \
    }}

LuaClassNonDeletable(btDefaultMotionState)
LuaClassNonDeletable(btMotionState)
LuaClassNonDeletable(btCollisionObject)
LuaClassNonDeletable(btRigidBody)

struct btMotionState_wrap : public btMotionState, luabind::wrap_base
{
                                       btMotionState_wrap(const btTransform &, const btTransform &) {}
                                       btMotionState_wrap(const btTransform &) {}

                                       virtual void getWorldTransform (btTransform &worldTrans) const {
                                       qDebug() << "btMotionState_wrap::getWorldTransform()";
                                       luabind::call_member<void>(this, "getWorldTransform", worldTrans);
                                       /*
                                                                                      lua_State* L = m_self.state();
                                                                                              m_self.get(L);
                                                                                              if( ! lua_isnil( L, -1 ) ) {
                                                                                              } else {
                                                                                                  qDebug() << "getWorldTransform missing on the Lua side";
                                                                                              }
                                                                                              lua_pop( L, 1 ); */
                                       }

                                       virtual void setWorldTransform (const btTransform &worldTrans) {
                                       qDebug() << "btMotionState_wrap::setWorldTransform()";
                                       luabind::call_member<void>(this, "setWorldTransform", worldTrans);
                                       /*
                                                                                      lua_State* L = m_self.state();
                                                                                              m_self.get(L);
                                                                                              if( ! lua_isnil( L, -1 ) )
                                                                                              else
                                                                                                  qDebug() << "setWorldTransform missing on the Lua side";
                                                                                              lua_pop( L, 1 );*/
                                       }

                                       virtual ~btMotionState_wrap() {
                                       qDebug() << "~btMotionState_wrap()";
                                       }
                                       };

struct btDefaultMotionState_wrap : public btDefaultMotionState, btMotionState_wrap
{
    btDefaultMotionState_wrap(const btTransform &startTrans, const btTransform &centerOfMassOffset)
        : btDefaultMotionState(startTrans, centerOfMassOffset), btMotionState_wrap(startTrans, centerOfMassOffset) {
        qDebug() << "btDefaultMotionState_wrap()";
    }
    btDefaultMotionState_wrap(const btTransform &startTrans) : btDefaultMotionState(startTrans), btMotionState_wrap(startTrans) {
        qDebug() << "btDefaultMotionState_wrap()";
    }

    virtual ~btDefaultMotionState_wrap() {
        qDebug() << "~btDefaultMotionState_wrap()";
    }
};

LuaBullet::LuaBullet(QObject *parent) :
    QObject(parent)
{
}

void LuaBullet::luaBind(lua_State *s)
{
    using namespace luabind;

    open(s);
    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtCollisionShape.html
            [
            class_<btCollisionShape>("btCollisionShape")
            .property("userPointer", &btCollisionShape::getUserPointer, &btCollisionShape::setUserPointer)
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
            .def("calculateLocalInertia", &btCollisionShape::calculateLocalInertia)
            .def("getName", &btCollisionShape::getName)
            .def("getShapeType", &btCollisionShape::getShapeType)
            .def("setMargin", &btCollisionShape::setMargin)
            .def("getMargin", &btCollisionShape::getMargin)
            .def("setUserPointer", &btCollisionShape::setUserPointer)
            .def("getUserPointer", &btCollisionShape::getUserPointer)
            .def("calculateSerializeBufferSize", &btCollisionShape::calculateSerializeBufferSize)
            .def("serialize", &btCollisionShape::serialize)
            .def("serializeSingleShape", &btCollisionShape::serializeSingleShape)
            ];

    // TODO
    // http://bulletphysics.com/Bullet/BulletFull/structbtDbvt.html
    // btStridingMeshInterface
    // btBroadphaseProxy


    // btMotionState

    module(s)
            [
            class_<btMotionState, boost::shared_ptr<btMotionState_wrap>, btMotionState_wrap >("btMotionState")
            .def("getWorldTransform", &btMotionState_wrap::getWorldTransform)
            .def("setWorldTransform", &btMotionState_wrap::setWorldTransform)
            ];

    // btDefaultMotionState
    module(s)
            [
            class_<btDefaultMotionState, boost::shared_ptr<btDefaultMotionState_wrap>, btDefaultMotionState_wrap, btMotionState >("btDefaultMotionState")
            .def(constructor<const btTransform&, const btTransform&>(), adopt(result))
            .def(constructor<const btTransform&>(), adopt(result))
            ];

    // BULLET SHAPE CLASSES

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtCompoundShape.html
            [
            class_<btCompoundShape,btCollisionShape>("btCompoundShape")
            .def(constructor<bool>())
            .def("addChildShape", &btCompoundShape::addChildShape)
            .def("removeChildShape", &btCompoundShape::removeChildShape)
            .def("removeChildShapeByIndex", &btCompoundShape::removeChildShapeByIndex)
            .def("getNumChildShapes", &btCompoundShape::getNumChildShapes)
            .def("getChildShape", (btCollisionShape*(btCompoundShape::*)(int))&btCompoundShape::getChildShape)
            .def("getChildTransform", (btTransform&(btCompoundShape::*)(int))&btCompoundShape::getChildTransform)
            .def("updateChildTransform", &btCompoundShape::updateChildTransform)
            .def("getChildList", &btCompoundShape::getChildList)
            .def("getDynamicAabbTree", (btDbvt*(btCompoundShape::*)(void))&btCompoundShape::getDynamicAabbTree)
            .def("createAabbTreeFromChildren", &btCompoundShape::createAabbTreeFromChildren)
            .def("calculatePrincipalAxisTransform", &btCompoundShape::calculatePrincipalAxisTransform)
            .def("getUpdateRevision", &btCompoundShape::getUpdateRevision)
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtConcaveShape.html
            [
            class_<btConcaveShape, btCollisionShape>("btConcaveShape")
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtConvexShape.html
            [
            class_<btConvexShape, btCollisionShape>("btConvexShape")
            .def("localGetSupportVertexWithoutMarginNonVirtual", &btConvexShape::localGetSupportVertexWithoutMarginNonVirtual)
            .def("localGetSupportVertexNonVirtual", &btConvexShape::localGetSupportVertexNonVirtual)
            .def("getMarginNonVirtual", &btConvexShape::getMarginNonVirtual)
            .def("getAabbNonVirtual", &btConvexShape::getAabbNonVirtual)
            .def("getAabb", &btConvexShape::getAabb)
            ];

    // not in the headers http://bulletphysics.com/Bullet/BulletFull/classbtConvex2dShape.html

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtConvexInternalShape.html
            [
            class_<btConvexInternalShape, btConvexShape>("btConvexInternalShape")
            .def("getImplicitShapeDimensions", &btConvexInternalShape::getImplicitShapeDimensions)
            .def("setImplicitShapeDimensions", &btConvexInternalShape::setImplicitShapeDimensions)
            .def("setSafeMargin", (void(btConvexInternalShape::*)(btScalar, btScalar))&btConvexInternalShape::setSafeMargin)
            .def("getAabb", &btConvexInternalShape::getAabb)
            .def("getLocalScalingNV", &btConvexInternalShape::getLocalScalingNV)
            .def("getMarginNV", &btConvexInternalShape::getMarginNV)
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtCapsuleShape.html
            [
            class_<btCapsuleShape, btConvexInternalShape>("btCapsuleShape")
            .def(constructor<btScalar, btScalar>())
            .def("getUpAxis", &btCapsuleShape::getUpAxis)
            .def("getRadius", &btCapsuleShape::getRadius)
            .def("getHalfHeight", &btCapsuleShape::getHalfHeight)
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtCapsuleShapeX.html
            [
            class_<btCapsuleShapeX, btCapsuleShape>("btCapsuleShapeX")
            .def(constructor<btScalar, btScalar>())
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtCapsuleShapeZ.html
            [
            class_<btCapsuleShapeZ, btCapsuleShape>("btCapsuleShapeZ")
            .def(constructor<btScalar, btScalar>())
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtConeShape.html
            [
            class_<btConeShape, btConvexInternalShape>("btConeShape")
            .def(constructor<btScalar, btScalar>())
            .def("getRadius", &btConeShape::getRadius)
            .def("getHeight", &btConeShape::getHeight)
            .def("setConeUpIndex", &btConeShape::setConeUpIndex)
            .def("getConeUpIndex", &btConeShape::getConeUpIndex)
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtConeShapeX.html
            [
            class_<btConeShapeX, btConeShape>("btConeShapeX")
            .def(constructor<btScalar, btScalar>())
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtConeShapeZ.html
            [
            class_<btConeShapeZ, btConeShape>("btConeShapeZ")
            .def(constructor<btScalar, btScalar>())
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtConvexInternalAabbCachingShape.html
            [
            class_<btConvexInternalAabbCachingShape>("btConvexInternalAabbCachingShape")
            .def("recalcLocalAabb", &btConvexInternalAabbCachingShape::recalcLocalAabb)
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtMultiSphereShape.html
            [
            class_<btMultiSphereShape, btConvexInternalAabbCachingShape>("btMultiSphereShape")
            .def(constructor<const btVector3*, const btScalar*, int>())
            .def("getSphereCount", &btMultiSphereShape::getSphereCount)
            .def("getSpherePosition", &btMultiSphereShape::getSpherePosition)
            .def("getSphereRadius", &btMultiSphereShape::getSphereRadius)
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtCylinderShape.html
            [
            class_<btCylinderShape, btConvexInternalShape>("btCylinderShape")
            .def("getHalfExtentsWithMargin", &btCylinderShape::getHalfExtentsWithMargin)
            .def("getHalfExtentsWithoutMargin", &btCylinderShape::getHalfExtentsWithoutMargin)
            .def("getAabb", &btCylinderShape::getAabb)
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtCylinderShapeX.html
            [
            class_<btCylinderShapeX, btCylinderShape>("btCylinderShapeX")
            .def(constructor<const btVector3&>())
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtCylinderShapeZ.html
            [
            class_<btCylinderShapeZ, btCylinderShape>("btCylinderShapeZ")
            .def(constructor<const btVector3&>())
            ];

    // not in the headers http://bulletphysics.com/Bullet/BulletFull/classbtMinkowskiSumShape.html

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtPolyhedralConvexShape.html
            [
            class_<btPolyhedralConvexShape, btConvexInternalShape>("btPolyhedralConvexShape")
            // TODO .def("getConvexPolyhedron", &btPolyhedralConvexShape::getConvexPolyhedron)
            // needs definition of btConvexPolyhedron not in the headers
            ];

    // not in the headers http://bulletphysics.com/Bullet/BulletFull/classbtBox2dShape.html

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtBoxShape.html
            [
            class_<btBoxShape, btPolyhedralConvexShape>("btBoxShape")
            .def(constructor<const btVector3&>())
            .def("getHalfExtentsWithMargin", &btBoxShape::getHalfExtentsWithMargin)
            .def("getHalfExtentsWithoutMargin", &btBoxShape::getHalfExtentsWithoutMargin)
            .def("localGetSupportingVertexWithoutMargin", &btBoxShape::localGetSupportingVertexWithoutMargin)
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtPolyhedralConvexAabbCachingShape.html
            [
            class_<btPolyhedralConvexAabbCachingShape, btPolyhedralConvexShape>("btPolyhedralConvexAabbCachingShape")
            .def("getNonvirtualAabb", &btPolyhedralConvexAabbCachingShape::getNonvirtualAabb)
            .def("recalcLocalAabb", &btPolyhedralConvexAabbCachingShape::recalcLocalAabb)
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtBU__Simplex1to4.html
            [
            class_<btBU_Simplex1to4, btPolyhedralConvexAabbCachingShape>("btBU_Simplex1to4")
            .def(constructor<>())
            .def(constructor<const btVector3&>())
            .def(constructor<const btVector3&, const btVector3&>())
            .def(constructor<const btVector3&, const btVector3&, const btVector3&>())
            .def(constructor<const btVector3&, const btVector3&, const btVector3&, const btVector3&>())
            .def("reset", &btBU_Simplex1to4::reset)
            .def("addVertex", &btBU_Simplex1to4::addVertex)
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtTetrahedronShapeEx.html
            [
            class_<btTetrahedronShapeEx, btBU_Simplex1to4>("btTetrahedronShapeEx")
            .def(constructor<>())
            .def("setVertices", &btTetrahedronShapeEx::setVertices)
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtConvexHullShape.html
            [
            class_<btConvexHullShape, btPolyhedralConvexAabbCachingShape>("btConvexHullShape")
            .def(constructor<const btScalar*, int, int>())
            .def("addPoint", &btConvexHullShape::addPoint)
            .def("getUnscaledPoints", (btVector3*(btConvexHullShape::*)())&btConvexHullShape::getUnscaledPoints)
            .def("getPoints", &btConvexHullShape::getPoints)
            .def("getScaledPoint", &btConvexHullShape::getScaledPoint)
            .def("getNumPoints", &btConvexHullShape::getNumPoints)
            ];

    // not defined in the headers http://bulletphysics.com/Bullet/BulletFull/classbtConvexPointCloudShape.html

    module(s)
            [
            class_<btStridingMeshInterface>("btStridingMeshInterface")
            .def("calculateAabbBruteForce", &btStridingMeshInterface::calculateAabbBruteForce)
            .def("getScaling", &btStridingMeshInterface::getScaling)
            .def("setScaling", &btStridingMeshInterface::setScaling)
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtConvexTriangleMeshShape.html
            [
            class_<btConvexTriangleMeshShape, btPolyhedralConvexAabbCachingShape>("btConvexTriangleMeshShape")
            .def(constructor<btStridingMeshInterface *, bool>())
            .def("getMeshInterface",
                 (btStridingMeshInterface*(btConvexTriangleMeshShape::*)())&btConvexTriangleMeshShape::getMeshInterface)
            .def("calculatePrincipalAxisTransform", &btConvexTriangleMeshShape::calculatePrincipalAxisTransform)
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtTriangleShape.html
            [
            class_<btTriangleShape, btPolyhedralConvexShape>("btTriangleShape")
            .def("getVertexPtr", (btVector3 &(btTriangleShape::*)(int))&btTriangleShape::getVertexPtr)
            .def("calcNormal", &btTriangleShape::calcNormal)
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtTriangleShapeEx.html
            [
            class_<btTriangleShapeEx, btTriangleShape>("btTriangleShapeEx")
            .def(constructor<>())
            .def(constructor<const btVector3&, const btVector3&, const btVector3&>())
            .def(constructor<const btTriangleShapeEx>())
            .def("applyTransform", &btTriangleShapeEx::applyTransform)
            .def("buildTriPlane", &btTriangleShapeEx::buildTriPlane)
            .def("overlap_test_conservative", &btTriangleShapeEx::overlap_test_conservative)
            ];

    // not defined in the headers http://bulletphysics.com/Bullet/BulletFull/classbtSoftClusterCollisionShape.html

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtSphereShape.html
            [
            class_<btSphereShape, btConvexInternalShape>("btSphereShape")
            .def(constructor<btScalar>())
            .def("getRadius", &btSphereShape::getRadius)
            .def("setUnscaledRadius", &btSphereShape::setUnscaledRadius)
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtUniformScalingShape.html
            [
            class_<btUniformScalingShape, btConvexShape>("btUniformScalingShape")
            .def(constructor<btConvexShape*, btScalar>())
            .def("getUniformScalingFactor", &btUniformScalingShape::getUniformScalingFactor)
            .def("getChildShape", (btConvexShape *(btUniformScalingShape::*)())&btUniformScalingShape::getChildShape)
            .def("getAabb", &btUniformScalingShape::getAabb)
            ];

    // BULLET GEOMETRY CLASSES

    module(s)
            [
            class_<btVector3>( "btVector3" )
            .def(constructor<>())
            .def(constructor<btScalar, btScalar, btScalar>())
            .def(const_self + const_self)
            .def(const_self - const_self)
            .def(const_self * other<btScalar>())
            .def(const_self / other<btScalar>())
            .def(const_self == const_self)
            .property("x", &btVector3::getX, &btVector3::setX)
            .property("y", &btVector3::getY, &btVector3::setY)
            .property("z", &btVector3::getZ, &btVector3::setZ)
            .def( "getX", &btVector3::getX )
            .def( "getY", &btVector3::getY )
            .def( "getZ", &btVector3::getZ )
            .def( "setX", &btVector3::setX )
            .def( "setY", &btVector3::setY )
            .def( "setZ", &btVector3::setZ )
            .def( "absolute", &btVector3::absolute )
            .def("angle", &btVector3::angle )
            .def("closestAxis", &btVector3::closestAxis )
            .def("cross", &btVector3::cross )
            .def("distance", &btVector3::distance )
            .def("distance2", &btVector3::distance2 )
            .def("dot", &btVector3::dot )
            .def("furthestAxis", &btVector3::furthestAxis )
            .def("fuzzyZero", &btVector3::fuzzyZero )
            .def("isZero", &btVector3::isZero )
            .def("length", &btVector3::length )
            .def("length2", &btVector3::length2 )
            .def("lerp", &btVector3::lerp )
            .def("maxAxis", &btVector3::maxAxis )
            .def("minAxis", &btVector3::minAxis )
            .def("normalize", &btVector3::normalize )
            .def("normalized", &btVector3::normalized )
            .def("rotate", &btVector3::rotate )
            .def("setZero", &btVector3::setZero )
            .def("triple", &btVector3::triple )
            .def(tostring(const_self))
            ];

    module(s)
            [
            class_<btVector4, btVector3>("btVector4")
            .def(constructor<>())
            .def(constructor<const btScalar&, const btScalar&, const btScalar&, const btScalar&>())
            .def("absolute4", &btVector4::absolute4)
            .def("getW", &btVector4::getW)
            .def("maxAxis4", &btVector4::maxAxis4)
            .def("minAxis4", &btVector4::minAxis4)
            .def("closestAxis4", &btVector4::closestAxis4)
            .def("setValue", &btVector4::setValue)
            ];

    module(s)
            [
            class_<btQuaternion>("btQuaternion")
            .def(constructor<>())
            .def(constructor<const btVector3&, btScalar>())
            .def(constructor<btScalar, btScalar, btScalar, btScalar>())
            .def("angle", &btQuaternion::angle )
            .def("dot", &btQuaternion::dot )
            .def("farthest", &btQuaternion::farthest )
            .def("getAngle", &btQuaternion::getAngle )
            .def("getAxis", &btQuaternion::getAxis )
            .def("getIdentity", &btQuaternion::getIdentity )
            .def("getW", &btQuaternion::getW )
            .def("getX", &btQuaternion::getX )
            .def("getY", &btQuaternion::getY )
            .def("getZ", &btQuaternion::getZ )
            .def("inverse", &btQuaternion::inverse )
            .def("length", &btQuaternion::length )
            .def("length2", &btQuaternion::length2 )
            .def("nearest", &btQuaternion::nearest )
            .def("normalize", &btQuaternion::normalize )
            .def("normalized", &btQuaternion::normalized )
            .def("setEuler", &btQuaternion::setEuler )
            .def("setEulerZYX", &btQuaternion::setEulerZYX )
            .def("setMax", &btQuaternion::setMax )
            .def("setMin", &btQuaternion::setMin )
            .def("setRotation", &btQuaternion::setRotation )
            .def("setW", &btQuaternion::setW )
            .def("setX", &btQuaternion::setX )
            .def("setY", &btQuaternion::setY )
            .def("setZ", &btQuaternion::setZ )
            .def("slerp", &btQuaternion::slerp )
            .def("w", &btQuaternion::w )
            .def("x", &btQuaternion::x )
            .def("y", &btQuaternion::y )
            .def("z", &btQuaternion::z )
            ];

    module(s) // http://bulletphysics.com/Bullet/BulletFull/classbtCollisionObject.html
            [
            class_<btCollisionObject, boost::shared_ptr<btCollisionObject> >("btCollisionObject")
            .def(constructor<>())
            .def("mergesSimulationIslands", &btCollisionObject::mergesSimulationIslands)
            .def("getAnisotropicFriction", &btCollisionObject::getAnisotropicFriction)
            .def("setAnisotropicFriction", &btCollisionObject::setAnisotropicFriction)
            .def("hasAnisotropicFriction", &btCollisionObject::hasAnisotropicFriction)
            .def("setContactProcessingThreshold", &btCollisionObject::setContactProcessingThreshold)
            .def("isStaticObject", &btCollisionObject::isStaticObject)
            .def("isKinematicObject", &btCollisionObject::isStaticOrKinematicObject)
            .def("hasContactResponse", &btCollisionObject::hasContactResponse)
            .def("getCollisionShape", (btCollisionShape *(btCollisionObject::*)())&btCollisionObject::getCollisionShape)
            // not in the headers .def("getRootCollisionShape",
            // (btCollisionShape *(btCollisionObject::*)())&btCollisionObject::getRootCollisionShape)
            .def("getActivationState", &btCollisionObject::getActivationState)
            .def("setActivationState", &btCollisionObject::setActivationState)
            .def("setDeactivationTime", &btCollisionObject::setDeactivationTime)
            .def("getDeactivationTime", &btCollisionObject::getDeactivationTime)
            .def("forceActivationState", &btCollisionObject::forceActivationState)
            .def("activate", &btCollisionObject::activate)
            .def("isActive", &btCollisionObject::isActive)
            .def("setRestitution", &btCollisionObject::setRestitution)
            .def("getRestitution", &btCollisionObject::getRestitution)
            .def("setFriction", &btCollisionObject::setFriction)
            .def("getFriction", &btCollisionObject::getFriction)
            .def("getWorldTransform", (btTransform&(btCollisionObject::*)())&btCollisionObject::getWorldTransform)
            .def("setWorldTransform", &btCollisionObject::setWorldTransform)
            .def("getBroadphaseHandle", (btBroadphaseProxy *(btCollisionObject::*)())&btCollisionObject::getBroadphaseHandle)
            .def("getInterpolationWorldTransform",
                 (btTransform&(btCollisionObject::*)())&btCollisionObject::getInterpolationWorldTransform)
            .def("setInterpolationWorldTransform", &btCollisionObject::setInterpolationWorldTransform)
            .def("setInterpolationLinearVelocity", &btCollisionObject::setInterpolationLinearVelocity)
            .def("setInterpolationAngularVelocity", &btCollisionObject::setInterpolationAngularVelocity)
            .def("getInterpolationLinearVelocity", &btCollisionObject::getInterpolationLinearVelocity)
            .def("getInterpolationAngularVelocity", &btCollisionObject::getInterpolationAngularVelocity)
            .def("getIslandTag", &btCollisionObject::getIslandTag)
            .def("setIslandTag", &btCollisionObject::setIslandTag)
            .def("getCompanionId", &btCollisionObject::getCompanionId)
            .def("setCompanionId", &btCollisionObject::setCompanionId)
            .def("getHitFraction", &btCollisionObject::getHitFraction)
            .def("setHitFraction", &btCollisionObject::setHitFraction)
            .def("getCollisionFlags", &btCollisionObject::setCollisionFlags)
            .def("setCollisionFlags", &btCollisionObject::getCollisionFlags)
            .def("getCcdSweptSphereRadius", &btCollisionObject::getCcdSweptSphereRadius)
            .def("setCcdSweptSphereRadius", &btCollisionObject::setCcdSweptSphereRadius)
            .def("getCcdMotionThreshold", &btCollisionObject::getCcdMotionThreshold)
            .def("getCcdSquareMotionThreshold", &btCollisionObject::getCcdSquareMotionThreshold)
            .def("setCcdMotionThreshold", &btCollisionObject::setCcdMotionThreshold)
            .def("getUserPointer", &btCollisionObject::getUserPointer)
            .def("setUserPointer", &btCollisionObject::setUserPointer)
            .def("checkCollideWith", &btCollisionObject::checkCollideWith)
            ];

    // btRigidBodyConstructionInfo

    module(s)
            [
            class_<btRigidBody::btRigidBodyConstructionInfo>("btRigidBodyConstructionInfo")
            .def(constructor<btScalar, btMotionState *, btCollisionShape *, const btVector3 &>())
            ];

    module(s)
            [
            class_<btRigidBody, btCollisionObject>("btRigidBody")
            .def(constructor<const btRigidBody::btRigidBodyConstructionInfo &>())
            .def(constructor<btScalar, btMotionState *, btCollisionShape *, const btVector3 &>())
            .def("proceedToTransform", &btRigidBody::proceedToTransform)
            .def("predictIntegratedTransform", &btRigidBody::predictIntegratedTransform)
            .def("saveKinematicState", &btRigidBody::saveKinematicState)
            .def("applyGravity", &btRigidBody::applyGravity)
            .def("setGravity", &btRigidBody::setGravity)
            .def("getGravity", &btRigidBody::getGravity)
            .def("setDamping", &btRigidBody::setDamping)
            .def("getLinearDamping", &btRigidBody::getLinearDamping)
            .def("getAngularDamping", &btRigidBody::getAngularDamping)
            .def("getLinearSleepingThreshold", &btRigidBody::getLinearSleepingThreshold)
            .def("getAngularSleepingThreshold", &btRigidBody::getAngularSleepingThreshold)
            .def("applyDamping", &btRigidBody::applyDamping)
            .def("getCollisionShape", (btCollisionShape*(btRigidBody::*)())&btRigidBody::getCollisionShape)
            .def("setMassProps", &btRigidBody::setMassProps)
            .def("getLinearFactor", &btRigidBody::getLinearFactor)
            .def("setLinearFactor", &btRigidBody::setLinearFactor)
            .def("getInvMass", &btRigidBody::getInvMass)
            .def("getInvInertiaTensorWorld", &btRigidBody::getInvInertiaTensorWorld)
            .def("integrateVelocities", &btRigidBody::integrateVelocities)
            .def("setCenterOfMassTransform", &btRigidBody::setCenterOfMassTransform)
            .def("applyCentralForce", &btRigidBody::applyCentralForce)
            .def("getTotalForce", &btRigidBody::getTotalForce)
            .def("getTotalTorque", &btRigidBody::getTotalTorque)
            .def("getInvInertiaDiagLocal", &btRigidBody::getInvInertiaDiagLocal)
            .def("setInvInertiaDiagLocal", &btRigidBody::setInvInertiaDiagLocal)
            .def("setSleepingThresholds", &btRigidBody::setSleepingThresholds)
            .def("applyTorque", &btRigidBody::applyTorque)
            .def("applyForce", &btRigidBody::applyForce)
            .def("applyCentralImpulse", &btRigidBody::applyCentralImpulse)
            .def("applyTorqueImpulse", &btRigidBody::applyTorqueImpulse)
            .def("applyImpulse", &btRigidBody::applyImpulse)
            .def("clearForces", &btRigidBody::clearForces)
            .def("updateInertiaTensor", &btRigidBody::updateInertiaTensor)
            .def("getCenterOfMassPosition", &btRigidBody::getCenterOfMassPosition)
            .def("getOrientation", &btRigidBody::getOrientation)
            .def("getCenterOfMassTransform", &btRigidBody::getCenterOfMassTransform)
            .def("getLinearVelocity", &btRigidBody::getLinearVelocity)
            .def("getAngularVelocity", &btRigidBody::getAngularVelocity)
            .def("setLinearVelocity", &btRigidBody::setLinearVelocity)
            .def("setAngularVelocity", &btRigidBody::setAngularVelocity)
            .def("getVelocityInLocalPoint", &btRigidBody::getVelocityInLocalPoint)
            .def("translate", &btRigidBody::translate)
            .def("getAabb", &btRigidBody::getAabb)
            .def("computeImpulseDenominator", &btRigidBody::computeImpulseDenominator)
            .def("computeAngularImpulseDenominator", &btRigidBody::computeAngularImpulseDenominator)
            .def("updateDeactivation", &btRigidBody::updateDeactivation)
            .def("wantsSleeping", &btRigidBody::wantsSleeping)
            .def("getBroadphaseProxy", (btBroadphaseProxy*(btRigidBody::*)(void))&btRigidBody::getBroadphaseProxy)
            .def("setNewBroadphaseProxy", &btRigidBody::setNewBroadphaseProxy)
            .def("getMotionState", (btMotionState *(btRigidBody::*)(void))&btRigidBody::getMotionState)
            .def("setMotionState", &btRigidBody::setMotionState)
            .def("setAngularFactor", (void(btRigidBody::*)(const btVector3&))&btRigidBody::setAngularFactor)
            .def("setAngularFactor", (void(btRigidBody::*)(btScalar))&btRigidBody::setAngularFactor)
            .def("getAngularFactor", &btRigidBody::getAngularFactor)
            .def("isInWorld", &btRigidBody::isInWorld)
            .def("checkCollideWithOverride", &btRigidBody::checkCollideWithOverride)
            .def("addConstraintRef", &btRigidBody::addConstraintRef)
            .def("removeConstraintRef", &btRigidBody::removeConstraintRef)
            .def("getConstraintRef", &btRigidBody::getConstraintRef)
            .def("getNumConstraintRefs", &btRigidBody::getNumConstraintRefs)
            .def("setFlags", &btRigidBody::setFlags)
            .def("getFlags", &btRigidBody::getFlags)
            // not in the headers .def("getDeltaLinearVelocity", &btRigidBody::getDeltaLinearVelocity)
            // not in the headers .def("getDeltaAngularVelocity", &btRigidBody::getDeltaAngularVelocity)
            // not in the headers .def("getPushVelocity", &btRigidBody::getPushVelocity)
            // not in the headers .def("getTurnVelocity", &btRigidBody::getTurnVelocity)
            ];

    module(s)
            [
            class_<btTransform>("btTransform")
            .def(constructor<>())
            .def(constructor<const btQuaternion&, const btVector3&>())
            .def("getIdentity", &btTransform::getIdentity )
            .def("getOpenGLMatrix", &btTransform::getOpenGLMatrix )
            .def("getRotation", &btTransform::getRotation )
            .def("inverse", &btTransform::inverse )
            .def("inverseTimes", &btTransform::inverseTimes )
            .def("invXform", &btTransform::invXform )
            .def("mult", &btTransform::mult )
            .def("setBasis", &btTransform::setBasis )
            .def("setFromOpenGLMatrix", &btTransform::setFromOpenGLMatrix )
            .def("setIdentity", &btTransform::setIdentity )
            .def("setOrigin", &btTransform::setOrigin )
            .def("setRotation", &btTransform::setRotation )
            ];

    // BULLET CONSTRAINT CLASSES

    module(s)
            [
            class_<btTypedConstraint>("btTypedConstraint")
            ];

    module(s)
            [
            class_<btPoint2PointConstraint,btTypedConstraint>("btPoint2PointConstraint")
            .def(constructor<btRigidBody&, btRigidBody&, const btVector3&, const btVector3&>())
            .def("setParam", &btPoint2PointConstraint::setParam)
            ];

    module(s)
            [
            class_<btHingeConstraint,btTypedConstraint>("btHingeConstraint")
            .def(constructor<btRigidBody&, btRigidBody&,
                 const btVector3&, const btVector3&, const btVector3&, const btVector3&>())
            .def(constructor<btRigidBody&, btRigidBody&, const btTransform&, const btTransform&>())
            .def("setAxis", &btHingeConstraint::setAxis)
            .def("setLimit", &btHingeConstraint::setLimit)
            .def("setParam", &btHingeConstraint::setParam)
            .def("enableAngularMotor", &btHingeConstraint::enableAngularMotor)
            .def("getHingeAngle",  (btScalar(btHingeConstraint::*)())&btHingeConstraint::getHingeAngle)
            .def("getHingeAngle", (btScalar(btHingeConstraint::*)(const btTransform&, const btTransform&))&btHingeConstraint::getHingeAngle)
            ];

    module(s)
            [
            class_<btHingeAccumulatedAngleConstraint,btHingeConstraint>("btHingeAccumulatedAngleConstraint")
            .def(constructor<btRigidBody&, btRigidBody&,
                 const btVector3&, const btVector3&, const btVector3&, const btVector3&, bool>())
            .def(constructor<btRigidBody&, btRigidBody&, const btTransform&, const btTransform&, bool>())
            .def("setAccumulatedHingeAngle", &btHingeAccumulatedAngleConstraint::setAccumulatedHingeAngle)
            .def("getAccumulatedHingeAngle", &btHingeAccumulatedAngleConstraint::getAccumulatedHingeAngle)
            ];

    module(s)
            [
            class_<btSliderConstraint,btTypedConstraint>("btSliderConstraint")
            .def(constructor<btRigidBody&, btRigidBody&, const btTransform&, const btTransform&, bool>())
            .def("setLowerLinLimit", &btSliderConstraint::setLowerLinLimit)
            .def("setUpperLinLimit", &btSliderConstraint::setUpperLinLimit)
            .def("setLowerAngLimit", &btSliderConstraint::setLowerAngLimit)
            .def("setUpperAngLimit", &btSliderConstraint::setUpperAngLimit)
            .def("setSoftnessDirLin", &btSliderConstraint::setSoftnessDirLin)
            .def("setRestitutionDirLin", &btSliderConstraint::setRestitutionDirLin)
            .def("setDampingDirLin", &btSliderConstraint::setDampingDirLin)
            .def("setSoftnessDirAng", &btSliderConstraint::setSoftnessDirAng)
            .def("setRestitutionDirAng", &btSliderConstraint::setRestitutionDirAng)
            .def("setDampingDirAng", &btSliderConstraint::setDampingDirAng)
            .def("setSoftnessLimLin", &btSliderConstraint::setSoftnessLimLin)
            .def("setRestitutionLimLin", &btSliderConstraint::setRestitutionLimLin)
            .def("setDampingLimLin", &btSliderConstraint::setDampingLimLin)
            .def("setSoftnessLimAng", &btSliderConstraint::setSoftnessLimAng)
            .def("setRestitutionLimAng", &btSliderConstraint::setRestitutionLimAng)
            .def("setDampingLimAng", &btSliderConstraint::setDampingLimAng)
            .def("setSoftnessOrthoLin", &btSliderConstraint::setSoftnessOrthoLin)
            .def("setRestitutionOrthoLin", &btSliderConstraint::setRestitutionOrthoLin)
            .def("setDampingOrthoLin", &btSliderConstraint::setDampingOrthoLin)
            .def("setSoftnessOrthoAng", &btSliderConstraint::setSoftnessOrthoAng)
            .def("setRestitutionOrthoAng", &btSliderConstraint::setRestitutionOrthoAng)
            .def("setDampingOrthoAng", &btSliderConstraint::setDampingOrthoAng)
            .def("setParam", &btSliderConstraint::setParam)
            ];

    module(s)
            [
            class_<btGeneric6DofConstraint,btTypedConstraint>("btGeneric6DofConstraint")
            .def(constructor<btRigidBody&, btRigidBody&, const btTransform&, const btTransform&, bool>())
            .def("setLinearUpperLimit", &btGeneric6DofConstraint::setLinearUpperLimit)
            .def("setLinearLowerLimit", &btGeneric6DofConstraint::setLinearLowerLimit)
            .def("setLimit", &btGeneric6DofConstraint::setLimit)
            .def("setAxis", &btGeneric6DofConstraint::setAxis)
            .def("setParam", &btGeneric6DofConstraint::setParam)
            ];

    module(s)
            [
            class_<btGeneric6DofSpringConstraint,btTypedConstraint>("btGeneric6DofSpringConstraint")
            .def(constructor<btRigidBody&, btRigidBody&, const btTransform&, const btTransform&, bool>())
            .def("enableSpring", &btGeneric6DofSpringConstraint::enableSpring)
            .def("setStiffness", &btGeneric6DofSpringConstraint::setStiffness)
            .def("setDamping", &btGeneric6DofSpringConstraint::setDamping)
            .def("setAxis", &btGeneric6DofSpringConstraint::setAxis)
            .def("setEquilibriumPoint",  (void(btGeneric6DofSpringConstraint::*)())&btGeneric6DofSpringConstraint::setEquilibriumPoint)
            .def("setEquilibriumPoint", (void(btGeneric6DofSpringConstraint::*)(int))&btGeneric6DofSpringConstraint::setEquilibriumPoint)
            .def("setEquilibriumPoint", (void(btGeneric6DofSpringConstraint::*)(int,btScalar))&btGeneric6DofSpringConstraint::setEquilibriumPoint)
            ];

    module(s)
            [
            class_<btUniversalConstraint,btTypedConstraint>("btUniversalConstraint")
            .def(constructor<btRigidBody&, btRigidBody&, const btVector3&, const btVector3&, const btVector3&>())
            .def("setAxis", &btUniversalConstraint::setAxis)
            .def("setUpperLimit", &btHingeConstraint::setLimit)
            .def("setLowerLimit", &btHingeConstraint::setParam)
            ];

    module(s)
            [
            class_<btVehicleRaycaster>("btVehicleRaycaster")
            ];

    module(s)
            [
            class_<btDefaultVehicleRaycaster, btVehicleRaycaster>("btDefaultVehicleRaycaster")
            ];

    module(s)
            [
            class_<btRaycastVehicle::btVehicleTuning>("btVehicleTuning")
            .def(constructor<>())
            .def_readwrite("suspensionStiffness", &btRaycastVehicle::btVehicleTuning::m_suspensionStiffness)
            .def_readwrite("suspensionCompression", &btRaycastVehicle::btVehicleTuning::m_suspensionCompression)
            .def_readwrite("suspensionDamping", &btRaycastVehicle::btVehicleTuning::m_suspensionDamping)
            .def_readwrite("maxSuspensionTravelCm", &btRaycastVehicle::btVehicleTuning::m_maxSuspensionTravelCm)
            .def_readwrite("frictionSlip", &btRaycastVehicle::btVehicleTuning::m_frictionSlip)
            .def_readwrite("maxSuspensionForce", &btRaycastVehicle::btVehicleTuning::m_maxSuspensionForce)
            ];

    module(s)
            [
            class_<btWheelInfo>("btWheelInfo")
            ];

    module(s)
            [
            class_<btRaycastVehicle>("btRaycastVehicle")
            .def(constructor<const btRaycastVehicle::btVehicleTuning&, btRigidBody*, btVehicleRaycaster*>())
            .def("setCoordinateSystem", &btRaycastVehicle::setCoordinateSystem)
            .def("addWheel", &btRaycastVehicle::addWheel)
            .def("applyEngineForce", &btRaycastVehicle::applyEngineForce)
            .def("updateWheelTransform", &btRaycastVehicle::updateWheelTransform)
            .def("updateVehicle", &btRaycastVehicle::updateVehicle)
            ];
}
