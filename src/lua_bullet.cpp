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
    // Decide whether the table is a pure array (integer keys 1..n) or a map.
    // Arrays become a QVariantList so positional tables keep their order and
    // don't collapse onto an empty string key; everything else becomes a map.
    struct Entry {
      QString key;
      int intKey = 0;
      bool isIntKey = false;
      QVariant value;
    };
    QList<Entry> entries;
    bool isArray = true;
    lua_pushnil(L);
    while (lua_next(L, index)) {  // table sits at @p index; pops nil/key, pushes (key, value)
      lua_pushvalue(L, -2);   // duplicate the key
      int keyType = lua_type(L, -1);
      Entry e;
      if (keyType == LUA_TNUMBER) {
        e.isIntKey = true;
        e.intKey = lua_tointeger(L, -1);
        e.key = QString::number(e.intKey);
        if (e.intKey <= 0) isArray = false;
      } else {
        e.isIntKey = false;
        e.key = lua_tostring(L, -1);
        isArray = false;
      }
      lua_pop(L, 1);          // pop the duplicate key
      e.value = var_from(L, -1);
      entries.append(e);
      lua_pop(L, 1);          // pop the value
    }
    if (isArray && !entries.isEmpty()) {
      bool contiguous = true;
      for (int i = 0; isArray && contiguous && i < (int)entries.size(); ++i)
        contiguous = entries[i].isIntKey && entries[i].intKey == i + 1;
      if (contiguous) {
        QVariantList list;
        for (const Entry &e : entries) list.append(e.value);
        var = list;
        break;
      }
    }
    QVariantMap map;
    for (const Entry &e : entries) map[e.key] = e.value;
    var = map;
    break;
  }
  default:
    // Anything that is not a primitive (functions, user data, threads) is
    // carried as a luabind::object, so that e.g. a Lua function passed to
    // Viewer::addParam() survives as the callback of a push button parameter.
    var = QVariant::fromValue(luabind::object(luabind::from_stack(L, index)));
    break;
  }
  return var;
}

void var_to(lua_State *L, QVariant const &v) {
  if (v.userType() == QVariant::Bool) {
    lua_pushboolean(L, v.toBool());
  } else if (v.userType() == QVariant::Int || v.userType() == QVariant::LongLong) {
    lua_pushinteger(L, v.toLongLong());
  } else if (v.userType() == QVariant::Double || v.userType() == QMetaType::Float) {
    lua_pushnumber(L, v.toDouble());   // (a float: a slider's value, a btScalar)
  } else if (v.userType() == QVariant::String) {
    lua_pushstring(L, v.toString().toUtf8().constData());
  } else if (v.userType() == QVariant::List) {
    const QVariantList list = v.toList();
    lua_createtable(L, list.size(), 0);
    for (int i = 0; i < list.size(); ++i) {
      lua_pushinteger(L, i + 1);
      var_to(L, list[i]);
      lua_settable(L, -3);
    }
  } else if (v.userType() == QVariant::Map) {
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

  // Bullet's default constructors leave these uninitialised, and luabind can
  // only call them. In a script btQuaternion() means "no rotation" (and
  // demos use it so), so with no arguments each now makes the identity or
  // zero; luabind looks up a class's __init when it is called.
  luaL_dostring(s, R"lua(
    local unpack = table.unpack or unpack
    local function default(class, ...)
      local init, args = class.__init, {...}
      class.__init = function(...)
        -- Only the new object, no arguments: construct with the defaults.
        -- Any other call goes through exactly as it came.
        if select("#", ...) == 1 then
          return init((...), unpack(args))
        end
        return init(...)
      end
    end
    default(btVector3, 0, 0, 0)
    default(btQuaternion, 0, 0, 0, 1)
    default(btMatrix3x3, 1, 0, 0, 0, 1, 0, 0, 0, 1)
    default(btTransform, btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0))
  )lua");
}
