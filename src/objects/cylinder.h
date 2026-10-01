#ifndef CYLINDER_H
#define CYLINDER_H

/**
 * @file cylinder.h
 * @brief Cylinder primitive.
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

/**
 * @brief A cylinder, centred on its own origin.
 *
 * Backed by a Bullet btCylinderShape and exported as a POV-Ray @c cylinder.
 */
class Cylinder : public Object {
public:
  /**
   * @brief Constructs a cylinder from a vector of dimensions.
   * @param dim  Radius and depth, taken from x and y.
   * @param mass Mass; 0 makes the cylinder static.
   */
  Cylinder(const btVector3 &dim, btScalar mass = 1.0);

  /**
   * @brief Constructs a cylinder from its radius and depth.
   * @param radius The radius.
   * @param depth  Extent along the cylinder's axis.
   * @param mass   Mass; 0 makes the cylinder static.
   */
  Cylinder(btScalar radius = 1.0, btScalar depth = 1.0, btScalar mass = 1.0);

  /**
   * @brief Destroys the cylinder and its Bullet shape and motion state.
   */
  ~Cylinder(); // Add destructor declaration

  btScalar lengths[3]; ///< The cylinder's half extents along each axis.

  /**
   * @brief Registers the Cylinder class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns the object's type name.
   * @return The literal @c "Cylinder".
   */
  QString toString() const override;

  /**
   * @brief Writes the cylinder to a POV-Ray scene as a @c cylinder.
   * @param s The stream to write to.
   */
  void toPOV(QTextStream *s) const override;

protected:
  /**
   * @brief Writes the cylinder's surface, wrapping a texture round it.
   *
   * POV-Ray has no @c uv_mapping for a cylinder, so the image is wrapped with
   * a cylindrical @c map_type instead, stretched along the axis so that it
   * goes round once and along once -- the same as the interactive view's
   * texture coordinates.
   *
   * @param s The stream to write to; a null stream writes nothing.
   */
  void povPigment(QTextStream *s) const override;

  /**
   * @brief Builds the collision shape, motion state and rigid body.
   * @param radius The radius.
   * @param depth  Extent along the cylinder's axis.
   * @param mass   Mass; 0 makes the cylinder static.
   */
  void init(btScalar radius, btScalar depth, btScalar mass);

  /**
   * @brief Draws the cylinder in its own frame.
   * @param minaabb Lower corner of the scene bounding box. Unused.
   * @param maxaabb Upper corner of the scene bounding box. Unused.
   */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;
};

#endif // CYLINDER_H
