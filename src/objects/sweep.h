#ifndef SWEEP_H
#define SWEEP_H

/**
 * @file sweep.h
 * @brief Swept primitive (rotational/translational/tapered sweep).
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

#include <vector>

/**
 * @brief Sweep type.
 */
enum SweepType {
  SWEEP_ROTATIONAL,   ///< Rotate profile around Y axis.
  SWEEP_TRANSLATIONAL,///< Translate profile along an axis.
  SWEEP_TAPER         ///< Translate profile while scaling it down.
};

/**
 * @brief An object created by sweeping a 2D profile.
 *
 * The profile is a list of 2D points stored as btVector3 (x = radial distance,
 * y = height, z unused). Backed by a Bullet btConvexHullShape for collision.
 * Exports as a POV-Ray @c mesh.
 */
class Sweep : public Object {
public:
  /**
   * @brief Constructs a sweep from a profile.
   * @param type    Sweep type (0=rotational, 1=translational, 2=tapered).
   * @param axis    Translation/taper axis (only for translational/taper).
   * @param length  Translation/taper length.
   * @param mass    Mass; 0 makes it static.
   */
  Sweep(int type = SWEEP_ROTATIONAL,
        const btVector3 &axis = btVector3(0, 1, 0), btScalar length = 1.0,
        btScalar mass = 1.0);

  /** @brief Destroys the sweep and its collision shape. */
  ~Sweep();

  /** @brief Adds a profile point (x = radial distance, y = height). */
  void addProfilePoint(btScalar x, btScalar y);

  /** @brief Sets the profile points (replaces all). */
  void setProfile(const std::vector<btVector3> &profile) { m_profile = profile; }

  /** @brief Returns the profile points. */
  const std::vector<btVector3> &getProfile() const { return m_profile; }

  /** @brief Sets the sweep type. */
  void setSweepType(SweepType type) { m_type = type; }

  /** @brief Returns the sweep type. */
  SweepType getSweepType() const { return m_type; }

  /**
   * @brief Registers the Sweep class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /** @brief Returns the object's type name. */
  QString toString() const override;

  /** @brief Writes the sweep to a POV-Ray scene as a @c mesh. */
  void toPOV(QTextStream *s) const override;

protected:
  /** @brief Draws the sweep as a solid shape. */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

  SweepType m_type;               ///< Sweep type.
  std::vector<btVector3> m_profile; ///< Profile points (x = radial distance, y = height).
  btVector3 m_axis;               ///< Translation/taper axis.
  btScalar m_length;              ///< Translation/taper length.
};

#endif // SWEEP_H
