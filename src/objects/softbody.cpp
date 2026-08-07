#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "softbody.h"

#ifdef WIN32
#include <windows.h>
#endif

#include "glutils.h"

#include <QDebug>

#include <BulletSoftBody/btSoftBodyHelpers.h>

using namespace std;

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

btSoftBodyWorldInfo *SoftBody::s_worldInfo = nullptr;
btSoftBodyWorldInfo SoftBody::s_fallbackWorldInfo;

void SoftBody::setWorldInfo(btSoftBodyWorldInfo *info) { s_worldInfo = info; }

SoftBody::SoftBody() : m_softBody(nullptr) {
  init(2.0, 2.0, 10, 10, 1.0, 0);
}

SoftBody::SoftBody(btScalar width, btScalar height) : m_softBody(nullptr) {
  init(width, height, 10, 10, 1.0, 0);
}

SoftBody::SoftBody(btScalar width, btScalar height, btScalar mass)
    : m_softBody(nullptr) {
  init(width, height, 10, 10, mass, 0);
}

SoftBody::SoftBody(btScalar width, btScalar height, int resX, int resY,
                   btScalar mass, int fixeds)
    : m_softBody(nullptr) {
  init(width, height, resX, resY, mass, fixeds);
}

void SoftBody::init(btScalar width, btScalar height, int resX, int resY,
                    btScalar mass, int fixeds) {
  btSoftBodyWorldInfo *info = s_worldInfo ? s_worldInfo : &s_fallbackWorldInfo;

  resX = btMax(resX, 2);
  resY = btMax(resY, 2);

  btVector3 corner00(-width * 0.5, 0, -height * 0.5);
  btVector3 corner10(width * 0.5, 0, -height * 0.5);
  btVector3 corner01(-width * 0.5, 0, height * 0.5);
  btVector3 corner11(width * 0.5, 0, height * 0.5);

  m_softBody = btSoftBodyHelpers::CreatePatch(
      *info, corner00, corner10, corner01, corner11, resX, resY, fixeds,
      true /* gendiags */);

  m_softBody->generateBendingConstraints(2);
  m_softBody->randomizeConstraints();
  m_softBody->m_cfg.piterations = 10;
  m_softBody->m_cfg.kDF = 0.5;
  m_softBody->setTotalMass(mass, true);

  // setTotalMass() redistributes mass across every node, including the
  // ones CreatePatch() just pinned via "fixeds" (their zero invmass gets
  // overwritten). Re-pin them so corner-fixing survives mass assignment.
  if (fixeds & 1)
    m_softBody->setMass(0, 0);
  if (fixeds & 2)
    m_softBody->setMass(resX - 1, 0);
  if (fixeds & 4)
    m_softBody->setMass((resY - 1) * resX, 0);
  if (fixeds & 8)
    m_softBody->setMass(resX * resY - 1, 0);

  setColor(127, 127, 127);
}

SoftBody::~SoftBody() {
  if (m_softBody != nullptr)
    delete m_softBody;
}

void SoftBody::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<SoftBody, Object>("SoftBody")
                .def(constructor<>(), adopt(result))
                .def(constructor<btScalar, btScalar>(), adopt(result))
                .def(constructor<btScalar, btScalar, btScalar>(),
                     adopt(result))
                .def(constructor<btScalar, btScalar, int, int, btScalar, int>(),
                     adopt(result))

                // Shadow Object's rigid-body-oriented "pos"/"mass"
                // properties with soft-body-appropriate ones: a soft body
                // has no single rigid transform, so "pos" reads/moves its
                // centroid, and "mass" reads/redistributes its total mass.
                .property("pos", &SoftBody::getCentroid, &SoftBody::setCentroid)
                .property("mass", &SoftBody::getTotalMass, &SoftBody::setTotalMass)

                .property("stiffness", &SoftBody::getStiffness,
                          &SoftBody::setStiffness)
                .property("pressure", &SoftBody::getPressure,
                          &SoftBody::setPressure)
                .property("damping", &SoftBody::getDampingCoeff,
                          &SoftBody::setDampingCoeff)
                .property("iterations", &SoftBody::getIterations,
                          &SoftBody::setIterations)
                .property("self_collision", &SoftBody::getSelfCollision,
                          &SoftBody::setSelfCollision)

                .property("nodeCount", &SoftBody::getNodeCount)
                .property("faceCount", &SoftBody::getFaceCount)

                .def("translate", &SoftBody::translate)
                .def("rotate", &SoftBody::rotate)
                .def("scale", &SoftBody::scale)

                .def("addForce", (void(SoftBody::*)(const btVector3 &)) &
                                      SoftBody::addForce)
                .def("addForce", (void(SoftBody::*)(const btVector3 &, int)) &
                                      SoftBody::addForceToNode)

                .def("fixNode", &SoftBody::fixNode)
                .def("setNodeMass", &SoftBody::setNodeMass)
                .def("getNodePosition", &SoftBody::getNodePosition)

                .def("appendAnchor",
                     (void(SoftBody::*)(int, btRigidBody *)) &
                         SoftBody::appendAnchor)
                .def("appendAnchor",
                     (void(SoftBody::*)(int, btRigidBody *, bool)) &
                         SoftBody::appendAnchor)

                .def(tostring(const_self))
                .def(const_self == const_self)];
}

