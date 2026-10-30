#ifndef BLOB_H
#define BLOB_H

/**
 * @file blob.h
 * @brief Blob primitive (meta-ball components).
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

#include <vector>

/**
 * @brief A single blob component.
 */
struct BlobComponent {
  btVector3 center;   ///< Component center.
  btScalar radius;    ///< Component radius.
  btScalar strength;  ///< Component strength.
  bool isCylinder;    ///< True for cylinder, false for sphere.
  btVector3 axis;     ///< Cylinder axis (only if isCylinder).
  btScalar height;    ///< Cylinder height (only if isCylinder).
};

/**
 * @brief A POV-Ray blob: meta-ball surface from component strengths.
 *
 * The surface is where the sum of component strengths reaches the threshold.
 * Backed by a Bullet btCompoundShape of spheres for collision.
 */
class Blob : public Object {
public:
  /**
   * @brief Constructs an empty blob.
   * @param threshold Surface threshold.
   * @param mass Mass; 0 makes it static.
   */
  Blob(btScalar threshold = 1.0, btScalar mass = 1.0);

  /** @brief Destroys the blob and its collision shape. */
  ~Blob();

  /**
   * @brief Adds a spherical component.
   * @param center Component center.
   * @param radius Component radius.
   * @param strength Component strength.
   */
  void addSphereComponent(const btVector3 &center, btScalar radius,
                          btScalar strength);

  /**
   * @brief Adds a cylindrical component.
   * @param center Component center.
   * @param axis Cylinder axis direction.
   * @param radius Cylinder radius.
   * @param height Cylinder height.
   * @param strength Component strength.
   */
  void addCylinderComponent(const btVector3 &center, const btVector3 &axis,
                            btScalar radius, btScalar height,
                            btScalar strength);

  /** @brief Sets the blob threshold. */
  void setThreshold(btScalar threshold) { m_threshold = threshold; }

  /** @brief Returns the blob threshold. */
  btScalar getThreshold() const { return m_threshold; }

  /** @brief Returns the component count. */
  int componentCount() const { return static_cast<int>(m_components.size()); }

  /**
   * @brief Registers the Blob class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /** @brief Returns the object's type name. */
  QString toString() const override;

  /** @brief Writes the blob to a POV-Ray scene as a @c blob. */
  void toPOV(QTextStream *s) const override;

protected:
  /** @brief Draws the blob components as spheres. */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

  btScalar m_threshold;           ///< Surface threshold.
  std::vector<BlobComponent> m_components; ///< Blob components.
};

#endif // BLOB_H
