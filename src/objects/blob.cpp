/**
 * @file blob.cpp
 * @brief Implementation of the blob primitive.
 */

#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "blob.h"

#ifdef WIN32
#include <windows.h>
#endif

#include "glutils.h"

#include <QDebug>

#include <cmath>
#include <utility>

#include <BulletCollision/CollisionShapes/btConvexHullShape.h>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

Blob::Blob(btScalar threshold, btScalar mass) {
  m_threshold = threshold;

  // Start with an empty compound shape
  shape = new btCompoundShape();

  btQuaternion qtn;
  btTransform trans;
  btDefaultMotionState *motionState = nullptr;

  trans.setIdentity();
  qtn.setEuler(0.0, 0.0, 0.0);
  trans.setRotation(qtn);
  trans.setOrigin(btVector3(0, 0, 0));
  motionState = new btDefaultMotionState(trans);

  btVector3 inertia;
  shape->calculateLocalInertia(mass, inertia);
  body = new btRigidBody(mass, motionState, shape, inertia);
}

Blob::~Blob() {
  deleteOwnShape(true);
}

void Blob::addSphereComponent(const btVector3 &center, btScalar radius,
                              btScalar strength) {
  BlobComponent comp;
  comp.center = center;
  comp.radius = radius;
  comp.strength = strength;
  comp.isCylinder = false;
  comp.axis = btVector3(0, 1, 0);
  comp.height = 0;
  m_components.push_back(comp);
  rebuild();
}

void Blob::addCylinderComponent(const btVector3 &center,
                                const btVector3 &axis, btScalar radius,
                                btScalar height, btScalar strength) {
  BlobComponent comp;
  comp.center = center;
  comp.radius = radius;
  comp.strength = strength;
  comp.isCylinder = true;
  comp.axis = axis.normalized();
  comp.height = height;
  m_components.push_back(comp);
  rebuild();
}

void Blob::setThreshold(btScalar threshold) {
  m_threshold = threshold;
  if (!m_components.empty())
    rebuild();
}

// POV-Ray's field of one component: strength * (1 - (d/r)^2)^2 at distance
// d < r from the centre, or from the segment of a cylinder component (which
// so has hemispherical caps), 0 further out.
static btScalar componentField(const BlobComponent &c, const btVector3 &p) {
  btVector3 nearest = c.center;
  if (c.isCylinder && c.height > 0) {
    btScalar t = (p - c.center).dot(c.axis);
    t = t < 0 ? 0 : (t > c.height ? c.height : t);
    nearest = c.center + c.axis * t;
  }
  const btScalar d2 = (p - nearest).length2();
  const btScalar r2 = c.radius * c.radius;
  if (d2 >= r2)
    return 0;
  const btScalar k = 1 - d2 / r2;
  return c.strength * k * k;
}

btScalar Blob::field(const btVector3 &p) const {
  btScalar sum = 0;
  for (const auto &comp : m_components)
    sum += componentField(comp, p);
  return sum;
}

