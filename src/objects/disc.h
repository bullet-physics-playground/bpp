#ifndef DISC_H
#define DISC_H

/**
 * @file disc.h
 * @brief Disc (flat cylinder) primitive.
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

/**
 * @brief A disc (flat cylinder), centred on its own origin in the XY plane.
 *
 * Backed by a Bullet btCylinderShape and exported as a POV-Ray @c disc.
 */
class Disc : public Object {
public:
  /**
   * @brief Constructs a disc from radius and height.
   * @param radius Radius of the disc.
   * @param height Thickness of the disc.
   * @param mass   Mass; 0 makes the disc static.
   */
  Disc(btScalar radius = 1.0, btScalar height = 0.2, btScalar mass = 1.0);

  /**
   * @brief Constructs a disc from a vector of dimensions.
   * @param dim  Radius (x) and height (y).
   * @param mass Mass; 0 makes the disc static.
   */
  Disc(const btVector3 &dim, btScalar mass = 1.0);

  /**
   * @brief Destroys the disc and its Bullet shape and motion state.
   */
  ~Disc();

  btScalar radius; ///< Radius of the disc.
  btScalar height; ///< Thickness of the disc.

  /**
   * @brief Registers the Disc class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns the object's type name.
   * @return The literal @c "Disc".
   */
  QString toString() const override;

  /**
   * @brief Writes the disc to a POV-Ray scene as a @c disc.
   * @param s The stream to write to.
   */
  void toPOV(QTextStream *s) const override;

protected:
  /**
   * @brief Writes the disc's surface, wrapping a texture round it.
   * @param s The stream to write to; a null stream writes nothing.
   */
  void povPigment(QTextStream *s) const override;

  /**
   * @brief Builds the collision shape, motion state and rigid body.
   * @param radius Radius of the disc.
   * @param height Thickness of the disc.
   * @param mass   Mass; 0 makes the disc static.
   */
  void init(btScalar radius, btScalar height, btScalar mass);

  /**
   * @brief Draws the disc in its own frame.
   * @param minaabb Lower corner of the scene bounding box. Unused.
   * @param maxaabb Upper corner of the scene bounding box. Unused.
   */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;
};

#endif // DISC_H