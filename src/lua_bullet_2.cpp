/**
 * @file lua_bullet_2.cpp
 * @brief The second quarter of the Bullet-to-Lua registrations.
 *
 * Split out of lua_bullet.cpp purely to shorten the build; see
 * lua_bullet_p.h. The registrations appear here in the same order they had
 * in the original single function.
 */

#include "lua_bullet_p.h"

/**
 * @brief Registers the second quarter of the Bullet API.
 * @param s The Lua state to register in.
 */
void luaBindBulletPart2(lua_State *s) {
  using namespace luabind;

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtConeShape.html
      [class_<btConeShape, btConvexInternalShape>("btConeShape")
           .def(constructor<btScalar, btScalar>(), adopt(result))
           .def("getRadius", &btConeShape::getRadius)
	       //.def("setRadius", &btConeShape::setRadius)
           //.property("radius", &btConeShape::getRadius, &btConeShape::setRadius)
           .def("getHeight", &btConeShape::getHeight)
	       //.def("setHeight", &btConeShape::setHeight)
           //.property("height", &btConeShape::getHeight, &btConeShape::setHeight)
           .def("setConeUpIndex", &btConeShape::setConeUpIndex)
           .def("getConeUpIndex", &btConeShape::getConeUpIndex)
           .def("setLocalScaling", &btConeShape::setLocalScaling)
           .def("getLocalScaling", &btConeShape::getLocalScaling)
           .def("calculateLocalInertia", &btConeShape::calculateLocalInertia)
           .def("setMargin", &btConeShape::setMargin)
           .def("getMargin", &btConeShape::getMargin)
           .def("setImplicitShapeDimensions", &btConeShape::setImplicitShapeDimensions)
           .def("getImplicitShapeDimensions", &btConeShape::getImplicitShapeDimensions)
           .def("getAabb", &btConeShape::getAabb)
           .def("localGetSupportingVertexWithoutMargin", &btConeShape::localGetSupportingVertexWithoutMargin)
           .def("localGetSupportingVertex", &btConeShape::localGetSupportingVertex)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtConeShapeX.html
      [class_<btConeShapeX, btConeShape>("btConeShapeX")
           .def(constructor<btScalar, btScalar>(), adopt(result))
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtConeShapeZ.html
      [class_<btConeShapeZ, btConeShape>("btConeShapeZ")
           .def(constructor<btScalar, btScalar>(), adopt(result))
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtConvexInternalAabbCachingShape.html
      [class_<btConvexInternalAabbCachingShape>(
           "btConvexInternalAabbCachingShape")
           .def("recalcLocalAabb",
                &btConvexInternalAabbCachingShape::recalcLocalAabb)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtMultiSphereShape.html
      [class_<btMultiSphereShape, btConvexInternalAabbCachingShape>(
           "btMultiSphereShape")
           .def(constructor<const btVector3 *, const btScalar *, int>(),
                adopt(result))
           .def("getSphereCount", &btMultiSphereShape::getSphereCount)
           .def("getSpherePosition", &btMultiSphereShape::getSpherePosition)
           .def("getSphereRadius", &btMultiSphereShape::getSphereRadius)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtCylinderShape.html
      [class_<btCylinderShape, btConvexInternalShape>("btCylinderShape")
           .def("getHalfExtentsWithMargin",
                &btCylinderShape::getHalfExtentsWithMargin)
           .def("getHalfExtentsWithoutMargin",
                &btCylinderShape::getHalfExtentsWithoutMargin)
           .def("getAabb", &btCylinderShape::getAabb)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtCylinderShapeX.html
      [class_<btCylinderShapeX, btCylinderShape>("btCylinderShapeX")
           .def(constructor<const btVector3 &>(), adopt(result))
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtCylinderShapeZ.html
      [class_<btCylinderShapeZ, btCylinderShape>("btCylinderShapeZ")
           .def(constructor<const btVector3 &>(), adopt(result))
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtPolyhedralConvexShape.html
      [class_<btPolyhedralConvexShape, btConvexInternalShape>(
          "btPolyhedralConvexShape")
       // TODO .def("getConvexPolyhedron",
       // &btPolyhedralConvexShape::getConvexPolyhedron) needs definition of
       // btConvexPolyhedron not in the headers
           .def(tostring(const_self))
           .def(const_self == const_self)
  ];

  // not in the headers
  // https://pybullet.org/Bullet/BulletFull/classbtBox2dShape.html

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtBoxShape.html
      [class_<btBoxShape, btPolyhedralConvexShape>("btBoxShape")
           .def(constructor<const btVector3 &>(), adopt(result))
           .def("getHalfExtentsWithMargin",
                &btBoxShape::getHalfExtentsWithMargin)
           .def("getHalfExtentsWithoutMargin",
                &btBoxShape::getHalfExtentsWithoutMargin)
           .def("localGetSupportingVertexWithoutMargin",
                &btBoxShape::localGetSupportingVertexWithoutMargin)
           .def("setImplicitShapeDimensions",
                &btBoxShape::setImplicitShapeDimensions)
           .def("getImplicitShapeDimensions",
                &btBoxShape::getImplicitShapeDimensions)
           .def("setMargin", &btBoxShape::setMargin)
           .def("getMargin", &btBoxShape::getMargin)
           .def("calculateLocalInertia", &btBoxShape::calculateLocalInertia)
           .def("setLocalScaling", &btBoxShape::setLocalScaling)
           .def("getLocalScaling", &btBoxShape::getLocalScaling)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtPolyhedralConvexAabbCachingShape.html
      [class_<btPolyhedralConvexAabbCachingShape, btPolyhedralConvexShape>(
           "btPolyhedralConvexAabbCachingShape")
           .def("getNonvirtualAabb",
                &btPolyhedralConvexAabbCachingShape::getNonvirtualAabb)
           .def("recalcLocalAabb",
                &btPolyhedralConvexAabbCachingShape::recalcLocalAabb)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtBU__Simplex1to4.html
      [class_<btBU_Simplex1to4, btPolyhedralConvexAabbCachingShape>(
           "btBU_Simplex1to4")
           .def(constructor<>(), adopt(result))
           .def(constructor<const btVector3 &>(), adopt(result))
           .def(constructor<const btVector3 &, const btVector3 &>(),
                adopt(result))
           .def(constructor<const btVector3 &, const btVector3 &,
                            const btVector3 &>(),
                adopt(result))
           .def(constructor<const btVector3 &, const btVector3 &,
                            const btVector3 &, const btVector3 &>(),
                adopt(result))
           .def("reset", &btBU_Simplex1to4::reset)
           .def("addVertex", &btBU_Simplex1to4::addVertex)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtTetrahedronShapeEx.html
      [class_<btTetrahedronShapeEx, btBU_Simplex1to4>("btTetrahedronShapeEx")
           .def(constructor<>(), adopt(result))
           .def("setVertices", &btTetrahedronShapeEx::setVertices)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtConvexHullShape.html
      [class_<btConvexHullShape, btPolyhedralConvexAabbCachingShape>(
           "btConvexHullShape")
           .def(constructor<>(), adopt(result))
           .def(constructor<const btScalar *, int, int>(), adopt(result))
           .def("addPoint", &btConvexHullShape::addPoint)
           .def("getUnscaledPoints", (btVector3 * (btConvexHullShape::*)()) &
                                         btConvexHullShape::getUnscaledPoints)
           .def("getPoints", &btConvexHullShape::getPoints)
           .def("getScaledPoint", &btConvexHullShape::getScaledPoint)
           .def("getNumPoints", &btConvexHullShape::getNumPoints)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  // not defined in the headers
  // https://pybullet.org/Bullet/BulletFull/classbtConvexPointCloudShape.html

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtStridingMeshInterface.html
      [class_<btStridingMeshInterface>("btStridingMeshInterface")
           .def("calculateAabbBruteForce",
                &btStridingMeshInterface::calculateAabbBruteForce)

           .property("scaling", &btStridingMeshInterface::getScaling,
                     &btStridingMeshInterface::setScaling)
           .def("getScaling", &btStridingMeshInterface::getScaling)
           .def("setScaling", &btStridingMeshInterface::setScaling)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s) // https://pybullet.org/Bullet/BulletFull/classbtTriangleIndexVertexArray.html
      [class_<btTriangleIndexVertexArray, btStridingMeshInterface>(
           "btTriangleIndexVertexArray")
           .def("getIndexedMeshArray",
                (IndexedMeshArray & (btTriangleIndexVertexArray::*)()) &
                    btTriangleIndexVertexArray::getIndexedMeshArray)
           .def("addaddIndexedMesh",
                &btTriangleIndexVertexArray::addIndexedMesh)
           .def(tostring(const_self))
           .def(const_self == const_self)];}
