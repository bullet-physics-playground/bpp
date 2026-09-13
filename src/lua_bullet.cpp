/**
 * @file lua_bullet.cpp
 * @brief Entry point of the Bullet-to-Lua bindings, and the QVariant bridge.
 *
 * The registrations themselves live in lua_bullet_1.cpp through
 * lua_bullet_4.cpp; see lua_bullet_p.h for why they are split up.
 */

#include "lua_bullet_p.h"

QVariant var_from(lua_State *L, int index) {
  QVariant var;
  int type = lua_type(L, index);
  switch (type) {
  case LUA_TNIL:
    var = QVariant();
    break;
  case LUA_TNUMBER:
    var = QVariant(lua_tonumber(L, index));
    break;
  case LUA_TSTRING:
    var = QVariant(lua_tostring(L, index));
    break;
  case LUA_TBOOLEAN:
    var = QVariant(lua_toboolean(L, index) != 0);
    break;
  case LUA_TTABLE: {
    QVariantMap map;
    lua_pushnil(L);
    while (lua_next(L, index - 1)) {
      lua_pushvalue(L, -2);
      QString key = lua_tostring(L, -1);
      lua_pop(L, 1);
      QVariant value = var_from(L, -1);
      map[key] = value;
      lua_pop(L, 1);
    }
    var = map;
    break;
  }
  default:
    break;
  }
  return var;
}

void var_to(lua_State *L, QVariant const &v) {
  if (v.type() == QVariant::Bool) {
    lua_pushboolean(L, v.toBool());
  } else if (v.type() == QVariant::Int || v.type() == QVariant::LongLong) {
    lua_pushinteger(L, v.toLongLong());
  } else if (v.type() == QVariant::Double) {
    lua_pushnumber(L, v.toDouble());
  } else if (v.type() == QVariant::String) {
    lua_pushstring(L, v.toString().toUtf8().constData());
  } else if (v.type() == QVariant::List) {
    const QVariantList list = v.toList();
    lua_createtable(L, list.size(), 0);
    for (int i = 0; i < list.size(); ++i) {
      lua_pushinteger(L, i + 1);
      var_to(L, list[i]);
      lua_settable(L, -3);
    }
  } else if (v.type() == QVariant::Map) {
    const QVariantMap map = v.toMap();
    lua_createtable(L, 0, map.size());
    for (auto it = map.constBegin(); it != map.constEnd(); ++it) {
      lua_pushstring(L, it.key().toUtf8().constData());
      var_to(L, it.value());
      lua_settable(L, -3);
    }
  } else {
    lua_pushnil(L);
  }
}

LuaBullet::LuaBullet(QObject *parent) : QObject(parent) {}

void LuaBullet::luaBind(lua_State *s) {
  // In order: luabind requires a base class to be registered before any
  // class deriving from it, and this is the same sequence the registrations
  // ran in when they were one function.
  luaBindBulletPart1(s);
  luaBindBulletPart2(s);
  luaBindBulletPart3(s);
  luaBindBulletPart4(s);
}
