#ifdef WIN32_VC90
#pragma warning (disable : 4251)
#endif

#include "viewer.h"

#include <QColor>

#include "lua_converters.h"

#ifdef HAS_LUA_QT
#include "lua_register.h"
#endif

#include "objects/object.h"
#include "objects/objects.h"
#include "objects/plane.h"
#include "objects/cube.h"
#include "objects/sphere.h"
#include "objects/cylinder.h"
#include "objects/mesh3ds.h"

#include "objects/palette.h"

#include "objects/cam.h"
#ifdef HAS_QEXTSERIAL
#include "qserial.h"
#endif

#ifdef WIN32
#include <windows.h>
#endif

#include <GL/glut.h>

#include <QDebug>

#include <boost/exception/all.hpp>
#include <boost/throw_exception.hpp>
#include <boost/exception/info.hpp>

#include <luabind/tag_function.hpp>

typedef boost::error_info<struct tag_stack_str,std::string> stack_info;

using namespace std;

std::ostream& operator<<(std::ostream& ostream, const Viewer& v) {
  ostream << v.toString().toAscii().data();
  return ostream;
}

std::ostream& operator<<(std::ostream& ostream, const btVector3& v) {
  ostream << "btVector3(" << v.x() << ", " << v.y() << ", " << v.z() << ")";
  return ostream;
}

std::ostream& operator<<(std::ostream& ostream, const QString& s) {
  ostream << s.toAscii().data();
  return ostream;
}

std::ostream& operator<<(std::ostream& ostream, const QColor& c) {
  ostream << "QColor(\"" << c.name().toAscii().data() << "\")";
  return ostream;
}

#include <luabind/operator.hpp>
#include <luabind/adopt_policy.hpp>

struct btMotionState_wrap : public btMotionState, wrap_base
{
    btMotionState_wrap(const btTransform &, const btTransform &) {}
    btMotionState_wrap(const btTransform &) {}
};

struct btDefaultMotionState_wrap : public btDefaultMotionState, btMotionState_wrap
{
    btDefaultMotionState_wrap(const btTransform &startTrans, const btTransform &centerOfMassOffset) : btMotionState_wrap(startTrans, centerOfMassOffset) {}
    btDefaultMotionState_wrap(const btTransform &startTrans) : btMotionState_wrap(startTrans) {}

    virtual void getWorldTransform (btTransform &worldTrans) const {
      call_member<void>(this, "getWorldTransform", worldTrans);
    }

    virtual void setWorldTransform (const btTransform &worldTrans) {
      call_member<void>(this, "setWorldTransform", worldTrans);
    }
};

QString Viewer::toString() const {
  return QString("Viewer");
}

