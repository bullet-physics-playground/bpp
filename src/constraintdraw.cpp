#include "constraintdraw.h"

#include <qopengl.h>

#include "glutils.h"

namespace {

// A solid cylinder from `from` to `to`, radius `radius`, colored `color`.
// Builds a rotation (via btPlaneSpace1, matching how btHingeConstraint
// itself derives a frame from a single axis) that maps the cylinder's
// local Z (solidCylinder()'s axis) onto the from->to direction.
void drawConstraintCylinder(const btVector3 &from, const btVector3 &to,
                            btScalar radius, const btVector3 &color) {
  btVector3 dir = to - from;
  btScalar length = dir.length();
  if (length < SIMD_EPSILON)
    return;
  dir /= length;

  btVector3 p1, p2;
  btPlaneSpace1(dir, p1, p2);

  btTransform t;
  t.setIdentity();
  t.setOrigin(from);
  t.getBasis().setValue(p1.x(), p2.x(), dir.x(), p1.y(), p2.y(), dir.y(),
                        p1.z(), p2.z(), dir.z());

  GLfloat m[16];
  t.getOpenGLMatrix(m);

  glColor3f(color.x(), color.y(), color.z());
  glPushMatrix();
  glMultMatrixf(m);
  solidCylinder(radius, length, 8, 1);
  glPopMatrix();
}

/// Colour every constraint marker is drawn in.
static const btVector3 kConstraintColor(1.0, 0.5, 0.0); // orange

// A 3-axis cross, for constraints that pin a full frame (generic 6dof /
// fixed) rather than a single axis or point.
void drawConstraintFrame(const btTransform &t, btScalar size) {
  btScalar radius = size * btScalar(0.1);
  const btVector3 &origin = t.getOrigin();
  drawConstraintCylinder(origin, origin + t.getBasis().getColumn(0) * size,
                         radius, kConstraintColor);
  drawConstraintCylinder(origin, origin + t.getBasis().getColumn(1) * size,
                         radius, kConstraintColor);
  drawConstraintCylinder(origin, origin + t.getBasis().getColumn(2) * size,
                         radius, kConstraintColor);
}

// A single cylinder through t's origin along one of its local axes, for
// constraints defined by one axis (hinge, slider, cone-twist's twist axis).
void drawConstraintAxis(const btTransform &t, int axis, btScalar size,
                        const btVector3 &color) {
  btScalar radius = size * btScalar(0.15);
  const btVector3 &origin = t.getOrigin();
  btVector3 dir = t.getBasis().getColumn(axis);
  drawConstraintCylinder(origin - dir * size, origin + dir * size, radius,
                         color);
}

// A small 3-axis cross of cylinders at a single world point, for point
// constraints (point2point pivot).
void drawConstraintPoint(const btVector3 &p, btScalar size,
                         const btVector3 &color) {
  btScalar radius = size * btScalar(0.15);
  drawConstraintCylinder(p - btVector3(size, 0, 0), p + btVector3(size, 0, 0),
                         radius, color);
  drawConstraintCylinder(p - btVector3(0, size, 0), p + btVector3(0, size, 0),
                         radius, color);
  drawConstraintCylinder(p - btVector3(0, 0, size), p + btVector3(0, 0, size),
                         radius, color);
}

} // namespace

