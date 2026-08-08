# Bullet Physics Constraint Demos

This directory contains Lua demos for various Bullet Physics constraint types.

## Constraint Types

### btHingeConstraint (00-hinge.lua)
A hinge constraint restricts one or two bodies to rotate around a shared axis. Supports angular motor for driving rotation.

**Features:**
- Single or two-body attachment
- Angular motor with velocity control
- Configurable limits

### btPoint2PointConstraint (02-point2point.lua)
A point-to-point constraint acts like a ball-and-socket joint, connecting two bodies at specific pivot points.

**Features:**
- Each body has a pivot point
- Creates chain/collar structures
- Used in pearls collar demo

### btSliderConstraint (03-sliderConstraint)
A slider constraint allows relative motion along one axis (linear sliding) and optionally rotation around that axis.

**Features:**
- Linear limits (lower/upper)
- Linear motor with velocity control
- Angular limits
- Angular motor with velocity control
- Configurable softness/damping

### btConeTwistConstraint (04-conetwist.lua)
A cone twist constraint limits rotation within a cone, commonly used for shoulder joints.

**Features:**
- Limit angular range per axis
- Motor target quaternion
- Enable/disable motor
- Max motor impulse

### btGeneric6DofConstraint (05-generic6dof.lua)
A generic 6 degrees of freedom constraint with independent limits per axis.

**Features:**
- Linear limits (X, Y, Z)
- Angular limits (X, Y, Z)
- Per-axis setLimit() method

### btGeneric6DofSpringConstraint (06-generic6dofspring.lua)
Extends btGeneric6DofConstraint with spring support per axis.

**Features:**
- All btGeneric6DofConstraint features
- Enable spring per axis
- Configurable stiffness
- Configurable damping
- Equilibrium point setting

### btGearConstraint (07-gear.lua)
A gear constraint couples two bodies' rotation with a configurable ratio.

**Features:**
- Configurable gear ratio
- Independent axis direction per body
- Used to simulate gear trains

### btFixedConstraint (08-fixed.lua)
A fixed constraint welds two bodies rigidly together: every linear and angular degree of freedom between them is locked, unlike btPoint2PointConstraint (locks position only) or btHingeConstraint (locks position but still allows rotation about its axis).

**Features:**
- All 6 relative degrees of freedom locked
- Each body keeps its own physics body/mass/collision shape
- Used to weld chains of parts into one rigid compound

### btGeneric6DofSpring2Constraint (09-generic6dofspring2.lua)
The improved successor to btGeneric6DofSpringConstraint, with a more stable spring implementation and servo motor support.

**Features:**
- All btGeneric6DofConstraint-style per-axis limits
- Enable spring per axis, with `limitIfNeeded` stiffness/damping safety
- Servo motor mode: drives an axis toward a target position/angle at a bounded speed, instead of spinning at a constant velocity like a plain motor
- Rotation order configurable for the Euler angle system

### btHinge2Constraint (10-hinge2.lua)
A specialization of btGeneric6DofSpring2Constraint for suspension joints (as in ODE's Hinge2): 2 rotational DOFs (steering around axis1, spin around axis2, which must be orthogonal to axis1) plus 1 translational DOF for spring-loaded suspension travel -- modeling a steerable, driven, sprung vehicle wheel in a single constraint.

**Features:**
- `getAngle1()`/`getAngle2()`, `getAxis1()`/`getAxis2()`, `getAnchor()`/`getAnchor2()`
- `setUpperLimit()`/`setLowerLimit()` convenience methods for the steering angle
- Independent motors for wheel spin (constant velocity) and steering (servo, toward a moving target)
- Suspension spring/limits inherited from btGeneric6DofSpring2Constraint

## Usage

Run a demo:
```bash
./release/bpp -f demo/constraint/00-hinge.lua
```

## Keyboard Shortcuts

- **F1** - Previous car (01-car.lua only)
- **F2** - Next car (01-car.lua only)

## See Also

- [Bullet Physics Documentation](https://pybullet.org/)
- [Bullet3 GitHub](https://github.com/bulletphysics/bullet3)