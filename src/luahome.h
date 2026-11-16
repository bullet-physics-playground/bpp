/**
 * @file luahome.h
 * @brief Lua values kept by C++, held from the main Lua thread.
 *
 * A luabind::object remembers the Lua thread it was made on and uses it
 * again when it is let go. A script can run as a coroutine (Babbage's Hall
 * loads its exhibits so, waiting for their parts while the hall goes on),
 * and a coroutine's thread is gone once it has finished: a value kept from
 * it (an object's body, a render function, a slider's button) would then be
 * let go through a thread that no longer exists, and bpp crashed on closing
 * the script. luaHome() gives back the same value held from the main thread.
 */
#pragma once

#include <lua.hpp>
#include <luabind/object.hpp>

/// The main Lua thread (set when the viewer opens Lua; null before).
inline lua_State *&mainLuaState() {
  static lua_State *s = nullptr;
  return s;
}

/// @p o, held from the main Lua thread (itself if it is already, or there is none).
inline luabind::object luaHome(const luabind::object &o) {
  lua_State *m = mainLuaState();
  if (!m || !o.is_valid() || o.interpreter() == m)
    return o;
  o.push(m);
  luabind::object home(luabind::from_stack(m, -1));
  lua_pop(m, 1);
  return home;
}
