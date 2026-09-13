/**
 * @file lua_bullet_4.cpp
 * @brief The last quarter of the Bullet-to-Lua registrations.
 *
 * Split out of lua_bullet.cpp purely to shorten the build; see
 * lua_bullet_p.h. The registrations appear here in the same order they had
 * in the original single function.
 */

#include "lua_bullet_p.h"

/**
 * @brief Registers the last quarter of the Bullet API.
 * @param s The Lua state to register in.
 */
void luaBindBulletPart4(lua_State *s) {
  using namespace luabind;

  module(s)[class_<btPoint2PointConstraint, btTypedConstraint>(
                "btPoint2PointConstraint")
                .def(constructor<btRigidBody &, btRigidBody &,
                                 const btVector3 &, const btVector3 &>())
                .def("setParam", &btPoint2PointConstraint::setParam)
                .def(tostring(const_self))
                .def(const_self == const_self)];

module(
    s)[class_<btHingeConstraint, btTypedConstraint>("btHingeConstraint")
           .def(constructor<btRigidBody &, btRigidBody &, const btVector3 &,
                            const btVector3 &, const btVector3 &,
                            const btVector3 &>())
           .def(constructor<btRigidBody &, btRigidBody &, const btTransform &,
                            const btTransform &>())
           .def(constructor<btRigidBody &, const btVector3 &, const btVector3 &>())
           .def("setAxis", &btHingeConstraint::setAxis)
           .def("setLimit", &btHingeConstraint::setLimit)
           .def("setParam", &btHingeConstraint::setParam)
           .def("setAngularOnly", &btHingeConstraint::setAngularOnly)
           .def("enableAngularMotor", &btHingeConstraint::enableAngularMotor)
           .def("getHingeAngle", (btScalar(btHingeConstraint::*)()) &
                                        btHingeConstraint::getHingeAngle)
           .def("getHingeAngle",
                (btScalar(btHingeConstraint::*)(const btTransform &,
                                                const btTransform &)) &
                        btHingeConstraint::getHingeAngle)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  /*
  module(s) // https://pybullet.org/Bullet/BulletFull/classbtHingeAccumulatedAngleConstraint.html
[class_<btHingeAccumulatedAngleConstraint, btHingeConstraint>(
             "btHingeAccumulatedAngleConstraint")
             .def(constructor<btRigidBody &, btRigidBody &, const btTransform &,
                              const btTransform &>())
             .def("getAccumulatedHingeAngle",
                  &btHingeAccumulatedAngleConstraint::getAccumulatedHingeAngle)];
  */

  module(s)
      [class_<btConeTwistConstraint, btTypedConstraint>("btConeTwistConstraint")
           .def(constructor<btRigidBody &, btRigidBody &, const btTransform &,
                            const btTransform &>())
           .def(constructor<btRigidBody &, const btTransform &>())
     	   //XXX  ^.def("getLimit", &btConeTwistConstraint::getLimit)
           .def("setLimit",
                (void(btConeTwistConstraint::*)(int, btScalar)) &
                    btConeTwistConstraint::setLimit)
           .def("setMotorTarget", &btConeTwistConstraint::setMotorTarget)
           .def("setMotorTargetInConstraintSpace",
                &btConeTwistConstraint::setMotorTargetInConstraintSpace)
           .def("enableMotor", &btConeTwistConstraint::enableMotor)
	       //XXX .def("isMotorEnabled", &btConeTwistConstraint::isMotorEnabled)
           .def("setMaxMotorImpulse", &btConeTwistConstraint::setMaxMotorImpulse)
           .def("getPointForAngle", &btConeTwistConstraint::GetPointForAngle)
           .def("setParam", &btConeTwistConstraint::setParam)
           .def("getAFrame", &btConeTwistConstraint::getAFrame)
           .def("getBFrame", &btConeTwistConstraint::getBFrame)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s)
      [class_<btSliderConstraint, btTypedConstraint>("btSliderConstraint")
           .def(constructor<btRigidBody &, btRigidBody &, const btTransform &,
                            const btTransform &, bool>())
           .def("setLowerLinLimit", &btSliderConstraint::setLowerLinLimit)
           .def("setUpperLinLimit", &btSliderConstraint::setUpperLinLimit)
           .def("setLowerAngLimit", &btSliderConstraint::setLowerAngLimit)
           .def("setUpperAngLimit", &btSliderConstraint::setUpperAngLimit)
           .def("setSoftnessDirLin", &btSliderConstraint::setSoftnessDirLin)
           .def("setRestitutionDirLin",
                &btSliderConstraint::setRestitutionDirLin)
           .def("setDampingDirLin", &btSliderConstraint::setDampingDirLin)
           .def("setSoftnessDirAng", &btSliderConstraint::setSoftnessDirAng)
           .def("setRestitutionDirAng",
                &btSliderConstraint::setRestitutionDirAng)
           .def("setDampingDirAng", &btSliderConstraint::setDampingDirAng)
           .def("setSoftnessLimLin", &btSliderConstraint::setSoftnessLimLin)
           .def("setRestitutionLimLin",
                &btSliderConstraint::setRestitutionLimLin)
           .def("setDampingLimLin", &btSliderConstraint::setDampingLimLin)
           .def("setSoftnessLimAng", &btSliderConstraint::setSoftnessLimAng)
           .def("setRestitutionLimAng",
                &btSliderConstraint::setRestitutionLimAng)
           .def("setDampingLimAng", &btSliderConstraint::setDampingLimAng)
           .def("setSoftnessOrthoLin", &btSliderConstraint::setSoftnessOrthoLin)
           .def("setRestitutionOrthoLin",
                &btSliderConstraint::setRestitutionOrthoLin)
           .def("setDampingOrthoLin", &btSliderConstraint::setDampingOrthoLin)
           .def("setSoftnessOrthoAng", &btSliderConstraint::setSoftnessOrthoAng)
           .def("setRestitutionOrthoAng",
                &btSliderConstraint::setRestitutionOrthoAng)
           .def("setDampingOrthoAng", &btSliderConstraint::setDampingOrthoAng)
           .def("setPoweredLinMotor", &btSliderConstraint::setPoweredLinMotor)
           .def("getPoweredLinMotor", &btSliderConstraint::getPoweredLinMotor)
           .def("getLinearPos", &btSliderConstraint::getLinearPos)
           .def("setTargetLinMotorVelocity",
                &btSliderConstraint::setTargetLinMotorVelocity)           .def("getTargetLinMotorVelocity",
                &btSliderConstraint::getTargetLinMotorVelocity)
           .def("setMaxLinMotorForce", &btSliderConstraint::setMaxLinMotorForce)
           .def("getMaxLinMotorForce", &btSliderConstraint::getMaxLinMotorForce)
           .def("setPoweredAngMotor", &btSliderConstraint::setPoweredAngMotor)
           .def("getPoweredAngMotor", &btSliderConstraint::getPoweredAngMotor)
           .def("setTargetAngMotorVelocity",
                &btSliderConstraint::setTargetAngMotorVelocity)
           .def("getTargetAngMotorVelocity",
                &btSliderConstraint::getTargetAngMotorVelocity)
           .def("setMaxAngMotorForce", &btSliderConstraint::setMaxAngMotorForce)
           .def("getMaxAngMotorForce", &btSliderConstraint::getMaxAngMotorForce)
           .def("setParam", &btSliderConstraint::setParam)
           .def(tostring(const_self))
           .def(const_self == const_self)];

module(
    s)[class_<btGeneric6DofConstraint, btTypedConstraint>(
           "btGeneric6DofConstraint")
           .def(constructor<btRigidBody &, btRigidBody &, const btTransform &,
                            const btTransform &, bool>())
           .def("setLinearUpperLimit",
                &btGeneric6DofConstraint::setLinearUpperLimit)
           .def("setLinearLowerLimit",
                &btGeneric6DofConstraint::setLinearLowerLimit)
           .def("setAngularUpperLimit",
                &btGeneric6DofConstraint::setAngularUpperLimit)
           .def("setAngularLowerLimit",
                &btGeneric6DofConstraint::setAngularLowerLimit)
           .def("setLimit", &btGeneric6DofConstraint::setLimit)
           .def("setAxis", &btGeneric6DofConstraint::setAxis)
           .def("setParam", &btGeneric6DofConstraint::setParam)
           .def(tostring(const_self))
           .def(const_self == const_self)];

module(
    s)[class_<btGeneric6DofSpringConstraint, btTypedConstraint>(
           "btGeneric6DofSpringConstraint")
           .def(constructor<btRigidBody &, btRigidBody &, const btTransform &,
                            const btTransform &, bool>())
           .def("setLinearUpperLimit",
                &btGeneric6DofSpringConstraint::setLinearUpperLimit)
           .def("setLinearLowerLimit",
                &btGeneric6DofSpringConstraint::setLinearLowerLimit)
           .def("setAngularUpperLimit",
                &btGeneric6DofSpringConstraint::setAngularUpperLimit)
           .def("setAngularLowerLimit",
                &btGeneric6DofSpringConstraint::setAngularLowerLimit)
           .def("enableSpring", &btGeneric6DofSpringConstraint::enableSpring)
           .def("setStiffness", &btGeneric6DofSpringConstraint::setStiffness)
           .def("setDamping", &btGeneric6DofSpringConstraint::setDamping)
           .def("setAxis", &btGeneric6DofSpringConstraint::setAxis)
           .def("setEquilibriumPoint",
                (void(btGeneric6DofSpringConstraint::*)()) &
                    btGeneric6DofSpringConstraint::setEquilibriumPoint)
           .def("setEquilibriumPoint",
                (void(btGeneric6DofSpringConstraint::*)(int)) &
                    btGeneric6DofSpringConstraint::setEquilibriumPoint)
           .def("setEquilibriumPoint",
                (void(btGeneric6DofSpringConstraint::*)(int, btScalar)) &
                    btGeneric6DofSpringConstraint::setEquilibriumPoint)
           .def(tostring(const_self))
           .def(const_self == const_self)];

module(
    s)[class_<btGeneric6DofSpring2Constraint, btTypedConstraint>(
           "btGeneric6DofSpring2Constraint")
           .def(constructor<btRigidBody &, btRigidBody &, const btTransform &,
                            const btTransform &>())
           .def("setLinearUpperLimit",
                &btGeneric6DofSpring2Constraint::setLinearUpperLimit)
           .def("setLinearLowerLimit",
                &btGeneric6DofSpring2Constraint::setLinearLowerLimit)
           .def("setAngularUpperLimit",
                &btGeneric6DofSpring2Constraint::setAngularUpperLimit)
           .def("setAngularLowerLimit",
                &btGeneric6DofSpring2Constraint::setAngularLowerLimit)
           .def("setLimit", &btGeneric6DofSpring2Constraint::setLimit)
           .def("setAxis", &btGeneric6DofSpring2Constraint::setAxis)
           .def("setBounce", &btGeneric6DofSpring2Constraint::setBounce)
           .def("enableMotor", &btGeneric6DofSpring2Constraint::enableMotor)
           .def("setServo", &btGeneric6DofSpring2Constraint::setServo)
           .def("setTargetVelocity",
                &btGeneric6DofSpring2Constraint::setTargetVelocity)
           .def("setServoTarget",
                &btGeneric6DofSpring2Constraint::setServoTarget)
           .def("setMaxMotorForce",
                &btGeneric6DofSpring2Constraint::setMaxMotorForce)
           .def("enableSpring", &btGeneric6DofSpring2Constraint::enableSpring)
           .def("setStiffness", &btGeneric6DofSpring2Constraint::setStiffness)
           .def("setDamping", &btGeneric6DofSpring2Constraint::setDamping)
           .def("setEquilibriumPoint",
                (void(btGeneric6DofSpring2Constraint::*)()) &
                    btGeneric6DofSpring2Constraint::setEquilibriumPoint)
           .def("setEquilibriumPoint",
                (void(btGeneric6DofSpring2Constraint::*)(int)) &
                    btGeneric6DofSpring2Constraint::setEquilibriumPoint)
           .def("setEquilibriumPoint",
                (void(btGeneric6DofSpring2Constraint::*)(int, btScalar)) &
                    btGeneric6DofSpring2Constraint::setEquilibriumPoint)
           .def("setParam", &btGeneric6DofSpring2Constraint::setParam)
           .def(tostring(const_self))
           .def(const_self == const_self)];

// btFixedConstraint: a btGeneric6DofSpring2Constraint with every linear and
// angular DOF locked at construction, welding rbA/rbB rigidly together at
// their relative frameInA/frameInB offset -- unlike btPoint2PointConstraint
// (locks position only) or a mass-0 body (immovable rather than jointed to
// another dynamic body), this is the one constraint that removes all 6
// relative degrees of freedom between two otherwise-independent bodies.
module(s)[class_<btFixedConstraint, btGeneric6DofSpring2Constraint>(
              "btFixedConstraint")
              .def(constructor<btRigidBody &, btRigidBody &,
                               const btTransform &, const btTransform &>())
              .def(tostring(const_self))
              .def(const_self == const_self)];

// btHinge2Constraint: an btGeneric6DofSpring2Constraint specialized for
// suspension -- 2 angular DOFs (steering around axis1, wheel spin around
// axis2, which must be orthogonal) plus 1 linear DOF along axis1 for the
// suspension's own spring travel; commonly used for a vehicle's
// steerable/driven wheel.
module(s)[class_<btHinge2Constraint, btGeneric6DofSpring2Constraint>(
              "btHinge2Constraint")
              .def(constructor<btRigidBody &, btRigidBody &, btVector3 &,
                               btVector3 &, btVector3 &>())
              .def("getAnchor", &btHinge2Constraint::getAnchor)
              .def("getAnchor2", &btHinge2Constraint::getAnchor2)
              .def("getAxis1", &btHinge2Constraint::getAxis1)
              .def("getAxis2", &btHinge2Constraint::getAxis2)
              .def("getAngle1", &btHinge2Constraint::getAngle1)
              .def("getAngle2", &btHinge2Constraint::getAngle2)
              .def("setUpperLimit", &btHinge2Constraint::setUpperLimit)
              .def("setLowerLimit", &btHinge2Constraint::setLowerLimit)
              .def(tostring(const_self))
              .def(const_self == const_self)];

module(
    s)[class_<btUniversalConstraint, btTypedConstraint>(
           "btUniversalConstraint")
           .def(constructor<btRigidBody &, btRigidBody &, const btVector3 &,
                            const btVector3 &, const btVector3 &>())
           .def("setAxis", &btUniversalConstraint::setAxis)
           .def("setUpperLimit", &btHingeConstraint::setLimit)
           .def("setLowerLimit", &btHingeConstraint::setParam)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s)[class_<btGearConstraint, btTypedConstraint>("btGearConstraint")
           .def(constructor<btRigidBody &, btRigidBody &, const btVector3 &,
                            const btVector3 &, btScalar>())
           .def("setAxisA", &btGearConstraint::setAxisA)
           .def("setAxisB", &btGearConstraint::setAxisB)
           .def("setRatio", &btGearConstraint::setRatio)
           .def("getAxisA", &btGearConstraint::getAxisA)
           .def("getAxisB", &btGearConstraint::getAxisB)
           .def("getRatio", &btGearConstraint::getRatio)
           .def(tostring(const_self))
           .def(const_self == const_self)];

  module(s)[class_<btVehicleRaycaster>("btVehicleRaycaster")
                .def(tostring(const_self))
                .def(const_self == const_self)];

  module(s)[class_<btDefaultVehicleRaycaster, btVehicleRaycaster>(
      "btDefaultVehicleRaycaster")
                .def(tostring(const_self))
                .def(const_self == const_self)];

  module(
      s)[class_<btRaycastVehicle::btVehicleTuning>("btVehicleTuning")
             .def(constructor<>())
             .def_readwrite(
                 "suspensionStiffness",
                 &btRaycastVehicle::btVehicleTuning::m_suspensionStiffness)
             .def_readwrite(
                 "suspensionCompression",
                 &btRaycastVehicle::btVehicleTuning::m_suspensionCompression)
             .def_readwrite(
                 "suspensionDamping",
                 &btRaycastVehicle::btVehicleTuning::m_suspensionDamping)
             .def_readwrite(
                 "maxSuspensionTravelCm",
                 &btRaycastVehicle::btVehicleTuning::m_maxSuspensionTravelCm)
             .def_readwrite("frictionSlip",
                            &btRaycastVehicle::btVehicleTuning::m_frictionSlip)
             .def_readwrite(
                 "maxSuspensionForce",
                 &btRaycastVehicle::btVehicleTuning::m_maxSuspensionForce)
             .def(tostring(const_self))
             .def(const_self == const_self)];

  module(s)[class_<btWheelInfo>("btWheelInfo")
                .def(tostring(const_self))
                .def(const_self == const_self)];

  module(
      s)[class_<btRaycastVehicle>("btRaycastVehicle")
             .def(constructor<const btRaycastVehicle::btVehicleTuning &,
                              btRigidBody *, btVehicleRaycaster *>())
             .def("setCoordinateSystem", &btRaycastVehicle::setCoordinateSystem)
             .def("addWheel", &btRaycastVehicle::addWheel)
             .def("applyEngineForce", &btRaycastVehicle::applyEngineForce)
             .def("updateWheelTransform",
                  &btRaycastVehicle::updateWheelTransform)
             .def("updateVehicle", &btRaycastVehicle::updateVehicle)
             .def(tostring(const_self))
             .def(const_self == const_self)];}