void Viewer::luaBind(lua_State *s) {
  using namespace luabind;

  open(s);

  module(s)
  [
   class_<Viewer>("Viewer")
   .def(constructor<>())
   .def("add", (void(Viewer::*)(Object *))&Viewer::addObject, adopt(_2))
   .def("remove", (void(Viewer::*)(Object *))&Viewer::removeObject, adopt(luabind::result))
   .def("addConstraint", (void(Viewer::*)(btTypedConstraint *))&Viewer::addConstraint, adopt(_2))
   .def("removeConstraint", (void(Viewer::*)(btTypedConstraint *))&Viewer::removeConstraint, adopt(_2))
   .def("createVehicleRaycaster", &Viewer::createVehicleRaycaster, adopt(luabind::result))
   .def("addVehicle", (void(Viewer::*)(btRaycastVehicle *))&Viewer::addVehicle, adopt(_2))
   .def("addShortcut", &Viewer::addShortcut, adopt(luabind::result))
   .def("removeShortcut", &Viewer::removeShortcut, adopt(luabind::result))
   .def("cam", (void(Viewer::*)(Cam *))&Viewer::setCamera, adopt(_2))
   .def("preDraw", (void(Viewer::*)(const luabind::object &fn))&Viewer::setCBPreDraw, adopt(luabind::result))
   .def("postDraw", (void(Viewer::*)(const luabind::object &fn))&Viewer::setCBPostDraw, adopt(luabind::result))
   .def("preSim", (void(Viewer::*)(const luabind::object &fn))&Viewer::setCBPreSim, adopt(luabind::result))
   .def("postSim", (void(Viewer::*)(const luabind::object &fn))&Viewer::setCBPostSim, adopt(luabind::result))
   .def("onCommand", (void(Viewer::*)(const luabind::object &fn))&Viewer::setCBOnCommand, adopt(luabind::result))
   .property("glShininess", &Viewer::getGLShininess, &Viewer::setGLShininess)
   .property("glSpecularColor", &Viewer::getGLSpecularColor, &Viewer::setGLSpecularColor)
   .property("glSpecularColor", &Viewer::getGLSpecularCol, &Viewer::setGLSpecularCol)
   .property("glLight0", &Viewer::getGLLight0, &Viewer::setGLLight0)
   .property("glLight1", &Viewer::getGLLight1, &Viewer::setGLLight1)

   .property("glAmbient", &Viewer::getGLAmbient, &Viewer::setGLAmbient)
   .property("glDiffuse", &Viewer::getGLDiffuse, &Viewer::setGLDiffuse)
   .property("glSpecular", &Viewer::getGLSpecular, &Viewer::setGLSpecular)
   .property("glModelAmbient", &Viewer::getGLModelAmbient, &Viewer::setGLModelAmbient)

   .property("glAmbient", &Viewer::getGLAmbientPercent, &Viewer::setGLAmbientPercent)
   .property("glDiffuse", &Viewer::getGLDiffusePercent, &Viewer::setGLDiffusePercent)
   .property("glSpecular", &Viewer::getGLSpecularPercent, &Viewer::setGLSpecularPercent)
   .property("glModelAmbient", &Viewer::getGLModelAmbientPercent, &Viewer::setGLModelAmbientPercent)

   .property("pre_sdl", &Viewer::getPreSDL, &Viewer::setPreSDL)
   .property("post_sdl", &Viewer::getPostSDL, &Viewer::setPostSDL)
   .def(tostring(const_self))
  ];

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
   class_<btMotionState_wrap>("btMotionState")
  ];

  // btDefaultMotionState
  module(s)
  [
   class_<btDefaultMotionState_wrap, btMotionState_wrap>("btDefaultMotionState")
   .def(constructor<const btTransform&, const btTransform&>())
   .def(constructor<const btTransform&>())
   .def("getWorldTransform", &btDefaultMotionState_wrap::getWorldTransform)
   .def("setWorldTransform", &btDefaultMotionState_wrap::setWorldTransform)
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
   .def("getMeshInterface", (btStridingMeshInterface*(btConvexTriangleMeshShape::*)())&btConvexTriangleMeshShape::getMeshInterface)
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
   class_<btCollisionObject>("btCollisionObject")
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
   // not in the headers .def("getRootCollisionShape", (btCollisionShape *(btCollisionObject::*)())&btCollisionObject::getRootCollisionShape)
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
   .def("getInterpolationWorldTransform", (btTransform&(btCollisionObject::*)())&btCollisionObject::getInterpolationWorldTransform)
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
   .def(constructor<btRigidBody&, btRigidBody&, const btVector3&, const btVector3&, const btVector3&, const btVector3&>())
   .def(constructor<btRigidBody&, btRigidBody&, const btTransform&, const btTransform&>())
   .def("setAxis", &btHingeConstraint::setAxis)
   .def("setLimit", &btHingeConstraint::setLimit)
   .def("setParam", &btHingeConstraint::setParam)
   .def("enableAngularMotor", &btHingeConstraint::enableAngularMotor)
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
   class_<btGeneric6DofSpringConstraint,btTypedConstraint>("btGeneric6DofSpringConstraint")
   .def(constructor<btRigidBody&, btRigidBody&, const btTransform&, const btTransform&, bool>())
   .def("enableSpring", &btGeneric6DofSpringConstraint::enableSpring)
   .def("setStiffness", &btGeneric6DofSpringConstraint::setStiffness)
   .def("setDamping", &btGeneric6DofSpringConstraint::setDamping)
   //.def("setEquilibriumPoint", &btGeneric6DofSpringConstraint::setEquilibriumPoint) // FIX ME: compilation error
   .def("setAxis", &btGeneric6DofSpringConstraint::setAxis)
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

  // QT helper classes

  module(s)
    [
     class_<QColor>("QColor")
     .def(constructor<>())
     .def(constructor<QString>())
     .def(constructor<int, int, int>())
     .def(constructor<int, int, int, int>())
     .property("r", &QColor::red, &QColor::setRed)
     .property("g", &QColor::green, &QColor::setGreen)
     .property("b", &QColor::blue, &QColor::setBlue)
   .def(tostring(self))
     ];

  module(s)
    [
     class_<QString>("QString")
     .def(constructor<>())
     .def(constructor<const char *>())
     .def(tostring(self))
     ];
}

void Viewer::addObject(Object* o) {
  addObject(o, o->getCol1(), o->getCol2());
  addConstraints(o->getConstraints());
}

void Viewer::removeObject(Object* o) {
  if (o->body != NULL)
    dynamicsWorld->removeRigidBody(o->body);

  _objects->remove(o);
}

void Viewer::addConstraint(btTypedConstraint *con) {
  dynamicsWorld->addConstraint(con, true);
  _constraints->insert(con);
}

void Viewer::removeConstraint(btTypedConstraint *con) {
  dynamicsWorld->removeConstraint(con);
  _constraints->remove(con);
}

void Viewer::addConstraints(QList<btTypedConstraint *> cons) {
  for (int i = 0; i < cons.size(); ++i) {
    addConstraint(cons[i]);
  }
}

btVehicleRaycaster* Viewer::createVehicleRaycaster() {
  return new btDefaultVehicleRaycaster(dynamicsWorld);
}

void Viewer::addVehicle(btRaycastVehicle *veh) {
  dynamicsWorld->addVehicle(veh);
  _raycast_vehicles->insert(veh);
}

void Viewer::luaBindInstance(lua_State *s) {
  using namespace luabind;

  globals(s)["v"] = this;
}

