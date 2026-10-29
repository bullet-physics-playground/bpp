#ifndef TORUS_H
#define TORUS_H

/**
 * @file torus.h
 * @brief Torus primitive.
 */

#include "object.h"

#include <btBulletDynamicsCommon.h>

/**
 * @brief A torus, centred on its own origin in the XY plane.
 *
 * Backed by a Bullet btConvexHullShape (approximation) and exported as a
 * POV-Ray @c torus.
 */
class Torus : public Object {
public:
  /**
   * @brief Constructs a torus from inner and outer radius.
   * @param innerRadius  Radius of the tube (cross-section).
   * @param outerRadius  Distance from centre of tube to centre of torus.
   * @param mass         Mass; 0 makes the torus static.
   */
  Torus(btScalar innerRadius = 0.3, btScalar outerRadius = 1.0, btScalar mass = 1.0);

  /**
   * @brief Constructs a torus from a vector of dimensions.
   * @param dim  Inner radius (x) and outer radius (y).
   * @param mass Mass; 0 makes the torus static.
   */
  Torus(const btVector3 &dim, btScalar mass = 1.0);

  /**
   * @brief Destroys the torus and its Bullet shape and motion state.
   */
  ~Torus();

  btScalar innerRadius; ///< Radius of the tube.
  btScalar outerRadius; ///< Distance from centre of tube to centre of torus.

  /**
   * @brief Registers the Torus class with a Lua state.
   * @param s The Lua state to register in.
   */
  static void luaBind(lua_State *s);

  /**
   * @brief Returns the object's type name.
   * @return The literal @c "Torus".
   */
  QString toString() const override;

  /**
   * @brief Writes the torus to a POV-Ray scene as a @c torus.
   * @param s The stream to write to.
   */
  void toPOV(QTextStream *s) const override;

protected:
  /**
   * @brief Writes the torus's surface, wrapping a texture round it.
   * @param s The stream to write to; a null stream writes nothing.
   */
  void povPigment(QTextStream *s) const override;

  /**
   * @brief Builds the collision shape, motion state and rigid body.
   * @param innerRadius Radius of the tube.
   * @param outerRadius Distance from centre of tube to centre of torus.
   * @param mass        Mass; 0 makes the torus static.
   */
  void init(btScalar innerRadius, btScalar outerRadius, btScalar mass);

  /**
   * @brief Draws the torus in its own frame.
   * @param minaabb Lower corner of the scene bounding box. Unused.
   * @param maxaabb Upper corner of the scene bounding box. Unused.
   */
  void renderInLocalFrame(btVector3 &minaabb, btVector3 &maxaabb) override;
};

#endif // TORUS_H