namespace ConstraintDraw {

// Half the average bounding-sphere radius of the two connected bodies, so
// markers scale with the parts a constraint actually joins rather than the
// whole scene (a single far-away or oversized object would otherwise blow
// up every marker's size).
btScalar size(btTypedConstraint *c) {
  btVector3 center;
  btScalar radiusA = 0, radiusB = 0;

  if (c->getRigidBodyA().getCollisionShape())
    c->getRigidBodyA().getCollisionShape()->getBoundingSphere(center, radiusA);
  if (c->getRigidBodyB().getCollisionShape())
    c->getRigidBodyB().getCollisionShape()->getBoundingSphere(center, radiusB);

  btScalar radius = (radiusA + radiusB) * btScalar(0.5);
  if (radius <= 0)
    radius = btScalar(1.0);

  return radius * btScalar(0.5);
}

// Modelled on btDiscreteDynamicsWorld::debugDrawConstraint(), implemented
// directly so we control size/color per type instead of Bullet's internal
// (often too-small) defaults.
void draw(btTypedConstraint *c, btScalar size) {
  const btTransform &trA = c->getRigidBodyA().getCenterOfMassTransform();
  const btTransform &trB = c->getRigidBodyB().getCenterOfMassTransform();

  switch (c->getConstraintType()) {
  case POINT2POINT_CONSTRAINT_TYPE: {
    auto *p2p = static_cast<btPoint2PointConstraint *>(c);
    drawConstraintPoint(trA * p2p->getPivotInA(), size, kConstraintColor);
    drawConstraintPoint(trB * p2p->getPivotInB(), size, kConstraintColor);
    break;
  }
  case HINGE_CONSTRAINT_TYPE: {
    // Hinge axis is the frame's local Z (see btHingeConstraint::setAxis()).
    auto *hinge = static_cast<btHingeConstraint *>(c);
    drawConstraintAxis(trA * hinge->getFrameOffsetA(), 2, size,
                       kConstraintColor);
    break;
  }
  case SLIDER_CONSTRAINT_TYPE: {
    // Slide axis is the frame's local X.
    auto *slider = static_cast<btSliderConstraint *>(c);
    drawConstraintAxis(slider->getCalculatedTransformA(), 0, size,
                       kConstraintColor);
    break;
  }
  case CONETWIST_CONSTRAINT_TYPE: {
    // Twist axis is the frame's local X.
    auto *cone = static_cast<btConeTwistConstraint *>(c);
    drawConstraintAxis(trA * cone->getAFrame(), 0, size, kConstraintColor);
    break;
  }
  case D6_CONSTRAINT_TYPE:
  case D6_SPRING_CONSTRAINT_TYPE: {
    // btGeneric6DofConstraint and btGeneric6DofSpringConstraint (which
    // derives from it) are a separate class hierarchy from
    // btGeneric6DofSpring2Constraint below -- casting either family to the
    // other's type would read through the wrong vtable/layout.
    auto *d6 = static_cast<btGeneric6DofConstraint *>(c);
    drawConstraintFrame(d6->getCalculatedTransformA(), size);
    break;
  }
  case D6_SPRING_2_CONSTRAINT_TYPE:
  case FIXED_CONSTRAINT_TYPE: {
    // Covers plain btGeneric6DofSpring2Constraint and btFixedConstraint
    // (both report D6_SPRING_2_CONSTRAINT_TYPE/FIXED_CONSTRAINT_TYPE and
    // draw as a 3-axis frame cross), and btHinge2Constraint, which also
    // reports D6_SPRING_2_CONSTRAINT_TYPE but is drawn more usefully as
    // its own two joint axes (steering + wheel-spin) through its anchor.
    auto *hinge2 = dynamic_cast<btHinge2Constraint *>(c);
    if (hinge2 != nullptr) {
      btVector3 anchor = hinge2->getAnchor();
      btScalar radius = size * btScalar(0.15);
      drawConstraintCylinder(anchor - hinge2->getAxis1() * size,
                             anchor + hinge2->getAxis1() * size, radius,
                             kConstraintColor);
      drawConstraintCylinder(anchor - hinge2->getAxis2() * size,
                             anchor + hinge2->getAxis2() * size, radius,
                             kConstraintColor);
    } else {
      auto *d6b = static_cast<btGeneric6DofSpring2Constraint *>(c);
      drawConstraintFrame(d6b->getCalculatedTransformA(), size);
    }
    break;
  }
  case GEAR_CONSTRAINT_TYPE: {
    auto *gear = static_cast<btGearConstraint *>(c);
    btVector3 axisA = trA.getBasis() * gear->getAxisA();
    btVector3 axisB = trB.getBasis() * gear->getAxisB();
    btScalar radius = size * btScalar(0.15);
    drawConstraintCylinder(trA.getOrigin() - axisA * size,
                           trA.getOrigin() + axisA * size, radius,
                           kConstraintColor);
    drawConstraintCylinder(trB.getOrigin() - axisB * size,
                           trB.getOrigin() + axisB * size, radius,
                           kConstraintColor);
    break;
  }
  default:
    break;
  }
}

} // namespace ConstraintDraw