void report_errors(lua_State *L, int status)
{
  if ( status!=0 ) {
    std::cerr << "-- " << lua_tostring(L, -1) << std::endl;
    lua_pop(L, 1); // remove error message
  }
}

#define G 9.81f

using namespace qglviewer;

namespace {
void getAABB(QSet<Object *> *objects, btScalar aabb[6]) {
  btVector3 aabbMin, aabbMax;

  aabb[0] = -10; aabb[1] = -10; aabb[2] = -10;
  aabb[3] = 10; aabb[4] = 10; aabb[5] = 10;

  QSet<Object*>::iterator oi;
  for (oi = objects->begin(); oi != objects->end(); oi++) {
    Object *o = *oi;

    if (o->toString() != QString("Plane") && o->body) {
      btVector3 oaabbmin, oaabbmax;
      o->body->getAabb(oaabbmin, oaabbmax);

      // qDebug() << o->toString() << oaabbmin.x() << oaabbmin.y() << oaabbmin.z()
      //         << oaabbmax.x() << oaabbmax.y() << oaabbmax.z();

      for (int i = 0; i < 3; ++i) {
        aabb[  i] = qMin(aabb[  i], oaabbmin[  i]);
        aabb[3+i] = qMax(aabb[3+i], oaabbmax[3+i]);
      }
      }
  }

  // qDebug() << "getAABB()" << aabb[0] << aabb[1] << aabb[2] << aabb[3] << aabb[4] << aabb[5];
}
}

void Viewer::keyPressEvent(QKeyEvent *e) {
  int keyInt = e->key();
  Qt::Key key = static_cast<Qt::Key>(keyInt);

  if (key == Qt::Key_unknown) {
      qDebug() << "Unknown key from a macro probably";
      return;
  }

  // the user have clicked just and only the special keys Ctrl, Shift, Alt, Meta.
  if(key == Qt::Key_Control ||
      key == Qt::Key_Shift ||
      key == Qt::Key_Alt ||
      key == Qt::Key_Meta)
  {
      // qDebug() << "Single click of special key: Ctrl, Shift, Alt or Meta";
      // qDebug() << "New KeySequence:" << QKeySequence(keyInt).toString(QKeySequence::NativeText);
      // return;
  }

  // check for a combination of user clicks
  Qt::KeyboardModifiers modifiers = e->modifiers();
  QString keyText = e->text();
  // if the keyText is empty than it's a special key like F1, F5, ...
  //  qDebug() << "Pressed Key:" << keyText;

  QList<Qt::Key> modifiersList;
  if(modifiers & Qt::ShiftModifier)
      keyInt += Qt::SHIFT;
  if(modifiers & Qt::ControlModifier)
      keyInt += Qt::CTRL;
  if(modifiers & Qt::AltModifier)
      keyInt += Qt::ALT;
  if(modifiers & Qt::MetaModifier)
      keyInt += Qt::META;

  QString seq = QKeySequence(keyInt).toString(QKeySequence::NativeText);
  // qDebug() << "KeySequence:" << seq;

  if (_cb_shortcuts->contains(seq)) {
    try {
      luabind::call_function<void>(_cb_shortcuts->value(seq), _frameNum);
    } catch(const std::exception& ex){
      showLuaException(ex, QString("shortcut '%1' function").arg(seq));
    }

    return; // skip built in command if overridden by shortcut
  }

  switch (e->key()) {

  case Qt::Key_S :
    _simulate = !_simulate;
    emit simulationStateChanged(_simulate);
    break;
  case Qt::Key_P :
    _savePOV = !_savePOV;
    if(_savePOV){
      _firstFrame=_frameNum;
    }
    emit POVStateChanged(_savePOV);
    break;
  case Qt::Key_G :
    _savePNG = !_savePNG;
    emit PNGStateChanged(_savePNG);
    break;
  case Qt::Key_D :
    _deactivation = !_deactivation;
    emit deactivationStateChanged(_deactivation);
    break;
  case Qt::Key_R :
    parse(_scriptContent);
    break;
  case Qt::Key_C :
    resetCamView();
    break;
  default:
    QGLViewer::keyPressEvent(e);
  }
}

void Viewer::addObject(Object *o, int type, int mask) {
  _objects->insert(o);

  if (o->body != NULL) {
    if(!_deactivation){
      o->body->setActivationState(DISABLE_DEACTIVATION);
    }
    dynamicsWorld->addRigidBody(o->body, type, mask);
  }
}

void Viewer::addObjects(QList<Object *> ol, int type, int mask) {
  foreach (Object *o, ol) {
    addObject(o, type, mask);
  }
}

void Viewer::addObjects() {

}

