/**
 * @file plane.cpp
 * @brief Implementation of the infinite ground plane.
 */

#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "plane.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <QDebug>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

Plane::Plane(const btVector3 &dim, btScalar nConst, btScalar psize) {
  init(dim.getX(), dim.getY(), dim.getZ(), nConst, psize);
}

Plane::Plane(btScalar nx, btScalar ny, btScalar nz, btScalar nConst,
             btScalar psize) {
  init(nx, ny, nz, nConst, psize);
}

void Plane::init(btScalar nx, btScalar ny, btScalar nz, btScalar nConst,
                 btScalar psize) {
  size = psize;

  shape = new btStaticPlaneShape(btVector3(nx, ny, nz), nConst);

  btQuaternion qtn;
  btTransform trans;
  btDefaultMotionState *motionState = nullptr;

  trans.setIdentity();
  qtn.setEuler(0.0, 0.0, 0.0);
  trans.setRotation(qtn);
  trans.setOrigin(btVector3(0, 0, 0));
  motionState = new btDefaultMotionState(trans);

  body = new btRigidBody(0.0, motionState, shape, btVector3(.0, .0, .0));
}

Plane::~Plane() {
  // (not a shape or motion state a script handed in: Lua owns those)
  deleteOwnShape(true);
}

void Plane::setPigment(const QString &pigment) { mPigment = pigment; }

/**
 * @brief Works out the square the plane is drawn as.
 *
 * render() draws this square and povPigment() lays a texture on it, so both
 * ask for it here rather than each deriving its own.
 *
 * @param shape  The plane's collision shape.
 * @param size   Half the edge length of the square.
 * @param normal Receives the plane normal.
 * @param corner Receives the corner the texture's origin sits on.
 * @param edge0  Receives the edge from that corner along the texture's u axis.
 * @param edge1  Receives the edge from that corner along its v axis.
 */
static void planeSquare(const btCollisionShape *shape, btScalar size,
                        btVector3 &normal, btVector3 &corner, btVector3 &edge0,
                        btVector3 &edge1) {
  const btStaticPlaneShape *staticPlaneShape =
      static_cast<const btStaticPlaneShape *>(shape);
  normal = staticPlaneShape->getPlaneNormal();

  btVector3 vec0, vec1;
  btPlaneSpace1(normal, vec0, vec1);

  edge0 = vec0 * (size * 2);
  edge1 = vec1 * (size * 2);
  corner = normal * staticPlaneShape->getPlaneConstant() - vec0 * size -
           vec1 * size;
}

void Plane::povPigment(QTextStream *s) const {
  if (s == nullptr || getTexture().isEmpty()) {
    Object::povPigment(s);
    return;
  }

  btVector3 normal, corner, edge0, edge1;
  planeSquare(shape, size, normal, corner, edge0, edge1);

  // An image_map covers x and y from 0 to 1 and repeats outside that, so the
  // matrix carries that unit square onto the square the view draws: the image
  // lands on the same patch of plane in both, and tiles away to the horizon
  // from there. POV-Ray's Z points the other way to ours (see
  // Object::povMatrixFromGL), hence the negated Z on each column.
  QString xform;
  QTextStream m(&xform);
  m << "matrix <" << edge0[0] << "," << edge0[1] << "," << -edge0[2] << ","
    << " " << edge1[0] << "," << edge1[1] << "," << -edge1[2] << ","
    << " " << normal[0] << "," << normal[1] << "," << -normal[2] << ","
    << " " << corner[0] << "," << corner[1] << "," << -corner[2] << ">";
  m.flush();

  povImageMap(s, QString(), QString(), xform);
}

void Plane::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<Plane, Object>("Plane")
                .def(constructor<>(), adopt(result))
                .def(constructor<btScalar>(), adopt(result))
                .def(constructor<btScalar, btScalar>(), adopt(result))
                .def(constructor<btScalar, btScalar, btScalar>(), adopt(result))
                .def(constructor<btScalar, btScalar, btScalar, btScalar>(),
                     adopt(result))
                .def(constructor<btScalar, btScalar, btScalar, btScalar,
                                 btScalar>(),
                     adopt(result))
                .def(constructor<const btVector3 &, btScalar, btScalar>(),
                     adopt(result))
                .def(tostring(const_self))
                .def(const_self == const_self)];
}