void Blob::rebuild() {
  m_verts.clear();
  m_norms.clear();

  // The field is 0 outside every component's reach.
  btVector3 lo(BT_LARGE_FLOAT, BT_LARGE_FLOAT, BT_LARGE_FLOAT);
  btVector3 hi = -lo;
  for (const auto &comp : m_components) {
    const btVector3 r(comp.radius, comp.radius, comp.radius);
    const btVector3 end = comp.isCylinder ? comp.center + comp.axis * comp.height
                                          : comp.center;
    lo.setMin(comp.center - r);
    lo.setMin(end - r);
    hi.setMax(comp.center + r);
    hi.setMax(end + r);
  }

  if (!m_components.empty()) {
    // Sample the field on a grid one cell larger than that box all round,
    // as field minus threshold: positive inside the surface.
    const int cells = 32; // along the longest side
    const btVector3 size = hi - lo;
    const btScalar h = size[size.maxAxis()] / cells;
    lo -= btVector3(h, h, h);
    int n[3];
    for (int i = 0; i < 3; ++i)
      n[i] = int(std::ceil(size[i] / h)) + 3;
    auto at = [&](int x, int y, int z) {
      return lo + btVector3(x * h, y * h, z * h);
    };
    std::vector<btScalar> f(size_t(n[0]) * n[1] * n[2]);
    auto idx = [&](int x, int y, int z) { return (size_t(z) * n[1] + y) * n[0] + x; };
    for (int z = 0; z < n[2]; ++z)
      for (int y = 0; y < n[1]; ++y)
        for (int x = 0; x < n[0]; ++x)
          f[idx(x, y, z)] = field(at(x, y, z)) - m_threshold;

    // The outward normal: the field falls going outwards.
    auto normal = [&](const btVector3 &p) {
      const btScalar e = h * 0.5f;
      btVector3 g(field(p + btVector3(e, 0, 0)) - field(p - btVector3(e, 0, 0)),
                  field(p + btVector3(0, e, 0)) - field(p - btVector3(0, e, 0)),
                  field(p + btVector3(0, 0, e)) - field(p - btVector3(0, 0, e)));
      return g.fuzzyZero() ? g : -g.normalized();
    };
    auto addTriangle = [&](const btVector3 &a, const btVector3 &b, const btVector3 &c,
                    const btVector3 &out) {
      btVector3 v[3] = {a, b, c};
      if ((b - a).cross(c - a).dot(out) < 0)
        std::swap(v[1], v[2]);
      for (const auto &p : v) {
        const btVector3 nn = normal(p);
        for (int i = 0; i < 3; ++i) {
          m_verts.push_back(p[i]);
          m_norms.push_back(nn[i]);
        }
      }
    };

    // Marching tetrahedra: each cell split into the six tetrahedra around
    // its diagonal from corner 0 (0,0,0) to corner 6 (1,1,1), the same way in
    // every cell so neighbouring cells share faces.
    static const int corner[8][3] = {{0, 0, 0}, {1, 0, 0}, {1, 1, 0}, {0, 1, 0},
                                     {0, 0, 1}, {1, 0, 1}, {1, 1, 1}, {0, 1, 1}};
    static const int tet[6][4] = {{0, 1, 2, 6}, {0, 3, 2, 6}, {0, 3, 7, 6},
                                  {0, 4, 7, 6}, {0, 4, 5, 6}, {0, 1, 5, 6}};
    for (int z = 0; z + 1 < n[2]; ++z)
      for (int y = 0; y + 1 < n[1]; ++y)
        for (int x = 0; x + 1 < n[0]; ++x)
          for (const auto &t : tet) {
            btVector3 p[4];
            btScalar v[4];
            std::vector<int> in, out;
            for (int k = 0; k < 4; ++k) {
              const int *o = corner[t[k]];
              p[k] = at(x + o[0], y + o[1], z + o[2]);
              v[k] = f[idx(x + o[0], y + o[1], z + o[2])];
              (v[k] > 0 ? in : out).push_back(k);
            }
            if (in.empty() || out.empty())
              continue;
            auto cut = [&](int a, int b) {
              return p[a] + (p[b] - p[a]) * (v[a] / (v[a] - v[b]));
            };
            btVector3 inC(0, 0, 0), outC(0, 0, 0);
            for (int k : in) inC += p[k];
            for (int k : out) outC += p[k];
            const btVector3 dir = outC / btScalar(out.size()) - inC / btScalar(in.size());
            if (in.size() == 1)
              addTriangle(cut(in[0], out[0]), cut(in[0], out[1]), cut(in[0], out[2]), dir);
            else if (out.size() == 1)
              addTriangle(cut(in[0], out[0]), cut(in[1], out[0]), cut(in[2], out[0]), dir);
            else {
              const btVector3 a = cut(in[0], out[0]), b = cut(in[0], out[1]),
                              c = cut(in[1], out[1]), d = cut(in[1], out[0]);
              addTriangle(a, b, c, dir);
              addTriangle(a, c, d, dir);
            }
          }
  }

  // Collide with the convex hull of the surface; with no surface, with
  // nothing (an empty compound shape).
  btCollisionShape *newShape;
  if (m_verts.empty()) {
    newShape = new btCompoundShape();
  } else {
    btConvexHullShape *hull = new btConvexHullShape();
    for (size_t i = 0; i < m_verts.size(); i += 3)
      hull->addPoint(btVector3(m_verts[i], m_verts[i + 1], m_verts[i + 2]), false);
    hull->recalcLocalAabb();
    hull->optimizeConvexHull();
    newShape = hull;
  }
  deleteOwnShape(false);
  shape = newShape;
  body->setCollisionShape(shape);

  // Recalculate inertia for the new shape, keeping the mass
  setMass(getMass());
}

