#ifndef RIGIDSOFTCONTACT_H
#define RIGIDSOFTCONTACT_H

#include <lua.hpp>
#include <luabind/luabind.hpp>

#include <btBulletDynamicsCommon.h>

#include <BulletSoftBody/btSoftBody.h>

#include <QString>
#include <iostream>

class RigidSoftContact;
std::ostream &operator<<(std::ostream &, const RigidSoftContact &);

// A read-only snapshot of one btSoftBody::RContact ("Rigid contact" in
// Bullet's own terminology, see btSoftBody.h's m_rcontacts array): a
// transient collision contact generated wherever a SoftBody node touches a
// rigid collision object. Bullet regenerates m_rcontacts from scratch every
// simulation step, so instances of this class are plain copied-out values,
// not live references — obtained via SoftBody:getContact(i), not
// constructed directly from Lua.
class RigidSoftContact {
public:
  RigidSoftContact();
  RigidSoftContact(int nodeIndex, const btSoftBody::RContact &rc);

  static void luaBind(lua_State *s);

  int getNode() const;
  btRigidBody *getBody() const;
  btVector3 getPosition() const;
  btVector3 getNormal() const;
  btScalar getOffset() const;
  btScalar getFriction() const;
  btScalar getHardness() const;

  QString toString() const;

protected:
  int m_node;
  btRigidBody *m_body;
  btVector3 m_position;
  btVector3 m_normal;
  btScalar m_offset;
  btScalar m_friction;
  btScalar m_hardness;
};

#endif // RIGIDSOFTCONTACT_H