Viewer::Viewer(QWidget *parent, bool savePNG, bool savePOV) : QGLViewer(parent)  {
  setAttribute(Qt::WA_DeleteOnClose);

  _objects = new QSet<Object *>();
  _constraints = new QSet<btTypedConstraint *>();
  _raycast_vehicles = new QSet<btRaycastVehicle *>();

  L = NULL;

  _savePNG = savePNG; _savePOV = savePOV; setSnapshotFormat("png");
  _simulate = false;
  _deactivation = true;

  collisionCfg = new btDefaultCollisionConfiguration();
  btBroadphaseInterface* broadphase = new btDbvtBroadphase();
  dynamicsWorld = new btDiscreteDynamicsWorld(new btCollisionDispatcher(collisionCfg), broadphase, new btSequentialImpulseConstraintSolver, collisionCfg);
  btCollisionDispatcher * dispatcher = static_cast<btCollisionDispatcher *>(dynamicsWorld ->getDispatcher());
  btGImpactCollisionAlgorithm::registerAlgorithm(dispatcher);

  dynamicsWorld->setGravity(btVector3(0.0f, -G, 0.0f));

  _frameNum = 0;
  _firstFrame = 0;

  _cb_shortcuts = new QHash<QString, luabind::object>();

  loadPrefs();

  _cam=NULL;

  // POV-Ray properties
  mPreSDL = "";
  mPostSDL = "";

  startAnimation();
}

void Viewer::close() {
  // qDebug() << "Viewer::close()";
  savePrefs();
  QGLViewer::close();
}

void Viewer::setCamera(Cam *cam) {
  _cam = cam;
  QGLViewer::setCamera( cam );
  // QGLViewer::setManipulatedFrame(cam->frame());
}

void Viewer::setSavePNG(bool png) {
  _savePNG = png;
}

void Viewer::setSavePOV(bool pov) {
  _savePOV = pov;
}

void Viewer::toggleSavePNG() {
  _savePNG = !_savePNG;
}

void Viewer::toggleSavePOV() {
  _savePOV = !_savePOV;
}

void Viewer::toggleDeactivation() {
  _deactivation = !_deactivation;
}

void Viewer::startSim() {
  _simulate = true;
}

void Viewer::stopSim() {
  _simulate = false;
}

void Viewer::restartSim() {
  parse(_scriptContent);
}

void Viewer::setScriptName(QString sn) {
  _scriptName = sn;
}

void Viewer::emitScriptOutput(const QString& out) {
  emit scriptHasOutput(out);
}

int Viewer::lua_print(lua_State* L) {

  Viewer* p = static_cast<Viewer*>(lua_touserdata(L, lua_upvalueindex(1)));

  if (p) {
    int n = lua_gettop(L);  /* number of arguments */

    int i;
    lua_getglobal(L, "tostring");
    for (i=1; i <= n; i++) {
      const char *s;
      lua_pushvalue(L, -1);  /* function to be called */
      lua_pushvalue(L, i);   /* value to print */
      lua_call(L, 1, 1);
      s = lua_tostring(L, -1);  /* get result */
      if (s == NULL)
        return luaL_error(L, LUA_QL("tostring") " must return a string to " LUA_QL("print"));
      // if (i>1) p->emitScriptOutput(QString("\t"));
      p->emitScriptOutput(QString(s));
      lua_pop(L, 1);  /* pop result */
    }

    // p->emitScriptOutput(QString("\n"));
  } else {
    return luaL_error(L, "stack has no thread ref", "");
  }

  return 0;
}

bool Viewer::parse(QString txt) {
  emit scriptStopped();

  QMutexLocker locker(&mutex);

  _parsing = true;
  _has_exception = false;

  _scriptContent = txt;

  bool animStarted = animationIsStarted();

  if (animStarted) {
      stopAnimation();
  }

  emit scriptStarts();

  if (L != NULL) {
    clear();
    // FIXME lua_gc(L, LUA_GCCOLLECT, 0); // collect garbage

    // invalidate function refs
    _cb_preDraw = luabind::object();
    _cb_postDraw = luabind::object();
    _cb_preSim = luabind::object();
    _cb_postSim = luabind::object();
    _cb_onCommand = luabind::object();

    lua_close(L);
  }

  // setup lua
  L = luaL_newstate();

  // open all standard Lua libs
  luaL_openlibs(L);

  // register all bpp classes
  Cam::luaBind(L);
  Object::luaBind(L);
  Objects::luaBind(L);
  Cube::luaBind(L);
  Cylinder::luaBind(L);
  Mesh3DS::luaBind(L);
  Palette::luaBind(L);
  Plane::luaBind(L);
  Sphere::luaBind(L);
  Viewer::luaBind(L);

#ifdef HAS_LUA_QT

#ifdef HAS_QEXTSERIAL
  QSerialPort::luaBind(L);
#endif

  // register some qt classes
  register_classes(L);

#endif

  luaBindInstance(L);

  lua_pushlightuserdata(L, (void*)this);
  lua_pushcclosure(L,  &Viewer::lua_print, 1);
  lua_setglobal(L, "print");

  int error = luaL_loadstring(L, txt.toAscii().constData())
    || lua_pcall(L, 0, LUA_MULTRET, 0);

  if (error) {
  lua_error = tr("error: %1").arg(lua_tostring(L, -1));

    if (lua_error.contains(QRegExp(tr("stopping$")))) {
      lua_error = tr("script stopped");
      qDebug() << "lua run : script stopped";
    } else {
      // qDebug() << QString("lua run : %1").arg(lua_error);
      emit scriptHasOutput(lua_error);
    }

    lua_pop(L, 1);  /* pop error message from the stack */
  } else {
    lua_error = tr("ok");
  }

  // report_errors(L, error);
  // lua_close(L);

  _frameNum = 0; // reset frames counter
  _firstFrame = 0;

  if (animStarted) {
      startAnimation();
  }

  // qDebug() << "Viewer::parse() end";

  _parsing = false;

  return (error ? false : true);
}

