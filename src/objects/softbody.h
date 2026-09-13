#ifndef SOFTBODY_H
#define SOFTBODY_H

/**
 * @file softbody.h
 * @brief Deformable cloth patch wrapping Bullet's btSoftBody.
 */

#include "object.h"
#include "rigidsoftcontact.h"

#include <btBulletDynamicsCommon.h>

#include <BulletSoftBody/btSoftBody.h>

/**
 * @brief A deformable cloth patch in the scene.
 *
 * Wraps a btSoftBody (a rectangular cloth patch) as a bpp Object.
 *
 * Unlike the rigid Object subclasses (Sphere, Cube, ...), a soft body has no
 * single rigid transform: its shape is defined by the current world-space
 * positions of its nodes. Object::body is therefore always left null here,
 * and Viewer specially recognizes SoftBody instances (via dynamic_cast) to
 * add/remove them from the dynamics world's soft body array instead of its
 * rigid body array, and to render/step them accordingly.
 *
 * Because the body is made of nodes rather than a single transform, most of
 * the interesting operations are per node: pinning one in place, pulling on
 * one with a force, or anchoring one to a rigid body.
 */
class SoftBody : public Object {
public:
  // Flat rectangular patch of cloth, resx x resy nodes, centered on the
  // origin in the XZ plane. "fixeds" is the corner-pinning bitmask used by
  // btSoftBodyHelpers::CreatePatch (1=corner00, 2=corner10, 4=corner01,
  // 8=corner11; corner00/11 are diagonally opposite, as are corner10/01).
  /**
   * @brief Constructs a cloth patch with the default size and resolution.
   */
  SoftBody();

  /**
   * @brief Constructs a cloth patch of a given size.
   * @param width  Extent along x.
   * @param height Extent along z.
   */
  SoftBody(btScalar width, btScalar height);

  /**
   * @brief Constructs a cloth patch of a given size and mass.
   * @param width  Extent along x.
   * @param height Extent along z.
   * @param mass   Total mass, spread over the nodes.
   */
  SoftBody(btScalar width, btScalar height, btScalar mass);

  /**
   * @brief Constructs a cloth patch, controlling every parameter.
   * @param width  Extent along x.
   * @param height Extent along z.
   * @param resX   Number of nodes along x.
   * @param resY   Number of nodes along z.
   * @param mass   Total mass, spread over the nodes.
   * @param fixeds Corner-pinning bitmask: 1 for corner00, 2 for corner10,
   *               4 for corner01 and 8 for corner11, where corner00 and
   *               corner11 are diagonally opposite, as are corner10 and
   *               corner01. 0 leaves the patch free.
   */
  SoftBody(btScalar width, btScalar height, int resX, int resY,
           btScalar mass, int fixeds);

  /**
   * @brief Destroys the soft body, unless Lua already owns it.
   */
  ~SoftBody();

  /**
   * @brief Tells the class which world info new soft bodies belong to.
   *
   * Viewer calls this once, right after (re)creating its dynamics world, so
   * subsequently-constructed SoftBody instances can create their btSoftBody
   * against the real world info (broadphase/dispatcher/gravity/sparse SDF).
   *
   * @param info The world info. Not owned; it belongs to the dynamics world.
   */
  static void setWorldInfo(btSoftBodyWorldInfo *info);

  /**
   * @brief Returns the wrapped Bullet soft body.
   * @return The soft body, or null once it has been released.
   */
  btSoftBody *getSoftBody() const { return m_softBody; }

  /**
   * @brief Registers the SoftBody class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns the object's type name.
   * @return The literal @c "SoftBody".
   */
  QString toString() const override;

  /**
   * @brief Writes the deformed patch to a POV-Ray scene.
   *
   * The node positions are emitted as they currently stand, so the exported
   * frame matches the simulated shape.
   *
   * @param s The stream to write to.
   */
  void toPOV(QTextStream *s) const override;

  /**
   * @brief Draws the soft body from its current node positions.
   *
   * Draws the current node/face positions directly in world space. Called
   * explicitly by Viewer::drawSceneInternal() instead of going through
   * Object::render(), which requires a non-null rigid body.
   */
  void renderWorld();

  /**
   * @brief Returns the soft body's total mass.
   * @return The total mass.
   */
  btScalar getTotalMass() const;

  /**
   * @brief Sets the soft body's total mass, spreading it over the nodes.
   * @param mass The new total mass.
   */
  void setTotalMass(btScalar mass);

  /**
   * @brief Returns how much the cloth resists stretching.
   * @return The linear stiffness coefficient.
   */
  btScalar getStiffness() const;

  /**
   * @brief Sets how much the cloth resists stretching.
   * @param linearStiffness The new coefficient, from 0 to 1.
   */
  void setStiffness(btScalar linearStiffness);

  /**
   * @brief Returns the pressure inflating the body.
   * @return The pressure coefficient; 0 leaves the patch uninflated.
   */
  btScalar getPressure() const;

  /**
   * @brief Sets a pressure that inflates the body from inside.
   *
   * Only meaningful for a closed surface.
   *
   * @param pressure The new pressure coefficient.
   */
  void setPressure(btScalar pressure);

  /**
   * @brief Returns how quickly node motion is damped.
   * @return The damping coefficient.
   */
  btScalar getDampingCoeff() const;

