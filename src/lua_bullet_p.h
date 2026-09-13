#ifndef LUA_BULLET_P_H
#define LUA_BULLET_P_H

/**
 * @file lua_bullet_p.h
 * @brief Glue shared by the lua_bullet translation units.
 *
 * Internal to the Bullet bindings; nothing outside them should include this.
 *
 * Besides the bindings themselves, registering Bullet with luabind needs glue
 * Bullet's own types do not provide: wrappers that let a Lua table act as a
 * Bullet callback, stream and comparison operators luabind's policies insist
 * on, and overrides that stop Lua's garbage collector from deleting objects
 * the simulation still owns. All of it lives here so the registrations can be
 * split across several translation units without duplicating any of it.
 *
 * The split exists purely to shorten the build: registering the whole Bullet
 * API in one function meant 707 luabind template instantiations in a single
 * translation unit, which took 45 s and 2.4 GB and was the critical path of
 * every parallel build. @ref LuaBullet::luaBind calls the parts in order, so
 * the registration sequence is exactly what it was when this was one function.
 */

#include "lua_bullet.h"
#include "lua_converters.h"

#include <QDebug>

#include <ostream>

#include <btBulletDynamicsCommon.h>

#include <BulletCollision/Gimpact/btGImpactCollisionAlgorithm.h>
#include <BulletCollision/Gimpact/btGImpactShape.h>
#include <BulletDynamics/Vehicle/btRaycastVehicle.h>

#include <luabind/adopt_policy.hpp>
#include <luabind/luabind.hpp>
#include <luabind/operator.hpp>
#include <luabind/wrapper_base.hpp>

/**
 * @brief Stops Lua's garbage collector from destroying instances of a class.
 *
 * Specializes luabind's deletion hooks for @p in_class so that they do
 * nothing. Bullet owns these objects - a rigid body belongs to the dynamics
 * world, a motion state to its body - so collecting the Lua wrapper must not
 * take the C++ object with it.
 *
 * @param in_class The class whose instances Lua must not delete.
 */

#define LuaClassNonDeletable(in_class)                                         \
  namespace luabind {                                                          \
  namespace detail {                                                           \
  template <> struct delete_s<in_class> {                                      \
    static void apply(void *) {}                                               \
  };                                                                           \
  template <> struct destruct_only_s<in_class> {                               \
    static void apply(void *) {}                                               \
  };                                                                           \
  }                                                                            \
  }

LuaClassNonDeletable(btDefaultMotionState) LuaClassNonDeletable(btMotionState)
    LuaClassNonDeletable(btCollisionObject) LuaClassNonDeletable(btRigidBody)
        LuaClassNonDeletable(btConcaveShape)

            /**
             * @brief Lets a Lua table implement Bullet's btMotionState interface.
             *
             * Bullet calls a motion state to read and write the transform of a body it is
             * simulating. Deriving from luabind::wrap_base lets those calls be dispatched
             * to the Lua object, so a script can position a kinematic body or observe a
             * dynamic one from Lua.
             */
            struct btMotionState_wrap : public btMotionState,
                                        luabind::wrap_base {
  /**
   * @brief Constructs the wrapper from a start transform and a centre of mass
   *        offset.
   *
   * Both are ignored here - a wrapper holds no transform of its own, the Lua
   * side does - and are left unnamed so the empty body draws no warning. The
   * signature exists so Lua can construct the object with the same arguments
   * as btDefaultMotionState.
   */
  btMotionState_wrap(const btTransform &, const btTransform &) {}

  /**
   * @brief Constructs the wrapper from a start transform alone.
   *
   * Ignored for the same reason as in the two-argument constructor.
   */
  btMotionState_wrap(const btTransform &) {}

  /**
   * @brief Asks the Lua object where the body should be.
   *
   * Bullet calls this for a kinematic body to find out where the simulation
   * should place it.
   *
   * @param[out] worldTrans Receives the transform the Lua side supplies.
   */
  virtual void getWorldTransform(btTransform &worldTrans) const {
    // qDebug() << "btMotionState_wrap::getWorldTransform()";
    luabind::call_member<void>(this, "getWorldTransform", worldTrans);
    /*
                                                                                          lua_State* L = m_self.state();
                                                                                                  m_self.get(L);
                                                                                                  if( ! lua_isnil( L, -1 ) ) {
                                                                                                  } else {
                                                                                                      qDebug() << "getWorldTransform missing on the Lua side";
                                                                                                  }
                                                                                                  lua_pop( L, 1 ); */
  }

  /**
   * @brief Tells the Lua object where the body has ended up.
   *
   * Bullet calls this after each step for a dynamic body, so a script can
   * follow the simulated motion.
   *
   * @param worldTrans The body's new world transform.
   */
  virtual void setWorldTransform(const btTransform &worldTrans) {
    // qDebug() << "btMotionState_wrap::setWorldTransform()";
    luabind::call_member<void>(this, "setWorldTransform", worldTrans);
    /*
                                                                                          lua_State* L = m_self.state();
                                                                                                  m_self.get(L);
                                                                                                  if( ! lua_isnil( L, -1 ) )
                                                                                                  else
                                                                                                      qDebug() << "setWorldTransform missing on the Lua side";
                                                                                                  lua_pop( L, 1 );*/
  }
};

/**
 * @brief A btDefaultMotionState whose methods a Lua table may override.
 *
 * Combines Bullet's stock implementation with btMotionState_wrap, so a script
 * gets the default behaviour for free and only has to define the methods it
 * actually wants to intercept.
 */