void Viewer::clear() {
  // qDebug() << "Viewer::clear() objects: " << _objects->size();

  // remove all objects
  QSet<Object *>::const_iterator i = _objects->constBegin();
  while (i != _objects->constEnd()) {
    if ((*i)->body != NULL)
      dynamicsWorld->removeRigidBody((*i)->body);
    ++i;
  }

  _objects->clear();

  // remove all contact manifolds
  for (int i = dynamicsWorld->getNumCollisionObjects()-1; i>=0 ;i--) {
    btCollisionObject* obj = dynamicsWorld->getCollisionObjectArray()[i];

    btRigidBody* body = btRigidBody::upcast(obj);
    if (body && body->getMotionState()) {
      delete body->getMotionState();
    }

    dynamicsWorld->removeCollisionObject( obj );

    delete obj;
  }

  // remove all constraints
  QSet<btTypedConstraint *>::const_iterator it = _constraints->constBegin();
  while (it != _constraints->constEnd()) {
    dynamicsWorld->removeConstraint(*it);
    ++it;
  }

  _constraints->clear();
  _cb_shortcuts->clear();
}

void Viewer::resetCamView() {

    camera()->setPosition(_initialCameraPosition);
    camera()->setOrientation(_initialCameraOrientation);
    updateGL();

}

void Viewer::loadPrefs() {
  QGLViewer::restoreStateFromFile();
}

void Viewer::savePrefs() {
  // qDebug() << "Viewer::savePrefs()";
  QGLViewer::saveStateToFile();
}

void Viewer::openPovFile() {
  QString file;
  QString fileMain;
  QString fileINI;
  QDir sceneDir("export");

  QString sceneName;
  if(!_scriptName.isEmpty()){
    sceneName=_scriptName;
  }else{
    sceneName="no_name.lua";
  }
  sceneDir.mkdir(qPrintable(sceneName));
  file.sprintf("export/%s/%s-%05d.inc", qPrintable(sceneName), qPrintable(sceneName), _frameNum);
  fileMain.sprintf("export/%s/%s.pov", qPrintable(sceneName), qPrintable(sceneName));
  fileINI.sprintf("export/%s/%s.ini", qPrintable(sceneName), qPrintable(sceneName));

  // qDebug() << "saving pov file:" << file;

  _fileINI = new QFile(fileINI);
  _fileINI->open(QFile::WriteOnly | QFile::Truncate);
  QTextStream *ini = new QTextStream(_fileINI);
  *ini << "; Animation INI file generated by Bullet Physics Playground" << endl << endl;
  *ini << "Input_File_Name=" << sceneName << ".pov" << endl;
  *ini << "Output_File_Name=" << sceneName << "-" << endl;
  *ini << "Output_to_File=On" << endl;
  *ini << "Pause_When_Done=Off" << endl;
  *ini << "Verbose=Off" << endl;
  *ini << "Display=On" << endl;
  *ini << "Width=720" << endl;
  *ini << "Width=480" << endl;
  *ini << "+FN" << endl;
  *ini << "+a +j0" << endl;

  // *ini << "Antialias_Threshold=0.3"

  *ini << "+L../../includes" << endl << endl;
  *ini << "Initial_Clock=" << _firstFrame << endl;
  *ini << "Final_Clock=" << _frameNum << endl;
  *ini << "Final_Frame=" << _frameNum << endl;

  *ini << "[LOW]"  << endl <<  "Width=320" << endl <<  "Height=200"  << endl << "Antialias=Off" << endl;
  *ini << "[MED]"  << endl <<  "Width=640" << endl <<  "Height=400"  << endl << "Antialias=Off" << endl;
  *ini << "[HIGH]" << endl << "Width=1280" << endl <<  "Height=800"  << endl << "Antialias=On" << endl << "Display=Off" << endl;
  *ini << "[HD]"   << endl << "Width=1920" << endl <<  "Height=1080" << endl << "Antialias=On" << endl << "Display=Off" << endl;

  if (_fileINI != NULL) {
    _fileINI->close();
  }

  _fileMain = new QFile(fileMain);
  _fileMain->open(QFile::WriteOnly | QFile::Truncate);

  QTextStream *smain = new QTextStream(_fileMain);
  *smain << "// Main POV file generated by Bullet Physics Playground" << endl << endl;
  *smain << "#include \"settings.inc\"" << endl << endl;
  *smain << "#include concat(concat(\"" << sceneName << "-\",str(clock,-5,0)),\".inc\")" << endl << endl;

  if (_fileMain != NULL) {
    _fileMain->close();
  }

  _file = new QFile(file);
  _file->open(QFile::WriteOnly | QFile::Truncate);

  _stream = new QTextStream(_file);

  *_stream << "// Include file generated by Bullet Physics Playground" << endl << endl;

  Vec pos = camera()->position();

  *_stream << "camera { " << endl;
  *_stream << "  location < " << pos.x << ", " << pos.y << ", " << pos.z << " >" << endl;
  *_stream << "  right -image_width/image_height*x" << endl;

  #define _USE_MATH_DEFINES
  if (_cam != NULL) {
    btVector3 vLook = _cam->getLookAt();
    *_stream << "  look_at < " << vLook.x() << ", " << vLook.y() << ", " << vLook.z();
    *_stream << "> angle " << _cam->fieldOfView() * 180.0 / M_PI << endl;
    //// qDebug() << vLook.x() << vLook.y() << vLook.z();
  } else {
    Vec vDir = camera()->viewDirection();
    *_stream << "  look_at < " << pos.x + vDir.x << ", " << pos.y + vDir.y << ", " << pos.z + vDir.z;
    *_stream << "> angle " << camera()->fieldOfView() * 180.0 / M_PI << endl;
     // qDebug() << pos.x + vDir.x << pos.y + vDir.y << pos.z + vDir.z;
  }
  *_stream << "  }" << endl << endl;
}