QString Plane::toString() const { return QString("Plane"); }

void Plane::toPOV(QTextStream *s) const {
  if (body != nullptr && body->getMotionState() != nullptr) {
    btTransform trans;

    body->getMotionState()->getWorldTransform(trans);
    trans.getOpenGLMatrix(matrix);
    povMatrixFromGL(matrix, matrix);
  }

  if (s != nullptr) {
    if (mPreSDL.isNull()) {
      const btStaticPlaneShape *staticPlaneShape =
          static_cast<const btStaticPlaneShape *>(shape);
      const btVector3 &planeNormal = staticPlaneShape->getPlaneNormal();
      btScalar planeConst = staticPlaneShape->getPlaneConstant();

      *s << "plane { <" << planeNormal[0] << ", " << planeNormal[1] << ", "
         << -planeNormal[2] << ">, " << planeConst << "\n";
    } else {
      *s << mPreSDL << "\n";
    }

    if (!mSDL.isNull()) {
      *s << mSDL << "\n";
    } else {
      povPigment(s);
    }

    *s << "  matrix <" << matrix[0] << "," << matrix[1] << "," << matrix[2]
       << "," << "\n"
       << "          " << matrix[4] << "," << matrix[5] << "," << matrix[6]
       << "," << "\n"
       << "          " << matrix[8] << "," << matrix[9] << "," << matrix[10]
       << "," << "\n"
       << "          " << matrix[12] << "," << matrix[13] << "," << matrix[14]
       << ">" << "\n";

    if (mPostSDL.isNull()) {
      *s << "}" << "\n"
         << "\n";
    } else {
      *s << mPostSDL << "\n";
    }
  }
}

void Plane::renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) {
  Q_UNUSED(minaabb)
  Q_UNUSED(maxaabb)

  // qDebug() << "Plane::renderInLocalFrame";

  btVector3 planeNormal, corner, edge0, edge1;
  planeSquare(shape, size, planeNormal, corner, edge0, edge1);

  // The 4 corners of the square, not the 4 edge-midpoints (which would
  // triangulate into a diamond instead of a rectangle). A texture covers the
  // square once, the same way povPigment() lays it on the exported plane.
  btVector3 pt0 = corner;
  btVector3 pt1 = corner + edge0;
  btVector3 pt2 = corner + edge0 + edge1;
  btVector3 pt3 = corner + edge1;

  // glTexCoord applies to the vertex that follows it, so the two travel
  // together.
  auto corner_v = [](const btVector3 &p, float u, float v) {
    glTexCoord2f(u, v);
    glVertex3fv(p);
  };

  glApplyColor();

  glBegin(GL_LINE_LOOP);
  corner_v(pt0, 0, 0);
  corner_v(pt1, 1, 0);
  corner_v(pt2, 1, 1);
  corner_v(pt3, 0, 1);
  glEnd();

  glBegin(GL_TRIANGLES);
  glNormal3fv(planeNormal);
  corner_v(pt0, 0, 0);
  corner_v(pt1, 1, 0);
  corner_v(pt2, 1, 1);
  corner_v(pt2, 1, 1);
  corner_v(pt1, 1, 0);
  corner_v(pt0, 0, 0);
  corner_v(pt2, 1, 1);
  corner_v(pt3, 0, 1);
  corner_v(pt0, 0, 0);
  corner_v(pt0, 0, 0);
  corner_v(pt3, 0, 1);
  corner_v(pt2, 1, 1);
  glEnd();
}

void Plane::render(btVector3 &minaabb, btVector3 &maxaabb) {
  renderInLocalFrame(minaabb, maxaabb);
}

btScalar Plane::getSize() const { return size; }