QString SoftBody::toString() const { return QString("SoftBody"); }

void SoftBody::toPOV(QTextStream *s) const {
  if (s == nullptr || m_softBody == nullptr)
    return;

  const btSoftBody::tFaceArray &faces = m_softBody->m_faces;

  if (mPreSDL.isNull()) {
    *s << "mesh2 {\n";
  } else {
    *s << mPreSDL << "\n";
  }

  *s << "  vertex_vectors {\n    " << faces.size() * 3;
  for (int i = 0; i < faces.size(); ++i) {
    const btSoftBody::Face &f = faces[i];
    for (int k = 0; k < 3; ++k) {
      const btVector3 &x = f.m_n[k]->m_x;
      *s << ", <" << x.x() << "," << x.y() << "," << -x.z() << ">";
    }
  }
  *s << "\n  }\n";

  *s << "  face_indices {\n    " << faces.size();
  for (int i = 0; i < faces.size(); ++i) {
    *s << ", <" << i * 3 << "," << i * 3 + 1 << "," << i * 3 + 2 << ">";
  }
  *s << "\n  }\n";

  if (mPreSDL.isNull()) {
    // Cloth is a single-sided sheet of triangles; light both faces.
    *s << "  double_illuminate\n";
  }

  if (!mSDL.isNull()) {
    *s << mSDL << "\n";
  } else {
    *s << "  pigment { rgb <" << color[0] / 255.0 << ", " << color[1] / 255.0
       << ", " << color[2] / 255.0 << "> }\n";
  }

  if (mPostSDL.isNull()) {
    *s << "}\n\n";
  } else {
    *s << mPostSDL << "\n";
  }
}

void SoftBody::renderWorld() {
  if (m_softBody == nullptr)
    return;

  glPushAttrib(GL_LIGHTING_BIT | GL_ENABLE_BIT);
  glEnable(GL_NORMALIZE);
  glDisable(GL_CULL_FACE);
  glLightModeli(GL_LIGHT_MODEL_TWO_SIDE, GL_TRUE);
  glColor3ub(color[0], color[1], color[2]);

  const btSoftBody::tFaceArray &faces = m_softBody->m_faces;

  glBegin(GL_TRIANGLES);
  for (int i = 0; i < faces.size(); ++i) {
    const btSoftBody::Face &f = faces[i];
    glNormal3d(f.m_normal.x(), f.m_normal.y(), f.m_normal.z());
    glVertex3d(f.m_n[0]->m_x.x(), f.m_n[0]->m_x.y(), f.m_n[0]->m_x.z());
    glVertex3d(f.m_n[1]->m_x.x(), f.m_n[1]->m_x.y(), f.m_n[1]->m_x.z());
    glVertex3d(f.m_n[2]->m_x.x(), f.m_n[2]->m_x.y(), f.m_n[2]->m_x.z());
  }
  glEnd();

  glPopAttrib();
}

btScalar SoftBody::getTotalMass() const {
  return m_softBody != nullptr ? m_softBody->getTotalMass() : 0;
}

void SoftBody::setTotalMass(btScalar mass) {
  if (m_softBody != nullptr)
    m_softBody->setTotalMass(mass, true);
}

