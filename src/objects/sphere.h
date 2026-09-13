#ifndef SPHERE_H
#define SPHERE_H

/**
 * @file sphere.h
 * @brief Sphere primitive.
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

/**
 * @brief A sphere, centred on its own origin.
 *
 * Backed by a Bullet btSphereShape and exported as a POV-Ray @c sphere.
 */
class Sphere : public Object {
public:
  /**
   * @brief Constructs a sphere.
   * @param radius The radius.
   * @param mass   Mass; 0 makes the sphere static.
   */
  Sphere(btScalar radius = 0.5, btScalar mass = 1.0);

  /**
   * @brief Destroys the sphere and its Bullet shape and motion state.
   */
  ~Sphere(); // Add destructor declaration

  /**
   * @brief Changes the sphere's radius.
   * @param radius The new radius.
   */
  void setRadius(btScalar radius);

  /**
   * @brief Returns the sphere's radius.
   * @return The radius.
   */
  btScalar getRadius() const;

  /**
   * @brief Registers the Sphere class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns the object's type name.
   * @return The literal @c "Sphere".
   */
  QString toString() const override;

  /**
   * @brief Writes the sphere to a POV-Ray scene as a @c sphere.
   * @param s The stream to write to.
   */
  void toPOV(QTextStream *s) const override;

protected:
  /**
   * @brief Draws the sphere in its own frame.
   * @param minaabb Lower corner of the scene bounding box. Unused.
   * @param maxaabb Upper corner of the scene bounding box. Unused.
   */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

  btScalar radius; ///< The sphere's radius.
};

#endif // SPHERE_H
