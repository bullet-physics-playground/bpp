#ifndef BOUND_H
#define BOUND_H

/**
 * @file bound.h
 * @brief Bound object primitive.
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

/**
 * @brief An object with an explicit bounding shape.
 *
 * Exports as a POV-Ray object with a @c bounded_by clause. The bound shape
 * is used both for POV-Ray export and as the collision shape.
 */
class Bound : public Object {
public:
  /**
   * @brief Constructs a bound object.
   * @param boundShape Collision/bounding shape.
   * @param mass Mass; 0 makes it static.
   */
  Bound(btCollisionShape *boundShape = nullptr, btScalar mass = 1.0);

  /** @brief Destroys the bound object. */
  ~Bound();

  /** @brief Sets the bounding shape. */
  void setBoundShape(btCollisionShape *shape);

  /** @brief Returns the bounding shape. */
  btCollisionShape *getBoundShape() const { return m_boundShape; }

  /**
   * @brief Registers the Bound class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /** @brief Returns the object's type name. */
  QString toString() const override;

  /** @brief Writes the bound object to a POV-Ray scene with @c bounded_by. */
  void toPOV(QTextStream *s) const override;

protected:
  /** @brief Draws the bound object's shape. */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

  btCollisionShape *m_boundShape; ///< Bounding shape.
};

#endif // BOUND_H
