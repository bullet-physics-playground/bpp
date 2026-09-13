#ifndef PLANE_H
#define PLANE_H

/**
 * @file plane.h
 * @brief Infinite ground plane primitive.
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

/**
 * @brief An infinite plane, usually the ground.
 *
 * Backed by a Bullet btStaticPlaneShape, so it is always static however it is
 * constructed, and exported as a POV-Ray @c plane, which is infinite too. In
 * the interactive view it is drawn as a finite square of the given size, since
 * an infinite surface cannot be rasterised; that same size is what the viewer
 * uses for the plane when it computes the scene bounding box, instead of the
 * effectively infinite extent Bullet reports.
 */
class Plane : public Object {
public:
  /**
   * @brief Constructs a plane from a normal vector.
   * @param dim    The plane's normal.
   * @param nConst Distance from the origin along the normal.
   * @param size   Half the edge length of the square that is drawn.
   */
  Plane(const btVector3 &dim, btScalar nConst, btScalar size);

  /**
   * @brief Constructs a plane from the components of its normal.
   * @param nx     Normal x component.
   * @param ny     Normal y component.
   * @param nz     Normal z component.
   * @param nConst Distance from the origin along the normal.
   * @param size   Half the edge length of the square that is drawn.
   */
  Plane(btScalar nx = 0.0, btScalar ny = 0.0, btScalar nz = 0.0,
        btScalar nConst = 0.0, btScalar size = 10.0);

  /**
   * @brief Destroys the plane and its Bullet shape and motion state.
   */
  ~Plane(); // Add destructor declaration

  /**
   * @brief Sets a POV-Ray pigment for the plane.
   * @param pigment The pigment SDL.
   */
  void setPigment(const QString &pigment);

  /**
   * @brief Registers the Plane class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns the object's type name.
   *
   * The literal @c "Plane" is also how the viewer recognises a plane when it
   * computes the scene bounding box.
   *
   * @return The literal @c "Plane".
   */
  QString toString() const override;

  /**
   * @brief Writes the plane to a POV-Ray scene as a @c plane.
   *
   * Takes the normal and distance from the Bullet shape, negating z for
   * POV-Ray's left-handed convention.
   *
   * @param s The stream to write to.
   */
  void toPOV(QTextStream *s) const override;

  /**
   * @brief Draws the plane as a finite square with an outline.
   *
   * The square is built from two in-plane axes derived from the normal, and
   * its triangles are emitted in both winding orders so the plane is visible
   * from either side.
   *
   * @param minaabb Lower corner of the scene bounding box. Unused.
   * @param maxaabb Upper corner of the scene bounding box. Unused.
   */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;

  /**
   * @brief Draws the plane.
   *
   * Unlike Object::render() this goes straight to renderInLocalFrame() with
   * no transform pushed, the plane being fixed at the origin. Note that it
   * does not override Object::render(), which is not virtual, so drawing
   * through an Object pointer takes the base class path.
   *
   * @param minaabb Lower corner of the scene bounding box.
   * @param maxaabb Upper corner of the scene bounding box.
   */
  void render(btVector3 &minaabb, btVector3 &maxaabb);

  /**
   * @brief Returns the size of the square the plane is drawn as.
   * @return Half the edge length.
   */
  btScalar getSize() const;

protected:
  /**
   * @brief Builds the collision shape, motion state and static rigid body.
   * @param nx     Normal x component.
   * @param ny     Normal y component.
   * @param nz     Normal z component.
   * @param nConst Distance from the origin along the normal.
   * @param size   Half the edge length of the square that is drawn.
   */
  void init(btScalar nx, btScalar ny, btScalar nz, btScalar nConst,
            btScalar size);

  btScalar size; ///< Half the edge length of the drawn square.

  QString mPigment; ///< POV-Ray pigment set by setPigment().
};

#endif // PLANE_H
