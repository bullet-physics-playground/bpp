#ifndef TRIANGLE_H
#define TRIANGLE_H

/**
 * @file triangle.h
 * @brief Single-triangle primitive.
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

/**
 * @brief One triangle, given by its three corners.
 *
 * Exported as a POV-Ray @c triangle. Useful for building a surface out of
 * individual faces, or as a thin static collider.
 */
class Triangle : public Object {

public:
  /**
   * @brief Constructs a triangle from three corners.
   * @param p0   First corner.
   * @param p1   Second corner.
   * @param p2   Third corner.
   * @param mass Mass; 0, the default, makes the triangle static.
   */
  Triangle(const btVector3 &p0 = btVector3(0, 0, 0),
           const btVector3 &p1 = btVector3(1, 0, 0),
           const btVector3 &p2 = btVector3(0.5, 0, 1),
           btScalar mass = 0);

  /**
   * @brief Destroys the triangle and its Bullet shape and motion state.
   */
  ~Triangle();

  btVector3 vertices[3]; ///< The triangle's three corners.

  /**
   * @brief Registers the Triangle class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns the object's type name.
   * @return The literal @c "Triangle".
   */
  QString toString() const override;

  /**
   * @brief Writes the triangle to a POV-Ray scene as a @c triangle.
   * @param s The stream to write to.
   */
  void toPOV(QTextStream *s) const override;

  /**
   * @brief Draws the triangle in its own frame.
   * @param minaabb Lower corner of the scene bounding box. Unused.
   * @param maxaabb Upper corner of the scene bounding box. Unused.
   */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

protected:
  /**
   * @brief Builds the collision shape, motion state and rigid body.
   * @param p0   First corner.
   * @param p1   Second corner.
   * @param p2   Third corner.
   * @param mass Mass; 0 makes the triangle static.
   */
  void init(const btVector3 &p0, const btVector3 &p1, const btVector3 &p2,
            btScalar mass);
};

#endif // TRIANGLE_H
