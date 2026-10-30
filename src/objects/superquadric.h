#ifndef SUPERQUADRIC_H
#define SUPERQUADRIC_H

/**
 * @file superquadric.h
 * @brief Superquadric primitive.
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

/**
 * @brief A superquadric (superellipsoid) shape.
 *
 * Roundness and thickness control the shape: 1.0 = sphere/cube, lower =
 * more star-like or octahedral. Exports as a POV-Ray @c superellipsoid.
 */
class SuperQuadric : public Object {
public:
  /**
   * @brief Constructs a superquadric.
   * @param roundness Roundness parameter (1.0 = spherical).
   * @param thickness Thickness parameter (1.0 = cubical).
   * @param size      Overall size.
   * @param mass      Mass; 0 makes it static.
   */
  SuperQuadric(btScalar roundness = 1.0, btScalar thickness = 1.0,
               btScalar size = 1.0, btScalar mass = 1.0);

  /** @brief Destroys the superquadric. */
  ~SuperQuadric();

  /** @brief Sets the roundness parameter. */
  void setRoundness(btScalar roundness) { m_roundness = roundness; }

  /** @brief Returns the roundness parameter. */
  btScalar getRoundness() const { return m_roundness; }

  /** @brief Sets the thickness parameter. */
  void setThickness(btScalar thickness) { m_thickness = thickness; }

  /** @brief Returns the thickness parameter. */
  btScalar getThickness() const { return m_thickness; }

  /** @brief Sets the overall size. */
  void setSize(btScalar size) { m_size = size; }

  /** @brief Returns the overall size. */
  btScalar getSize() const { return m_size; }

  /**
   * @brief Registers the SuperQuadric class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /** @brief Returns the object's type name. */
  QString toString() const override;

  /** @brief Writes the superquadric to a POV-Ray scene as a @c superellipsoid. */
  void toPOV(QTextStream *s) const override;

protected:
  /** @brief Draws the superquadric as a solid sphere approximation. */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

  btScalar m_roundness; ///< Roundness parameter.
  btScalar m_thickness; ///< Thickness parameter.
  btScalar m_size;      ///< Overall size.
};

#endif // SUPERQUADRIC_H
