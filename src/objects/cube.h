#ifndef CUBE_H
#define CUBE_H

/**
 * @file cube.h
 * @brief Box primitive.
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

/**
 * @brief A rectangular box, centred on its own origin.
 *
 * Backed by a Bullet btBoxShape, drawn as a solid cube scaled to its
 * dimensions and exported as a POV-Ray @c box.
 */
class Cube : public Object {

public:
  /**
   * @brief Constructs a box from a vector of dimensions.
   * @param dim  Width, height and depth as x, y and z.
   * @param mass Mass; 0 makes the box static.
   */
  Cube(const btVector3 &dim, btScalar mass = 1.0);

  /**
   * @brief Constructs a box from its three dimensions.
   * @param width  Extent along x.
   * @param height Extent along y.
   * @param depth  Extent along z.
   * @param mass   Mass; 0 makes the box static.
   */
  Cube(btScalar width = 1.0, btScalar height = 1.0, btScalar depth = 1.0,
       btScalar mass = 1.0);

  /**
   * @brief Destroys the box and its Bullet shape and motion state.
   */
  ~Cube(); // Add destructor declaration

  btScalar lengths[3]; ///< The box's width, height and depth.

  /**
   * @brief Registers the Cube class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns the object's type name.
   * @return The literal @c "Cube".
   */
  QString toString() const override;

  /**
   * @brief Writes the box to a POV-Ray scene as a @c box.
   * @param s The stream to write to.
   */
  void toPOV(QTextStream *s) const override;

  /**
   * @brief Draws the box in its own frame.
   * @param minaabb Lower corner of the scene bounding box. Unused.
   * @param maxaabb Upper corner of the scene bounding box. Unused.
   */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

protected:
  /**
   * @brief Builds the collision shape, motion state and rigid body.
   *
   * Shared by both constructors.
   *
   * @param width  Extent along x.
   * @param height Extent along y.
   * @param depth  Extent along z.
   * @param mass   Mass; 0 makes the box static.
   */
  void init(btScalar width, btScalar height, btScalar depth, btScalar mass);
};

#endif // CUBE_H
