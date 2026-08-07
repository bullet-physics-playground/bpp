#ifndef SOFTBODY_H
#define SOFTBODY_H

#include "object.h"
#include "rigidsoftcontact.h"

#include <btBulletDynamicsCommon.h>

#include <BulletSoftBody/btSoftBody.h>

// Wraps a btSoftBody (a rectangular cloth patch) as a bpp Object.
//
// Unlike the rigid Object subclasses (Sphere, Cube, ...), a soft body has no
// single rigid transform: its shape is defined by the current world-space
// positions of its nodes. Object::body is therefore always left null here,
// and Viewer specially recognizes SoftBody instances (via dynamic_cast) to
// add/remove them from the dynamics world's soft body array instead of its
// rigid body array, and to render/step them accordingly.
class SoftBody : public Object {
public:
  // Flat rectangular patch of cloth, resx x resy nodes, centered on the
  // origin in the XZ plane. "fixeds" is the corner-pinning bitmask used by
  // btSoftBodyHelpers::CreatePatch (1=corner00, 2=corner10, 4=corner01,
  // 8=corner11; corner00/11 are diagonally opposite, as are corner10/01).
  SoftBody();
  SoftBody(btScalar width, btScalar height);
  SoftBody(btScalar width, btScalar height, btScalar mass);
  SoftBody(btScalar width, btScalar height, int resX, int resY,
           btScalar mass, int fixeds);
  ~SoftBody();

  // Viewer calls this once, right after (re)creating its dynamics world, so
  // subsequently-constructed SoftBody instances can create their btSoftBody
  // against the real world info (broadphase/dispatcher/gravity/sparse SDF).
  static void setWorldInfo(btSoftBodyWorldInfo *info);

  btSoftBody *getSoftBody() const { return m_softBody; }

  static void luaBind(lua_State *s);
  QString toString() const override;
  void toPOV(QTextStream *s) const override;

  // Draws the current node/face positions directly in world space. Called
  // explicitly by Viewer::drawSceneInternal() instead of going through
  // Object::render(), which requires a non-null rigid body.
  void renderWorld();

  btScalar getTotalMass() const;
  void setTotalMass(btScalar mass);

  btScalar getStiffness() const;
  void setStiffness(btScalar linearStiffness);

  btScalar getPressure() const;
  void setPressure(btScalar pressure);

  btScalar getDampingCoeff() const;
  void setDampingCoeff(btScalar damping);

  int getIterations() const;
  void setIterations(int iterations);

  bool getSelfCollision() const;
  void setSelfCollision(bool onoff);

  btVector3 getCentroid() const;
  void setCentroid(const btVector3 &pos);

  void translate(const btVector3 &v);
  void rotate(const btQuaternion &q);
  void scale(const btVector3 &v);

  void addForce(const btVector3 &force);
  void addForceToNode(const btVector3 &force, int node);

  void fixNode(int node);
  void setNodeMass(int node, btScalar mass);
  btVector3 getNodePosition(int node) const;

  void appendAnchor(int node, btRigidBody *body);
  void appendAnchor(int node, btRigidBody *body, bool disableCollision);

  int getNodeCount() const;
  int getFaceCount() const;

  // Rigid-soft contacts (btSoftBody::RContact / m_rcontacts) currently
  // touching this soft body: Bullet regenerates the whole array from
  // scratch every simulation step, so these are read-only snapshots, not
  // live handles. Call after a simulation step (e.g. from postSim).
  int getContactCount() const;
  RigidSoftContact getContact(int i) const;

  // Drops the raw btSoftBody pointer without deleting it. Mirrors
  // Mesh::luaRelease(): called by Viewer during teardown after the soft
  // body has already been removed from the dynamics world and its C++
  // ownership settled, so ~SoftBody() does not touch a stale pointer.
  void luaRelease() { m_softBody = nullptr; }

protected:
  void init(btScalar width, btScalar height, int resX, int resY,
            btScalar mass, int fixeds);

  btSoftBody *m_softBody;

  static btSoftBodyWorldInfo *s_worldInfo;
  static btSoftBodyWorldInfo s_fallbackWorldInfo;
};

#endif // SOFTBODY_H