void Viewer::closePovFile() {
  if (_file != NULL) {
    _file->close();
  }
}

Viewer::~Viewer() {
  // qDebug() << "Viewer::~Viewer()";
  delete _objects;
  delete dynamicsWorld;
  delete collisionCfg;
}

void Viewer::computeBoundingBox() {
  getAABB(_objects, _aabb);

  btVector3 vmin(_aabb[0], _aabb[1], _aabb[2]);
  btVector3 vmax(_aabb[3], _aabb[4], _aabb[5]);

  float radius = (vmax - vmin).length() * 10.0f;
  // qDebug() << "setSceneRadius() " << radius;
  setSceneRadius(radius);

  btVector3 center = (vmin + vmax) / 2.0f;
  // qDebug() << "setSceneCenter() " << center.z() << center.y() << center.z();
  setSceneCenter(Vec(center.x(), center.y(), 0));

  // setSceneCenter(Vec());
}

void Viewer::init() {
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  glEnable(GL_DEPTH_TEST);
  glShadeModel(GL_SMOOTH);

  computeBoundingBox();

  if (!restoreStateFromFile()) {
    showEntireScene();
  }

  _gl_shininess = btScalar(25.0);
  _gl_specular_col = btVector4(.85f, .85f, .85f, 1.0f);

  _light0 = btVector4(200.0, 200.0, 200.0, 0.2);
  _light1 = btVector4(400.0, 400.0, 200.0, 0.1);

  _gl_ambient = btVector3(.1f, .1f, 1.0f);
  _gl_diffuse = btVector4(.9f, .9f, .9f, 1.0f);
  _gl_specular = btVector4(.85f, .85f, .85f, 1.0f);
  _gl_model_ambient = btVector4(.4f, .4f, 0.4f, 1.0f);

  _initialCameraPosition=camera()->position();
  _initialCameraOrientation=camera()->orientation();
}

void Viewer::draw() {

  if (_parsing) return;

  // Don't know if this is a good idea..
  // computeBoundingBox();

  QMutexLocker locker(&mutex);

  glDisable(GL_COLOR_MATERIAL);

  glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, _gl_shininess);

  GLfloat specular_color[4] = {
      _gl_specular_col.x(),
      _gl_specular_col.y(),
      _gl_specular_col.z(),
      _gl_specular_col.w()
  };

  glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR,  specular_color);

  GLfloat light0_pos[] = {_light0.x(), _light0.y(), _light0.z(), _light0.w()};
  GLfloat light1_pos[] = {_light1.x(), _light1.y(), _light1.z(), _light1.w()};

  GLfloat ambient[]  = { _gl_ambient.x(),  _gl_ambient.y(), _gl_ambient.z() };
  GLfloat diffuse[]  = { _gl_diffuse.x(),  _gl_diffuse.y(), _gl_diffuse.z() };
  GLfloat specular[] = {_gl_specular.x(), _gl_specular.y(), _gl_specular.z() };

  GLfloat lmodel_ambient[] = {
      _gl_model_ambient.x(),
      _gl_model_ambient.y(),
      _gl_model_ambient.z(), _gl_model_ambient.w() };
  GLfloat local_view[] = { 0.0 };

  glLightfv(GL_LIGHT0, GL_POSITION, light0_pos);
  glLightfv(GL_LIGHT1, GL_POSITION, light1_pos);

  glEnable(GL_LIGHT0);
  glEnable(GL_LIGHT1);

  glLightModelfv(GL_LIGHT_MODEL_AMBIENT, lmodel_ambient);

  glEnable(GL_LIGHTING);

  glLightfv(GL_LIGHT0, GL_AMBIENT, ambient);
  glLightfv(GL_LIGHT0, GL_DIFFUSE, diffuse);
  glLightfv(GL_LIGHT0, GL_SPECULAR, specular);

  glLightModelfv(GL_LIGHT_MODEL_LOCAL_VIEWER, local_view);

  if (_cb_preDraw) {
    try {
      luabind::call_function<void>(_cb_preDraw, _frameNum);
    } catch(const std::exception& e){
    showLuaException(e, "v:preDraw()");
  }
  }

  if (manipulatedFrame() != NULL) {
    glPushMatrix();
    glMultMatrixd(manipulatedFrame()->matrix());
  }

  if (_savePOV) {
    openPovFile();

    if (!mPreSDL.isEmpty()) {
      *_stream << mPreSDL;
    }
  }

  // qDebug() << "Number of objects:" << _objects->size();
  foreach (Object *o, *_objects) {
    try {
      if (_savePOV) {
        o->render(_stream);
      } else {
        o->render(NULL);
      }
    } catch(const std::exception& e){
      showLuaException(e, "object:render()");
    }
  }

  if (_savePOV) {
    if (!mPostSDL.isEmpty()) {
      *_stream << mPostSDL;
    }
    closePovFile();
  }

  if (manipulatedFrame() != NULL) {
    glPopMatrix();
  }
}

