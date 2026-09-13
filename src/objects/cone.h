#ifndef CONE_H
#define CONE_H

/**
 * @file cone.h
 * @brief Cone primitive.
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

/**
 * @brief A cone standing on the y axis, apex upwards.
 *
 * Backed by a Bullet btConeShape and exported as a POV-Ray @c cone.
 */
class Cone : public Object {
public:
  /**
   * @brief Constructs a cone.
   * @param radius Radius at the base.
   * @param height Height from base to apex.
   * @param mass   Mass; 0 makes the cone static.
   */
  Cone(btScalar radius = 0.5, btScalar height = 1.0, btScalar mass = 1.0);

  /**
   * @brief Destroys the cone and its Bullet shape and motion state.
   */
  ~Cone();

  /**
   * @brief Changes the cone's base radius.
   * @param radius The new radius.
   */
  void setRadius(btScalar radius);

  /**
   * @brief Returns the cone's base radius.
   * @return The radius.
   */
  btScalar getRadius() const;

  /**
   * @brief Changes the cone's height.
   * @param height The new height.
   */
  void setHeight(btScalar height);

  /**
   * @brief Returns the cone's height.
   * @return The height.
   */
  btScalar getHeight() const;

  /**
   * @brief Registers the Cone class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns the object's type name.
   * @return The literal @c "Cone".
   */
  QString toString() const override;

  /**
   * @brief Writes the cone to a POV-Ray scene as a @c cone.
   * @param s The stream to write to.
   */
  void toPOV(QTextStream *s) const override;

protected:
  /**
   * @brief Builds the collision shape, motion state and rigid body.
   * @param radius Radius at the base.
   * @param height Height from base to apex.
   * @param mass   Mass; 0 makes the cone static.
   */
  void init(btScalar radius, btScalar height, btScalar mass);

  /**
   * @brief Draws the cone in its own frame.
   * @param minaabb Lower corner of the scene bounding box. Unused.
   * @param maxaabb Upper corner of the scene bounding box. Unused.
   */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

  btScalar radius; ///< Radius at the base.
  btScalar height; ///< Height from base to apex.
};

#endif // CONE_H
