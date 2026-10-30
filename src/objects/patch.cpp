/**
 * @file patch.cpp
 * @brief Implementation of the patch primitive.
 */

#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "patch.h"

#ifdef WIN32
#include <windows.h>
#endif

#include "glutils.h"

#include <QDebug>
#include <BulletCollision/Gimpact/btGImpactCollisionAlgorithm.h>
#include <BulletCollision/Gimpact/btGImpactShape.h>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

Patch::Patch(btScalar size, btScalar mass) : m_mass(mass) {
  // Default flat patch
  std::array<btVector3, 16> points;
  float half = size * 0.5f;
  for (int u = 0; u < 4; ++u) {
    for (int v = 0; v < 4; ++v) {
      float fu = (u == 0 || u == 1) ? -half : half;
      float fv = (v == 0 || v == 1) ? -half : half;
      points[u * 4 + v] = btVector3(fu, 0, fv);
    }
  }
  init(points, mass);
}

Patch::Patch(const std::array<btVector3, 16> &points, btScalar mass) : m_mass(mass) {
  init(points, mass);
}

void Patch::init(const std::array<btVector3, 16> &points, btScalar mass) {
  controlPoints = points;
  m_mass = mass;
  buildMesh(8);
}

Patch::~Patch() {
  if (m_mesh) {
    delete m_mesh;
    m_mesh = nullptr;
  }
  deleteOwnShape(false);
}

void Patch::setControlPoint(int u, int v, const btVector3 &point) {
  if (u >= 0 && u < 4 && v >= 0 && v < 4) {
    controlPoints[u * 4 + v] = point;
    rebuild();
  }
}

btVector3 Patch::getControlPoint(int u, int v) const {
  if (u >= 0 && u < 4 && v >= 0 && v < 4) {
    return controlPoints[u * 4 + v];
  }
  return btVector3(0, 0, 0);
}

static float bernstein(int i, float t) {
  switch (i) {
    case 0: return (1 - t) * (1 - t) * (1 - t);
    case 1: return 3 * t * (1 - t) * (1 - t);
    case 2: return 3 * t * t * (1 - t);
    case 3: return t * t * t;
  }
  return 0;
}

btVector3 Patch::evaluate(float u, float v) const {
  btVector3 result(0, 0, 0);
  for (int i = 0; i < 4; ++i) {
    float bu = bernstein(i, u);
    for (int j = 0; j < 4; ++j) {
      float bv = bernstein(j, v);
      result += controlPoints[i * 4 + j] * (bu * bv);
    }
  }
  return result;
}

