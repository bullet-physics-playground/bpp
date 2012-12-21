#ifndef BINDINGS_H
#define BINDINGS_H

#include <lua.hpp>
#include <luabind/luabind.hpp>

#include <QString>

namespace luabind
{
  template <>
  struct default_converter<unsigned long long>
  : native_converter_base<unsigned long long>
  {
    static int compute_score(lua_State* L, int index) {
    return lua_type(L, index) == LUA_TNUMBER ? 0 : -1;
    }

    unsigned long long from(lua_State* L, int index) {
    return static_cast<unsigned long long>(lua_tonumber(L, index));
    }

    void to(lua_State* L, unsigned long long value) {
    lua_pushnumber(L, static_cast<lua_Number>(value));
    }
  };

  template <>
  struct default_converter<unsigned long long const>
  : default_converter<unsigned long long>
  {};

  template <>
  struct default_converter<unsigned long long const&>
  : default_converter<unsigned long long>
  {};

  template <>
    struct default_converter<QString>
  : native_converter_base<QString>
  {
  static int compute_score(lua_State* L, int index) {
    return lua_type(L, index) == LUA_TSTRING ? 0 : -1;
  }

  QString from(lua_State* L, int index) {
    return QString(lua_tostring(L, index));
  }

  void to(lua_State* L, QString const& x) {
    lua_pushstring(L, x.toAscii());
  }
  };

  template <>
    struct default_converter<QString const>
  : default_converter<QString>
  {};

  template <>
    struct default_converter<QString const&>
  : default_converter<QString>
  {};

  /*
  template <>
  struct default_converter<btScalar>
  : native_converter_base<btScalar>
  {
    static int compute_score(lua_State* L, int index) {
    return lua_type(L, index) == LUA_TNUMBER ? 0 : -1;
    }

    btScalar from(lua_State* L, int index) {
    return static_cast<type>(lua_tonumber(L, index));
    }

    void to(lua_State* L, btScalar const& value) {
    lua_pushnumber(L, static_cast<lua_Number>(value));
    }
  }

  template <>
    struct default_converter<btScalar const>
  : default_converter<btScalar>
  {};

  template <>
    struct default_converter<btScalar const&>
  : default_converter<btScalar>
  {};*/

}

#endif // BINDINGS_H