void Viewer::setCBPreDraw(const luabind::object &fn) {
  if(luabind::type(fn) == LUA_TFUNCTION) {
    _cb_preDraw = fn;
  }
}

void Viewer::setCBPostDraw(const luabind::object &fn) {
  if(luabind::type(fn) == LUA_TFUNCTION) {
    _cb_postDraw = fn;
  }
}

void Viewer::setCBPreSim(const luabind::object &fn) {
  if(luabind::type(fn) == LUA_TFUNCTION) {
    _cb_preSim = fn;
  }
}

void Viewer::setCBPostSim(const luabind::object &fn) {
  if(luabind::type(fn) == LUA_TFUNCTION) {
    _cb_postSim = fn;
  }
}

void Viewer::setCBOnCommand(const luabind::object &fn) {
  if(luabind::type(fn) == LUA_TFUNCTION) {
    _cb_onCommand = fn;
  }
}

void Viewer::addShortcut(const QString &keys, const luabind::object &fn) {
  if(luabind::type(fn) == LUA_TFUNCTION) {
    _cb_shortcuts->insert(keys, fn);
  }
}

void Viewer::removeShortcut(const QString &keys) {
  _cb_shortcuts->remove(keys);
}

void Viewer::postDraw() {
  QGLViewer::postDraw();

  if(_cb_postDraw) {
    try {
      luabind::call_function<void>(_cb_postDraw, _frameNum);
    } catch(const std::exception& e){
    showLuaException(e, "v:postDraw()");
    }
  }

  // Red dot when EventRecorder is active

  if (animationIsStarted()) {
    startScreenCoordinatesSystem();
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glPointSize(12.0);
    glColor3f(1.0, 0.0, 0.0);
    glBegin(GL_POINTS);
    glVertex2i(width()-20, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
    // restore foregroundColor
    qglColor(foregroundColor());
  }

  if (_simulate) {
    startScreenCoordinatesSystem();
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glPointSize(12.0);
    glColor3f(0.0, 1.0, 0.0);
    glBegin(GL_POINTS);
    glVertex2i(width()-40, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
    // restore foregroundColor
    qglColor(foregroundColor());
  }

  if (_savePNG) {
    startScreenCoordinatesSystem();
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glPointSize(12.0);
    glColor3f(0.0, 0.0, 1.0);
    glBegin(GL_POINTS);
    glVertex2i(width()-60, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
    // restore foregroundColor
    qglColor(foregroundColor());
  }

  if (_savePOV) {
    startScreenCoordinatesSystem();
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glPointSize(12.0);
    glColor3f(0.0, 1.0, 1.0);
    glBegin(GL_POINTS);
    glVertex2i(width()-80, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
    // restore foregroundColor
    qglColor(foregroundColor());
  }

    if (_deactivation) {
    startScreenCoordinatesSystem();
    glDisable(GL_LIGHTING);
    glDisable(GL_DEPTH_TEST);
    glPointSize(12.0);
    glColor3f(1.0, 1.0, 0.0);
    glBegin(GL_POINTS);
    glVertex2i(width()-100, 20);
    glEnd();
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);
    stopScreenCoordinatesSystem();
    // restore foregroundColor
    qglColor(foregroundColor());
  }

}

void Viewer::startAnimation() {
  _time.start();
  QGLViewer::startAnimation();
}

void Viewer::stopAnimation() {
  QGLViewer::stopAnimation();
  //  updateGL();
}

void Viewer::animate() {
  QMutexLocker locker(&mutex);

  if (_has_exception) {
    return;
  }

  // emitScriptOutput(QString("_frameNum = %1").arg(_frameNum));

  // emitScriptOutput("Viewer::animate() begin");

  // Find the time elapsed between last time
  float nbSecsElapsed = 0.08f; // 25 pics/sec
  // float nbSecsElapsed = 1.0 / 24.0;
  //  float nbSecsElapsed = _time.elapsed()/10.0f;

  if (_savePNG) {
    QDir sceneDir("screenshots");
    QString file;
    if(!_scriptName.isEmpty()){
      sceneDir.mkdir(qPrintable(_scriptName));
      file.sprintf("screenshots/%s/%s-%05d.png", qPrintable(_scriptName), qPrintable(_scriptName), _frameNum);
    }else{
      sceneDir.mkdir("no_name");
      file.sprintf("screenshots/no_name/no_name-%05d.png", _frameNum);
    }
    saveSnapshot(file, true);
  }

  if (_simulate) {

    if(_cb_preSim) {
      try {
        luabind::call_function<void>(_cb_preSim, _frameNum);
      } catch(const std::exception& e){
        showLuaException(e, "v:preSim()");
      }
    }

    dynamicsWorld->stepSimulation(nbSecsElapsed, 10);

    if(_cb_postSim) {
      try {
        luabind::call_function<void>(_cb_postSim, _frameNum);
      } catch(const std::exception& e){
        showLuaException(e, "v:postSim()");
      }
    }

    if (_frameNum > 10)
      emit postDrawShot(_frameNum);

     _frameNum++;
  }

  // Restart the elapsed time counter
  _time.restart();

  // emitScriptOutput("Viewer::animate() end");
}

void Viewer::command(QString cmd) {
  QMutexLocker locker(&mutex);

  // emitScriptOutput("Viewer::command() begin");

  if(_cb_onCommand) {
    try {
      luabind::call_function<void>(_cb_onCommand, cmd);
    } catch(const std::exception& e){
      showLuaException(e, "v:onCommand()");
    }
  }

  // emitScriptOutput("Viewer::command() end");
}

void Viewer::showLuaException(const std::exception &e, const QString& context) {
  _has_exception = true;

  if ( std::string const *stack = boost::get_error_info<stack_info>(e) ) {
    std::cout << stack << std::endl;
  }

  // the error message should be on top of the stack
  QString luaWhat = QString("%1").arg(lua_tostring(L, -1));

  emitScriptOutput(QString("%1 in %2: %3").arg(e.what()).arg(context).arg(luaWhat));
}

void Viewer::setGLShininess(const btScalar &s) {
  _gl_shininess = s;
}

btScalar Viewer::getGLShininess() const {
  return _gl_shininess;
}

void Viewer::setGLSpecularColor(const btVector4 &col) {
  _gl_specular_col = col;
}

btVector4 Viewer::getGLSpecularColor() const {
  return _gl_specular_col;
}

void Viewer::setGLSpecularCol(const btScalar col) {
  _gl_specular_col = btVector4(col, col, col, col);
}

btScalar Viewer::getGLSpecularCol() const {
  return _gl_specular_col.length();
}

void Viewer::setGLLight0(const btVector4 &pos) {
    _light0 = pos;
}

btVector4 Viewer::getGLLight0() const {
    return _light0;
}

void Viewer::setGLLight1(const btVector4 &pos) {
    _light1 = pos;
}

btVector4 Viewer::getGLLight1() const {
    return _light1;
}

// Vector

void Viewer::setGLAmbient(const btVector3 &am) {
    _gl_ambient = am;
}

btVector3 Viewer::getGLAmbient() const {
    return _gl_ambient;
}

void Viewer::setGLDiffuse(const btVector4 &col) {
  _gl_diffuse = col;
}

btVector4 Viewer::getGLDiffuse() const {
  return _gl_diffuse;
}

void Viewer::setGLSpecular(const btVector4 &col) {
  _gl_specular = col;
}

btVector4 Viewer::getGLSpecular() const {
  return _gl_specular;
}

void Viewer::setGLModelAmbient(const btVector4 &am) {
    _gl_model_ambient = am;
}

btVector4 Viewer::getGLModelAmbient() const {
    return _gl_model_ambient;
}

// Percent

void Viewer::setGLAmbientPercent(const btScalar am) {
    _gl_ambient = btVector3(am, am, am);
}

btScalar Viewer::getGLAmbientPercent() const {
    return _gl_ambient.length();
}

void Viewer::setGLDiffusePercent(const btScalar col) {
  _gl_diffuse = btVector4(col, col, col, 1);
}

btScalar Viewer::getGLDiffusePercent() const {
  return _gl_diffuse.length();
}

void Viewer::setGLSpecularPercent(const btScalar col) {
  _gl_specular = btVector4(col, col, col, 1);
}

btScalar Viewer::getGLSpecularPercent() const {
  return _gl_specular.length();
}

void Viewer::setGLModelAmbientPercent(const btScalar am) {
    _gl_model_ambient = btVector4(am, am, am, 1);
}

btScalar Viewer::getGLModelAmbientPercent() const {
    return _gl_model_ambient.length();
}

// POV-Ray properties

void Viewer::setPreSDL(const QString &preSDL) {
    mPreSDL = preSDL;
}

QString Viewer::getPreSDL() const {
    return mPreSDL;
}

void Viewer::setPostSDL(const QString &postSDL) {
    mPostSDL = postSDL;
}

QString Viewer::getPostSDL() const {
    return mPostSDL;
}

