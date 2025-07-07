#ifndef LUA_BULLET_H
#define LUA_BULLET_H

#include <lua.hpp>

#include <luabind/luabind.hpp>

#include <QObject>

#pragma GCC diagnostic ignored "-Wunused-parameter"

#include <btBulletDynamicsCommon.h>
#include <btBulletCollisionCommon.h>

#pragma GCC diagnostic pop

class LuaBullet : public QObject
{
    Q_OBJECT
public:
    explicit LuaBullet(QObject *parent = 0);
    static void luaBind(lua_State *);
signals:

public slots:

};

#endif // LUA_BULLET_H