struct btDefaultMotionState_wrap : public btDefaultMotionState,
                                   btMotionState_wrap {
  /**
   * @brief Constructs the motion state at a transform with a centre of mass
   *        offset.
   * @param startTrans         Initial world transform of the body.
   * @param centerOfMassOffset Offset from that transform to the centre of mass.
   */
  btDefaultMotionState_wrap(const btTransform &startTrans,
                            const btTransform &centerOfMassOffset)
      : btDefaultMotionState(startTrans, centerOfMassOffset),
        btMotionState_wrap(startTrans, centerOfMassOffset) {
    // qDebug() << "btDefaultMotionState_wrap()";
  }
  /**
   * @brief Constructs the motion state at a transform.
   * @param startTrans Initial world transform of the body; the centre of mass
   *                   is taken to be at its origin.
   */
  btDefaultMotionState_wrap(const btTransform &startTrans)
      : btDefaultMotionState(startTrans), btMotionState_wrap(startTrans) {
    // qDebug() << "btDefaultMotionState_wrap()";
  }
};

/**
 * @brief Free-function form of btQuaternion::setRotation(), for binding.
 *
 * Sets @p q to the rotation of @p angle radians about @p axis. Wrapped as a
 * free function because the member is overloaded, which luabind cannot resolve
 * from a plain member pointer.
 *
 * @param q     The quaternion to overwrite.
 * @param axis  Axis to rotate about.
 * @param angle Rotation angle in radians.
 */
inline void btQuaternion_setRotation(btQuaternion& q, const btVector3& axis, btScalar angle) {
    q.setRotation(axis, angle);
}

// Bullet's C++ classes provide neither operator<< nor operator==, but
// luabind's tostring()/comparison policies require both to be found via ADL
// for every class registered with them. Without a fallback, calling
// tostring()/print() or comparing an instance of an unregistered class from
// Lua trips a hard C-level assert in luabind (object_rep.cpp's
// dispatch_operator: Assertion `inst' failed), crashing the app instead of
// raising a Lua error. Provide identity-based operator<</== for every
// distinct Bullet class hierarchy registered below; C++ reference-binding
// makes these visible to every derived class too, so only hierarchy roots
// (and otherwise-unrelated standalone structs) need one.
/**
 * @brief Defines identity-based @c operator<< and @c operator== for a type.
 *
 * The streamed form is the type name and the object's address, and two
 * instances compare equal only when they are the same object.
 *
 * @param Type The class to define the operators for.
 */
#define BT_LUA_IDENTITY_OPS(Type)                                            \
  inline std::ostream &operator<<(std::ostream &os, const Type &x) {         \
    return os << #Type "(" << static_cast<const void *>(&x) << ")";          \
  }                                                                           \
  inline bool operator==(const Type &a, const Type &b) { return &a == &b; }

// btMatrix3x3 and btTransform already come with a real, value-based
// operator== from Bullet itself - only operator<< is missing for those two.
/**
 * @brief Defines only the identity-based @c operator<< for a type.
 *
 * For btMatrix3x3 and btTransform, which already have a real, value-based
 * @c operator== from Bullet that should not be replaced.
 *
 * @param Type The class to define the stream operator for.
 */
#define BT_LUA_TOSTRING_ONLY(Type)                                          \
  inline std::ostream &operator<<(std::ostream &os, const Type &x) {         \
    return os << #Type "(" << static_cast<const void *>(&x) << ")";          \
  }

BT_LUA_IDENTITY_OPS(btCollisionShape)
BT_LUA_IDENTITY_OPS(btMotionState)
BT_LUA_IDENTITY_OPS(btStridingMeshInterface)
BT_LUA_IDENTITY_OPS(btAABB)
BT_LUA_TOSTRING_ONLY(btMatrix3x3)
BT_LUA_IDENTITY_OPS(btCollisionObject)
BT_LUA_IDENTITY_OPS(btRigidBody::btRigidBodyConstructionInfo)
BT_LUA_TOSTRING_ONLY(btTransform)
BT_LUA_IDENTITY_OPS(btTypedConstraint)
BT_LUA_IDENTITY_OPS(btVehicleRaycaster)
BT_LUA_IDENTITY_OPS(btRaycastVehicle::btVehicleTuning)
BT_LUA_IDENTITY_OPS(btWheelInfo)
BT_LUA_IDENTITY_OPS(btRaycastVehicle)

#undef BT_LUA_IDENTITY_OPS
#undef BT_LUA_TOSTRING_ONLY

/**
 * @brief Registers the first quarter of the Bullet API.
 *
 * Called by LuaBullet::luaBind(); see this file's description for why the
 * registrations are split. The parts must run in order, since luabind needs a
 * base class registered before anything deriving from it.
 *
 * @param s The Lua state to register in.
 */
void luaBindBulletPart1(lua_State *s);

/**
 * @brief Registers the second quarter of the Bullet API.
 * @param s The Lua state to register in.
 */
void luaBindBulletPart2(lua_State *s);

/**
 * @brief Registers the third quarter of the Bullet API.
 * @param s The Lua state to register in.
 */
void luaBindBulletPart3(lua_State *s);

/**
 * @brief Registers the last quarter of the Bullet API.
 * @param s The Lua state to register in.
 */
void luaBindBulletPart4(lua_State *s);

#endif // LUA_BULLET_P_H
