#ifndef LUA_BULLET_H
#define LUA_BULLET_H

/**
 * @file lua_bullet.h
 * @brief Luabind registration of the Bullet Physics types exposed to scripts.
 */

#include <lua.hpp>

#include <luabind/luabind.hpp>

#include <QObject>

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"

#include <btBulletCollisionCommon.h>
#include <btBulletDynamicsCommon.h>

#pragma GCC diagnostic pop

/**
 * @brief Binds the Bullet Physics API into a Lua interpreter.
 *
 * The class carries no state of its own; it exists so the binding code has a
 * QObject to live in. All the work happens in the static luaBind().
 */
class LuaBullet : public QObject {
  Q_OBJECT
public:
  /**
   * @brief Constructs the binder.
   * @param parent Parent object, passed through to QObject.
   */
  explicit LuaBullet(QObject *parent = nullptr);

  /**
   * @brief Registers the Bullet math, collision and dynamics classes with a
   *        Lua state.
   *
   * Exposes the vector/quaternion/transform maths, the collision shapes, the
   * rigid and soft body types and the constraint types in the @c bullet
   * namespace, so scripts can build and inspect a simulation directly. Call
   * once per lua_State, after the state has been opened.
   *
   * @param L The Lua state to register the bindings in.
   */
  static void luaBind(lua_State *L);
signals:

public slots:
};

#endif // LUA_BULLET_H