  /**
   * @brief Sets how quickly node motion is damped.
   * @param damping The new damping coefficient.
   */
  void setDampingCoeff(btScalar damping);

  /**
   * @brief Returns how many solver iterations the body gets per step.
   * @return The iteration count.
   */
  int getIterations() const;

  /**
   * @brief Sets how many solver iterations the body gets per step.
   *
   * More iterations make the cloth stiffer and steadier, at a cost.
   *
   * @param iterations The new iteration count.
   */
  void setIterations(int iterations);

  /**
   * @brief Returns whether the body can collide with itself.
   * @return True if self collision is on.
   */
  bool getSelfCollision() const;

  /**
   * @brief Turns self collision on or off.
   *
   * Stops a folded cloth passing through itself, at a noticeable cost.
   *
   * @param onoff True to enable it.
   */
  void setSelfCollision(bool onoff);

  /**
   * @brief Returns the average position of all the nodes.
   * @return The centroid in world space.
   */
  btVector3 getCentroid() const;

  /**
   * @brief Moves the body so its centroid lands on a position.
   * @param pos The position to move the centroid to.
   */
  void setCentroid(const btVector3 &pos);

  /**
   * @brief Moves every node by an offset.
   * @param v The offset.
   */
  void translate(const btVector3 &v);

  /**
   * @brief Rotates the whole body.
   * @param q The rotation to apply.
   */
  void rotate(const btQuaternion &q);

  /**
   * @brief Scales the whole body.
   * @param v Per-axis scale factors.
   */
  void scale(const btVector3 &v);

  /**
   * @brief Applies a force to every node.
   * @param force The force to apply.
   */
  void addForce(const btVector3 &force);

  /**
   * @brief Applies a force to one node.
   * @param force The force to apply.
   * @param node  Index of the node.
   */
  void addForceToNode(const btVector3 &force, int node);

  /**
   * @brief Pins one node in place by giving it infinite mass.
   * @param node Index of the node to pin.
   */
  void fixNode(int node);

  /**
   * @brief Sets one node's mass.
   *
   * A mass of 0 pins the node, which is what fixNode() does.
   *
   * @param node Index of the node.
   * @param mass The new mass.
   */
  void setNodeMass(int node, btScalar mass);

  /**
   * @brief Returns where one node currently is.
   * @param node Index of the node.
   * @return Its world position.
   */
  btVector3 getNodePosition(int node) const;

  /**
   * @brief Attaches one node to a rigid body.
   *
   * The node then follows the body, which is how cloth is hung from something
   * that moves.
   *
   * @param node Index of the node.
   * @param body The rigid body to attach it to.
   */
  void appendAnchor(int node, btRigidBody *body);

  /**
   * @brief Attaches one node to a rigid body, controlling collision.
   * @param node             Index of the node.
   * @param body             The rigid body to attach it to.
   * @param disableCollision True to stop the soft body colliding with that
   *                         rigid body, which avoids the jitter an anchored
   *                         node can otherwise cause.
   */
  void appendAnchor(int node, btRigidBody *body, bool disableCollision);

  /**
   * @brief Returns how many nodes the body has.
   * @return The node count.
   */
  int getNodeCount() const;

  /**
   * @brief Returns how many triangular faces the body has.
   * @return The face count.
   */
  int getFaceCount() const;

  /**
   * @brief Returns how many rigid contacts the body currently has.
   *
   * Rigid-soft contacts (btSoftBody::RContact / m_rcontacts) currently
   * touching this soft body: Bullet regenerates the whole array from
   * scratch every simulation step, so these are read-only snapshots, not
   * live handles. Call after a simulation step (e.g. from postSim).
   *
   * @return The contact count.
   */
  int getContactCount() const;

  /**
   * @brief Returns a snapshot of one rigid contact.
   * @param i Contact index, below getContactCount().
   * @return A copy of the contact; see RigidSoftContact.
   */
  RigidSoftContact getContact(int i) const;

  /**
   * @brief Drops the Bullet pointer without deleting it.
   *
   * Drops the raw btSoftBody pointer without deleting it. Mirrors
   * Mesh::luaRelease(): called by Viewer during teardown after the soft
   * body has already been removed from the dynamics world and its C++
   * ownership settled, so ~SoftBody() does not touch a stale pointer.
   */
  void luaRelease() { m_softBody = nullptr; }

protected:
  /**
   * @brief Builds the cloth patch; shared by every constructor.
   * @param width  Extent along x.
   * @param height Extent along z.
   * @param resX   Number of nodes along x.
   * @param resY   Number of nodes along z.
   * @param mass   Total mass, spread over the nodes.
   * @param fixeds Corner-pinning bitmask, as for the full constructor.
   */
  void init(btScalar width, btScalar height, int resX, int resY,
            btScalar mass, int fixeds);

  btSoftBody *m_softBody; ///< The wrapped Bullet soft body.

  static btSoftBodyWorldInfo *s_worldInfo; ///< World info new bodies are built
                                           ///< against; set by setWorldInfo().
  static btSoftBodyWorldInfo s_fallbackWorldInfo; ///< Used when no world info
                                                  ///< has been set yet.
};

#endif // SOFTBODY_H