btScalar SoftBody::getStiffness() const {
  return (m_softBody != nullptr && m_softBody->m_materials.size() > 0)
             ? m_softBody->m_materials[0]->m_kLST
             : 0;
}

void SoftBody::setStiffness(btScalar linearStiffness) {
  if (m_softBody != nullptr && m_softBody->m_materials.size() > 0) {
    m_softBody->m_materials[0]->m_kLST = linearStiffness;
    m_softBody->m_materials[0]->m_kAST = linearStiffness;
  }
}

btScalar SoftBody::getPressure() const {
  return m_softBody != nullptr ? m_softBody->m_cfg.kPR : 0;
}

void SoftBody::setPressure(btScalar pressure) {
  if (m_softBody != nullptr)
    m_softBody->m_cfg.kPR = pressure;
}

btScalar SoftBody::getDampingCoeff() const {
  return m_softBody != nullptr ? m_softBody->m_cfg.kDP : 0;
}

void SoftBody::setDampingCoeff(btScalar damping) {
  if (m_softBody != nullptr)
    m_softBody->m_cfg.kDP = damping;
}

int SoftBody::getIterations() const {
  return m_softBody != nullptr ? m_softBody->m_cfg.piterations : 0;
}

void SoftBody::setIterations(int iterations) {
  if (m_softBody != nullptr)
    m_softBody->m_cfg.piterations = iterations;
}

bool SoftBody::getSelfCollision() const {
  return m_softBody != nullptr &&
         (m_softBody->m_cfg.collisions & btSoftBody::fCollision::CL_SELF);
}

void SoftBody::setSelfCollision(bool onoff) {
  if (m_softBody == nullptr)
    return;

  if (onoff) {
    m_softBody->m_cfg.collisions |= btSoftBody::fCollision::CL_SELF |
                                    btSoftBody::fCollision::CL_SS;
    if (m_softBody->clusterCount() == 0)
      m_softBody->generateClusters(0);
  } else {
    m_softBody->m_cfg.collisions &= ~(btSoftBody::fCollision::CL_SELF |
                                      btSoftBody::fCollision::CL_SS);
  }
}

btVector3 SoftBody::getCentroid() const {
  return m_softBody != nullptr ? m_softBody->getCenterOfMass() : btVector3();
}

void SoftBody::setCentroid(const btVector3 &pos) {
  if (m_softBody != nullptr)
    m_softBody->translate(pos - m_softBody->getCenterOfMass());
}

void SoftBody::translate(const btVector3 &v) {
  if (m_softBody != nullptr)
    m_softBody->translate(v);
}

void SoftBody::rotate(const btQuaternion &q) {
  if (m_softBody != nullptr)
    m_softBody->rotate(q);
}

void SoftBody::scale(const btVector3 &v) {
  if (m_softBody != nullptr)
    m_softBody->scale(v);
}

void SoftBody::addForce(const btVector3 &force) {
  if (m_softBody != nullptr)
    m_softBody->addForce(force);
}

void SoftBody::addForceToNode(const btVector3 &force, int node) {
  if (m_softBody != nullptr)
    m_softBody->addForce(force, node);
}

void SoftBody::fixNode(int node) {
  if (m_softBody != nullptr)
    m_softBody->setMass(node, 0);
}

void SoftBody::setNodeMass(int node, btScalar mass) {
  if (m_softBody != nullptr)
    m_softBody->setMass(node, mass);
}

btVector3 SoftBody::getNodePosition(int node) const {
  if (m_softBody != nullptr && node >= 0 && node < m_softBody->m_nodes.size())
    return m_softBody->m_nodes[node].m_x;
  return btVector3();
}

void SoftBody::appendAnchor(int node, btRigidBody *body) {
  appendAnchor(node, body, false);
}

void SoftBody::appendAnchor(int node, btRigidBody *body, bool disableCollision) {
  if (m_softBody != nullptr && body != nullptr)
    m_softBody->appendAnchor(node, body, disableCollision);
}

int SoftBody::getNodeCount() const {
  return m_softBody != nullptr ? m_softBody->m_nodes.size() : 0;
}

int SoftBody::getFaceCount() const {
  return m_softBody != nullptr ? m_softBody->m_faces.size() : 0;
}
