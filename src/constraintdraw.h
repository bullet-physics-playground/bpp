#ifndef CONSTRAINTDRAW_H
#define CONSTRAINTDRAW_H

#include <btBulletDynamicsCommon.h>

/**
 * @brief The markers v.showConstraints draws for joints, in the current
 * OpenGL context.
 *
 * Viewer::drawConstraints() decides which joints are drawn and where (a
 * joint in a placed world is drawn in that world's place); this draws each
 * one.
 */
namespace ConstraintDraw {

/**
 * @brief Chooses a marker size that suits the bodies a constraint joins.
 *
 * Half the average bounding-sphere radius of the two connected bodies, so
 * markers scale with the parts a constraint actually joins rather than the
 * whole scene.
 *
 * @param c The constraint.
 * @return The marker size; 0.5 if neither body has a collision shape.
 */
btScalar size(btTypedConstraint *c);

/**
 * @brief Draws the marker for one constraint.
 *
 * Modelled on btDiscreteDynamicsWorld::debugDrawConstraint() but implemented
 * directly, so the size and colour can be chosen per type instead of using
 * Bullet's often too-small internal defaults. Point constraints get a cross
 * at each pivot, hinge, slider and cone-twist constraints a cylinder along
 * their axis, six-degree-of-freedom and fixed constraints a three-axis
 * frame, a gear constraint one cylinder per body axis, and a
 * btHinge2Constraint its two joint axes through its anchor.
 *
 * @param c    The constraint to draw.
 * @param size Marker size, from size().
 */
void draw(btTypedConstraint *c, btScalar size);

} // namespace ConstraintDraw

#endif // CONSTRAINTDRAW_H
