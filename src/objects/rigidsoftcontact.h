#ifndef RIGIDSOFTCONTACT_H
#define RIGIDSOFTCONTACT_H

/**
 * @file rigidsoftcontact.h
 * @brief A copied-out snapshot of one soft-body to rigid-body contact.
 */

#include <lua.hpp>
#include <luabind/luabind.hpp>

#include <btBulletDynamicsCommon.h>

#include <BulletSoftBody/btSoftBody.h>

#include <QString>
#include <iostream>

class RigidSoftContact;

/**
 * @brief Writes a contact's description to a standard stream.
 * @param ostream The stream to write to.
 * @param c       The contact to describe.
 * @return @p ostream, for chaining.
 */
std::ostream &operator<<(std::ostream &ostream, const RigidSoftContact &c);

/**
 * @brief One contact between a soft body node and a rigid body.
 *
 * A read-only snapshot of one btSoftBody::RContact ("Rigid contact" in
 * Bullet's own terminology, see btSoftBody.h's m_rcontacts array): a
 * transient collision contact generated wherever a SoftBody node touches a
 * rigid collision object. Bullet regenerates m_rcontacts from scratch every
 * simulation step, so instances of this class are plain copied-out values,
 * not live references - obtained via SoftBody:getContact(i), not
 * constructed directly from Lua.
 */
class RigidSoftContact {
public:
  /**
   * @brief Constructs an empty contact, with no node and no body.
   */
  RigidSoftContact();

  /**
   * @brief Copies the interesting fields out of a Bullet contact.
   * @param nodeIndex Index of the soft body node that is touching.
   * @param rc        The Bullet contact to copy from.
   */
  RigidSoftContact(int nodeIndex, const btSoftBody::RContact &rc);

  /**
   * @brief Registers the RigidSoftContact class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns which soft body node is touching.
   * @return The node index, or -1 for an empty contact.
   */
  int getNode() const;

  /**
   * @brief Returns the rigid body being touched.
   * @return The body, or null if the collision object is not a rigid body.
   */
  btRigidBody *getBody() const;

  /**
   * @brief Returns where the contact is.
   * @return The touching node's world position.
   */
  btVector3 getPosition() const;

  /**
   * @brief Returns the contact normal.
   * @return The normal in world space.
   */
  btVector3 getNormal() const;

  /**
   * @brief Returns how far the node is from the rigid body's surface.
   * @return The signed offset along the normal.
   */
  btScalar getOffset() const;

  /**
   * @brief Returns the friction the solver used for this contact.
   * @return The friction coefficient.
   */
  btScalar getFriction() const;

  /**
   * @brief Returns the contact hardness the solver used.
   * @return The hardness coefficient.
   */
  btScalar getHardness() const;

  /**
   * @brief Returns a short description naming the node.
   * @return Text of the form @c "RigidSoftContact(node=N)".
   */
  QString toString() const;

protected:
  int m_node;            ///< Index of the touching soft body node.
  btRigidBody *m_body;   ///< The rigid body being touched, or null.
  btVector3 m_position;  ///< World position of the touching node.
  btVector3 m_normal;    ///< Contact normal in world space.
  btScalar m_offset;     ///< Signed distance to the rigid body's surface.
  btScalar m_friction;   ///< Friction the solver used.
  btScalar m_hardness;   ///< Contact hardness the solver used.
};

#endif // RIGIDSOFTCONTACT_H