void Blob::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<Blob, Object>("Blob")
                .def(constructor<>(), adopt(result))
                .def(constructor<btScalar, btScalar>(), adopt(result))
                .def("addSphereComponent", &Blob::addSphereComponent)
                .def("addCylinderComponent", &Blob::addCylinderComponent)
                .property("threshold", &Blob::getThreshold,
                          &Blob::setThreshold)
                .def("componentCount", &Blob::componentCount)
                .def(tostring(const_self))
                .def(const_self == const_self)];
}

QString Blob::toString() const { return QString("Blob"); }

void Blob::toPOV(QTextStream *s) const {
  if (body != nullptr && body->getMotionState() != nullptr) {
    btTransform trans;

    body->getMotionState()->getWorldTransform(trans);
    trans.getOpenGLMatrix(matrix);
    povMatrixFromGL(matrix, matrix);
  }

  if (s != nullptr) {
    if (mPreSDL.isNull()) {
      *s << "blob { threshold " << m_threshold << "\n";
      for (const auto &comp : m_components) {
        if (comp.isCylinder) {
          *s << "  cylinder { <" << comp.center.x() << ", " << comp.center.y()
             << ", " << comp.center.z() << ">, <"
             << (comp.center.x() + comp.axis.x() * comp.height) << ", "
             << (comp.center.y() + comp.axis.y() * comp.height) << ", "
             << (comp.center.z() + comp.axis.z() * comp.height) << ">, "
             << comp.radius << ", strength " << comp.strength << " }\n";
        } else {
          *s << "  sphere { <" << comp.center.x() << ", " << comp.center.y()
             << ", " << comp.center.z() << ">, " << comp.radius
             << ", strength " << comp.strength << " }\n";
        }
      }
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

    if (mBoundShape != nullptr) {
      *s << "  bounded_by { ";
      if (dynamic_cast<btSphereShape *>(mBoundShape)) {
        btSphereShape *sphere = static_cast<btSphereShape *>(mBoundShape);
        *s << "sphere { <0,0,0>, " << sphere->getRadius() << " }";
      } else if (dynamic_cast<btBoxShape *>(mBoundShape)) {
        btBoxShape *box = static_cast<btBoxShape *>(mBoundShape);
        btVector3 half = box->getHalfExtentsWithMargin();
        *s << "box { <" << -half.x() << ", " << -half.y() << ", " << -half.z()
           << ">, <" << half.x() << ", " << half.y() << ", " << half.z()
           << "> }";
      } else {
        *s << "sphere { <0,0,0>, 0 }";
      }
      *s << "}" << "\n";
    }

    if (mNoImage)
      *s << "  no_image" << "\n";
    if (mNoReflection)
      *s << "  no_reflection" << "\n";
    if (mDoubleIlluminate)
      *s << "  double_illuminate" << "\n";
    if (mHollow)
      *s << "  hollow" << "\n";
    if (!mCastShadow)
      *s << "  no_shadow" << "\n";

    QString photons = getPovPhotons();
    if (!photons.isEmpty())
      *s << photons;

    if (!mPreMatrixSDL.isNull())
      *s << mPreMatrixSDL << "\n";

    if (mPostSDL.isNull()) {
      *s << "}" << "\n"
         << "\n";
    } else {
      *s << mPostSDL << "\n";
    }
  }
}

void Blob::renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) {
  Q_UNUSED(minaabb)
  Q_UNUSED(maxaabb)

  if (m_verts.empty()) return;

  glApplyColor();

  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_NORMAL_ARRAY);
  glVertexPointer(3, GL_DOUBLE, 0, m_verts.data());
  glNormalPointer(GL_DOUBLE, 0, m_norms.data());
  glDrawArrays(GL_TRIANGLES, 0, (GLsizei)(m_verts.size() / 3));
  glDisableClientState(GL_NORMAL_ARRAY);
  glDisableClientState(GL_VERTEX_ARRAY);
}