void Patch::buildMesh(int tessellation) {
  if (m_mesh) {
    delete m_mesh;
    m_mesh = nullptr;
  }
  if (shape) {
    delete shape;
    shape = nullptr;
  }

  m_mesh = new btTriangleMesh();

  m_verts.clear();
  m_norms.clear();
  m_idxs.clear();

  std::vector<btVector3> verts((tessellation + 1) * (tessellation + 1));
  std::vector<btVector3> norms((tessellation + 1) * (tessellation + 1));

  for (int i = 0; i <= tessellation; ++i) {
    float u = float(i) / tessellation;
    for (int j = 0; j <= tessellation; ++j) {
      float v = float(j) / tessellation;
      btVector3 pos = evaluate(u, v);
      verts[i * (tessellation + 1) + j] = pos;

      float du = 1e-3f;
      float dv = 1e-3f;
      btVector3 pu = evaluate(std::min(1.0f, u + du), v) -
                     evaluate(std::max(0.0f, u - du), v);
      btVector3 pv = evaluate(u, std::min(1.0f, v + dv)) -
                     evaluate(u, std::max(0.0f, v - dv));
      btVector3 n = pu.cross(pv);
      if (n.length2() > 0) n.normalize();
      else n = btVector3(0, 1, 0);
      norms[i * (tessellation + 1) + j] = n;

      m_verts.push_back(pos.x());
      m_verts.push_back(pos.y());
      m_verts.push_back(pos.z());
      m_norms.push_back(n.x());
      m_norms.push_back(n.y());
      m_norms.push_back(n.z());
    }
  }

  for (int i = 0; i < tessellation; ++i) {
    for (int j = 0; j < tessellation; ++j) {
      int i0 = i * (tessellation + 1) + j;
      int i1 = i * (tessellation + 1) + j + 1;
      int i2 = (i + 1) * (tessellation + 1) + j;
      int i3 = (i + 1) * (tessellation + 1) + j + 1;

      m_mesh->addTriangle(verts[i0], verts[i2], verts[i1], true);
      m_mesh->addTriangle(verts[i1], verts[i2], verts[i3], true);

      m_idxs.push_back(static_cast<unsigned int>(i0));
      m_idxs.push_back(static_cast<unsigned int>(i2));
      m_idxs.push_back(static_cast<unsigned int>(i1));
      m_idxs.push_back(static_cast<unsigned int>(i1));
      m_idxs.push_back(static_cast<unsigned int>(i2));
      m_idxs.push_back(static_cast<unsigned int>(i3));
    }
  }

  btGImpactMeshShape *gimpactShape = new btGImpactMeshShape(m_mesh);
  gimpactShape->updateBound();
  shape = gimpactShape;

  btQuaternion qtn;
  btTransform trans;
  btDefaultMotionState *motionState = nullptr;

  trans.setIdentity();
  qtn.setEuler(0.0, 0.0, 0.0);
  trans.setRotation(qtn);
  trans.setOrigin(btVector3(0, 0, 0));
  motionState = new btDefaultMotionState(trans);

  btVector3 inertia;
  shape->calculateLocalInertia(m_mass, inertia);
  body = new btRigidBody(m_mass, motionState, shape, inertia);
  _ownsBody = true;
}

void Patch::rebuild() {
  if (m_mesh) {
    delete m_mesh;
    m_mesh = nullptr;
  }
  if (shape) {
    delete shape;
    shape = nullptr;
  }
  buildMesh(8);
}

void Patch::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<Patch, Object>("Patch")
                .def(constructor<>(), adopt(result))
                .def(constructor<btScalar>(), adopt(result))
                .def(constructor<btScalar, btScalar>(), adopt(result))
                .def("setControlPoint", &Patch::setControlPoint)
                .def("getControlPoint", &Patch::getControlPoint)
                .def("evaluate", &Patch::evaluate)
                .def("rebuild", &Patch::rebuild)
                .def(tostring(const_self))
                .def(const_self == const_self)];
}

QString Patch::toString() const { return QString("Patch"); }

void Patch::toPOV(QTextStream *s) const {
  if (!s) return;

  if (body != nullptr && body->getMotionState() != nullptr) {
    btTransform trans;
    body->getMotionState()->getWorldTransform(trans);
    if (placed)
      trans = place * trans;
    trans.getOpenGLMatrix(matrix);
    povMatrixFromGL(matrix, matrix);
  }

  if (mPreSDL.isNull()) {
    *s << "bicubic_patch {\n";
    *s << "  type 1\n";
    *s << "  flatness 0.01\n";
    *s << "  u_steps 8\n";
    *s << "  v_steps 8\n";

    for (int i = 0; i < 4; ++i) {
      for (int j = 0; j < 4; ++j) {
        const btVector3 &p = controlPoints[i * 4 + j];
        *s << "  <" << p.x() << ", " << p.y() << ", " << p.z() << ">\n";
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

  if (mPostSDL.isNull()) {
    *s << "}" << "\n" << "\n";
  } else {
    *s << mPostSDL << "\n";
  }
}

void Patch::renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) {
  Q_UNUSED(minaabb)
  Q_UNUSED(maxaabb)

  if (m_verts.empty()) return;

  glApplyColor();

  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_NORMAL_ARRAY);
  glVertexPointer(3, GL_DOUBLE, 0, m_verts.data());
  glNormalPointer(GL_DOUBLE, 0, m_norms.data());
  glDrawElements(GL_TRIANGLES, (GLsizei)m_idxs.size(), GL_UNSIGNED_INT,
                 m_idxs.data());
  glDisableClientState(GL_NORMAL_ARRAY);
  glDisableClientState(GL_VERTEX_ARRAY);
}
