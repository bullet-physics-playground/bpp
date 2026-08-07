#ifdef WIN32_VC90
#pragma warning(disable : 4251)
#endif

#include "rigidsoftcontact.h"

#ifdef WIN32
#include <windows.h>
#endif

#include <luabind/adopt_policy.hpp>
#include <luabind/operator.hpp>

std::ostream &operator<<(std::ostream &ostream, const RigidSoftContact &c) {
  ostream << c.toString().toUtf8().data();
  return ostream;
}

RigidSoftContact::RigidSoftContact()
    : m_node(-1), m_body(nullptr), m_position(0, 0, 0), m_normal(0, 0, 0),
      m_offset(0), m_friction(0), m_hardness(0) {}

RigidSoftContact::RigidSoftContact(int nodeIndex,
                                   const btSoftBody::RContact &rc)
    : m_node(nodeIndex),
      m_body(btRigidBody::upcast(
          const_cast<btCollisionObject *>(rc.m_cti.m_colObj))),
      m_position(rc.m_node->m_x), m_normal(rc.m_cti.m_normal),
      m_offset(rc.m_cti.m_offset), m_friction(rc.m_c3), m_hardness(rc.m_c4) {}

void RigidSoftContact::luaBind(lua_State *s) {
  using namespace luabind;

  module(s)[class_<RigidSoftContact>("RigidSoftContact")
                .def(constructor<>(), adopt(result))
                .property("node", &RigidSoftContact::getNode)
                .property("body", &RigidSoftContact::getBody)
                .property("pos", &RigidSoftContact::getPosition)
                .property("normal", &RigidSoftContact::getNormal)
                .property("offset", &RigidSoftContact::getOffset)
                .property("friction", &RigidSoftContact::getFriction)
                .property("hardness", &RigidSoftContact::getHardness)
                .def(tostring(const_self))];
}

int RigidSoftContact::getNode() const { return m_node; }

btRigidBody *RigidSoftContact::getBody() const { return m_body; }

btVector3 RigidSoftContact::getPosition() const { return m_position; }

btVector3 RigidSoftContact::getNormal() const { return m_normal; }

btScalar RigidSoftContact::getOffset() const { return m_offset; }

btScalar RigidSoftContact::getFriction() const { return m_friction; }

btScalar RigidSoftContact::getHardness() const { return m_hardness; }

QString RigidSoftContact::toString() const {
  return QString("RigidSoftContact(node=%1)").arg(m_node);
}
